# Strapi 应用部署指南

本文档提供了如何使用 Docker 和 Docker Compose 部署 Glass Enterprise Strapi 应用的指南。

## 前提条件

确保服务器上已安装：
- Docker (20.10+)
- Docker Compose (2.0+)
- Git

## 部署步骤

### 1. 准备环境

1. 克隆代码库到服务器:

```bash
git clone <仓库地址> glass-enterprise-strapi
cd glass-enterprise-strapi
```

2. 创建环境变量文件:

```bash
cp .env.example .env
```

3. 编辑 `.env` 文件，设置安全的密钥和密码:

```bash
# 生成随机密钥
APP_KEYS=$(openssl rand -base64 32),$(openssl rand -base64 32)
API_TOKEN_SALT=$(openssl rand -base64 32)
ADMIN_JWT_SECRET=$(openssl rand -base64 32)
JWT_SECRET=$(openssl rand -base64 32)
DATABASE_PASSWORD=$(openssl rand -base64 16)

# 将生成的密钥替换到 .env 文件中
sed -i "s/APP_KEYS=.*/APP_KEYS=$APP_KEYS/" .env
sed -i "s/API_TOKEN_SALT=.*/API_TOKEN_SALT=$API_TOKEN_SALT/" .env
sed -i "s/ADMIN_JWT_SECRET=.*/ADMIN_JWT_SECRET=$ADMIN_JWT_SECRET/" .env
sed -i "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
sed -i "s/DATABASE_PASSWORD=.*/DATABASE_PASSWORD=$DATABASE_PASSWORD/" .env

# 如果是在 macOS 上执行，需要使用不同的 sed 命令
# sed -i '' "s/APP_KEYS=.*/APP_KEYS=$APP_KEYS/" .env
# sed -i '' "s/API_TOKEN_SALT=.*/API_TOKEN_SALT=$API_TOKEN_SALT/" .env
# sed -i '' "s/ADMIN_JWT_SECRET=.*/ADMIN_JWT_SECRET=$ADMIN_JWT_SECRET/" .env
# sed -i '' "s/JWT_SECRET=.*/JWT_SECRET=$JWT_SECRET/" .env
# sed -i '' "s/DATABASE_PASSWORD=.*/DATABASE_PASSWORD=$DATABASE_PASSWORD/" .env
```

### 2. 构建和启动容器

```bash
# 构建 Docker 映像
docker compose build

# 以分离模式启动容器
docker compose up -d
```

### 3. 首次设置

首次启动后，访问 `http://服务器IP:1337/admin` 创建管理员账户并进行初始配置。

### 4. 维护命令

```bash
# 查看容器日志
docker compose logs -f strapi

# 重启服务
docker compose restart strapi

# 停止所有服务
docker compose down

# 停止并删除所有数据（谨慎使用！）
docker compose down -v
```

### 5. 数据备份

定期备份 PostgreSQL 数据和上传的文件：

```bash
# 备份数据库
docker exec glass-enterprise-postgres pg_dump -U strapi -d strapi > backup_$(date +%Y-%m-%d).sql

# 备份上传的文件
tar -czvf uploads_backup_$(date +%Y-%m-%d).tar.gz ./public/uploads
```

### 6. 更新应用

当需要更新应用时，请按照以下步骤操作：

```bash
# 拉取最新代码
git pull

# 重新构建并启动容器
docker compose build
docker compose up -d
```

## 配置 Nginx 反向代理（推荐）

为了更好的性能和安全性，建议使用 Nginx 作为反向代理。以下是一个基本的 Nginx 配置示例：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:1337;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

配置 HTTPS（推荐）：
```bash
# 安装 Certbot
apt-get update
apt-get install certbot python3-certbot-nginx

# 获取并配置 SSL 证书
certbot --nginx -d your-domain.com
```

## 故障排除

1. 如果容器无法启动，检查日志：
```bash
docker compose logs strapi
```

2. 数据库连接问题：
   - 确保环境变量正确设置
   - 检查网络连接：`docker compose exec strapi ping postgres`

3. 权限问题：
   - 确保 `public/uploads` 目录具有正确的权限
   ```bash
   chmod -R 755 public/uploads
   ```

## 性能优化

1. 增加 Strapi 和数据库的资源限制（在 docker-compose.yml 中）：

```yaml
strapi:
  # ...其他配置
  deploy:
    resources:
      limits:
        cpus: '1'
        memory: 1G

postgres:
  # ...其他配置
  deploy:
    resources:
      limits:
        cpus: '1'
        memory: 1G
```

2. 启用 PostgreSQL 缓存配置（需要修改 postgres 服务配置）。

如需更多帮助，请参考 [Strapi 官方文档](https://docs.strapi.io/)。