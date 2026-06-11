---
description: 继续执行当前任务（异常中断后恢复）；开发类任务须拆分子 agent、遵守仓库工作流与 TDD/E2E 门禁
---

## 含义

**`jx` = 继续**：从对话与仓库状态中**接续被中断或未完成的工作**，不重新开题、不默认推翻已有结论。若中断前有明确计划/分支/待办，以之为 SSOT；若上下文不全，先**短读**相关文件与 `git status` 再动手。

## Agent 必须遵守

### 1. 恢复上下文（先做）

- 回顾用户**上一段有效目标**与任何**未完成步骤**；必要时 `git status -sb`、`git diff --stat`、打开活跃方案 `docs/superpowers/plans/*.md` 或用户指定的文档。
- **不要**在未确认当前分支与仓库边界的情况下大范围改代码（见 [docs/GIT_WORKFLOW.md](mdc:docs/GIT_WORKFLOW.md)）。

### 2. 开发类任务：多拆 **Task 子 agent**（尽量并行）

- 将剩余工作拆成**彼此独立、可并行**的包（例如：backend 单测 / operation-backend Vitest / frontend 构建与 e2e / 文档-only），**分别**用 **Task** 子 agent 执行；能并行则**同轮并行派发**，勿串行堆在一轮对话里硬啃。
- 子 agent **须带足上下文**（路径、验收标准、禁止事项），避免重复全仓探索。
- **Cursor Task 约定**（MUST）：默认**不要**向 `Task` 传入 `model` 参数，以免 Free 套餐报错；见 [Cursor 环境规则（本环境忽略）](mdc:Cursor 环境规则（本环境忽略）)。

### 3. 工作流与 TDD / E2E（MUST）

- **工作流**：[AGENTS.md](mdc:AGENTS.md)、[docs/GIT_WORKFLOW.md](mdc:docs/GIT_WORKFLOW.md)（分支、commit、子模块边界）。
- **测试与 TDD**：[.agents/rules/kangdou-testing-coverage.md](mdc:.agents/rules/kangdou-testing-coverage.md)（各子系统命令、首个失败即停、禁止假绿 skip）。
- **方案/收尾门禁**：加载并遵循 [.agents/skills/architecture-review-e2e-tdd/SKILL.md](mdc:.agents/skills/architecture-review-e2e-tdd/SKILL.md) —— **先测后码、红→绿**；宣称完成前须跑通文档规定的**全量验证命令**并保留证据。
- 实现阶段可配合 [.agents/skills/subagent-driven-development/SKILL.md](mdc:.agents/skills/subagent-driven-development/SKILL.md) 或 [.agents/skills/dispatching-parallel-agents/SKILL.md](mdc:.agents/skills/dispatching-parallel-agents/SKILL.md) 的拆分与派发方式（与上条子 agent 策略一致）。

### 4. 非开发类任务

- 调研、文档、排障等：仍先对齐目标与证据；若可拆（多文件检索、多模块只读），同样**优先子 agent 并行**，再汇总结论。

## 禁止

- 为「省事」跳过失败测试、改断言糊弄绿、或未经用户同意在 `dev`/`master` 上直接提交。
- 在未读失败日志/网络/控制台的情况下盲改 E2E（与 `kangdou-testing-coverage` 一致）。

**你必须：** 用简短列表向用户说明**接续的是哪条任务**、**本轮拆了几种子任务/子 agent**、以及**下一步**或**验证命令结果**。
