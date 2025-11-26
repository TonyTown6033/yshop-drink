#!/bin/bash

################################################################################
# YSHOP - Nginx 配置脚本
# 用于配置 Nginx 代替 http-server
################################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# 检查是否 root
if [ "$EUID" -ne 0 ]; then
    log_error "请使用 sudo 运行此脚本"
    exit 1
fi

echo -e "${GREEN}"
echo "========================================"
echo "  YSHOP - Nginx 配置脚本"
echo "========================================"
echo -e "${NC}"

# 项目目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FRONTEND_DIR="${PROJECT_DIR}/yshop-drink-vue3"

# 检查 Nginx 是否已安装
if ! command -v nginx >/dev/null 2>&1; then
    log_info "安装 Nginx..."
    apt-get update
    apt-get install -y nginx
    log_success "Nginx 安装完成"
else
    log_info "Nginx 已安装"
fi

# 询问域名或 IP
read -p "请输入域名或服务器 IP（直接回车使用 _）: " SERVER_NAME
if [ -z "$SERVER_NAME" ]; then
    SERVER_NAME="_"
fi

# 检查前端目录
if [ -d "${FRONTEND_DIR}/dist-prod" ]; then
    DIST_DIR="${FRONTEND_DIR}/dist-prod"
    log_info "使用 dist-prod 目录"
elif [ -d "${FRONTEND_DIR}/dist" ]; then
    DIST_DIR="${FRONTEND_DIR}/dist"
    log_info "使用 dist 目录"
else
    log_error "未找到前端构建目录（dist-prod 或 dist）"
    log_info "请先部署前端："
    echo "  sudo ./start-server.sh --github-release"
    exit 1
fi

# 创建 Nginx 配置
log_info "创建 Nginx 配置..."
cat > /etc/nginx/sites-available/yshop << EOF
server {
    listen 80;
    server_name ${SERVER_NAME};
    
    # 前端静态文件
    root ${DIST_DIR};
    index index.html;
    
    # 访问日志
    access_log /var/log/nginx/yshop-access.log;
    error_log /var/log/nginx/yshop-error.log;
    
    # Gzip 压缩
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;
    
    # 前端路由（SPA）
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # 后端 API 代理
    location /admin-api/ {
        proxy_pass http://localhost:48081;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket 支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    location /app-api/ {
        proxy_pass http://localhost:48081;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # WebSocket 支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # 静态资源缓存
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
}
EOF

log_success "Nginx 配置已创建"

# 启用站点
log_info "启用站点..."
ln -sf /etc/nginx/sites-available/yshop /etc/nginx/sites-enabled/

# 删除默认站点（可选）
if [ -f /etc/nginx/sites-enabled/default ]; then
    log_warning "删除默认站点配置"
    rm -f /etc/nginx/sites-enabled/default
fi

# 测试配置
log_info "测试 Nginx 配置..."
if nginx -t; then
    log_success "Nginx 配置测试通过"
else
    log_error "Nginx 配置测试失败"
    exit 1
fi

# 停止 http-server（如果在运行）
log_info "停止 http-server（如果在运行）..."
pkill -f "http-server" || true

# 重启 Nginx
log_info "重启 Nginx..."
systemctl restart nginx
systemctl enable nginx

log_success "Nginx 配置完成"

# 显示状态
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Nginx 配置成功！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "前端地址: ${BLUE}http://${SERVER_NAME}/${NC}"
echo -e "后端 API: ${BLUE}http://${SERVER_NAME}/admin-api/${NC}"
echo ""
echo -e "配置文件: ${BLUE}/etc/nginx/sites-available/yshop${NC}"
echo -e "访问日志: ${BLUE}/var/log/nginx/yshop-access.log${NC}"
echo -e "错误日志: ${BLUE}/var/log/nginx/yshop-error.log${NC}"
echo ""
echo -e "${YELLOW}常用命令:${NC}"
echo -e "  重启 Nginx: ${BLUE}sudo systemctl restart nginx${NC}"
echo -e "  查看状态:   ${BLUE}sudo systemctl status nginx${NC}"
echo -e "  查看日志:   ${BLUE}sudo tail -f /var/log/nginx/yshop-access.log${NC}"
echo ""

