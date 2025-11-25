#!/bin/bash

################################################################################
# YSHOP 意象点餐系统 - Ubuntu 服务器启动脚本
# 
# 功能：
# 1. 检查并安装必要的环境（JDK17, Maven, Node.js, pnpm, Docker）
# 2. 启动 MySQL 和 Redis 容器
# 3. 编译并启动后端服务
# 4. 启动管理界面前端
#
# 使用方法：
#   chmod +x start-server.sh
#   ./start-server.sh
#
# 作者：AI Assistant
# 日期：2025-11-25
################################################################################

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${PROJECT_DIR}/yshop-drink-boot3"
FRONTEND_DIR="${PROJECT_DIR}/yshop-drink-vue3"

# 日志目录（稍后根据实际用户设置）
LOG_DIR=""

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

# 打印标题
print_title() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}$1${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
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

# 配置国内镜像源
configure_mirrors() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}配置国内镜像源${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    
    # 1. 配置 Maven 阿里云镜像
    echo -e "${BLUE}[INFO]${NC} 配置 Maven 阿里云镜像..."
    MAVEN_SETTINGS="${HOME}/.m2/settings.xml"
    mkdir -p "${HOME}/.m2"
    
    if [ ! -f "${MAVEN_SETTINGS}" ]; then
        cat > "${MAVEN_SETTINGS}" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 
          http://maven.apache.org/xsd/settings-1.0.0.xsd">
    <mirrors>
        <mirror>
            <id>aliyunmaven</id>
            <mirrorOf>*</mirrorOf>
            <name>阿里云公共仓库</name>
            <url>https://maven.aliyun.com/repository/public</url>
        </mirror>
    </mirrors>
</settings>
EOF
        echo -e "${GREEN}[SUCCESS]${NC} Maven 镜像配置完成"
    else
        echo -e "${BLUE}[INFO]${NC} Maven 配置文件已存在"
    fi
    
    # 2. 配置 npm 淘宝镜像
    echo -e "${BLUE}[INFO]${NC} 配置 npm 淘宝镜像..."
    npm config set registry https://registry.npmmirror.com 2>/dev/null || true
    echo -e "${GREEN}[SUCCESS]${NC} npm 镜像配置完成"
    
    # 3. 配置 pnpm 淘宝镜像
    if command -v pnpm >/dev/null 2>&1; then
        echo -e "${BLUE}[INFO]${NC} 配置 pnpm 淘宝镜像..."
        pnpm config set registry https://registry.npmmirror.com 2>/dev/null || true
        echo -e "${GREEN}[SUCCESS]${NC} pnpm 镜像配置完成"
    fi
}

# 安装 JDK 17
install_jdk17() {
    log_info "安装 OpenJDK 17..."
    sudo apt-get update
    sudo apt-get install -y openjdk-17-jdk
    log_success "JDK 17 安装完成"
}

# 安装 Maven
install_maven() {
    log_info "安装 Maven 3.9..."
    sudo apt-get update
    sudo apt-get install -y maven
    log_success "Maven 安装完成"
}

# 安装 Node.js 和 pnpm
install_nodejs() {
    log_info "安装 Node.js 18 LTS..."
    
    # 使用 NodeSource 仓库安装 Node.js 18.x
    log_info "添加 NodeSource 仓库..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    
    log_info "安装 Node.js..."
    apt-get install -y nodejs
    
    # 验证安装
    if command_exists node && command_exists npm; then
        log_success "Node.js 安装完成"
        log_info "Node.js 版本: $(node -v)"
        log_info "npm 版本: $(npm -v)"
    else
        log_error "Node.js 安装失败"
        exit 1
    fi
    
    # 安装 pnpm
    log_info "安装 pnpm..."
    npm install -g pnpm
    
    if command_exists pnpm; then
        log_success "pnpm 安装完成"
        log_info "pnpm 版本: $(pnpm -v)"
    else
        log_error "pnpm 安装失败"
        exit 1
    fi
}

