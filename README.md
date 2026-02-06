# chatluna-install-auto

自动安装**koishi及chatluna**

原始项目地址：[GitHub - ChatLunaLab/chatluna: 多平台模型接入，可扩展，多种输出格式，提供大语言模型聊天服务的插件 | A bot plugin for LLM chat services with multi-model integration, extensibility, and various output formats](https://github.com/ChatLunaLab/chatluna)

koishi地址：[GitHub - koishijs/koishi: Cross-platform chatbot framework made with love](https://github.com/koishijs/koishi)

Napcat地址：[GitHub - NapNeko/NapCatQQ: 现代化的基于 NTQQ 的 Bot 协议端实现](https://github.com/NapNeko/NapCatQQ)

## 安装方式

### Windows 使用教程

1. 右键 `一键安装chatluna.ps1` 文件
2. 选择 **使用 PowerShell 打开**
3. 按照提示完成安装

### Linux/macOS 使用教程

1. 打开终端
2. 进入存放 `一键安装chatluna.sh` 的文件夹
3. 输入 `chmod +x 一键安装chatluna.sh`
4. 输入 `./一键安装chatluna.sh`
5. 按照提示完成安装

### Docker 部署 （未经测试）

你都使用docker了 你应该会自己解决的吧（

使用 Docker 可以快速部署 ChatLuna，无需手动安装 Node.js 和依赖。

#### 快速开始

```bash
# 仅启动 Koishi
docker-compose up -d

# 启动 Koishi 和 NapCat
docker-compose --profile napcat up -d
```

#### 访问服务

- Koishi 控制台: http://localhost:5140
- NapCat 控制台: http://localhost:3000

#### 详细文档

请查看 [DOCKER.md](DOCKER.md) 获取完整的 Docker 部署指南。

## 功能特性

- ✅ 自动安装 Node.js
- ✅ 自动配置 npm 镜像
- ✅ 自动初始化 Koishi
- ✅ 自动安装 ChatLuna 插件
- ✅ 自动安装 OneBot 适配器
- ✅ 可选安装 NapCat
- ✅ Docker 支持
- ✅ 多发行版支持（Debian/RedHat/Arch/macOS）

## 注意事项

- Windows 脚本需要管理员权限运行
- Linux/macOS 脚本需要 sudo 权限（用于安装 Node.js）
- 安装完成后，Koishi 会安装在桌面目录下的 `koishi-app` 文件夹中
- Docker 部署需要预先安装 Docker 和 Docker Compose
