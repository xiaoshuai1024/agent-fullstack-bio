# 飞书文档上传 MUST 规范

更新时间：2026-05-09

## 一、单文档原则（硬约束）

1. **一次任务只允许创建一个飞书文档**。
2. `scripts/feishu/upload-doc.sh` 默认会在创建前做**同名知识库节点检测**（需 `FEISHU_AUTH_TYPE=user`）；同一目录下标题已存在则中止，避免重复文档。仅在不接受检测时使用 `--allow-multiple`（不推荐）。
3. 如果需要尝试不同方案：
   - **只能修改或删除当前已创建的文档**；
   - 不允许继续创建新的重复文档，导致同名多份散落。

## 二、重试原则（硬约束）

1. 当出现渲染失败（如 Markdown 标题/列表异常、**Mermaid 图不渲染**）或内容需要修正时：
   - 先删除本任务前一次创建的失败文档（或删除除最终文档以外的重复文档）；
   - 再用修正后的方案重新上传，确保最终只保留一份文档。
2. 若多次上传已产生重复文档，必须在最终交付前清理到**只剩 1 份**。

## 三、Mermaid 图渲染原则（硬约束）

1. Mermaid 图必须使用标准代码块格式：` ```mermaid ... ``` `
2. Mermaid 图节点中的文本如包含括号/逗号等特殊字符时，必须使用双引号包裹（保证渲染稳定）。
3. **`flowchart` / `graph` 中节点 ID 禁止使用语言保留字**，否则飞书/ Mermaid 解析会报 `Expecting ... got 'end'` 等错误。典型禁止项：**`end`**（用于闭合 `subgraph` 等）、勿用 **`subgraph`** 作节点 id。结束类节点请改用 **`done`**、`finish`、`END1` 等，例如 `done([结束])` 而非 `end([结束])`。
4. 上传模式优先选择支持 Mermaid 渲染的模式；若某模式校验失败，则切换到可正常渲染的模式（但不得因此产生重复文档）。

## 四、正文呈现原则（硬约束）

1. **禁止**在飞书文档正文中出现「整篇 Markdown 以代码块上传」或 **sha256 / 校验说明等调试性文案**。
2. 必须使用 `scripts/feishu/upload-doc.sh` 的 **默认 native 渲染**（标题/列表/表格/代码块语言高亮/Mermaid 等飞书原生能力），与本地 `.md` 语义对齐、便于阅读。

## 五、分享链接（硬约束）

1. 向用户或云效任务描述粘贴**可打开的正文链接**时，必须使用 **`https://{租户}.feishu.cn/docx/{document_id}`**（`document_id` 即上传成功日志里的 `document_id` / `obj_token`）。
2. **禁止**把知识库节点的 `node_token` 拼成 `https://{租户}.feishu.cn/wiki/{node_token}` 当作「文档正文链接」交付（易出现无权限、空白或跳错页）；与 `docs/dev/PR提交流程约束.md` 中飞书链接约定一致。
3. 若必须从知识库目录进入，可说明空间/父目录名称，由读者在飞书内导航；**对外可复制链接仍以 docx 为准**。

## 六、程序化编辑 Docx 正文（补充）

若使用 OpenAPI 对 **已有 Docx** 做表格拆行、批量改单元格等操作：Wiki 节点 token 与 **`document_id`（obj_token）易混淆**；表格单元格可能含 **多个段落子块**，校验不可只读第一个子块；部分 **`batch_update`** 能力在本仓库实践中 **用户令牌**更可行。详见：`docs/dev/飞书Docx-表格拆行与批量编辑验收经验.md`。

**整篇用本地 Markdown 覆盖知识库已有云文档**（先清空根级正文再 native 写入）：命令与注意事项见 **`docs/dev/飞书文档上传渲染修复经验.md`** 中「覆盖已有知识库文档」一节（`overwrite-feishu-wiki-doc.sh`）。

## 七、Cursor `/feishu-doc`（知识库父节点映射上传）

将本地 `.md` 传到飞书知识库 **指定父 wiki 节点之下** 时，可使用 Cursor 命令 **`.agents/commands/feishu-doc.md`**（`/feishu-doc`），底层仍须遵守上文 **单文档、同名防护、Mermaid、正文链接** 等约束；`parent_node_token` 由本地 **`scripts/feishu/wiki-dir-mappings.json`** 维护（示例见 `wiki-dir-mappings.example.json`）。若空间内多为 **单页 wiki 平铺**，勿把同名叶子文档的 `node_id` 想当然当作父节点；须选用飞书侧 **允许挂载子云文档** 的父节点（见 `docs/dev/feishu-mcp-setup.md` §6）。

