#!/bin/bash

################################################################################
# YSHOP 端口清理脚本
# 智能清理被占用的端口：
# - 对于 Docker 容器：使用 docker stop/rm/rmi
# - 对于普通进程：使用 kill 优雅停止
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

# 检查进程是否是 Docker 容器
is_docker_process() {
    local pid=$1
    
    # 检查进程的 cgroup 是否包含 docker
    if [ -f "/proc/$pid/cgroup" ]; then
        if grep -q "docker" "/proc/$pid/cgroup" 2>/dev/null; then
            return 0
        fi
    fi
    
    # 检查进程名称
    local process_name=$(ps -p $pid -o comm= 2>/dev/null)
    if [[ "$process_name" =~ ^(dockerd|containerd|docker-proxy)$ ]]; then
        return 0
    fi
    
    return 1
}

# 通过 PID 获取 Docker 容器 ID
get_container_by_pid() {
    local pid=$1
    
    # 方法1：通过 docker inspect 查找
    for container_id in $(docker ps -q 2>/dev/null); do
        local container_pid=$(docker inspect --format '{{.State.Pid}}' $container_id 2>/dev/null)
        if [ "$container_pid" = "$pid" ]; then
            echo $container_id
            return 0
        fi
    done
    
    # 方法2：通过 cgroup 获取
    if [ -f "/proc/$pid/cgroup" ]; then
        local container_id=$(grep "docker" "/proc/$pid/cgroup" 2>/dev/null | head -n1 | sed 's/.*docker[/-]\([a-z0-9]*\).*/\1/' | head -c 12)
        if [ -n "$container_id" ] && docker ps -q --no-trunc | grep -q "$container_id"; then
            echo $container_id
            return 0
        fi
    fi
    
    return 1
}

# 通过端口查找 Docker 容器
find_container_by_port() {
    local port=$1
    
    # 查找所有运行中的容器
    for container_id in $(docker ps -q 2>/dev/null); do
        # 获取容器的端口映射
        local ports=$(docker port $container_id 2>/dev/null | grep "0.0.0.0:$port\|127.0.0.1:$port")
        if [ -n "$ports" ]; then
            echo $container_id
            return 0
        fi
    done
    
    return 1
}

# 获取端口占用信息（增强版）
get_port_info() {
    local port=$1
    
    if ! check_port $port; then
        return 1
    fi
    
    local pid=$(lsof -ti :$port 2>/dev/null | head -n1)
    local process_name=$(ps -p $pid -o comm= 2>/dev/null || echo "未知进程")
    local user=$(ps -p $pid -o user= 2>/dev/null || echo "未知用户")
    
    echo "端口: ${port}"
    echo "  PID: ${pid}"
    echo "  进程: ${process_name}"
    echo "  用户: ${user}"
    
    # 尝试查找关联的 Docker 容器
    local container_id=$(find_container_by_port $port)
    if [ -n "$container_id" ]; then
        local container_name=$(docker inspect --format '{{.Name}}' $container_id 2>/dev/null | sed 's/^\///')
        local container_image=$(docker inspect --format '{{.Config.Image}}' $container_id 2>/dev/null)
        echo "  ${YELLOW}[Docker 容器]${NC}"
        echo "    容器 ID: ${container_id}"
        echo "    容器名称: ${container_name}"
        echo "    镜像: ${container_image}"
    fi
    
    return 0
}

# 停止 Docker 容器（优雅方式）
stop_docker_container() {
    local container_id=$1
    local remove_container=$2
    local remove_image=$3
    
    local container_name=$(docker inspect --format '{{.Name}}' $container_id 2>/dev/null | sed 's/^\///')
    local container_image=$(docker inspect --format '{{.Config.Image}}' $container_id 2>/dev/null)
    
    log_info "停止 Docker 容器: ${container_name}"
    
    # 优雅停止（给 10 秒时间）
    if docker stop -t 10 $container_id 2>/dev/null; then
        log_success "容器已停止: ${container_name}"
    else
        log_error "容器停止失败: ${container_name}"
        return 1
    fi
    
    # 是否删除容器
    if [ "$remove_container" = "yes" ]; then
        log_info "删除容器: ${container_name}"
        if docker rm $container_id 2>/dev/null; then
            log_success "容器已删除: ${container_name}"
        else
            log_warning "容器删除失败: ${container_name}"
        fi
    fi
    
    # 是否删除镜像
    if [ "$remove_image" = "yes" ] && [ -n "$container_image" ]; then
        log_info "删除镜像: ${container_image}"
        if docker rmi $container_image 2>/dev/null; then
            log_success "镜像已删除: ${container_image}"
        else
            log_warning "镜像删除失败（可能被其他容器使用）: ${container_image}"
        fi
    fi
    
    return 0
}

# 停止普通进程（优雅方式）
stop_normal_process() {
    local pid=$1
    local process_name=$(ps -p $pid -o comm= 2>/dev/null || echo "未知进程")
    
    log_info "停止进程: ${process_name} (PID: ${pid})"
    
    # 优雅停止 (SIGTERM)
    kill $pid 2>/dev/null
    
    # 等待进程退出（最多 10 秒）
    local count=0
    while [ $count -lt 10 ]; do
        if ! ps -p $pid > /dev/null 2>&1; then
            log_success "进程已停止: ${process_name}"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    
    # 如果还在运行，强制停止 (SIGKILL)
    if ps -p $pid > /dev/null 2>&1; then
        log_warning "优雅停止失败，强制停止: ${process_name}"
        kill -9 $pid 2>/dev/null
        sleep 1
        
        if ps -p $pid > /dev/null 2>&1; then
            log_error "进程停止失败: ${process_name}"
            return 1
        else
            log_success "进程已强制停止: ${process_name}"
            return 0
        fi
    fi
    
    return 0
}

