#!/bin/bash

################################################################################
# 测试脚本 - 验证部署目录修复
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}测试部署脚本目录修复${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

FRONTEND_DIR="./yshop-drink-vue3"
PASS=0
FAIL=0

# 测试 1: 检查 dist-prod 目录
echo -e "${YELLOW}[测试 1]${NC} 检查 dist-prod 目录支持..."
if grep -q "dist-prod" start-server.sh; then
    echo -e "  ${GREEN}✓${NC} start-server.sh 包含 dist-prod 支持"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} start-server.sh 不包含 dist-prod 支持"
    FAIL=$((FAIL + 1))
fi

# 测试 2: 检查向后兼容性
echo -e "${YELLOW}[测试 2]${NC} 检查 dist 目录向后兼容..."
if grep -q 'elif \[ -d "dist" \]' start-server.sh; then
    echo -e "  ${GREEN}✓${NC} start-server.sh 支持 dist 目录向后兼容"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} start-server.sh 不支持 dist 目录向后兼容"
    FAIL=$((FAIL + 1))
fi

# 测试 3: 检查复制逻辑
echo -e "${YELLOW}[测试 3]${NC} 检查前端文件复制逻辑..."
if grep -q 'frontend/dist-prod' start-server.sh; then
    echo -e "  ${GREEN}✓${NC} start-server.sh 正确处理 frontend/dist-prod"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} start-server.sh 未正确处理 frontend/dist-prod"
    FAIL=$((FAIL + 1))
fi

# 测试 4: 检查 GitHub Actions 配置
echo -e "${YELLOW}[测试 4]${NC} 检查 GitHub Actions 构建配置..."
if grep -q 'dist-prod' .github/workflows/build-release.yml; then
    echo -e "  ${GREEN}✓${NC} GitHub Actions 配置输出 dist-prod"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} GitHub Actions 配置未输出 dist-prod"
    FAIL=$((FAIL + 1))
fi

# 测试 5: 检查日志提示
echo -e "${YELLOW}[测试 5]${NC} 检查日志提示信息..."
if grep -q '使用生产构建（dist-prod 目录）' start-server.sh; then
    echo -e "  ${GREEN}✓${NC} start-server.sh 包含 dist-prod 日志提示"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} start-server.sh 缺少 dist-prod 日志提示"
    FAIL=$((FAIL + 1))
fi

# 测试 6: 检查动态目录选择
echo -e "${YELLOW}[测试 6]${NC} 检查动态目录选择逻辑..."
if grep -q 'DIST_DIR=""' start-server.sh; then
    echo -e "  ${GREEN}✓${NC} start-server.sh 使用动态目录变量"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} start-server.sh 未使用动态目录变量"
    FAIL=$((FAIL + 1))
fi

# 测试 7: 检查 http-server 启动命令
echo -e "${YELLOW}[测试 7]${NC} 检查 http-server 启动命令..."
if grep -q 'http-server ${DIST_DIR}' start-server.sh; then
    echo -e "  ${GREEN}✓${NC} http-server 使用动态目录"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} http-server 未使用动态目录"
    FAIL=$((FAIL + 1))
fi

# 测试 8: 检查文档一致性
echo -e "${YELLOW}[测试 8]${NC} 检查部署文档一致性..."
if grep -q 'dist-prod' SERVER-DEPLOY.md; then
    echo -e "  ${GREEN}✓${NC} SERVER-DEPLOY.md 提到 dist-prod"
    PASS=$((PASS + 1))
else
    echo -e "  ${RED}✗${NC} SERVER-DEPLOY.md 未提到 dist-prod"
    FAIL=$((FAIL + 1))
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
    echo -e "${GREEN}✓ 部署脚本已正确修复，支持 dist-prod 目录${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}✗ 有 ${FAIL} 个测试失败${NC}"
    echo -e "${YELLOW}请检查相关配置${NC}"
    echo ""
    exit 1
fi

