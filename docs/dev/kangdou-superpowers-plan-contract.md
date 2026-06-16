<!--
description: 新建或修改 Superpowers plan 时提醒加载方案编写契约与执行约束
globs: docs/superpowers/plans/**/*.md
alwaysApply: false
-->

# Superpowers Plan 契约（软提醒）

用户在聊天中提出「写方案」等**实现计划**意图但未显式使用 **`/plan-template`** 时，Agent 应**主动建议**使用该命令（两段式流程与例外见 **[PLAN_WRITING_CONTRACT.md](docs/superpowers/PLAN_WRITING_CONTRACT.md)**「推荐入口与 Agent 提醒」）。

编辑或新建 `docs/superpowers/plans/**/*.md` 时：

1. 编写前加载 **[PLAN_WRITING_CONTRACT.md](docs/superpowers/PLAN_WRITING_CONTRACT.md)**，核对必选章节（需求溯源、**§0.1 分支与仓库（方案阶段 / 执行阶段）**、**§4.0 按系统新增功能模块表**、**§4.2 列表级交互链路**、**§4.3 页面结构展示与高保真原型**、集成复用表（§5）、UX 自检摘要（§4.1）、架构/E2E 自检（§6.1）、E2E 计划含 P0、**§7.1 跨端主路径表**、**§7.2 脚本保障逻辑**、文首 `taskGraph`）。
2. 执行与收尾对齐 **[AGENT_WORKFLOW_CONSTRAINTS.md](docs/superpowers/AGENT_WORKFLOW_CONSTRAINTS.md)**（TDD、并行 subagent 条件、Console→Network→后端日志、verification）。
3. 任务状态以 **[SSOT-TASK-GRAPH-PLAN.md](docs/superpowers/tasks/SSOT-TASK-GRAPH-PLAN.md)** 与对应 JSON 为准；校验 `node scripts/verify-plan-ssot.mjs validate <path>`。
4. **范围与质量（对齐 `/plan-template`）**：采用**最完整可交付策略**——需求内功能**不得静默跳过**；同时**控制功能膨胀**——凡非需求原文或本期目标所必需的能力，须列入「**明确不做 / 后续迭代**」并说明理由，禁止无边界镀金。禁止假绿、占位、骨架页、以 raw JSON 顶替用户页面；页面交互须与 **§4.2 / §4.3**、E2E 计划可验收对齐。详见 **[plan-template.md](.agents/commands/plan-template.md)**。
5. **多维结论落盘**：若用户要求将并行多视角结论写入本 plan，须按 **[10-bs.md](.agents/commands/10-bs.md)**（**`/10-bs`**）执行：仅将**综合结论**写入目标文档的约定章节，不得把分轮过程堆进 plan。
6. **编写方案时可按需加载的 skills**（路径以仓库为准）：**`architecture-review-e2e-tdd`**（`.agents/skills/architecture-review-e2e-tdd/SKILL.md`）、**`ux-product-review`**（与 **`/super-pm`**）、**`writing-plans`**（`.agents/skills/writing-plans/SKILL.md`）、**`brainstorming`**（需求含混或创新点前）、**`plan-eng-review`** / **`plan-ceo-review`**（锁架构或调范围时）、**`ui-spec-enforcer`**（前端/UI 规范对照）、**`ten-round-brainstorm`**（与 **`/10-bs`** 配套）。

本规则为 **fail open** 提醒；合并不以此文件为唯一门禁，仍以人审与 CI 为准。

---

## 经验：十轮并行头脑风暴的工作方法

每个独立视角同时审视同一命题，非串行改稿：

1. 定义 10 个正交的视角维度（功能缺失、设计缺陷、可用性、性能、冲突、边界、自动化、可读性、增量、工作流整合）
2. 所有视角**并行**思考，互不干扰
3. 结论按 H/M/L 优先级排序，纳入方案
4. 有效避免「想到哪算哪」的盲点

---

## 经验：writing-plans discipline — 写方案前必须先加载 PLAN_WRITING_CONTRACT

### 场景
撰写 V2 完整实现计划 `2026-06-05-v2-complete-implementation.md` 时，直接输出 §2 任务表 → §3 执行计划 → §4 验证门禁三段，缺失 §4 页面结构展示、§5 集成复用表、§6 数据隔离声明、§7 E2E 脚本保障逻辑、§8 TDD 执行约定——共 5 个 MUST 章节。

### 根因
1. 没有加载 `writing-plans` skill 就动手写 plan
2. 没有读取 `PLAN_WRITING_CONTRACT.md` 核对必选章节清单
3. 凭记忆输出模板，而非按契约逐节对照
4. 认为"快点产出再说，细节后面补"——但 plan-template 禁止静默跳过 MUST 章节

### 解决方案
1. 每轮定稿前显式加载 `writing-plans` skill + 读取 `PLAN_WRITING_CONTRACT.md` 章节清单
2. 逐节对照：文首 YAML → §0.1 分支 → §1 溯源 → §2 → §3 → §4.0/4.1/4.2/4.3 → §5 → §6/6.1 → §7/7.1/7.2 → §8
3. 每节都核对质量禁令自检表与分级验收门禁
4. 用户指出缺失后补回全部 MISS 章节

### 预防
- 写 plan 前必须执行：`writing-plans` skill → `PLAN_WRITING_CONTRACT.md` → SSOT-TASK-GRAPH-PLAN.md
- 完成后自检：§4.3 页面结构展示是否存在？§5 集成复用表是否存在？§7.2 脚本保障逻辑是否存在？
- 预检可以用 `grep "## §4"` 快速确认章节完整性
