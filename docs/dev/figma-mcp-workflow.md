# Figma MCP 双工具协作开发规范

本文档定义康豆全栈项目中使用 Figma 进行原型开发的标准工作流。

---

## 1. 工具角色分工

康豆项目同时使用两个 Figma MCP server，各有侧重：

| 工具 | 类型 | 核心能力 | 适用场景 |
|------|------|---------|---------|
| **figma-mcp-go** | 本地 | 73 个读写工具、变量绑定、Token 管理、截图导出 | 绑定设计 Token、精细修改、导出 |
| **官方 Figma MCP** | 云端 | Code to Canvas、get_design_context、设计读取 | HTML 组件生成、读取设计→生成代码 |

### 为什么需要两个

- **figma-mcp-go**：不能导入 SVG 图标，创建渐变填充等复杂样式困难
- **官方 MCP**：Code to Canvas 可以将 HTML（含 SVG / CSS 渐变）变成 Figma 可编辑图层
- **互补**：官方 MCP 负责"生成高品质图层"，figma-mcp-go 负责"绑定 Token + 精细操控"

---

## 2. 标准工作流

```
┌─────────────────────────────────────────────────────────────────┐
│  Phase 1: 设计生成（官方 MCP → Code to Canvas）                │
├─────────────────────────────────────────────────────────────────┤
│  ① Claude 根据需求写 HTML 组件（含 SVG 图标、CSS 渐变、阴影）   │
│  ② HTML 注入 capture.js 脚本                                   │
│  ③ 启动本地 HTTP server 提供服务                                │
│  ④ 浏览器打开 → capture.js 捕获页面结构                        │
│  ⑤ Figma 收到可编辑图层（矢量、文字、渐变均保留）               │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Phase 2: Token 绑定（figma-mcp-go）                            │
├─────────────────────────────────────────────────────────────────┤
│  ⑥ 在 Figma 中打开新文件 → 运行 figma-mcp-go 插件              │
│  ⑦ get_document / get_design_context → 读取图层结构            │
│  ⑧ create_variable_collection → 创建 kd-* 变量集合             │
│  ⑨ bind_variable_to_node → 绑定颜色/圆角/间距变量              │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Phase 3: 精修 + 组件化（人工）                                  │
├─────────────────────────────────────────────────────────────────┤
│  ⑩ 设计师在 Figma 中调整图层细节                                │
│  ⑪ 选中组件 → 右键 Create Component → 转为可复用组件           │
│  ⑫ 组件加入组件库面板                                          │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│  Phase 4: 开发还原（官方 MCP get_design_context）                │
├─────────────────────────────────────────────────────────────────┤
│  ⑬ get_design_context("组件名") → 读取布局、样式、Token 绑定    │
│  ⑭ get_screenshot → 视觉对照                                  │
│  ⑮ get_variable_defs → 确认 Token 值一致                       │
│  ⑯ Claude 生成 Vue 代码（结构 + Token 引用 + 交互）            │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Phase 1 详细操作手册

### 3.1 生成 HTML 组件规范

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=375, initial-scale=1.0">
<script src="https://mcp.figma.com/mcp/html-to-design/capture.js" async></script>
<!-- ↑ 必须加 capture.js 才能被 Code to Canvas 识别 ↑ -->
<style>
  /* 使用 kd-* CSS 变量值，确保 Token 一致 */
  .component { background: #00B341; }  /* kd-color-primary */
</style>
</head>
```

**规范：**
- 宽度 375px（小程序标准），可在 `<meta viewport>` 中锁定
- CSS 值直接使用 `variables.css` 中的 Token 值（而非 var()，因为 Figma 不解析 CSS 变量）
- SVG 图标直接内联到 HTML 中（Code to Canvas 会转成 Figma 矢量图层）

### 3.2 启动本地服务器

```bash
# 在项目根目录
python3 -m http.server 8899 --bind 127.0.0.1
# 或
npx http-server . -p 8899
```

### 3.3 Code to Canvas 导入

1. 调用 `generate_figma_design(url, outputMode, fileKey)`
2. 获取 `captureId`
3. `open "<url>#figmacapture=<captureId>&figmaendpoint=..."` 在浏览器打开
4. 等 5 秒 → 轮询 `generate_figma_design(captureId)` 直到 `completed`

### 3.4 多页面捕获

每个页面需要独立的 `captureId`。可以一次性生成多个 capture ID 并行捕获。

---

## 4. Phase 2 详细操作手册

### 4.1 准备工作

在 Figma 桌面版中：
1. 打开要操作的文件
2. **Plugins → figma-mcp-go → Run**
3. 确认 Claude 中 `get_metadata()` 返回正确的 `fileName`

### 4.2 变量创建顺序

```javascript
// 1. 创建集合
create_variable_collection("kd-color", "Green (默认)")
create_variable_collection("kd-radius", "默认")

// 2. 创建变量
create_variable("kd-color", "color/primary", COLOR, "#00B341")
create_variable("kd-radius", "radius/lg", FLOAT, 10)

// 3. 绑定到节点
bind_variable_to_node("1:3", cornerRadius, "radius/lg")
bind_variable_to_node("1:24", fillColor, "color/primary")
```

### 4.3 已知限制

- **只能绑定纯色填充**：渐变填充的节点无法绑定 COLOR 变量。需先 `set_fills` 改为纯色再绑定
- **变量文件隔离**：Figma 变量按文件隔离，跨文件需要重新创建
- **Token 同步**：CSS token 变更后，Figma 变量需要手动同步（可用 `scripts/sync-tokens-to-figma.mjs` 辅助）

---

## 5. 常见问题

### Q: Code to Canvas 导入的组件没有图标？
A: 图标必须在 HTML 中用 `<svg>` 内联，Code to Canvas 才会转成矢量图层。图片 URL 可能因为 CSP 无法加载。

### Q: 渐变填充无法绑定 Token？
A: 先用 `set_fills` 将渐变改为纯色，再绑定变量。或者保留渐变设计效果，不用变量绑定。

### Q: figma-mcp-go 卡在旧文件？
A: 每个 Figma 文件需要单独运行一次 figma-mcp-go 插件。关闭旧文件，在新文件中重新运行。

### Q: 官方 MCP 读工具次数有限？
A: 免费版每月 6 次读调用。`generate_figma_design` 不限次数。建议将设计集中批处理，减少不必要的 get 调用。

### Q: 如何确保 Token 值两端一致？
A: 运行 `node scripts/sync-tokens-to-figma.mjs --export-css` 导出 Figma 变量为 CSS，与 `variables.css` 比对。

---

## 6. 项目配置

两个 MCP server 已在 `.claude/mcp.json` 中配置：

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

官方 MCP 首次使用需要 OAuth 授权，按 Claude 提示在浏览器中完成。