# 清理端口（智能选择方法）
clean_port() {
    local port=$1
    local remove_container=$2
    local remove_image=$3
    
    if ! check_port $port; then
        return 0
    fi
    
    # 查找容器
    local container_id=$(find_container_by_port $port)
    
    if [ -n "$container_id" ]; then
        # Docker 容器占用端口
        log_info "检测到 Docker 容器占用端口 ${port}"
        stop_docker_container $container_id "$remove_container" "$remove_image"
    else
        # 普通进程占用端口
        local pid=$(lsof -ti :$port 2>/dev/null | head -n1)
        if [ -n "$pid" ]; then
            log_info "检测到普通进程占用端口 ${port}"
            stop_normal_process $pid
        fi
    fi
    
    # 验证端口是否已释放
    sleep 1
    if check_port $port; then
        log_error "端口 ${port} 清理失败"
        return 1
    else
        log_success "端口 ${port} 已释放"
        return 0
    fi
}

# 主函数
main() {
    clear
    
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}  YSHOP 智能端口清理工具${NC}"
    echo -e "${GREEN}================================================${NC}"
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
        [8801]="前端服务"
    )
    
    # 检查所有端口
    log_info "检查端口占用情况..."
    echo ""
    
    local occupied_ports=()
    local has_docker_container=false
    
    for port in "${!PORTS[@]}"; do
        if check_port $port; then
            echo -e "${YELLOW}✗${NC} 端口 ${port} (${PORTS[$port]}) ${RED}已被占用${NC}"
            get_port_info $port
            occupied_ports+=($port)
            
            # 检查是否有 Docker 容器
            local container_id=$(find_container_by_port $port)
            if [ -n "$container_id" ]; then
                has_docker_container=true
            fi
            
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
    
    # 询问清理选项
    echo -e "${YELLOW}发现 ${#occupied_ports[@]} 个端口被占用${NC}"
    echo ""
    
    local remove_container="no"
    local remove_image="no"
    
    if [ "$has_docker_container" = true ]; then
        echo -e "${BLUE}检测到 Docker 容器占用端口${NC}"
        echo ""
        echo "清理选项："
        echo "  1. 仅停止容器（推荐）"
        echo "  2. 停止并删除容器"
        echo "  3. 停止、删除容器并删除镜像"
        echo "  4. 取消"
        echo ""
        read -p "请选择 (1-4): " -n 1 -r
        echo
        echo ""
        
        case $REPLY in
            1)
                remove_container="no"
                remove_image="no"
                log_info "将停止 Docker 容器（不删除）"
                ;;
            2)
                remove_container="yes"
                remove_image="no"
                log_info "将停止并删除 Docker 容器（保留镜像）"
                ;;
            3)
                remove_container="yes"
                remove_image="yes"
                log_warning "将停止、删除容器并删除镜像"
                read -p "确认删除镜像? (y/n) " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    remove_image="no"
                    log_info "取消删除镜像"
                fi
                ;;
            4|*)
                log_info "取消清理"
                exit 0
                ;;
        esac
        echo ""
    else
        read -p "是否清理端口? (y/n) " -n 1 -r
        echo
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "取消清理"
            exit 0
        fi
    fi
    
    # 清理端口
    log_info "开始清理端口..."
    echo ""
    
    local success_count=0
    local fail_count=0
    
    for port in "${occupied_ports[@]}"; do
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}清理端口 ${port} (${PORTS[$port]})${NC}"
        echo ""
        
        if clean_port $port "$remove_container" "$remove_image"; then
            success_count=$((success_count + 1))
        else
            fail_count=$((fail_count + 1))
        fi
        echo ""
    done
    
    # 显示结果
    echo ""
    echo -e "${GREEN}================================================${NC}"
    echo -e "${GREEN}清理完成${NC}"
    echo -e "${GREEN}================================================${NC}"
    echo ""
    echo -e "成功清理: ${GREEN}${success_count}${NC} 个端口"
    echo -e "清理失败: ${RED}${fail_count}${NC} 个端口"
    echo ""
    
    # 显示清理详情
    if [ "$has_docker_container" = true ]; then
        echo -e "${BLUE}Docker 清理详情:${NC}"
        if [ "$remove_container" = "yes" ]; then
            echo -e "  ✓ 容器已删除"
        else
            echo -e "  ✓ 容器已停止（未删除）"
        fi
        
        if [ "$remove_image" = "yes" ]; then
            echo -e "  ✓ 镜像已删除"
        else
            echo -e "  ✓ 镜像已保留"
        fi
        echo ""
    fi
    
    if [ $fail_count -eq 0 ]; then
        log_success "所有端口已清理，现在可以启动服务"
        echo ""
        log_info "运行启动脚本："
        echo "  ${BLUE}sudo ./start-server.sh --github-release${NC}"
        echo ""
    else
        log_warning "部分端口清理失败，请手动检查"
        echo ""
        log_info "查看端口占用："
        echo "  ${BLUE}sudo lsof -i :端口号${NC}"
        echo ""
    fi
}

# 运行主函数
main "$@"

