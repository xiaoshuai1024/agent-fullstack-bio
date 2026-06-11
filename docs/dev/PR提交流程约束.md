# PR 提交流程约束

更新时间：2026-04-29

## 规则

当 PR/MR 提交成功后，必须返回 **PR/MR 的具体地址**，不得仅返回项目仓库地址。
当创建飞书文档成功后，必须返回 **可直接访问的飞书文档链接**，不得仅返回标题、`node_token` 或 `document_id`。

## 执行要求

1. 返回信息中必须包含可直接访问的 PR/MR URL。
2. 若同一轮操作创建了多个 PR/MR，需要逐条返回各自地址。
3. 若创建失败，需要明确失败原因与下一步处理建议，不得返回仓库首页代替结果。
4. 若同一轮操作创建了多个飞书文档，需要逐条返回各自可访问链接。
5. 若飞书文档创建失败，需要明确失败原因与下一步处理建议，不得只返回 token/id。

## 示例

- 正确：`https://codeup.aliyun.com/.../merge_requests/123`
- 错误：`https://codeup.aliyun.com/.../my-repo`
- 正确：`https://{tenant}.feishu.cn/docx/{document_id}`
- 错误：`已创建：核心流程梳理（document_id=xxx）`
- 错误（知识库亦同）：`https://{tenant}.feishu.cn/wiki/{node_token}` 充当正文链接（应改用 `docx/{document_id}`，见 `docs/dev/飞书文档上传MUST规范.md` 第五节）

