# 飞书 MCP 初始化指引

本文档用于本仓库 `feishu-mcp` 的本地接入。

## 1. 创建飞书应用并获取凭证

1. 打开飞书开放平台：[https://open.feishu.cn/app](https://open.feishu.cn/app)
2. 点击「创建企业自建应用」。
3. 进入应用详情页，找到：
   - `App ID`（也叫 `cli_xxx`）
   - `App Secret`
4. 将这两个值填入 `scripts/feishu/.env`：

```env
FEISHU_APP_ID=cli_xxx
FEISHU_APP_SECRET=xxxx
```

## 2. App ID 是否必须？

是，必须。

- `feishu-mcp` 启动鉴权依赖 `FEISHU_APP_ID + FEISHU_APP_SECRET` 成对使用。
- 只有 `Secret` 没有 `App ID` 无法完成应用身份校验。

## 3. 初始化和启动

1. 初始化模板：

```bash
bash scripts/feishu/init-feishu-mcp.sh
```

2. 填写 `scripts/feishu/.env` 后启动：

```bash
bash scripts/feishu/start-feishu-mcp.sh
```

## 4. 常见问题

- **报错：missing FEISHU_APP_ID or FEISHU_APP_SECRET**
  - 检查 `scripts/feishu/.env` 是否存在且变量不为空。
  - 检查是否有额外空格或引号导致解析失败。
- **变量填写后仍失败**
  - 重新打开终端或重新执行脚本，确保加载了最新 `.env`。

## 5. `upload-doc.sh` 与 MCP 用户令牌（表格列宽等）

`scripts/feishu/upload-doc.sh` 在调用 Docx OpenAPI（如表格列宽 `batch_update`）时，需要 **user_access_token** 才不易出现知识库文档 **403**。脚本会**自动**按顺序尝试：

1. 环境变量 `FEISHU_USER_ACCESS_TOKEN`（若已手动配置）；
2. 本机 **feishu-mcp** OAuth 缓存文件 `user_token_cache.json`（默认目录：`~/.cache/feishu-mcp` 或 `~/.feishu-mcp`），缓存键为 `user_access_token:${FEISHU_USER_KEY}`；未配置 `FEISHU_USER_KEY` 时与 MCP 默认一致为 **`stdio`**；
3. 若缓存中 access 将过期，则用缓存里的 **refresh_token** 调用 `authen/v2/oauth/token` 刷新（需同一 `.env` 中的 `FEISHU_APP_ID` / `FEISHU_APP_SECRET`）；
4. 最后才使用 **tenant_access_token**（在部分租户上对 wiki 正文 patch 会失败）。

因此：**先按上文启动 MCP 并完成一次用户授权登录**，再跑上传脚本，通常**不必**再单独配置 `FEISHU_USER_ACCESS_TOKEN`。

## 6. `/feishu-doc` 与目录映射（知识库子目录）

Cursor 自定义命令 **`/feishu-doc`**（见 `.agents/commands/feishu-doc.md`）会把本地 Markdown 传到 **康豆企业知识库** 下指定子目录，底层调用：

- `scripts/feishu/feishu-doc-sync.sh`（解析目录别名 → `parent_node_token`，支持模糊命中后 **`--pick N`**）
- `scripts/feishu/upload-doc.sh`（实际上传）

请复制 `scripts/feishu/wiki-dir-mappings.example.json` 为 **`scripts/feishu/wiki-dir-mappings.json`**（已加入 `.gitignore`），填写各目录的 **`parent_node_token`** 与 **`aliases`**。默认目录别名为 **「产品文档」**。

**单页 wiki 空间（平铺为主）**：列表里大量节点是「一页一篇」的云文档时，`upload-doc.sh` 创建新文档仍需要 **父 wiki 节点** `parent_node_token`。此时映射名「产品文档」只表示 **产品侧习惯分类**，**不等于**必须把同名那篇叶子文档的 `node_id` 当作父节点（飞书未必允许在单页文档下再挂子文档，或行为与预期不一致）。请在飞书内确认 **可挂子节点的父级**（例如单独建的收纳页/文件夹节点、或团队约定的根下容器），把该父节点的 `node_id` 写入映射。

### 6.1 用接口列出知识库节点（获取 `parent_node_token`）

无需手抄浏览器时，可在主仓库根执行（需已配置 `.env` 且 `FEISHU_AUTH_TYPE=user` 并完成 OAuth）：

```bash
# 列出默认企业 wiki 空间根下子节点
bash scripts/feishu/wiki-list-nodes.sh

# 列出某父文件夹下的子节点
bash scripts/feishu/wiki-list-nodes.sh --parent <父节点 node_token>

# 按关键词搜索 wiki 节点（找「产品文档」等）
bash scripts/feishu/wiki-list-nodes.sh --search 产品文档
```

将输出 JSON 中 **作为父挂载点** 的 **`node_id`**（与 `…/wiki/<node_id>` 一致；`search_feishu_documents` 返回字段名为 `node_id`）填入 `wiki-dir-mappings.json` 的 `parent_node_token`。勿与已有文档的 **`obj_token`（云文档 docx id）** 混淆。
