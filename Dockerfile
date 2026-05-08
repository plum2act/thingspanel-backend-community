# syntax=docker/dockerfile:1
FROM golang:alpine AS builder
WORKDIR $GOPATH/src/app

# 使用 GOPROXY 加速下载
ARG GOPROXY=https://goproxy.cn,direct
ENV GO111MODULE=on
ENV GOPROXY=$GOPROXY

# 复制依赖文件并下载
COPY go.mod go.sum ./
RUN go mod download

# 复制源码并构建
COPY . ./
RUN go build -o ThingsPanel-Go .

# 第二阶段：精简镜像
FROM alpine:latest
LABEL description="ThingsPanel Go Backend"

WORKDIR /go/src/app

# 安装时区数据
RUN apk update && apk add --no-cache tzdata

# 只复制必要的文件
COPY --from=builder /go/src/app/ThingsPanel-Go ./
COPY --from=builder /go/src/app/configs ./configs
COPY --from=builder /go/src/app/sql ./sql
COPY --from=builder /go/src/app/mqtt ./mqtt
COPY --from=builder /go/src/app/static ./static
COPY --from=builder /go/src/app/files ./files

# 设置权限
RUN chmod +x ThingsPanel-Go

EXPOSE 9999

ENTRYPOINT [ "./ThingsPanel-Go" ]