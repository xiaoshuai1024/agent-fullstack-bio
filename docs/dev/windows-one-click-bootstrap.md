# Windows 一键安装开发环境使用文档

## 入口

仓库根目录执行：

```powershell
.\bootstrap-windows.ps1
```

执行后会自动完成以下内容：

1. 安装 `Chocolatey`（如果本机尚未安装）
2. 安装 `Java 17`
3. 安装 `Node.js LTS`
4. 安装 `Cursor`
5. 写入 Cursor 基础配置
6. 默认启动 Cursor，并打开当前仓库目录

## 前置条件

- 需要 Windows 系统
- 需要具备联网能力
- 首次安装时建议使用管理员权限运行 PowerShell
- 如果公司网络有代理或访问限制，建议先配置网络环境

## 适用场景

- 新电脑首次初始化开发环境
- 需要快速安装前后端本地开发依赖
- 需要同时安装并打开 Cursor

## 脚本说明

### `bootstrap-windows.ps1`

这是唯一的总入口脚本。它会直接调用内部安装逻辑，不需要手动分别执行 Java、Node.js、Cursor 的安装步骤。

### 安装内容

- `Chocolatey`：Windows 包管理器
- `Java 17`：用于后端开发
- `Node.js LTS`：用于前端开发
- `Cursor`：用于代码编辑与协作

## 使用步骤

1. 打开 PowerShell
2. 进入仓库根目录
3. 执行：

```powershell
.\bootstrap-windows.ps1
```

4. 等待脚本完成
5. 如果脚本未自动打开 Cursor，可手动启动 Cursor 并打开仓库目录

## 结果检查

脚本执行完成后，建议确认以下内容：

- 输入 `java -version` 能看到 Java 版本
- 输入 `node -v` 能看到 Node.js 版本
- Cursor 已安装并可启动
- 仓库根目录下生成了 `.cursor/user/settings.json`

## 常见问题

### 1. 提示无法安装 Chocolatey

通常是网络不可达、权限不足或执行策略限制。建议：

- 以管理员身份运行 PowerShell
- 检查网络是否可访问 `https://community.chocolatey.org`
- 检查公司代理是否生效

### 2. 安装完成后命令未立即生效

有些软件安装后需要重新打开终端，或刷新环境变量后才能识别新命令。

### 3. Cursor 没有自动打开

脚本会尽量定位 `Cursor.exe` 并启动。如果没有找到，请手动检查安装结果，或直接从开始菜单启动 Cursor。

## 维护建议

如果后续要支持更多环境项，可以继续在 `scripts/windows/install-dev-env.ps1` 中扩展安装流程，但仍建议保留 `bootstrap-windows.ps1` 作为唯一入口。
