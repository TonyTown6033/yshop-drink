# 🖥️ 服务器部署指南

## 🎉 CI/CD 已跑通！现在部署到服务器

### 前提条件

- ✅ GitHub Actions 构建成功
- ✅ GitHub Release 已创建
- ✅ 部署包已上传

---

## 🚀 快速部署（3步）

### 步骤1：准备服务器

```bash
# SSH 到服务器
ssh user@your-server

# 进入项目目录（如果还没有克隆）
cd /path/to/
git clone https://github.com/YOUR_USERNAME/yshop-drink.git
cd yshop-drink

# 如果已经克隆，拉取最新代码
cd /path/to/yshop-drink
git pull
```

### 步骤2：一键部署

```bash
# 自动下载并部署最新版本
sudo ./start-server.sh --github-release

# 或指定版本
sudo ./start-server.sh --github-release v1.0.0
```

### 步骤3：验证部署

```bash
# 检查服务状态
docker ps
sudo lsof -i :48081
sudo lsof -i :80

# 访问服务
curl http://localhost:48081/admin-api/system/health
curl http://localhost:80

# 查看日志
tail -f ~/logs/yshop-server.log
```

---

## 📋 详细步骤

### 1. 服务器环境准备

#### 1.1 安装 Docker

```bash
# 如果还没有 Docker
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

# 启动 Docker
sudo systemctl start docker
sudo systemctl enable docker

# 验证
docker --version
docker compose version
```

#### 1.2 安装 JDK 17

```bash
# 安装 OpenJDK 17
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk

# 验证
java -version
```

#### 1.3 克隆项目

```bash
# 克隆项目
cd ~
git clone https://github.com/YOUR_USERNAME/yshop-drink.git
cd yshop-drink

# 或者从私有仓库克隆
git clone https://YOUR_TOKEN@github.com/YOUR_USERNAME/yshop-drink.git
```

---

### 2. 配置文件准备

#### 2.1 后端配置

编辑 `yshop-drink-boot3/yshop-server/src/main/resources/application-local.yaml`：

```yaml
# 修改关键配置
server:
  port: 48081

spring:
  datasource:
    url: jdbc:mysql://localhost:3306/yixiang-drink
    username: root
    password: root123456
  
  data:
    redis:
      host: localhost
      port: 6379
      password: redis123456

# 配置微信小程序（如果需要）
yshop:
  weixin:
    mini-app:
      appid: YOUR_APPID
      secret: YOUR_SECRET
```

#### 2.2 前端配置（可选）

编辑 `yshop-drink-vue3/.env.local`：

```bash
# 后端 API 地址
VITE_BASE_URL=http://your-server-ip:48081
```

---

### 3. 部署

#### 3.1 自动部署（推荐）✨

```bash
# 进入项目目录
cd /path/to/yshop-drink

# 一键部署最新版本
sudo ./start-server.sh --github-release
```

脚本会自动：
1. ✅ 从 GitHub 获取最新版本
2. ✅ 下载部署包
3. ✅ 验证文件完整性（SHA256）
4. ✅ 解压并复制文件
5. ✅ 启动 Docker 容器（MySQL、Redis）
6. ✅ 导入数据库（首次）
7. ✅ 启动后端服务
8. ✅ 启动前端服务

#### 3.2 指定版本部署

```bash
# 部署指定版本
sudo ./start-server.sh --github-release v1.0.0

# 部署其他版本（回滚）
sudo ./start-server.sh --github-release v0.9.9
```

#### 3.3 手动下载部署

如果网络问题无法自动下载：

```bash
# 1. 手动下载
wget https://github.com/YOUR_USERNAME/yshop-drink/releases/download/v1.0.0/yshop-deploy-v1.0.0.tar.gz

# 2. 验证（可选）
wget https://github.com/YOUR_USERNAME/yshop-drink/releases/download/v1.0.0/yshop-deploy-v1.0.0.tar.gz.sha256
sha256sum -c yshop-deploy-v1.0.0.tar.gz.sha256

# 3. 解压
tar -xzf yshop-deploy-v1.0.0.tar.gz

# 4. 复制文件
cp backend/yshop-server*.jar yshop-drink-boot3/yshop-server/target/
cp -r frontend/dist-prod yshop-drink-vue3/

# 5. 启动服务
sudo ./start-server.sh --skip-build --prod-frontend
```

