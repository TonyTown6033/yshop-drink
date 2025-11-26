#!/bin/bash

################################################################################
# 测试 GitHub Release 下载功能
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}测试 GitHub Release 下载功能${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

REPO="TonyTown6033/yshop-drink"
PASS=0
FAIL=0

# 测试 1: 检查仓库是否存在
echo -e "${YELLOW}[测试 1]${NC} 检查 GitHub 仓库..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://github.com/${REPO}")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "  ${GREEN}✓${NC} 仓库存在: https://github.com/${REPO}"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} 仓库不存在或无法访问 (HTTP $HTTP_CODE)"
    FAIL=$((FAIL + 1))
fi

# 测试 2: 获取最新版本
echo -e "${YELLOW}[测试 2]${NC} 获取最新版本..."
LATEST_VERSION=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -n "$LATEST_VERSION" ]; then
    echo -e "  ${GREEN}✓${NC} 最新版本: ${LATEST_VERSION}"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} 无法获取最新版本"
    FAIL=$((FAIL + 1))
    # 尝试备用方法
    echo -e "  ${YELLOW}→${NC} 尝试备用方法..."
    LATEST_VERSION=$(curl -sL "https://github.com/${REPO}/releases" | grep -oP 'releases/tag/\K[^"]+' | head -n 1)
    if [ -n "$LATEST_VERSION" ]; then
        echo -e "  ${GREEN}✓${NC} 备用方法成功: ${LATEST_VERSION}"
        PASS=$((PASS + 1))
    fi
fi

if [ -z "$LATEST_VERSION" ]; then
    echo -e "${RED}无法继续测试，请检查网络连接或仓库状态${NC}"
    exit 1
fi

# 测试 3: 检查 Release 页面
echo -e "${YELLOW}[测试 3]${NC} 检查 Release 页面..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://github.com/${REPO}/releases/tag/${LATEST_VERSION}")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "  ${GREEN}✓${NC} Release 页面存在"
    echo -e "  ${BLUE}→${NC} https://github.com/${REPO}/releases/tag/${LATEST_VERSION}"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} Release 页面不存在 (HTTP $HTTP_CODE)"
    FAIL=$((FAIL + 1))
fi

# 测试 4: 检查部署包是否存在
echo -e "${YELLOW}[测试 4]${NC} 检查部署包文件..."
PACKAGE_NAME="yshop-deploy-${LATEST_VERSION}.tar.gz"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_VERSION}/${PACKAGE_NAME}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L "$DOWNLOAD_URL")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "  ${GREEN}✓${NC} 部署包存在: ${PACKAGE_NAME}"
    echo -e "  ${BLUE}→${NC} ${DOWNLOAD_URL}"
    PASS=$((PASS + 1))
    
    # 获取文件大小
    FILE_SIZE=$(curl -sI -L "$DOWNLOAD_URL" | grep -i content-length | awk '{print $2}' | tr -d '\r')
    if [ -n "$FILE_SIZE" ]; then
        FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
        echo -e "  ${BLUE}→${NC} 文件大小: ${FILE_SIZE_MB} MB"
    fi
else
    echo -e "  ${RED}✗${NC} 部署包不存在 (HTTP $HTTP_CODE)"
    echo -e "  ${RED}→${NC} ${DOWNLOAD_URL}"
    FAIL=$((FAIL + 1))
fi

# 测试 5: 检查校验文件
echo -e "${YELLOW}[测试 5]${NC} 检查 SHA256 校验文件..."
CHECKSUM_URL="${DOWNLOAD_URL}.sha256"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -L "$CHECKSUM_URL")
if [ "$HTTP_CODE" = "200" ]; then
    echo -e "  ${GREEN}✓${NC} 校验文件存在"
    PASS=$((PASS + 1))
else
    echo -e "  ${YELLOW}⚠${NC} 校验文件不存在 (HTTP $HTTP_CODE)"
    echo -e "  ${YELLOW}→${NC} 不影响部署，但建议添加"
fi

# 测试 6: 检查 start-server.sh
echo -e "${YELLOW}[测试 6]${NC} 检查 start-server.sh 脚本..."
if [ -f "start-server.sh" ]; then
    echo -e "  ${GREEN}✓${NC} start-server.sh 存在"
    PASS=$((PASS + 1))
    
    # 检查是否可执行
    if [ -x "start-server.sh" ]; then
        echo -e "  ${GREEN}✓${NC} start-server.sh 可执行"
    else
        echo -e "  ${YELLOW}⚠${NC} start-server.sh 不可执行"
        echo -e "  ${YELLOW}→${NC} 运行: chmod +x start-server.sh"
    fi
    
    # 检查是否包含 --github-release 支持
    if grep -q "github-release" start-server.sh; then
        echo -e "  ${GREEN}✓${NC} 支持 --github-release 参数"
    else
        echo -e "  ${RED}✗${NC} 不支持 --github-release 参数"
        FAIL=$((FAIL + 1))
    fi
else
    echo -e "  ${RED}✗${NC} start-server.sh 不存在"
    FAIL=$((FAIL + 1))
fi

# 测试 7: 测试下载（小文件测试）
echo -e "${YELLOW}[测试 7]${NC} 测试下载速度（下载前 1KB）..."
START_TIME=$(date +%s)
curl -s -r 0-1023 -L "$DOWNLOAD_URL" -o /dev/null 2>/dev/null
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
if [ $ELAPSED -lt 10 ]; then
    echo -e "  ${GREEN}✓${NC} 下载速度正常 (${ELAPSED}秒)"
    PASS=$((PASS + 1))
else
    echo -e "  ${YELLOW}⚠${NC} 下载速度较慢 (${ELAPSED}秒)"
    echo -e "  ${YELLOW}→${NC} 可能需要使用代理或手动下载"
fi

# 显示结果
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}测试结果${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "通过: ${GREEN}${PASS}${NC} / $((PASS + FAIL))"
echo -e "失败: ${RED}${FAIL}${NC} / $((PASS + FAIL))"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ 所有测试通过！${NC}"
    echo -e "${GREEN}✓ 可以使用以下命令部署：${NC}"
    echo ""
    echo -e "  ${BLUE}sudo ./start-server.sh --github-release${NC}"
    echo ""
    echo -e "或指定版本："
    echo ""
    echo -e "  ${BLUE}sudo ./start-server.sh --github-release ${LATEST_VERSION}${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ 有 ${FAIL} 个测试失败${NC}"
    echo ""
    echo -e "${YELLOW}建议：${NC}"
    echo "  1. 检查网络连接"
    echo "  2. 检查 Release 是否已发布"
    echo "  3. 查看详细信息: https://github.com/${REPO}/releases"
    echo ""
    exit 1
fi

