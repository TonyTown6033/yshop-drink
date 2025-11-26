# 🚀 GitHub Release 自动部署指南

## 📦 你的 Release 信息

- **仓库**: [TonyTown6033/yshop-drink](https://github.com/TonyTown6033/yshop-drink)
- **最新版本**: [v1.1.2](https://github.com/TonyTown6033/yshop-drink/releases/tag/v1.1.2)
- **发布时间**: 2025-11-26

---

## 🎯 快速部署

### 方法1：自动下载最新版本（推荐）✨

```bash
cd /path/to/yshop-drink
sudo ./start-server.sh --github-release
```

脚本会自动：
- ✅ 从你的仓库获取最新版本
- ✅ 下载 `yshop-deploy-v1.1.2.tar.gz`
- ✅ 验证文件完整性（SHA256）
- ✅ 解压并部署
- ✅ 启动所有服务

---

### 方法2：指定版本部署

```bash
cd /path/to/yshop-drink
sudo ./start-server.sh --github-release v1.1.2
```

---

### 方法3：手动下载部署

```bash
# 1. 下载部署包
wget https://github.com/TonyTown6033/yshop-drink/releases/download/v1.1.2/yshop-deploy-v1.1.2.tar.gz

# 2. 下载校验文件
wget https://github.com/TonyTown6033/yshop-drink/releases/download/v1.1.2/yshop-deploy-v1.1.2.tar.gz.sha256

# 3. 验证文件（可选但推荐）
sha256sum -c yshop-deploy-v1.1.2.tar.gz.sha256

# 4. 解压
tar -xzf yshop-deploy-v1.1.2.tar.gz

# 5. 复制文件
cd /path/to/yshop-drink
cp /path/to/download/backend/yshop-server*.jar yshop-drink-boot3/yshop-server/target/
cp -r /path/to/download/frontend/dist-prod yshop-drink-vue3/

# 6. 启动服务
sudo ./start-server.sh --skip-build --prod-frontend
```

---

## 📋 部署包内容

从你的 Release 下载的 `yshop-deploy-v1.1.2.tar.gz` 包含：

```
yshop-deploy-v1.1.2/
├── backend/
│   └── yshop-server-2.9.jar          # 后端 JAR (约 50MB)
├── frontend/
│   └── dist-prod/                    # 前端构建产物 (约 10MB)
│       ├── index.html
│       ├── assets/
│       │   ├── index-xxx.js
│       │   └── index-xxx.css
│       └── ...
├── VERSION                           # 版本信息
└── README.md                         # 部署说明
```

**总大小**: 约 40MB（压缩后）

---

## 🔧 配置选项

### 使用不同的仓库

如果你 fork 了项目或使用其他仓库：

```bash
sudo ./start-server.sh --github-release --github-repo YOUR_USERNAME/yshop-drink
```

### 查看帮助

```bash
./start-server.sh --help
```

---

## 📊 部署流程

```
1️⃣ 自动检测仓库
   ├─ 从 git remote 获取
   └─ 或使用默认: TonyTown6033/yshop-drink
   ↓
2️⃣ 获取最新版本
   ├─ 通过 GitHub API
   └─ 或从 releases 页面
   ↓
3️⃣ 下载部署包
   ├─ yshop-deploy-v1.1.2.tar.gz
   └─ yshop-deploy-v1.1.2.tar.gz.sha256
   ↓
4️⃣ 验证文件完整性
   └─ SHA256 校验
   ↓
5️⃣ 解压并复制文件
   ├─ backend/yshop-server*.jar → yshop-drink-boot3/
   └─ frontend/dist-prod/ → yshop-drink-vue3/
   ↓
6️⃣ 启动服务
   ├─ Docker 容器（MySQL + Redis）
   ├─ 后端服务（端口 48081）
   └─ 前端服务（端口 80）
   ↓
7️⃣ 完成！🎉
```

---

## 🔍 预期日志输出

```
========================================
下载 GitHub Release
========================================

[INFO] GitHub 仓库: TonyTown6033/yshop-drink
[INFO] 获取最新版本信息...
[INFO] 最新版本: v1.1.2
[INFO] 版本: v1.1.2
[INFO] 仓库: https://github.com/TonyTown6033/yshop-drink
[INFO] 下载地址: https://github.com/TonyTown6033/yshop-drink/releases/download/v1.1.2/yshop-deploy-v1.1.2.tar.gz
[INFO] 开始下载部署包（可能需要几分钟）...
######################################################################## 100.0%
[SUCCESS] 下载完成
[INFO] 文件大小: 40M
[INFO] 下载校验文件...
[INFO] 验证文件完整性...
[SUCCESS] 文件校验通过
[INFO] 解压部署包...
[INFO] 复制文件到项目目录...
[SUCCESS] 后端文件已复制: yshop-server-2.9.jar
[SUCCESS] 前端文件已复制（dist-prod）

[INFO] 版本信息：
  Version: v1.1.2
  Build Date: 2025-11-26 07:16:00
  Commit: 430f7e6

[SUCCESS] GitHub Release 部署包下载完成
```

---

## ❓ 常见问题

### Q1: 下载失败怎么办？

**错误**: `curl: (22) The requested URL returned error: 404`

**原因**: Release 文件未找到

**解决**:
1. 检查 Release 是否存在: https://github.com/TonyTown6033/yshop-drink/releases
2. 确认文件已上传（`yshop-deploy-v1.1.2.tar.gz`）
3. 手动指定版本：`sudo ./start-server.sh --github-release v1.1.2`

---

### Q2: API 请求受限怎么办？

**错误**: `GitHub API 请求受限`

**原因**: GitHub API 限流（未认证用户 60 次/小时）

**解决**:
- 脚本会自动切换到备用方法（从 releases 页面获取）
- 或等待一小时后重试
- 或手动指定版本号

---

### Q3: 如何验证下载的文件？

```bash
# 下载后自动校验
sha256sum -c yshop-deploy-v1.1.2.tar.gz.sha256

# 手动检查文件大小
ls -lh yshop-deploy-v1.1.2.tar.gz
# 应该约 40MB

# 查看压缩包内容
tar -tzf yshop-deploy-v1.1.2.tar.gz | head -20
```

---

### Q4: 如何切换到旧版本？

```bash
# 部署旧版本
sudo ./start-server.sh --github-release v1.1.1

# 查看所有可用版本
curl -s https://api.github.com/repos/TonyTown6033/yshop-drink/releases | grep tag_name
```

---

### Q5: 下载速度慢怎么办？

**方案A**: 使用代理

```bash
export https_proxy=http://proxy:8080
sudo -E ./start-server.sh --github-release
```

**方案B**: 在本地下载后上传到服务器

```bash
# 本地下载
wget https://github.com/TonyTown6033/yshop-drink/releases/download/v1.1.2/yshop-deploy-v1.1.2.tar.gz

# 上传到服务器
scp yshop-deploy-v1.1.2.tar.gz server:/tmp/

# 服务器上部署
ssh server
cd /path/to/yshop-drink
tar -xzf /tmp/yshop-deploy-v1.1.2.tar.gz -C /tmp/
cp /tmp/backend/yshop-server*.jar yshop-drink-boot3/yshop-server/target/
cp -r /tmp/frontend/dist-prod yshop-drink-vue3/
sudo ./start-server.sh --skip-build --prod-frontend
```

---

## 🎯 完整部署示例

### 服务器环境（Ubuntu 20.04+）

```bash
# 1. SSH 到服务器
ssh user@your-server

# 2. 克隆项目（如果还没有）
git clone https://github.com/TonyTown6033/yshop-drink.git
cd yshop-drink

# 或者拉取最新代码
cd yshop-drink
git pull

# 3. 一键部署最新版本
sudo ./start-server.sh --github-release

# 4. 等待 2-3 分钟...

# 5. 验证服务
curl http://localhost:48081/admin-api/system/health
curl http://localhost:80

# 6. 访问管理后台
# http://your-server-ip/
# 账号：admin
# 密码：admin123
```

---

## 📈 版本历史

| 版本 | 发布日期 | 说明 |
|------|---------|------|
| [v1.1.2](https://github.com/TonyTown6033/yshop-drink/releases/tag/v1.1.2) | 2025-11-26 | 最新版本 |
| v1.1.1 | 2025-11-25 | Bug 修复 |
| v1.1.0 | 2025-11-24 | 新功能发布 |

---

## 🔗 相关链接

- **GitHub 仓库**: https://github.com/TonyTown6033/yshop-drink
- **所有 Releases**: https://github.com/TonyTown6033/yshop-drink/releases
- **问题反馈**: https://github.com/TonyTown6033/yshop-drink/issues

---

## 💡 最佳实践

### 生产环境部署

1. **使用特定版本**
   ```bash
   sudo ./start-server.sh --github-release v1.1.2
   ```
   不要使用 `--github-release`（自动获取最新），避免意外更新。

2. **备份数据**
   ```bash
   # 部署前备份
   sudo docker exec yshop-mysql mysqldump -uroot -proot123456 yixiang-drink \
     > backup-$(date +%Y%m%d).sql
   ```

3. **验证部署**
   ```bash
   # 检查所有服务
   docker ps
   curl http://localhost:48081/admin-api/system/health
   curl http://localhost:80
   ```

4. **监控日志**
   ```bash
   tail -f ~/logs/yshop-server.log
   ```

---

## 🎉 完成！

现在你可以通过以下命令轻松部署：

```bash
# 最简单的方式
sudo ./start-server.sh --github-release
```

一切都是自动化的！🚀✨

---

**文档版本**: v1.0  
**最后更新**: 2025-11-26  
**适用于**: start-server.sh v1.2+