---

## 🔍 部署过程详解

### 阶段1：下载部署包

```
[INFO] 下载 GitHub Release...
[INFO] 最新版本: v1.0.0
[INFO] 下载地址: https://github.com/.../yshop-deploy-v1.0.0.tar.gz
[INFO] 下载部署包...
[SUCCESS] 下载完成
[INFO] 验证文件完整性...
[SUCCESS] 文件校验通过
```

### 阶段2：解压并复制

```
[INFO] 解压部署包...
[INFO] 复制文件到项目目录...
[SUCCESS] 后端文件已复制: yshop-server-2.9.jar
[SUCCESS] 前端文件已复制
[INFO] 版本信息:
  Version: v1.0.0
  Build Date: 2025-11-25 10:00:00
  Commit: abc123...
```

### 阶段3：启动 Docker

```
[INFO] 检查并清理端口占用...
[SUCCESS] 端口检查完成
[INFO] 启动 MySQL 容器...
[INFO] 等待 MySQL 启动...
[SUCCESS] MySQL 容器启动成功
[INFO] 启动 Redis 容器...
[SUCCESS] Redis 容器启动成功
```

### 阶段4：导入数据库（首次）

```
[INFO] 检查数据库是否已有数据...
[WARNING] 数据库为空，开始导入数据...
[INFO] 正在导入 SQL 数据...
[SUCCESS] 数据库导入成功
[INFO] 数据库表数量: 85
```

### 阶段5：启动后端

```
[INFO] 使用已编译的 jar 文件（跳过编译）
[INFO] jar 文件: yshop-server-2.9.jar
[INFO] 文件大小: 50M
[INFO] 启动后端服务...
[INFO] 后端进程 PID: 12345
[INFO] 等待后端服务就绪...
[SUCCESS] 后端服务启动成功
[INFO] 后端地址: http://localhost:48081
```

### 阶段6：启动前端

```
[INFO] 使用生产构建（dist-prod 目录）
[INFO] 启动静态文件服务器...
[INFO] 前端进程 PID: 12346
[SUCCESS] 前端服务启动成功（生产模式）
[INFO] 前端地址: http://localhost:80
```

### 完成

```
========================================
🎉 启动成功！
========================================

管理后台: http://localhost:80
默认账号: admin
默认密码: admin123

后端API: http://localhost:48081

数据库信息:
  主机: localhost:3306
  用户: root
  密码: root123456
  数据库: yixiang-drink

Redis信息:
  主机: localhost:6379
  密码: redis123456
```

---

## 🔧 服务管理

### 查看服务状态

```bash
# Docker 容器
docker ps

# 后端服务
sudo lsof -i :48081

# 前端服务
sudo lsof -i :80

# 查看 PID
cat ~/logs/backend.pid
cat ~/logs/frontend.pid
```

### 查看日志

```bash
# 后端日志
tail -f ~/logs/yshop-server.log

# 前端日志
tail -f ~/logs/yshop-frontend.log

# 实时监控（多窗口）
tail -f ~/logs/yshop-server.log ~/logs/yshop-frontend.log
```

### 停止服务

```bash
# 停止所有服务
sudo ./stop-server.sh

# 只停止后端
pkill -f yshop-server

# 只停止前端
pkill -f http-server
```

### 重启服务

```bash
# 完整重启
sudo ./stop-server.sh
sudo ./start-server.sh --github-release

# 只重启后端
pkill -f yshop-server
cd yshop-drink-boot3/yshop-server/target
nohup java -jar yshop-server*.jar --spring.profiles.active=local > ~/logs/yshop-server.log 2>&1 &
```

---

## 🔄 更新部署

### 当有新版本时

```bash
# 1. 停止服务
sudo ./stop-server.sh

# 2. 部署新版本
sudo ./start-server.sh --github-release v1.1.0

# 3. 验证
curl http://localhost:48081/admin-api/system/health
```

### 快速更新（不停服）

```bash
# 先下载新版本
sudo ./start-server.sh --github-release v1.1.0
# 会提示后端已运行，选择 y 重启
```

---

## 🌐 外网访问配置

### 1. 开放端口

```bash
# Ubuntu UFW 防火墙
sudo ufw allow 80
sudo ufw allow 48081

# 或者 iptables
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 48081 -j ACCEPT
```

