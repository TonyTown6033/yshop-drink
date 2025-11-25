#!/bin/bash

################################################################################
# 前端构建测试脚本
# 在推送到 GitHub 前，先在本地验证构建是否成功
################################################################################

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
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  前端构建测试${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# 进入前端目录
cd yshop-drink-vue3

# 检查 package.json
if [ ! -f "package.json" ]; then
    log_error "未找到 package.json"
    exit 1
fi

log_success "找到 package.json"

# 检查可用的构建脚本
echo ""
log_info "可用的构建脚本："
cat package.json | grep '"build:' | sed 's/^[[:space:]]*/  /'

# 检查 pnpm
echo ""
if ! command -v pnpm >/dev/null 2>&1; then
    log_error "未安装 pnpm"
    log_info "安装: npm install -g pnpm"
    exit 1
fi

PNPM_VERSION=$(pnpm -v)
log_success "pnpm 版本: ${PNPM_VERSION}"

# 询问是否继续
echo ""
read -p "是否测试构建? (y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "取消测试"
    exit 0
fi

# 选择构建模式
echo ""
log_info "选择构建模式:"
echo "  1) build:prod  - 生产环境 (推荐，GitHub Actions 使用)"
echo "  2) build:local - 本地环境"
echo "  3) build:dev   - 开发环境"
echo ""
read -p "请选择 [1-3] (默认: 1): " choice
choice=${choice:-1}

case $choice in
    1)
        BUILD_CMD="build:prod"
        ;;
    2)
        BUILD_CMD="build:local"
        ;;
    3)
        BUILD_CMD="build:dev"
        ;;
    *)
        log_error "无效选择"
        exit 1
        ;;
esac

log_info "使用构建命令: pnpm run ${BUILD_CMD}"

# 清理旧构建
echo ""
if [ -d "dist" ]; then
    log_info "清理旧的 dist 目录..."
    rm -rf dist
fi

# 安装依赖
echo ""
log_info "安装依赖..."
log_warning "这可能需要几分钟..."

if pnpm install --no-frozen-lockfile 2>&1 | tee /tmp/pnpm-install.log; then
    log_success "依赖安装成功"
    
    # 检查警告
    if grep -q "WARN" /tmp/pnpm-install.log; then
        log_warning "安装过程有警告（通常可以忽略）"
        grep "WARN" /tmp/pnpm-install.log | head -5
    fi
else
    log_error "依赖安装失败"
    cat /tmp/pnpm-install.log
    exit 1
fi

# 构建
echo ""
log_info "开始构建..."
log_warning "这可能需要 1-2 分钟..."

START_TIME=$(date +%s)

if pnpm run ${BUILD_CMD} 2>&1 | tee /tmp/pnpm-build.log; then
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    log_success "构建成功！"
    log_info "构建耗时: ${DURATION} 秒"
else
    log_error "构建失败"
    cat /tmp/pnpm-build.log
    exit 1
fi

# 验证构建产物
echo ""
log_info "验证构建产物..."

if [ ! -d "dist" ]; then
    log_error "未找到 dist 目录"
    exit 1
fi

if [ ! -f "dist/index.html" ]; then
    log_error "未找到 index.html"
    exit 1
fi

log_success "dist 目录存在"
log_success "index.html 存在"

# 统计信息
echo ""
log_info "构建产物统计:"

FILE_COUNT=$(find dist -type f | wc -l)
TOTAL_SIZE=$(du -sh dist | cut -f1)

echo "  文件数量: ${FILE_COUNT}"
echo "  总大小: ${TOTAL_SIZE}"

# 显示主要文件
echo ""
log_info "主要文件:"
ls -lh dist/index.html dist/assets/ 2>/dev/null | head -10

# 完成
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}✅ 测试完成！${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

log_success "前端构建测试成功"
echo ""
log_info "可以推送到 GitHub 了："
echo "  ${BLUE}git tag v1.0.0 -m \"Release v1.0.0\"${NC}"
echo "  ${BLUE}git push origin v1.0.0${NC}"
echo ""

# 询问是否预览
read -p "是否启动本地预览? (y/n) " -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "启动预览服务器..."
    log_info "访问: http://localhost:4173"
    log_info "按 Ctrl+C 停止"
    echo ""
    pnpm run serve:prod
fi