# 配置 Docker（不重装）
configure_docker() {
    log_info "配置 Docker..."
    
    # 检查 Docker 是否已安装
    if ! command_exists docker; then
        log_error "未检测到 Docker，请先安装 Docker"
        log_info "安装命令："
        echo "  curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun"
        exit 1
    fi
    
    # 配置 Docker 镜像加速
    DOCKER_DAEMON_JSON="/etc/docker/daemon.json"
    
    if [ -f "${DOCKER_DAEMON_JSON}" ]; then
        log_info "Docker 配置文件已存在，跳过配置"
    else
        log_info "配置 Docker 阿里云镜像加速..."
        mkdir -p /etc/docker
        tee ${DOCKER_DAEMON_JSON} > /dev/null <<EOF
{
    "registry-mirrors": [
        "https://mirror.ccs.tencentyun.com",
        "https://docker.mirrors.ustc.edu.cn",
        "https://hub-mirror.c.163.com"
    ]
}
EOF
        systemctl daemon-reload 2>/dev/null || true
        systemctl restart docker 2>/dev/null || true
        log_success "Docker 镜像配置完成"
    fi
    
    # 确保 Docker 服务运行
    if ! systemctl is-active --quiet docker; then
        log_info "启动 Docker 服务..."
        systemctl start docker
        systemctl enable docker
    fi
    
    log_success "Docker 配置完成"
}

# 检查环境
check_environment() {
    print_title "检查运行环境"
    
    local need_install=false
    
    # 检查 Java
    if command_exists java; then
        JAVA_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
        log_info "Java 版本: ${JAVA_VERSION}"
        
        if [[ ! $JAVA_VERSION =~ ^17\. ]]; then
            log_warning "需要 JDK 17，当前版本: ${JAVA_VERSION}"
            read -p "是否安装 JDK 17? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                install_jdk17
            fi
        fi
    else
        log_error "未检测到 Java，开始安装..."
        install_jdk17
    fi
    
    # 检查 Maven
    if command_exists mvn; then
        MVN_VERSION=$(mvn -version | head -n 1 | awk '{print $3}')
        log_info "Maven 版本: ${MVN_VERSION}"
    else
        log_error "未检测到 Maven，开始安装..."
        install_maven
    fi
    
    # 检查 Node.js
    if command_exists node; then
        NODE_VERSION=$(node -v)
        NODE_MAJOR_VERSION=$(echo $NODE_VERSION | sed 's/v//' | cut -d. -f1)
        log_info "Node.js 版本: ${NODE_VERSION}"
        
        # 检查版本是否满足要求（需要 v16+）
        if [ "$NODE_MAJOR_VERSION" -lt 16 ]; then
            log_warning "Node.js 版本过低（需要 v16+），当前: ${NODE_VERSION}"
            log_info "请升级 Node.js"
            log_info "升级方法 1（推荐）："
            echo "  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
            echo "  sudo apt-get install -y nodejs"
            log_info "升级方法 2（使用 nvm）："
            echo "  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash"
            echo "  nvm install 18"
            echo "  nvm use 18"
            exit 1
        fi
    else
        log_error "未检测到 Node.js"
        log_info "请先安装 Node.js 18 LTS"
        log_info "安装命令："
        echo "  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
        echo "  sudo apt-get install -y nodejs"
        exit 1
    fi
    
    # 检查 npm
    if ! command_exists npm; then
        log_error "npm 未找到，请重新安装 Node.js"
        log_info "安装命令："
        echo "  curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -"
        echo "  sudo apt-get install -y nodejs"
        exit 1
    fi
    
    # 检查 pnpm
    if command_exists pnpm; then
        PNPM_VERSION=$(pnpm -v)
        log_info "pnpm 版本: ${PNPM_VERSION}"
    else
        log_warning "未检测到 pnpm，开始安装..."
        log_info "安装 pnpm..."
        npm install -g pnpm
        
        # 验证安装
        if command_exists pnpm; then
            log_success "pnpm 安装成功"
        else
            log_error "pnpm 安装失败"
            log_info "手动安装命令："
            echo "  npm install -g pnpm"
            exit 1
        fi
    fi
    
    # 检查 Docker
    if command_exists docker; then
        DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
        log_info "Docker 版本: ${DOCKER_VERSION}"
    else
        log_error "未检测到 Docker，请先安装 Docker"
        log_info "快速安装命令："
        echo "  curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun"
        exit 1
    fi
    
    # 检查 Docker Compose
    if docker compose version &>/dev/null; then
        COMPOSE_VERSION=$(docker compose version | awk '{print $4}')
        log_info "Docker Compose 版本: ${COMPOSE_VERSION}"
    else
        log_error "未检测到 Docker Compose Plugin"
        exit 1
    fi
    
    log_success "环境检查完成"
}

