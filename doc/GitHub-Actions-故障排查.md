# GitHub Actions 故障排查指南

## ❌ 常见错误及解决方案

### 错误1：actions/upload-artifact v3 已弃用

#### 错误信息
```
Error: This request has been automatically failed because it uses a deprecated version of 
`actions/upload-artifact: v3`. Learn more: https://github.blog/changelog/2024-04-16-deprecation-notice-v3-of-the-artifact-actions/
```

#### 原因
GitHub 在 2024年4月16日弃用了 v3 版本的 artifact actions。

#### 解决方案
已修复！所有 actions 已更新到 v4：

```yaml
# ✅ 已更新
- uses: actions/checkout@v4          # v3 → v4
- uses: actions/setup-java@v4        # v3 → v4  
- uses: actions/setup-node@v4        # v3 → v4
- uses: actions/upload-artifact@v4   # v3 → v4
```

#### 验证修复
```bash
# 1. 拉取最新代码
git pull

# 2. 推送一个新 tag 测试
git tag v1.0.1-test
git push origin v1.0.1-test

# 3. 查看 Actions 执行结果
# 访问：https://github.com/YOUR_USERNAME/yshop-drink/actions
```

---

### 错误2：Maven 依赖下载失败

#### 错误信息
```
[ERROR] Failed to execute goal ... Could not resolve dependencies
```

#### 原因
- 网络问题
- Maven 仓库不可访问
- 依赖版本不存在

#### 解决方案

**方案1：使用镜像**（已配置）
```yaml
- name: Configure Maven mirror (China)
  run: |
    mkdir -p ~/.m2
    cat > ~/.m2/settings.xml << 'EOF'
    <settings>
      <mirrors>
        <mirror>
          <id>aliyunmaven</id>
          <mirrorOf>*</mirrorOf>
          <url>https://maven.aliyun.com/repository/public</url>
        </mirror>
      </mirrors>
    </settings>
    EOF
```

**方案2：重试构建**
1. 访问 Actions 页面
2. 点击失败的 workflow
3. 点击 "Re-run failed jobs"

**方案3：检查依赖**
```bash
# 本地验证
cd yshop-drink-boot3
mvn dependency:resolve
```

---

### 错误3：前端构建失败

#### 错误信息
```
[ERROR] pnpm install failed
[ERROR] pnpm build failed
```

#### 原因
- Node.js 版本不匹配
- 依赖版本冲突
- 构建脚本错误

#### 解决方案

**方案1：检查 Node.js 版本**
```yaml
# 确保版本匹配
- name: Set up Node.js
  uses: actions/setup-node@v4
  with:
    node-version: '18'  # 确保与本地一致
```

**方案2：清理缓存**

编辑 workflow，添加：
```yaml
- name: Clean npm cache
  run: |
    pnpm store prune
    rm -rf node_modules
```

**方案3：锁定依赖版本**
```bash
# 本地生成 lockfile
cd yshop-drink-vue3
pnpm install
git add pnpm-lock.yaml
git commit -m "Update lockfile"
git push
```

---

### 错误4：创建 Release 失败

#### 错误信息
```
Error: Resource not accessible by integration
Error: Not Found
```

#### 原因
- 没有权限创建 Release
- Tag 已存在
- GITHUB_TOKEN 权限不足

#### 解决方案

**方案1：检查 Token 权限**

在仓库设置中：
1. 进入 `Settings` → `Actions` → `General`
2. 找到 `Workflow permissions`
3. 选择 `Read and write permissions`
4. 勾选 `Allow GitHub Actions to create and approve pull requests`
5. 保存设置

**方案2：手动提供 Token**

如果需要更高权限：
```yaml
- name: Create Release
  uses: softprops/action-gh-release@v1
  with:
    files: |
      yshop-deploy-*.tar.gz
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**方案3：删除已存在的 Release**
```bash
# 使用 GitHub CLI
gh release delete v2.9.0 --yes

