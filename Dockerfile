# ============================================
# ChatLuna Docker 镜像
# 基于 Koishi 官方镜像构建
# ============================================

FROM node:22-alpine

# 设置工作目录
WORKDIR /koishi

# 安装依赖
RUN apk add --no-cache git curl

# 配置 npm 镜像
RUN npm config set registry https://registry.npmmirror.com

# 初始化 Koishi
RUN npm init koishi@latest --yes

# 进入 koishi-app 目录
WORKDIR /koishi/koishi-app

# 安装 ChatLuna 插件
RUN npm install --silent && \
    npm install koishi-plugin-chatluna --silent && \
    npm install koishi-plugin-adapter-onebot --silent

# 配置 Koishi 注册表镜像
RUN sed -i 's|https://registry\.koishi\.chat/index\.json|https://koi.nyan.zone/registry/index.json|g' koishi.yml

# 创建数据目录
RUN mkdir -p /koishi/data

# 暴露端口
EXPOSE 5140

# 设置环境变量
ENV KOISHI_PORT=5140
ENV NODE_ENV=production

# 启动命令
CMD ["npm", "run", "start"]
