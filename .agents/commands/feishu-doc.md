---
description: 将当前任务中刚完成的本地 Markdown 上传到飞书康豆企业知识库指定目录；默认「产品文档」；目录别名支持模糊匹配与选择
---

**Agent：** 执行前必读 **`docs/dev/飞书文档上传MUST规范.md`**（单文档、Mermaid、链接、同名防护等硬约束）。

### 1. 行为说明

- 用户通过 **`/feishu-doc`** 或 **`/feishu-doc <目录别名>`** 触发（例如：`/feishu-doc 产品文档`）。
- **默认目录别名**：未跟参数时视为 **`产品文档`**（由本地 `wiki-dir-mappings.json` 解析为 `parent_node_token`）。若知识库以 **单页 wiki 平铺** 为主：该别名对应的是 **「新文档要挂在哪个父 wiki 节点下」**，不一定是名为「产品文档」的那篇 **叶子文档** 的 `node_id`；父节点须在飞书内选 **可挂子文档的容器**（见 `docs/dev/feishu-mcp-setup.md` §6）。
- **与微信商户提现并行**：本命令只负责 **本地 Markdown → 飞书知识库云文档**；不改变微信支付商户侧结算逻辑。
- **上传实现**：调用 `scripts/feishu/feishu-doc-sync.sh`，其内部再调 `scripts/feishu/upload-doc.sh`（`--space enterprise`、native 渲染）。

### 2. 一次性配置（用户本机）

1. `cp scripts/feishu/wiki-dir-mappings.example.json scripts/feishu/wiki-dir-mappings.json`
2. 在 `wiki-dir-mappings.json` 中为每条目录填写 **`parent_node_token`**。可从飞书客户端/链接复制，或在主仓根执行 **`bash scripts/feishu/wiki-list-nodes.sh`**（根下列表）、**`--parent <token>`**（子层）、**`--search 关键词`**（wiki 搜索）从接口 JSON 中取 `node_token`（详见 `docs/dev/feishu-mcp-setup.md` §6.1）。
3. `scripts/feishu/.env`：`FEISHU_APP_ID`、`FEISHU_APP_SECRET`、`FEISHU_AUTH_TYPE=user`，并完成 **feishu-mcp 用户 OAuth**（见 `docs/dev/feishu-mcp-setup.md`）。

### 3. 确定待上传文件（Agent 须明确）

从 **用户当前意图** 中解析要上传的 Markdown 路径，优先级建议：

1. 用户消息里 **显式给出的路径**；  
2. 本轮对话中 **刚编写/保存** 的文件（例如用户打开的 `docs/research/...md`）；  
3. 若无把握，**向用户确认**路径后再执行。

将路径传给脚本的 **`-f/--file`**（或环境变量 `FEISHU_UPLOAD_FILE`）。

### 4. 执行命令（主仓库根）

```bash
# 默认上传到映射表中「产品文档」对应目录
FEISHU_WIKI_NON_INTERACTIVE=1 bash scripts/feishu/feishu-doc-sync.sh -f "相对或绝对路径/到文件.md"

# 指定目录别名（须与 wiki-dir-mappings.json 中某 alias 匹配或可模糊命中）
FEISHU_WIKI_NON_INTERACTIVE=1 bash scripts/feishu/feishu-doc-sync.sh -f "docs/research/foo.md" "产品文档"
```

- **`FEISHU_WIKI_NON_INTERACTIVE=1`**：Agent 场景必选，避免脚本 `input()` 挂起。  
- 若脚本以 **退出码 2** 结束，stderr 会打印 **`ambiguous_dir_alias`** 的 JSON（含 `candidates` 数组）。**你必须**：把候选读给用户或根据 `label/alias` 代选，然后带 **`--pick N`**（`N` 为 JSON 里 `candidates` 的顺序，从 1 起）重跑同一命令。

```bash
FEISHU_WIKI_NON_INTERACTIVE=1 bash scripts/feishu/feishu-doc-sync.sh -f "docs/research/foo.md" "运维" --pick 2
```

可选：**仅一条模糊候选且与用户意图一致** 时，可用 **`-y`** 自动选用该目录（慎用）。

```bash
FEISHU_WIKI_NON_INTERACTIVE=1 bash scripts/feishu/feishu-doc-sync.sh -f "docs/foo.md" "产品文" -y
```

### 5. 成功交付

- 汇总终端中的 **`document_id`** / **`obj_token`**，向用户给出 **`https://{租户}.feishu.cn/docx/{document_id}`** 正文链接（规范见 MUST 文档 §五）。  
- 若 `upload-doc.sh` 因 **同名目录下已存在同标题文档** 退出码 2：说明 MUST 防重复已生效，**不得**用 `--allow-multiple` 盲目再传；应引导用户删/改名飞书旧文档或改本地 `--title`（若未来脚本暴露该参数）。

### 6. 干跑（可选）

```bash
bash scripts/feishu/feishu-doc-sync.sh --dry-run -f "docs/foo.md" "产品文档"
```
