# 🧹 智能端口清理工具使用指南

## 📋 功能说明

`clean-ports.sh` 是一个智能端口清理工具，能够：

1. ✅ **识别端口占用类型**
   - Docker 容器
   - 普通进程

2. ✅ **优雅清理 Docker 容器**
   - 使用 `docker stop` 优雅停止（10秒超时）
   - 使用 `docker rm` 删除容器（可选）
   - 使用 `docker rmi` 删除镜像（可选）

3. ✅ **优雅清理普通进程**
   - 先发送 SIGTERM 信号（优雅停止）
   - 等待 10 秒
   - 如需要才使用 SIGKILL 强制停止

---

## 🚀 快速使用

### 基本用法

```bash
cd ~/github/yshop-drink
sudo ./clean-ports.sh
```

### 执行流程

```
1️⃣ 扫描端口占用
   └─ 检查 3306, 6379, 48081, 80
   ↓
2️⃣ 显示占用详情
   ├─ 进程 PID
   ├─ 进程名称
   └─ 关联的 Docker 容器（如果有）
   ↓
3️⃣ 询问清理方式
   ├─ 仅停止容器（推荐）
   ├─ 停止并删除容器
   ├─ 停止、删除容器并删除镜像
   └─ 取消
   ↓
4️⃣ 执行清理
   ├─ Docker 容器 → docker stop/rm/rmi
   └─ 普通进程 → kill (SIGTERM) → kill -9 (SIGKILL)
   ↓
5️⃣ 显示结果
   └─ 成功/失败统计
```

---

## 📊 清理选项说明

### 选项1：仅停止容器（推荐）⭐

```
操作: docker stop
结果: 
  ✓ 容器停止运行
  ✓ 容器保留（可用 docker start 恢复）
  ✓ 镜像保留
  ✓ 数据卷保留
```

**适用场景**：
- 临时需要端口
- 后续还要使用容器
- 不想重新下载镜像

**恢复方法**：
```bash
docker start yshop-mysql
docker start yshop-redis
```

---

### 选项2：停止并删除容器

```
操作: docker stop + docker rm
结果:
  ✓ 容器停止运行
  ✓ 容器被删除
  ✓ 镜像保留（可重新创建容器）
  ⚠️ 数据卷可能丢失（取决于配置）
```

**适用场景**：
- 需要重新创建容器
- 容器配置错误
- 清理旧容器

**恢复方法**：
```bash
cd ~/github/yshop-drink
sudo ./start-server.sh --github-release
# 或
docker compose up -d
```

---

### 选项3：停止、删除容器并删除镜像

```
操作: docker stop + docker rm + docker rmi
结果:
  ✓ 容器停止运行
  ✓ 容器被删除
  ✓ 镜像被删除
  ✓ 释放磁盘空间（500MB+）
  ⚠️ 需要重新下载镜像
```

**适用场景**：
- 完全清理环境
- 磁盘空间不足
- 升级镜像版本

**恢复方法**：
```bash
cd ~/github/yshop-drink
sudo ./start-server.sh --github-release
# 会自动下载新镜像
```

---

## 🎯 使用示例

### 示例1：临时清理端口

```bash
$ sudo ./clean-ports.sh

================================================
  YSHOP 智能端口清理工具
================================================

[INFO] 检查端口占用情况...

✗ 端口 3306 (MySQL) 已被占用
端口: 3306
  PID: 12345
  进程: docker-proxy
  用户: root
  [Docker 容器]
    容器 ID: abc123def456
    容器名称: yshop-mysql
    镜像: mysql:8.0

✗ 端口 6379 (Redis) 已被占用
端口: 6379
  PID: 12346
  进程: docker-proxy
  用户: root
  [Docker 容器]
    容器 ID: def456abc789
    容器名称: yshop-redis
    镜像: redis:7.0

发现 2 个端口被占用

检测到 Docker 容器占用端口

清理选项：
  1. 仅停止容器（推荐）
  2. 停止并删除容器
  3. 停止、删除容器并删除镜像
  4. 取消

请选择 (1-4): 1

[INFO] 将停止 Docker 容器（不删除）

[INFO] 开始清理端口...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
清理端口 3306 (MySQL)

[INFO] 检测到 Docker 容器占用端口 3306
[INFO] 停止 Docker 容器: yshop-mysql
[SUCCESS] 容器已停止: yshop-mysql
[SUCCESS] 端口 3306 已释放

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
清理端口 6379 (Redis)

[INFO] 检测到 Docker 容器占用端口 6379
[INFO] 停止 Docker 容器: yshop-redis
[SUCCESS] 容器已停止: yshop-redis
[SUCCESS] 端口 6379 已释放

================================================
清理完成
================================================

成功清理: 2 个端口
清理失败: 0 个端口

Docker 清理详情:
  ✓ 容器已停止（未删除）
  ✓ 镜像已保留

[SUCCESS] 所有端口已清理，现在可以启动服务

[INFO] 运行启动脚本：
  sudo ./start-server.sh --github-release
```

---

### 示例2：完全清理（包括镜像）

