# Windows 开发环境一键初始化指南

本文档说明如何使用仓库根目录下的 `bootstrap-windows.ps1` 一键安装 Windows 开发环境，并完成 Cursor 初始化。

## 适用范围

- Windows 10 / Windows 11
- 需要安装：Java 17、Node.js LTS、Cursor
- 适用于当前仓库的前后端开发环境准备

## 总入口

请在仓库根目录执行：

```powershell
.\bootstrap-windows.ps1
```

如果你不想在安装完成后自动打开 Cursor，可以执行：

```powershell
.\bootstrap-windows.ps1 -NoAutoStart
```

## 执行内容

该脚本会按顺序完成以下工作：

1. 检查当前仓库路径
2. 检查 `frontend/` 和 `backend/` 是否存在
3. 安装 Chocolatey（如果未安装）
4. 安装 Java 17（Temurin）
5. 安装 Node.js LTS
6. 安装 Cursor
7. 生成 Cursor 基础配置
8. 默认打开 Cursor 并定位到当前仓库

## 前置条件

- 需要管理员权限或允许安装软件的终端权限
- 机器需要可访问外网，以便下载安装包和 Chocolatey
- 如果仓库使用子模块，建议先确保 `frontend/` 与 `backend/` 已初始化

## 安装后如何验证

执行完成后，可以手动确认：

```powershell
java -version
node -v
```

同时检查：

- Cursor 已安装
- Cursor 已打开并定位到仓库目录
- `.cursor/user/settings.json` 已生成

## 常见问题

### 1. 提示找不到 `frontend/` 或 `backend/`

说明子模块可能还没有初始化，请先完成子模块拉取，再执行安装脚本。

### 2. Chocolatey 安装失败

通常是网络、代理或权限问题。建议确认：

- 终端是否有管理员权限
- 外网是否可访问
- 公司网络是否拦截了下载地址

### 3. 安装完成后命令不可用

某些软件安装后可能需要重新打开终端，才能在 PATH 中识别到新命令。

## 推荐使用方式

- 首次配置一台新的 Windows 电脑：直接运行 `bootstrap-windows.ps1`
- 已经安装过部分组件：仍然可以运行，总入口会自动跳过已安装项

## 脚本位置

- 总入口：`bootstrap-windows.ps1`
- 内部安装逻辑：`scripts/windows/install-dev-env.ps1`
- Cursor 初始化：`scripts/init-cursor.ps1`
