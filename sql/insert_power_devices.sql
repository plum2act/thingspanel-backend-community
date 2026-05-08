-- ============================================================
-- ThingsPanel 电力设备数据插入脚本
-- 对应协议: MQTT连接协议V0.0.4.md
--
-- 三种设备类型:
--   - 油浸变压器状态监测装置 (msgtype=221, device_type=0x8B)
--   - 物联版低压测控监测单元 (msgtype=222, device_type=0x84)
--   - 塑壳断路器智能附件     (msgtype=223, device_type=0x81)
--
-- 所有设备均为 MQTT 直连设备 (device_type=1)
--
-- 使用前:
--   1. 将 :TENANT_ID 占位符替换为系统实际的 tenant_id
--   2. 确保 MQTT service_plugin 已存在 (可通过 sql/14.sql 初始化)
--
-- 执行: psql -h <host> -U postgres -d ThingsPanel -f insert_power_devices.sql
-- 回滚: psql -h <host> -U postgres -d ThingsPanel -c "DELETE FROM ... " (见本文档末尾)
-- ============================================================

-- 设置租户ID (必须替换为实际值)
\set TENANT_ID 'd616bcbb'

BEGIN;

-- ============================================================
-- 第一部分: 设备模板 (device_templates)
-- type_key 用于在 ThingsPanel 内部标识设备类型
-- ============================================================

-- ---- 模板1: 油浸变压器状态监测装置 ----
INSERT INTO public.device_templates
    (id, name, description, tenant_id, created_at, updated_at, flag, label, path, type_key, brand, model_number)
VALUES
    ('tpl-oil-transformer-monitor',
     '油浸变压器状态监测装置',
     '油浸变压器状态监测装置，MQTT直连协议，监测油箱压力、油温、油位、开关量、继电器状态',
     :'TENANT_ID', NOW(), NOW(), 1,
     'power,transformer,oil-monitor',
     '',
     'oil_transformer_monitor',
     'KYDQ',
     'KYZHM870');

-- ---- 模板2: 物联版低压测控监测单元 ----
INSERT INTO public.device_templates
    (id, name, description, tenant_id, created_at, updated_at, flag, label, path, type_key, brand, model_number)
VALUES
    ('tpl-lvm-controller',
     '物联版低压测控监测单元',
     '物联版低压测控监测单元，MQTT直连协议，三相电力参数综合监测',
     :'TENANT_ID', NOW(), NOW(), 1,
     'power,lvm,low-voltage',
     '',
     'lvm_controller',
     'KYDQ',
     'KY-PWC-BM');

-- ---- 模板3: 塑壳断路器智能附件 ----
INSERT INTO public.device_templates
    (id, name, description, tenant_id, created_at, updated_at, flag, label, path, type_key, brand, model_number)
VALUES
    ('tpl-mccb-smart-attachment',
     '塑壳断路器智能附件',
     '塑壳断路器智能附件，MQTT直连协议，监测塑壳断路器状态、电能、谐波等参数',
     :'TENANT_ID', NOW(), NOW(), 1,
     'power,mccb,circuit-breaker',
     '',
     'mccb_smart_attachment',
     'KYDQ',
     'KYDQ-MCB1');

-- ============================================================
-- 第二部分: 物模型 - 遥测数据点 (device_model_telemetry)
-- data_identifier 与协议 JSON 字段名完全对应
-- ============================================================

-- ---- 油浸变压器: 15个遥测数据点 ----
INSERT INTO public.device_model_telemetry
    (id, device_template_id, data_name, data_identifier, read_write_flag, data_type, unit, description, created_at, updated_at, tenant_id)
VALUES
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '报文类型',     'msgtype',   'R', 'Number', '',    '固定值221',             NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '信号强度',     'csq',       'R', 'Number', '',    '信号强度 0-31',         NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '油箱压力',     'p_tank',    'R', 'Number', 'kPa', '油箱压力值',           NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '油顶温度',     't_oil',     'R', 'Number', '°C',  '油顶温度',             NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '油位状态',     'lvl_oil',   'R', 'Number', '',    '0正常 1油位低',         NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '油顶温度状态', 'st_t_oil',  'R', 'Number', '',    '0正常 1温度保护',       NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '油箱压力状态', 'st_p',       'R', 'Number', '',    '0正常 1压力保护',       NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '开关量输入1',  'dii1',       'R', 'Number', '',    '0断开 1闭合',           NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '开关量输入2',  'dii2',       'R', 'Number', '',    '0断开 1闭合',           NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '开关量输入3',  'dii3',       'R', 'Number', '',    '0断开 1闭合',           NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '开关量输入4',  'dii4',       'R', 'Number', '',    '0断开 1闭合',           NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '开关量输出1',  'dio1',       'R', 'Number', '',    '0断开 1闭合',           NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '开关量输出2',  'dio2',       'R', 'Number', '',    '0断开 1闭合',           NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '继电器1状态',  'relay1',     'RW','Number', '',    '0断开 1闭合',           NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '继电器2状态',  'relay2',     'RW','Number', '',    '0断开 1闭合',           NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '控制模式',    'ctl_mode',   'RW','Number', '',    '00当地 01远方',         NOW(), NOW(), :'TENANT_ID');

