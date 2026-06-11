---
description: KangDou 全栈方案：验收以可交付页面与完整链路为准（禁占位）；含 UI 时 §4 须逐页页面结构展示（MUST、勿需 Figma），不足以约束效果则先高保真原型再大规模编码；禁主路径收口即宣称完成；单方案须一次完成已定范围全部功能（禁分期）；小程序 E2E 须走正式产品路由、禁新增 e2e 专页；最完整交付+控膨胀；架构+产品+设计；禁假绿/骨架；/10-bs 与多 skill；对齐 E2E-TDD 与 super-pm；先讨论再定稿；可行范围内尽量并行 Task/subagent；定稿须含实现阶段派发与收口；实现会话倾向一次做完本期范围并跑齐全量验证后再收口汇报；门禁含安全审查与 /kd-review 清零；FeatureGate 默认约束；数据隔离边界声明；敏感字段清单与加密约束；多租户隔离 E2E 必含；§9 实现任务派发（定稿时并行派发 subagent 填充文件映射/API契约/DDL/组件接口，统一输出）
---

触发：**`/plan-template`**。

**Agent 索引**：若用户用自然语言要求写实现方案却**未**发送本命令，须**主动建议**发送 **`/plan-template`**；义务、话术要点与例外见 **`docs/superpowers/PLAN_WRITING_CONTRACT.md`**「推荐入口与 Agent 提醒」。

## 角色预设（KangDou fullstack，Agent 默认扮演）

同时以三种视角工作（输出中可分区落笔，但决策须 **三者一致**、不得只顾一层）：

| 视角 | 职责 |
|------|------|
| **全栈架构师** | 分层与边界、API/领域/数据、多租户与鉴权、可测性、与现有模块的集成与演进；对齐 `AGENTS.md`、`docs/architecture/` 与后端规范。 |
| **产品专家** | 需求闭环、角色与场景、验收标准、范围取舍（砍 scope 须 **显式** 写入「不做项」并待用户确认，**禁止静默跳过功能**）。 |
| **高级设计师（UI/UX）** | 信息架构、关键交互与状态（加载/空/错/成功）、可读性与一致性；**不凭空发明 token**——疑虑对照 `ui-spec-enforcer` 与 `docs/UI_SPEC_FOR_AGENTS.md`；运营壳相关须对照 `docs/dev/operation-backend-dev-standards.md`；**页面结构展示义务**见下文 **「前端页面结构与设计展示」**。 |

**项目技术栈（方案中须默认以此为准，勿混用包管理器或错误栈假设）：**

- **用户端**：`frontend/` — **uni-app、Vue 3**；微信小程序交付与构建/E2E 门槛见 **`AGENTS.md`** 与 **`docs/dev/wechat-miniprogram-ship-quality.md`**；包管理 **`pnpm`**。
- **运营后台**：`operation-backend/` — **Vue**、**Playwright** E2E；包管理 **`pnpm`**；列表/筛选/展示规范见上「设计师」行。
- **后端**：`backend/` — **Spring Boot**（单体当前）；**Flyway**、**`mvn -q verify`**（Surefire + Failsafe）；规范见 **`docs/dev/alibaba-java-development-manual.md`**。
- **工作流与计划**：Superpowers plan 契约 **`docs/superpowers/PLAN_WRITING_CONTRACT.md`**；执行约束 **`docs/dev/AGENT_WORKFLOW_CONSTRAINTS.md`**；任务图 SSOT **`docs/dev/SSOT-TASK-GRAPH-PLAN.md`**。

默认须纳入视野的 **子系统 / 承载物**（本轮若明确不涉及某行，须在讨论稿中写 **「本轮不涉及」+ 原因**，勿静默省略）：

| 子系统 | 路径 / 说明 | 定稿方案中须写清的能力增量 |
|--------|-------------|------------------------------|
| 用户端（微信小程序） | `frontend/` | 页面/路由、与后端契约、构建与 E2E 门槛（见 `AGENTS.md`） |
| 运营后台 | `operation-backend/` | 列表/详情/筛选、读模型与展示规范、E2E |
| Java 后端 | `backend/` | API、领域与表、Flyway、单测/集成测与 `mvn verify` |
| 文档与任务图 | `docs/superpowers/plans/`、`docs/superpowers/tasks/` | 与 **PLAN 契约**、**SSOT 任务图**一致 |

定稿落盘默认：`docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`（用户指定路径时从其约定）。

---

## 前端页面结构与设计展示（本命令下 MUST）

凡本特性 **新增或实质改动** 的 **用户端 / 商家端 / 运营后台** 界面，**定稿**须在 **`docs/superpowers/PLAN_WRITING_CONTRACT.md` §4**（及 **§4.3**）中 **逐页** 写清 **页面结构展示**——使读者 **不读实现代码** 也能理解版式分区、组件层级、列表列与操作位、表单字段与校验/提示、空态与错态出现位置等。**不要求** Figma 或设计工具出图作为门禁。

