# mcp-memory-service 部署指南（本地免费 / SQLite 落盘）

## 1. 方案概述

使用 `mcp-memory-service`（社区成熟方案）在本机以 `uvx + Python 3.11` 方式运行（不依赖 Docker）：

- MCP（Streamable HTTP）：`http://127.0.0.1:8765/mcp`
- 数据持久化：`scripts/memory/data/sqlite_vec.db`

## 2. 启动 / 关闭

首次建议先复制环境模板：

```bash
cp scripts/memory/.env.example scripts/memory/.env
```

启动：

```bash
bash scripts/memory/up.sh
```

关闭：

```bash
bash scripts/memory/down.sh
```

## 3. Cursor 接入

项目已在 `.cursor/mcp.json` 配置：

- `memory` → `http://127.0.0.1:8765/mcp`

重启 Cursor 后即可看到 memory 工具。

## 4. OpenCode 接入（两种）

### 4.1 作为 Remote MCP（推荐）

在 OpenCode 配置 `mcp` 中加：

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "memory": {
      "type": "remote",
      "url": "http://127.0.0.1:8765/mcp",
      "enabled": true
    }
  }
}
```

### 4.2 使用 OpenCode 官方 memory-awareness 插件（可选）

参考上游仓库 `doobidoo/mcp-memory-service/opencode/README.md`，该插件会在会话开始时自动检索并注入 memory（当前主要读，不含自动写回）。

## 5. 验收

1. `curl -X POST http://127.0.0.1:8765/mcp -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"tools/list\",\"id\":1}'`\n
2. Cursor 中能看到 `memory_*` 工具（如 `memory_store`、`memory_search`）\n
3. 写入一条 memory 后重启服务进程，仍可检索到（验证落盘）