-- ---- 物联版低压测控监测单元: 22个遥测数据点 ----
INSERT INTO public.device_model_telemetry
    (id, device_template_id, data_name, data_identifier, read_write_flag, data_type, unit, description, created_at, updated_at, tenant_id)
VALUES
    (gen_random_uuid(), 'tpl-lvm-controller', '报文类型',     'msgtype',   'R', 'Number', '',    '固定值222',              NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '信号强度',     'csq',       'R', 'Number', '',    '信号强度 0-31',          NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'A相电压',     'UAA',       'R', 'Number', 'V',   'A相电压',                NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'B相电压',     'UBB',       'R', 'Number', 'V',   'B相电压',                NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'C相电压',     'UCC',       'R', 'Number', 'V',   'C相电压',                NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'AB线电压',    'UAB',       'R', 'Number', 'V',   'AB线电压',               NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'BC线电压',    'UBC',       'R', 'Number', 'V',   'BC线电压',               NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'CA线电压',    'UCA',       'R', 'Number', 'V',   'CA线电压',               NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'A相电流',     'IAA',       'R', 'Number', 'A',   'A相电流',                NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'B相电流',     'IBB',       'R', 'Number', 'A',   'B相电流',                NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'C相电流',     'ICC',       'R', 'Number', 'A',   'C相电流',                NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '总有功功率',  'totp',      'R', 'Number', 'kW',  '总有功功率',             NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '总无功功率',  'totq',      'R', 'Number', 'kvar', '总无功功率',             NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '总视在功率',  'tots',      'R', 'Number', 'kVA',  '总视在功率',             NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '总功率因数',  'totpf',     'R', 'Number', '',    '总功率因数',             NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '电网频率',    'freq',      'R', 'Number', 'Hz',  '电网频率',               NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'TA温度',      'TAA',       'R', 'Number', '°C',  'TA温度',                 NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'TB温度',      'TBB',       'R', 'Number', '°C',  'TB温度',                 NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'TC温度',      'TCC',       'R', 'Number', '°C',  'TC温度',                 NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'IA相总谐波畸变率', 'ia_thd', 'R', 'Number', '%',  'IA相总谐波畸变率',       NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'IB相总谐波畸变率', 'ib_thd', 'R', 'Number', '%',  'IB相总谐波畸变率',       NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'IC相总谐波畸变率', 'ic_thd', 'R', 'Number', '%',  'IC相总谐波畸变率',       NOW(), NOW(), :'TENANT_ID');

-- ---- 塑壳断路器智能附件: 17个遥测数据点 ----
INSERT INTO public.device_model_telemetry
    (id, device_template_id, data_name, data_identifier, read_write_flag, data_type, unit, description, created_at, updated_at, tenant_id)
VALUES
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '报文类型',         'msgtype',   'R', 'Number', '',    '固定值223',              NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '信号强度',         'csq',       'R', 'Number', '',    '信号强度 0-31',          NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', 'A相电压',         'vol_a',     'R', 'Number', 'V',   'A相电压',                NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', 'B相电压',         'vol_b',     'R', 'Number', 'V',   'B相电压',                NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', 'C相电压',         'vol_c',     'R', 'Number', 'V',   'C相电压',                NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', 'A相电流',         'cur_a',     'R', 'Number', 'A',   'A相电流',                NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', 'B相电流',         'cur_b',     'R', 'Number', 'A',   'B相电流',                NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', 'C相电流',         'cur_c',     'R', 'Number', 'A',   'C相电流',                NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '瞬时总有功功率',   'p_tot',     'R', 'Number', 'kW',  '瞬时总有功功率',         NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '瞬时总无功功率',   'q_tot',     'R', 'Number', 'kvar', '瞬时总无功功率',         NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '瞬时总视在功率',   's_tot',     'R', 'Number', 'kVA', '瞬时总视在功率',         NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '总功率因数',       'pf_tot',    'R', 'Number', '',    '总功率因数',             NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '电网频率',         'f_grid',    'R', 'Number', 'Hz',  '电网频率',               NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '当前组合有功总电能', 'e_act',   'R', 'Number', 'kWh', '当前组合有功总电能',     NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '当前正向有功总电能', 'e_fwd',   'R', 'Number', 'kWh', '当前正向有功总电能',     NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '当前闸位状态',     'sw_pos',    'R', 'Number', '',    '0合闸 1分闸',            NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '跳闸原因',         'trip_rsn',  'R', 'Number', '',    '0正常 1-31故障代码',    NOW(), NOW(), :'TENANT_ID');

