# Agent Fullstack Bio 🚀

> AI Agent 驱动的全栈开发脚手架 — 从实战项目中提炼的技能库、工作流模板与开发规范，一键注入新项目

## 为什么需要这个项目？

当你用 Claude Code、Cursor 等 AI Agent 开发新项目时，每次都要从零配置：
- 怎么做 TDD？怎么写方案？怎么做代码审查？
- E2E 测试怎么写？覆盖率怎么保？
- Git 工作流怎么管？多子模块怎么协调？
- Agent 怎么并行？怎么分配任务？

**agent-fullstack-bio** 把这些能力打包成**即插即用的技能和规范**，一个命令注入你的项目，AI Agent 立刻拥有成熟的开发工作流。

## 📦 包含什么

### 🧠 Skills — AI 技能库（80+ 个）

每个 Skill 是一个 `SKILL.md` 文件，定义了 Agent 在特定场景下的完整行为模式。

| 类别 | 技能 | 说明 |
|------|------|------|
| **开发工作流** | `tdd` `executing-plans` `writing-plans` `finishing-a-development-branch` | TDD 驱动开发、方案编写/执行、分支收尾 |
| **质量保障** | `verification-before-completion` `systematic-debugging` `qa` `benchmark` | 完成前验证、系统排障、QA 闭环、性能基准 |
| **架构审查** | `architecture-review-e2e-tdd` `e2e-testing` `e2e-flow-check` | 架构自检、E2E 覆盖分析、流程检查 |
| **代码审查** | `requesting-code-review` `receiving-code-review` `review` | 双向代码审查流程 |
| **产品 & UX** | `ux-product-review` `ui-spec-enforcer` `ui-ux-pro-max` `frontend-design` | 产品 UX 审查、UI 规格、高保真原型 |
| **并行开发** | `dispatching-parallel-agents` `subagent-driven-development` | 派发并行子 agent、子 agent 驱动 |
| **Git 管理** | `git-workflow` `using-git-worktrees` | 分支管理、worktree 隔离 |
| **创意 & 规划** | `ten-round-brainstorm` `brainstorming` `prd` | 十轮头脑风暴、PRD 编写 |
| **后端模式** | `backend-patterns` `docker-patterns` `android-clean-architecture` | 后端架构模式 |
| **前端模式** | `frontend-patterns` `frontend-slides` `accessibility` | 前端架构模式 |
| **Agent 自身** | `agent-introspection-debugging` `agent-eval` `agent-harness-construction` | Agent 自省、评估、框架 |

**Skill 的结构：**
```
.agents/skills/tdd/
├── SKILL.md          # 技能定义（触发条件、执行步骤、输出格式）
├── rubric-template.md  # 评分模板（部分技能有）
└── README.md           # 说明文档（部分技能有）
```

**Skill 的工作原理：**
- Agent 读取 `SKILL.md` 获取行为指令
- 用户通过 `/tdd` 斜杠命令触发（命令定义在 `.agents/commands/tdd.md`）
- Skill 可组合：`/kd-review` 自动调用 `/super-pm` + `/e2e-archi` + 循环收敛

### ⌨️ Commands — 斜杠命令（28 个）

命令是 Skill 的快捷入口，放在 `.agents/commands/` 下。

| 命令 | 调用的技能 | 用途 |
|------|----------|------|
| `/tdd` | test-driven-development | TDD 红绿循环 |
| `/plan-template` | writing-plans + subagent | 方案模板 + 自动派发 §9 |
| `/e2e-archi` | architecture-review-e2e-tdd | 架构自检 + E2E 覆盖 |
| `/super-pm` | ux-product-review | 产品 + UX 结构化审查 |
| `/10-bs` | ten-round-brainstorm | 并行十轮头脑风暴 |
| `/kd-review` | super-pm + e2e-archi | 全自动审查循环直到零问题 |
| `/prd` | prd | 编写产品需求文档 |
| `/write-ex` | — | 提取会话经验归档 |
| `/flyway-squash` | — | Flyway 迁移整理 |
| `/merge-conflict` | — | 合并冲突（保留双方代码） |
| `/pr-all` `/pr-backend` `/pr-frontend` `/pr-operations` | git-workflow | MR 提交 |
| `/pull-all` `/push-all` | git-workflow | 拉取/推送 |
| `/mp-e2e` `/op-e2e` | e2e-testing | 小程序/运营后台 E2E |
| `/jx` | — | 继续被中断的任务 |

### 📐 工作流架构（Superpowers）

核心工作流定义在 `docs/superpowers/` 和 `docs/SUPERPOWERS.md` 中：

