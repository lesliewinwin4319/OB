# ---- Build Stage ----
FROM node:20-alpine AS builder

WORKDIR /app

# 安装依赖（利用 Docker 层缓存，package.json 不变时跳过 npm install）
COPY package*.json ./
RUN npm ci --only=production=false

COPY . .
RUN npm run build

# ---- Production Stage ----
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# 只复制生产依赖
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# 复制编译产物
COPY --from=builder /app/dist ./dist

EXPOSE 3000

# 启动：migrations 在 main.ts 中自动执行后再启动 HTTP 服务
CMD ["node", "dist/main"]
