# ⚡ 快速开始 - 服务器部署

## 🎯 3分钟部署

### 前提
- ✅ GitHub Actions 已运行成功
- ✅ Release 已创建
- ✅ 有一台 Ubuntu 服务器

---

## 🚀 部署步骤

### 1. 准备服务器（首次）

```bash
# SSH 到服务器
ssh user@your-server

# 安装 Docker（如果没有）
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun

# 安装 JDK 17
sudo apt-get update && sudo apt-get install -y openjdk-17-jdk

# 克隆项目
git clone https://github.com/YOUR_USERNAME/yshop-drink.git
cd yshop-drink

# 配置后端（修改数据库密码等）
vim yshop-drink-boot3/yshop-server/src/main/resources/application-local.yaml
```

### 2. 一键部署

```bash
# 自动下载并部署最新版本
sudo ./start-server.sh --github-release

# 或指定版本
sudo ./start-server.sh --github-release v1.0.0
```

### 3. 验证

```bash
# 检查服务
docker ps
curl http://localhost:48081/admin-api/system/health
curl http://localhost:80

# 访问管理后台
http://your-server-ip/
# 账号：admin
# 密码：admin123
```

---

## 🔄 日常更新

```bash
# 1. 本地推送新版本
git tag v1.1.0 -m "New release"
git push origin v1.1.0

# 2. 等待 CI/CD 完成（8-10分钟）
gh run watch

# 3. 服务器部署
ssh user@your-server
cd yshop-drink
sudo ./stop-server.sh
sudo ./start-server.sh --github-release v1.1.0
```

---

## 🔧 常用命令

```bash
# 查看日志
tail -f ~/logs/yshop-server.log

# 停止服务
sudo ./stop-server.sh

# 重启服务
sudo ./stop-server.sh
sudo ./start-server.sh --github-release

# 查看状态
docker ps
sudo lsof -i :48081
```

---

## 📚 完整文档

- **[SERVER-DEPLOY.md](SERVER-DEPLOY.md)** - 完整部署指南（推荐阅读）
- [start-server.sh](start-server.sh) - 启动脚本
- [stop-server.sh](stop-server.sh) - 停止脚本

---

## 💡 部署流程说明

当你执行 `sudo ./start-server.sh --github-release` 时：

1. 📥 从 GitHub 下载最新的 Release 包
2. 🔍 验证文件完整性（SHA256）
3. 📦 解压并复制文件
4. 🐳 启动 Docker 容器（MySQL、Redis）
5. 💾 导入数据库（首次）
6. ⚙️ 启动后端服务（端口 48081）
7. 🌐 启动前端服务（端口 80）
8. ✅ 完成！

整个过程 2-3 分钟（首次稍慢，需要导入数据库）。

---

## 🎉 完成！

现在你可以访问：

- **管理后台**: http://your-server-ip/
- **后端 API**: http://your-server-ip:48081

默认账号：`admin`  
默认密码：`admin123`  
**记得登录后立即修改密码！** 🔐

---

**就这么简单！** 🚀✨