# 启动 Docker 容器（MySQL 和 Redis）
start_docker_containers() {
    print_title "启动 Docker 容器"
    
    cd "${PROJECT_DIR}"
    
    # 检查 SQL 文件是否存在
    SQL_FILE="${PROJECT_DIR}/yshop-drink-boot3/sql/yixiang-drink-open.sql"
    if [ ! -f "${SQL_FILE}" ]; then
        log_error "未找到 SQL 文件: ${SQL_FILE}"
        exit 1
    fi
    
    # 检查容器是否已运行
    MYSQL_FIRST_RUN=false
    if docker ps | grep -q "yshop-mysql"; then
        log_info "MySQL 容器已在运行"
    else
        log_info "启动 MySQL 容器..."
        
        # 检查是否是首次运行（数据目录是否存在）
        if [ ! -d "${PROJECT_DIR}/mysql-data/yixiang-drink" ]; then
            MYSQL_FIRST_RUN=true
            log_info "检测到首次运行，将自动导入数据库..."
        fi
        
        docker compose up -d mysql
        log_info "等待 MySQL 启动..."
        sleep 15
        log_success "MySQL 容器启动成功"
    fi
    
    if docker ps | grep -q "yshop-redis"; then
        log_info "Redis 容器已在运行"
    else
        log_info "启动 Redis 容器..."
        docker compose up -d redis
        sleep 3
        log_success "Redis 容器启动成功"
    fi
    
    # 如果是首次运行，导入数据库
    if [ "$MYSQL_FIRST_RUN" = true ]; then
        import_database
    else
        # 检查数据库是否有数据
        log_info "检查数据库是否已有数据..."
        TABLE_COUNT=$(docker exec yshop-mysql mysql -uroot -proot123456 yixiang-drink -e "SHOW TABLES;" 2>/dev/null | wc -l)
        
        if [ $TABLE_COUNT -le 1 ]; then
            log_warning "数据库为空，开始导入数据..."
            import_database
        else
            log_info "数据库已有数据（${TABLE_COUNT} 张表）"
        fi
    fi
    
    # 显示容器状态
    echo ""
    log_info "Docker 容器状态："
    docker ps --filter "name=yshop-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
}

# 导入数据库
import_database() {
    print_title "导入数据库"
    
    SQL_FILE="${PROJECT_DIR}/yshop-drink-boot3/sql/yixiang-drink-open.sql"
    
    if [ ! -f "${SQL_FILE}" ]; then
        log_error "SQL 文件不存在: ${SQL_FILE}"
        exit 1
    fi
    
    log_info "SQL 文件: $(basename ${SQL_FILE})"
    log_info "文件大小: $(du -h ${SQL_FILE} | cut -f1)"
    
    log_info "开始导入数据库，这可能需要几分钟..."
    
    # 等待 MySQL 完全启动
    log_info "等待 MySQL 完全就绪..."
    MAX_RETRY=30
    RETRY=0
    while [ $RETRY -lt $MAX_RETRY ]; do
        if docker exec yshop-mysql mysqladmin ping -uroot -proot123456 --silent 2>/dev/null; then
            log_success "MySQL 已就绪"
            break
        fi
        RETRY=$((RETRY + 1))
        echo -n "."
        sleep 2
    done
    echo ""
    
    if [ $RETRY -eq $MAX_RETRY ]; then
        log_error "MySQL 启动超时"
        exit 1
    fi
    
    # 导入 SQL 文件
    log_info "正在导入 SQL 数据..."
    if docker exec -i yshop-mysql mysql -uroot -proot123456 yixiang-drink < "${SQL_FILE}" 2>&1 | tee "${LOG_DIR}/sql-import.log"; then
        log_success "数据库导入成功"
        
        # 验证导入
        TABLE_COUNT=$(docker exec yshop-mysql mysql -uroot -proot123456 yixiang-drink -e "SHOW TABLES;" 2>/dev/null | wc -l)
        log_info "数据库表数量: $((TABLE_COUNT - 1))"
    else
        log_error "数据库导入失败，请查看日志: ${LOG_DIR}/sql-import.log"
        exit 1
    fi
}

