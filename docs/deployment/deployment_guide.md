# 部署指南

## 1. 部署概述

### 1.1 部署目标
- 实现应用的高可用部署
- 确保部署过程的可重复性
- 最小化部署风险
- 支持快速回滚

### 1.2 部署架构
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   用户请求   │────▶│  负载均衡器  │────▶│   Web服务器  │
└─────────────┘     └─────────────┘     └─────────────┘
                            │                     │
                            ▼                     ▼
                    ┌─────────────┐      ┌─────────────┐
                    │   应用服务器  │      │   数据库    │
                    └─────────────┘      └─────────────┘
```

### 1.3 环境说明
| 环境 | 用途 | 服务器配置 | 域名 |
|------|------|-----------|------|
| 开发环境 | 开发测试 | 2核4G | dev.example.com |
| 测试环境 | 集成测试 | 4核8G | test.example.com |
| 预发布环境 | 上线前验证 | 8核16G | staging.example.com |
| 生产环境 | 正式服务 | 16核32G×4 | api.example.com |

## 2. 部署前准备

### 2.1 环境检查清单
- [ ] 服务器操作系统版本确认
- [ ] 必要的系统依赖已安装
- [ ] 数据库已创建并初始化
- [ ] 域名DNS配置完成
- [ ] SSL证书已准备
- [ ] 防火墙规则已配置
- [ ] 监控告警已配置

### 2.2 依赖安装

#### 2.2.1 系统依赖
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    git \
    curl \
    wget \
    nginx \
    redis-server \
    postgresql-14

# CentOS/RHEL
sudo yum install -y \
    gcc \
    git \
    curl \
    wget \
    nginx \
    redis \
    postgresql14-server
```

#### 2.2.2 运行时环境
```bash
# Node.js安装 (使用nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18.17.0
nvm use 18.17.0

# Python安装 (使用pyenv)
curl https://pyenv.run | bash
pyenv install 3.11.0
pyenv global 3.11.0

# Docker安装
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

### 2.3 配置文件准备

#### 2.3.1 环境变量配置
```bash
# .env.production
NODE_ENV=production
APP_PORT=3000
DATABASE_URL=postgresql://user:password@localhost:5432/dbname
REDIS_URL=redis://localhost:6379
JWT_SECRET=your-secret-key
API_KEY=your-api-key
LOG_LEVEL=info
```

#### 2.3.2 Nginx配置
```nginx
# /etc/nginx/sites-available/app.conf
server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name example.com;
    
    ssl_certificate /etc/ssl/certs/example.com.crt;
    ssl_certificate_key /etc/ssl/private/example.com.key;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 3. 部署方式

### 3.1 手动部署

#### 3.1.1 部署步骤
```bash
# 1. 获取代码
git clone https://github.com/example/app.git
cd app
git checkout v1.0.0

# 2. 安装依赖
npm ci --production

# 3. 构建应用
npm run build

# 4. 数据库迁移
npm run migrate:production

# 5. 启动应用
pm2 start ecosystem.config.js --env production
```

#### 3.1.2 PM2配置
```javascript
// ecosystem.config.js
module.exports = {
  apps: [{
    name: 'app',
    script: './dist/index.js',
    instances: 4,
    exec_mode: 'cluster',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: './logs/err.log',
    out_file: './logs/out.log',
    log_file: './logs/combined.log',
    time: true
  }]
};
```

### 3.2 Docker部署

#### 3.2.1 Dockerfile
```dockerfile
# 多阶段构建
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY --from=builder /app/dist ./dist
EXPOSE 3000
CMD ["node", "dist/index.js"]
```

#### 3.2.2 Docker Compose
```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://postgres:password@db:5432/appdb
      - REDIS_URL=redis://redis:6379
    depends_on:
      - db
      - redis
    restart: always

  db:
    image: postgres:14
    environment:
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=appdb
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: always

  redis:
    image: redis:7-alpine
    restart: always

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - app
    restart: always

volumes:
  postgres_data:
```

### 3.3 Kubernetes部署

#### 3.3.1 Deployment配置
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-deployment
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:v1.0.0
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: "production"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: database-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### 3.3.2 Service配置
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: myapp
  ports:
    - protocol: TCP
      port: 80
      targetPort: 3000
  type: LoadBalancer