-- ============================================================
-- 第三部分: 物模型 - 属性 (device_model_attributes)
-- ============================================================

-- ---- 油浸变压器: 5个属性 ----
INSERT INTO public.device_model_attributes
    (id, device_template_id, data_name, data_identifier, read_write_flag, data_type, unit, description, created_at, updated_at, tenant_id)
VALUES
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '实物编码',   'oil_id',  'R', 'String', '', '设备唯一身份编码',          NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '厂商简称',   'oil_ent', 'R', 'String', '', '公司英文简称',              NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '设备型号',   'oil_mod', 'R', 'String', '', '供货设备型号',              NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '软件版本',   'oil_sw',  'R', 'String', '', '格式V01.02.33',            NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '硬件版本',   'oil_hw',  'R', 'String', '', '硬件版本号',               NOW(), NOW(), :'TENANT_ID');

-- ---- 物联版低压测控监测单元: 7个属性 ----
INSERT INTO public.device_model_attributes
    (id, device_template_id, data_name, data_identifier, read_write_flag, data_type, unit, description, created_at, updated_at, tenant_id)
VALUES
    (gen_random_uuid(), 'tpl-lvm-controller', '实物编码',   'lvm_id',  'R', 'String', '', '设备唯一身份编码',          NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '厂商简称',   'lvm_ent', 'R', 'String', '', '公司英文简称',              NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '设备型号',   'lvm_mod', 'R', 'String', '', '供货设备型号',              NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '软件版本',   'lvm_sw',  'R', 'String', '', '格式V01.02.33',            NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '硬件版本',   'lvm_hw',  'R', 'String', '', '硬件版本号',               NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '接线方式',   'wmod',    'RW','Number', '', '0三相四线 1三相三线',       NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '变比',       'ratio',   'RW','Number', '', '变比',                     NOW(), NOW(), :'TENANT_ID');

-- ---- 塑壳断路器智能附件: 6个属性 ----
INSERT INTO public.device_model_attributes
    (id, device_template_id, data_name, data_identifier, read_write_flag, data_type, unit, description, created_at, updated_at, tenant_id)
VALUES
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '实物编码',      'lvi_id',    'R', 'String', '', '设备唯一身份编码',    NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '厂商简称',      'lvi_ent',   'R', 'String', '', '公司英文简称',        NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '设备型号',      'lvi_mod',   'R', 'String', '', '供货设备型号',        NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '软件版本',      'lvi_sw',    'R', 'String', '', '格式V01.02.33',      NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '硬件版本',      'lvi_hw',    'R', 'String', '', '硬件版本号',         NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '电流互感器变比', 'ct_ratio', 'RW','Number', '', '电流互感器变比',     NOW(), NOW(), :'TENANT_ID');

-- ============================================================
-- 第四部分: 物模型 - 命令 (device_model_commands)
-- msgtype 对应协议控制指令报文类型
-- ============================================================

-- ---- 油浸变压器: 7个命令 (msgtype=242) ----
INSERT INTO public.device_model_commands
    (id, device_template_id, data_name, data_identifier, params, description, created_at, updated_at, tenant_id)
VALUES
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '参数复位', 'param_reset', '{}'::jsonb, '油箱参数复位', NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '设备重启', 'dev_reboot',  '{}'::jsonb, '设备重启',     NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '油顶温度保护值', 'prot_t_oil', '{"type":"Number","unit":"°C"}'::jsonb, '设置温度保护阈值', NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '压力保护值',   'prot_p',     '{"type":"Number","unit":"kPa"}'::jsonb, '设置压力保护阈值', NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '继电器1控制', 'relay1',      '{"type":"Number","enum":[0,1]}'::jsonb, '0断开 1闭合', NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '继电器2控制', 'relay2',      '{"type":"Number","enum":[0,1]}'::jsonb, '0断开 1闭合', NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-oil-transformer-monitor', '控制模式',     'ctl_mode',   '{"type":"Number","enum":[0,1]}'::jsonb, '00当地 01远方', NOW(), NOW(), :'TENANT_ID');

