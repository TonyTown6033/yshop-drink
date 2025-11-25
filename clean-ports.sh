#!/bin/bash

################################################################################
# YSHOP 端口清理脚本
# 清理被占用的端口，为启动服务做准备
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
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        return 0
    else
        return 1
    fi
}

# 获取端口占用信息
get_port_info() {
    local port=$1
    
    if check_port $port; then
        local pid=$(lsof -ti :$port 2>/dev/null)
        local process_name=$(ps -p $pid -o comm= 2>/dev/null || echo "未知进程")
        local user=$(ps -p $pid -o user= 2>/dev/null || echo "未知用户")
        
        echo "端口: ${port}"
        echo "  PID: ${pid}"
        echo "  进程: ${process_name}"
        echo "  用户: ${user}"
        
        return 0
    else
        return 1
    fi
}

# 停止端口占用
kill_port() {
    local port=$1
    local force=$2
    
    if ! check_port $port; then
        return 0
    fi
    
    local pid=$(lsof -ti :$port 2>/dev/null)
    
    if [ -z "$pid" ]; then
        return 0
    fi
    
    log_info "停止进程 PID: ${pid}"
    
    if [ "$force" = "force" ]; then
        # 强制停止
        kill -9 $pid 2>/dev/null
    else
        # 优雅停止
        kill $pid 2>/dev/null
        
        # 等待进程退出
        local count=0
        while [ $count -lt 5 ]; do
            if ! ps -p $pid > /dev/null 2>&1; then
                break
            fi
            sleep 1
            count=$((count + 1))
        done
        
        # 如果还在运行，强制停止
        if ps -p $pid > /dev/null 2>&1; then
            log_warning "优雅停止失败，强制停止..."
            kill -9 $pid 2>/dev/null
        fi
    fi
    
    sleep 1
    
    if check_port $port; then
        log_error "端口 ${port} 清理失败"
        return 1
    else
        log_success "端口 ${port} 已清理"
        return 0
    fi
}

# 停止 YSHOP Docker 容器
stop_yshop_containers() {
    log_info "检查 YSHOP Docker 容器..."
    
    local containers=$(docker ps -q --filter "name=yshop-" 2>/dev/null)
    
    if [ -n "$containers" ]; then
        log_warning "发现运行中的 YSHOP 容器"
        docker ps --filter "name=yshop-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        echo ""
        read -p "是否停止这些容器? (y/n) " -n 1 -r
        echo
        
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "停止容器..."
            docker stop $(docker ps -q --filter "name=yshop-") 2>/dev/null
            log_success "容器已停止"
            sleep 2
        fi
    else
        log_info "未发现运行中的 YSHOP 容器"
    fi
}

# 主函数
main() {
    clear
    
    echo ""
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}  YSHOP 端口清理工具${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo ""
    
    # 检查权限
    if [ "$EUID" -ne 0 ]; then
        log_warning "建议使用 sudo 运行此脚本以获得完整权限"
        echo ""
    fi
    
    # 定义需要检查的端口
    declare -A PORTS=(
        [3306]="MySQL"
        [6379]="Redis"
        [48081]="后端服务"
        [80]="前端服务"
    )
    
    # 检查所有端口
    log_info "检查端口占用情况..."
    echo ""
    
    local occupied_ports=()
    
    for port in "${!PORTS[@]}"; do
        if check_port $port; then
            echo -e "${YELLOW}✗${NC} 端口 ${port} (${PORTS[$port]}) ${RED}已被占用${NC}"
            get_port_info $port
            occupied_ports+=($port)
            echo ""
        else
            echo -e "${GREEN}✓${NC} 端口 ${port} (${PORTS[$port]}) ${GREEN}可用${NC}"
        fi
    done
    
    echo ""
    
    # 如果没有端口被占用
    if [ ${#occupied_ports[@]} -eq 0 ]; then
        log_success "所有端口都可用，无需清理"
        exit 0
    fi
    
    # 询问是否清理
    echo -e "${YELLOW}发现 ${#occupied_ports[@]} 个端口被占用${NC}"
    echo ""
    
    # 先尝试停止 Docker 容器
    stop_yshop_containers
    
    # 再次检查端口
    echo ""
    log_info "重新检查端口..."
    
    local remaining_ports=()
    for port in "${occupied_ports[@]}"; do
        if check_port $port; then
            remaining_ports+=($port)
        fi
    done
    
    if [ ${#remaining_ports[@]} -eq 0 ]; then
        log_success "所有端口已清理完成"
        exit 0
    fi
    
    # 还有端口被占用
    echo ""
    log_warning "仍有 ${#remaining_ports[@]} 个端口被占用"
    echo ""
    
    read -p "是否清理剩余端口? (y/n) " -n 1 -r
    echo
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "取消清理"
        exit 0
    fi
    
    # 清理端口
    local success_count=0
    local fail_count=0
    
    for port in "${remaining_ports[@]}"; do
        echo -e "${BLUE}清理端口 ${port} (${PORTS[$port]})...${NC}"
        
        if kill_port $port; then
            success_count=$((success_count + 1))
        else
            fail_count=$((fail_count + 1))
        fi
        echo ""
    done
    
    # 显示结果
    echo ""
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}清理完成${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo ""
    echo -e "成功: ${GREEN}${success_count}${NC} 个端口"
    echo -e "失败: ${RED}${fail_count}${NC} 个端口"
    echo ""
    
    if [ $fail_count -eq 0 ]; then
        log_success "所有端口已清理，现在可以启动服务"
        echo ""
        log_info "运行启动脚本："
        echo "  sudo ./start-server.sh"
    else
        log_warning "部分端口清理失败，请手动检查"
    fi
    
    echo ""
}

# 运行主函数
main "$@"

