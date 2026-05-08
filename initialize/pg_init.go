package initialize

import (
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	global "project/pkg/global"
	utils "project/pkg/utils"

	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
	"gorm.io/gorm/schema"
)

// 数据库配置
type DbConfig struct {
	Host          string
	Port          int
	DbName        string
	Username      string
	Password      string
	TimeZone      string
	LogLevel      int
	SlowThreshold int
	IdleConns     int
	OpenConns     int
}

func PgInit() (*gorm.DB, error) {
	// 初始化配置
	config, err := LoadDbConfig()
	if err != nil {
		logrus.Errorf("加载数据库配置失败: %v", err)
		return nil, err
	}

	// 初始化数据库（添加重试逻辑）
	var db *gorm.DB
	maxRetries := 10
	retryInterval := 6 * time.Second

	for retryCount := 0; retryCount < maxRetries; retryCount++ {
		db, err = PgConnect(config)
		if err == nil {
			break
		}

		logrus.Warnf("连接数据库失败 (尝试 %d/%d): %v", retryCount+1, maxRetries, err)

		if retryCount < maxRetries-1 {
			logrus.Infof("将在 %v 后重试连接...", retryInterval)
			time.Sleep(retryInterval)
		}
	}

	if err != nil {
		logrus.Error("连接数据库失败，已达到最大重试次数:", err)
		return nil, err
	}

	global.DB = db

	// casbin 初始化
	CasbinInit()

	// 检查版本
	err = CheckVersion(db)
	if err != nil {
		fmt.Println(err)
	}

	return db, nil
}

// LoadDbConfig 从配置文件加载数据库配置
func LoadDbConfig() (*DbConfig, error) {
	config := &DbConfig{
		Host:          viper.GetString("db.psql.host"),
		Port:          viper.GetInt("db.psql.port"),
		DbName:        viper.GetString("db.psql.dbname"),
		Username:      viper.GetString("db.psql.username"),
		Password:      viper.GetString("db.psql.password"),
		TimeZone:      viper.GetString("db.psql.time_zone"),
		LogLevel:      viper.GetInt("db.psql.log_level"),
		SlowThreshold: viper.GetInt("db.psql.slow_threshold"),
		IdleConns:     viper.GetInt("db.psql.idle_conns"),
		OpenConns:     viper.GetInt("db.psql.open_conns"),
	}

	// 设置默认值
	if config.Host == "" {
		config.Host = "localhost"
	}
	if config.Port == 0 {
		config.Port = 5432
	}
	if config.TimeZone == "" {
		config.TimeZone = "Asia/Shanghai"
	}
	if config.LogLevel == 0 {
		config.LogLevel = 1
	}
	if config.SlowThreshold == 0 {
		config.SlowThreshold = 200
	}
	if config.IdleConns == 0 {
		config.IdleConns = 10
	}
	if config.OpenConns == 0 {
		config.OpenConns = 50
	}

	// 检查必要的配置
	if config.DbName == "" || config.Username == "" || config.Password == "" {
		return nil, fmt.Errorf("database configuration is incomplete")
	}

	return config, nil
}

// Writer 重写gorm日志的Writer
// type Writer struct{}

// func (w Writer) Printf(format string, args ...interface{}) {
// 	log.Println(args...)
// }

