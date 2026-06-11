# Figma MCP 原型开发经验总结

本文记录康豆全栈项目中使用双 MCP（figma-mcp-go + 官方 Figma MCP）进行 Figma 原型开发的经验教训，供后续开发参考。

---

## 1. 工具选型对比

### 1.1 figma-mcp-go（本地）

| 优点 | 缺点 |
|------|------|
| 73 个工具，覆盖面广 | 无法导入 SVG 图标到 Figma |
| 无频率限制，完全免费 | CSS 渐变/阴影只能近似模拟 |
| 支持变量绑定（bind_variable_to_node） | 需在 Figma 桌面版安装插件并运行 |
| 支持截图导出（save_screenshots） | 图层只能通过基础形状构建 |
| 创建/修改变量集合（COLOR / FLOAT） | |

### 1.2 官方 Figma MCP（云端）

| 优点 | 缺点 |
|------|------|
| Code to Canvas：HTML 变成 Figma 图层 | 免费版每月仅 6 次读调用 |
| 保留 SVG 图标为矢量图层 | 读次数用完无法使用 get_screenshot 等 |
| CSS 渐变/阴影完整保留 | 渐变填充无法绑定 COLOR 变量 |
| 真实图片（`<img>`）可导入 | 需 OAuth 授权 |
| `generate_figma_design` 不限次数 | 需启动本地 HTTP 服务来提供 HTML |

### 1.3 结论：互补使用

| 场景 | 推荐工具 |
|------|---------|
| 生成带 SVG 图标、渐变的复杂组件 | 官方 MCP（Code to Canvas） |
| 绑定设计 Token 到已有组件 | figma-mcp-go |
| 截图导出预览 | figma-mcp-go（save_screenshots） |
| 读取设计结构 | figma-mcp-go（get_design_context） |
| 精细修改图层属性 | figma-mcp-go（set_fills, bind_variable_to_node） |

---

## 2. Code to Canvas 最佳实践

### 2.1 HTML 编写规范

```html
<!-- 关键：必须添加 capture.js 脚本 -->
<script src="https://mcp.figma.com/mcp/html-to-design/capture.js" async></script>

<!-- Viewport 锁定宽度（小程序标准 375px） -->
<meta name="viewport" content="width=375, initial-scale=1.0">

<!-- 颜色值直接用 hex，非 CSS 变量（Figma 不解析 var()） -->
<style>
  .banner { background: #00B341; }
</style>
```

### 2.2 真实图片

- 使用 `<img src="assets/xxx.jpg">` 本地图片
- 图片下载来源：`picsum.photos`（CC0 许可）
- **必须**通过本地 HTTP 服务提供 HTML，不能用 `file://` 协议

### 2.3 多状态展示

- Tab 选中/未选中状态可以平铺展示（非交互）
- 按钮禁用态、已领取态等可平铺对比
- 多种 Banner 风格可垂直堆叠

### 2.4 改进空间

- **交互效果**：Figma 原型交互（`set_reactions`）需要手动绑定，Code to Canvas 不包含交互逻辑
- **组件化**：导入的图层需人工转为 Figma Component
- **Token 绑定**：渐变色图层无法绑定 COLOR 变量，需先改为纯色

---

## 3. Token 变量同步

### 3.1 现状

CSS Token 源 `frontend/src/styles/tokens/generated/variables.css` 是 SSOT。

Figma 变量按文件隔离，跨文件需要重新创建。

### 3.2 同步脚本

```bash
# 查看差异报告
node scripts/sync-tokens-to-figma.mjs

# 生成 MCP 命令
node scripts/sync-tokens-to-figma.mjs --sync
```

### 3.3 已知限制

- Figma 变量只能绑定到纯色填充（solid paint），渐变不可绑定
- rgb/rgba 值中的透明度信息在 Figma COLOR 变量中丢失，需通过独立 opacity 设置

---

## 4. 双 MCP 操作流程

### 标准开发流程

```
① Claude 写 HTML（含 SVG 图标、CSS 渐变、真实图片）
        ↓
② 启动本地 HTTP 服务：python3 -m http.server 8899
        ↓
③ 官方 MCP：generate_figma_design(url, fileKey) → 获取 captureId
        ↓
④ 浏览器打开 #figmacapture={captureId} 链接 → 自动捕获
        ↓
⑤ 轮询 captureId 直到 completed
        ↓
⑥ figma-mcp-go：在当前文件中创建变量集合 + 绑定 Token
        ↓
⑦ 人工：在 Figma 中转为 Component
```

### 注意事项

- 每个 captureId **一次性使用**，不可重复
- 同一个文件可多次 generate_figma_design（outputMode: existingFile）
- 每次捕获生成独立的 nodeId，需清理旧版本
- 官方 MCP 免费版读工具仅 6 次/月，写工具（generate_figma_design）不限

---

## 5. 实际效果评估

| 维度 | 还原度 | 说明 |
|------|--------|------|
| 颜色 | 100% | 通过 Token 变量绑定确保一致 |
| 间距/圆角 | 100% | kd-space / kd-radius 统一控制 |
| SVG 图标 | 100% | Code to Canvas 保留矢量图层 |
| 真实图片 | 100% | `<img>` 导入为 Figma 图片图层 |
| CSS 渐变 | ~95% | 线性渐变保留，但无法绑定变量 |
| 布局结构 | ~90% | HTML Flex 映射为 Figma Auto Layout |
| 文字样式 | ~95% | 字体、字号、颜色保留，字重可能偏差 |
| 原型交互 | 0% | 需手动用 figma-mcp-go set_reactions 或 Figma 内添加 |

---

## 6. 工具配置

配置文件：`.claude/mcp.json`

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

官方 MCP 首次使用需完成 OAuth 授权，由 Claude 引导在浏览器中完成。
