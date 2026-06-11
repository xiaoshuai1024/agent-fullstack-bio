# 云效 MCP 不生效排查

本页用于解决「MCP 显示已安装，但 Agent 不能调用云效工具」的问题。

**Projex OpenAPI 与 MCP 工具对照、PAT 下可用的 `workitems:search` 等**：见 `docs/dev/yunxiao-operations-cookbook.md`（便于离线执行，不必临时检索）。

## 官方基线（已核对）

- 官方推荐 stdio 方式：`npx -y alibabacloud-devops-mcp-server`
- 必需环境变量：`YUNXIAO_ACCESS_TOKEN`
- 可选环境变量：`YUNXIAO_API_BASE_URL`（中心站默认 `https://openapi-rdc.aliyuncs.com`）

参考：

- https://help.aliyun.com/zh/yunxiao/use-cases/lingma-and-alibaba-cloud-devops-mcp
- https://raw.githubusercontent.com/aliyun/alibabacloud-devops-mcp-server/master/README.zh-cn.md

## 当前仓库修复

为避免 Cursor 会话环境变量丢失，已改为通过包装脚本启动 MCP：

- 配置：`.cursor/mcp.json`
- 启动脚本：`scripts/codeup/start-yunxiao-mcp.sh`

脚本行为：

1. 自动读取 `scripts/codeup/.env`
2. 自动把 `YUNXIAO_TOKEN` 映射为 `YUNXIAO_ACCESS_TOKEN`
3. 默认 API 站点为中心站
4. 启动 `alibabacloud-devops-mcp-server`

## 本机验证命令

```bash
cursor agent mcp list
cursor agent mcp list-tools yunxiao
```

若看到 `yunxiao: ready` 且存在 `create_change_request`，表示 MCP server 已就绪。

## 仍不生效时（通常是会话授权层）

1. 在 Cursor IDE 中确认当前聊天会话已允许 MCP 工具调用（不是仅资源读取）。
2. 新开一个聊天会话再试（旧会话可能没有刷新工具列表）。
3. 确认当前会话已信任工作区并允许执行工具。
4. 检查 `scripts/codeup/.env` 中 token 是否有效且具备组织/代码管理读写权限。

## 另见

- 工作项状态、工时、本地任务缓存与 Agent 行为：`docs/dev/yunxiao-agile-agent.md`