### 2. 配置域名（可选）

#### 使用 Nginx 反向代理

```bash
# 安装 Nginx
sudo apt-get install -y nginx

# 配置站点
sudo vim /etc/nginx/sites-available/yshop
```

```nginx
server {
    listen 80;
    server_name your-domain.com;
    
    # 前端
    location / {
        proxy_pass http://localhost:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    
    # 后端 API
    location /admin-api/ {
        proxy_pass http://localhost:48081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location /app-api/ {
        proxy_pass http://localhost:48081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

```bash
# 启用站点
sudo ln -s /etc/nginx/sites-available/yshop /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

---

## 🔐 安全配置

### 1. 修改默认密码

```bash
# 登录管理后台
http://your-server/

# 使用默认账号登录
# 账号：admin
# 密码：admin123

# 立即修改密码！
```

### 2. 修改数据库密码

```bash
# 停止服务
sudo ./stop-server.sh

# 修改 docker-compose.yml
vim docker-compose.yml
# 修改 MYSQL_ROOT_PASSWORD

# 修改 application-local.yaml
vim yshop-drink-boot3/yshop-server/src/main/resources/application-local.yaml
# 修改 spring.datasource.password

# 重启
docker compose down
docker compose up -d
sudo ./start-server.sh --github-release
```

### 3. 配置防火墙

```bash
# 只开放必要端口
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22    # SSH
sudo ufw allow 80    # HTTP
sudo ufw allow 443   # HTTPS
sudo ufw enable
```

---

## 📊 部署验证清单

### ✅ 服务检查

```bash
# 1. Docker 容器
docker ps
# 应该看到 yshop-mysql 和 yshop-redis

# 2. 后端服务
curl http://localhost:48081/admin-api/system/health
# 应该返回健康状态

# 3. 前端服务
curl http://localhost:80
# 应该返回 HTML

# 4. 数据库
docker exec -it yshop-mysql mysql -uroot -proot123456 -e "SHOW DATABASES;"
# 应该看到 yixiang-drink

# 5. Redis
docker exec -it yshop-redis redis-cli -a redis123456 PING
# 应该返回 PONG
```

### ✅ 功能检查

1. **访问管理后台**
   ```
   http://your-server/
   账号：admin
   密码：admin123
   ```

2. **测试登录**
   - ✅ 能够登录
   - ✅ 能够看到菜单
   - ✅ 能够访问各功能模块

3. **测试 API**
   ```bash
   # 获取验证码
   curl http://your-server/admin-api/system/captcha/get
   ```

---

## 🔍 常见问题

### Q1: 下载部署包很慢怎么办？

**方案A：使用代理**
```bash
export https_proxy=http://proxy:8080
sudo -E ./start-server.sh --github-release
```

**方案B：在本地下载后上传**
```bash
# 本地下载
wget https://github.com/YOUR_USERNAME/yshop-drink/releases/download/v1.0.0/yshop-deploy-v1.0.0.tar.gz

# 上传到服务器
scp yshop-deploy-v1.0.0.tar.gz server:/tmp/

# 服务器上手动部署
ssh server
cd /path/to/yshop-drink
tar -xzf /tmp/yshop-deploy-v1.0.0.tar.gz
cp backend/yshop-server*.jar yshop-drink-boot3/yshop-server/target/
cp -r frontend/dist-prod yshop-drink-vue3/
sudo ./start-server.sh --skip-build --prod-frontend
```

---

### Q2: 端口被占用怎么办？

```bash
# 使用端口清理脚本
sudo ./clean-ports.sh

# 然后重新启动
sudo ./start-server.sh --github-release
```

---

### Q3: 数据库导入失败？

```bash
# 检查 MySQL 容器
docker logs yshop-mysql

# 手动导入
docker exec -i yshop-mysql mysql -uroot -proot123456 yixiang-drink < yshop-drink-boot3/sql/yixiang-drink-open.sql
```

---

### Q4: 后端启动失败？

```bash
# 查看日志
tail -f ~/logs/yshop-server.log

# 检查常见问题：
# - 数据库连接失败
# - Redis 连接失败
# - 端口被占用
# - 配置文件错误
```

---

### Q5: 如何访问管理后台？

