# nvm 使用说明

## 🎯 什么是 nvm？

**nvm (Node Version Manager)** 是 Node.js 的版本管理工具，可以轻松切换不同的 Node.js 版本。

### 优势

- ✅ 管理多个 Node.js 版本
- ✅ 快速切换版本
- ✅ 无需 sudo 权限安装全局包
- ✅ 项目级版本隔离
- ✅ 更干净的系统环境

---

## 🚀 快速安装

### 方法1：使用安装脚本（推荐）

```bash
# 运行 nvm 安装脚本
./install-nvm.sh
```

这个脚本会：
- ✅ 安装 nvm
- ✅ 安装 Node.js 18 LTS
- ✅ 配置国内镜像
- ✅ 安装 pnpm
- ✅ 设置默认版本

### 方法2：手动安装

```bash
# 1. 安装 nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 2. 加载 nvm
source ~/.bashrc
# 或
source ~/.zshrc

# 3. 配置国内镜像
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
export NVM_IOJS_ORG_MIRROR=https://npmmirror.com/mirrors/iojs

# 4. 安装 Node.js 18
nvm install 18

# 5. 设置默认版本
nvm alias default 18
nvm use 18

# 6. 安装 pnpm
npm install -g pnpm
```

---

## 📋 启动脚本集成

### start-server.sh 现在会自动：

1. **检测 nvm**
   - 自动加载 nvm 环境
   - 识别 nvm 管理的 Node.js

2. **版本检查**
   - 如果版本过低，自动用 nvm 安装 Node.js 18
   - 如果 nvm 未安装，自动安装 nvm

3. **智能安装**
   - 优先使用 nvm 管理
   - 所有操作以实际用户身份执行

### 使用示例

```bash
# 如果已经安装了 nvm
sudo ./start-server.sh
# 脚本会自动检测并使用 nvm 管理的 Node.js

# 如果没有安装 nvm
sudo ./start-server.sh
# 脚本会自动安装 nvm 和 Node.js 18
```

---

## 🎓 nvm 常用命令

### 安装和卸载

```bash
# 安装指定版本
nvm install 18              # 安装 Node.js 18
nvm install 16              # 安装 Node.js 16
nvm install --lts           # 安装最新 LTS 版本

# 卸载版本
nvm uninstall 16
```

### 查看版本

```bash
# 查看已安装的版本
nvm list
nvm ls

# 查看当前使用的版本
nvm current

# 查看可用的远程版本
nvm ls-remote
nvm ls-remote --lts         # 只看 LTS 版本
```

### 切换版本

```bash
# 切换到指定版本
nvm use 18
nvm use 16

# 切换到默认版本
nvm use default

# 在当前 shell 中使用指定版本
nvm exec 18 node app.js
```

### 设置默认版本

```bash
# 设置默认版本（新终端会自动使用）
nvm alias default 18

# 设置其他别名
nvm alias stable 18
nvm alias unstable 19
```

### 查看路径

```bash
# 查看当前 Node.js 路径
nvm which current

# 查看指定版本路径
nvm which 18
```

---

## 🔧 配置文件

### 自动加载 nvm

nvm 会自动在以下文件中添加配置：
- `~/.bashrc` (bash)
- `~/.zshrc` (zsh)
- `~/.profile`

