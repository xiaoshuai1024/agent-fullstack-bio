# Superpowers 工作流

本文档定义 Agent 在项目中必须遵守的工作流规范。

**相关文档（交叉引用）：**

- **[`docs/superpowers/GSTACK_AND_SUPERPOWERS.md`](superpowers/GSTACK_AND_SUPERPOWERS.md)** — **GStack 与 Superpowers 如何分工与串联**（需求侧 skill ↔ 计划/任务图 ↔ 评审 QA）；Agent 处理「需求 + 实现」迭代时优先读此文。
- `AGENTS.md` — 仓库级启动检查、工作流总览与子模块规则；其中「工作流」须与本节的 Superpowers 链对齐。
- `docs/AGENT_RULES.md`「§3 文档与计划」— 计划文件归档到 `docs/FEATURES.md` 的约定，以及与本节技能触发时机配合使用。
- [`docs/superpowers/PLAN_WRITING_CONTRACT.md`](superpowers/PLAN_WRITING_CONTRACT.md) — **`writing-plans` 产出 plan 的必选章节**与方案阶段 UX / 架构-E2E 自检要求。
- [`docs/dev/AGENT_WORKFLOW_CONSTRAINTS.md`](dev/AGENT_WORKFLOW_CONSTRAINTS.md) — **执行阶段**：TDD、并行 subagent、E2E 失败排查顺序、`verification-before-completion`。
- [`docs/superpowers/templates/`](superpowers/templates/) — 《原始需求》模板与 PR 描述最小勾选项。

---

## 对用户（操作者）的引导

Agent 在识别到**新需求、多步骤实现或「做计划」**意图时，应**主动说明**下一步将按 Superpowers 推进，避免用户跳过关键阶段：

1. **头脑风暴**（`brainstorming`）— 澄清目标、约束与可选方案；创意类、模糊需求或有多解时必须先经过此步（见本节「Skill 使用规则」表）。
2. **写实现计划**（`writing-plans`）— 将共识落盘到 `docs/superpowers/plans/`，再进入编码。
3. **执行计划**（`executing-plans`，或与计划内说明一致的 `subagent-driven-development`）— 仅在**已有书面计划**且用户同意开始实现时启用；按任务勾选与检查点推进。
4. **全栈方案命令**（**`/plan-template`**）— KangDou 推荐入口：第一轮讨论稿对齐范围与「明确不做」，第二轮再按 [`PLAN_WRITING_CONTRACT.md`](superpowers/PLAN_WRITING_CONTRACT.md) 定稿；命令定义见 [`.agents/commands/plan-template.md`](../.agents/commands/plan-template.md)。

**引导话术要点**：说明「先想清再写计划、有计划再执行」，并指向本文件中的流程图与「计划类 Skill 的触发时机」小节；若用户只想先讨论不写代码，仍以 `brainstorming` 为主，不强行创建计划文件。**当用户表达写实现方案类意图但未在本轮使用 `/plan-template` 时**，Agent 须主动建议发送 **`/plan-template`**（义务与例外见 **`PLAN_WRITING_CONTRACT.md`**「推荐入口与 Agent 提醒」）。

---

## 核心原则

1. **禁止直接写代码** — 任何任务必须先经过设计阶段
2. **禁止假设** — 有 1% 概率适用某 skill 时，必须加载该 skill
3. **禁止推测** — 需求或信息不完整时必须主动询问，禁止推测性开发（见 `.agents/rules/kangdou-no-speculation-no-blind-dev.md`）
4. **禁止跳过验证** — 声称完成前必须运行验证命令
5. **优先并行** — 任何工作，只要能开启 subagent 进行，就尽可能多的开启 subagent 并行执行（见下「协作粒度」）

---

## 工作流类型

### A. 新功能 / 特性开发

```
brainstorming → writing-plans → implementation → verification → requesting-code-review
```

**步骤：**
1. **brainstorming** — 理解需求，探索方案，提出设计
2. **writing-plans** — 创建实现计划
3. **implementation** — 按计划执行；**默认**拆分为独立子任务，**优先**起多个 subagent 并行执行
4. **verification-before-completion** — 运行验证命令，确认通过；合并/验收前另须完成 [`AGENT_WORKFLOW_CONSTRAINTS.md`](dev/AGENT_WORKFLOW_CONSTRAINTS.md) **§5.1**（`architecture-review-e2e-tdd` + `ux-product-review` 与方案阶段同口径收口）
5. **requesting-code-review** — 请求代码审查

---

### B. Bug 修复

```
systematic-debugging → implementation → verification
```

**步骤：**
1. **systematic-debugging** — 定位问题根因，禁止猜测
2. **implementation** — 修复问题
3. **verification-before-completion** — 验证修复有效

---

### C. 代码审查

```
receiving-code-review → implementation → verification
```

**步骤：**
1. **receiving-code-review** — 接收审查反馈，理解问题
2. **implementation** — 修复审查意见
3. **verification-before-completion** — 验证修复

---

## Skill 使用规则

| 场景 | 必须加载的 Skill |
|------|---------------|
| 任何创造性工作（功能、组件、行为） | `brainstorming` |
| 有书面实现计划时 | `executing-plans` |
| 遇到 bug 或测试失败 | `systematic-debugging` |
| **任何可并行的工作**（只要能开启 subagent 进行） | **`dispatching-parallel-agents`**（MUST；优先使用） |
| 需要隔离开发 | `using-git-worktrees` |
| 声称完成后 | `verification-before-completion` |
| 请求合并/PR 前 | `requesting-code-review` |
| 接收代码审查反馈 | `receiving-code-review` |