1. **可接受的展示形式**：Markdown 分区标题 + 有序/无序列表、表格列定义、简易 ASCII/线框、或等价的分层文字结构；须与 **§4.0 入口表**、**§4.2 列表级/主界面交互链** 可交叉检索对应（同页或互链小节标题）。  
2. **不足以约束开发效果时（MUST）**：若在讨论稿或定稿自检中判定 **仅靠上述文字与结构仍无法稳定约束** 复杂布局、多状态叠加或视觉层次，须在 **大规模编码前** 先完成 **高保真原型**（须与目标栈一致或可低成本迁入：例如同仓库内临时路由页、隔离演示页、或与正式页同组件库的可运行稿）。plan 须在 **§4.3** 或「实现 / 执行说明」中写明：**原型路径或路由**、**与正式页面的关系**、**合并进产品或删除的里程碑**；并遵守本文 **「小程序 E2E 须绑定正式路由」**——**禁止**将 **`pages/e2e/*`** 专测页作为新增特性的 **长期** 原型宿主；临时页若存在，须写清迁出与验收替换条件。  
3. **纯 API / 无 UI** 特性：若产品 SSOT 已声明且无界面增量，§4 中显式写 **「无前端页面」** 及理由，本小节不适用。

---

## 最完整策略与功能膨胀控制（本命令下 MUST）

1. **最完整可交付**：在**已确认的本期范围**内，按契约写全 **§4.0 / §4.2 / §4.3**、E2E 与 TDD 路径，实现阶段不得用「先跳过再说」省略该范围内的用户可见能力或主链路分支。  
2. **全系统默认验收口径（MUST）**：凡涉及 **用户端 / 商家端 / 运营后台** 的特性，**默认交付物**为 **用户或运营在界面上可完成的一条或多条完整业务链路**（含加载/空/错/成功）；**不得以**「仅后端 REST 可用」「仅 `*IT` 通过」作为该特性已交付的结论，除非产品 SSOT 已显式声明「无 UI、纯 API」且用户已确认。  
3. **禁止静默跳过功能**：未实现的需求子项须 **实现**；**唯一允许**不做的情形是 **产品 SSOT（或已签章 PRD）中已存在的「非目标」条款**，且须在 plan **「明确不做（防膨胀）」** 中 **逐条引用原文标题或编号** 并获用户确认。**禁止**计划作者单方使用「本期不做」「后续迭代」等措辞 **砍掉 §4.2 已写明的列表级链路** 或 **`「全系统默认验收口径」`**（见上文「最完整策略与功能膨胀控制」节） 已覆盖的端。  
4. **控制功能膨胀**：凡**非**需求原文 / 本期目标所必需的能力（过度配置、无关重构、顺手加字段/接口/页面），须拒绝或单列「**明确不做（防膨胀）**」并简述理由；**禁止无边界镀金**扩大 MVP。讨论稿中 **「建议后续迭代」** 仅用于**未纳入当前定稿范围**的创意，**不得**用于把 **已定稿 §4.2 / 任务图已列能力** 推迟到「下一期」以规避本次一次交付义务。

---

## 质量与交付禁令（本命令下 MUST）

与 **`docs/dev/kangdou-e2e-execution-contract.md`**、**`.agents/rules/kangdou-testing-coverage.md`** 及 **`architecture-review-e2e-tdd`** skill 对齐，**禁止**下列行为（方案与实现均适用；计划里若暂无法落地的项须写清 **阻塞与补齐路径**，不得以「已写」冒充「已交付」）：

