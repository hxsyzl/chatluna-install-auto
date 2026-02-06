#!/bin/bash

# ============================================
# ChatLuna 一键安装脚本 (Linux/macOS 版本)
# ============================================

# 设置错误处理
set -e

# 颜色输出函数
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${CYAN}$1${NC}"
}

print_success() {
    echo -e "${GREEN}$1${NC}"
}

print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

print_error() {
    echo -e "${RED}$1${NC}"
}

# 配置常量
NODE_VERSION="22.x"
NPM_MIRROR="https://registry.npmmirror.com"
KOISHI_REGISTRY="https://koi.nyan.zone/registry/index.json"
NAPCAT_INSTALL_URL="https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.sh"

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if [ -f /etc/debian_version ]; then
            DISTRO="debian"
        elif [ -f /etc/redhat-release ]; then
            DISTRO="redhat"
        elif [ -f /etc/arch-release ]; then
            DISTRO="arch"
        else
            DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    else
        print_error "不支持的操作系统: $OSTYPE"
        exit 1
    fi
}

# 检查命令是否存在
command_exists() {
    command -v "$1" &> /dev/null
}

# ============================================
# 步骤 1: 检查并安装 Node.js
# ============================================
print_info "\n=== 步骤 1/7: 检查 Node.js ==="

detect_os

if command_exists node; then
    NODE_VER=$(node --version)
    print_success "Node.js 已安装: $NODE_VER"
else
    print_warning "Node.js 未安装，正在安装..."
    
    case $DISTRO in
        debian)
            print_info "使用 NodeSource 安装 Node.js $NODE_VERSION..."
            curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | sudo -E bash -
            sudo apt update
            sudo apt install -y nodejs
            ;;
        redhat)
            print_info "使用 NodeSource 安装 Node.js $NODE_VERSION..."
            curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION} | sudo bash -
            sudo yum install -y nodejs
            ;;
        arch)
            print_info "使用 pacman 安装 Node.js..."
            sudo pacman -S --noconfirm nodejs npm
            ;;
        macos)
            if command_exists brew; then
                print_info "使用 Homebrew 安装 Node.js..."
                brew install node
            else
                print_error "请先安装 Homebrew: https://brew.sh/"
                exit 1
            fi
            ;;
        *)
            print_error "不支持的发行版，请手动安装 Node.js"
            exit 1
            ;;
    esac
    
    # 验证安装
    if command_exists node; then
        print_success "Node.js 安装完成: $(node --version)"
    else
        print_error "Node.js 安装失败"
        exit 1
    fi
fi

# ============================================
# 步骤 2: 配置 npm 镜像
# ============================================
print_info "\n=== 步骤 2/7: 配置 npm 镜像 ==="

if ! command_exists npm; then
    print_error "npm 命令不可用，请检查 Node.js 安装"
    exit 1
fi

print_info "正在配置 npm 镜像为 $NPM_MIRROR..."
npm config set registry "$NPM_MIRROR"
print_success "npm 镜像配置完成"

# ============================================
# 步骤 3: 初始化 Koishi
# ============================================
print_info "\n=== 步骤 3/7: 初始化 Koishi ==="

# 获取桌面路径
if [ "$OS" == "macos" ]; then
    desktop_path="$HOME/Desktop"
else
    if [ "$EUID" -eq 0 ]; then
        desktop_path="/root/Desktop"
    else
        desktop_path="$HOME/Desktop"
    fi
fi

# 创建桌面目录
mkdir -p "$desktop_path"
cd "$desktop_path"

print_info "正在运行 npm init koishi@latest..."
npm init koishi@latest --yes

# 等待初始化完成
sleep 3

koishi_app_path="$desktop_path/koishi-app"

if [ ! -d "$koishi_app_path" ]; then
    print_error "koishi-app 目录未创建，初始化可能失败"
    exit 1
fi

print_success "Koishi 初始化完成"

# ============================================
# 步骤 4: 创建启动脚本
# ============================================
print_info "\n=== 步骤 4/7: 创建启动脚本 ==="

cd "$koishi_app_path"

cat > koishi.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
echo "正在启动 Koishi..."
npm run start
EOF

chmod +x koishi.sh
print_success "已创建 koishi.sh 启动脚本"

# ============================================
# 步骤 5: 安装 ChatLuna 插件
# ============================================
print_info "\n=== 步骤 5/7: 安装 ChatLuna 插件 ==="

print_info "正在安装依赖..."
npm install --silent

print_info "正在安装 koishi-plugin-chatluna..."
npm install koishi-plugin-chatluna --silent

print_success "ChatLuna 插件安装完成"

# ============================================
# 步骤 6: 配置 Koishi 注册表
# ============================================
print_info "\n=== 步骤 6/7: 配置 Koishi 注册表 ==="

koishi_yml_path="$koishi_app_path/koishi.yml"

if [ -f "$koishi_yml_path" ]; then
    if sed -i.bak "s|https://registry\.koishi\.chat/index\.json|$KOISHI_REGISTRY|g" "$koishi_yml_path" 2>/dev/null; then
        print_success "Koishi 注册表已更新"
        rm -f "${koishi_yml_path}.bak"
    else
        print_warning "无法更新 koishi.yml"
    fi
else
    print_warning "koishi.yml 文件不存在"
fi

# ============================================
# 步骤 7: 安装 OneBot 适配器
# ============================================
print_info "\n=== 步骤 7/7: 安装 OneBot 适配器 ==="

print_info "正在安装 koishi-plugin-adapter-onebot..."
npm install koishi-plugin-adapter-onebot --silent
print_success "OneBot 适配器安装完成"

# ============================================
# 安装完成
# ============================================
print_info "\n========================================"
print_success "Koishi 安装完成！"
print_info "安装路径: $koishi_app_path"
print_info "========================================\n"

# 询问是否启动 Koishi
read -p "是否立即启动 Koishi? (Y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "正在启动 Koishi..."
    cd "$koishi_app_path"
    ./koishi.sh
fi

# ============================================
# NapCat 安装选项
# ============================================
print_info "\n========================================"
print_info "是否安装 NapCat (QQ 机器人适配器)?"
print_info "1. 是 - 安装 NapCat"
print_info "2. 否 - 跳过 NapCat 安装"
print_info "========================================\n"

read -p "请输入选项 (1 或 2): " choice

case $choice in
    1)
        print_info "\n正在下载 NapCat 安装脚本..."
        cd "$desktop_path"
        if curl -fsSL -o napcat-install.sh "$NAPCAT_INSTALL_URL"; then
            chmod +x napcat-install.sh
            print_success "NapCat 安装脚本已下载到: $desktop_path/napcat-install.sh"
            print_info "请手动运行以下命令安装 NapCat:"
            print_info "sudo bash $desktop_path/napcat-install.sh --tui"
            
            read -p "是否立即运行 NapCat 安装脚本? (Y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_info "正在运行 NapCat 安装脚本..."
                sudo bash napcat-install.sh --tui
            fi
        else
            print_error "NapCat 安装脚本下载失败"
        fi
        ;;
    2)
        print_warning "已跳过 NapCat 安装"
        ;;
    *)
        print_warning "无效的选项，已跳过 NapCat 安装"
        ;;
esac

print_info "\n========================================"
print_success "安装流程全部完成！"
print_info "Koishi 启动脚本: $koishi_app_path/koishi.sh"
print_info "========================================\n"
