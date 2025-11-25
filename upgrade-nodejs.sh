#!/bin/bash

################################################################################
# Node.js 升级脚本
# 自动升级 Node.js 到 v18 LTS 并安装 pnpm
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

# 检查是否使用 sudo
if [ "$EUID" -ne 0 ]; then
    log_error "请使用 sudo 运行此脚本"
    log_info "正确用法: sudo ./upgrade-nodejs.sh"
    exit 1
fi

echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}  Node.js 升级脚本${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""

# 显示当前版本
log_info "当前 Node.js 版本："
if command -v node >/dev/null 2>&1; then
    node -v
else
    echo "  未安装"
fi

log_info "当前 npm 版本："
if command -v npm >/dev/null 2>&1; then
    npm -v
else
    echo "  未安装"
fi

echo ""
read -p "是否继续升级到 Node.js 18 LTS? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "取消升级"
    exit 0
fi

# 1. 卸载旧版本
log_info "卸载旧版本 Node.js..."
apt-get remove --purge -y nodejs npm 2>/dev/null || true
apt-get autoremove -y

# 清理残留文件
log_info "清理残留文件..."
rm -rf /usr/local/bin/npm 2>/dev/null || true
rm -rf /usr/local/share/man/man1/node* 2>/dev/null || true
rm -rf /usr/local/lib/dtrace/node.d 2>/dev/null || true

log_success "旧版本卸载完成"

# 2. 添加 NodeSource 仓库
log_info "添加 NodeSource 仓库（Node.js 18 LTS）..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -

if [ $? -ne 0 ]; then
    log_error "添加仓库失败"
    exit 1
fi

log_success "仓库添加成功"

# 3. 安装 Node.js
log_info "安装 Node.js 18 LTS..."
apt-get install -y nodejs

if [ $? -ne 0 ]; then
    log_error "Node.js 安装失败"
    exit 1
fi

log_success "Node.js 安装完成"

# 4. 验证安装
log_info "验证安装..."
echo ""

if command -v node >/dev/null 2>&1; then
    NODE_VERSION=$(node -v)
    log_success "Node.js 版本: ${NODE_VERSION}"
else
    log_error "Node.js 安装失败"
    exit 1
fi

if command -v npm >/dev/null 2>&1; then
    NPM_VERSION=$(npm -v)
    log_success "npm 版本: ${NPM_VERSION}"
else
    log_error "npm 未找到"
    exit 1
fi

# 5. 安装 pnpm
log_info "安装 pnpm..."
npm install -g pnpm

if [ $? -ne 0 ]; then
    log_error "pnpm 安装失败"
    exit 1
fi

if command -v pnpm >/dev/null 2>&1; then
    PNPM_VERSION=$(pnpm -v)
    log_success "pnpm 版本: ${PNPM_VERSION}"
else
    log_error "pnpm 安装失败"
    exit 1
fi

# 6. 配置 npm 和 pnpm 镜像
log_info "配置国内镜像源..."
npm config set registry https://registry.npmmirror.com
pnpm config set registry https://registry.npmmirror.com
log_success "镜像源配置完成"

# 完成
echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}✅ 升级完成！${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo -e "Node.js: ${GREEN}${NODE_VERSION}${NC}"
echo -e "npm:     ${GREEN}${NPM_VERSION}${NC}"
echo -e "pnpm:    ${GREEN}${PNPM_VERSION}${NC}"
echo ""
log_info "现在可以运行启动脚本了："
echo "  sudo ./start-server.sh"
echo ""