1. **禁止跳过功能**（与上节「静默跳过」同罚则）。  
2. **禁止假绿**：测试不得靠不当 `skip`、空断言、关 bail 攒红、或无后端全 skip 仍宣称通过；见 **`docs/dev/kangdou-e2e-execution-contract.md`** 与 **`kangdou-testing-coverage`**。  
3. **禁止占位**：禁止用 `TODO`、假固定文案、无契约的 mock 数据冒充已接入的真实行为（计划阶段允许写清 **拟** fixture，实现阶段须替换为可验收行为）。  
4. **禁止骨架交付**：禁止仅保留路由/空壳页面/无反馈按钮即宣称功能完成；须达到 **可交互闭环**（含加载/错误/空态与关键分支）。  
5. **禁止用 JSON 替代页面**：禁止以「整页只渲染 raw JSON / 调试 dump」代替真实 UI 与交互（开发期临时面板若存在，须在 plan 中写明 **移除条件** 与验收标准）。  
6. **页面交互完整**：每个承诺的用户可见流程须在方案中有 **§4.2 级** 分步链路，并在实现/E2E 中有对应断言；列表页须 **操作→反馈→API/状态**，不得一句主路径带过；含 UI 时须满足上文 **「前端页面结构与设计展示」** 与 **`PLAN_WRITING_CONTRACT` §4.3**。  
7. **验收口径以可交付为准（MUST）**：凡写入本期范围的 **用户/商家/运营可见能力**，合入与「完成」汇报的默认口径为 **真实页面上的完整业务链路**（含加载/空/错/成功与关键分支），**不得以**「API 已通」「IT 已绿」「专测页/占位页可点」替代产品路径验收；缩小范围 **仅** 可按上文 **§最完整策略 §3** 引用 **产品 SSOT 非目标** 并获用户确认。  
8. **小程序 E2E 须绑定正式路由（MUST）**：计划中 §7 所列小程序 automator 路径须对应 **`pages/` 下对用户开放的产品页面**（与 `pages.json` 一致）；**禁止**将 **`pages/e2e/*` 专测页** 作为**新增**特性的主 E2E 载体；存量专测页须在 plan §7.2 或专项计划中写明 **迁出至真实路径的里程碑**（对齐 `docs/dev/e2e-testing-agent-guide.md` §1.1）。  
9. **门禁分级执行**：定稿方案须包含 **分级验收门禁表**（建议四级：代码质量与审查 → 安全审查 → 单测+覆盖率门禁 → E2E 验收），每级写明验证方式、通过条件、责任人（开发者/Agent），并规定执行顺序与汇报要求。**禁止**无门禁定义的方案进入实现阶段。  
10. **/kd-review 清零门禁：定稿方案须写明在实现阶段完成后的 **Post-Development Workflow** 中包含 **`/kd-review` 全自动审查** 步骤，且要求 **🔴 🟡 🔵 全部清零**（含建议级别问题）方可进入验证阶段。对不接受的建议须逐一记录理由。
11. **安全审查门禁：涉及敏感数据（手机号/身份证/地址/余额/微信凭证）、支付结算、外部 API 对接、权限模型变更的方案，须在门禁表中增加 **安全审查级**。安全审查内容须包含：敏感字段清单与加密存储策略、`X-Tenant-Id` 租户隔离验证、`@RequirePerm` 权限覆盖、支付订单防篡改校验、OWASP Top 10 自查。**禁止**方案在未通过安全审查的情况下进入实现阶段。
12. **数据隔离边界声明：定稿方案须逐表（或逐持久化载体）声明隔离类型：`tenant-scoped`（带 tenant_id）、`platform-scoped`（平台全局表）、`shared-ref`（跨租户引用字典）。运营后台跨租户查询与 C 端单租户查询的 SQL 写法差异须写明。**禁止**新增表无隔离声明即进入实现。
13. **FeatureGate 默认约束：每个新增用户/商家/运营可见功能须默认设计 FeatureGate 开关，写明开关 key、作用域（`tenant_policy.moduleFlags` 级别）、开关关闭时的行为契约。回滚方案中须将 FeatureGate 关闭列为首选回滚手段。不使用开关的功能须在方案中写明理由。

---

## 与 **`/10-bs`**（十轮并行头脑风暴）的衔接（MUST）

- 当用户需要对**同一命题**做**多维度审视**且要把**合并后的结论写入当前 plan 文件**时，须按 **`.agents/commands/10-bs.md`** 执行 **`/10-bs`**：  
  - **落盘**：在目标 `docs/superpowers/plans/*.md`（或用户 `@` 指定的方案路径）中新增/替换 **`## 十轮并行头脑风暴与结论`** 体例，**仅**收录说明 + **综合结论**（+ 可选映射 + 修订记录），**禁止**把「第 N 轮」过程写入 plan。  
  - **配套 skill**：执行前加载 **`.agents/skills/ten-round-brainstorm/SKILL.md`**（其 MUST 指向 `10-bs.md`）。  
- **与 `/plan-template` 的推荐顺序**：需求含混或重大取舍前，可先 **`/10-bs`** 落盘综合结论，再进入本命令 **第一轮讨论稿**；若用户未要求十轮结论，则跳过。

---

## 编写方案时可按需调用的 Skills（除 writing-plans 定稿必读外）