# 等待服务就绪
wait_for_service() {
    local service_name=$1
    local port=$2
    local max_attempts=30
    local attempt=0
    
    log_info "等待 ${service_name} 就绪..."
    
    while [ $attempt -lt $max_attempts ]; do
        if check_port $port; then
            log_success "${service_name} 已就绪"
            return 0
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    log_error "${service_name} 启动超时"
    return 1
}

# 编译并启动后端
start_backend() {
    print_title "启动后端服务"
    
    cd "${BACKEND_DIR}"
    
    # 检查后端是否已运行
    if check_port 48081; then
        log_warning "后端服务已在运行 (端口 48081)"
        read -p "是否重启后端服务? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
        
        # 停止现有服务
        log_info "停止现有后端服务..."
        pkill -f "yshop-server" || true
        sleep 3
    fi
    
    # 编译项目（以实际用户身份）
    log_info "开始编译后端项目..."
    log_info "这可能需要几分钟，请耐心等待..."
    
    sudo -u ${REAL_USER} mvn clean install package -Dmaven.test.skip=true -T 1C 2>&1 | tee "${LOG_DIR}/backend-build.log"
    
    if [ $? -eq 0 ]; then
        log_success "后端编译成功"
    else
        log_error "后端编译失败，请查看日志: ${LOG_DIR}/backend-build.log"
        exit 1
    fi
    
    # 查找并启动 jar 文件
    JAR_FILE=$(find "${BACKEND_DIR}/yshop-server/target" -name "yshop-server-*.jar" | head -n 1)
    
    if [ -z "$JAR_FILE" ]; then
        log_error "未找到编译后的 jar 文件"
        exit 1
    fi
    
    log_info "找到 jar 文件: $(basename $JAR_FILE)"
    log_info "启动后端服务..."
    
    # 启动服务（以实际用户身份后台运行）
    sudo -u ${REAL_USER} nohup java -jar "${JAR_FILE}" \
        --spring.profiles.active=local \
        > "${LOG_DIR}/yshop-server.log" 2>&1 &
    
    BACKEND_PID=$!
    echo $BACKEND_PID > "${LOG_DIR}/backend.pid"
    chown ${REAL_USER}:${REAL_USER} "${LOG_DIR}/backend.pid"
    
    log_info "后端进程 PID: ${BACKEND_PID}"
    log_info "日志文件: ${LOG_DIR}/yshop-server.log"
    
    # 等待服务启动
    wait_for_service "后端服务" 48081
    
    log_success "后端服务启动成功"
    log_info "后端地址: http://localhost:48081"
}

# 启动前端
start_frontend() {
    print_title "启动管理界面前端"
    
    cd "${FRONTEND_DIR}"
    
    # 检查前端是否已运行
    if check_port 80; then
        log_warning "前端服务已在运行 (端口 80)"
        read -p "是否重启前端服务? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
        
        # 停止现有服务
        log_info "停止现有前端服务..."
        pkill -f "vite" || true
        sleep 2
    fi
    
    # 检查是否已安装依赖（以实际用户身份）
    if [ ! -d "node_modules" ]; then
        log_info "安装前端依赖..."
        sudo -u ${REAL_USER} pnpm install 2>&1 | tee "${LOG_DIR}/frontend-install.log"
        
        if [ $? -eq 0 ]; then
            log_success "前端依赖安装成功"
        else
            log_error "前端依赖安装失败，请查看日志: ${LOG_DIR}/frontend-install.log"
            exit 1
        fi
    else
        log_info "前端依赖已安装"
    fi
    
    # 启动开发服务器（以实际用户身份）
    log_info "启动前端开发服务器..."
    
    sudo -u ${REAL_USER} nohup pnpm run dev \
        > "${LOG_DIR}/yshop-frontend.log" 2>&1 &
    
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "${LOG_DIR}/frontend.pid"
    chown ${REAL_USER}:${REAL_USER} "${LOG_DIR}/frontend.pid"
    
    log_info "前端进程 PID: ${FRONTEND_PID}"
    log_info "日志文件: ${LOG_DIR}/yshop-frontend.log"
    
    # 等待服务启动
    sleep 5
    
    log_success "前端服务启动成功"
    log_info "前端地址: http://localhost:80"
}

