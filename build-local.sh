#!/bin/bash

################################################################################
# YSHOP 本地编译脚本
# 在本地编译项目，生成可部署的文件
################################################################################

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="${PROJECT_DIR}/yshop-drink-boot3"
FRONTEND_DIR="${PROJECT_DIR}/yshop-drink-vue3"
DEPLOY_DIR="${PROJECT_DIR}/deploy"

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

# 编译后端
build_backend() {
    print_title "编译后端项目"
    
    cd "${BACKEND_DIR}"
    
    log_info "开始编译..."
    log_info "这可能需要几分钟，请耐心等待..."
    
    mvn clean install package -Dmaven.test.skip=true -T 1C
    
    if [ $? -eq 0 ]; then
        log_success "后端编译成功"
    else
        log_error "后端编译失败"
        exit 1
    fi
    
    # 查找 jar 文件
    JAR_FILE=$(find "${BACKEND_DIR}/yshop-server/target" -name "yshop-server-*.jar" | head -n 1)
    
    if [ -z "$JAR_FILE" ]; then
        log_error "未找到编译后的 jar 文件"
        exit 1
    fi
    
    # 创建部署目录
    mkdir -p "${DEPLOY_DIR}/backend"
    
    # 复制 jar 文件
    cp "$JAR_FILE" "${DEPLOY_DIR}/backend/"
    
    log_success "jar 文件已复制到: ${DEPLOY_DIR}/backend/"
    log_info "文件: $(basename $JAR_FILE)"
    log_info "大小: $(du -h $JAR_FILE | cut -f1)"
}

# 编译前端
build_frontend() {
    print_title "编译前端项目"
    
    cd "${FRONTEND_DIR}"
    
    # 检查依赖
    if [ ! -d "node_modules" ]; then
        log_info "安装依赖..."
        pnpm install
    fi
    
    # 编译生产版本
    log_info "开始编译生产版本..."
    pnpm run build
    
    if [ $? -eq 0 ]; then
        log_success "前端编译成功"
    else
        log_error "前端编译失败"
        exit 1
    fi
    
    # 创建部署目录
    mkdir -p "${DEPLOY_DIR}/frontend"
    
    # 复制构建产物
    if [ -d "dist" ]; then
        rm -rf "${DEPLOY_DIR}/frontend/dist"
        cp -r dist "${DEPLOY_DIR}/frontend/"
        log_success "构建产物已复制到: ${DEPLOY_DIR}/frontend/dist"
        
        # 统计文件
        FILE_COUNT=$(find "${DEPLOY_DIR}/frontend/dist" -type f | wc -l)
        TOTAL_SIZE=$(du -sh "${DEPLOY_DIR}/frontend/dist" | cut -f1)
        log_info "文件数量: ${FILE_COUNT}"
        log_info "总大小: ${TOTAL_SIZE}"
    else
        log_error "未找到 dist 目录"
        exit 1
    fi
}

# 创建部署包
create_deploy_package() {
    print_title "创建部署包"
    
    cd "${PROJECT_DIR}"
    
    # 创建时间戳
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    PACKAGE_NAME="yshop-deploy-${TIMESTAMP}.tar.gz"
    
    log_info "打包文件..."
    
    # 打包
    tar -czf "${PACKAGE_NAME}" \
        -C "${DEPLOY_DIR}" \
        backend \
        frontend
    
    if [ $? -eq 0 ]; then
        log_success "部署包创建成功"
        log_info "文件名: ${PACKAGE_NAME}"
        log_info "大小: $(du -h ${PACKAGE_NAME} | cut -f1)"
        log_info "路径: ${PROJECT_DIR}/${PACKAGE_NAME}"
    else
        log_error "打包失败"
        exit 1
    fi
}

# 生成部署说明
generate_deploy_readme() {
    cat > "${DEPLOY_DIR}/README.md" << 'EOF'
# YSHOP 部署包

## 📦 包含内容

- `backend/yshop-server-*.jar` - 后端服务
- `frontend/dist/` - 前端构建产物

## 🚀 部署步骤

### 1. 上传到服务器

```bash
# 解压部署包
tar -xzf yshop-deploy-*.tar.gz

# 复制文件到项目目录
cp backend/yshop-server-*.jar /path/to/yshop-drink/yshop-drink-boot3/yshop-server/target/
cp -r frontend/dist /path/to/yshop-drink/yshop-drink-vue3/
```

### 2. 启动服务

```bash
# 进入项目目录
cd /path/to/yshop-drink

# 使用跳过编译模式启动
sudo ./start-server.sh --skip-build --prod-frontend
```

## 📋 注意事项

1. 确保服务器已安装：
   - JDK 17
   - Node.js（如使用生产构建可选）
   - Docker（MySQL 和 Redis）

2. 配置文件：
   - 后端配置：`application-local.yaml`
   - 前端配置：`.env.local`

3. 数据库：
   - 首次部署会自动导入 SQL
   - 后续部署不会重复导入

## 🔧 快速命令

```bash
# 只启动后端（跳过编译）
sudo ./start-server.sh --skip-build

# 使用生产前端
sudo ./start-server.sh --prod-frontend

# 两者结合
sudo ./start-server.sh --skip-build --prod-frontend
```

EOF

    log_success "部署说明已生成: ${DEPLOY_DIR}/README.md"
}

# 主函数
main() {
    clear
    
    echo ""
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}  YSHOP 本地编译脚本${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo ""
    
    # 检查环境
    log_info "检查编译环境..."
    
    if ! command_exists mvn; then
        log_error "未检测到 Maven"
        exit 1
    fi
    
    if ! command_exists node; then
        log_error "未检测到 Node.js"
        exit 1
    fi
    
    if ! command_exists pnpm; then
        log_error "未检测到 pnpm"
        log_info "安装命令: npm install -g pnpm"
        exit 1
    fi
    
    log_success "编译环境检查完成"
    
    # 清理旧的部署目录
    if [ -d "${DEPLOY_DIR}" ]; then
        log_warning "清理旧的部署目录..."
        rm -rf "${DEPLOY_DIR}"
    fi
    
    mkdir -p "${DEPLOY_DIR}"
    
    # 编译
    build_backend
    build_frontend
    
    # 生成部署说明
    generate_deploy_readme
    
    # 创建部署包
    echo ""
    read -p "是否创建部署包? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        create_deploy_package
    fi
    
    # 完成
    echo ""
    echo -e "${GREEN}=======================================${NC}"
    echo -e "${GREEN}✅ 编译完成！${NC}"
    echo -e "${GREEN}=======================================${NC}"
    echo ""
    echo -e "部署文件位置: ${BLUE}${DEPLOY_DIR}${NC}"
    echo ""
    echo -e "${YELLOW}后续步骤:${NC}"
    echo "1. 上传 deploy 目录到服务器"
    echo "2. 复制文件到对应位置"
    echo "3. 运行: sudo ./start-server.sh --skip-build --prod-frontend"
    echo ""
    
    # 显示上传命令示例
    echo -e "${YELLOW}上传命令示例:${NC}"
    echo "scp -r deploy/ user@server:/path/to/yshop-drink/"
    echo ""
}

# 运行主函数
main "$@"