-- ---- 物联版低压测控监测单元: 9个命令 (msgtype=243) ----
INSERT INTO public.device_model_commands
    (id, device_template_id, data_name, data_identifier, params, description, created_at, updated_at, tenant_id)
VALUES
    (gen_random_uuid(), 'tpl-lvm-controller', '额定电流',       'irate',      '{"type":"Number","unit":"mA"}'::jsonb,   '设置额定电流',         NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '最大电流',       'imax',       '{"type":"Number","unit":"mA"}'::jsonb,   '设置最大电流',         NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '接线方式',      'wmod',       '{"type":"Number","enum":[0,1]}'::jsonb, '0三相四线 1三相三线',   NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '变比',          'ratio',      '{"type":"Number"}'::jsonb,              '设置变比',             NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '过压保护',      'uoverset',   '{"type":"Number","unit":"1%Un"}'::jsonb,'设置过压保护值',       NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '低压保护',      'uunderset', '{"type":"Number","unit":"1%Un"}'::jsonb,'设置低压保护值',       NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', '过温预警',      'twarnset',   '{"type":"Number","unit":"0.1°C"}'::jsonb,'设置过温预警值',       NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'DO1动作执行',  'd1actexe',   '{"type":"Number"}'::jsonb,              '执行DO1动作',          NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-lvm-controller', 'DO2动作执行',  'd2actexe',   '{"type":"Number"}'::jsonb,              '执行DO2动作',          NOW(), NOW(), :'TENANT_ID');

-- ---- 塑壳断路器智能附件: 6个命令 (msgtype=244) ----
INSERT INTO public.device_model_commands
    (id, device_template_id, data_name, data_identifier, params, description, created_at, updated_at, tenant_id)
VALUES
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '断零保护',   'en_nbrk',   '{"type":"Number","enum":[0,1,2]}'::jsonb, '00不投入 01投入保护 10投入告警', NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '缺相保护',   'en_miss',   '{"type":"Number","enum":[0,1,2]}'::jsonb, '00不投入 01投入保护 10投入告警', NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '低压保护',   'en_uv',     '{"type":"Number","enum":[0,1,2]}'::jsonb, '00不投入 01投入保护 10投入告警', NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '过压保护',   'en_ov',     '{"type":"Number","enum":[0,1,2]}'::jsonb, '00不投入 01投入保护 10投入告警', NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '分合闸控制', 'sw_ctl',    '{"type":"String","hex":"0x5555分闸 0xAAAA合闸"}'::jsonb, '0x5555分闸 0xAAAA合闸', NOW(), NOW(), :'TENANT_ID'),
    (gen_random_uuid(), 'tpl-mccb-smart-attachment', '设备复位',   'dev_reset', '{}'::jsonb,                            '复位设备',              NOW(), NOW(), :'TENANT_ID');

-- ============================================================
-- 第五部分: 设备配置 (device_configs)
-- device_type='1' 表示直连设备, protocol_type='MQTT'
-- ============================================================

-- 确认 MQTT service_plugin 已存在
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM public.service_plugins WHERE service_identifier = 'MQTT') THEN
        RAISE NOTICE 'MQTT service_plugin not found, please ensure it is initialized';
    END IF;
END $$;

-- ---- 油浸变压器设备配置 ----
INSERT INTO public.device_configs
    (id, name, device_template_id, device_type, protocol_type, voucher_type,
     device_conn_type, tenant_id, created_at, updated_at, protocol_config, additional_info)
VALUES
    ('cfg-oil-transformer-monitor',
     '油浸变压器配置（MQTT直连）',
     'tpl-oil-transformer-monitor',
     '1',              -- 直连设备
     'MQTT',
     'username_password',
     'A',              -- 设备连接平台
     :'TENANT_ID', NOW(), NOW(),
     '{"broker":"tcp://localhost:1883","client_id":"${device_id}","username":"${username}","password":"${password}","qos":1}'::jsonb,
     '{}'::jsonb);

