# Figma MCP 初始化指南

首次使用 Figma MCP 时，按以下步骤完成初始化。

---

## 前置条件

- Claude Code 已安装
- Figma 桌面版（免费即可）
- Node.js 和 npx 可用

---

## 步骤 1：写入 MCP 配置

将以下内容写入 `.claude/mcp.json`（项目级配置），或执行命令自动添加：

```bash
# 添加 figma-mcp-go（本地，73 个读写工具）
claude mcp add -s project figma-mcp-go -- npx -y @vkhanhqui/figma-mcp-go@latest

# 添加官方 Figma MCP（云端，Code to Canvas）
claude mcp add --transport http figma-official https://mcp.figma.com/mcp
```

完成后 `.claude/mcp.json` 应包含：

```json
{
  "mcpServers": {
    "figma-mcp-go": {
      "command": "npx",
      "args": ["-y", "@vkhanhqui/figma-mcp-go@latest"]
    },
    "figma-official": {
      "type": "http",
      "url": "https://mcp.figma.com/mcp"
    }
  }
}
```

**注意**：修改配置后需要**退出并重启 Claude Code 会话**才能生效。

---

## 步骤 2：安装 figma-mcp-go 插件（必做）

figma-mcp-go 需要 Figma 桌面端插件桥才能工作。

### 2.1 下载插件

```bash
gh release download --repo vkhanhqui/figma-mcp-go v0.1.3 --pattern "*.zip" --dir ~/Desktop/figma-plugin
```

如果 `gh` 不可用，从 [GitHub Releases](https://github.com/vkhanhqui/figma-mcp-go/releases) 手动下载 `plugin.zip`。

### 2.2 导入到 Figma

1. 解压 `plugin.zip`
2. 打开 **Figma 桌面版**
3. **Plugins → Development → Import plugin from manifest...**
4. 选择解压出来的 `manifest.json`
5. 插件出现在 Plugins 菜单中

---

## 步骤 3：授权官方 MCP（首次需要）

官方 MCP 需要一次 OAuth 授权：

1. Claude 会提示一个浏览器链接，打开它
2. 在 Figma 授权页面点击**允许**
3. 浏览器跳转到 `http://localhost:.../callback?code=...`
4. 如果显示连接错误，从**地址栏复制完整 URL** 粘贴给 Claude

授权完成后，官方 MCP 的写工具（Code to Canvas）即可使用。

---

## 步骤 4：使用验证

在 Claude 中执行以下任一操作验证安装成功：

```bash
# 验证 figma-mcp-go 连接
get_metadata()

# 验证官方 MCP 连接
whoami()
```

---

## 使用方式

### 方式 A：本地读写（figma-mcp-go）

1. 打开要操作的 Figma 文件
2. **Plugins → figma-mcp-go → Run**（每次操作不同文件都需要运行一次）
3. 告诉 Claude 要对哪个节点做什么操作

### 方式 B：HTML 导入（官方 MCP Code to Canvas）

1. 准备好 HTML 文件（含 `capture.js` 脚本）
2. 启动本地 HTTP 服务：`python3 -m http.server 8899`
3. 告诉 Claude：`把这个 HTML 导入 Figma，文件名 xxx`
4. Claude 会完成 captureId 生成 → 浏览器打开 → 轮询完成

### 方式 C：双工具协作（推荐）

```
Code to Canvas 生成图层 → figma-mcp-go 绑定 Token → 精修
```

详见 `docs/dev/figma-mcp-workflow.md`。

---

## 常见问题

| 问题 | 解决 |
|------|------|
| figma-mcp-go 卡在旧文件 | 在新文件中重新 Run 插件 |
| 官方 MCP 说读工具次数用完 | 免费版每月 6 次。写工具（generate_figma_design）不限 |
| Code to Canvas 没有反应 | 确认 HTML 中注入了 `capture.js`，且用 HTTP 服务而非 file:// |
| 渐变填充无法绑定变量 | 先用 `set_fills` 改为纯色再绑定 |

---

## 相关文档

| 文档 | 内容 |
|------|------|
| `docs/dev/figma-mcp-workflow.md` | 双 MCP 协作开发规范 |
| `docs/dev/figma-prototype-experience.md` | 开发经验总结 |
| `scripts/sync-tokens-to-figma.mjs` | Token 同步脚本用法 |
