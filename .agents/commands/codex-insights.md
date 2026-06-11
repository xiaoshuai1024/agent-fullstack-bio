---
description: 在 Codex 中生成 Claude `/insights` 的本地替代摘要（读取本机 `~/.claude/projects/*.jsonl`）
---

触发：**`/codex-insights`**，或用户明确要求“看 Claude insights / 生成 insights 摘要”。

## 目标

Claude 的 **`/insights`** 是内置命令，不来自项目的 `.claude/commands/`。  
在 Codex 中无法直接调用该内置能力，因此本命令改为读取本机 Claude 会话 JSONL，
生成一个近似的项目级摘要。

## 执行步骤

1. 在仓库根目录运行：

```bash
pnpm run insights:claude
```

2. 若用户指定了别的项目 slug、Claude home 或最近会话条数，则改用：

```bash
node scripts/claude-insights.mjs --project-slug <slug> --claude-home <path> --recent-limit <n>
```

3. 将结果用中文简要回报给用户，至少包含：
   - 命中的 Claude project slug
   - 会话数 / 时间范围
   - user / assistant 消息数
   - 模型分布
   - 最近活跃会话

## 注意

- **不要**把该命令同步到 `.claude/commands/insights.md`，避免与 Claude 内置 **`/insights`** 冲突。
- 若脚本报 “Unable to resolve Claude project slug”，应显式传入 `--project-slug`。
- 该脚本的数据源默认是：`C:\Users\<用户名>\.claude\projects\`