-- ---- 物联版低压测控监测单元设备配置 ----
INSERT INTO public.device_configs
    (id, name, device_template_id, device_type, protocol_type, voucher_type,
     device_conn_type, tenant_id, created_at, updated_at, protocol_config, additional_info)
VALUES
    ('cfg-lvm-controller',
     '低压测控监测单元配置（MQTT直连）',
     'tpl-lvm-controller',
     '1',              -- 直连设备
     'MQTT',
     'username_password',
     'A',
     :'TENANT_ID', NOW(), NOW(),
     '{"broker":"tcp://localhost:1883","client_id":"${device_id}","username":"${username}","password":"${password}","qos":1}'::jsonb,
     '{}'::jsonb);

-- ---- 塑壳断路器智能附件设备配置 ----
INSERT INTO public.device_configs
    (id, name, device_template_id, device_type, protocol_type, voucher_type,
     device_conn_type, tenant_id, created_at, updated_at, protocol_config, additional_info)
VALUES
    ('cfg-mccb-smart-attachment',
     '塑壳断路器智能附件配置（MQTT直连）',
     'tpl-mccb-smart-attachment',
     '1',              -- 直连设备
     'MQTT',
     'username_password',
     'A',
     :'TENANT_ID', NOW(), NOW(),
     '{"broker":"tcp://localhost:1883","client_id":"${device_id}","username":"${username}","password":"${password}","qos":1}'::jsonb,
     '{}'::jsonb);

-- ============================================================
-- 第六部分: 设备实例 (devices)
-- 每个设备类型插入一个示例设备实例用于验证
-- ============================================================

-- ---- 油浸变压器设备实例 ----
INSERT INTO public.devices
    (id, name, voucher, tenant_id, is_enabled, activate_flag,
     created_at, update_at, device_number, protocol, device_config_id,
     access_way, description, location, label)
VALUES
    ('dev-oil-monitor-001',
     '1#主变油浸变压器监测装置',
     '{"username":"oil001","password":"Oil@2024!"}'::jsonb,
     :'TENANT_ID', 'enabled', 'active',
     NOW(), NOW(),
     'OIL-001',
     'MQTT',
     'cfg-oil-transformer-monitor',
     'A',
     '1#主变油浸变压器油温、油压、油位综合监测',
     '1#主变配电间',
     'power,transformer,oil');

-- ---- 物联版低压测控监测单元设备实例 ----
INSERT INTO public.devices
    (id, name, voucher, tenant_id, is_enabled, activate_flag,
     created_at, update_at, device_number, protocol, device_config_id,
     access_way, description, location, label)
VALUES
    ('dev-lvm-001',
     '2#楼层低压测控监测单元',
     '{"username":"lvm001","password":"Lvm@2024!"}'::jsonb,
     :'TENANT_ID', 'enabled', 'active',
     NOW(), NOW(),
     'LVM-001',
     'MQTT',
     'cfg-lvm-controller',
     'A',
     '2#楼层低压配电柜三相电力参数监测',
     '2#楼层配电间',
     'power,low-voltage,lvm');

-- ---- 塑壳断路器智能附件设备实例 ----
INSERT INTO public.devices
    (id, name, voucher, tenant_id, is_enabled, activate_flag,
     created_at, update_at, device_number, protocol, device_config_id,
     access_way, description, location, label)
VALUES
    ('dev-mccb-001',
     '2#楼层照明箱塑壳断路器',
     '{"username":"mccb001","password":"Mccb@2024!"}'::jsonb,
     :'TENANT_ID', 'enabled', 'active',
     NOW(), NOW(),
     'MCCB-001',
     'MQTT',
     'cfg-mccb-smart-attachment',
     'A',
     '2#楼层照明箱塑壳断路器状态及电能监测',
     '2#楼层照明配电间',
     'power,mccb,lighting');

-- ============================================================
-- 第七部分: 设备分组 (groups)
-- 创建电力设备分组结构
-- ============================================================

-- 电力设备根分组
INSERT INTO public.groups (id, parent_id, tier, name, description, created_at, updated_at, tenant_id, remark)
VALUES ('grp-power-equipment', '0', 1, '电力设备', '所有电力监测设备', NOW(), NOW(), :'TENANT_ID', 'auto-created')
ON CONFLICT DO NOTHING;

-- 油浸变压器分组
INSERT INTO public.groups (id, parent_id, tier, name, description, created_at, updated_at, tenant_id, remark)
VALUES ('grp-oil-transformer', 'grp-power-equipment', 2, '油浸变压器', '油浸变压器状态监测装置', NOW(), NOW(), :'TENANT_ID', 'auto-created')
ON CONFLICT DO NOTHING;

