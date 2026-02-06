# ============================================
# ChatLuna 一键安装脚本 (PowerShell 版本)
# ============================================

# 设置错误处理
$ErrorActionPreference = "Stop"

# 请求管理员权限
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Host "正在请求管理员权限..." -ForegroundColor Yellow
    Start-Process powershell "-Verb RunAs -ArgumentList `"-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"`""
    exit
}

# 配置常量
$NODE_VERSION = "v22.13.1"
$NPM_MIRROR = "https://registry.npmmirror.com"
$KOISHI_REGISTRY = "https://koi.nyan.zone/registry/index.json"
$NAPCAT_INSTALL_URL = "https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.ps1"

# 获取系统路径
$nodeExePath = "$env:ProgramFiles\nodejs\node.exe"
$desktopPath = [System.Environment]::GetFolderPath('Desktop')
$koishiAppPath = Join-Path -Path $desktopPath -ChildPath "koishi-app"

# 函数：显示带颜色的消息
function Write-ColorMessage {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# 函数：检查命令是否存在
function Test-Command {
    param([string]$Command)
    try {
        $null = Get-Command $Command -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# ============================================
# 步骤 1: 安装/检查 Node.js
# ============================================
Write-ColorMessage "`n=== 步骤 1/7: 检查 Node.js ===" "Cyan"

if (Test-Path $nodeExePath) {
    $installedVersion = & $nodeExePath --version
    Write-ColorMessage "Node.js 已安装: $installedVersion" "Green"
} else {
    Write-ColorMessage "正在下载 Node.js $NODE_VERSION ..." "Yellow"
    $DOWNLOAD_URL = "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-x64.msi"
    $msiPath = "$env:TEMP\node-$NODE_VERSION-x64.msi"
    
    try {
        # 使用 ProgressPreference 提高下载速度
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $msiPath -UseBasicParsing
        $ProgressPreference = 'Continue'
        
        if (-Not (Test-Path $msiPath)) {
            throw "下载失败，请检查网络连接"
        }
        
        Write-ColorMessage "正在安装 Node.js..." "Yellow"
        $installResult = Start-Process msiexec -ArgumentList "/i `"$msiPath`" /qn ADDLOCAL=NodeRuntime,npm,NpmAndNodePathFeature" -Wait -PassThru
        
        # 等待安装完成
        Start-Sleep -Seconds 15
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
        
        if (-Not (Test-Path $nodeExePath)) {
            throw "安装失败，node.exe 未找到"
        }
        
        Write-ColorMessage "Node.js 安装完成！" "Green"
    } catch {
        Write-ColorMessage "错误: $_" "Red"
        Remove-Item $msiPath -ErrorAction SilentlyContinue
        Read-Host "按回车键退出"
        exit 1
    } finally {
        Remove-Item $msiPath -ErrorAction SilentlyContinue
    }
}

# ============================================
# 步骤 2: 验证 npm 并配置镜像
# ============================================
Write-ColorMessage "`n=== 步骤 2/7: 配置 npm 镜像 ===" "Cyan"

# 刷新环境变量以确保 npm 可用
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

if (-Not (Test-Command "npm")) {
    Write-ColorMessage "错误: npm 命令不可用，请检查 Node.js 安装" "Red"
    Read-Host "按回车键退出"
    exit 1
}

try {
    Write-ColorMessage "正在配置 npm 镜像为 $NPM_MIRROR ..." "Yellow"
    npm config set registry $NPM_MIRROR
    Write-ColorMessage "npm 镜像配置完成" "Green"
} catch {
    Write-ColorMessage "错误: 无法配置 npm 镜像 - $_" "Red"
    Read-Host "按回车键退出"
    exit 1
}

# ============================================
# 步骤 3: 初始化 Koishi
# ============================================
Write-ColorMessage "`n=== 步骤 3/7: 初始化 Koishi ===" "Cyan"

if (-Not (Test-Path $desktopPath)) {
    Write-ColorMessage "警告: 桌面路径不存在，将创建目录" "Yellow"
    New-Item -ItemType Directory -Path $desktopPath -Force | Out-Null
}

Set-Location -Path $desktopPath

try {
    Write-ColorMessage "正在运行 npm init koishi@latest ..." "Yellow"
    npm init koishi@latest --yes
    
    if (-Not (Test-Path $koishiAppPath)) {
        throw "koishi-app 目录未创建，初始化可能失败"
    }
    
    Write-ColorMessage "Koishi 初始化完成" "Green"
} catch {
    Write-ColorMessage "错误: 无法初始化 Koishi - $_" "Red"
    Read-Host "按回车键退出"
    exit 1
}

# ============================================
# 步骤 4: 创建启动脚本
# ============================================
Write-ColorMessage "`n=== 步骤 4/7: 创建启动脚本 ===" "Cyan"

Set-Location -Path $koishiAppPath

$koishiBatContent = @"
@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 正在启动 Koishi...
npm run start
pause
"@

$koishiBatPath = Join-Path -Path $koishiAppPath -ChildPath "koishi.bat"
Set-Content -Path $koishiBatPath -Value $koishiBatContent -Encoding UTF8
Write-ColorMessage "已创建 koishi.bat 启动脚本" "Green"

# ============================================
# 步骤 5: 安装 ChatLuna 插件
# ============================================
Write-ColorMessage "`n=== 步骤 5/7: 安装 ChatLuna 插件 ===" "Cyan"

try {
    Write-ColorMessage "正在安装依赖..." "Yellow"
    npm install --silent
    
    Write-ColorMessage "正在安装 koishi-plugin-chatluna..." "Yellow"
    npm install koishi-plugin-chatluna --silent
    
    Write-ColorMessage "ChatLuna 插件安装完成" "Green"
} catch {
    Write-ColorMessage "错误: 无法安装插件 - $_" "Red"
    Read-Host "按回车键退出"
    exit 1
}

# ============================================
# 步骤 6: 配置 Koishi 注册表
# ============================================
Write-ColorMessage "`n=== 步骤 6/7: 配置 Koishi 注册表 ===" "Cyan"

$koishiYmlPath = Join-Path -Path $koishiAppPath -ChildPath "koishi.yml"

if (Test-Path $koishiYmlPath) {
    try {
        $content = Get-Content -Path $koishiYmlPath -Raw -Encoding UTF8
        $newContent = $content -replace 'https://registry\.koishi\.chat/index\.json', $KOISHI_REGISTRY
        Set-Content -Path $koishiYmlPath -Value $newContent -Encoding UTF8
        Write-ColorMessage "Koishi 注册表已更新" "Green"
    } catch {
        Write-ColorMessage "警告: 无法更新 koishi.yml - $_" "Yellow"
    }
} else {
    Write-ColorMessage "警告: koishi.yml 文件不存在" "Yellow"
}

# ============================================
# 步骤 7: 安装 OneBot 适配器
# ============================================
Write-ColorMessage "`n=== 步骤 7/7: 安装 OneBot 适配器 ===" "Cyan"

try {
    Write-ColorMessage "正在安装 koishi-plugin-adapter-onebot..." "Yellow"
    npm install koishi-plugin-adapter-onebot --silent
    Write-ColorMessage "OneBot 适配器安装完成" "Green"
} catch {
    Write-ColorMessage "错误: 无法安装 OneBot 适配器 - $_" "Red"
    Read-Host "按回车键退出"
    exit 1
}

# ============================================
# 安装完成
# ============================================
Write-ColorMessage "`n========================================" "Cyan"
Write-ColorMessage "Koishi 安装完成！" "Green"
Write-ColorMessage "安装路径: $koishiAppPath" "Cyan"
Write-ColorMessage "========================================`n" "Cyan"

# 询问是否启动 Koishi
$startKoishi = Read-Host "是否立即启动 Koishi? (Y/N)"
if ($startKoishi -eq "Y" -or $startKoishi -eq "y") {
    Write-ColorMessage "正在启动 Koishi..." "Yellow"
    try {
        Start-Process -FilePath $koishiBatPath
        Write-ColorMessage "Koishi 已启动" "Green"
    } catch {
        Write-ColorMessage "错误: 无法启动 Koishi - $_" "Red"
    }
}

# ============================================
# NapCat 安装选项
# ============================================
Write-ColorMessage "`n========================================" "Cyan"
Write-ColorMessage "是否安装 NapCat (QQ 机器人适配器)?" "Cyan"
Write-ColorMessage "1. 是 - 安装 NapCat" "White"
Write-ColorMessage "2. 否 - 跳过 NapCat 安装" "White"
Write-ColorMessage "========================================`n" "Cyan"

$choice = Read-Host "请输入选项 (1 或 2)"

switch ($choice) {
    "1" {
        Write-ColorMessage "`n正在下载 NapCat 安装脚本..." "Yellow"
        try {
            $installScriptPath = Join-Path -Path $desktopPath -ChildPath "napcat-install.ps1"
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -Uri $NAPCAT_INSTALL_URL -OutFile $installScriptPath -UseBasicParsing
            $ProgressPreference = 'Continue'
            
            if (Test-Path $installScriptPath) {
                Write-ColorMessage "NapCat 安装脚本已下载到: $installScriptPath" "Green"
                Write-ColorMessage "请手动运行以下命令安装 NapCat:" "Yellow"
                Write-ColorMessage "powershell -ExecutionPolicy Bypass -File `"$installScriptPath`"" "Cyan"
                
                $runNow = Read-Host "是否立即运行 NapCat 安装脚本? (Y/N)"
                if ($runNow -eq "Y" -or $runNow -eq "y") {
                    Write-ColorMessage "正在运行 NapCat 安装脚本..." "Yellow"
                    Start-Process powershell -ArgumentList "-ExecutionPolicy Bypass -File `"$installScriptPath`"" -Verb RunAs
                }
            } else {
                Write-ColorMessage "错误: NapCat 安装脚本下载失败" "Red"
            }
        } catch {
            Write-ColorMessage "错误: 下载 NapCat 安装脚本失败 - $_" "Red"
        }
    }
    "2" {
        Write-ColorMessage "已跳过 NapCat 安装" "Yellow"
    }
    default {
        Write-ColorMessage "无效的选项，已跳过 NapCat 安装" "Yellow"
    }
}

Write-ColorMessage "`n========================================" "Cyan"
Write-ColorMessage "安装流程全部完成！" "Green"
Write-ColorMessage "Koishi 启动脚本: $koishiBatPath" "Cyan"
Write-ColorMessage "========================================`n" "Cyan"

Read-Host "按回车键退出"