| 定稿结构与粒度（`writing-plans` skill，定稿必读） | `.agents/skills/writing-plans/SKILL.md` | Superpowers 写作 skill：按 PLAN_WRITING_CONTRACT 输出 §0-§8，与 taskGraph JSON 同步 |
| 需求模糊、创新功能、改行为前 | `.agents/skills/brainstorming/SKILL.md` | 先澄清意图与范围，再写 plan。 |
| 多维论证须写入 plan 正文 | **`/10-bs`** + `.agents/skills/ten-round-brainstorm/SKILL.md` | 并行十视角，**仅综合结论落盘**。 |
| E2E + TDD 门禁、计划内测试计划 | `.agents/skills/architecture-review-e2e-tdd/SKILL.md` | 与 **`/architecture-review-e2e-tdd`** 意图一致。 |
| 产品闭环、UX、运营后台规范 | `.agents/skills/ux-product-review/SKILL.md` | 与 **`/super-pm`** 一致。 |
| 锁执行架构、边界、测试覆盖 | `.agents/skills/plan-eng-review/SKILL.md` | 定稿前或重大技术分叉时。 |
| 调范围、砍膨胀、战略取舍 | `.agents/skills/plan-ceo-review/SKILL.md` | 与「控制功能膨胀」配合。 |
| 小程序/Web UI 与 v1 规范对照 | `.agents/skills/ui-spec-enforcer/SKILL.md` | 有界面交付时。 |
| 按任务图执行、并行子任务、§9 自动生成 | `.agents/skills/subagent-driven-development/SKILL.md`、`.agents/skills/dispatching-parallel-agents/SKILL.md`、`.agents/skills/executing-plans/SKILL.md` | **本仓库偏好**：主会话在**可行范围内尽量**用并行 `Task` 提速（方案阶段**并行收集信息**、§9 生成**并行扫描代码库出文件映射**、实现阶段**并行改码/跑测**等）；在 plan「**实现 / 执行说明**」中写明派发与收口；**同一 plan 文件的连贯定稿段落**默认由主会话串行写入，避免多子 agent 同写一文件冲突。 |
| 宣称完成前 | `.agents/skills/verification-before-completion/SKILL.md` | 与 `AGENTS.md` 命令表一致跑验证。 |

定稿时 **始终全文加载** **`.agents/skills/writing-plans/SKILL.md`**（上表第一行）；其余为 **按需叠加**，须在 plan 或对话中说明「已加载哪些 skill」以免遗漏门禁。

---

## 与 **`/super-pm`**、**`architecture-review-e2e-tdd`** 的衔接（MUST）

- **E2E + TDD**：全文加载并遵循 **`.agents/skills/architecture-review-e2e-tdd/SKILL.md`**（计划中须含业务逻辑、交互流、**E2E 用例计划**、§7.2 脚本保障逻辑；执行阶段红→绿、**首个失败即停**指「修当前红用例时先专注该条」，**不是**在仍有未实现范围或未跑齐门禁时提前收工——与下文 **§硬要求 5** 一致）。  
- **产品 + UX + 运营规范 + 交付硬约束**：当需求涉及体验、闭环、**运营后台 / 运营壳路由**、**C 端可发布标准**、或**禁止 MVP** 时，须全文加载 **`.agents/skills/ux-product-review/SKILL.md`**（与 **`/super-pm`**、**`/ux-product-review`** 命令一致），输出或 plan 附录中须覆盖该 skill 规定的 **rubric**（含 **「KangDou 产品交付硬约束核对」**、触发条件下的 **「C 端交付硬约束对照」**、**「运营后台交互规范对照」**、**「方案与系统入口／数据依赖对照」**、有 PRD 时的 **全量「需求对照」**）。  
- 用户已显式执行 **`/super-pm`** 时，本命令产出须与其结论 **无矛盾**；若有冲突须在讨论稿中列出并让用户裁定。

---

## 用户对方案的硬要求（本命令下 MUST）

1. **TDD 先行**  
   - **方案阶段**：写明关键行为由哪类测试先锁定（E2E / 单测 / IT），P0 与合并门禁关系。  
   - **执行纪律**：先测后码、红→绿→重构；对齐 **`architecture-review-e2e-tdd`** 与 **`docs/dev/AGENT_WORKFLOW_CONSTRAINTS.md`**。

2. **并行 subagent（方案 + §9 + 实现；仓库偏好：尽量多用）**  
   - **方案阶段**：**鼓励**用并行 `Task` 做 **信息收集**（多路径检索、对照文档与既有实现、只读探索等），再汇总到主会话写讨论稿/定稿；与 **`AGENTS.md`**「尽量并行子 agent」一致。  
   - **定稿 Markdown 的连贯章节**（同一 `docs/superpowers/plans/*.md` 内连续段落、文首 `taskGraph` 等）：默认 **主会话串行落盘**，避免多子 agent 同时改同一文件；子 agent 产出可先收聊天/中间笔记再合并。  
   - **§9 生成阶段**（§0-§8 写完后，同一轮内）：派发**每子系统一个 subagent**（backend / frontend / operation），各自使用 codegraph 搜索代码库，并行产出文件映射、API 契约、DDL、组件接口。主 agent 待所有 subagent 返回后合并追加到 plan 文件，输出完整 §0-§9。  
   - **实现阶段**（按 plan 写代码 / 跑测）：凡可拆成 **彼此无依赖、可独立验收** 的线，定稿中须**显式标出**（可多拆则多拆，以无依赖边界为准），并写明主会话如何 **并发 `Task` 派发** 与 **汇总收口**（对齐 **`AGENT_WORKFLOW_CONSTRAINTS.md` §1**；就绪集可用 `scripts/verify-plan-ssot.mjs ready <plan路径>` 等仓库约定）。其它 Agent 工作（排障、评审、大范围检索）同样在**可并行、无写冲突**时**优先**拆 `Task`。执行接续可配合 **`/jx`**。  
   - 调用 **`Task` 时默认不传 `model`**，避免 Free/仅 Auto 订阅失败（**`Cursor 环境规则（本环境忽略）`**）。

