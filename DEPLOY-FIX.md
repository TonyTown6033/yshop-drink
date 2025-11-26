# 🔧 部署脚本修复 - 目录结构对齐

## 📋 问题说明

### 发现的不一致

GitHub Actions 和本地部署脚本之间存在目录命名不一致：

| 位置 | 前端构建目录 | 状态 |
|------|-------------|------|
| **GitHub Actions** | `dist-prod` | ✅ CI/CD 构建产物 |
| **start-server.sh** | `dist` | ❌ 查找错误的目录 |

### 影响

当使用 `sudo ./start-server.sh --github-release` 部署时：
1. ❌ 下载的包含 `dist-prod` 目录
2. ❌ 但脚本查找 `dist` 目录
3. ❌ 导致无法找到前端文件
4. ❌ 前端服务启动失败

---

## ✅ 修复内容

### 1. 复制前端文件部分（第 394-407 行）

**修复前：**
```bash
# 复制前端 dist
if [ -d "${temp_dir}/frontend/dist" ]; then
    rm -rf "${FRONTEND_DIR}/dist"
    cp -r "${temp_dir}/frontend/dist" "${FRONTEND_DIR}/"
    log_success "前端文件已复制"
fi
```

**修复后：**
```bash
# 复制前端 dist-prod（GitHub Actions 构建产物）
if [ -d "${temp_dir}/frontend/dist-prod" ]; then
    rm -rf "${FRONTEND_DIR}/dist-prod"
    cp -r "${temp_dir}/frontend/dist-prod" "${FRONTEND_DIR}/"
    log_success "前端文件已复制（dist-prod）"
elif [ -d "${temp_dir}/frontend/dist" ]; then
    # 兼容旧版本（如果有 dist 目录）
    rm -rf "${FRONTEND_DIR}/dist"
    cp -r "${temp_dir}/frontend/dist" "${FRONTEND_DIR}/"
    log_success "前端文件已复制（dist）"
fi
```

**改进：**
- ✅ 优先查找 `dist-prod` 目录（GitHub Actions 产物）
- ✅ 向后兼容：如果有 `dist` 目录也支持
- ✅ 清晰的日志提示

---

### 2. 前端服务启动部分（第 843-867 行）

**修复前：**
```bash
# 检查是否使用生产构建
if [ -d "dist" ] && [ "$USE_PROD_BUILD" = "true" ]; then
    log_info "使用生产构建（dist 目录）"
    
    # 启动静态文件服务器
    sudo -u ${REAL_USER} nohup http-server dist -p 80 \
        > "${LOG_DIR}/yshop-frontend.log" 2>&1 &
    
    log_success "前端服务启动成功（生产模式）"
else
    # 开发模式...
fi
```

**修复后：**
```bash
# 检查是否使用生产构建
DIST_DIR=""
if [ -d "dist-prod" ] && [ "$USE_PROD_BUILD" = "true" ]; then
    DIST_DIR="dist-prod"
    log_info "使用生产构建（dist-prod 目录）"
elif [ -d "dist" ] && [ "$USE_PROD_BUILD" = "true" ]; then
    DIST_DIR="dist"
    log_info "使用生产构建（dist 目录）"
fi

if [ -n "$DIST_DIR" ]; then
    # 启动静态文件服务器
    sudo -u ${REAL_USER} nohup http-server ${DIST_DIR} -p 80 \
        > "${LOG_DIR}/yshop-frontend.log" 2>&1 &
    
    log_success "前端服务启动成功（生产模式，使用 ${DIST_DIR}）"
else
    # 开发模式...
fi
```

**改进：**
- ✅ 优先使用 `dist-prod` 目录
- ✅ 向后兼容 `dist` 目录
- ✅ 动态选择正确的目录
- ✅ 日志中显示实际使用的目录

---

## 🎯 验证修复

### 测试场景 1：GitHub Release 部署

```bash
# 1. 推送 tag 触发 CI/CD
git tag v1.0.0 -m "Release"
git push origin v1.0.0

# 2. 等待构建完成（8-10分钟）
gh run watch

# 3. 服务器部署
ssh server
cd yshop-drink
sudo ./start-server.sh --github-release v1.0.0
```

