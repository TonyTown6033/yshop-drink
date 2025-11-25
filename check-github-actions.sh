#!/bin/bash

################################################################################
# GitHub Actions 配置检查脚本
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
echo -e "${GREEN}  GitHub Actions 配置检查${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# 检查 workflow 文件
WORKFLOW_FILE=".github/workflows/build-release.yml"

if [ ! -f "$WORKFLOW_FILE" ]; then
    log_error "未找到 workflow 文件: $WORKFLOW_FILE"
    exit 1
fi

log_success "Workflow 文件存在"

# 检查 actions 版本
echo ""
log_info "检查 Actions 版本..."

check_action_version() {
    local action=$1
    local expected_version=$2
    local line=$(grep "uses: $action" "$WORKFLOW_FILE" | head -1)
    
    if [ -z "$line" ]; then
        log_warning "未找到 $action"
        return 1
    fi
    
    if echo "$line" | grep -q "@$expected_version"; then
        log_success "$action 版本正确 ($expected_version)"
        return 0
    else
        local found_version=$(echo "$line" | sed -n 's/.*@\([^"]*\).*/\1/p')
        log_error "$action 版本过旧: $found_version (需要 $expected_version)"
        return 1
    fi
}

error_count=0

check_action_version "actions/checkout" "v4" || ((error_count++))
check_action_version "actions/setup-java" "v4" || ((error_count++))
check_action_version "actions/setup-node" "v4" || ((error_count++))
check_action_version "actions/upload-artifact" "v4" || ((error_count++))

# 检查 Git 配置
echo ""
log_info "检查 Git 配置..."

if git remote -v | grep -q "github.com"; then
    REMOTE_URL=$(git remote get-url origin)
    log_success "Git remote 已配置: $REMOTE_URL"
    
    # 提取仓库名
    if [[ $REMOTE_URL =~ github.com[:/](.+/.+)(\.git)?$ ]]; then
        REPO="${BASH_REMATCH[1]}"
        REPO="${REPO%.git}"
        log_info "仓库: $REPO"
    fi
else
    log_warning "未找到 GitHub remote"
    log_info "添加 remote: git remote add origin https://github.com/username/yshop-drink.git"
fi

# 检查是否有未提交的修改
if [ -n "$(git status --porcelain)" ]; then
    log_warning "有未提交的修改"
    git status --short
else
    log_success "工作区干净"
fi

# 检查 tags
echo ""
log_info "检查现有 tags..."

TAG_COUNT=$(git tag | wc -l)
if [ $TAG_COUNT -gt 0 ]; then
    log_success "找到 $TAG_COUNT 个 tag"
    echo ""
    log_info "最近的 tags:"
    git tag --sort=-creatordate | head -5 | while read tag; do
        echo "  - $tag"
    done
else
    log_warning "还没有 tags"
    log_info "创建第一个 tag: git tag v1.0.0 -m \"First release\""
fi

# 检查构建文件
echo ""
log_info "检查项目结构..."

check_file() {
    if [ -e "$1" ]; then
        log_success "$1 存在"
    else
        log_error "$1 不存在"
        ((error_count++))
    fi
}

check_file "yshop-drink-boot3/pom.xml"
check_file "yshop-drink-vue3/package.json"
check_file "yshop-drink-vue3/pnpm-lock.yaml"

# 检查 GitHub CLI
echo ""
log_info "检查工具..."

if command -v gh >/dev/null 2>&1; then
    log_success "GitHub CLI 已安装"
    
    # 检查登录状态
    if gh auth status >/dev/null 2>&1; then
        log_success "GitHub CLI 已登录"
    else
        log_warning "GitHub CLI 未登录"
        log_info "登录: gh auth login"
    fi
else
    log_warning "未安装 GitHub CLI (可选)"
    log_info "安装: brew install gh  # macOS"
    log_info "安装: sudo apt install gh  # Ubuntu"
fi

# 生成测试命令
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}检查结果${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

if [ $error_count -eq 0 ]; then
    log_success "所有检查通过！"
    echo ""
    echo -e "${YELLOW}下一步操作：${NC}"
    echo ""
    echo "1. 确保代码已推送到 GitHub："
    echo "   ${BLUE}git push origin master${NC}"
    echo ""
    echo "2. 创建并推送 tag："
    echo "   ${BLUE}git tag v1.0.0 -m \"First release\"${NC}"
    echo "   ${BLUE}git push origin v1.0.0${NC}"
    echo ""
    echo "3. 查看 Actions 执行："
    if [ -n "$REPO" ]; then
        echo "   ${BLUE}https://github.com/$REPO/actions${NC}"
    else
        echo "   ${BLUE}https://github.com/YOUR_USERNAME/yshop-drink/actions${NC}"
    fi
    echo ""
    echo "4. 等待构建完成后，在服务器部署："
    echo "   ${BLUE}sudo ./start-server.sh --github-release${NC}"
    echo ""
else
    log_error "发现 $error_count 个问题，请先修复"
    echo ""
    echo -e "${YELLOW}修复建议：${NC}"
    echo ""
    echo "1. 更新 Actions 版本："
    echo "   ${BLUE}git pull${NC}  # 拉取最新的 workflow 配置"
    echo ""
    echo "2. 添加 GitHub remote："
    echo "   ${BLUE}git remote add origin https://github.com/username/yshop-drink.git${NC}"
    echo ""
    echo "3. 提交未提交的修改："
    echo "   ${BLUE}git add .${NC}"
    echo "   ${BLUE}git commit -m \"Update configuration\"${NC}"
    echo ""
fi

# 额外建议
echo -e "${YELLOW}💡 小贴士：${NC}"
echo ""
echo "• 查看构建日志: ${BLUE}gh run list${NC} 和 ${BLUE}gh run view <run-id> --log${NC}"
echo "• 测试 workflow 语法: ${BLUE}cat $WORKFLOW_FILE | grep 'uses:'${NC}"
echo "• 重新运行失败的构建: ${BLUE}gh run rerun <run-id> --failed${NC}"
echo ""

exit $error_count

