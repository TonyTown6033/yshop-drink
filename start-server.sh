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

# 清理端口占用
clean_port() {
    local port=$1
    local service_name=$2
    
    if check_port $port; then
        log_warning "端口 ${port} 已被占用"
        
        # 获取占用端口的进程信息
        local pid=$(lsof -ti :$port)
        local process_name=$(ps -p $pid -o comm= 2>/dev/null || echo "未知进程")
        
        log_info "占用进程: PID=${pid}, 名称=${process_name}"
        
        # 检查是否是 Docker 容器
        if docker ps --format "{{.Names}}" | grep -q "yshop-"; then
            log_info "检测到 YSHOP 相关容器，尝试停止..."
            docker stop $(docker ps -q --filter "name=yshop-") 2>/dev/null || true
            sleep 2
        fi
        
        # 再次检查端口
        if check_port $port; then
            log_warning "端口仍被占用，尝试强制停止进程..."
            read -p "是否强制停止占用端口 ${port} 的进程 (PID: ${pid})? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                kill -9 $pid 2>/dev/null || true
                sleep 1
                
                if check_port $port; then
                    log_error "端口 ${port} 清理失败"
                    return 1
                else
                    log_success "端口 ${port} 已清理"
                fi
            else
                log_error "用户取消清理，无法继续"
                return 1
            fi
        else
            log_success "端口 ${port} 已清理"
        fi
    fi
    
    return 0
}

# 配置国内镜像源（以实际用户身份）
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
    
    # 4. 配置 nvm 镜像
    if [ -d "${REAL_HOME}/.nvm" ]; then
        echo -e "${BLUE}[INFO]${NC} 配置 nvm 淘宝镜像..."
        export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
        export NVM_IOJS_ORG_MIRROR=https://npmmirror.com/mirrors/iojs
        
        # 写入配置文件
        if ! grep -q "NVM_NODEJS_ORG_MIRROR" "${REAL_HOME}/.bashrc" 2>/dev/null; then
            echo 'export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node' >> "${REAL_HOME}/.bashrc"
            echo 'export NVM_IOJS_ORG_MIRROR=https://npmmirror.com/mirrors/iojs' >> "${REAL_HOME}/.bashrc"
        fi
        
        echo -e "${GREEN}[SUCCESS]${NC} nvm 镜像配置完成"
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

# 加载 nvm
load_nvm() {
    export NVM_DIR="${REAL_HOME}/.nvm"
    
    # 尝试加载 nvm
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        . "$NVM_DIR/nvm.sh"
        return 0
    elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
        export NVM_DIR="/usr/local/opt/nvm"
        . "$NVM_DIR/nvm.sh"
        return 0
    fi
    
    return 1
}

# 安装 nvm
install_nvm() {
    log_info "安装 nvm（Node Version Manager）..."
    
    # 以实际用户身份安装 nvm
    sudo -u ${REAL_USER} bash -c 'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash'
    
    if [ $? -ne 0 ]; then
        log_error "nvm 安装失败"
        exit 1
    fi
    
    # 设置 nvm 环境变量
    export NVM_DIR="${REAL_HOME}/.nvm"
    
    # 加载 nvm
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
    
    log_success "nvm 安装完成"
}

