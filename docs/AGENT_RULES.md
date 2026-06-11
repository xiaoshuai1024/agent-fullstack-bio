# Agent 遵守的规则

本文档整理开发过程中 Agent 需要遵守的核心规则，按类别组织。详细内容见各引用文档。

---

## 0. 语言

- 向用户**提问、确认、弹窗选项**默认**中文**；**禁止用英文询问**，除非用户明确要求英文。详见 `AGENTS.md`「用户交互偏好」和 `docs/interaction-preferences.md`。

---

## 1. Git 与分支

详见 `docs/GIT_WORKFLOW.md`（含 **〇.6 合并冲突与拉取**）

- 分支结构：`master` ← `dev` ← `feature/xxx`
- 每次 commit/push/PR 前必须**用户确认**
- 禁止直接提交到 dev 或 master

### 合并与拉取（MUST）

- **禁止自动合并**：不得擅自完成 merge/rebase 并提交合并结果；发现冲突须**停手、说明、询问用户**再按指示操作。  
- **用户要求 pull 前**：若工作区有未提交改动，须先与用户确认并完成 **commit**（或用户明确要求的 stash 等），再 `pull`。详见 `docs/GIT_WORKFLOW.md` 〇.6。

### 云效规则（MUST）

**全文见 `docs/dev/yunxiao-agile-agent.md`（约定总览）** 与 `.agents/rules/yunxiao-agile-agent.md`。

摘要：
- **MCP 优先**：云效/Codeup/PR/工作项默认用 Yunxiao MCP Server
- **工作项写入**：开始/完成/工时须先推断 → 询问用户 → 再写入
- **PR 创建**：默认通过 `scripts/codeup/create-mr.sh` 或 `scripts/codeup/create-pr-all.sh`
- **缓存**：`.cursor/state/yunxiao/`（不提交 Git）
- **任务归属**：新建任务默认到当前 Sprint，若无则询问用户

---

## 2. 子任务执行

- **默认**：任何工作，只要能开启 subagent 进行，就尽可能多的开启 subagent 并行执行（**优先并行**）
- **拆分原则**：将任务拆分为多个独立的子任务，每个子任务有明确的范围、目标和交付物，无共享状态或顺序依赖
- **拆分场景**（包括但不限于）：
  - 多个文件的编辑（不同目录/模块）
  - 多个独立测试的修复
  - 多子系统的并行开发
  - 方案阶段的并行信息收集与对读
  - 问题排查阶段的并行调查
- **主 agent** 负责拆分决策、编排与结果汇总
- 所有 agent（含 subagent）执行前必须先检查并加载 `skills/` 目录中的项目级技能文件
- 计划阶段前置收敛用户决策项；开发执行阶段默认持续推进，仅在阻塞时中断询问

### Cursor `Task` 子 agent 与模型参数

- 调用 Cursor **`Task` 工具**派发子 agent 时：**无任何限制**，可以根据任务需要自由指定模型参数。
- 可以直接使用 `model` 参数为不同的 subagent 选择合适的模型。

---

## 3. 文档与计划

- **功能真相源**：以 `docs/FEATURES.md` 记录已实现、部分实现与未实现能力
- **计划文件**：阶段执行完毕后，将结论收敛到 `docs/FEATURES.md`，并删除对应 plan 文件
- **双仓**：前端与后端仓库的说明需一致或指回主文档

### Superpowers 工作流（交叉引用）

实现类计划与执行的**技能级约定**见 **`docs/SUPERPOWERS.md`**（含 `brainstorming` → `writing-plans` → `executing-plans` 等触发条件）。

### GStack 与 Superpowers（交叉引用）

需求澄清 / CEO·EM 审方案 / 评审 / QA / 根因排查用的 **GStack skill**，与 Superpowers **计划与任务图**如何衔接，见 **`docs/superpowers/GSTACK_AND_SUPERPOWERS.md`**。

---

## 4. API 与通信

- **统一响应格式**：非 2xx 响应为 `{"error": "<错误码>"}`
- **错误码**：`invalid_uuid`、`invalid_json_body`、`unauthorized`、`forbidden`、`not_found`、`unknown_user`、`internal_error`
- **前端处理**：以 `error.response?.data?.error` 为主，勿假定响应体为 HTML 或非 JSON

---

## 5. 后端规则

- **本地运行**：修改 **`backend/`**（Java、Flyway 脚本、`application*.yml`、资源等）后，**必须重启**本地 Spring Boot（结束占用 **`server.port`** 的旧进程后再启动；常见 **`SPRING_PROFILES_ACTIVE=local`** + **`mvn spring-boot:run`**），以便加载新代码、执行 Flyway、并与运行期元数据缓存一致。细则见 **`docs/JAVA_DEV_STANDARDS.md`**「七」与 **`.cursor/rules/kangdou-backend-restart-after-edit.mdc`**。
- **接口与表结构**：新增或变更 REST 字段时须与 **`db/migration`** 及**实际连接库**对齐；禁止「缺列仍 200、数据没落库」。见 **`docs/JAVA_DEV_STANDARDS.md`**「四」与 **`.cursor/rules/kangdou-backend-api-schema-alignment.mdc`**。
- **日志**：
  - 第三方 API 调用必须打日志（INFO 摘要 + WARN/ERROR 失败日志）
  - 禁止输出密钥、`secret`、完整 `access_token`、用户敏感标识
