# 使用 localhost 作为后端地址调试指南

## 📋 当前配置状态

### 小程序配置文件

**文件位置**：`yshop-drink-uniapp-vue3/config/index.js`

```javascript
export const VUE_APP_API_URL = 'http://localhost:48081/app-api'
//export const VUE_APP_API_URL = 'https://apidc.yixiang.co/app-api'
export const VUE_APP_RESOURCES_URL = 'https://h5.yixiang.co/static'
export const VUE_APP_UPLOAD_URL = VUE_APP_API_URL + '/infra/file/upload'
```

✅ **配置已经是 localhost**，无需修改！

---

## 🎯 使用 localhost 的好处

### ✅ 优点

1. **不需要内网穿透工具**
   - 不需要 natapp
   - 不需要配置公网IP
   - 不需要配置微信IP白名单

2. **开发更快速**
   - 请求直接走本地
   - 延迟更低
   - 调试更方便

3. **成本更低**
   - 无需购买内网穿透服务
   - 无需云服务器

### ❌ 限制

1. **只能在微信开发者工具中使用**
   - ⚠️ 真机无法访问 localhost
   - 真机必须使用公网地址

2. **某些功能受限**
   - 微信支付回调无法测试（需要公网地址）
   - 第三方接口回调无法测试

---

## 🛠️ 配置步骤

### 步骤1：确认后端服务运行

```bash
# 检查后端是否运行在 48081 端口
lsof -i :48081

# 或者
curl http://localhost:48081/app-api
```

**预期结果**：返回API响应或错误页面（说明服务正常）

### 步骤2：配置微信开发者工具

#### 2.1 打开微信开发者工具

#### 2.2 关闭域名校验

```
路径：详情 → 本地设置 → 勾选以下选项

✅ 不校验合法域名、web-view（业务域名）、TLS 版本以及 HTTPS 证书
✅ 启用调试模式（可选）
```

**重要**：这个设置对每个项目都要单独配置！

#### 2.3 编译运行

- 点击"编译"按钮
- 查看控制台是否有网络错误

### 步骤3：测试登录功能

#### 3.1 解决微信小程序登录的问题

使用 localhost 后，微信小程序登录会有新的问题：

**问题**：调用微信接口 `wx.login().then(res => {...})` 时，后端仍然需要调用微信API

**解决方案A**：使用模拟登录（推荐开发调试）

修改后端代码，跳过微信验证：

```java
// 在 MemberAuthServiceImpl.java 中
// 添加开发环境的模拟登录逻辑
```

**解决方案B**：配置微信IP白名单（如果仍需要调用微信API）

即使使用 localhost，后端调用微信API时仍然是从您的电脑发出请求：
- 需要查询您的公网IP
- 将公网IP加入微信白名单

```bash
# 查询您的公网IP
curl ifconfig.me
# 或
curl ip.sb
```

#### 3.2 测试短信验证码

短信验证码功能正常可用：
- 钉钉短信渠道会正常工作
- 查看日志获取验证码（通常是 9999）

---

## 📱 真机调试怎么办？

### 方法1：使用内网IP（同一局域网）

如果您的手机和电脑在同一个WiFi网络：

#### 1. 查看电脑内网IP

```bash
# macOS/Linux
ifconfig | grep "inet " | grep -v 127.0.0.1

# 会显示类似：
# inet 192.168.1.100 netmask 0xffffff00 broadcast 192.168.1.255
```

#### 2. 修改配置文件

```javascript
// config/index.js
export const VUE_APP_API_URL = 'http://192.168.1.100:48081/app-api'
```

#### 3. 在微信开发者工具中真机预览

- 点击"预览"按钮
- 扫码在真机上打开
- 仍需关闭域名校验（在开发者工具中设置）

**限制**：
- ⚠️ 手机必须和电脑在同一WiFi
- ⚠️ 某些路由器可能禁止设备间通信
- ⚠️ 微信支付等功能仍无法测试

### 方法2：配置多个环境

创建不同环境的配置：

```javascript
// config/index.js
const env = process.env.NODE_ENV

let VUE_APP_API_URL

if (env === 'development') {
  // 开发环境：使用 localhost
  VUE_APP_API_URL = 'http://localhost:48081/app-api'
} else if (env === 'test') {
  // 测试环境：使用 natapp
  VUE_APP_API_URL = 'http://yshop.natapp1.cc/app-api'
} else {
  // 生产环境：使用正式域名
  VUE_APP_API_URL = 'https://api.yourdomain.com/app-api'
}

export { VUE_APP_API_URL }
```

---

## 🔧 完整配置示例

### 配置文件：config/index.js

