FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 使用阿里云镜像源
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

# 安装全局依赖
RUN apk add --no-cache build-base gcc autoconf automake zlib-dev libpng-dev vips-dev python3 g++ make libtool

# 安装 bun (因为项目使用 bun.lock)
RUN npm install -g bun

# 复制 package.json, bun.lock 和 其他配置文件
COPY package.json bun.lock* ./
COPY tsconfig.json ./

# 安装依赖
RUN bun install

# 复制源代码
COPY . .

# 构建项目
RUN bun run build

# 暴露端口
EXPOSE 1337

# 设置环境变量
ENV NODE_ENV=production

# 启动命令
CMD ["bun", "run", "start"]