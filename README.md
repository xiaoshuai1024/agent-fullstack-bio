# Agent Fullstack Bio 🚀

> **AI Agent 全栈开发脚手架** — 从生产级多租户社交电商平台中提炼的技能库、工作流引擎与开发规范，一键注入新项目，让 AI 编码工具立刻拥有成熟的团队级开发工作流。

[![GitHub](https://img.shields.io/badge/GitHub-xiaoshuai1024%2Fagent--fullstack--bio-blue?logo=github)](https://github.com/xiaoshuai1024/agent-fullstack-bio)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 目录

- [为什么需要这个项目？](#为什么需要这个项目)
- [核心概念：从零理解 Agent 工作流](#核心概念从零理解-agent-工作流)
- [架构总览](#架构总览)
- [工作流详解](#工作流详解)
- [命令手册](#命令手册)
- [设计 Token 体系](#设计-token-体系)
- [技术栈与架构详解](#技术栈与架构详解)
- [快速开始](#快速开始)
- [目录结构](#目录结构)
- [贡献指南](#贡献指南)

---

## 为什么需要这个项目？

### 问题

当你用 AI Agent（Claude Code、Cursor 等）开发项目时：

| 痛点 | 表现 |
|------|------|
| **Agent 乱写代码** | 不写测试、不守规范、凭记忆改代码 |
| **没有工作流** | 想做 TDD 不知道怎么组织，做完了不知道怎么验证 |
| **质量无保障** | 没有审查循环，问题堆积到上线才发现 |
| **每次从零配置** | 换个项目，所有 Agent 配置又要重来一遍 |

### 解决方案

**agent-fullstack-bio** 把以下能力打包成**即插即用的知识库**：

```
80+ AI Skills（技能）  +  28 个 Slash Commands（命令）  +  35+ 开发规范文档
         ↓                    ↓                              ↓
    定义 Agent 行为      快捷触发工作流步骤           约束 Agent 输出质量
```

---

## 核心概念：从零理解 Agent 工作流

> 如果你是第一次接触 AI Agent 开发，从这里开始。

### 什么是 AI Agent？

AI Agent 不是简单的"对话式代码生成器"。它是一个**能够自主规划、执行、验证的开发伙伴**，但它需要明确的行为指令才能高效工作。

类比：
```
没有 Skills 的 Agent  = 一个聪明的实习生（能力强，但不知道团队规范）
有 Skills 的 Agent    = 一个熟悉团队流程的高级工程师
```

### 三个核心层

```
┌─────────────────────────────────────────────────┐
│  第 1 层：Skills（技能）                          │
│  定义 Agent "会做什么"                           │
│  例：怎么做 TDD、怎么做代码审查、怎么排障          │
│  格式：.agents/skills/tdd/SKILL.md               │
├─────────────────────────────────────────────────┤
│  第 2 层：Commands（命令）                        │
│  定义 "怎么触发" 一个技能或工作流步骤              │
│  例：输入 /tdd 触发 TDD 技能                     │
│  格式：.agents/commands/tdd.md                   │
├─────────────────────────────────────────────────┤
│  第 3 层：Rules & Docs（规则与规范）              │
│  定义 "不能做什么" 和 "应该怎么做"                │
│  例：禁止手动写 Flyway 版本号、必须 UTF-8 编码    │
│  格式：.agents/rules/ + docs/dev/                │
└─────────────────────────────────────────────────┘
```

### Skill 是什么？

一个 Skill 就是一个 `SKILL.md` 文件，告诉 Agent 在特定场景下的完整行为：

```markdown
# .agents/skills/tdd/SKILL.md

## 触发条件
用户要求开发新功能，或说 /tdd

## 执行步骤
1. 先写失败的测试（RED）
2. 写最少代码让测试通过（GREEN）
3. 重构优化（REFACTOR）
4. 循环直到所有测试通过

## 输出要求
- 每步都要运行测试并展示结果
- 最终汇报覆盖率
```

### Command 是什么？

Command 是 Skill 的快捷入口。用户输入 `/tdd`，Agent 就去读对应的 Skill 定义：

```markdown
# .agents/commands/tdd.md

description: 以 TDD 模式推进当前任务：红→绿→重构
---
加载 test-driven-development skill，按红绿重构循环执行
```

### 工作流是什么？

工作流是多个 Skills 和 Commands 的**有序组合**，模拟真实团队的开发流程：

```
一个完整的开发工作流：

/writing-plans     写方案
      ↓
/architecture-review  架构审查
      ↓
/executing-plans   执行实现
      ↓
/tdd               TDD 红绿循环
      ↓
/verification      完成前验证
      ↓
/code-review       代码审查
      ↓
/push-all          推送 MR
```

---

## 架构总览

### 系统架构图

```
                    ┌──────────────────────────┐
                    │      用户输入             │
                    │  /tdd  /plan  /review    │
                    └──────────┬───────────────┘
                               │
                    ┌──────────▼───────────────┐
                    │    Command Router         │
                    │  .agents/commands/*.md    │
                    │  匹配命令 → 加载对应 Skill │
                    └──────────┬───────────────┘
                               │
              ┌────────────────┼────────────────┐
              │                │                │
    ┌─────────▼──────┐ ┌──────▼───────┐ ┌──────▼───────┐
    │   Skill 执行    │ │  Skill 执行  │ │  Skill 执行  │
    │  TDD 红绿循环   │ │ 架构审查     │ │ 代码审查     │
    │                │ │              │ │              │
    │ 读 Rules ──────►│◄──── 读 Docs  │◄──── 读 Specs │
    └────────────────┘ └──────────────┘ └──────────────┘
              │                │                │
              └────────────────┼────────────────┘
                               │
                    ┌──────────▼───────────────┐
                    │    项目文件系统            │
                    │  代码 / 测试 / 配置 / DB  │
                    └──────────────────────────┘
```

### 文件到 Agent 行为的映射

```
项目根目录/
├── .agents/                          ← Agent 行为定义
│   ├── skills/                       ← 技能库（Agent 能力）
│   │   ├── tdd/SKILL.md             ← TDD 技能定义
│   │   ├── systematic-debugging/     ← 系统排障技能
│   │   └── ... (80+)
│   ├── commands/                     ← 命令（触发入口）
│   │   ├── tdd.md                   ← /tdd 命令
│   │   ├── plan-template.md         ← /plan-template 命令
│   │   └── ... (28)
│   └── rules/                        ← 规则（约束）
│       ├── agent-hooks.md           ← Agent 钩子规则
│       └── self-improve.md          ← 自我改进规则
├── .claude/                          ← Claude Code 配置
│   ├── settings.json                ← 权限白名单
│   ├── settings.local.json          ← 本地覆盖 + Hooks
│   └── mcp.json                     ← MCP 服务器配置
├── docs/                             ← 开发规范文档
│   ├── SUPERPOWERS.md               ← 工作流总纲
│   ├── GIT_WORKFLOW.md              ← Git 工作流
│   ├── AGENT_RULES.md               ← Agent 行为总则
│   └── dev/                          ← 开发规范
│       ├── test-spec.md             ← 测试规范
│       ├── e2e-test-style-guide.md  ← E2E 编写指南
│       └── ... (35+)
└── init.sh                           ← 一键初始化脚本
```

---

## 工作流详解

> 以下是从零开始，按真实开发顺序排列的完整工作流说明。

### 工作流 1：创意 & 规划阶段

当你有一个新想法或新需求，还没开始写代码时：

```
/10-bs（十轮头脑风暴）
    │
    │  从 10 个不同视角独立思考同一问题
    │  输出：综合结论 + 可行方案
    │
    ▼
/prd（编写产品需求文档）
    │
    │  按功能复杂度选取章节组合
    │  输出：PRD 文档（产品价值/成功指标/竞品分析/用户画像/Mermaid 流程图）
    │
    ▼
/writing-plans（编写技术方案）
    │
    │  基于产品需求编写技术方案
    │  输出：含 §9 实现任务派发的完整方案文档
    │
    ▼
/e2e-archi（架构自检）
       │
       │  审查方案中的架构问题
       │  检查项：分层合理性/事务边界/测试矩阵/安全合规/性能/可观测性
       │  输出：问题清单 + 修复建议
```

**触发方式**：对 Agent 说 "我要做一个 XXX 功能" 或输入 `/10-bs`

### 工作流 2：实现阶段

方案确定后，进入编码实现：

```
/executing-plans（执行方案）
    │
    │  读取方案文档，按 §9 任务列表逐步实现
    │  每个任务自动走 TDD 流程
    │
    ▼
/tdd（TDD 红绿循环）─────────────────────────┐
    │                                        │
    │  1. RED：写一个失败的测试               │
    │  2. GREEN：写最少代码让测试通过          │
    │  3. REFACTOR：重构优化                   │
    │  4. 如果还有功能未完成 ──────────────────┘
    │
    │  每步都运行测试并展示结果
    │  最终汇报覆盖率
    │
    ▼
/verification-before-completion（完成前验证）
    │
    │  检查清单：
    │  ✅ 所有测试通过
    │  ✅ 覆盖率达标
    │  ✅ 无遗留 TODO
    │  ✅ 代码规范合规
    │  ✅ 构建/编译成功
```

**触发方式**：对 Agent 说 "开始实现方案" 或输入 `/executing-plans`

### 工作流 3：质量保障阶段

代码写完后，进入质量闭环：

```
/super-pm（产品 UX 审查）
    │
    │  以 UX + 产品专家视角审查
    │  检查项：产品闭环/体验/规范对照/假功能排查
    │  输出：🔴 严重 🟡 建议 🔵 优化 三级问题列表
    │
    ▼
/kd-review（全自动审查循环）────────────────┐
    │                                       │
    │  并行派发 ~20 个审查 subagent          │
    │  每个 subagent 审查一个窄范围           │
    │  发现问题 → 立刻派修复 subagent         │
    │  修复后再审查                          │
    │  循环直到 🔴🟡🔵 全部清零 ─────────────┘
    │
    │  这是质量保障的终极武器
    │  平均需要 3-5 轮收敛
    │
    ▼
/requesting-code-review（请求代码审查）
    │
    │  生成审查请求，展示改动摘要
    │
    ▼
/finishing-a-development-branch（分支收尾）
       │
       │  整理提交信息、检查未提交文件
       │  构建 + 测试最终验证
       │  输出：分支状态报告
```

**触发方式**：输入 `/kd-review`（推荐）或逐步执行 `/super-pm` → `/e2e-archi`

### 工作流 4：合并 & 发布阶段

```
/push-all（推送所有子模块）
    │
    │  自动检测有改动的子模块
    │  按仓库自动生成 conventional commit message
    │  依次 add → commit → push
    │
    ▼
/pr-all（创建 MR）
    │
    │  对有改动的子仓库与主仓库
    │  依次 push → 创建 MR 到 dev
    │  有冲突则等待手动处理
    │
    ▼
/merge-conflict（解决冲突）
       │
       │  原则：保留双方代码
       │  逐文件展示方案并需用户确认
       │  合并后自动构建 + 测试
```

### 工作流 5：持续改进

```
/write-ex（提取经验）
    │
    │  自动提取当前会话中的排障经验
    │  归类追加到 docs/dev/ 对应规则文件
    │  写入持久化记忆
    │
    │  例：发现 Flyway 迁移不能 DROP TABLE
    │  → 自动追加到 kangdou-flyway-migration-standards.md
    │  → 下次 Agent 读到这个文件就知道不能 DROP TABLE
```

### 组合工作流速查

| 场景 | 推荐命令序列 | 估计耗时 |
|------|-------------|---------|
| 新功能从零到 MR | `/10-bs` → `/plan-template` → `/executing-plans` → `/kd-review` → `/pr-all` | 2-4h |
| 快速修 Bug | `/systematic-debugging` → 修复 → `/verification-before-completion` → `/push-all` | 15-30min |
| 方案评审 | `/super-pm` + `/e2e-archi` | 10-20min |
| 全量质量检查 | `/kd-review`（自动循环收敛） | 20-40min |
| 经验沉淀 | `/write-ex` | 2min |

---

## 命令手册

### 开发流程命令

| 命令 | 说明 | 详细行为 |
|------|------|---------|
| `/tdd` | TDD 模式开发 | 🔴 写失败测试 → 🟢 最少代码通过 → 🔵 重构 → 循环。每步展示测试结果，最终汇报覆盖率 |
| `/plan-template` | 编写技术方案 | 加载方案模板，引导填入验收标准/UI规格/API契约/DDL/组件接口，定稿后自动派发 subagent 填充 §9 实现细节 |
| `/executing-plans` | 执行方案实现 | 读取方案文档 §9 任务列表，逐任务实现，每个任务自动走 TDD |
| `/jx` | 继续中断的任务 | 恢复上次被异常中断的任务上下文，从断点继续执行 |

### 质量保障命令

| 命令 | 说明 | 详细行为 |
|------|------|---------|
| `/kd-review` | **全自动审查循环** | 核心质量命令。并行派发 ~20 个审查 subagent（产品闭环/UX/安全/性能/架构/E2E覆盖），发现问题即派修复 agent，循环直到零问题收敛 |
| `/super-pm` | 产品 UX 审查 | 以产品专家视角，按 rubric 评分：产品闭环(25分)+体验(25分)+规范(25分)+交付(25分)，输出 🔴🟡🔵 问题列表 |
| `/e2e-archi` | 架构 + E2E 自检 | 9 维度审查：分层合理性/关键行为追踪/事务边界/测试矩阵/安全合规/性能/可观测性/依赖治理/历史事故回归 |
| `/ux-product-review` | UX 产品审查 | 加载 ux-product-review skill，按交付契约做产品/UX/交付审查 |
| `/verification-before-completion` | 完成前验证 | 检查所有测试通过、覆盖率达标、无遗留 TODO、构建成功 |
| `/write-ex` | 经验提取 | 将当前会话的排障经验归类追加到 docs/dev/ 对应规则 + 持久化记忆 |

### 创意 & 规划命令

| 命令 | 说明 | 详细行为 |
|------|------|---------|
| `/10-bs` | 十轮头脑风暴 | 并行 10 个独立视角思考同一问题（成本/性能/体验/安全/扩展性/竞品/...），综合输出结论 |
| `/prd` | 编写 PRD | 按功能复杂度选取章节，含产品价值/成功指标/竞品分析/用户画像/优先级/Mermaid 流程图 |

### Git & MR 命令

| 命令 | 说明 | 详细行为 |
|------|------|---------|
| `/push-all` | 推送所有子模块 | 自动检测改动，按仓库生成 conventional commit，依次 add → commit → push |
| `/pull-all` | 拉取所有子模块 | 拉取目标分支（默认 dev）到当前分支 |
| `/pr-all` | 全部创建 MR | 对所有有改动的子仓库 + 主仓库依次 push → 创建 MR 到 dev |
| `/pr-backend` | 仅后端 MR | 只提交 backend/ 子仓库并创建 MR |
| `/pr-frontend` | 仅前端 MR | 只提交 frontend/ 子仓库并创建 MR |
| `/pr-operations` | 仅运营后台 MR | 只提交 operation-backend/ 并创建 MR |
| `/pr-fullstack` | 仅主仓库 MR | 只提交 kangdou-fullstack 主仓库并创建 MR |
| `/merge-branch` | 合并分支 | 交互式多仓库合并：review → merge → 修复 → changelog |
| `/merge-conflict` | 解决冲突 | 原则保留双方代码，逐文件展示方案需确认，合并后构建+测试 |

### 测试命令

| 命令 | 说明 | 详细行为 |
|------|------|---------|
| `/mp-e2e` | 小程序 E2E | 微信小程序 automator 端到端测试，依赖后端 8080，含环境预检 |
| `/op-e2e` | 运营后台 E2E | Playwright 端到端测试，默认无头模式，TDD + 失败先收集再分析 |

### 其他命令

| 命令 | 说明 | 详细行为 |
|------|------|---------|
| `/flyway-squash` | Flyway 迁移整理 | 评估 squash 可行性，本地执行 squash，共享库/生产仅输出指导 |
| `/feishu-doc` | 上传飞书文档 | 将本地 Markdown 上传到飞书企业知识库指定目录 |
| `/effort` | 调整用力档位 | 设定 Agent 推理/执行深度（等价 Claude Code /effort） |
| `/codex-insights` | 开发洞察摘要 | 读取本机 claude projects jsonl 生成 insight 摘要 |

---

## 设计 Token 体系

本项目包含一套完整的 **Design Token 系统**，实现主题化、多租户品牌色切换。

### 三层 Token 架构

```
JSON 源（DTCG 格式，手动编辑入口）
├── global/color-space.json    — 全局色板（green/amber/red/blue 等 ramp）
├── alias/core.json            — 语义别名（引用 global 色板）
├── comp/semantic.json         — 组件级 token（button/input/card）
└── themes/{name}.json         — 主题覆盖（只输出差异）

        ↓  node scripts/build-tokens.mjs

生成的 CSS
├── variables.css              — 默认绿色主题（page {}）
├── theme-{name}.css           — 各主题覆盖（.kd-theme-{name} {}）
├── utilities.css              — 工具类（.kd-glass-card, .kd-skeleton 等）
└── theme-catalog.ts           — 主题元数据（TypeScript）
```

### 品牌色 Token

| Token | 值 | 用途 |
|-------|-----|------|
| `--kd-color-primary` | `#00B341` | 品牌绿，主按钮、选中态、聚焦环、价格、链接 |
| `--kd-color-primary-light` | `#34D399` | hover 态底色 |
| `--kd-color-primary-dark` | `#047857` | 按压态 |
| `--kd-color-primary-subtle` | `rgba(0,179,65,.08)` | 极淡绿底 |
| `--kd-color-primary-soft` | `rgba(0,179,65,.12)` | 淡绿底 |
| `--kd-color-primary-glow` | `rgba(0,179,65,.18)` | 绿色发光 |

### 语义色 Token

| Token | 值 | 用途 |
|-------|-----|------|
| `--kd-color-accent` | `#FFD554` | 活力黄，促销、次要强调 |
| `--kd-color-danger` | `#DC2626` | 警示、错误、删除 |
| `--kd-color-info` | `#2563EB` | 信息提示 |
| `--kd-color-success` | `#27AE60` | 成功 |
| `--kd-color-warning` | `#F59E0B` | 警告 |

### 面 & 背景 Token

| Token | 值 | 用途 |
|-------|-----|------|
| `--kd-surface` | `#FFFFFF` | 白色面板 |
| `--kd-surface-elevated` | `#FAFAFA` | 抬高面 |
| `--kd-surface-hover` | `#F5F5F5` | hover 态 |
| `--kd-surface-dim` | `#E5E5E5` | 沉底面 |

### 文字色 Token

| Token | 值 | 用途 |
|-------|-----|------|
| `--kd-color-text` | `#1a1a2e` | 主文案 |
| `--kd-color-text-secondary` | `#737373` | 次要文案 |
| `--kd-color-text-tertiary` | `#A3A3A3` | 辅助文案、占位符 |
| `--kd-color-text-inverse` | `#FFFFFF` | 反色文案 |

> 完整 Token 速查见 `docs/dev/kangdou-design-tokens.md`

---

## 技术栈与架构详解

本项目提炼自一个**生产级多租户社交电商平台**，以下是完整的技术栈和架构说明。

### 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                      平台治理层                              │
│   租户生命周期 · 策略发布 · 配额控制 · 平台运营               │
├─────────────────────────────────────────────────────────────┤
│                      租户经营层                              │
│   用户中心 · 交易中心 · 资产中心 · 营销履约 · 内容管理        │
├──────────────┬──────────────────────┬───────────────────────┤
│  小程序触点   │    运营后台触点       │    商家端触点          │
│  uni-app     │    Vue 3 + Vite      │    uni-app            │
│  (C 端用户)  │    Element Plus      │    (B 端商户)         │
├──────────────┴──────────────────────┴───────────────────────┤
│                      后端服务层                              │
│   Spring Boot 3.3 · MyBatis-Plus · MySQL · Redis · RabbitMQ │
├─────────────────────────────────────────────────────────────┤
│                      基础设施层                              │
│   Flyway(DB迁移) · Elasticsearch(搜索) · 七牛(存储)          │
│   微信支付(服务商模式) · 微信开放平台(第三方平台)              │
└─────────────────────────────────────────────────────────────┘
```

### 后端架构（Java / Spring Boot）

```
backend/
├── config/              全局配置（CORS、Security、Swagger、Redis）
├── tenant/              多租户核心
│   ├── auth/            认证（微信登录、JWT、第三方平台 OAuth）
│   ├── pay/             支付（微信支付服务商模式、分账、退款）
│   ├── trade/           交易（订单、商品、店铺、购物车）
│   ├── social/          社交（圈子、活动、会员、动态）
│   ├── talent/          达人（CPS 分佣、推广）
│   └── merchantcenter/  商家端
├── ops/                 运营后台 API（RBAC 权限保护）
│   ├── auth/            运营端认证（管理员、角色、权限）
│   ├── trade/           交易运营
│   ├── user/            用户管理
│   └── saas/            SaaS 租户管理
├── home/                首页（楼层、Banner）
├── im/                  即时通讯
├── error/               统一错误处理（AppException + ApiErrorCode）
├── cache/               Redis 缓存策略
├── logging/             日志（RequestId 链路追踪）
└── db/migration/        Flyway 版本化迁移
```

**分层规范：**
```
Controller (@RestController, Swagger @Operation)
    ↓
Service (@Transactional, 领域逻辑)
    ↓
Repository (MyBatis-Plus + XML Mapper)
    ↓
Database (Flyway 版本迁移)
```

### 小程序前端架构（uni-app / Vue 3）

```
frontend/
├── src/
│   ├── pages/           页面（Tab: 首页 | 动态 | 发布 | 我的）
│   │   ├── home/        首页楼层
│   │   ├── circle/      圈子（20+ 页面）
│   │   ├── trade/       订单、退款、商品
│   │   ├── merchant/    商家中心
│   │   └── im/          即时通讯
│   ├── api/             API 调用层
│   ├── components/      通用组件
│   ├── composables/     组合式函数（页面级状态，无全局 Store）
│   ├── styles/tokens/   Design Token 系统
│   │   ├── json/        Token 源文件（DTCG 格式）
│   │   └── generated/   构建产物（CSS 变量）
│   └── e2e/             小程序 automator E2E
├── scripts/             构建脚本（token 构建、Flyway 辅助）
└── e2e/miniprogram/     微信小程序 automator E2E 测试
```

### 运营后台架构（Vue 3 / Element Plus）

```
operation-backend/
├── src/
│   ├── views/           页面（租户管理、交易运营、资金运营、策略配置）
│   ├── components/      通用组件（KdImageUpload, OpsPageTenantField）
│   ├── stores/          Pinia 状态管理
│   ├── api/             API 调用层
│   └── router/          路由（RBAC 动态路由）
├── tests/e2e/           Playwright E2E 测试
└── scripts/             跨系统验证脚本
```

### 测试架构

```
┌───────────────────────────────────────────────────────────┐
│                    E2E 测试层                              │
│  微信小程序 automator    │    Playwright（运营后台）         │
│  模拟真实用户操作         │    模拟管理员操作                │
├───────────────────────────────────────────────────────────┤
│                    单元测试层                              │
│  Jest（前端）    │    Vitest（运营后台）   │   JUnit（后端） │
│  覆盖率 85%     │    覆盖率 90%          │   覆盖率 95%    │
├───────────────────────────────────────────────────────────┤
│                    构建门禁                                │
│  编译通过 + 测试通过 + 覆盖率达标 = 才能合并 MR              │
└───────────────────────────────────────────────────────────┘
```

### 多租户架构

```
请求 → TenantFilter → 注入 X-Tenant-Id → 全链路租户隔离
                                                    ↓
                              DB: 所有表含 tenant_id 列
                              Cache: Redis Key 含 tenant 前缀
                              支付: 微信支付服务商模式（子商户）
                              小程序: 每个租户独立 AppId
```

### Git 多仓库架构

```
kangdou-fullstack/          ← Git Superproject（主仓库）
├── backend/                ← Git Submodule（后端）
├── frontend/               ← Git Submodule（小程序前端）
├── operation-backend/      ← Git Submodule（运营后台）
├── .agents/                ← Agent 技能和命令
├── docs/                   ← 开发规范文档
└── Makefile                ← 一键开发/测试/部署
```

---

## 快速开始

### 方式一：命令行初始化（推荐）

```bash
# 克隆
git clone https://github.com/xiaoshuai1024/agent-fullstack-bio.git

# 在你的项目中运行初始化
cd your-project
/path/to/agent-fullstack-bio/init.sh
```

`init.sh` 会自动：
- ✅ 复制 `.agents/`（技能 + 命令 + 规则）到你的项目
- ✅ 合并通用 `docs/`（开发规范 + 工作流文档）
- ✅ 生成 `.claude/` 配置模板
- ✅ 检测项目类型并生成基础 `CLAUDE.md`

### 方式二：手动复制

```bash
git clone https://github.com/xiaoshuai1024/agent-fullstack-bio.git

# 完整复制
cp -rn agent-fullstack-bio/.agents /your-project/
cp -rn agent-fullstack-bio/.claude /your-project/
cp -rn agent-fullstack-bio/docs /your-project/
```

### 方式三：选择性复制

```bash
# 只要技能
cp -r agent-fullstack-bio/.agents/skills /your-project/.agents/skills

# 只要 Claude Code 配置
cp -r agent-fullstack-bio/.claude /your-project/.claude

# 只要 E2E 测试规范
cp agent-fullstack-bio/docs/dev/e2e-test-style-guide.md /your-project/docs/
```

### 方式四：Agent Prompt 初始化

在 Claude Code 中直接说：

```
请从 https://github.com/xiaoshuai1024/agent-fullstack-bio 读取项目结构，
将 .agents/ 和 .claude/ 和 docs/ 复制到我的项目根目录，
然后根据我的技术栈调整 CLAUDE.md。
```

### 在 CLAUDE.md 中引用

```markdown
## Agent 工具集

- **Skills**: `.agents/skills/` — 80+ AI 技能
- **Commands**: `.agents/commands/` — 28 个斜杠命令
- **Rules**: `.agents/rules/` — 行为约束
- **规范**: `docs/dev/` — 开发规范文档
- **工作流**: `docs/SUPERPOWERS.md` — 工作流总纲
```

---

## 目录结构

```
agent-fullstack-bio/
├── README.md                            ← 本文件
├── init.sh                              ← 一键初始化脚本
│
├── .agents/                             ← Agent 行为定义
│   ├── .cursorrules                     ← Cursor 规则
│   ├── skills/                          ← 80+ AI 技能
│   │   ├── tdd/SKILL.md                ← TDD 红绿循环
│   │   ├── systematic-debugging/        ← 系统排障
│   │   ├── architecture-review-e2e-tdd/ ← 架构审查 + E2E
│   │   ├── dispatching-parallel-agents/ ← 并行 agent 派发
│   │   ├── ten-round-brainstorm/        ← 十轮头脑风暴
│   │   ├── ux-product-review/           ← UX 产品审查
│   │   ├── coding-agent/               ← 编码子 agent
│   │   ├── writing-plans/              ← 方案编写
│   │   ├── executing-plans/            ← 方案执行
│   │   └── ... (80+)
│   ├── commands/                        ← 28 个斜杠命令
│   │   ├── plan-template.md            ← /plan-template
│   │   ├── kd-review.md               ← /kd-review
│   │   ├── tdd.md                     ← /tdd
│   │   ├── super-pm.md                ← /super-pm
│   │   ├── 10-bs.md                   ← /10-bs
│   │   └── ... (28)
│   └── rules/                           ← 通用规则
│       ├── agent-hooks.md              ← Agent 钩子
│       └── self-improve.md             ← 自我改进
│
├── .claude/                             ← Claude Code 配置
│   ├── settings.json                   ← 权限白名单模板
│   ├── settings.local.json             ← 本地覆盖 + Hooks 模板
│   └── mcp.json                        ← MCP 服务器配置模板
│
└── docs/                                ← 开发规范文档
    ├── SUPERPOWERS.md                   ← 工作流总纲
    ├── GIT_WORKFLOW.md                  ← Git 工作流
    ├── AGENT_RULES.md                   ← Agent 规则
    ├── PROJECT_DOCUMENT_WRITING_SPEC.md ← 文档编写规范
    ├── UI_SPEC_FOR_AGENTS.md            ← Agent 理解的 UI 规格
    ├── dev/                             ← 35+ 开发规范
    │   ├── test-spec.md                ← 全栈测试规范
    │   ├── e2e-test-style-guide.md     ← E2E 编写指南
    │   ├── JAVA_DEV_STANDARDS.md       ← Java 开发规范
    │   ├── alibaba-java-development-manual.md ← 阿里巴巴规范
    │   ├── kangdou-design-tokens.md    ← Design Token 完整速查
    │   ├── debugging-protocol.md       ← 排障协议
    │   ├── figma-prototype-experience.md ← Figma 原型经验
    │   └── ... (35+)
    └── superpowers/                     ← 工作流引擎
        ├── GSTACK_AND_SUPERPOWERS.md    ← 工作流引擎说明
        ├── PLAN_WRITING_CONTRACT.md     ← 方案编写契约
        └── templates/                   ← 方案模板
```

---

## 贡献指南

欢迎提交 PR：

- **新增 Skill** → `.agents/skills/<name>/SKILL.md`
- **新增 Command** → `.agents/commands/<name>.md`
- **新增规范** → `docs/dev/<name>.md`
- **修复/改进** → 直接 PR

## License

MIT

---

**从实战中来，到实战中去** — 这不是 demo，是经过数百次 AI Agent 开发迭代验证的工具集。