配置内容：
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
```

### 配置国内镜像

在 `~/.bashrc` 或 `~/.zshrc` 中添加：
```bash
# nvm 国内镜像
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
export NVM_IOJS_ORG_MIRROR=https://npmmirror.com/mirrors/iojs
```

---

## 📁 项目级版本管理

### 使用 .nvmrc 文件

在项目根目录创建 `.nvmrc` 文件：
```
18
```

然后在项目目录运行：
```bash
nvm use
# 会自动使用 .nvmrc 中指定的版本
```

### 自动切换版本

在 `~/.bashrc` 或 `~/.zshrc` 中添加：
```bash
# 自动切换 nvm 版本
autoload -U add-zsh-hook
load-nvmrc() {
  if [[ -f .nvmrc && -r .nvmrc ]]; then
    nvm use
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc
```

---

## 🔍 故障排查

### nvm: command not found

**原因**：nvm 未正确加载

**解决**：
```bash
# 重新加载配置
source ~/.bashrc
# 或
source ~/.zshrc

# 或重新登录终端
```

### nvm 安装很慢

**原因**：从国外服务器下载

**解决**：
```bash
# 配置镜像后重试
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
nvm install 18
```

### 权限问题

**原因**：不要使用 sudo

**解决**：
```bash
# ❌ 错误
sudo nvm install 18

# ✅ 正确
nvm install 18
```

### 多个 shell 版本不同

**原因**：每个 shell 独立管理

**解决**：
```bash
# 设置全局默认版本
nvm alias default 18
```

---

## 🎯 最佳实践

### 1. 使用 LTS 版本

```bash
# 安装最新 LTS
nvm install --lts

# 设为默认
nvm alias default lts/*
```

### 2. 项目使用 .nvmrc

在每个项目中创建 `.nvmrc`：
```bash
echo "18" > .nvmrc
```

### 3. 清理旧版本

```bash
# 查看已安装版本
nvm list

# 卸载不需要的版本
nvm uninstall 12
nvm uninstall 14
```

### 4. 定期更新

```bash
# 更新 nvm 本身
cd ~/.nvm
git pull

# 安装最新 LTS
nvm install --lts --latest-npm
```

---

## 📊 与启动脚本配合

### 场景1：全新安装

```bash
# 1. 运行安装脚本
./install-nvm.sh

# 2. 重新加载 shell
source ~/.bashrc

# 3. 运行启动脚本
sudo ./start-server.sh
```

### 场景2：已有 nvm

```bash
# 直接运行启动脚本
sudo ./start-server.sh
# 脚本会自动加载 nvm
```

### 场景3：版本过低

```bash
# 启动脚本会自动提示并安装新版本
sudo ./start-server.sh
# 如果 Node.js < 16，会自动安装 Node.js 18
```

---

## 🔄 版本升级

### 升级 Node.js

```bash
# 1. 安装新版本
nvm install 20

# 2. 迁移全局包
nvm use 20
npm list -g --depth=0          # 查看全局包

# 从旧版本迁移
nvm reinstall-packages 18

# 3. 设置为默认
nvm alias default 20

# 4. 卸载旧版本
nvm uninstall 18
```

### 降级 Node.js

```bash
# 安装旧版本
nvm install 16

# 切换
nvm use 16
nvm alias default 16
```

---

## 🌍 环境变量

### nvm 相关环境变量

```bash
# nvm 安装目录
export NVM_DIR="$HOME/.nvm"

# Node.js 下载镜像
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node

# iojs 下载镜像
export NVM_IOJS_ORG_MIRROR=https://npmmirror.com/mirrors/iojs

# 默认版本
export NVM_DEFAULT_VERSION=18
```

---

## 📞 常见问题

### Q1: nvm 和系统 Node.js 冲突？

A: nvm 管理的 Node.js 优先级更高，不会冲突。建议卸载系统 Node.js：
```bash
sudo apt-get remove nodejs npm
```

### Q2: 为什么 sudo 后找不到 node？

A: sudo 使用不同的环境变量。解决方法：
```bash
# 方法1：使用完整路径
sudo $(which node) app.js

# 方法2：传递环境变量
sudo -E node app.js
```

### Q3: 如何在脚本中使用 nvm？

A: 在脚本开头添加：
```bash
#!/bin/bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 18
```

### Q4: 如何完全卸载 nvm？

A: 
```bash
# 1. 删除 nvm 目录
rm -rf ~/.nvm

# 2. 删除配置
# 编辑 ~/.bashrc 或 ~/.zshrc
# 删除 nvm 相关的行
```

---

## 🎉 总结

使用 nvm 的好处：
- ✅ 灵活管理多个 Node.js 版本
- ✅ 无需 sudo 权限
- ✅ 项目间版本隔离
- ✅ 快速切换和测试

现在 `start-server.sh` 已经完全支持 nvm，会自动：
- 检测并加载 nvm
- 安装所需版本
- 配置国内镜像

直接运行即可：
```bash
sudo ./start-server.sh
```

---

**更新时间**: 2025-11-25
**版本**: v1.0

