# GitHub Actions 自动编译部署指南

## 🎯 概述

使用 GitHub Actions 自动编译项目，每次发布新版本时自动构建并上传到 GitHub Releases，服务器可以直接下载并部署。

### 工作流程

```
推送 Tag → GitHub Actions 自动编译 → 创建 Release → 服务器下载部署
```

---

## 🚀 快速开始

### 1. 推送代码到 GitHub

```bash
# 初始化 git（如果还没有）
git init
git add .
git commit -m "Initial commit"

# 添加远程仓库
git remote add origin https://github.com/YOUR_USERNAME/yshop-drink.git

# 推送代码
git push -u origin master
```

### 2. 创建发布版本

```bash
# 创建并推送 tag
git tag -a v2.9.0 -m "Release version 2.9.0"
git push origin v2.9.0
```

### 3. 自动构建

GitHub Actions 会自动：
- ✅ 编译后端（生成 jar）
- ✅ 编译前端（生成 dist）
- ✅ 打包成 tar.gz
- ✅ 创建 GitHub Release
- ✅ 上传部署包

### 4. 服务器部署

```bash
# 方法1：自动下载最新版本
cd /path/to/yshop-drink
sudo ./start-server.sh --github-release

# 方法2：指定版本
sudo ./start-server.sh --github-release v2.9.0

# 方法3：指定仓库和版本
sudo ./start-server.sh --github-release v2.9.0 --github-repo username/yshop-drink
```

---

## 📋 详细说明

### GitHub Actions 工作流配置

文件位置：`.github/workflows/build-release.yml`

#### 触发条件

```yaml
on:
  push:
    tags:
      - 'v*.*.*'  # 推送 v 开头的 tag 时触发
  workflow_dispatch:  # 允许手动触发
```

**支持的 tag 格式**：
- `v2.9.0` ✅
- `v2.9.1` ✅
- `v3.0.0` ✅
- `v2.9.0-beta` ✅
- `2.9.0` ❌（必须以 v 开头）

#### 构建步骤

1. **准备环境**
   - JDK 17
   - Node.js 18
   - Maven & pnpm

2. **配置镜像**
   - Maven 使用阿里云镜像
   - npm 使用淘宝镜像

3. **编译项目**
   - 后端：`mvn clean install package`
   - 前端：`pnpm run build`

4. **打包**
   - 创建 `deploy` 目录
   - 复制 jar 和 dist
   - 生成版本信息
   - 打包成 tar.gz

5. **发布**
   - 创建 GitHub Release
   - 上传部署包
   - 生成 SHA256 校验和

---

## 🔧 使用方法

### 方法1：推送 Tag 触发（推荐）

```bash
# 1. 确保代码已提交
git add .
git commit -m "准备发布 v2.9.0"

# 2. 创建 tag
git tag -a v2.9.0 -m "Release version 2.9.0
- 新功能：xxx
- 修复：xxx
- 优化：xxx"

# 3. 推送 tag
git push origin v2.9.0

# 4. 查看构建进度
# 访问：https://github.com/YOUR_USERNAME/yshop-drink/actions
```

### 方法2：手动触发

1. 访问仓库的 Actions 页面
2. 选择 "Build and Release" 工作流
3. 点击 "Run workflow"
4. 选择分支并运行

### 方法3：通过 GitHub CLI

```bash
# 安装 GitHub CLI
# Ubuntu: sudo apt install gh
# macOS: brew install gh

# 登录
gh auth login

# 创建 release（会自动触发构建）
gh release create v2.9.0 \
  --title "Release v2.9.0" \
  --notes "发布说明"
```

---

## 📦 部署包内容

下载的部署包包含：

```
yshop-deploy-v2.9.0.tar.gz
├── backend/
│   └── yshop-server-2.9.jar
├── frontend/
│   └── dist/
│       ├── index.html
│       ├── assets/
│       └── ...
├── VERSION          # 版本信息
└── README.md        # 部署说明
```

---

## 🖥️ 服务器部署

### 完全自动化部署（推荐）

```bash
# 进入项目目录
cd /path/to/yshop-drink

# 一键部署最新版本
sudo ./start-server.sh --github-release
```