3. **系统与链路写全**  
   定稿须包含（与 **`docs/superpowers/PLAN_WRITING_CONTRACT.md`** 的 **§4.0 按系统新增功能模块**、**§4.2 列表级交互链路**、**§4.3 页面结构展示与高保真原型** 对齐，不得用一句「主路径」代替）：  
   - **涉及哪些系统**（上表子集或扩展，含 DB/消息等若适用）；  
   - **各系统新增什么**（模块、接口、页面、表/migration、配置、脚本）；  
   - **端到端链路**：操作 → 请求/消息 → 响应或状态 → 落库或副作用；**列表页**须 **分步**（操作→反馈→API/状态），不得仅概括。

4. **先讨论，再给方案**  
   - **第一轮**：**禁止**直接输出可落盘的完整 `docs/superpowers/plans/*.md` 正文（勿代替用户一次性定稿）。第一轮只输出 **讨论稿**：范围与假设、**待你确认的问题（编号）**、各系统 **拟** 增量一行级摘要、风险与依赖、可选方案 A/B、**「明确不做（防膨胀）」草案**。  
   - **第二轮**：在用户补充或明确「按某方向定稿」之后，再 **全文加载** **`.agents/skills/writing-plans/SKILL.md`**，并按 **`docs/superpowers/PLAN_WRITING_CONTRACT.md`** 必选章节输出可执行 plan（含文首 `taskGraph`、与 **`docs/dev/SSOT-TASK-GRAPH-PLAN.md`** / 对应 JSON 的同步说明、校验命令如 `scripts/verify-plan-ssot.mjs validate <path>`）。

5. **一次完成本期范围 + 跑齐全量验证后再做「完成」汇报（维护者偏好，MUST）**  
   - **定稿中**须在「实现 / 执行说明」或验收章节写明完整的 **Post-Development Workflow**，包含：代码提交 → **`/kd-review` 全自动审查（🔴🟡🔵 清零）** → 编译 → 单测+覆盖率门禁 → 询问用户后跑 E2E → 全栈覆盖率汇总 → 完成汇报。  
   - **`/kd-review` 先行**：所有验证步骤前必须先执行 `/kd-review` 并清零，**禁止**在未通过代码审查的情况下跑验证。  
   - 按本 plan 进入**实现会话**时，须在 **已确认的本期范围** 内 **连续推进至全部就绪**，**禁止**在仅完成部分子能力、或验证命令尚未按 **`AGENTS.md`** / **`kangdou-testing-coverage`** / 本 plan 所列门禁 **全部跑通** 之前，以「先到这儿」「主体已完成」等**结束实现并等同交付收口**（**不得**把部分功能完成当成会话终点）。  
   - **禁止主路径收口即宣称完成（MUST）**：**不得**仅以「核心主链路可走通」替代本 plan **§4.2 / §4.3 / 任务图 JSON** 已列的 **全部** 用户/商家/运营可操作能力；缺任一端、任一链路、任一闸门即 **不得** 做完成汇报。  
   - **禁止分期交付同一方案（MUST）**：同一 `docs/superpowers/plans/*.md` 定稿所承诺的本期功能，须在**单次实现周期内全部完成**并通过验证门禁；**不得**在正文使用「第一期/第二期/V1/V2 分批上线」等将**同一已定范围**拆成多期交付与多期验收。若确需分文件推进，须拆成 **多份独立 plan**（各含独立 `taskGraph` 与 DoD），**每一份仍须各自一次完成**，**禁止**用「下期 plan 再补」逃避当前定稿范围。  
   - **完成汇报**默认指：**本期范围内代码与配置已齐** + **与本 plan 相关的各子项目约定验证命令均已通过**（保留命令与关键输出证据，见 **`.agents/skills/verification-before-completion/SKILL.md`**）后的 **一次汇总**；中途如需同步，仅用**极简进度**（可选），**不得**用完成口吻收尾后等用户追问剩余工作。  
   - **与 TDD 的关系**：**首个失败即停**用于 **定位并修复当前失败用例**，修绿后继续直至 **全量** 门禁通过；**不是**「见好就收」在仍有红或未跑层时停止。  
   - **例外**：用户**显式**要求暂停/缩小范围、遇须用户决策的阻塞、或环境/配额硬限制无法继续时，须列出**残余项与下一步**，**禁止**假装已全量完成。

---

## §9 实现任务派发 — 第二轮定稿时并行生成（本命令下 MUST）

