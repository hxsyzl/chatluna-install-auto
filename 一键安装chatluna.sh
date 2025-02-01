#!/bin/bash

# 检查是否安装了 Node.js
if ! command -v node &> /dev/null; then
    echo "Node.js 未安装，正在安装..."
    
    # 导入 NodeSource 官方库并安装最新的 Node.js 版本
    curl -fsSL https://deb.nodesource.com/setup_current.x | sudo -E bash -
    sudo apt update
    sudo apt install -y nodejs
fi

# 确保 Node.js 已安装
command -v node >/dev/null 2>&1 || { echo >&2 "Node.js 安装失败。"; exit 1; }

# 配置 npm 镜像
echo "正在配置 npm 镜像为 https://registry.npmmirror.com..."
npm config set registry https://registry.npmmirror.com

# 检测当前运行脚本的用户
current_user=$(whoami)
desktop_path=""

if [ "$current_user" == "root" ]; then
    desktop_path="/root/Desktop"
else
    desktop_path="$HOME/Desktop"
fi

mkdir -p "$desktop_path"
cd "$desktop_path"

echo "在 $desktop_path 目录下运行 npm init koishi@latest..."
npm init koishi@latest

# 等待五秒
echo "等待五秒..."
sleep 5

# 进入 koishi-app 目录
koishi_app_path="$desktop_path/koishi-app"
cd "$koishi_app_path"

# 安装 koishi-plugin-chatluna 和 koishi-plugin-chatluna-deepseek-adapter
echo "在 koishi-app 目录下安装 koishi-plugin-chatluna 和 koishi-plugin-chatluna-deepseek-adapter..."
npm install
npm install koishi-plugin-chatluna
npm install koishi-plugin-chatluna-deepseek-adapter

# 搜索并替换 koishi.yml 中的 URL
koishi_yml_path="$koishi_app_path/koishi.yml"
echo "正在搜索并替换 koishi.yml 中的 URL..."
sed -i 's|https://registry.koishi.chat/index.json|https://koi.nyan.zone/registry/index.json|g' "$koishi_yml_path"

# 安装 koishi-plugin-adapter-onebot
echo "在 koishi-app 目录下安装 koishi-plugin-adapter-onebot..."
npm install koishi-plugin-adapter-onebot

# 启动 Koishi 并启用 OneBot 和 ChatLuna 插件
echo "正在启动 Koishi"
npm run start 

echo "Node.js、npm 镜像配置、Koishi 初始化以及插件安装完成。Koishi 安装在 $desktop_path/koishi-app"