脚本会自动：
1. ✅ 从 GitHub 获取最新版本号
2. ✅ 下载部署包
3. ✅ 验证文件完整性（SHA256）
4. ✅ 解压并复制文件
5. ✅ 启动服务

### 部署指定版本

```bash
# 部署 v2.9.0
sudo ./start-server.sh --github-release v2.9.0

# 部署 v2.8.5
sudo ./start-server.sh --github-release v2.8.5
```

### 指定 GitHub 仓库

如果脚本无法自动识别仓库：

```bash
sudo ./start-server.sh \
  --github-release v2.9.0 \
  --github-repo username/yshop-drink
```

### 手动下载部署

```bash
# 1. 下载
wget https://github.com/username/yshop-drink/releases/download/v2.9.0/yshop-deploy-v2.9.0.tar.gz

# 2. 验证（可选）
wget https://github.com/username/yshop-drink/releases/download/v2.9.0/yshop-deploy-v2.9.0.tar.gz.sha256
sha256sum -c yshop-deploy-v2.9.0.tar.gz.sha256

# 3. 解压
tar -xzf yshop-deploy-v2.9.0.tar.gz

# 4. 复制文件
cp backend/yshop-server-*.jar /path/to/yshop-drink/yshop-drink-boot3/yshop-server/target/
cp -r frontend/dist /path/to/yshop-drink/yshop-drink-vue3/

# 5. 启动
cd /path/to/yshop-drink
sudo ./start-server.sh --skip-build --prod-frontend
```

---

## 🔄 版本管理

### 语义化版本（推荐）

遵循 [Semantic Versioning](https://semver.org/lang/zh-CN/)：

- **主版本号**：不兼容的 API 修改
- **次版本号**：向下兼容的功能性新增
- **修订号**：向下兼容的问题修正

示例：
```bash
# 主版本更新
git tag v3.0.0

# 次版本更新（新功能）
git tag v2.10.0

# 修订版本（Bug 修复）
git tag v2.9.1
```

### 预发布版本

```bash
# Beta 版本
git tag v2.9.0-beta.1
git tag v2.9.0-beta.2

# RC 版本
git tag v2.9.0-rc.1

# 正式版本
git tag v2.9.0
```

### 查看所有版本

```bash
# 本地 tags
git tag -l

# 远程 releases
gh release list

# 或访问
# https://github.com/YOUR_USERNAME/yshop-drink/releases
```

### 删除错误的版本

```bash
# 删除本地 tag
git tag -d v2.9.0

# 删除远程 tag
git push origin :refs/tags/v2.9.0

# 删除 GitHub Release
gh release delete v2.9.0
```

---

## 📊 构建状态

### 查看构建进度

1. **GitHub Web UI**
   ```
   https://github.com/YOUR_USERNAME/yshop-drink/actions
   ```

2. **GitHub CLI**
   ```bash
   gh run list
   gh run view <run-id>
   gh run watch
   ```

### 构建状态徽章

在 README.md 中添加：

```markdown
[![Build Status](https://github.com/YOUR_USERNAME/yshop-drink/workflows/Build%20and%20Release/badge.svg)](https://github.com/YOUR_USERNAME/yshop-drink/actions)
```

---

## 🔧 高级配置

### 自定义构建环境

编辑 `.github/workflows/build-release.yml`：

```yaml
# 修改 Java 版本
- name: Set up JDK 17
  uses: actions/setup-java@v3
  with:
    java-version: '17'  # 改为 11 或 21

# 修改 Node.js 版本
- name: Set up Node.js
  uses: actions/setup-node@v3
  with:
    node-version: '18'  # 改为 16 或 20
```

### 添加构建步骤

```yaml
- name: Run Tests
  run: |
    cd yshop-drink-boot3
    mvn test

- name: Security Scan
  run: |
    # 添加安全扫描
```

### 多环境构建

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, windows-latest]
    java: [17, 21]
```

### 构建缓存优化

```yaml
- name: Cache Maven packages
  uses: actions/cache@v3
  with:
    path: ~/.m2
    key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}