第二轮定稿包含 **两阶段**：第一阶段按 `PLAN_WRITING_CONTRACT.md` 写出 §0-§8（**含 taskGraph JSON**），**之后在同一轮内**并行派发 subagent 扫描代码库填充 §9（文件→任务映射、API 契约、DDL 草图、组件接口、并行派发计划），追加到同一 plan 文件后输出完整 plan。§9 是定稿的**标准章节**，非可选附加。

### 工作流

```
第二轮第一阶段：主 agent 串行写入 §0-§8
  ├─ 创建或更新 docs/superpowers/tasks/<featureId>.json（与 plan 文首 taskGraph 一致）
  └─ 执行 scripts/verify-plan-ssot.mjs validate <path> 确保 JSON 合法

第二轮第二阶段：
  Step 1: 读取 taskGraph JSON，tasks 按子系统分组
  Step 2: 并行派发 subagent（backend / frontend / operation）
          各自用 codegraph 搜索代码库，产出文件映射/API/DDL/组件接口
          ⚠️ 某 subagent 失败 → 自动重试 1 次；仍失败则跳过该组并在报告中标记
  Step 3: 主 agent 合并所有结果 → 去重 → 一致性校验 → 追加 §9
  Step 4: 输出完整 plan（§0-§9）+ 汇总表格
```

### Step 1：分组

读取 plan 文首 YAML 的 `taskGraph` → `docs/superpowers/tasks/<featureId>.json`（该 JSON 已在第一阶段创建）。将所有 tasks 按子系统分组：

| 分组 | 筛选条件 |
|------|---------|
| `[backend]` | 标题含 后端/服务/API/接口/Controller/Service/DB/Flyway/migration |
| `[frontend]` | 标题含 页面/组件/小程序/前端/路由/UI |
| `[operation]` | 标题含 运营/管理页/配置页/审核/list 页 |
| `[cross]` | 跨子系统（标题同时含前后端关键词或描述涉及多端），加入所有相关组 |

如果某组 task 数为 0，显式写「无该子系统任务」并 skip 对应的 subagent 派发。

### Step 2：并行派发 subagent

每子系统一个 subagent，并行启动。每个 agent 接收对应任务列表 + 以下 prompt：

```
你是专注于 {group} 系统的架构师，负责以下任务：
{taskList}

你有以下 MCP 工具可用：
- codegraph_files:  浏览项目目录结构（先调用此工具了解项目布局）
- codegraph_search: 按符号名搜索（用于找同类 Controller/Service/组件）
- codegraph_context: 按功能描述获取上下文（用于理解现有模块结构）

请用这些工具搜索代码库，为 plan 的 §9 贡献内容：
切忌凭记忆编造路径或字段。搜索不到就明确写「[待确认]」并说明原因。

## 9.1 文件变更总览
每个 task 搜出相关文件，填表（task ID / 文件路径 / 新建or修改 / 摘要）。
- 新建文件：先 codegraph_files 确认同级目录结构，再参考同级文件命名风格
- 修改文件：codegraph_search 确认真实存在
- 搜索不到：写「[待确认] 目录/文件名_说明」并在备注列写原因

## 9.2 API 契约（backend agent 专用）
每个 REST task 填写：端点、方法、请求响应字段（TypeScript 风格）、错误码、鉴权。
- 先 codegraph_search 找同级 Controller 的 @RequestMapping 作为风格参考
- 字段名与现有风格一致（统一 tenantId 而非 tenant_id）
仅后端 agent 做此项，其余 skip。

## 9.3 数据库变更（backend agent 专用）
每个 DB task 给出完整 CREATE TABLE / ALTER TABLE。
- Flyway 版本：在项目根目录执行 make flyway-next 获取版本号
- 参考同级 migration 的 DDL 风格和注释惯例
仅后端 agent 做此项，其余 skip。

## 9.4 组件接口（frontend / operation agent 专用）
每个 UI task 给出组件 props/emits 类型、composable 签名。
- 先 codegraph_files 查看 components/ 目录下同类组件命名
- 参考现有的 .vue 组件 props 定义风格
仅前端/运营 agent 做此项，其余 skip。
```

### Step 3：主 agent 合并 → 去重 → 校验 → 追加 §9

所有 subagent 完成后，主 agent 按顺序执行：

**3a. 收集与去重**
- 合并所有 subagent 的产出
- 若多个 agent 提到同一文件（跨子系统共享文件），以后端 agent 的版本为准，非后端 agent 的条目标记为 `[参见 backend]`
- 若同一 endpoint 被多个 agent 重复定义，合并为一条
- **交叉校验**：前端/运营 agent 列出的 API 调用字段，必须能在后端 agent 的 API 契约中找到对应定义；缺少的字段标记为 `[待确认：前端需后端提供]`