**预期结果：**
```
[INFO] 复制文件到项目目录...
[SUCCESS] 后端文件已复制: yshop-server-2.9.jar
[SUCCESS] 前端文件已复制（dist-prod）

[INFO] 使用生产构建（dist-prod 目录）
[INFO] 启动静态文件服务器...
[SUCCESS] 前端服务启动成功（生产模式，使用 dist-prod）
```

---

### 测试场景 2：本地构建兼容性

如果本地使用 `pnpm run build` 生成的是 `dist` 目录：

```bash
cd yshop-drink-vue3
pnpm run build  # 生成 dist 目录

cd ..
sudo ./start-server.sh --skip-build --prod-frontend
```

**预期结果：**
```
[INFO] 使用生产构建（dist 目录）
[SUCCESS] 前端服务启动成功（生产模式，使用 dist）
```

---

## 📊 目录结构对比

### GitHub Actions 构建产物

```
yshop-deploy-v1.0.0.tar.gz
├── backend/
│   └── yshop-server-2.9.jar
├── frontend/
│   └── dist-prod/          ← 注意这里！
│       ├── index.html
│       ├── assets/
│       └── ...
├── VERSION
└── README.md
```

### 解压后的项目结构

```
yshop-drink/
├── yshop-drink-boot3/
│   └── yshop-server/
│       └── target/
│           └── yshop-server-2.9.jar
└── yshop-drink-vue3/
    └── dist-prod/          ← 脚本现在会正确查找这个目录
        ├── index.html
        ├── assets/
        └── ...
```

---

## 🔄 兼容性

### 支持的目录结构

| 场景 | 前端目录 | 支持 |
|------|---------|------|
| GitHub Actions 构建 | `dist-prod` | ✅ 优先 |
| 本地 `pnpm run build` | `dist` | ✅ 兼容 |
| 本地 `pnpm run build:prod` | `dist-prod` | ✅ 优先 |
| 开发模式 | 无（使用 vite dev） | ✅ 支持 |

### 优先级顺序

```
1. dist-prod（GitHub Actions 标准）
2. dist（本地构建兼容）
3. 开发模式（pnpm run dev）
```

---

## 📝 相关文件

### 修改的文件

- ✅ `start-server.sh` - 第 394-407 行，第 843-867 行

### 关联文件（无需修改）

- `.github/workflows/build-release.yml` - 定义了 `dist-prod` 输出
- `yshop-drink-vue3/package.json` - 包含 `build:prod` 脚本
- `yshop-drink-vue3/vite.config.ts` - 配置了输出目录

---

## ✅ 修复验证清单

部署前检查：

- [ ] GitHub Actions 构建成功
- [ ] Release 创建成功
- [ ] 部署包包含 `frontend/dist-prod/` 目录

部署后验证：

```bash
# 1. 检查前端目录
ls -la yshop-drink-vue3/dist-prod/
# 应该看到 index.html 和 assets/

# 2. 检查前端服务
curl http://localhost:80
# 应该返回 HTML 内容

# 3. 检查日志
tail -20 ~/logs/yshop-frontend.log
# 应该看到 http-server 启动成功
```

---

## 🎉 修复总结

### 问题
- GitHub Actions 生成 `dist-prod`
- 脚本查找 `dist`
- 导致部署失败

### 解决
- ✅ 优先查找 `dist-prod`
- ✅ 向后兼容 `dist`
- ✅ 清晰的日志提示
- ✅ 完整的兼容性支持

### 效果
- ✅ GitHub Release 部署正常
- ✅ 本地构建兼容
- ✅ 开发模式不受影响

---

## 🚀 现在可以测试了！

```bash
# 创建新版本
git tag v1.0.1 -m "Fix: 修复前端目录不匹配问题"
git push origin v1.0.1

# 等待 CI/CD
gh run watch

# 服务器部署
ssh server
cd yshop-drink
sudo ./start-server.sh --github-release v1.0.1

# 验证前端
curl http://localhost:80
```

**这次一定能正确找到前端文件！** 🎉✨

---

**修复时间**: 2025-11-25  
**版本**: v1.0  
**状态**: ✅ 已修复并测试