- **接口测试与交工前验证（MUST）**：新增/修改接口须同步 **`MockMvc`/`*IT` 等可执行测试**，合并前 **`mvn verify`**（或团队约定的 `mvn test` 范围）须通过；且在**宣称任务完成或提交 PR 前**，还须完成至少一项**可观测**的接口验证（Swagger **Try it out**、对本地已启动后端的 **`curl`/HTTP 调用**、或消费端页面 **Network** 确认状态码与响应体），**禁止仅靠编译无报错即交工**。全文见 **`.cursor/rules/kangdou-api-verify-before-handoff.mdc`** 与 **`docs/JAVA_DEV_STANDARDS.md`**「二」。
- **Swagger 约束（架构级）**：新增接口必须同时补齐 Swagger 信息，不得"先上接口后补文档"
- **Swagger 门禁**：CI "只告警不阻断"，出现告警须优先补齐 Swagger 描述后再提交

### PHP 迁移规则（MUST）

- 涉及 PHP 接口迁移时，必须使用 **最完整链路策略**，禁止"最小可用"实现
- 必须逐行对照来源系统对应的 controller/service/model/sql
- 必须有 reviewer 角色按 `docs/templates/php-migration-review.md` 逐项审计
- 未还原项不为 0 时，禁止标记迁移完成
- 推荐对照基线：`docs/examples/shop-goods-lists-migration-baseline.md`
- 迁移任务完成后，必须先执行并通过：
  - `scripts/review/php-migration-review-gate.sh --review-doc <review文档> --test-cmd "<接口契约测试命令>"`
  - 未通过前，禁止判定"迁移完成"

---

## 6. 前端规则

- **包管理**：`frontend/` 与 `operation-backend/` 统一 **pnpm**（安装：`pnpm install`；勿默认使用 `npm install`）。详见 `AGENTS.md`「技术栈规范」。
- **依赖脚本**：不要使用 `npx`，命令须声明在 `dependencies` / `devDependencies`
- **枚举显示**：禁止直接显示英文原值，必须通过中文映射函数渲染
- **E2E 端口**：5174 与 dev 5173 分离
- **运营 Playwright**：依赖 **`http://127.0.0.1:8080`**；执行前须确保后端已启动（未监听时在 **`backend/`** 拉起；**TDD 改后端后须重启**）。**禁止**未起后端却以 **`SKIP_OPS_E2E=1`** 得到全体 skip 当作验收通过（细则见 **`AGENTS.md`**、`docs/dev/e2e-testing-agent-guide.md` §4.1）。

---

## 7. 响应式设计 (RWD)

- **移动优先**：所有页面须在 320px ~ 1024px+ 下可用
- **断点**：
  - ≤960px：单列布局
  - ≤1100px：双列改单列
  - ≤520px：单列压缩
- **导航可达性**：窄屏下必须能到达核心业务能力
- **横向溢出**：表格须包在 `overflow-x: auto` 容器内

---

## 8. 界面布局约束

- **控件堆叠**：纵向堆叠须显式间距，禁止零间距紧贴
- **多控件排列**：两个及以上纵向控件须使用 `NSpace vertical` 或 `ui-stack`，禁止裸堆叠
- **新页面自检**：320px / 375px / 768px / 1024px 下无横向撑破、无不可达入口

---

## 9. 产品交互完整性（双端）

- 涉及 C 端 + B 端（个人端 + 企业端）的模块设计，必须同时覆盖两端主路径，禁止只实现单端交互
- 对于"发布/管理"类能力，除企业侧入口外，必须同步提供个人侧可见的消费与跟踪路径（如投递记录、状态跟踪、反馈入口）
- 原型评审前必须自检"入口-详情-状态-返回"四段闭环在两端均可跑通

---

## 10. 需求信息完整性（MUST）

### 10.1 禁止推测与无信息开发

任何开发或设计任务开始前，必须先确认需求和信息的完整性。详见 `.agents/rules/kangdou-no-speculation-no-blind-dev.md`。

### 10.2 必须明确的信息清单

开始编码前，必须确认以下信息已明确：

| 信息类别 | 检查项 |
|---------|--------|
| **需求背景** | 用户要解决什么问题？为谁解决？业务价值是什么？ |
| **功能范围** | 明确要做什么？**明确不做什么**？ |
| **用户流程** | 用户如何操作？每一步的输入、输出、系统响应是什么？ |
| **边界条件** | 异常情况如何处理？极限值、错误状态、权限边界？ |
| **验收标准** | 如何算完成？验收清单是什么？ |
| **技术方案** | 技术选型、数据结构、API 契约是否明确？ |

### 10.3 信息缺失时的处理流程

1. **立即暂停**：发现信息缺口时，立即停止当前工作
2. **结构化询问**：使用 `AskUserQuestion` 工具，提供清晰的问题和选项
3. **等待确认**：在用户回复前，不进行推测性开发
4. **记录假设**：如用户授权可按经验处理，必须在代码/计划中明确记录假设

### 10.4 红线与例外

**红线（必须遵守）**：
- ❌ 需求只有一句话，没有用户故事 → 必须询问
- ❌ 技术方案存在多种选择 → 必须询问
- ❌ 验收标准缺失 → 必须询问
- ❌ 对用户意图有任何疑问 → 必须询问

**例外（可处理）**：
- ✅ 用户明确授权："你看着办"
- ✅ 极小的、不影响核心的细节（文案措辞等）
- ✅ 已有明确的先例或规范可复用

### 10.5 与 Superpowers 工作流的配合

- 新需求必须先经过 `brainstorming` 或 `/plan-template` 澄清
- 禁止跳过设计阶段直接编码
- 执行阶段必须有书面计划（见 `docs/SUPERPOWERS.md`）