**3b. 一致性校验**
- 每一条文件路径，要么通过 codegraph 确认存在，要么已标注 `[待确认]`
- DDL 的表名字段名不可与 plan §0-§8 矛盾
- API 端点列表不可超出 plan §0-§8 中声明的接口范围
- 组件 props/emits 的类型与数量与 plan §4 的页面结构描述一致
- 无可疑编造（缺少 `[待确认]` 标记但路径不存在）

**3c. 失败处理**
- 若某 subagent 重试 1 次仍失败：跳过该组，在汇总报告中标记为 `❌ 未生成`
- 若全部 subagent 失败：§9 输出简版（仅 9.5 并行计划，其余节写「subagent 未就绪，须人工补充」）

**3d. 追加 §9**，按以下模板：

```markdown
## 9. 实现任务派发

### 9.1 文件变更总览

{合并、去重后的表格，按 task ID 排序}

### 9.2 API 契约

{合并接口定义，仅后端 agent 产出}

### 9.3 数据库变更

{合并 DDL，仅后端 agent 产出}

### 9.4 前端组件接口

{合并组件接口，仅前端/运营 agent 产出}

### 9.5 并行派发计划

| 并行组 | 任务ID | 前提条件 | 估算文件数 | 建议 agent | 派发批次 |
|:------:|:-------|:--------|:---------:|:---------:|:--------:|

**分组推导规则**（基于 taskGraph JSON 的 `dependsOn` 依赖关系）：

1. **并行分组**：解析 JSON 的 tasks 数组，按 `dependsOn`（前置依赖）分组：
   - `dependsOn: []`（无依赖）→ 组A（第一批并行执行）
   - `dependsOn: [组A的任务]` → 组B（等组A完成后执行）
   - `dependsOn: [组B的任务]` → 组C（等组B完成后执行）
   - 如果 A→B, A→C, B→D, C→D：则 B/C 同组（组B），D 为下一组（组C）
2. **跨组依赖**：task 的 `dependsOn` 可引用其他组的 task ID，该 task 所在批不得早于其依赖的 task 的批。
3. **最终派发批次** = 并行分组 + 组内依赖排序（例如 组A→组B→组C）
```

### Step 4：报告

追加完成后打印汇总：

```
§9 实现任务派发已追加到 docs/superpowers/plans/<plan>.md

  子系统      任务数    文件数    状态
  backend     5         12        ✅
  frontend    3          6        ✅
  operation   2          4        ⚠️ [待确认]路径 ×1
  ──────────────────────────────────
  合计        10        22      

  ⚡ 并行组: 3 批 (组A 5 个 → 组B 3 个 → 组C 2 个)
  ⚠️ 未通过的校验项: 无
  📋 请在编码前审阅 §9 的 API 契约和 DDL
```

### §9 质量要求

1. **禁止编造文件路径** — 须通过 codegraph 确认存在；搜索不到时写 `[待确认]` + 原因，禁止默认随意选一个目录
2. **无同类模式可参考时** — 用文字描述预期位置和命名，填入 `[待确认]` 列，不做无依据猜测
3. **冲突处理** — 跨子系统共享文件以后端 agent 为准
4. **一致性** — §9 的 API 签名、字段名、表名须与 plan §0-§8 一致
5. **Flyway 版本** — 统一使用 `make flyway-next` 获取版本号（或参考最大版本 +100 gap）
6. **并行派发计划** — 必须与 taskGraph JSON 的 `dependsOn` + `group` 完全一致
7. **门禁值** — backend 行 95%/分支 85%, frontend 行 85%/分支 75%, operation 行 90%/分支 80%
8. **输出验证** — 追加 §9 后主 agent 须对每条文件路径做最终确认（可用 codegraph 批量查询），发现无效路径即标记回 `[待确认]`
9. **subagent 全失败降级** — 全部 subagent 失败时输出简版 §9（仅 9.5 并行计划），不堵塞后续流程

---

## Agent 必读索引（第二轮定稿前逐项核对）

| 文档 / Skill | 用途 |
|----------------|------|
| `.agents/skills/writing-plans/SKILL.md` | 定稿结构与粒度 |
| `docs/dev/e2e-testing-agent-guide.md` §1.1 | 小程序 E2E 与正式页面路径（禁专测页作主载体） |
| `docs/superpowers/PLAN_WRITING_CONTRACT.md` | 必选章节、§4.0 / §4.2 / **§4.3**、§7 E2E |
| `docs/dev/AGENT_WORKFLOW_CONSTRAINTS.md` | TDD、并行 subagent、验证顺序 |
| `docs/dev/SSOT-TASK-GRAPH-PLAN.md` | 任务图 JSON schema 与校验 |
| `.agents/skills/architecture-review-e2e-tdd/SKILL.md` | E2E + TDD 门禁 |
| `.agents/skills/ux-product-review/SKILL.md` | 与 **`/super-pm`** 一致 |
| `AGENTS.md` | 各子项目构建与测试命令表 |
| `codegraph` MCP tools（`codegraph_files` / `codegraph_search` / `codegraph_context`） | §9 生成时搜索现有文件结构、定位同类模式（禁止用 grep 替代） |
| `.agents/rules/kangdou-testing-coverage.md` | 测试分层与假绿相关底线 |
| `docs/dev/kangdou-e2e-execution-contract.md` | E2E 执行契约 |
| `docs/dev/kangdou-superpowers-plan-contract.md` | 编辑本目录 plan 时的软提醒（与本文对齐） |
| `scripts/verify-plan-ssot.mjs` | 任务图 JSON 校验脚本（validate / ready） |

