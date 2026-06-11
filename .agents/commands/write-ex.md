---
description: 将当前会话中的排障经验归类追加到对应规则文件并写入 claude-mem 个人记忆，全程自动完成
---

## 含义

**`/write-ex`**：自动完成三件事：

1. **团队共享** → 按主题归类追加到 `docs/dev/` 对应文件（提交 Git）
2. **个人记忆** → 写入 claude-mem `memory/*.md`（后续会话自动感知）
3. **索引更新** → 追加条目到 `MEMORY.md`

## 归类映射

| 标签关键词 | 目标文件 |
|-----------|---------|
| flyway, migration, sql, 迁移 | `docs/dev/kangdou-flyway-new-migration.md` |
| e2e, testing, playwright, e2e-guide, automator | `docs/dev/kangdou-e2e-agent-guide.md` |
| e2e-contract, 假绿, 测试纪律 | `docs/dev/kangdou-e2e-execution-contract.md` |
| git, merge, pull, conflict, 冲突 | `docs/dev/kangdou-git-merge-pull.md` |
| redis, cache, ttl | `docs/dev/kangdou-redis-cache.md` |
| frontend, ux, enum, 中文显示, 枚举 | `docs/dev/kangdou-frontend-ux-enum.md` |
| testing-coverage, 单测, 覆盖率 | `.agents/rules/kangdou-testing-coverage.md` |
| wechat, miniprogram, 小程序 | `docs/dev/wechat-miniprogram-ship-quality.md` |
| dev-prototype, 原型 | `docs/dev/kangdou-dev-no-prototype-docs.md` |
| plan, superpowers, task-graph | `docs/dev/kangdou-superpowers-plan-contract.md` |
| plan-mode, agent-mode | `.agents/rules/kangdou-plan-agent-mode-triggers.md` |
| design-tokens, token, 样式 | `docs/dev/kangdou-design-tokens.md` |
| hooks | `.agents/rules/agent-hooks.md` |
| cross-cutting, 全栈审查 | `docs/dev/kangdou-cross-cutting-standards.md` |
| yunxiao, 云效 | `docs/dev/yunxiao-agile-agent.md` |
| kd-review, review, 审查 | `docs/dev/kd-review-five-rounds-gate.md` |
| daily-dev, daily, 日常 | `docs/dev/kangdou-daily-dev-sync.md` |
| speculation, blind-dev, 臆测 | `.agents/rules/kangdou-no-speculation-no-blind-dev.md` |
| alibaba, java-manual, 编码规范 | `docs/dev/alibaba-java-development-manual.md` |
| ops-tenant, 运营后台 | `docs/dev/kangdou-ops-tenant-ui.md` |
| superpowers-task-graph, task-graph-ssot | `docs/dev/kangdou-superpowers-task-graph-ssot.md` |
| experience, 经验教训, lessons | `docs/dev/kangdou-experience-lessons.md`（通用兜底） |
| 其他（未匹配） | `docs/dev/self-improve.md` |

## Agent 执行步骤

### Step 1 — 提取经验

回顾当前会话的完整上下文，提取：

- **问题标题**：简短概括
- **场景**：什么操作触发了问题
- **根因**：为什么出现
- **解决方案**：如何修复（关键命令、SQL、代码修改）
- **预防措施**：以后怎样避免

### Step 2 — 写入团队规则文件

1. 根据标签匹配目标规则文件（上表）
2. 读取文件末尾，追加 `## 经验：{问题标题}` 章节

格式：

```markdown
---

## 经验：{问题标题}

### 场景
{触发条件、错误表现}

### 根因
{为什么}

### 解决方案
```bash
{关键命令}
```
```sql
{关键 SQL}
```

### 预防
{检查清单、配置规范}
```

3. 若目标文件已有同名章节，追加 `### 案例 N`

### Step 3 — 写入 claude-mem 个人记忆（MCP）

个人记忆通过 **claude-mem MCP** 自动管理，**禁止** 手动写入本地 `memory/*.md` 文件。

记忆由 claude-mem hooks 自动捕获（PostToolUse / UserPromptSubmit 等），无需手动调用 MCP 写入工具。

**只需做一件事**：确认本次经验中用户的具体偏好（如 UI 决策、命名习惯、工作流选择）已被写入 team docs，由 claude-mem 在后续会话中自动从 team docs 提取上下文。

> ⚠️ 本项目 `MEMORY.md` 已迁移至 claude-mem 插件管理，不再由 `/write-ex` 命令维护。

### Step 4 — 提交 Git（团队部分）

```bash
git add docs/dev/{匹配的文件}
git commit -m "chore: add experience - {问题标题}"
```

> 提交前经用户确认。