```javascript
// 开发环境配置
const DEV_CONFIG = {
  // 方式1：使用 localhost（仅开发工具可用）
  apiUrl: 'http://localhost:48081/app-api',
  
  // 方式2：使用内网IP（开发工具 + 真机预览）
  // apiUrl: 'http://192.168.1.100:48081/app-api',
  
  // 方式3：使用 natapp（开发工具 + 真机预览 + 完整功能）
  // apiUrl: 'http://yshop.natapp1.cc/app-api',
}

// 生产环境配置
const PROD_CONFIG = {
  apiUrl: 'https://api.yourdomain.com/app-api',
}

// 根据环境选择配置
const config = process.env.NODE_ENV === 'production' ? PROD_CONFIG : DEV_CONFIG

export const VUE_APP_API_URL = config.apiUrl
export const VUE_APP_RESOURCES_URL = 'https://h5.yixiang.co/static'
export const VUE_APP_UPLOAD_URL = VUE_APP_API_URL + '/infra/file/upload'
```

---

## 🎯 推荐的开发流程

### 阶段1：功能开发（当前）

```
配置：localhost
工具：微信开发者工具
优势：快速开发，无需额外配置
限制：不能真机测试
```

### 阶段2：真机测试

```
配置：内网IP（192.168.x.x）或 natapp
工具：微信开发者工具 + 真机预览
优势：可以在真机测试大部分功能
限制：支付回调等功能仍不可用
```

### 阶段3：完整测试

```
配置：natapp 或云服务器
工具：真机扫码测试
优势：所有功能完整可测试
限制：需要配置公网访问
```

### 阶段4：生产部署

```
配置：正式域名 + HTTPS
工具：发布上线
优势：正式环境，稳定可靠
```

---

## ⚠️ 重要注意事项

### 1. 微信小程序登录问题

**使用 localhost 时的特殊处理**：

即使使用 localhost，**后端调用微信API时仍然需要IP白名单**！

原因：
```
小程序 → localhost:48081（您的后端）→ 微信服务器
                                      ↑
                                 这一步需要IP白名单
```

**解决方案**：

**选项A：查询并配置您的公网IP**
```bash
# 查询公网IP
curl ifconfig.me

# 将返回的IP添加到微信白名单
```

**选项B：开发环境跳过微信登录验证**
- 修改后端代码，开发环境返回mock数据
- 仅用于快速开发测试

### 2. 开发工具设置

**每次打开项目都要检查**：
- ✅ 不校验合法域名
- ✅ 不校验TLS版本
- ✅ 不校验HTTPS证书

### 3. 跨域问题

使用 localhost 通常不会有跨域问题，但如果遇到：

```java
// 后端已经配置了CORS
// 在 CorsConfiguration 中允许了所有来源
```

---

## 🔍 故障排查

### 问题1：请求失败，控制台显示网络错误

**检查清单**：
- [ ] 后端服务是否运行（访问 http://localhost:48081）
- [ ] 端口是否正确（48081）
- [ ] 开发工具是否关闭域名校验
- [ ] 防火墙是否阻止了请求

```bash
# 测试后端是否可访问
curl http://localhost:48081/app-api

# 检查端口占用
lsof -i :48081
```

### 问题2：登录失败，显示40164错误

**原因**：后端调用微信API时IP不在白名单

**解决**：
```bash
# 查询您的公网IP
curl ifconfig.me

# 将IP添加到微信公众平台的白名单
```

### 问题3：真机预览时无法访问

**原因**：真机不能访问 localhost

**解决**：
```javascript
// 改用内网IP
export const VUE_APP_API_URL = 'http://192.168.1.100:48081/app-api'
```

---

## 📋 快速操作清单

### 使用 localhost 开发

- [ ] 确认后端运行在 localhost:48081
- [ ] 确认配置文件使用 localhost
- [ ] 打开微信开发者工具
- [ ] 关闭域名校验
- [ ] 编译运行
- [ ] 测试基本功能

### 如果需要测试微信登录

- [ ] 查询公网IP：`curl ifconfig.me`
- [ ] 添加IP到微信白名单
- [ ] 等待1-2分钟生效
- [ ] 重新测试登录

### 如果需要真机测试

- [ ] 查询内网IP：`ifconfig`
- [ ] 修改配置为内网IP
- [ ] 使用真机预览功能
- [ ] 测试功能

---

## 💡 推荐配置

### 最佳实践：环境切换

创建 `.env` 文件管理不同环境：

```
# .env.development
VUE_APP_API_URL=http://localhost:48081/app-api

# .env.test
VUE_APP_API_URL=http://yshop.natapp1.cc/app-api

# .env.production
VUE_APP_API_URL=https://api.yourdomain.com/app-api
```

这样可以快速切换不同环境！

---

## 📞 总结

### 使用 localhost 的核心要点

1. ✅ **配置已经正确**：`http://localhost:48081/app-api`
2. ✅ **开发工具必须关闭域名校验**
3. ⚠️ **仍需配置微信IP白名单**（如果要测试登录）
4. ⚠️ **真机无法使用 localhost**（需要内网IP或natapp）

### 当前状态

- 后端：localhost:48081 ✅
- 前端配置：localhost ✅
- 微信开发工具：需要关闭域名校验 ⚠️
- 微信IP白名单：需要配置（如果测试登录）⚠️

### 下一步

1. 在微信开发者工具中关闭域名校验
2. 测试基本功能
3. 如需测试登录，配置公网IP到微信白名单
4. 如需真机测试，改用内网IP或natapp

