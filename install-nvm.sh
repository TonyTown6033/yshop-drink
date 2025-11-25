#!/bin/bash

################################################################################
# nvm + Node.js 18 安装脚本
# 使用 nvm 管理 Node.js 版本
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  nvm + Node.js 安装脚本${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""

# 检查当前 Node.js 版本
log_info "当前环境："
if command -v node >/dev/null 2>&1; then
    echo "  Node.js: $(node -v)"
else
    echo "  Node.js: 未安装"
fi

if command -v npm >/dev/null 2>&1; then
    echo "  npm: $(npm -v)"
else
    echo "  npm: 未安装"
fi

# 检查 nvm 是否已安装
NVM_DIR="${HOME}/.nvm"
if [ -d "$NVM_DIR" ]; then
    log_warning "nvm 已安装"
    
    # 加载 nvm
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    
    if command -v nvm >/dev/null 2>&1; then
        log_info "nvm 版本: $(nvm --version)"
    fi
else
    echo ""
    log_info "开始安装 nvm..."
    
    # 安装 nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
    
    if [ $? -ne 0 ]; then
        log_error "nvm 安装失败"
        exit 1
    fi
    
    log_success "nvm 安装完成"
fi

# 加载 nvm
export NVM_DIR="${HOME}/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

# 验证 nvm
if ! command -v nvm >/dev/null 2>&1; then
    log_error "nvm 加载失败"
    log_info "请手动运行以下命令："
    echo "  source ~/.bashrc"
    echo "  或"
    echo "  source ~/.zshrc"
    exit 1
fi

log_success "nvm 已就绪"

# 配置 nvm 国内镜像
log_info "配置 nvm 国内镜像..."
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
export NVM_IOJS_ORG_MIRROR=https://npmmirror.com/mirrors/iojs

# 写入配置文件
SHELL_RC="${HOME}/.bashrc"
if [ -f "${HOME}/.zshrc" ]; then
    SHELL_RC="${HOME}/.zshrc"
fi

if ! grep -q "NVM_NODEJS_ORG_MIRROR" "$SHELL_RC" 2>/dev/null; then
    echo '' >> "$SHELL_RC"
    echo '# nvm 国内镜像' >> "$SHELL_RC"
    echo 'export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node' >> "$SHELL_RC"
    echo 'export NVM_IOJS_ORG_MIRROR=https://npmmirror.com/mirrors/iojs' >> "$SHELL_RC"
    log_success "镜像配置已写入 $SHELL_RC"
fi

# 显示可用版本
log_info "查看可用的 Node.js LTS 版本..."
nvm ls-remote --lts | tail -5

echo ""
read -p "是否安装 Node.js 18 LTS? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "取消安装"
    exit 0
fi

# 安装 Node.js 18
log_info "安装 Node.js 18 LTS..."
nvm install 18

if [ $? -ne 0 ]; then
    log_error "Node.js 安装失败"
    exit 1
fi

# 设置为默认版本
log_info "设置 Node.js 18 为默认版本..."
nvm alias default 18
nvm use 18

# 验证安装
NODE_VERSION=$(node -v)
NPM_VERSION=$(npm -v)

log_success "Node.js 安装完成"
log_info "Node.js 版本: ${NODE_VERSION}"
log_info "npm 版本: ${NPM_VERSION}"

# 配置 npm 镜像
log_info "配置 npm 淘宝镜像..."
npm config set registry https://registry.npmmirror.com
log_success "npm 镜像配置完成"

# 安装 pnpm
log_info "安装 pnpm..."
npm install -g pnpm

if [ $? -ne 0 ]; then
    log_error "pnpm 安装失败"
    exit 1
fi

# 验证 pnpm
if command -v pnpm >/dev/null 2>&1; then
    PNPM_VERSION=$(pnpm -v)
    log_success "pnpm 安装完成"
    log_info "pnpm 版本: ${PNPM_VERSION}"
    
    # 配置 pnpm 镜像
    log_info "配置 pnpm 淘宝镜像..."
    pnpm config set registry https://registry.npmmirror.com
    log_success "pnpm 镜像配置完成"
else
    log_error "pnpm 安装失败"
    exit 1
fi

# 显示安装的 Node.js 版本列表
echo ""
log_info "已安装的 Node.js 版本："
nvm list

# 完成
echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}✅ 安装完成！${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo -e "Node.js: ${GREEN}${NODE_VERSION}${NC}"
echo -e "npm:     ${GREEN}${NPM_VERSION}${NC}"
echo -e "pnpm:    ${GREEN}${PNPM_VERSION}${NC}"
echo ""
log_info "nvm 常用命令："
echo "  nvm list              # 查看已安装版本"
echo "  nvm install 18        # 安装 Node.js 18"
echo "  nvm use 18            # 切换到 Node.js 18"
echo "  nvm alias default 18  # 设置默认版本"
echo "  nvm current           # 查看当前版本"
echo ""
log_warning "重要：请重新加载 shell 配置"
echo "  source ~/.bashrc"
echo "  或"
echo "  source ~/.zshrc"
echo ""
log_info "然后运行启动脚本："
echo "  sudo ./start-server.sh"
echo ""