# 或通过 Web UI 删除
```

---

### 错误5：磁盘空间不足

#### 错误信息
```
Error: No space left on device
```

#### 原因
GitHub Actions runner 磁盘空间有限（约14GB）

#### 解决方案

**方案1：清理构建产物**

添加清理步骤：
```yaml
- name: Clean up
  run: |
    cd yshop-drink-boot3
    mvn clean
    rm -rf ~/.m2/repository/*
```

**方案2：不保存中间文件**
```yaml
- name: Build Backend
  run: |
    cd yshop-drink-boot3
    mvn package -Dmaven.test.skip=true
    # 只保留最终 jar
    find . -name "*.jar" ! -name "yshop-server-*.jar" -delete
```

**方案3：使用 GitHub 缓存**
```yaml
- name: Cache Maven packages
  uses: actions/cache@v4
  with:
    path: ~/.m2
    key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
```

---

### 错误6：网络超时

#### 错误信息
```
Error: connect ETIMEDOUT
Error: read ECONNRESET
```

#### 原因
- 网络连接不稳定
- 依赖服务器响应慢
- 防火墙阻拦

#### 解决方案

**方案1：增加超时时间**
```yaml
- name: Build Backend
  timeout-minutes: 30  # 默认是 360 分钟
  run: |
    cd yshop-drink-boot3
    mvn package
```

**方案2：添加重试逻辑**
```yaml
- name: Build Backend with retry
  uses: nick-invision/retry@v2
  with:
    timeout_minutes: 30
    max_attempts: 3
    command: |
      cd yshop-drink-boot3
      mvn package -Dmaven.test.skip=true
```

**方案3：使用国内镜像**（已配置）
```yaml
- name: Configure mirrors
  run: |
    # Maven 阿里云镜像
    # npm 淘宝镜像
    pnpm config set registry https://registry.npmmirror.com
```

---

## 🔍 调试技巧

### 1. 查看详细日志

**在 workflow 中启用调试**：

仓库设置中添加 secrets：
- `ACTIONS_STEP_DEBUG` = `true`
- `ACTIONS_RUNNER_DEBUG` = `true`

**或在 workflow 中添加**：
```yaml
- name: Debug info
  run: |
    echo "Working directory: $(pwd)"
    echo "Java version: $(java -version)"
    echo "Node version: $(node -v)"
    echo "Maven version: $(mvn -v)"
    ls -la
```

### 2. 本地测试

使用 [act](https://github.com/nektos/act) 本地运行 GitHub Actions：

```bash
# 安装 act
brew install act  # macOS
# 或
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# 运行 workflow
act -j build
```

### 3. 缩小测试范围

创建临时 workflow 测试特定步骤：
```yaml
name: Test Build

on: workflow_dispatch

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Test Maven
        run: |
          cd yshop-drink-boot3
          mvn clean compile
```

---

## 📊 性能优化

### 1. 使用缓存

```yaml
- name: Cache Maven packages
  uses: actions/cache@v4
  with:
    path: ~/.m2
    key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
    restore-keys: |
      ${{ runner.os }}-m2-

- name: Cache pnpm store
  uses: actions/cache@v4
  with:
    path: ~/.pnpm-store
    key: ${{ runner.os }}-pnpm-${{ hashFiles('**/pnpm-lock.yaml') }}
    restore-keys: |
      ${{ runner.os }}-pnpm-
```

### 2. 并行构建

```yaml
jobs:
  build-backend:
    runs-on: ubuntu-latest
    steps:
      - name: Build Backend
        run: mvn package
  
  build-frontend:
    runs-on: ubuntu-latest
    steps:
      - name: Build Frontend
        run: pnpm build
  
  create-release:
    needs: [build-backend, build-frontend]
    runs-on: ubuntu-latest
    steps:
      - name: Create Release
        run: ...
```

### 3. 跳过不必要的步骤

```yaml
- name: Build
  if: startsWith(github.ref, 'refs/tags/')
  run: mvn package
```

---

## 🚨 紧急处理

### 构建一直失败怎么办？

**方案1：临时禁用 Actions**
1. 进入仓库 `Settings` → `Actions` → `General`
2. 选择 `Disable actions`
3. 修复问题后重新启用

**方案2：使用本地编译**
```bash
# 回退到方案2（本地预编译）
./build-local.sh
scp yshop-deploy-*.tar.gz server:/tmp/
ssh server "cd project && sudo ./start-server.sh --skip-build"
```

**方案3：手动创建 Release**
```bash
# 1. 本地编译
./build-local.sh

# 2. 手动创建 Release
gh release create v2.9.0 \
  --title "Release v2.9.0" \
  --notes "Manual release due to CI issues" \
  yshop-deploy-*.tar.gz
```

---

## ✅ 检查清单

部署前检查：

- [ ] 代码已提交且无冲突
- [ ] 所有测试通过
- [ ] 版本号正确
- [ ] Tag 格式正确（v*.*.* ）
- [ ] GitHub Token 权限正确
- [ ] workflow 文件语法正确

构建失败时检查：

- [ ] 查看详细日志
- [ ] 检查网络连接
- [ ] 验证依赖版本
- [ ] 确认磁盘空间
- [ ] 检查权限设置

---

## 📞 快速命令参考

```bash
# 查看 Actions 运行状态
gh run list

# 查看特定 run 的日志
gh run view <run-id> --log

# 重新运行失败的 job
gh run rerun <run-id> --failed

# 删除 tag 和 release
git tag -d v2.9.0
git push origin :refs/tags/v2.9.0
gh release delete v2.9.0 --yes

# 本地测试构建
cd yshop-drink-boot3 && mvn clean package -DskipTests
cd yshop-drink-vue3 && pnpm install && pnpm build
```

---

## 🎯 常见问题 FAQ

### Q1: 为什么我的 Actions 没有运行？

A: 检查：
1. workflow 文件路径是否正确（`.github/workflows/`）
2. tag 格式是否匹配（`v*.*.*`）
3. Actions 是否被禁用

### Q2: 构建成功但没有 Release？

A: 检查：
1. `softprops/action-gh-release` 步骤是否执行
2. GITHUB_TOKEN 权限是否足够
3. 查看 Actions 日志中的错误信息

### Q3: 如何加速构建？

A: 
1. 使用缓存
2. 使用国内镜像
3. 跳过测试（如果可以）
4. 并行构建

### Q4: 可以手动触发构建吗？

A: 可以！在 workflow 中添加：
```yaml
on:
  workflow_dispatch:  # 允许手动触发
```

然后在 GitHub Actions 页面点击 "Run workflow"

---

## 🎉 现在已修复！

所有 actions 都已更新到最新版本：
- ✅ `actions/checkout@v4`
- ✅ `actions/setup-java@v4`
- ✅ `actions/setup-node@v4`
- ✅ `actions/upload-artifact@v4`

**现在可以重新推送 tag 测试了**：

```bash
git pull
git tag v1.0.0
git push origin v1.0.0
```

然后访问 Actions 页面查看构建进度！🚀

---

**更新时间**: 2025-11-25  
**版本**: v1.0