```bash
# 如果在服务器本地
http://localhost/

# 如果从外网访问
http://your-server-ip/

# 如果配置了域名
http://your-domain.com/

# 默认账号
账号：admin
密码：admin123
```

---

## 🎯 完整部署流程示例

```bash
# === 在本地 ===
# 1. 创建并推送 tag
git tag v1.0.0 -m "First release"
git push origin v1.0.0

# 2. 等待 GitHub Actions 完成（8-10分钟）
gh run watch

# === 在服务器 ===
# 3. SSH 到服务器
ssh user@your-server

# 4. 准备项目
cd ~
git clone https://github.com/YOUR_USERNAME/yshop-drink.git
cd yshop-drink

# 5. 配置文件（如需要）
vim yshop-drink-boot3/yshop-server/src/main/resources/application-local.yaml

# 6. 一键部署
sudo ./start-server.sh --github-release v1.0.0

# 7. 等待 2-3 分钟（首次导入数据库）

# 8. 验证
curl http://localhost:48081/admin-api/system/health
curl http://localhost:80

# 9. 访问管理后台
http://your-server-ip/

# 10. 完成！🎉
```

---

## 📈 性能监控

### 系统资源

```bash
# CPU 和内存
htop

# 磁盘空间
df -h

# Docker 资源
docker stats
```

### 服务监控

```bash
# 后端响应时间
time curl http://localhost:48081/admin-api/system/health

# 数据库连接
docker exec yshop-mysql mysqladmin -uroot -proot123456 ping

# Redis 连接
docker exec yshop-redis redis-cli -a redis123456 PING
```

---

## 🔄 日常维护

### 查看日志

```bash
# 实时日志
tail -f ~/logs/yshop-server.log

# 错误日志
grep ERROR ~/logs/yshop-server.log

# 最近 100 行
tail -100 ~/logs/yshop-server.log
```

### 备份数据

```bash
# 备份数据库
docker exec yshop-mysql mysqldump -uroot -proot123456 yixiang-drink > backup-$(date +%Y%m%d).sql

# 备份 Redis（可选）
docker exec yshop-redis redis-cli -a redis123456 --rdb /data/dump.rdb
```

### 更新到新版本

```bash
# 1. 停止服务
sudo ./stop-server.sh

# 2. 备份（可选）
cp yshop-drink-boot3/yshop-server/target/yshop-server*.jar backups/

# 3. 部署新版本
sudo ./start-server.sh --github-release v1.1.0

# 4. 验证
curl http://localhost:48081/admin-api/system/health
```

---

## 🆘 故障恢复

### 服务异常

```bash
# 1. 查看日志
tail -100 ~/logs/yshop-server.log

# 2. 重启服务
sudo ./stop-server.sh
sudo ./start-server.sh --github-release

# 3. 如果还有问题，回滚
sudo ./start-server.sh --github-release v0.9.9
```

### 数据库问题

```bash
# 重启 MySQL
docker restart yshop-mysql

# 查看日志
docker logs yshop-mysql

# 重新导入（危险！会清空数据）
docker exec -i yshop-mysql mysql -uroot -proot123456 -e "DROP DATABASE yixiang-drink;"
docker exec -i yshop-mysql mysql -uroot -proot123456 -e "CREATE DATABASE yixiang-drink;"
docker exec -i yshop-mysql mysql -uroot -proot123456 yixiang-drink < yshop-drink-boot3/sql/yixiang-drink-open.sql
```

---

## 📞 快速命令速查

```bash
# 部署
sudo ./start-server.sh --github-release [版本]

# 停止
sudo ./stop-server.sh

# 重启
sudo ./stop-server.sh && sudo ./start-server.sh --github-release

# 查看日志
tail -f ~/logs/yshop-server.log

# 查看状态
docker ps
sudo lsof -i :48081
sudo lsof -i :80

# 清理端口
sudo ./clean-ports.sh

# 访问管理后台
http://your-server/
```

---

## 🎉 恭喜！

你现在已经成功：
- ✅ 配置完整的 CI/CD 流程
- ✅ 部署到生产服务器
- ✅ 实现一键发布和部署

**享受自动化带来的便利吧！** 🚀✨

---

**文档版本**: v1.0  
**最后更新**: 2025-11-25  
**状态**: ✅ 生产就绪