# 安装 Node.js 和 pnpm（使用 nvm）
install_nodejs() {
    log_info "使用 nvm 安装 Node.js 18 LTS..."
    
    # 确保 nvm 已安装
    if ! load_nvm; then
        log_info "nvm 未安装，开始安装 nvm..."
        install_nvm
        load_nvm
    fi
    
    # 以实际用户身份安装 Node.js
    log_info "安装 Node.js 18..."
    sudo -u ${REAL_USER} bash -c ". ${NVM_DIR}/nvm.sh && nvm install 18"
    
    # 设置默认版本
    log_info "设置默认版本..."
    sudo -u ${REAL_USER} bash -c ". ${NVM_DIR}/nvm.sh && nvm alias default 18"
    sudo -u ${REAL_USER} bash -c ". ${NVM_DIR}/nvm.sh && nvm use 18"
    
    # 重新加载以获取新安装的 Node.js
    load_nvm
    nvm use 18
    
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

# 从 GitHub Release 下载部署包
download_github_release() {
    print_title "下载 GitHub Release"
    
    local version=$1
    local repo=$2
    
    # 如果没有指定仓库，尝试从 git remote 获取
    if [ -z "$repo" ]; then
        if command_exists git && [ -d "${PROJECT_DIR}/.git" ]; then
            local remote_url=$(git -C "${PROJECT_DIR}" remote get-url origin 2>/dev/null)
            if [[ $remote_url =~ github.com[:/](.+/.+)(\.git)?$ ]]; then
                repo="${BASH_REMATCH[1]}"
                repo="${repo%.git}"  # 移除 .git 后缀
                log_info "从 git remote 获取仓库: ${repo}"
            fi
        fi
    fi
    
    # 如果还是没有仓库信息，使用默认仓库
    if [ -z "$repo" ]; then
        repo="TonyTown6033/yshop-drink"
        log_warning "未指定仓库，使用默认仓库: ${repo}"
        log_info "如需使用其他仓库，请使用 --github-repo 参数"
        log_info "例如: --github-repo username/yshop-drink"
    fi
    
    log_info "GitHub 仓库: ${repo}"
    
    # 如果没有指定版本，获取最新版本
    if [ -z "$version" ]; then
        log_info "获取最新版本信息..."
        
        # 尝试使用 GitHub API 获取最新版本
        local api_response=$(curl -s -w "\n%{http_code}" "https://api.github.com/repos/${repo}/releases/latest")
        local http_code=$(echo "$api_response" | tail -n1)
        local response_body=$(echo "$api_response" | sed '$d')
        
        if [ "$http_code" = "200" ]; then
            version=$(echo "$response_body" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
        elif [ "$http_code" = "403" ]; then
            log_warning "GitHub API 请求受限，尝试备用方法..."
            # 尝试从 releases 页面获取
            version=$(curl -sL "https://github.com/${repo}/releases" | grep -oP 'releases/tag/\K[^"]+' | head -n 1)
        fi
        
        if [ -z "$version" ]; then
            log_error "无法获取最新版本信息"
            log_info "请检查："
            echo "  1. 仓库是否存在: https://github.com/${repo}"
            echo "  2. 是否有发布的 Release: https://github.com/${repo}/releases"
            echo "  3. 网络连接是否正常"
            echo ""
            echo "或者手动指定版本："
            echo "  sudo ./start-server.sh --github-release v1.1.2"
            exit 1
        fi
        
        log_info "最新版本: ${version}"
    fi
    
    # 构建下载 URL
    local package_name="yshop-deploy-${version}.tar.gz"
    local download_url="https://github.com/${repo}/releases/download/${version}/${package_name}"
    local checksum_url="${download_url}.sha256"
    
    log_info "版本: ${version}"
    log_info "仓库: https://github.com/${repo}"
    log_info "下载地址: ${download_url}"
    
    # 创建临时目录
    local temp_dir="/tmp/yshop-release-$$"
    mkdir -p "${temp_dir}"
    
    # 下载部署包
    log_info "开始下载部署包（可能需要几分钟）..."
    if curl -L --progress-bar -o "${temp_dir}/${package_name}" "${download_url}"; then
        log_success "下载完成"
        
        # 显示文件大小
        local file_size=$(du -h "${temp_dir}/${package_name}" | cut -f1)
        log_info "文件大小: ${file_size}"
    else
        log_error "下载失败"
        log_info "请检查："
        echo "  1. 网络连接是否正常"
        echo "  2. Release 是否存在: https://github.com/${repo}/releases/tag/${version}"
        echo "  3. 文件是否已上传: ${package_name}"
        echo ""
        echo "你也可以手动下载并部署："
        echo "  wget ${download_url}"
        echo "  tar -xzf ${package_name}"
        echo "  cp backend/yshop-server*.jar yshop-drink-boot3/yshop-server/target/"
        echo "  cp -r frontend/dist-prod yshop-drink-vue3/"
        echo "  sudo ./start-server.sh --skip-build --prod-frontend"
        rm -rf "${temp_dir}"
        exit 1
    fi
    
    # 下载校验和
    log_info "下载校验文件..."
    if curl -L -o "${temp_dir}/${package_name}.sha256" "${checksum_url}" 2>/dev/null; then
        log_info "验证文件完整性..."
        cd "${temp_dir}"
        if sha256sum -c "${package_name}.sha256" 2>/dev/null; then
            log_success "文件校验通过"
        else
            log_warning "文件校验失败，但继续执行"
        fi
        cd "${PROJECT_DIR}"
    else
        log_warning "未找到校验文件，跳过校验"
    fi
    
    # 解压
    log_info "解压部署包..."
    tar -xzf "${temp_dir}/${package_name}" -C "${temp_dir}"
    
    # 复制文件
    log_info "复制文件到项目目录..."
    
    # 复制后端 jar
    if [ -d "${temp_dir}/backend" ]; then
        mkdir -p "${BACKEND_DIR}/yshop-server/target"
        cp ${temp_dir}/backend/yshop-server*.jar "${BACKEND_DIR}/yshop-server/target/" 2>/dev/null || true
        
        local jar_file=$(ls ${BACKEND_DIR}/yshop-server/target/yshop-server*.jar 2>/dev/null | head -n 1)
        if [ -n "$jar_file" ]; then
            log_success "后端文件已复制: $(basename $jar_file)"
        else
            log_error "后端文件复制失败"
            rm -rf "${temp_dir}"
            exit 1
        fi
    fi
    
    # 复制前端 dist-prod（GitHub Actions 构建产物）
    if [ -d "${temp_dir}/frontend/dist-prod" ]; then
        rm -rf "${FRONTEND_DIR}/dist-prod"
        cp -r "${temp_dir}/frontend/dist-prod" "${FRONTEND_DIR}/"
        log_success "前端文件已复制（dist-prod）"
    elif [ -d "${temp_dir}/frontend/dist" ]; then
        # 兼容旧版本（如果有 dist 目录）
        rm -rf "${FRONTEND_DIR}/dist"
        cp -r "${temp_dir}/frontend/dist" "${FRONTEND_DIR}/"
        log_success "前端文件已复制（dist）"
    fi
    
    # 显示版本信息
    if [ -f "${temp_dir}/VERSION" ]; then
        echo ""
        log_info "版本信息："
        cat "${temp_dir}/VERSION" | sed 's/^/  /'
        echo ""
    fi
    
    # 清理临时文件
    rm -rf "${temp_dir}"
    
    log_success "GitHub Release 部署包下载完成"
    
    # 设置跳过编译标志
    SKIP_BUILD="true"
    USE_PROD_BUILD="true"
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
    
    # 尝试加载 nvm
    load_nvm
    
    # 检查 Node.js
    if command_exists node; then
        NODE_VERSION=$(node -v)
        NODE_MAJOR_VERSION=$(echo $NODE_VERSION | sed 's/v//' | cut -d. -f1)
        log_info "Node.js 版本: ${NODE_VERSION}"
        
        # 显示 nvm 信息
        if load_nvm && command -v nvm >/dev/null 2>&1; then
            log_info "Node.js 管理: nvm"
            CURRENT_NODE=$(sudo -u ${REAL_USER} bash -c ". ${NVM_DIR}/nvm.sh && nvm current")
            log_info "当前使用: ${CURRENT_NODE}"
        fi
        
        # 检查版本是否满足要求（需要 v16+）
        if [ "$NODE_MAJOR_VERSION" -lt 16 ]; then
            log_warning "Node.js 版本过低（需要 v16+），当前: ${NODE_VERSION}"
            
            # 检查是否使用 nvm
            if load_nvm && command -v nvm >/dev/null 2>&1; then
                log_info "检测到 nvm，尝试安装 Node.js 18..."
                sudo -u ${REAL_USER} bash -c ". ${NVM_DIR}/nvm.sh && nvm install 18 && nvm use 18 && nvm alias default 18"
                
                # 重新加载
                load_nvm
                nvm use 18
                
                NODE_VERSION=$(node -v)
                log_success "已切换到 Node.js ${NODE_VERSION}"
            else
                log_error "Node.js 版本不满足要求"
                log_info "将使用 nvm 安装 Node.js 18..."
                install_nodejs
            fi
        fi
    else
        log_error "未检测到 Node.js"
        log_info "将使用 nvm 安装 Node.js 18 LTS..."
        install_nodejs
    fi
    
    # 检查 npm
    if ! command_exists npm; then
        log_error "npm 未找到"
        log_info "将使用 nvm 重新安装 Node.js..."
        install_nodejs
    fi
    
    # 检查 pnpm
    if command_exists pnpm; then
        PNPM_VERSION=$(pnpm -v)
        log_info "pnpm 版本: ${PNPM_VERSION}"
    else
        log_warning "未检测到 pnpm，开始安装..."
        log_info "安装 pnpm..."
        
        # 以实际用户身份安装
        sudo -u ${REAL_USER} bash -c "npm install -g pnpm"
        
        # 验证安装
        if command_exists pnpm; then
            log_success "pnpm 安装成功"
            PNPM_VERSION=$(pnpm -v)
            log_info "pnpm 版本: ${PNPM_VERSION}"
        else
            log_error "pnpm 安装失败"
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
    
    # 清理端口占用
    log_info "检查并清理端口占用..."
    clean_port 3306 "MySQL" || exit 1
    clean_port 6379 "Redis" || exit 1
    log_success "端口检查完成"
    
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
    
    # 查找 jar 文件
    JAR_FILE=$(find "${BACKEND_DIR}/yshop-server/target" -name "yshop-server*.jar" 2>/dev/null | head -n 1)
    
    # 如果没有找到 jar 文件，或者设置了强制编译，则进行编译
    if [ -z "$JAR_FILE" ] || [ "$SKIP_BUILD" != "true" ]; then
        if [ -z "$JAR_FILE" ]; then
            log_warning "未找到已编译的 jar 文件"
        fi
        
        if [ "$SKIP_BUILD" = "true" ]; then
            log_error "跳过编译模式下未找到 jar 文件"
            log_info "请先编译项目或不使用 --skip-build 参数"
            exit 1
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
        
        # 重新查找 jar 文件
        JAR_FILE=$(find "${BACKEND_DIR}/yshop-server/target" -name "yshop-server*.jar" | head -n 1)
        
        if [ -z "$JAR_FILE" ]; then
            log_error "编译后仍未找到 jar 文件"
            exit 1
        fi
    else
        log_info "使用已编译的 jar 文件（跳过编译）"
        
        # 显示 jar 文件信息
        JAR_SIZE=$(du -h "$JAR_FILE" | cut -f1)
        JAR_DATE=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$JAR_FILE" 2>/dev/null || stat -c "%y" "$JAR_FILE" 2>/dev/null | cut -d'.' -f1)
        log_info "jar 文件: $(basename $JAR_FILE)"
        log_info "文件大小: ${JAR_SIZE}"
        log_info "编译时间: ${JAR_DATE}"
    fi
    
    log_info "启动后端服务..."
    
    # 启动服务（以实际用户身份后台运行）
    sudo nohup java -jar "${JAR_FILE}" \
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
    
    DIST_DIR="dist-prod"
    
    if [ -n "$DIST_DIR" ]; then
        # 检查是否安装了 http-server
        if ! command_exists http-server; then
            log_info "安装 http-server..."
            sudo npm install -g http-server
        fi
        
        # 启动静态文件服务器
        log_info "启动静态文件服务器..."
        sudo nohup http-server ${DIST_DIR} -p 80 \
            > "${LOG_DIR}/yshop-frontend.log" 2>&1 &
        
        FRONTEND_PID=$!
        echo $FRONTEND_PID > "${LOG_DIR}/frontend.pid"
        chown ${REAL_USER}:${REAL_USER} "${LOG_DIR}/frontend.pid"
        
        log_info "前端进程 PID: ${FRONTEND_PID}"
        log_success "前端服务启动成功（生产模式，使用 ${DIST_DIR}）"
    else
        # 开发模式
        # 检查是否已安装依赖（以实际用户身份）
        if [ ! -d "node_modules" ]; then
            if [ "$SKIP_BUILD" = "true" ]; then
                log_error "跳过编译模式下未找到 node_modules"
                log_info "请先运行: pnpm install"
                exit 1
            fi
            
            log_info "安装前端依赖..."
            sudo pnpm install 2>&1 | tee "${LOG_DIR}/frontend-install.log"
            
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
        
        sudo nohup pnpm run dev \
            > "${LOG_DIR}/yshop-frontend.log" 2>&1 &
        
        FRONTEND_PID=$!
        echo $FRONTEND_PID > "${LOG_DIR}/frontend.pid"
        chown ${REAL_USER}:${REAL_USER} "${LOG_DIR}/frontend.pid"
        
        log_info "前端进程 PID: ${FRONTEND_PID}"
        log_success "前端服务启动成功（开发模式）"
    fi
    
    log_info "日志文件: ${LOG_DIR}/yshop-frontend.log"
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

# 显示帮助信息
show_help() {
    echo "使用方法: sudo ./start-server.sh [选项]"
    echo ""
    echo "选项:"
    echo "  --skip-build               跳过编译，使用已编译的文件"
    echo "  --prod-frontend            使用前端生产构建（dist 目录）"
    echo "  --github-release [版本]    从 GitHub Release 下载部署包"
    echo "  --github-repo <repo>       指定 GitHub 仓库（默认从 git remote 获取）"
    echo "  --help, -h                 显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  sudo ./start-server.sh                           # 正常启动（编译后启动）"
    echo "  sudo ./start-server.sh --skip-build              # 跳过编译直接启动"
    echo "  sudo ./start-server.sh --prod-frontend           # 使用前端生产构建"
    echo "  sudo ./start-server.sh --github-release          # 使用最新 GitHub Release"
    echo "  sudo ./start-server.sh --github-release v2.9.0   # 使用指定版本"
    echo ""
}

# 主函数
main() {
    # 解析命令行参数
    SKIP_BUILD="false"
    USE_PROD_BUILD="false"
    GITHUB_RELEASE="false"
    GITHUB_VERSION=""
    GITHUB_REPO=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-build)
                SKIP_BUILD="true"
                shift
                ;;
            --prod-frontend)
                USE_PROD_BUILD="true"
                shift
                ;;
            --github-release)
                GITHUB_RELEASE="true"
                shift
                # 检查下一个参数是否是版本号（不以 -- 开头）
                if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
                    GITHUB_VERSION="$1"
                    shift
                fi
                ;;
            --github-repo)
                if [[ $# -lt 2 ]]; then
                    log_error "--github-repo 需要指定仓库名称"
                    exit 1
                fi
                GITHUB_REPO="$2"
                shift 2
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    clear
    
    echo -e "${GREEN}"
    echo "========================================"
    echo "  YSHOP 意象点餐系统 - 启动脚本"
    echo "========================================"
    echo -e "${NC}"
    
    # 显示运行模式
    if [ "$SKIP_BUILD" = "true" ]; then
        log_info "运行模式: 跳过编译（使用已编译文件）"
    else
        log_info "运行模式: 完整编译并启动"
    fi
    
    if [ "$USE_PROD_BUILD" = "true" ]; then
        log_info "前端模式: 生产构建"
    else
        log_info "前端模式: 开发服务器"
    fi
    echo ""
    
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
    
    # 设置日志目录
    LOG_DIR="${REAL_HOME}/logs"
    mkdir -p "${LOG_DIR}"
    chown ${REAL_USER}:${REAL_USER} "${LOG_DIR}"
    
    # 如果使用 GitHub Release，下载部署包
    if [ "$GITHUB_RELEASE" = "true" ]; then
        download_github_release "$GITHUB_VERSION" "$GITHUB_REPO"
    fi
    
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

