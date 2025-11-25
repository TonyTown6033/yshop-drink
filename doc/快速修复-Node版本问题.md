# Node.js 版本问题快速修复指南

## 🔍 问题说明

您遇到的错误：
```
[INFO] Node.js 版本: v12.22.9
[ERROR] 未检测到 pnpm，开始安装...
sudo: npm: command not found
```

**问题原因**：
1. Node.js 版本过低（v12.22.9），项目需要 v16+
2. npm 命令找不到，可能 Node.js 安装不完整

---

## 🚀 解决方案

### 方案1：使用 NodeSource 仓库升级（推荐）

```bash
# 1. 添加 NodeSource 仓库（Node.js 18 LTS）
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# 2. 安装 Node.js
sudo apt-get install -y nodejs

# 3. 验证安装
node -v    # 应该显示 v18.x.x
npm -v     # 应该显示 npm 版本

# 4. 安装 pnpm
sudo npm install -g pnpm

# 5. 验证 pnpm
pnpm -v
```

### 方案2：使用 nvm 管理 Node.js 版本

```bash
# 1. 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 2. 重新加载配置
source ~/.bashrc
# 或
source ~/.zshrc

# 3. 安装 Node.js 18
nvm install 18

# 4. 设置默认版本
nvm use 18
nvm alias default 18

# 5. 验证
node -v
npm -v

# 6. 安装 pnpm
npm install -g pnpm
```

### 方案3：完全卸载后重新安装

```bash
# 1. 卸载旧版本 Node.js
sudo apt-get remove --purge nodejs npm
sudo apt-get autoremove

# 2. 清理残留文件
sudo rm -rf /usr/local/bin/npm
sudo rm -rf /usr/local/share/man/man1/node*
sudo rm -rf /usr/local/lib/dtrace/node.d
sudo rm -rf ~/.npm
sudo rm -rf ~/.node-gyp

# 3. 添加 NodeSource 仓库
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# 4. 安装 Node.js
sudo apt-get install -y nodejs

# 5. 验证
node -v
npm -v

# 6. 安装 pnpm
sudo npm install -g pnpm
```

---

## ✅ 验证安装

运行以下命令验证：

```bash
# 检查 Node.js 版本（应该是 v16+ 或 v18+）
node -v

# 检查 npm 版本
npm -v

# 检查 pnpm 版本
pnpm -v

# 测试 npm 是否工作
npm --version
```

预期输出：
```
v18.18.0  # Node.js
9.8.1     # npm
8.10.0    # pnpm
```

---

## 🔄 完成后重新运行脚本

```bash
# 进入项目目录
cd /path/to/yshop-drink

# 使用 sudo 运行启动脚本
sudo ./start-server.sh
```

---

## 📋 版本要求

### 项目要求的最低版本

- **Node.js**: v16.0.0 或更高（推荐 v18 LTS）
- **npm**: 8.0.0 或更高
- **pnpm**: 8.0.0 或更高

### 推荐版本

- **Node.js**: v18.18.0（LTS）
- **npm**: 9.8.1
- **pnpm**: 8.10.0

---

## ⚠️ 常见问题

### Q1: 为什么 npm 找不到？

A: Node.js v12 可能安装不完整，或者通过 snap 安装导致路径问题。建议使用 NodeSource 仓库重新安装。

### Q2: 安装后还是提示版本过低怎么办？

A: 可能有多个 Node.js 版本，检查：
```bash
which node
which npm

# 查看所有 node 位置
whereis node

# 使用 nvm 管理版本
nvm list
nvm use 18
```

### Q3: 使用 snap 安装的 Node.js 可以吗？

A: 不推荐。snap 安装的 Node.js 可能有权限问题，建议使用 NodeSource 或 nvm。

### Q4: 能用 apt 直接安装吗？

A: Ubuntu 默认仓库的 Node.js 版本太老，必须使用 NodeSource 仓库。

---

## 🛠️ 故障排查

### 检查当前安装的 Node.js

```bash
# 查看 Node.js 信息
node -v
npm -v
which node
which npm

# 查看 Node.js 安装路径
ls -la $(which node)
ls -la $(which npm)

# 检查 Node.js 包来源
dpkg -l | grep nodejs
```

### 如果 npm 报错

```bash
# 修复 npm 缓存
npm cache clean --force

# 重新安装 npm
sudo apt-get install --reinstall npm

# 或者通过 n 模块修复
sudo npm install -g n
sudo n stable
```

---

## 📝 安装日志

如果遇到问题，保存安装日志：

```bash
# 保存安装过程
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - 2>&1 | tee ~/nodejs-install.log
sudo apt-get install -y nodejs 2>&1 | tee -a ~/nodejs-install.log

# 查看日志
cat ~/nodejs-install.log
```

---

## 🎯 推荐配置（Ubuntu 20.04+）

```bash
# 一键安装脚本
cat > ~/install-nodejs.sh << 'EOF'
#!/bin/bash
set -e

echo "卸载旧版本..."
sudo apt-get remove --purge -y nodejs npm 2>/dev/null || true
sudo apt-get autoremove -y

echo "添加 NodeSource 仓库..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

echo "安装 Node.js..."
sudo apt-get install -y nodejs

echo "验证安装..."
node -v
npm -v

echo "安装 pnpm..."
sudo npm install -g pnpm

echo "验证 pnpm..."
pnpm -v

echo ""
echo "✅ 安装完成！"
echo "Node.js: $(node -v)"
echo "npm: $(npm -v)"
echo "pnpm: $(pnpm -v)"
EOF

# 添加执行权限
chmod +x ~/install-nodejs.sh

# 运行安装脚本
~/install-nodejs.sh
```

---

## 📞 需要帮助？

如果问题仍然存在，请提供：

1. **系统信息**
```bash
lsb_release -a
uname -a
```

2. **当前 Node.js 状态**
```bash
node -v
npm -v
which node
which npm
dpkg -l | grep nodejs
```

3. **错误日志**
```bash
cat ~/nodejs-install.log
```

---

**更新时间**: 2025-11-25

