# YSHOP 意象点餐系统 - Ubuntu 服务器部署指南

## 📋 目录

- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [详细步骤](#详细步骤)
- [常见问题](#常见问题)
- [服务管理](#服务管理)

---

## 🎯 环境要求

### 系统要求
- **操作系统**: Ubuntu 20.04 LTS 或更高版本
- **内存**: 至少 4GB RAM（推荐 8GB+）
- **磁盘**: 至少 20GB 可用空间
- **网络**: 稳定的网络连接

### 软件要求
脚本会自动检查并安装以下软件：
- OpenJDK 17
- Maven 3.8+
- Node.js 18 LTS
- pnpm
- Docker 和 Docker Compose

---

## 🚀 快速开始

### 方式1：一键启动（推荐）

```bash
# 1. 进入项目目录
cd /path/to/yshop-drink

# 2. 给脚本添加执行权限
chmod +x start-server.sh stop-server.sh

# 3. 运行启动脚本
./start-server.sh
```

脚本会自动完成：
- ✅ 环境检查和安装
- ✅ 配置国内镜像源
- ✅ 启动 MySQL 和 Redis 容器
- ✅ 编译并启动后端服务
- ✅ 启动管理界面前端

### 方式2：Docker 快速启动

```bash
# 仅启动 MySQL 和 Redis
docker compose up -d
```

---

## 📖 详细步骤

### 步骤1：下载项目

```bash
# 克隆项目（如果还没有下载）
git clone https://gitee.com/guchengwuyue/yshop-drink.git
cd yshop-drink
```

### 步骤2：配置镜像源（可选，脚本会自动配置）

#### Maven 阿里云镜像

创建或编辑 `~/.m2/settings.xml`：

```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0">
    <mirrors>
        <mirror>
            <id>aliyunmaven</id>
            <mirrorOf>*</mirrorOf>
            <name>阿里云公共仓库</name>
            <url>https://maven.aliyun.com/repository/public</url>
        </mirror>
    </mirrors>
</settings>
```

#### npm/pnpm 淘宝镜像

```bash
npm config set registry https://registry.npmmirror.com
pnpm config set registry https://registry.npmmirror.com
```

#### Docker 阿里云镜像

编辑 `/etc/docker/daemon.json`：

```json
{
    "registry-mirrors": [
        "https://mirror.ccs.tencentyun.com",
        "https://docker.mirrors.ustc.edu.cn"
    ]
}
```

然后重启 Docker：

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

### 步骤3：运行启动脚本

```bash
./start-server.sh
```

**首次运行时间**：
- 环境安装：5-10 分钟（如果需要）
- Docker 镜像下载：5-10 分钟
- 后端编译：5-10 分钟
- 前端依赖安装：3-5 分钟

**总计**：首次部署约 20-30 分钟

### 步骤4：访问系统

启动完成后，访问：

**管理后台**:
- 地址：http://服务器IP:80
- 账号：admin
- 密码：admin123

**后端API**:
- 地址：http://服务器IP:48081

---

## 🔧 服务管理

### 启动服务

```bash
./start-server.sh
```

### 停止服务

```bash
./stop-server.sh
```

### 查看服务状态

```bash
# 查看 Docker 容器状态
docker ps

# 查看后端日志
tail -f ~/logs/yshop-server.log

# 查看前端日志
tail -f ~/logs/yshop-frontend.log

# 查看后端进程
ps aux | grep yshop-server

# 查看前端进程
ps aux | grep vite
```

### 重启服务

```bash
# 重启后端
./stop-server.sh
./start-server.sh
```

### 手动启动服务

#### 启动 Docker 容器

```bash
docker compose up -d
```

#### 手动编译后端

```bash
cd yshop-drink-boot3
mvn clean install package -Dmaven.test.skip=true
```

#### 手动启动后端

```bash
cd yshop-drink-boot3/yshop-server/target
java -jar yshop-server-*.jar --spring.profiles.active=local
```

#### 手动启动前端

```bash
cd yshop-drink-vue3
pnpm install
pnpm run dev
```

---

## ⚠️ 常见问题

### 问题1：端口被占用

**错误信息**：
```
Port 48081 is already in use
```

**解决方法**：

```bash
# 查找占用端口的进程
sudo lsof -i :48081

# 杀死进程
sudo kill -9 <PID>

# 或者修改配置文件中的端口
```

### 问题2：Docker 权限不足

**错误信息**：
```
permission denied while trying to connect to the Docker daemon socket
```

**解决方法**：

```bash
# 将当前用户添加到 docker 组
sudo usermod -aG docker $USER

# 重新登录或运行
newgrp docker

# 重启 Docker
sudo systemctl restart docker
```

### 问题3：Maven 编译失败

**错误信息**：
```
Failed to execute goal ... Could not resolve dependencies
```

**解决方法**：

```bash
# 清理 Maven 缓存
rm -rf ~/.m2/repository

# 重新编译
cd yshop-drink-boot3
mvn clean install -U
```

### 问题4：前端依赖安装失败

**错误信息**：
```
ERR_PNPM_NO_MATCHING_VERSION
```

**解决方法**：

```bash
# 清理缓存
cd yshop-drink-vue3
rm -rf node_modules pnpm-lock.yaml

# 重新安装
pnpm install
```

### 问题5：MySQL 连接失败

**错误信息**：
```
Unable to connect to MySQL
```

**解决方法**：

```bash
# 检查 MySQL 容器状态
docker ps | grep mysql

# 查看 MySQL 日志
docker logs yshop-mysql

# 重启 MySQL 容器
docker restart yshop-mysql

# 等待 MySQL 完全启动
sleep 10
```

### 问题6：内存不足

**症状**：服务启动缓慢或失败

**解决方法**：

```bash
# 检查内存使用
free -h

# 如果内存不足，可以：
# 1. 增加交换空间
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 2. 限制 Java 堆内存
java -Xmx1g -Xms512m -jar yshop-server-*.jar
```

---

## 🔐 安全配置

### 修改默认密码

#### 1. 修改数据库密码

编辑 `docker-compose.yml`：

```yaml
services:
  mysql:
    environment:
      MYSQL_ROOT_PASSWORD: your_secure_password
```

同时修改 `application-local.yaml` 中的密码。

#### 2. 修改 Redis 密码

编辑 `docker-compose.yml`：

```yaml
services:
  redis:
    command: redis-server --requirepass your_secure_password
```

同时修改 `application-local.yaml` 中的密码。

### 防火墙配置

```bash
# 开放必要的端口
sudo ufw allow 80/tcp    # 前端
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 48081/tcp # 后端 API

# 启用防火墙
sudo ufw enable
```

---

## 📊 性能优化

### 1. JVM 优化

编辑启动脚本，添加 JVM 参数：

```bash
java -jar yshop-server-*.jar \
    -Xms2g \
    -Xmx2g \
    -XX:+UseG1GC \
    -XX:MaxGCPauseMillis=200 \
    --spring.profiles.active=local
```

### 2. 数据库优化

编辑 `docker-compose.yml`：

```yaml
services:
  mysql:
    command: --max_connections=1000 --innodb_buffer_pool_size=1G
```

### 3. Redis 优化

编辑 `docker-compose.yml`：

```yaml
services:
  redis:
    command: redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru
```

---

## 🚀 生产环境部署

### 1. 使用 Nginx 反向代理

安装 Nginx：

```bash
sudo apt-get install -y nginx
```

配置 Nginx（`/etc/nginx/sites-available/yshop`）：

```nginx
server {
    listen 80;
    server_name yourdomain.com;

    # 前端
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # 后端 API
    location /app-api/ {
        proxy_pass http://localhost:48081/app-api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location /admin-api/ {
        proxy_pass http://localhost:48081/admin-api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

启用配置：

```bash
sudo ln -s /etc/nginx/sites-available/yshop /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 2. 配置 HTTPS（使用 Let's Encrypt）

```bash
# 安装 Certbot
sudo apt-get install -y certbot python3-certbot-nginx

# 获取证书
sudo certbot --nginx -d yourdomain.com

# 自动续期
sudo systemctl enable certbot.timer
```

### 3. 配置 Systemd 服务

创建服务文件 `/etc/systemd/system/yshop-backend.service`：

```ini
[Unit]
Description=YSHOP Backend Service
After=docker.service
Requires=docker.service

[Service]
Type=simple
User=your_username
WorkingDirectory=/path/to/yshop-drink/yshop-drink-boot3/yshop-server/target
ExecStart=/usr/bin/java -jar yshop-server-*.jar --spring.profiles.active=local
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

启用服务：

```bash
sudo systemctl daemon-reload
sudo systemctl enable yshop-backend
sudo systemctl start yshop-backend
```

---

## 📝 日志管理

### 查看日志

```bash
# 后端日志
tail -f ~/logs/yshop-server.log

# 前端日志
tail -f ~/logs/yshop-frontend.log

# Docker 日志
docker logs -f yshop-mysql
docker logs -f yshop-redis
```

### 日志轮转

创建 logrotate 配置 `/etc/logrotate.d/yshop`：

```
/home/*/logs/yshop-*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0644 user user
    sharedscripts
}
```

---

## 🆘 技术支持

- **官网**: https://www.yixiang.co/
- **QQ群**: 544263002
- **文档**: 项目 README.md

---

## 📜 许可证

MIT License - 100% 免费使用

---

**祝您部署顺利！🎉**

