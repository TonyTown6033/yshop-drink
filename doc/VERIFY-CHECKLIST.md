# ✅ GitHub Actions 验证清单

## 📋 在推送 tag 之前检查

### 1. 文件检查

```bash
# 检查 workflow 文件
cat .github/workflows/build-release.yml | grep -A 5 "pnpm/action-setup"
# 应该看到 version: 8

# 检查 pnpm-lock.yaml 存在
ls -la yshop-drink-vue3/pnpm-lock.yaml
# 应该显示文件存在

# 检查 pom.xml 存在
ls -la yshop-drink-boot3/pom.xml
# 应该显示文件存在
```

**预期结果**：
- ✅ workflow 使用 `pnpm/action-setup@v2`
- ✅ `pnpm-lock.yaml` 存在
- ✅ `pom.xml` 存在

---

### 2. Git 状态检查

```bash
# 检查 git 状态
git status

# 检查 remote
git remote -v | grep github.com
```

**预期结果**：
- ✅ 工作区干净或只有已知的修改
- ✅ GitHub remote 已配置

---

### 3. 运行配置检查脚本

```bash
./check-github-actions.sh
```

**预期结果**：
- ✅ 所有检查通过
- ✅ 没有错误提示

---

## 🚀 推送 tag

### 1. 提交所有更改

```bash
# 如果有未提交的修改
git add .
git commit -m "Fix GitHub Actions pnpm cache configuration"
git push
```

### 2. 创建并推送 tag

```bash
# 创建 tag
git tag v1.0.0 -m "Release v1.0.0
- 修复 GitHub Actions 缓存配置
- 优化构建性能
- 完整的 CI/CD 流程"

# 推送 tag
git push origin v1.0.0
```

---

## 👀 监控构建

### 方法1：使用 GitHub CLI

```bash
# 查看运行列表
gh run list

# 实时监控（推荐）
gh run watch

# 查看详细日志
gh run view --log
```

### 方法2：Web 界面

访问：`https://github.com/YOUR_USERNAME/yshop-drink/actions`

---

## 📊 构建步骤验证

### 预期看到的步骤（按顺序）

1. ✅ **Checkout code**
   ```
   Syncing repository: YOUR_USERNAME/yshop-drink
   ```

2. ✅ **Set up JDK 17**
   ```
   Java version: 17.x.x
   ```

3. ✅ **Cache Maven packages**
   ```
   Cache restored from key: Linux-maven-xxx
   或
   Cache not found for input keys: ...
   ```

4. ✅ **Set up Node.js**
   ```
   Successfully set up Node.js version 18
   ```

5. ✅ **Install pnpm**
   ```
   pnpm version 8.x.x
   ```

6. ✅ **Get pnpm store directory**
   ```
   Store path: /home/runner/.pnpm-store
   ```

7. ✅ **Setup pnpm cache**
   ```
   Cache restored from key: Linux-pnpm-store-xxx
   或
   Cache not found for input keys: ...
   ```

8. ✅ **Configure Maven mirror (China)**
   ```
   Maven settings.xml configured
   ```

9. ✅ **Build Backend**
   ```
   BUILD SUCCESS
   Total time: X min
   ```

10. ✅ **Build Frontend**
    ```
    dist/index.html created
    ```

11. ✅ **Prepare Deploy Package**
    ```
    deploy/ directory created
    ```

12. ✅ **Create Release Package**
    ```
    yshop-deploy-v1.0.0.tar.gz created
    ```

13. ✅ **Create Release**
    ```
    Release v1.0.0 created
    ```

14. ✅ **Upload Build Artifacts**
    ```
    Artifact uploaded successfully
    ```

---

## ❌ 如果出现错误

### 错误：缓存配置问题

**症状**：
```
Error: Some specified paths were not resolved
```

**解决**：
```bash
# 确认已拉取最新代码
git pull

# 检查 workflow 配置
grep "pnpm/action-setup" .github/workflows/build-release.yml
```

---

### 错误：pnpm 未找到

**症状**：
```
pnpm: command not found
```

**解决**：workflow 应该已经包含 `pnpm/action-setup`，检查配置是否正确。

---

### 错误：Maven 构建失败

**症状**：
```
[ERROR] Failed to execute goal
```

**解决**：
1. 检查本地是否能编译成功
2. 查看详细错误日志
3. 参考 [GitHub-Actions-故障排查.md](doc/GitHub-Actions-故障排查.md)

---