- name: Cache pnpm store
  uses: actions/cache@v3
  with:
    path: ~/.pnpm-store
    key: ${{ runner.os }}-pnpm-${{ hashFiles('**/pnpm-lock.yaml') }}
```

---

## 🚨 故障排查

### 问题1：构建失败

**检查日志**：
```bash
gh run view --log

# 或访问 Web UI 查看详细日志
```

**常见原因**：
- Maven 依赖下载失败 → 检查 settings.xml
- 前端构建失败 → 检查 package.json
- 内存不足 → GitHub Actions 有资源限制

### 问题2：服务器下载失败

**检查网络**：
```bash
# 测试连接
curl -I https://github.com

# 使用代理
export https_proxy=http://proxy.example.com:8080
sudo -E ./start-server.sh --github-release
```

**手动下载**：
```bash
# 使用 wget
wget --no-check-certificate https://...

# 使用国内镜像（如果有）
# GitHub 在国内可能较慢
```

### 问题3：无法识别仓库

**指定仓库**：
```bash
sudo ./start-server.sh \
  --github-release v2.9.0 \
  --github-repo username/yshop-drink
```

**检查 git remote**：
```bash
git remote -v
# 应该显示 GitHub 仓库地址
```

### 问题4：版本校验失败

**跳过校验**（不推荐）：
修改脚本，注释掉 sha256sum 检查

**重新下载**：
```bash
# 删除损坏的文件
rm yshop-deploy-v2.9.0.tar.gz

# 重新下载
wget https://...
```

---

## 📝 最佳实践

### 1. 发布前检查

```bash
# 1. 确保所有测试通过
mvn test
pnpm test

# 2. 确保代码已提交
git status

# 3. 更新版本号（如果有）
# 编辑 pom.xml 和 package.json

# 4. 更新 CHANGELOG.md
vim CHANGELOG.md

# 5. 提交版本更新
git add .
git commit -m "Bump version to 2.9.0"

# 6. 创建 tag
git tag -a v2.9.0 -m "Release v2.9.0"

# 7. 推送
git push origin master
git push origin v2.9.0
```

### 2. 版本回滚

```bash
# 查看当前版本
curl http://localhost:48081/admin-api/system/version

# 部署旧版本
sudo ./stop-server.sh
sudo ./start-server.sh --github-release v2.8.5
```

### 3. 金丝雀部署

```bash
# 服务器A：保持旧版本运行
# 服务器B：部署新版本测试
sudo ./start-server.sh --github-release v2.9.0

# 测试通过后，逐步切换流量
# 最后在服务器A也更新
```

### 4. 自动化脚本

创建 `auto-deploy.sh`：

```bash
#!/bin/bash

# 监听新版本并自动部署
REPO="username/yshop-drink"
CURRENT_VERSION=$(cat /var/lib/yshop/version 2>/dev/null || echo "v0.0.0")

while true; do
    # 获取最新版本
    LATEST=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
    
    if [ "$LATEST" != "$CURRENT_VERSION" ]; then
        echo "发现新版本: $LATEST"
        
        # 部署
        cd /path/to/yshop-drink
        sudo ./stop-server.sh
        sudo ./start-server.sh --github-release $LATEST
        
        # 更新记录
        echo $LATEST > /var/lib/yshop/version
        
        CURRENT_VERSION=$LATEST
    fi
    
    # 每小时检查一次
    sleep 3600
done
```

---

## 🎉 总结

### 完整工作流程

```
开发 → 测试 → 提交代码 → 创建 Tag → 自动构建 → 服务器部署
```

### 关键命令

```bash
# 开发端
git tag -a v2.9.0 -m "Release v2.9.0"
git push origin v2.9.0

# 服务器端
sudo ./start-server.sh --github-release
```

### 优势

- ✅ 零编译负载
- ✅ 秒级部署
- ✅ 版本可追溯
- ✅ 支持回滚
- ✅ 自动化流程
- ✅ 一致性保证

现在你的项目已经实现了**完全自动化的 CI/CD 流程**！🚀

---

**更新时间**: 2025-11-25  
**版本**: v1.0