# 显示服务状态
show_status() {
    print_title "服务状态"
    
    echo -e "${GREEN}Docker 容器:${NC}"
    docker ps --filter "name=yshop-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    
    echo -e "${GREEN}后端服务:${NC}"
    if check_port 48081; then
        echo -e "  状态: ${GREEN}运行中${NC}"
        echo -e "  地址: http://localhost:48081"
        if [ -f "${LOG_DIR}/backend.pid" ]; then
            echo -e "  PID: $(cat ${LOG_DIR}/backend.pid)"
        fi
    else
        echo -e "  状态: ${RED}未运行${NC}"
    fi
    echo ""
    
    echo -e "${GREEN}前端服务:${NC}"
    if check_port 80; then
        echo -e "  状态: ${GREEN}运行中${NC}"
        echo -e "  地址: http://localhost:80"
        if [ -f "${LOG_DIR}/frontend.pid" ]; then
            echo -e "  PID: $(cat ${LOG_DIR}/frontend.pid)"
        fi
    else
        echo -e "  状态: ${RED}未运行${NC}"
    fi
    echo ""
    
    echo -e "${GREEN}日志文件:${NC}"
    echo -e "  后端日志: ${LOG_DIR}/yshop-server.log"
    echo -e "  前端日志: ${LOG_DIR}/yshop-frontend.log"
    echo -e "  编译日志: ${LOG_DIR}/backend-build.log"
    echo ""
    
    echo -e "${YELLOW}常用命令:${NC}"
    echo -e "  查看后端日志: tail -f ${LOG_DIR}/yshop-server.log"
    echo -e "  查看前端日志: tail -f ${LOG_DIR}/yshop-frontend.log"
    echo -e "  停止服务: ./stop-server.sh"
    echo ""
}

# 主函数
main() {
    clear
    
    echo -e "${GREEN}"
    echo "========================================"
    echo "  YSHOP 意象点餐系统 - 启动脚本"
    echo "========================================"
    echo -e "${NC}"
    
    # 检查是否使用 sudo 运行
    if [ "$EUID" -ne 0 ]; then
        log_error "请使用 sudo 运行此脚本"
        log_info "正确用法: sudo ./start-server.sh"
        exit 1
    fi
    
    # 获取实际用户（不是root）
    REAL_USER=${SUDO_USER:-$USER}
    REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    
    if [ "$REAL_USER" = "root" ]; then
        log_error "请不要直接使用 root 用户运行，请使用普通用户通过 sudo 运行"
        exit 1
    fi
    
    log_info "实际用户: ${REAL_USER}"
    
    # 检查环境
    check_environment
    
    # 配置镜像源
    configure_mirrors
    
    # 启动服务
    start_docker_containers
    start_backend
    start_frontend
    
    # 显示状态
    show_status
    
    log_success "所有服务启动完成！"
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}🎉 启动成功！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "管理后台: ${BLUE}http://localhost:80${NC}"
    echo -e "默认账号: ${BLUE}admin${NC}"
    echo -e "默认密码: ${BLUE}admin123${NC}"
    echo ""
    echo -e "后端API: ${BLUE}http://localhost:48081${NC}"
    echo ""
    echo -e "数据库信息:"
    echo -e "  主机: ${BLUE}localhost:3306${NC}"
    echo -e "  用户: ${BLUE}root${NC}"
    echo -e "  密码: ${BLUE}root123456${NC}"
    echo -e "  数据库: ${BLUE}yixiang-drink${NC}"
    echo ""
    echo -e "Redis信息:"
    echo -e "  主机: ${BLUE}localhost:6379${NC}"
    echo -e "  密码: ${BLUE}redis123456${NC}"
    echo ""
    echo -e "${YELLOW}提示: 首次启动可能需要几分钟初始化数据库${NC}"
    echo ""
}

# 运行主函数
main "$@"