// PgInit 初始化数据库连接
func PgConnect(config *DbConfig) (*gorm.DB, error) {
	dataSource := fmt.Sprintf("host=%s port=%d dbname=%s user=%s password=%s sslmode=disable TimeZone=%s",
		config.Host, config.Port, config.DbName, config.Username, config.Password, config.TimeZone)

	// 根据配置获取 SQL 日志 Writer（支持文件和控制台输出）
	sqlLogWriter := GetSQLLogWriter()

	newLogger := logger.New(
		//Writer{},
		log.New(sqlLogWriter, "\r\n", log.LstdFlags), // 使用配置的日志输出（文件或控制台）
		logger.Config{
			SlowThreshold:             time.Duration(config.SlowThreshold) * time.Millisecond,
			LogLevel:                  logger.LogLevel(config.LogLevel),
			IgnoreRecordNotFoundError: true,
			Colorful:                  true, // 控制台输出时显示颜色，文件输出时会被忽略
		})

	var err error
	db, err := gorm.Open(postgres.Open(dataSource), &gorm.Config{
		Logger:                 newLogger,
		SkipDefaultTransaction: true,
		NamingStrategy: schema.NamingStrategy{
			SingularTable: false, // use singular table name, table for `User` would be `user` with this option enabled
		},
	})
	if err != nil {
		return nil, fmt.Errorf("连接数据库失败: %v", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		return nil, fmt.Errorf("获取原生数据库连接失败: %v", err)
	}

	sqlDB.SetMaxIdleConns(config.IdleConns)
	sqlDB.SetMaxOpenConns(config.OpenConns)
	sqlDB.SetConnMaxLifetime(time.Hour)

	logrus.Infoln("连接数据库完成...")

	return db, nil
}

/*
注意 sql中不要有sys_version表
1. 检查版本表是否存在: 检查数据库版本，如果没有sys_version表，创建sys_version表，插入版本序号0，版本号0.0.0
2. 程序版本低于数据版本: 提示升级
3. 数据版本低于程序版本: 执行sql文件，更新版本号

优化：
- 每个SQL文件单独执行，失败不影响后续文件
- 使用"继续执行"模式处理已存在的对象
- 事务仅用于更新版本号
*/
func CheckVersion(db *gorm.DB) error {
	version := global.VERSION
	versionNumber := global.VERSION_NUMBER
	var dataVersionNumber int

	// 判断有没有sys_version的表
	var exists bool
	result := db.Raw("SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='sys_version')").Scan(&exists)
	if result.Error != nil {
		return result.Error
	}

	logrus.Info("----", exists)
	if !exists {
		logrus.Info("创建sys_version表")
		dataVersionNumber = 0
		t := db.Exec("CREATE TABLE sys_version (version_number INT NOT NULL DEFAULT 0, version varchar(255) NOT NULL, PRIMARY KEY (version_number))")
		if t.Error != nil {
			return t.Error
		}
	}

	// 查询版本号
	result = db.Table("sys_version").Select("version_number").Scan(&dataVersionNumber)
	if result.Error != nil {
		return result.Error
	}

	// 如果版本号为空，插入版本号
	if dataVersionNumber == 0 {
		t := db.Exec("INSERT INTO sys_version (version_number, version) VALUES (?, ?)", 0, "0.0.0")
		if t.Error != nil {
			return t.Error
		}
	}

	if dataVersionNumber > global.VERSION_NUMBER {
		return fmt.Errorf("当前数据版本高于程序版本，请升级程序")
	} else if dataVersionNumber < global.VERSION_NUMBER {
		logrus.Infoln("数据版本：", dataVersionNumber)
		logrus.Infoln("程序版本：", global.VERSION_NUMBER)
		logrus.Infoln("开始升级...")

		// 每个SQL文件单独执行，失败记录但继续
		for i := dataVersionNumber + 1; i <= global.VERSION_NUMBER; i++ {
			fileName := fmt.Sprintf("sql/%d.sql", i)
			if !utils.FileExist(fileName) {
				return fmt.Errorf("sql文件不存在,可能需要手动升级：%s", fileName)
			}

			logrus.Infoln("执行sql文件：", fileName)
			sqlFile, err := os.ReadFile(fileName)
			if err != nil {
				return fmt.Errorf("读取sql文件失败 %s: %w", fileName, err)
			}

			// 直接执行整个SQL文件（保持DO块完整性）
			t := db.Exec(string(sqlFile))
			if t.Error != nil {
				// 检查是否是"已存在"类错误，忽略这些非致命错误
				errStr := t.Error.Error()
				if strings.Contains(errStr, "already exists") ||
					strings.Contains(errStr, "duplicate key") ||
					strings.Contains(errStr, "42P07") || // relation already exists
					strings.Contains(errStr, "42710") || // object already exists
					strings.Contains(errStr, "23505") { // unique_violation
					logrus.Warnf("SQL执行警告 [%s] (可忽略): %v", fileName, t.Error)
				} else {
					return fmt.Errorf("执行sql文件失败 %s: %w", fileName, t.Error)
				}
			}
		}

		// 更新版本号（使用事务保证原子性）
		tx := db.Begin()
		t := tx.Exec("UPDATE sys_version SET version_number = ?, version = ?", versionNumber, version)
		if t.Error != nil {
			tx.Rollback()
			return t.Error
		}
		if err := tx.Commit().Error; err != nil {
			return err
		}
		logrus.Infoln("升级成功")
	}
	return nil
}

func ExecuteSQLFile(db *gorm.DB, fileName string) error {
	// 读取 SQL 脚本文件
	sqlFile, err := os.ReadFile(fileName)
	if err != nil {
		return err
	}
	// 执行 SQL 脚本
	t := db.Exec(string(sqlFile))
	if t.Error != nil {
		return t.Error
	}

	return nil
}