-- 低压测控分组
INSERT INTO public.groups (id, parent_id, tier, name, description, created_at, updated_at, tenant_id, remark)
VALUES ('grp-lvm-controller', 'grp-power-equipment', 2, '低压测控', '物联版低压测控监测单元', NOW(), NOW(), :'TENANT_ID', 'auto-created')
ON CONFLICT DO NOTHING;

-- 塑壳断路器分组
INSERT INTO public.groups (id, parent_id, tier, name, description, created_at, updated_at, tenant_id, remark)
VALUES ('grp-mccb', 'grp-power-equipment', 2, '塑壳断路器', '塑壳断路器智能附件', NOW(), NOW(), :'TENANT_ID', 'auto-created')
ON CONFLICT DO NOTHING;

-- ============================================================
-- 第八部分: 设备-分组关联 (r_group_device)
-- ============================================================

INSERT INTO public.r_group_device (group_id, device_id, tenant_id)
VALUES ('grp-oil-transformer', 'dev-oil-monitor-001', :'TENANT_ID')
ON CONFLICT DO NOTHING;

INSERT INTO public.r_group_device (group_id, device_id, tenant_id)
VALUES ('grp-lvm-controller', 'dev-lvm-001', :'TENANT_ID')
ON CONFLICT DO NOTHING;

INSERT INTO public.r_group_device (group_id, device_id, tenant_id)
VALUES ('grp-mccb', 'dev-mccb-001', :'TENANT_ID')
ON CONFLICT DO NOTHING;

COMMIT;

-- ============================================================
-- 验证查询 (可注释掉)
-- ============================================================

-- SELECT '=== 设备模板 ===' AS info;
-- SELECT id, name, type_key FROM public.device_templates WHERE tenant_id = :'TENANT_ID';

-- SELECT '=== 物模型遥测数据点统计 ===' AS info;
-- SELECT dt.name, COUNT(dmt.id) as telemetry_count
-- FROM public.device_templates dt
-- LEFT JOIN public.device_model_telemetry dmt ON dt.id = dmt.device_template_id
-- WHERE dt.tenant_id = :'TENANT_ID'
-- GROUP BY dt.id, dt.name;

-- SELECT '=== 设备配置 ===' AS info;
-- SELECT id, name, device_type, protocol_type FROM public.device_configs WHERE tenant_id = :'TENANT_ID';

-- SELECT '=== 设备实例 ===' AS info;
-- SELECT id, name, device_number, device_config_id FROM public.devices WHERE tenant_id = :'TENANT_ID';

-- ============================================================
-- 回滚语句 (需要时单独执行)
-- ============================================================
--
-- BEGIN;
-- -- 删除设备-分组关联
-- DELETE FROM public.r_group_device WHERE device_id IN ('dev-oil-monitor-001','dev-lvm-001','dev-mccb-001');
-- -- 删除设备实例
-- DELETE FROM public.devices WHERE id IN ('dev-oil-monitor-001','dev-lvm-001','dev-mccb-001');
-- -- 删除设备配置
-- DELETE FROM public.device_configs WHERE id IN ('cfg-oil-transformer-monitor','cfg-lvm-controller','cfg-mccb-smart-attachment');
-- -- 删除命令定义
-- DELETE FROM public.device_model_commands WHERE device_template_id IN ('tpl-oil-transformer-monitor','tpl-lvm-controller','tpl-mccb-smart-attachment');
-- -- 删除属性定义
-- DELETE FROM public.device_model_attributes WHERE device_template_id IN ('tpl-oil-transformer-monitor','tpl-lvm-controller','tpl-mccb-smart-attachment');
-- -- 删除遥测数据点
-- DELETE FROM public.device_model_telemetry WHERE device_template_id IN ('tpl-oil-transformer-monitor','tpl-lvm-controller','tpl-mccb-smart-attachment');
-- -- 删除设备模板
-- DELETE FROM public.device_templates WHERE id IN ('tpl-oil-transformer-monitor','tpl-lvm-controller','tpl-mccb-smart-attachment');
-- -- 删除分组 (注意: 会受 ON DELETE CASCADE 影响)
-- DELETE FROM public.groups WHERE id IN ('grp-oil-transformer','grp-lvm-controller','grp-mccb','grp-power-equipment');
-- COMMIT;
