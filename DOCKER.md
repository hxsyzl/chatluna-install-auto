# ChatLuna Docker 部署指南

本文档介绍如何使用 Docker 部署 ChatLuna。

## 前置要求

- Docker 20.10+
- Docker Compose 2.0+

## 快速开始

### 1. 克隆项目

```bash
git clone <repository-url>
cd chatluna-install-auto
```

### 2. 构建并启动

```bash
# 仅启动 Koishi
docker-compose up -d

# 启动 Koishi 和 NapCat
docker-compose --profile napcat up -d
```

### 3. 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看特定服务日志
docker-compose logs -f koishi
docker-compose logs -f napcat
```

### 4. 访问服务

- Koishi 控制台: http://localhost:5140
- NapCat 控制台: http://localhost:3000

## 配置说明

### 环境变量

在 `docker-compose.yml` 中可以配置以下环境变量：

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `NODE_ENV` | `production` | Node.js 运行环境 |
| `KOISHI_PORT` | `5140` | Koishi 服务端口 |
| `TZ` | `Asia/Shanghai` | 时区设置 |

### 数据持久化

以下目录会被挂载到宿主机：

- `./data` - Koishi 数据目录
- `./napcat/config` - NapCat 配置目录
- `./napcat/data` - NapCat 数据目录

### 自定义配置

如果需要自定义 Koishi 配置，可以创建 `koishi.yml` 文件：

```bash
# 从容器中复制默认配置
docker-compose exec koishi cat /koishi/koishi-app/koishi.yml > koishi.yml

# 编辑配置文件
vim koishi.yml

# 重启服务使配置生效
docker-compose restart koishi
```

## 常用命令

### 服务管理

```bash
# 启动服务
docker-compose up -d

# 停止服务
docker-compose stop

# 重启服务
docker-compose restart

# 删除服务
docker-compose down

# 删除服务及数据卷
docker-compose down -v
```

### 构建镜像

```bash
# 重新构建镜像
docker-compose build

# 强制重新构建（不使用缓存）
docker-compose build --no-cache
```

### 进入容器

```bash
# 进入 Koishi 容器
docker-compose exec koishi sh

# 进入 NapCat 容器
docker-compose exec napcat sh
```

## 故障排查

### 查看容器状态

```bash
docker-compose ps
```

### 查看容器日志

```bash
docker-compose logs koishi
```

### 重新构建镜像

如果遇到问题，可以尝试重新构建镜像：

```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## 注意事项

1. **端口冲突**: 如果 5140 或 3000 端口已被占用，请修改 `docker-compose.yml` 中的端口映射
2. **数据备份**: 建议定期备份 `./data` 目录
3. **NapCat 配置**: NapCat 需要额外的 QQ 账号配置，请参考 NapCat 官方文档
4. **资源限制**: 根据服务器配置，可能需要调整 Docker 的资源限制

## 更新

```bash
# 拉取最新代码
git pull

# 重新构建并启动
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## 卸载

```bash
# 停止并删除服务
docker-compose down

# 删除数据卷（谨慎操作）
docker-compose down -v

# 删除镜像
docker rmi chatluna-install-auto-koishi
```

## 许可证

本项目遵循与主项目相同的许可证。