---

## 建议输出骨架

**第一轮（讨论稿）**  
- 一句话背景与目标  
- 待确认问题（编号，可勾选）  
- 子系统涉及表 + 每系统 **拟** 增量（各不超过数行）  
- **「明确不做（防膨胀）」** 与 **「建议后续迭代」**  
- 风险、外部依赖、与现有文档/接口冲突  
- 请用户选择或补充后再进入第二轮  

**第二轮（定稿 plan，含 §0-§8）**  
- 开场一句：正按 `writing-plans` + `PLAN_WRITING_CONTRACT` 输出  
- **需求追溯矩阵**：将上游文档每条功能需求映射到 task id + E2E 场景 + 验收门禁，确保无遗漏  
- **明确不做（防膨胀）**：从第一轮讨论稿继承已达成共识的「不做项」和「建议后续迭代」，逐条引用原文或编号。禁止静默丢失第一轮已确认的边界。  
- 完整契约章节 + **§4.3 逐页页面结构**（或已声明的高保真原型路径与合并条件）+ 任务勾选 + E2E/TDD + **实现阶段**并行 Task 线说明 + **质量禁令自检表**（逐条勾选）  
- **分级验收门禁表**（建议四级：代码质量与审查 → 安全审查 → 测试覆盖率门禁 → E2E 验收），包含门禁编号(G1-GN)、验证方式、通过条件、执行顺序  
- **敏感字段清单与分级约束**：列出新增 API/表中所有敏感字段（PII、金融数据、凭证），标明加密存储策略、日志脱敏规则、前端展示规则，并映射到安全审查门禁  
- **数据隔离边界声明**：逐表声明 `tenant-scoped` / `platform-scoped` / `shared-ref`，写明跨租户查询与单租户查询的 SQL 写法差异  
- **FeatureGate 开关设计**：每个新增功能写明开关 key、作用域、关闭时行为；不使用开关的须说明理由  
- **E2E 用例枚举**：每场景一张表（前置条件、逐条用例操作与断言、清理方案），且至少包含一条多租户隔离验证用例（Tenant-A 创建 → Tenant-B 访问 → 404/403/空）  
- **E2E 路由合规性确认**：所有小程序 E2E 所在页面的路由路径必须为产品 `pages/` 正式路由，无新增 `pages/e2e/*` 专测页；若存在存量专测页，须标为「技术债迁出中」并指向专项计划。  
- **禁止用 JSON 替代页面**：每个用户可见页面必须渲染真实 UI（含加载/空/错态），不得以 raw JSON 或调试 dump 作为正式交付物。开发期临时面板须写明移除条件与验收标准。  
- **错误场景清单**：每个新增功能列出至少 3 种非正常路径（网络失败、权限不足、数据不存在、外部依赖故障等）及对应 UI 表现  
- **回滚方案**：涉及 Flyway 迁移、配置变更、外部 API 对接的任务，须写明回滚步骤（FeatureGate 关闭列为首选）  
- **Post-Development Workflow**：代码提交 → `/kd-review` 清零（🔴🟡🔵）→ 编译 → 单测+覆盖率门禁 → 询问用户后跑 E2E → 全栈覆盖率汇总 → 完成汇报  
- **实现会话**：写明本期范围须 **一次推进至验证全绿** 后再做完成汇报。首个失败即停用于定位并修复当前失败用例，修绿后继续直至全量门禁通过，不得以此作为提前收工的理由（见上文 **硬要求 §5**）。  
- **每步必须定义验证门**：实现阶段的每个任务/子任务须写明其 **验证门**（如 `mvn -q compile`、`pnpm vitest run`、`pnpm playwright test`），格式为 `验证门: <命令>`。执行时门不通过不得进入下一步。分散在多个模块的改动（如同时涉及 `backend/` + `frontend/`）须为每个模块分别定义验证门。  

**§0-§8 写完后 → 在同一轮内进入 §9 生成**（见上文「§9 实现任务派发」节）：派发并行 subagent 填充文件映射/API契约/DDL/组件接口/并行派发计划，追加到同一 plan 文件后输出完整 plan（§0-§9）。  

策略：本命令不替代 `mvn verify`、Playwright 或小程序 E2E 的实际执行；定稿中的命令须与 `AGENTS.md` 一致；实现时遵守 **硬要求 §5**，避免「做一半就停」式收口。
