# 请求管理员权限
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Start-Process powershell "-Verb RunAs -ArgumentList `"$PSCommandPath`""
    exit
}

# 设置变量
$NODE_VERSION = "v22.13.1"
$nodeExePath = "$env:ProgramFiles\nodejs\node.exe"

# 检查 Node.js 是否已安装
if (Test-Path $nodeExePath) {
    Write-Host "Node.js $NODE_VERSION 已安装，跳过下载和安装步骤。"
} else {
    Write-Host "正在下载 Node.js $NODE_VERSION ..."
    $DOWNLOAD_URL = "https://nodejs.org/dist/$NODE_VERSION/node-$NODE_VERSION-x64.msi"
    Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile "$env:TEMP\node-$NODE_VERSION-x64.msi"

    if (-Not (Test-Path "$env:TEMP\node-$NODE_VERSION-x64.msi")) {
        Write-Host "下载失败，请检查网络连接"
        pause
        exit
    }

    Write-Host "正在安装 Node.js..."
    Start-Process msiexec -ArgumentList "/i `"$env:TEMP\node-$NODE_VERSION-x64.msi`" /qn ADDLOCAL=NodeRuntime,npm,NpmAndNodePathFeature" -Wait
    Start-Sleep -Seconds 15

    if (-Not (Test-Path "$env:ProgramFiles\nodejs\node.exe")) {
        Write-Host "安装失败，node.exe未找到,请手动安装"
        Remove-Item "$env:TEMP\node-$NODE_VERSION-x64.msi" -ErrorAction SilentlyContinue
        exit 1
    }

    Remove-Item "$env:TEMP\node-$NODE_VERSION-x64.msi" -ErrorAction SilentlyContinue
    Write-Host "安装完成！正在验证安装..."
}

# 强制刷新环境变量
[Environment]::SetEnvironmentVariable("PATH", [Environment]::GetEnvironmentVariable("PATH", "Machine"), "Process")

# 配置 npm 镜像
Write-Output "正在配置 npm 镜像为 https://registry.npmmirror.com..."
try {
    npm config set registry https://registry.npmmirror.com
} catch {
    Write-Error "无法配置 npm 镜像: $_"
    exit
}

# 在系统桌面运行 npm init koishi@latest
$desktopPath = [System.Environment]::GetFolderPath('Desktop')
Set-Location -Path $desktopPath
Write-Output "在系统桌面运行 npm init koishi@latest..."
try {
    npm init koishi@latest
} catch {
    Write-Error "无法初始化 Koishi: $_"
    exit
}

# 进入 koishi-app 目录
$koishiAppPath = Join-Path -Path $desktopPath -ChildPath "koishi-app"
Set-Location -Path $koishiAppPath

# 创建 koishi.bat 文件
$koishiBatContent = @"
@echo off
cd %cd%
npm run start
"@
$koishiBatPath = Join-Path -Path $koishiAppPath -ChildPath "koishi.bat"
Set-Content -Path $koishiBatPath -Value $koishiBatContent
Write-Output "已创建 koishi.bat 文件"

# 安装 koishi-plugin-chatluna 和 koishi-plugin-chatluna-deepseek-adapter
Write-Output "在 koishi-app 目录下安装 koishi-plugin-chatluna 和 koishi-plugin-chatluna-deepseek-adapter..."
try {
    npm install
    npm install koishi-plugin-chatluna
    npm install koishi-plugin-chatluna-deepseek-adapter
} catch {
    Write-Error "无法安装插件: $_"
    exit
}

# 搜索并替换 koishi.yml 中的 URL
$koishiYmlPath = Join-Path -Path $koishiAppPath -ChildPath "koishi.yml"
Write-Output "正在搜索并替换 koishi.yml 中的 URL..."
try {
    (Get-Content -Path $koishiYmlPath) -replace 'https://registry.koishi.chat/index.json', 'https://koi.nyan.zone/registry/index.json' | Set-Content -Path $koishiYmlPath
} catch {
    Write-Error "无法更新 koishi.yml: $_"
    exit
}

# 安装 koishi-plugin-adapter-onebot
Write-Output "在 koishi-app 目录下安装 koishi-plugin-adapter-onebot..."
try {
    npm install koishi-plugin-adapter-onebot
} catch {
    Write-Error "无法安装 OneBot 适配器: $_"
    exit
}

# 启动 Koishi 并启用
Write-Output "正在启动 Koishi"
try {
    Start-Process -FilePath "$koishiAppPath\koishi.bat"
} catch {
    Write-Error "无法启动 Koishi: $_"
    exit
}

Write-Output "Node.js、npm 镜像配置、Koishi 初始化以及插件安装完成,Koishi 安装在 $desktopPath/koishi-app"

# 提示用户选择操作系统版本
Write-Output "请选择您的操作系统版本："
Write-Output "1. Win10"
Write-Output "2. Win11"
$choice = Read-Host "输入选项 (1 或 2) 然后按回车键"

switch ($choice) {
    1 {
        Write-Output "您选择了 Win10。正在执行相关操作..."
        more +3 "%~f0" >>generate.ps1; powershell -ExecutionPolicy ByPass -File ./generate.ps1 -verb runas; del ./generate.ps1; powershell -ExecutionPolicy ByPass -File ./install.ps1 -verb runas 
    }
    2 {
        Write-Output "您选择了 Win11。正在执行相关操作..."
        curl -o install.ps1 https://nclatest.znin.net/NapNeko/NapCat-Installer/main/script/install.ps1
        powershell -ExecutionPolicy ByPass -File ./install.ps1 -verb runas
    }
    default {
        Write-Output "无效的选项，请重新运行脚本并选择 1 或 2。"
        exit
    }
}
