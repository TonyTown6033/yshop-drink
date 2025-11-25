#!/bin/bash

################################################################################
# YSHOP 意象点餐系统 - Ubuntu 服务器停止脚本
# 
# 功能：
# 1. 停止后端服务
# 2. 停止前端服务
# 3. 停止 Docker 容器（可选）
#
# 使用方法：
#   chmod +x stop-server.sh
#   ./stop-server.sh
#
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志目录
LOG_DIR="${HOME}/logs"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 打印日志函数
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

# 停止后端服务
stop_backend() {
    log_info "停止后端服务..."
    
    if [ -f "${LOG_DIR}/backend.pid" ]; then
        PID=$(cat "${LOG_DIR}/backend.pid")
        if ps -p $PID > /dev/null 2>&1; then
            kill $PID
            sleep 2
            
            # 如果进程还在运行，强制杀死
            if ps -p $PID > /dev/null 2>&1; then
                kill -9 $PID
            fi
            
            rm -f "${LOG_DIR}/backend.pid"
            log_success "后端服务已停止"
        else
            log_warning "后端服务未运行"
            rm -f "${LOG_DIR}/backend.pid"
        fi
    else
        # 尝试通过名称杀死进程
        pkill -f "yshop-server" && log_success "后端服务已停止" || log_warning "后端服务未运行"
    fi
}

# 停止前端服务
stop_frontend() {
    log_info "停止前端服务..."
    
    if [ -f "${LOG_DIR}/frontend.pid" ]; then
        PID=$(cat "${LOG_DIR}/frontend.pid")
        if ps -p $PID > /dev/null 2>&1; then
            kill $PID
            sleep 2
            
            # 如果进程还在运行，强制杀死
            if ps -p $PID > /dev/null 2>&1; then
                kill -9 $PID
            fi
            
            rm -f "${LOG_DIR}/frontend.pid"
            log_success "前端服务已停止"
        else
            log_warning "前端服务未运行"
            rm -f "${LOG_DIR}/frontend.pid"
        fi
    else
        # 尝试通过名称杀死进程
        pkill -f "vite" && log_success "前端服务已停止" || log_warning "前端服务未运行"
    fi
}

# 停止 Docker 容器
stop_docker() {
    log_info "停止 Docker 容器..."
    
    cd "${PROJECT_DIR}"
    
    if docker ps | grep -q "yshop-"; then
        docker compose down
        log_success "Docker 容器已停止"
    else
        log_warning "Docker 容器未运行"
    fi
}

# 主函数
main() {
    echo ""
    echo -e "${YELLOW}=======================================${NC}"
    echo -e "${YELLOW}  YSHOP 意象点餐系统 - 停止服务${NC}"
    echo -e "${YELLOW}=======================================${NC}"
    echo ""
    
    # 停止服务
    stop_backend
    stop_frontend
    
    # 询问是否停止 Docker
    read -p "是否停止 Docker 容器 (MySQL/Redis)? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        stop_docker
    fi
    
    echo ""
    log_success "服务停止完成！"
    echo ""
}

# 运行主函数
main "$@"