### 计划类 Skill 的触发时机（与 Superpowers 对齐）

技能在仓库中的名称是 `writing-plans` / `executing-plans`；在部分环境中也会写作 `superpowers:writing-plans`、`superpowers:executing-plans`，含义相同。

| 用户意图 | 应做的事 |
|---------|---------|
| **做计划 / 写计划 / 规划 / 实现计划文档**，或等价表达（多步骤、要先落盘再动手、要可勾选的实施清单） | **先**加载 **`writing-plans`**，在 `docs/superpowers/plans/` 下创建实现计划文件（默认命名 `YYYY-MM-DD-<feature-name>.md`），**不要**在未产出计划文件前直接进入编码（用户明确只要极小改动、无需计划的除外）。 |
| **已有计划文件**，且用户要「按计划执行 / 实现这份计划 / 跑 plan」 | 加载 **`executing-plans`**（或与计划内说明一致时优先 **`subagent-driven-development`**），按任务逐步执行并做检查点。 |

**执行顺序**：多步骤特性开发一般为 `brainstorming`（澄清与方案）→ `writing-plans`（落盘计划）→ 再选 `executing-plans` 或 subagent 实现；**不要**把「写计划」和「执行计划」混在同一步里，除非用户明确只要其中一种。

**方案契约与执行约束**：落盘 `docs/superpowers/plans/*.md` 时须遵守 [`PLAN_WRITING_CONTRACT.md`](superpowers/PLAN_WRITING_CONTRACT.md)（含需求溯源、**§4.0 按系统新增模块**、**§4.2 列表级交互链**、集成复用表、UX/架构自检、E2E 计划含 **§7.1 / §7.2** 等）；编码与收尾须遵守 [`AGENT_WORKFLOW_CONSTRAINTS.md`](dev/AGENT_WORKFLOW_CONSTRAINTS.md)（TDD、Console→Network→日志、并行条件、占位禁止）。

**与项目归档**：计划执行完毕、结论需纳入长期功能清单时，按 `docs/AGENT_RULES.md`「§3 文档与计划」收敛到 `docs/FEATURES.md` 并清理临时 plan 文件。

### 任务图 JSON（唯一事实源）

每 feature 在 `docs/superpowers/tasks/<featureId>.json` 维护依赖、状态、子任务与并行就绪关系。新建或修改 `docs/superpowers/plans/` 下计划时须同步该 JSON，并在执行阶段更新状态。约定与十轮头脑风暴结论见 **[`docs/dev/SSOT-TASK-GRAPH-PLAN.md`](dev/SSOT-TASK-GRAPH-PLAN.md)**；校验：`node scripts/verify-plan-ssot.mjs validate <path>`。

---

## 多 Agent 协作与并行（优先并行）

### 协作粒度（MUST）

| 场景 | 建议 |
|------|------|
| **任何可并行的工作**（只要能开启 subagent 进行） | **主 agent 编排，优先起多个 subagent 并行执行**（用 `dispatching-parallel-agents` 或直接调用 `Task`） |
| 顺序依赖极强、无法拆分的单一步骤 | **单一会话 / 单 agent 串行**（仅在确实无法并行时使用） |

**优先并行原则**：任何工作，只要能拆分为独立子任务，就尽可能多的开启 subagent 并行执行；并行是默认首选，串行是例外。

### 何时必须并行

当任务满足以下**任一**条件时，必须评估并行 subagent：

- 多个**独立**的模块/页面/接口（无共享可变状态）
- 多个**不相关**的文件修改且可独立测试
- 可以**同时**开发而互不影响
- 方案阶段的并行信息收集与对读
- 问题排查阶段的并行调查
- 多子系统的并行开发

### 应避免的做法

- ❌ **默认串行** — 本可并行的工作强行顺序完成
- ❌ **过度保守** — 担心冲突而不敢并行
- ✅ **大胆拆分** — 拆分为明确的独立子任务，大胆并行；主 agent 负责汇总与解决冲突

### 并行时的执行方式（按需）

```
主 agent
├── subagent 1 → 并行任务 A（可选）
├── subagent 2 → 并行任务 B（可选）
└── ...
```

需要并行时，subagent **同时启动**，主 agent 负责汇总与解决冲突。

---

## 验证要求

任何"完成"声明前，必须：

1. **运行验证命令**（根据项目类型）
   - 前端：`npm run build`
   - 后端：`mvn test`
2. **确认输出无错误**
3. **证据在先，断言在后** — 禁止声称"已经通过"而不提供证据

---

## 禁止的行为

- ❌ 跳过 brainstorming 直接写代码
- ❌ 用"简单"为理由跳过设计
- ❌ 声称完成后不运行验证
- ❌ 在设计未确认前进入实现
- ❌ 盲目猜测 bug 根因
- ❌ 忽略 skill 触发条件

---

## 技能加载方式

```bash
# 加载 skill
skill <skill-name>

# 可用 skills
- brainstorming
- systematic-debugging
- test-driven-development
- writing-plans
- executing-plans
- verification-before-completion
- requesting-code-review
- receiving-code-review
- dispatching-parallel-agents
- using-git-worktrees
- using-superpowers
- finishing-a-development-branch
```