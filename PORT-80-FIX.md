# 🔧 端口 80 权限问题修复

## ❌ 错误信息

```
Error: listen EACCES: permission denied 0.0.0.0:80
```

**原因**: 端口 80 是特权端口，需要 root 权限。

---

## ✅ 解决方案（4种）

### 方案1：使用 sudo（最简单）⭐

```bash
# 使用启动脚本（推荐）
cd ~/github/yshop-drink
sudo ./start-server.sh --github-release v1.1.2

# 或者手动启动
sudo http-server dist-prod -p 80
```

---

### 方案2：使用 Nginx（生产环境推荐）⭐⭐⭐

```bash
# 1. 运行 Nginx 配置脚本
cd ~/github/yshop-drink
sudo ./setup-nginx.sh

# 2. 完成！Nginx 会自动：
#    - 服务前端静态文件（端口 80）
#    - 代理后端 API
#    - 启用 Gzip 压缩
#    - 配置静态资源缓存
```

**优点**：
- ✅ 性能更好
- ✅ 更稳定
- ✅ 支持 HTTPS（可扩展）
- ✅ 生产环境标准方案

---

### 方案3：使用非特权端口（测试用）

```bash
# 使用端口 8080（无需 sudo）
http-server dist-prod -p 8080

# 访问
http://your-server-ip:8080
```

**缺点**：需要在 URL 中加端口号

---

### 方案4：给 Node.js 添加权限

```bash
# 给 Node.js 添加绑定特权端口的能力
sudo setcap 'cap_net_bind_service=+ep' $(which node)

# 然后就可以不用 sudo 了
http-server dist-prod -p 80
```

⚠️ **警告**：有安全风险，不推荐！

---

## 🎯 推荐方案对比

| 方案 | 难度 | 性能 | 适用场景 | 推荐度 |
|------|------|------|---------|--------|
| **Nginx** | ⭐⭐ | ⭐⭐⭐⭐⭐ | 生产环境 | ⭐⭐⭐⭐⭐ |
| **sudo** | ⭐ | ⭐⭐⭐ | 快速部署 | ⭐⭐⭐⭐ |
| **非特权端口** | ⭐ | ⭐⭐⭐ | 测试 | ⭐⭐ |
| **setcap** | ⭐⭐ | ⭐⭐⭐ | 不推荐 | ⭐ |

---

## 📋 完整部署流程

### 使用 Nginx（推荐）

```bash
# 1. 部署应用
cd ~/github/yshop-drink
sudo ./start-server.sh --github-release v1.1.2

# 启动脚本会：
# - 启动 MySQL 和 Redis
# - 启动后端（端口 48081）
# - ⚠️ 尝试启动 http-server（端口 80）但会失败

# 2. 停止 http-server 尝试（如果有）
pkill -f http-server

# 3. 配置并启动 Nginx
sudo ./setup-nginx.sh

# 4. 验证
curl http://localhost/
curl http://localhost/admin-api/system/health

# 5. 完成！
```

---

### 使用 sudo 快速部署

```bash
# 一条命令完成所有部署
cd ~/github/yshop-drink
sudo ./start-server.sh --github-release v1.1.2
```

**注意**：脚本必须用 `sudo` 运行，这样内部的 `http-server` 才能绑定端口 80。

---

## 🔍 故障排查

### 问题1：Nginx 启动失败

```bash
# 查看错误
sudo nginx -t
sudo systemctl status nginx

# 查看日志
sudo tail -f /var/log/nginx/error.log
```

**常见原因**：
- 端口 80 被占用
- 配置文件语法错误
- 前端目录不存在

---

### 问题2：端口 80 被占用

```bash
# 查看谁占用了端口 80
sudo lsof -i :80

# 停止占用进程
sudo kill -9 <PID>

# 或者停止 Apache（如果安装了）
sudo systemctl stop apache2
sudo systemctl disable apache2
```

---

### 问题3：前端 404

```bash
# 检查前端目录
ls -la ~/github/yshop-drink/yshop-drink-vue3/dist-prod/

# 应该看到：
# - index.html
# - assets/

# 如果目录为空，重新部署
cd ~/github/yshop-drink
sudo ./start-server.sh --github-release v1.1.2
```

---

## 🎯 Nginx 配置详解

配置文件位置：`/etc/nginx/sites-available/yshop`

```nginx
server {
    listen 80;                        # 监听端口 80
    server_name _;                    # 接受所有域名/IP
    
    # 前端静态文件
    root /path/to/dist-prod;         # 前端构建目录
    index index.html;
    
    # 前端路由（SPA）
    location / {
        try_files $uri $uri/ /index.html;  # Vue Router 支持
    }
    
    # 后端 API 代理
    location /admin-api/ {
        proxy_pass http://localhost:48081;  # 转发到后端
    }
    
    location /app-api/ {
        proxy_pass http://localhost:48081;
    }
    
    # 静态资源缓存
    location ~* \.(jpg|png|css|js)$ {
        expires 30d;                  # 缓存 30 天
    }
}
```

---

## 💡 最佳实践

### 生产环境部署清单

- [x] 使用 Nginx 代替 http-server
- [x] 启用 Gzip 压缩
- [x] 配置静态资源缓存
- [x] 配置访问日志
- [x] 设置开机自启动
- [ ] 配置 HTTPS（Let's Encrypt）
- [ ] 配置防火墙
- [ ] 配置监控

---

## 🚀 快速命令

```bash
# === 方案1：使用 Nginx ===
sudo ./setup-nginx.sh

# === 方案2：使用 sudo ===
sudo ./start-server.sh --github-release

# === 验证服务 ===
curl http://localhost/
docker ps
sudo lsof -i :80

# === 查看日志 ===
# Nginx 日志
sudo tail -f /var/log/nginx/yshop-access.log

# http-server 日志
tail -f ~/logs/yshop-frontend.log

# === 重启服务 ===
# Nginx
sudo systemctl restart nginx

# http-server
pkill -f http-server
sudo http-server dist-prod -p 80 &
```

---

## 📞 需要帮助？

如果还有问题：

1. 查看完整日志：`tail -100 ~/logs/yshop-frontend.log`
2. 检查端口占用：`sudo lsof -i :80`
3. 验证前端文件：`ls -la ~/github/yshop-drink/yshop-drink-vue3/dist-prod/`

---

**推荐方案**: 使用 `setup-nginx.sh` 配置 Nginx，这是生产环境的标准做法！

```bash
sudo ./setup-nginx.sh
```

简单、安全、高性能！🚀✨