### 错误：前端构建失败

**症状**：
```
[ERROR] pnpm build failed
```

**解决**：
1. 检查 `pnpm-lock.yaml` 是否已提交
2. 检查 `package.json` 中的 build 脚本
3. 本地测试：`cd yshop-drink-vue3 && pnpm install && pnpm build`

---

## ✨ 构建成功后

### 1. 验证 Release

```bash
# 查看 Releases
gh release list

# 查看特定版本
gh release view v1.0.0
```

**应该看到**：
- ✅ Release v1.0.0 存在
- ✅ 包含 `yshop-deploy-v1.0.0.tar.gz`
- ✅ 包含 `.sha256` 校验文件
- ✅ 有 Release Notes

---

### 2. 下载验证（可选）

```bash
# 下载部署包
wget https://github.com/YOUR_USERNAME/yshop-drink/releases/download/v1.0.0/yshop-deploy-v1.0.0.tar.gz

# 验证校验和
wget https://github.com/YOUR_USERNAME/yshop-drink/releases/download/v1.0.0/yshop-deploy-v1.0.0.tar.gz.sha256
sha256sum -c yshop-deploy-v1.0.0.tar.gz.sha256

# 查看内容
tar -tzf yshop-deploy-v1.0.0.tar.gz
```

**应该看到**：
```
backend/yshop-server-2.9.jar
frontend/dist/
VERSION
README.md
```

---

### 3. 服务器部署

```bash
# SSH 到服务器
ssh your-server

# 进入项目目录
cd /path/to/yshop-drink

# 拉取最新脚本（如果需要）
git pull

# 部署
sudo ./start-server.sh --github-release v1.0.0
```

**预期流程**：
1. ✅ 自动下载部署包
2. ✅ 验证文件完整性
3. ✅ 解压并复制文件
4. ✅ 启动服务

---

## 📈 性能指标

### 首次构建（无缓存）

| 步骤 | 预期时间 |
|------|----------|
| Maven 依赖下载 | 2-3 分钟 |
| Maven 编译 | 3-4 分钟 |
| pnpm 依赖安装 | 1-2 分钟 |
| 前端构建 | 1 分钟 |
| **总计** | **8-10 分钟** |

### 后续构建（有缓存）

| 步骤 | 预期时间 |
|------|----------|
| Maven 缓存恢复 | 10-20 秒 |
| Maven 编译 | 3-4 分钟 |
| pnpm 缓存恢复 | 5-10 秒 |
| 前端构建 | 1 分钟 |
| **总计** | **5-6 分钟** |

**性能提升**：约 **40-50%**

---

## 🎯 完整工作流程

```
┌─────────────────┐
│ 1. 本地开发完成 │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 2. 提交代码     │
│    git push     │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 3. 创建 tag     │
│    git tag v1.0 │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 4. 推送 tag     │
│    git push tag │
└────────┬────────┘
         │
         ▼
┌──────────────────────────┐
│ 5. GitHub Actions 自动  │
│    ✓ 编译后端（3-4分钟）│
│    ✓ 编译前端（1分钟）  │
│    ✓ 打包（10秒）       │
│    ✓ 创建 Release（5秒）│
└────────┬─────────────────┘
         │
         ▼
┌─────────────────┐
│ 6. 服务器部署   │
│    (1分钟)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 7. 完成！🎉    │
└─────────────────┘
```

---

## 📚 相关文档

- 📖 [GITHUB-ACTIONS-UPDATE.md](GITHUB-ACTIONS-UPDATE.md) - 本次修复说明
- 📖 [GITHUB-ACTIONS-FIXED.md](GITHUB-ACTIONS-FIXED.md) - 第一次修复
- 📖 [RELEASE-GUIDE.md](RELEASE-GUIDE.md) - 快速发布指南
- 📖 [doc/GitHub-Actions部署指南.md](doc/GitHub-Actions部署指南.md) - 完整教程
- 📖 [doc/GitHub-Actions-故障排查.md](doc/GitHub-Actions-故障排查.md) - 故障排查

---

## 🎉 准备就绪！

所有配置都已正确，现在可以：

```bash
# 一键创建发布
git tag v1.0.0 -m "First release" && git push origin v1.0.0

# 然后喝杯咖啡 ☕
# 5-10 分钟后回来查看构建结果
```

**祝你发布顺利！** 🚀

---

**创建时间**: 2025-11-25  
**版本**: v1.0  
**状态**: ✅ 准备就绪

