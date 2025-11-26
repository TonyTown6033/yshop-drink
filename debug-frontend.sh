#!/bin/bash

################################################################################
# 调试前端启动问题
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}调试前端启动问题${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="${PROJECT_DIR}/yshop-drink-vue3"

echo -e "${YELLOW}[1] 检查前端目录${NC}"
echo "前端目录: ${FRONTEND_DIR}"
if [ -d "${FRONTEND_DIR}" ]; then
    echo -e "${GREEN}✓ 前端目录存在${NC}"
else
    echo -e "${RED}✗ 前端目录不存在${NC}"
    exit 1
fi
echo ""

echo -e "${YELLOW}[2] 检查 dist-prod 目录${NC}"
cd "${FRONTEND_DIR}"
if [ -d "dist-prod" ]; then
    echo -e "${GREEN}✓ dist-prod 目录存在${NC}"
    echo "  文件列表:"
    ls -lh dist-prod/ | head -10
else
    echo -e "${RED}✗ dist-prod 目录不存在${NC}"
    if [ -d "dist" ]; then
        echo -e "${YELLOW}→ 找到 dist 目录${NC}"
    fi
fi
echo ""

echo -e "${YELLOW}[3] 检查 http-server${NC}"
if command -v http-server >/dev/null 2>&1; then
    echo -e "${GREEN}✓ http-server 已安装${NC}"
    echo "  版本: $(http-server --version 2>&1 | head -1)"
else
    echo -e "${RED}✗ http-server 未安装${NC}"
    echo "  安装命令: sudo npm install -g http-server"
fi
echo ""

echo -e "${YELLOW}[4] 检查端口 80${NC}"
if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
    PID=$(lsof -ti :80 2>/dev/null)
    PROCESS=$(ps -p $PID -o comm= 2>/dev/null)
    echo -e "${RED}✗ 端口 80 已被占用${NC}"
    echo "  PID: ${PID}"
    echo "  进程: ${PROCESS}"
else
    echo -e "${GREEN}✓ 端口 80 可用${NC}"
fi
echo ""

echo -e "${YELLOW}[5] 检查日志文件${NC}"
LOG_FILE="${HOME}/logs/yshop-frontend.log"
if [ -f "${LOG_FILE}" ]; then
    echo -e "${GREEN}✓ 日志文件存在: ${LOG_FILE}${NC}"
    echo "  最后 20 行:"
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    tail -20 "${LOG_FILE}" | sed 's/^/  /'
    echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
else
    echo -e "${YELLOW}⚠ 日志文件不存在: ${LOG_FILE}${NC}"
fi
echo ""

echo -e "${YELLOW}[6] 检查 PID 文件${NC}"
PID_FILE="${HOME}/logs/frontend.pid"
if [ -f "${PID_FILE}" ]; then
    STORED_PID=$(cat "${PID_FILE}")
    echo -e "${GREEN}✓ PID 文件存在: ${PID_FILE}${NC}"
    echo "  记录的 PID: ${STORED_PID}"
    
    if ps -p ${STORED_PID} > /dev/null 2>&1; then
        PROCESS=$(ps -p ${STORED_PID} -o comm= 2>/dev/null)
        echo -e "  ${GREEN}→ 进程正在运行: ${PROCESS}${NC}"
    else
        echo -e "  ${RED}→ 进程已不存在${NC}"
    fi
else
    echo -e "${YELLOW}⚠ PID 文件不存在: ${PID_FILE}${NC}"
fi
echo ""

echo -e "${YELLOW}[7] 测试手动启动${NC}"
echo "尝试手动启动 http-server..."
echo "命令: sudo http-server dist-prod -p 80"
echo ""
read -p "是否测试启动? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "启动中..."
    sudo http-server dist-prod -p 80 &
    MANUAL_PID=$!
    echo "PID: ${MANUAL_PID}"
    sleep 3
    
    if lsof -Pi :80 -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        echo -e "${GREEN}✓ 启动成功！端口 80 正在监听${NC}"
        echo ""
        echo "测试访问："
        curl -s http://localhost:80 | head -5
        echo ""
        read -p "按任意键停止测试服务..." -n 1 -r
        sudo kill ${MANUAL_PID} 2>/dev/null
    else
        echo -e "${RED}✗ 启动失败${NC}"
    fi
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}调试完成${NC}"
echo -e "${BLUE}========================================${NC}"