```bash
$ sudo ./clean-ports.sh

# ... (扫描端口) ...

清理选项：
  1. 仅停止容器（推荐）
  2. 停止并删除容器
  3. 停止、删除容器并删除镜像
  4. 取消

请选择 (1-4): 3

[WARNING] 将停止、删除容器并删除镜像
确认删除镜像? (y/n) y

[INFO] 开始清理端口...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
清理端口 3306 (MySQL)

[INFO] 检测到 Docker 容器占用端口 3306
[INFO] 停止 Docker 容器: yshop-mysql
[SUCCESS] 容器已停止: yshop-mysql
[INFO] 删除容器: yshop-mysql
[SUCCESS] 容器已删除: yshop-mysql
[INFO] 删除镜像: mysql:8.0
[SUCCESS] 镜像已删除: mysql:8.0
[SUCCESS] 端口 3306 已释放

# ...

Docker 清理详情:
  ✓ 容器已删除
  ✓ 镜像已删除

[SUCCESS] 所有端口已清理，现在可以启动服务
```

---

## 🔧 高级功能

### 手动指定端口

编辑脚本中的 `PORTS` 数组：

```bash
declare -A PORTS=(
    [3306]="MySQL"
    [6379]="Redis"
    [48081]="后端服务"
    [80]="前端服务"
    [8080]="自定义服务"  # 添加新端口
)
```

### 查看容器详情

脚本会自动显示：
- 容器 ID
- 容器名称
- 镜像名称
- 端口映射

---

## ⚠️ 注意事项

### 1. 数据安全

**删除容器前请确认**：
- ❌ 选项2/3 可能导致数据丢失
- ✅ 使用 Docker Compose volumes 持久化数据
- ✅ 定期备份数据库

**数据位置**：
```
~/github/yshop-drink/
├── mysql-data/    # MySQL 数据持久化
└── redis-data/    # Redis 数据持久化
```

### 2. 权限要求

```bash
# 必须使用 sudo
sudo ./clean-ports.sh

# 否则无法访问 Docker
```

### 3. 容器依赖

删除镜像前检查：
```bash
# 查看镜像被哪些容器使用
docker ps -a --filter ancestor=mysql:8.0
```

---

## 🆚 对比：新旧版本

### 旧版本（不推荐）

```bash
# 直接 kill -9 所有进程
kill -9 $(lsof -ti :3306)

问题：
  ❌ 不区分 Docker 容器和普通进程
  ❌ 强制停止，可能导致数据损坏
  ❌ 容器状态不一致
  ❌ 镜像残留
```

### 新版本（推荐）⭐

```bash
# 智能识别并优雅清理
sudo ./clean-ports.sh

优点：
  ✅ 识别 Docker 容器
  ✅ 优雅停止（10秒超时）
  ✅ 可选删除容器/镜像
  ✅ 保留数据卷
  ✅ 清晰的操作反馈
```

---

## 🔍 故障排查

### 问题1：权限不足

```bash
[ERROR] Permission denied

解决：
sudo ./clean-ports.sh
```

### 问题2：端口仍然占用

```bash
# 手动检查
sudo lsof -i :3306

# 查看 Docker 容器
docker ps -a

# 强制删除容器
docker rm -f yshop-mysql
```

### 问题3：镜像删除失败

```
[WARNING] 镜像删除失败（可能被其他容器使用）

原因：镜像被其他容器使用

解决：
# 1. 查看所有使用该镜像的容器
docker ps -a --filter ancestor=mysql:8.0

# 2. 删除所有相关容器
docker rm -f $(docker ps -aq --filter ancestor=mysql:8.0)

# 3. 重新删除镜像
docker rmi mysql:8.0
```

---

## 📝 恢复服务

### 恢复 Docker 容器

```bash
# 如果只是停止（选项1）
docker start yshop-mysql yshop-redis

# 如果删除了容器（选项2/3）
cd ~/github/yshop-drink
docker compose up -d

# 或使用启动脚本
sudo ./start-server.sh --github-release
```

### 检查数据完整性

```bash
# MySQL
docker exec yshop-mysql mysql -uroot -proot123456 yixiang-drink -e "SHOW TABLES;"

# Redis
docker exec yshop-redis redis-cli -a redis123456 PING
```

---

## 💡 最佳实践

### 开发环境

```bash
# 推荐使用选项1（仅停止）
sudo ./clean-ports.sh
# 选择：1. 仅停止容器

# 优点：
# - 快速恢复
# - 保留所有数据
# - 不需要重新下载镜像
```

### 测试环境

```bash
# 可使用选项2（删除容器）
sudo ./clean-ports.sh
# 选择：2. 停止并删除容器

# 优点：
# - 清理旧配置
# - 保留镜像（快速重建）
# - 节省一些空间
```

### 生产环境

```bash
# ⚠️ 谨慎操作！
# 建议先备份数据
docker exec yshop-mysql mysqldump -uroot -proot123456 yixiang-drink \
  > backup-$(date +%Y%m%d).sql

# 然后使用选项1
sudo ./clean-ports.sh
```

---

## 🎉 总结

新版 `clean-ports.sh` 提供了：

1. ✅ **智能识别**：区分 Docker 容器和普通进程
2. ✅ **优雅停止**：使用 `docker stop` 而不是 `kill -9`
3. ✅ **灵活选择**：3种清理级别供选择
4. ✅ **安全可靠**：保护数据，清晰反馈
5. ✅ **易于恢复**：提供完整的恢复指南

**使用建议**：
- 开发：选项1（仅停止）
- 测试：选项2（删除容器）
- 生产：谨慎操作，建议先备份

---

**更新时间**: 2025-11-26  
**版本**: v2.0  
**状态**: ✅ 生产就绪