```
┌─────────────────────────────────────────────────────────┐
│                    Superpowers 工作流                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  /writing-plans ──→ 方案文档 ──→ /executing-plans         │
│       │                              │                   │
│       │    ┌── /architecture-review ─┤                   │
│       │    │                         │                   │
│       │    └── /ux-product-review    └──→ 代码实现        │
│       │                                    │             │
│       └── /10-bs (方案前头脑风暴)            │             │
│                                            ▼             │
│  /verification-before-completion ◄── /tdd (红绿循环)      │
│       │                                                  │
│       ▼                                                  │
│  /finishing-a-development-branch                         │
│       │                                                  │
│       ├── /requesting-code-review                        │
│       ├── /receiving-code-review                         │
│       └── /push-all → MR                                 │
│                                                          │
│  /kd-review = /super-pm + /e2e-archi × N (收敛循环)      │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 📏 开发规范文档

| 文档 | 说明 |
|------|------|
| `docs/SUPERPOWERS.md` | Superpowers 工作流总纲 |
| `docs/GIT_WORKFLOW.md` | Git 分支流与 MR 规范 |
| `docs/AGENT_RULES.md` | Agent 行为约束总则 |
| `docs/PROJECT_DOCUMENT_WRITING_SPEC.md` | 项目文档编写规范 |
| `docs/UI_SPEC_FOR_AGENTS.md` | Agent 理解的 UI 规格 |
| `docs/dev/test-spec.md` | 全栈测试规范 |
| `docs/dev/e2e-test-style-guide.md` | E2E 测试编写指南 |
| `docs/dev/JAVA_DEV_STANDARDS.md` | Java 开发规范 |
| `docs/dev/alibaba-java-development-manual.md` | 阿里巴巴 Java 开发手册 |
| `docs/dev/operation-backend-dev-standards.md` | 运营后台开发标准 |
| `docs/dev/debugging-protocol.md` | 系统性排障协议 |
| `docs/dev/figma-prototype-experience.md` | Figma 原型开发经验 |
| `docs/dev/saas-module-e2e-full-coverage-methodology.md` | SaaS E2E 全覆盖方法论 |

---

## 🚀 快速开始

### 方式一：命令行初始化（推荐）

```bash
# 1. 克隆到任意位置
git clone https://github.com/your-username/agent-fullstack-bio.git

# 2. 运行初始化脚本
cd your-project
/path/to/agent-fullstack-bio/init.sh
```

初始化脚本会：
- ✅ 复制 `.agents/` 目录到你的项目根目录
- ✅ 复制通用 `docs/` 到你的项目（已有 docs/ 则合并）
- ✅ 检测项目技术栈并生成基础 `CLAUDE.md`

### 方式二：手动复制

```bash
# 克隆
git clone https://github.com/your-username/agent-fullstack-bio.git

# 复制到你的项目（保留已有文件）
cp -rn agent-fullstack-bio/.agents /your-project/
cp -rn agent-fullstack-bio/docs /your-project/
```

### 方式三：作为 Git Submodule

```bash
cd your-project
git submodule add https://github.com/your-username/agent-fullstack-bio.git .agents-bio
ln -s .agents-bio/.agents .agents
```

### 方式四：Agent Prompt 初始化

在 Claude Code 对话中直接说：

```
请从 https://github.com/your-username/agent-fullstack-bio 读取 .agents/ 和 docs/ 目录，
将 skills 和 commands 复制到我的项目根目录的 .agents/ 下，将通用规范文档复制到 docs/ 下。
然后根据我的项目技术栈生成 CLAUDE.md。
```

或者在项目已有 `CLAUDE.md` 中添加一行引用：

```markdown
## Agent 工具集
- Skills 和 Commands 参见 `.agents/` 目录
- 开发规范参见 `docs/dev/` 目录
- 工作流总纲参见 `docs/SUPERPOWERS.md`
```

---

## 🏗️ 适用技术栈

| 层 | 技术 |
|----|------|
| 小程序前端 | uni-app (Vue 3), TypeScript, pnpm, Jest |
| 后端 | Java 17, Spring Boot 3.x, Maven, MyBatis-Plus, MySQL, Flyway, Redis |
| 运营后台 | Vue 3, Vite, TypeScript, Element Plus, Pinia, Playwright |
| E2E 测试 | 微信小程序 automator, Playwright |
| AI Agent | Claude Code, Cursor |

> 技能和规范本身是技术栈无关的。Java 规范可替换为 Go/Python 规范，uni-app 可替换为 Taro/RN。

---

## 📁 目录结构

```
agent-fullstack-bio/
├── README.md                           # 本文件
├── init.sh                             # 一键初始化脚本
├── .agents/
│   ├── .cursorrules                    # Cursor 规则
│   ├── skills/                         # 80+ AI 技能
│   │   ├── tdd/SKILL.md               # TDD 工作流
│   │   ├── systematic-debugging/       # 系统排障
│   │   ├── architecture-review-e2e-tdd/ # 架构审查
│   │   ├── dispatching-parallel-agents/ # 并行 agent
│   │   ├── ten-round-brainstorm/       # 十轮头脑风暴
│   │   ├── ux-product-review/          # UX 产品审查
│   │   └── ... (80+)
│   ├── commands/                       # 28 个斜杠命令
│   │   ├── plan-template.md           # 方案模板
│   │   ├── kd-review.md              # 全自动审查
│   │   ├── tdd.md                    # TDD 入口
│   │   └── ... (28)
│   └── rules/                          # 通用规则
│       ├── agent-hooks.md             # Agent 钩子
│       └── self-improve.md            # 自我改进
└── docs/
    ├── SUPERPOWERS.md                  # 工作流总纲
    ├── GIT_WORKFLOW.md                 # Git 工作流
    ├── AGENT_RULES.md                  # Agent 规则
    ├── dev/                            # 开发规范 (35+)
    │   ├── test-spec.md               # 测试规范
    │   ├── e2e-test-style-guide.md    # E2E 指南
    │   ├── JAVA_DEV_STANDARDS.md      # Java 规范
    │   └── ...
    └── superpowers/
        ├── GSTACK_AND_SUPERPOWERS.md   # 工作流引擎说明
        ├── PLAN_WRITING_CONTRACT.md    # 方案编写契约
        └── templates/                  # 方案模板
```

---

## 🤝 贡献

欢迎提交 PR：
- 新增 Skill → 在 `.agents/skills/` 下新建目录，包含 `SKILL.md`
- 新增 Command → 在 `.agents/commands/` 下新建 `.md`
- 新增规范 → 在 `docs/dev/` 下新建 `.md`

## 📄 License

MIT

---

**从实战中来，到实战中去** — 这不是 demo，是经过数百次 AI Agent 开发迭代验证的工具集。