```

### 3.4 CI/CD自动化部署

#### 3.4.1 GitHub Actions
```yaml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Run tests
        run: npm test
        
      - name: Build application
        run: npm run build
        
      - name: Build Docker image
        run: |
          docker build -t myapp:${{ github.ref_name }} .
          docker tag myapp:${{ github.ref_name }} myapp:latest
          
      - name: Push to registry
        run: |
          echo ${{ secrets.DOCKER_PASSWORD }} | docker login -u ${{ secrets.DOCKER_USERNAME }} --password-stdin
          docker push myapp:${{ github.ref_name }}
          docker push myapp:latest
          
      - name: Deploy to server
        uses: appleboy/ssh-action@v0.1.5
        with:
          host: ${{ secrets.HOST }}
          username: ${{ secrets.USERNAME }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /opt/app
            docker-compose pull
            docker-compose up -d
```

## 4. 数据库部署

### 4.1 数据库初始化
```sql
-- 创建数据库
CREATE DATABASE appdb;

-- 创建用户
CREATE USER appuser WITH PASSWORD 'secure_password';

-- 授权
GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;

-- 创建扩展
\c appdb
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

### 4.2 数据迁移
```bash
# 使用迁移工具
npm run migrate:up

# 或使用SQL脚本
psql -h localhost -U appuser -d appdb -f migrations/001_initial.sql
```

### 4.3 数据备份策略
```bash
# 定时备份脚本
#!/bin/bash
BACKUP_DIR="/backup/postgres"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_NAME="appdb"

# 创建备份
pg_dump -h localhost -U postgres $DB_NAME > $BACKUP_DIR/backup_$TIMESTAMP.sql

# 压缩备份
gzip $BACKUP_DIR/backup_$TIMESTAMP.sql

# 删除7天前的备份
find $BACKUP_DIR -name "backup_*.sql.gz" -mtime +7 -delete
```

## 5. 部署后验证

### 5.1 健康检查
```bash
# 应用健康检查
curl -f http://localhost:3000/health || exit 1

# 数据库连接检查
psql -h localhost -U appuser -d appdb -c "SELECT 1"

# Redis连接检查
redis-cli ping
```

### 5.2 功能验证清单
- [ ] 首页正常访问
- [ ] 用户登录功能正常
- [ ] API接口响应正常
- [ ] 静态资源加载正常
- [ ] WebSocket连接正常
- [ ] 日志记录正常
- [ ] 监控数据上报正常

### 5.3 性能验证
```bash
# 简单性能测试
ab -n 1000 -c 10 http://localhost:3000/api/health

# 响应时间检查
time curl http://localhost:3000/api/users
```

## 6. 回滚方案

### 6.1 快速回滚步骤
```bash
# 1. 停止当前版本
pm2 stop app

# 2. 切换到上一个版本
cd /opt/app
git checkout v0.9.0

# 3. 重新安装依赖和构建
npm ci --production
npm run build

# 4. 数据库回滚（如需要）
npm run migrate:down

# 5. 重启应用
pm2 restart app
```

### 6.2 Docker回滚
```bash
# 回滚到上一个版本
docker-compose down
docker-compose up -d myapp:v0.9.0
```

### 6.3 Kubernetes回滚
```bash
# 查看部署历史
kubectl rollout history deployment/app-deployment

# 回滚到上一个版本
kubectl rollout undo deployment/app-deployment

# 回滚到指定版本
kubectl rollout undo deployment/app-deployment --to-revision=2
```

## 7. 监控与告警

### 7.1 监控配置
```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'app'
    static_configs:
      - targets: ['localhost:3000']
    metrics_path: '/metrics'
```

### 7.2 告警规则
```yaml
# alerts.yml
groups:
  - name: app_alerts
    rules:
      - alert: AppDown
        expr: up{job="app"} == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "应用服务宕机"
          
      - alert: HighMemoryUsage
        expr: process_resident_memory_bytes > 1e9
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "内存使用过高"
```

## 8. 故障排查

### 8.1 常见问题
| 问题 | 可能原因 | 解决方案 |
|------|---------|---------|
| 应用无法启动 | 端口被占用 | 检查端口占用，kill进程 |
| 数据库连接失败 | 配置错误 | 检查连接字符串 |
| 性能下降 | 资源不足 | 扩容或优化代码 |

### 8.2 日志查看
```bash
# 应用日志
pm2 logs app

# Nginx日志
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# 系统日志
journalctl -u app -f
```

## 9. 安全加固

### 9.1 系统安全
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 配置防火墙
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# 禁用root登录
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### 9.2 应用安全
- 使用HTTPS
- 启用CORS
- 实施速率限制
- 定期更新依赖
- 使用安全的密码策略

## 10. 维护计划

### 10.1 日常维护
- 日志清理（每日）
- 监控检查（每日）
- 备份验证（每周）
- 安全更新（每月）

### 10.2 定期维护脚本
```bash
#!/bin/bash
# maintenance.sh

# 清理日志
find /var/log -name "*.log" -mtime +30 -delete

# 清理临时文件
find /tmp -type f -mtime +7 -delete

# 数据库维护
psql -U postgres -d appdb -c "VACUUM ANALYZE;"

# 更新系统
apt update && apt upgrade -y
```

---
*文档版本*：1.0  
*最后更新*：YYYY-MM-DD  
*运维负责人*：[姓名]