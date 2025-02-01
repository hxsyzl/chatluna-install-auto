# 检查是否安装了 winget
$winget = Get-Command winget -ErrorAction SilentlyContinue

if (-not $winget) {
    Write-Output "winget 未安装，正在安装 Microsoft.DesktopAppInstaller..."
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
}

# 确保 winget 已安装
$winget = Get-Command winget -ErrorAction Stop

# 使用 winget 安装 Node.js 的最新版本
Write-Output "正在使用 winget 安装 Node.js 的最新版本..."
winget install --id OpenJS.NodeJS --latest

# 配置 npm 镜像
Write-Output "正在配置 npm 镜像为 https://registry.npmmirror.com..."
npm config set registry https://registry.npmmirror.com

# 在系统桌面运行 npm init koishi@latest
$desktopPath = [System.Environment]::GetFolderPath('Desktop')
Set-Location -Path $desktopPath
Write-Output "在系统桌面运行 npm init koishi@latest..."
npm init koishi@latest

# 进入 koishi-app 目录
$koishiAppPath = Join-Path -Path $desktopPath -ChildPath "koishi-app"
Set-Location -Path $koishiAppPath

# 安装 koishi-plugin-chatluna 和 koishi-plugin-chatluna-deepseek-adapter
Write-Output "在 koishi-app 目录下安装 koishi-plugin-chatluna 和 koishi-plugin-chatluna-deepseek-adapter..."
npm install
npm install koishi-plugin-chatluna
npm install koishi-plugin-chatluna-deepseek-adapter

# 搜索并替换 koishi.yml 中的 URL
$koishiYmlPath = Join-Path -Path $koishiAppPath -ChildPath "koishi.yml"
Write-Output "正在搜索并替换 koishi.yml 中的 URL..."
(Get-Content -Path $koishiYmlPath) -replace 'https://registry.koishi.chat/index.json', 'https://koi.nyan.zone/registry/index.json' | Set-Content -Path $koishiYmlPath

# 安装 koishi-plugin-adapter-onebot
Write-Output "在 koishi-app 目录下安装 koishi-plugin-adapter-onebot..."
npm install koishi-plugin-adapter-onebot

# 启动 Koishi 并启用 OneBot 和 ChatLuna 插件
Write-Output "正在启动 Koishi"
Start-Process -FilePath "$koishiAppPath\koishi.bat"

Write-Output "Node.js、npm 镜像配置、Koishi 初始化以及插件安装完成,Koishi 安装在 $desktop_path/koishi-app"
