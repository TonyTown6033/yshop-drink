# 📦 发布部署快速指南

## 🚀 发布新版本（3步）

```bash
# 1. 创建 tag
git tag -a v2.9.0 -m "Release v2.9.0"

# 2. 推送 tag
git push origin v2.9.0

# 3. 等待自动构建
# 访问 https://github.com/YOUR_USERNAME/yshop-drink/actions
```

✅ GitHub Actions 会自动编译并创建 Release

---

## 🖥️ 服务器部署（1步）

```bash
# 自动下载并部署最新版本
sudo ./start-server.sh --github-release
```

完成！🎉

---

## 📋 常用命令

### 发布端

```bash
# 创建新版本
git tag -a v2.9.0 -m "Release notes"
git push origin v2.9.0

# 查看所有版本
git tag -l

# 删除错误版本
git tag -d v2.9.0
git push origin :refs/tags/v2.9.0

# 查看构建状态
gh run list
gh run watch
```

### 服务器端

```bash
# 部署最新版本
sudo ./start-server.sh --github-release

# 部署指定版本
sudo ./start-server.sh --github-release v2.9.0

# 指定仓库
sudo ./start-server.sh --github-release v2.9.0 --github-repo username/yshop-drink

# 查看服务状态
docker ps
sudo lsof -i :48081
tail -f ~/logs/yshop-server.log
```

---

## 🔄 版本号规范

遵循语义化版本：`v主版本.次版本.修订号`

```bash
# 主版本（不兼容的改动）
v3.0.0

# 次版本（新功能）
v2.10.0

# 修订版本（Bug 修复）
v2.9.1

# 预发布版本
v2.9.0-beta.1
v2.9.0-rc.1
```

---

## 📊 工作流程图

```
┌──────────────┐
│  编写代码    │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  提交代码    │
│ git commit   │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  创建 Tag    │
│ git tag      │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│  推送 Tag    │
│ git push     │
└──────┬───────┘
       │
       ▼
┌──────────────────────┐
│ GitHub Actions 自动  │
│ • 编译后端          │
│ • 编译前端          │
│ • 打包              │
│ • 创建 Release      │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ 服务器部署          │
│ ./start-server.sh   │
│ --github-release    │
└──────────────────────┘
```

---

## 🎯 部署模式对比

| 模式 | 命令 | 编译位置 | 速度 | 推荐场景 |
|------|------|----------|------|----------|
| 完整编译 | `./start-server.sh` | 服务器 | 慢(10分钟) | 开发环境 |
| 本地预编译 | `./start-server.sh --skip-build` | 本地 | 快(1分钟) | 小团队 |
| GitHub 自动编译 | `./start-server.sh --github-release` | GitHub | 快(1分钟) | **生产环境(推荐)** |

---

## ⚡ 典型场景

### 场景1：日常开发

```bash
# 本地修改代码，服务器编译
git push
ssh server "cd /path/to/yshop-drink && git pull && sudo ./start-server.sh"
```

### 场景2：版本发布

```bash
# 创建版本，GitHub 编译，服务器部署
git tag v2.9.0 && git push origin v2.9.0
ssh server "cd /path/to/yshop-drink && sudo ./start-server.sh --github-release"
```

### 场景3：紧急回滚

```bash
# 回滚到上一个版本
ssh server "cd /path/to/yshop-drink && sudo ./start-server.sh --github-release v2.8.5"
```

### 场景4：多服务器部署

```bash
# 一次编译，多台服务器部署
git tag v2.9.0 && git push origin v2.9.0

# 等待 GitHub Actions 完成后
for server in server1 server2 server3; do
    ssh $server "cd /path/to/yshop-drink && sudo ./start-server.sh --github-release v2.9.0"
done
```

---

## 🔍 验证部署

```bash
# 1. 检查版本
curl http://localhost:48081/admin-api/system/version

# 2. 检查服务
curl http://localhost:48081/admin-api/system/health

# 3. 查看日志
tail -f ~/logs/yshop-server.log

# 4. 检查进程
ps aux | grep yshop-server
```

---

## 🆘 快速故障排查

### 构建失败

```bash
# 查看构建日志
gh run list
gh run view <run-id> --log

# 或访问 Web UI
https://github.com/YOUR_USERNAME/yshop-drink/actions
```

### 下载失败

```bash
# 手动下载
wget https://github.com/YOUR_USERNAME/yshop-drink/releases/download/v2.9.0/yshop-deploy-v2.9.0.tar.gz

# 解压并部署
tar -xzf yshop-deploy-v2.9.0.tar.gz
cp backend/yshop-server-*.jar yshop-drink-boot3/yshop-server/target/
cp -r frontend/dist yshop-drink-vue3/
sudo ./start-server.sh --skip-build --prod-frontend
```

### 服务启动失败

```bash
# 检查端口
sudo ./clean-ports.sh

# 检查 Docker
docker ps

# 查看详细日志
tail -100 ~/logs/yshop-server.log
```

---

## 📚 相关文档

- [GitHub Actions 部署指南](doc/GitHub-Actions部署指南.md) - 完整说明
- [预编译部署指南](doc/预编译部署指南.md) - 本地编译方式
- [端口清理指南](doc/端口清理指南.md) - 端口问题解决
- [nvm 使用说明](doc/nvm使用说明.md) - Node.js 版本管理

---

## 💡 小技巧

### 自动部署脚本

```bash
# 创建 auto-update.sh
cat > auto-update.sh << 'EOF'
#!/bin/bash
cd /path/to/yshop-drink
sudo ./stop-server.sh
sudo ./start-server.sh --github-release
EOF

chmod +x auto-update.sh
```

### 版本别名

```bash
# .bashrc 或 .zshrc
alias yshop-deploy='sudo ./start-server.sh --github-release'
alias yshop-stop='sudo ./stop-server.sh'
alias yshop-logs='tail -f ~/logs/yshop-server.log'
alias yshop-status='docker ps && sudo lsof -i :48081'
```

### Webhook 自动部署

在服务器上设置 webhook 监听 GitHub Release 事件，自动触发部署。

---

**快速帮助**：遇到问题查看 [GitHub Actions 部署指南](doc/GitHub-Actions部署指南.md) 📖

