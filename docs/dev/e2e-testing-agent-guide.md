# KangDou 端到端测试 — Agent 执行指南

本文档为 **执行、调试、编写或修改 E2E** 时的单一事实来源（与 `.agents/rules/kangdou-testing-coverage.md`、`AGENTS.md` 对齐）。**Agent 在跑 E2E 或改 E2E 代码前须完整阅读本节对应条目。**

---

## 1. E2E 类型与所属目录

| 类型 | 目录 / 入口 | 典型命令 |
|------|----------------|----------|
| **跨系统一键验证（运营仓编排）** | `operation-backend/scripts/cross-system-verify.mjs` | `cd operation-backend && pnpm run verify:cross-system`（8080 健康 + `frontend` **`test:trade`** + 本包 Vitest）；加 Playwright / 小程序 P0 见该脚本文件头注释 |
| **运营后台（Vue + Playwright）** | `operation-backend/tests/e2e/`、`playwright.config.ts` | `cd operation-backend && pnpm run test:e2e` |
| **微信小程序（automator / Node）** | `frontend/e2e/miniprogram/`、`run.mjs` | `cd frontend && pnpm run e2e:mp-weixin` |
| **微信小程序 P0 交易闭环** | `run-p0-trade.mjs`、`pages/order/list?automatorP0=1`（内嵌 `OrderListP0AutomatorPanel`，`data-e2e=e2e-p0-*`） | `cd frontend && pnpm run e2e:mp-weixin:p0-trade`（须 **8080**、`SPRING_PROFILES_ACTIVE` 含 **local** 以启用退款 mock；可调 `WECHAT_E2E_P0_FLOW_MS`） |
| **跨端 P0（小程序分段 + 运营 Playwright）** | `operation-backend/scripts/trade-p0-cross-e2e.mjs`、`trade-p0-cross.spec.ts` | `cd operation-backend && pnpm run verify:trade-p0-cross`；握手与环境见 [`trade-p0-cross-handshake.md`](trade-p0-cross-handshake.md) |
| **frontend Jest E2E（含 automator 烟测）** | `frontend/e2e/*.test.ts`（`jest --roots e2e`） | `cd frontend && pnpm run test:e2e` |
| **后端集成测（非浏览器 E2E）** | `backend/src/test/java/**/*IT.java` | `cd backend && mvn -q verify` |

说明：**`/mp-e2e` 命令与小程序脚本指 `frontend/`**，不是 `mvn verify`。需要 Java 全链路接口测时用 **`mvn verify`**。

### 1.1 小程序 E2E：须走正式产品页面（MUST）

- **默认口径**：微信小程序 automator / Jest E2E 的**主断言路径**须落在 **`src/pages/` 下对用户开放的产品路由**（与 `pages.json` 注册一致），模拟真实用户从入口到结果的操作链。**全仓库特性验收**在含 UI 时须同一口径：**不得以专测页替代产品路径作为唯一合入门禁**。  
- **禁止（新增特性）**：为通过自动化而**新建**仅存在于 `pages/e2e/*`、无产品文档与用户入口的「专测页」，并将其作为该特性的**唯一或主要** E2E 载体。  
- **存量技术债（已收口）**：历史曾使用 `pages/e2e/e2e-p0-trade-flow`、`pages/e2e/e2e-joint-card-flow`；已迁至 **`pages/order/list?automatorP0=1`**（交易 P0）与 **`pages/joint-card/detail` → `checkout`**（联合套卡 P0）。新特性**不得**再增加 `pages/e2e/*` 专页作为主载体。  
- **与 plan 契约对齐**：`docs/superpowers/PLAN_WRITING_CONTRACT.md` §7.1 / §7.2 中「入口端」须写**正式页路径**，不得仅写专测页路径冒充 §4.2 交互链。

### 1.2 小程序 E2E 执行顺序：H5 先于 automator（MUST）

- **执行顺序契约**：当 plan 要求执行小程序 E2E 时，必须先跑 **H5 模式**（`pnpm run e2e:h5`），H5 全部通过后，再跑 **微信 automator**（`pnpm run e2e:mp-weixin`）。
- **理由**：
  - H5 模式启动快、环境简单、失败诊断直接，适合快速检出业务逻辑问题
  - automator 依赖微信开发者工具 CLI，启动慢、调试成本高，适合在 H5 确认无阻塞问题后再做完整验收
- **例外**：仅当用户明确指示跳过 H5 直接跑 automator 时，可跳过 H5。
- **与 plan 契约对齐**：定稿方案 §7 的 E2E 执行顺序须体现 H5→automator 的先后关系。

---

## 2. TDD 与「首个失败即停」（MUST）

1. **任意一条失败 → 立即停止后续用例**（Playwright：`maxFailures: 1`；Jest `e2e/`：`--bail`；小程序 `run.mjs`：进程失败即 `exit 1`）。
2. **先修当前失败的一条**：单条 / 单文件重跑 **绿** 后，再跑**完整** E2E 命令做回归。
3. **禁止**攒多条红再一起改；**禁止**为「先绿再说」关掉 bail/maxFailures（仅排查「全部失败列表」时临时设 **`OPS_E2E_NO_BAIL=1`**（Playwright）或等价策略）。
4. 编写新链路：**先测后码**（红 → 最小实现 → 绿 → 重构）。
5. **依赖本地 `8080` 的链路**：若在 **TDD 会话中修改了 `backend/`**（Java、YAML、`resources/`、Flyway 等），在再次执行运营 Playwright / 小程序 automator 或手工验证「需登录」路径前，**须重启后端**，避免旧 JVM 缓存行为导致误判。

### 2.5 E2E 执行契约（高优先级 · MUST）

本节与 [`docs/dev/kangdou-e2e-execution-contract.md`](../../docs/dev/kangdou-e2e-execution-contract.md)、[`docs/superpowers/PLAN_WRITING_CONTRACT.md`](../superpowers/PLAN_WRITING_CONTRACT.md) §7、[`docs/superpowers/AGENT_WORKFLOW_CONSTRAINTS.md`](../superpowers/AGENT_WORKFLOW_CONSTRAINTS.md) §2.4 对齐；Agent **运行、调试、编写或修改 E2E** 及 **宣称合入门禁通过** 时均须遵守。

#### 2.5.1 禁止假绿与禁止降级（MUST）

- **假绿**：指在未真实满足验收条件时，通过 skip、弱化断言、关 bail、不当环境变量等使命令「退出成功」或报告通过，从而**冒充**已验收。  
- **已约定 E2E**：指已在 `AGENTS.md`、`kangdou-testing-coverage` 或本仓库 CI/文档中作为**默认合入门禁**或 **P0 契约**运行的脚本与命令组合（含默认 `maxFailures` / `--bail`、默认登录、依赖 `8080` / `5174` / 微信 CLI 等）。  
- **禁止降级**上述路径，包括但不限于：扩大 `SKIP_OPS_E2E` / `SKIP_WECHAT_E2E` 等适用范围（超出本文 §4.3 / `kangdou-testing-coverage` 已写明的 **CI 或应急** 场景）、关闭「首个失败即停」用于扫尾却不修根因、批量 `test.skip`、无用户授权而**放宽超时**、**弱化 `expect`**、用更窄的用例子集命令**冒充**文档要求的全量门禁、擅自修改 `loginAsAdmin` 等**约定默认账号**。  
- **环境或服务未就绪**：须按 §4.1、§3、`AGENTS.md` **先排查并起服务**（含 `backend/` 启动、`actuator/health`、DB/Flyway）；**禁止**在未完成排查前改测或全 skip 以得零失败假象。流水线等 **文档已允许的** `SKIP_*` 除外，且须在 PR/流水线说明中写明；**不得**将「关键 P0 路径全体 skip + 退出码 0」表述为「E2E 已通过」。

#### 2.5.2 执行会话内：测试代码冻结（MUST）

- **触发**：为**当前验收任务**已执行至少一次文档约定的 E2E/回归命令（含对**同一失败点**的重复重跑、单 spec 重跑）后，至该任务**收口汇报**前。  
- **冻结范围**：不得修改 `operation-backend/tests/e2e/**`、`frontend/e2e/**`（含 `*.test.ts`、`miniprogram/`、`run*.mjs` 中与断言/跳过/超时相关的逻辑）、`playwright.config.ts` / Jest e2e 配置中影响**是否跑、跑什么、如何通过**的项，以及与上述直接相关的 test helper。  
- **允许修改**：业务源码、后端配置与 Flyway、环境变量、启动顺序、**非测试断言**的数据准备脚本、文档。根因**确属测试错误**（错误期望、flake 已定位在测侧）时：**暂停**并向用户说明证据，**取得用户明确授权**后再改测；**禁止**边跑边改测「试到绿」。  
- **「新会话」**：仅新开 Cursor/OpenCode **聊天窗口**、**同一 git 分支、同一需求/同一 PR 目标**的，**不**自动解除本条冻结。解除条件为：用户**明确声明**换任务（例如「本需求收束，新开只做 E2E 修复」）、或**书面授权**可改哪些测试文件、或**单独 PR** 且描述为测试/契约变更并已获审查认可。

#### 2.5.3 格式化豁免（ALLOWED）

以下对测试文件的修改**无需**用户额外授权，且**不**视为解除 §2.5.2 中对语义变更的冻结：

- 仅 **空白 / 换行 / 缩进**、工具固定的 **import 排序**、**不改变语义** 的 Prettier/ESLint **format** 类变更。

**不属于**格式化豁免：任何 `expect` / `toMatch` / 选择器 / `timeout` / `skip` / `only` / mock 行为 / `describe` 结构变更。

#### 2.5.4 方案（plan）中的跨端主路径（MUST）

凡特性涉及 **多端或多系统**（例如 **小程序 → 后端 → 运营后台**），[`docs/superpowers/PLAN_WRITING_CONTRACT.md`](../superpowers/PLAN_WRITING_CONTRACT.md) **§7** 须包含 **「E2E 主路径」** 小节（**§7.1**）：每条路径写清 **入口端**、**依赖服务**（如 `8080`、`5174`、微信 CLI）、**与 P0 对应的自动化命令**（或明确写「尚无脚本，合入前须补」）。须同时满足 **§7.2**：每条路径写明 **覆盖的 §4.2 交互链**、fixture、**关键断言**与合并门禁；脚本未落地时须写 **拟** 保障逻辑。不得仅用笼统「写 E2E」替代可执行路径表与断言级说明。

#### 2.5.5 收口汇报（MUST）

宣称 E2E/合入门禁通过时须列出：**实际完整命令**、**退出码**、**失败数（须为 0）**；若有 skip 须列 **条数与原因**（且须符合本文与 `kangdou-testing-coverage` 对 skip 的约定）。若本轮**曾修改测试文件**（非 §2.5.3），须写明 **用户授权依据** 或 **单独 PR 链接**。

---

## 3. 失败时信息收集顺序（MUST）

**先收集证据，再改断言或业务代码**：

1. **Console**（浏览器 DevTools / **微信开发者工具** Console）
2. **Network**（失败请求、HTTP 状态码、响应体中与 `requestId` / 错误码相关的片段）
3. **后端日志**（见下 **§3.1**：本地文件路径、`requestId` 与 **时间** 的对齐方式）

禁止跳过前几步直接改 `tests/e2e` 里的选择器或**约定登录账号**糊弄过关。

### 3.1 后端日志：本地文件与「时间」读法（MUST 理解，避免误判）

本仓库后端在 **`spring.profiles.active=local`**（默认联调）下为 **控制台 + 文件双写**（见 `backend/src/main/resources/logback-spring.xml`、`application-local.yml`）。**同一条日志事件**会同时出现在终端与 `kangdou-local.log`；**业务时刻以 `requestId` 钉死**，不要因「控制台时间格式与文件里 `ts=` 长得不一样」而误判为两条请求。

| 项 | 说明 |
|----|------|
| **文件路径** | 默认 **`backend/logs/kangdou-local.log`**（相对进程 **`logging.file.path`**，一般为在 **`backend/` 目录** 启动时的 `./logs`）。Agent 可用 `Read` / `grep` 直接查该文件。 |
| **`ts=` 含义** | 文件行前缀 **`ts=`** 为 **后端 JVM 写出该条日志时的墙钟时间**（带时区偏移，与 Logback pattern 一致），**不是** E2E 报告生成时间、也不是浏览器 solely 的本地时间。终端里 Spring Boot 默认格式可能**没有** `ts=` 前缀，**不代表**与文件不是同一时刻——仍以 **`requestId`** 关联。 |
| **对齐失败请求（推荐顺序）** | **① 优先用 `requestId`**（响应头 `X-Request-Id`、错误 JSON `requestId`、与文件中 `requestId=…` 同一串）把前端 Network 与后端一行日志 **钉死**；**② 再用时间** 作辅助：与 E2E 失败时刻应在 **同一短窗口** 内，但允许 **本机与服务器时钟差** 或 **跨日滚动** 导致「差几分钟」观感，**不得**仅凭时间差就断定「不是同一次请求」。 |
| **旧内容 / 多次启动** | `logs/` 下可能仍有 **上一次进程** 的滚动片段；**优先 `tail` 最新段** 或看文件 **mtime**，或在复现前 **重启后端** 再跑一次 E2E，减少串读旧日志。 |
| **集成测 profile** | `mvn verify` 使用 **`test`** 等 profile 时 **不写** `kangdou-local.log`（仅控制台）；只有 **本机长期跑的 `local` 后端** 才有该文件。 |

---

## 4. 运营后台 Playwright（`operation-backend`）

### 4.0 浏览器约定（MUST）

**运营后台端到端测试一律使用本机已安装的 Google Chrome**（Playwright `channel: "chrome"`），与 **无头 / 有头** 无关：执行 `pnpm run test:e2e` 或 `pnpm run test:e2e:headed` 时均走本机 Chrome，便于与日常浏览器版本、企业策略、本机证书环境一致。**Agent 或本机跑 E2E 时须遵守此约定**，不要默认去装仅用 Playwright 自带的 `chromium` 来跑运营 E2E。

- **首次 / 换机**：在 `operation-backend` 执行 `pnpm run install:e2e`（内部为 `playwright install chrome`，安装与本机 Chrome 通道配套的驱动/组件）。需本机已安装 **Google Chrome**（稳定版）。
- **操作审计 E2E（`tests/e2e/audit-log.spec.ts`）**：依赖后端库存在 **`audit_event`** 且运营菜单已指向审计页：正常路径为 Flyway **V15+V16**；若共享库曾占用 V15/V16 为其它脚本，则依赖补救 **`V24`**（见 **`docs/dev/ops-auth-flyway-mysql-lessons.md`** 第 6.1 节）。未就绪时 `beforeAll` 探测 `GET /api/platform/audit-events` 非 200 会 **skip**；**`CI=true` 且后端健康但探测失败** 时 **抛错**。
- **例外**：流水线等 **无系统 Chrome** 的环境，使用 **`OPS_E2E_USE_PLAYWRIGHT_CHROMIUM=1`** 回退到 Playwright 自带 Chromium（`pnpm run test:e2e:ci` 已默认带上）；**不得**在本地开发文档中把该回退写成默认路径。

### 4.1 前置条件

- 后端 API 根须健康（默认 **`http://127.0.0.1:8080`**；可通过 **`OPS_E2E_API_BASE`** 指向其它主机/端口，与 `tests/e2e/globalSetup.ts` 一致）。**Agent 执行运营 E2E 前**：若健康检查失败，**须尝试** **`cd backend && mvn spring-boot:run`**（或与团队一致的启动命令，默认 **`local` profile**），并据控制台 / **`backend/logs/kangdou-local.log`** 排查 MySQL/**`kddev`**、Redis、Flyway、端口占用等后再跑 **`pnpm run test:e2e`**。**`/tdd`** 与合入验证：**禁止**仅以「服务未起」收工；**禁止**滥用 **`SKIP_OPS_E2E=1`**（须为文档允许的 CI 豁免且 **PR/流水线说明**）。未设 **`SKIP_OPS_E2E=1`** 时 **`globalSetup` 在健康或预登录失败时抛错**，**`pnpm run test:e2e` 非零退出**，不得将「未起后端」当作假绿理由。**TDD 中若改动了 `backend/` 源码或配置**，再次跑依赖该 API 的 E2E 前 **须重启后端进程**。个别用例在内嵌健康探测失败时仍可 **skip**（不得伪造断言通过），但合入级门禁不得建立在「全体 skip」之上。
- 通常需要 **`http://127.0.0.1:5174`**（Vite）；或由 Playwright **`webServer`** 自动执行 `pnpm run dev`。若已手动起 dev：**`SKIP_OPS_E2E_SERVER=1`**。
- 本机已安装 **Google Chrome**；首次跑前执行 `cd operation-backend && pnpm run install:e2e`。国内下载参见下文代理。

### 4.2 命令

```bash
cd operation-backend && pnpm run install:e2e    # 首次：playwright install chrome
cd operation-backend && pnpm run test:e2e       # 默认无头，仍使用本机 Chrome 通道
cd operation-backend && pnpm run test:e2e:headed # 有界面调试（同为 Chrome）
cd operation-backend && pnpm run test:e2e:ci    # CI：无 Chrome 时用自带 Chromium
```

### 4.3 配置与健康变量

| 变量 | 含义 |
|------|------|
| `OPS_E2E_BASE_URL` | 前端 baseURL（默认 `http://127.0.0.1:5174`） |
| `OPS_E2E_API_BASE` | 后端 API 根，用于 **`globalSetup` 健康检查**（默认 `http://127.0.0.1:8080`，勿尾斜杠）；与 `8080` 监听地址不一致时必须设置 |
| `OPS_E2E_HEADED=1` | 有头浏览器（与 `test:e2e:headed` 一致）；**仍为本机 Chrome** |
| `OPS_E2E_USE_PLAYWRIGHT_CHROMIUM=1` | 不使用本机 Chrome，改用 Playwright 自带 Chromium（**仅 CI / 无 Chrome 环境**）；`pnpm run test:e2e:ci` 已默认设置 |
| `OPS_E2E_BUNDLED_CHROMIUM=1` | 与上一行等价别名（`playwright.config.ts` 内同时识别） |
| `SKIP_OPS_E2E_SERVER=1` | 不自动起 `pnpm run dev` |
| `SKIP_OPS_E2E=1` | **仅**流水线等无法在 Job 内启动 `8080` 时使用；跳过依赖后端的用例。**禁止**在本地/Agent 默认使用；**禁止**将「全部 skip + 绿退出」当作运营 E2E 已通过 |
| `OPS_E2E_NO_BAIL=1` | 关闭「首个失败即停」，用于一次性收集多条失败 |
| `OPS_E2E_WORKERS` | Playwright **并行 worker 数**（正整数）。未设置时：本地 `min(4, availableParallelism)`，**CI** `min(2, availableParallelism)`；`playwright.config.ts` 仍 **`fullyParallel: false`**（同文件内顺序、**跨文件**并行）。并行依赖**单后端 + 单库**时若出现偶发竞争，可设 **`OPS_E2E_WORKERS=1`** 或 `pnpm run test:e2e:serial` 复现 |
| `OPS_E2E_USERNAME` / `OPS_E2E_PASSWORD` | **仅临时**覆盖登录；须在 PR/说明写原因 |
| `OPS_E2E_TENANT_ID` | 运营 Playwright「圈子系统」等用例 URL 租户（默认 `t_eb78751bae84`） |
| `OPS_E2E_CIRCLE_OWNER_USER_ID` | 可选：`circle-system-full.spec.ts` 创建圈子时写入 **圈主 user_id**（须租户内已存在用户） |

### 4.4 运作架构与测试编写规范

#### 4.4.1 认证共享（globalSetup + storageState）

所有 Playwright E2E 测试通过 **`tests/e2e/globalSetup.ts`** 在进程启动时完成一次登录，将 sessionStorage（含 `kd.ops.token`）保存为 `tests/e2e/.auth/state.json`。各 spec 文件通过 `storageState` 配置自动注入登录态，**不再在每个测试中调用 `loginAsAdmin()`**。

**原理**：Playwright 1.49+ 的 `context.storageState()` 已支持保存 sessionStorage，token 可通过跨用例共享。

**新增 spec 文件时的约束（MUST）**：
1. **不要**添加 `import { loginAsAdmin }` 或调用 `loginAsAdmin()`（除非测试登录流程本身）
2. **不要**在 `beforeAll` 中写后端健康检查——由 `globalSetup.ts` 统一处理
3. **导入健康标志**：`import { isBackendReady } from "./helpers/healthFlag"`
4. **`beforeEach` 中加跳过逻辑**：
   ```typescript
   test.beforeEach(() => {
     if (!isBackendReady()) test.skip();
   });
   ```
5. 直接写业务断言，`page` 已处于已登录状态

**与 §4.1 的关系**：`isBackendReady()` 仅配合 **`SKIP_OPS_E2E=1`** 或运行中后端掉线等场景；**合入 / `/tdd` 验收**须先满足 §4.1（启动后端或文档化豁免），**不得**用「每条 `test.skip`」逃避 **`globalSetup` 抛错、非零退出** 的合入门禁。

**模板（新增 spec 文件）**：
```typescript
import { expect, test } from "@playwright/test";
import { isBackendReady } from "./helpers/healthFlag";

test.describe("模块名称", () => {
  test.beforeEach(() => {
    if (!isBackendReady()) test.skip();
  });

  test("测试描述", async ({ page }) => {
    await page.goto("/path/to/page");
    await expect(page.getByTestId("some-element")).toBeVisible();
  });
});
```

**特例 `login.spec.ts`**：须添加 `test.use({ storageState: undefined })` 以禁用预认证，显式调用 `loginAsAdmin()`。

#### 4.4.2 Workers 与数据隔离

Playwright 并行 worker 数由 `playwright.config.ts` 中 `resolveWorkers()` 决定：
- 本地：`Math.min(6, availableParallelism)`（6 核即 6 个 worker）
- CI：`Math.min(2, availableParallelism)`
- 可通过 `OPS_E2E_WORKERS` 环境变量覆盖

写测试时的注意事项：
- **`fullyParallel: false`** 保持不变——同一 `.spec.ts` 文件内的测试顺序执行
- **跨文件并行**：不同 spec 文件由不同 worker 并行执行
- **写入的数据**使用 `Date.now()` + `Math.random()` 保证唯一性（见 `ensureTradeOrder.ts`、`audit-log.spec.ts` 中的 `uniquePermKey()`），无需额外隔离措施
- 若并行时观察到偶发竞争：临时设 `OPS_E2E_WORKERS=1` 或 `pnpm run test:e2e:serial` 复现

#### 4.4.3 保持的约定（不做改变）

- `maxFailures: 1` — 首个失败即停（AGENTS.md 硬约束）
- `test:e2e:headed` — 有头调试
- `OPS_E2E_NO_BAIL=1` — 排查时临时收集多条失败
- 默认账号 `dev01` / `kangdou` — 禁止修改

### 4.5 登录账号（固定）

- **`tests/e2e/helpers/loginAsAdmin.ts`** 默认 **`dev01` / `kangdou`**。
- **禁止**为本地无用户等原因改仓库默认账号；应在环境中创建/迁移用户（如 Flyway **`V14__seed_ops_user_dev01.sql`**）或数据库修复。
- 替代账号仅用环境变量临时覆盖并注明原因。

---

## 5. 微信小程序 E2E（`frontend`）

### 5.1 环境初始化（Agent 须协助用户）

1. `cd frontend && pnpm install`
2. 安装 **微信开发者工具**，开启 **设置 → 安全设置 → 服务端口**
3. 设置 **`WECHAT_CLI_PATH`** 或 **`WECHAT_WEB_DEVTOOLS_CLI`**（CLI 可执行文件路径）
4. `pnpm run build:mp-weixin`（或保证 `dist/dev/mp-weixin` / `dist/build/mp-weixin` 存在）
5. 后端 **`http://127.0.0.1:8080`** 可用（登录、code 换 session 等）
6. 国内：`HTTPS_PROXY` / `HTTP_PROXY` + **`NO_PROXY=localhost,127.0.0.1,::1`**

### 5.2 预检与执行

```bash
bash scripts/e2e/mp-weixin-preflight.sh
# 或
cd frontend && pnpm run e2e:mp:preflight

cd frontend && pnpm run e2e:mp-weixin
cd frontend && pnpm run e2e:mp-weixin:p0-trade   # P0：登录 → 下单/支付/退款/mock → Node 校验订单 REFUNDED
cd frontend && pnpm run e2e:wechat-login:visible   # 可选：可见窗口
cd frontend && pnpm run e2e:wechat-circle:visible # 已登录：圈子 Hub → 详情 / 广场冒烟
cd frontend && pnpm run e2e:wechat-circle-full:visible # 已登录：圈子 Hub → 详情 → 加入 → 人脉 Tab → 活动列表 → 发动态 → 详情（须 8080 + 微信 CLI；可选 `WECHAT_E2E_CIRCLE_FULL_CHAIN=1` 走 `e2e:wechat-circle:visible` 同路径）
```

### 5.3 变量与行为

| 变量 | 含义 |
|------|------|
| `WECHAT_E2E_CIRCLE_FULL_CHAIN` / `WECHAT_E2E_CIRCLE_FULL` | 设为 `1` 时，`e2e:wechat-circle:visible` 在 Hub→详情后继续 **加入 / 人脉 / 活动 / 发动态** 全链路（与 `e2e:wechat-circle-full:visible` 等价） |
| `WECHAT_MINIPROGRAM_PATH` / `MINIPROGRAM_PROJECT_PATH` | 小程序编译产物目录 |
| `WECHAT_E2E_NO_BAIL=1` | `wechat-login:visible` 在失败后按间隔重试（默认首个失败即停） |
| `WECHAT_E2E_HEADED=1` | 小程序 automator 相关脚本**非静默**：终端输出 launch 心跳、进度、`islogin` 预检等（默认静默，类比无头） |
| `WECHAT_E2E_P0_FLOW_MS` | `e2e:mp-weixin:p0-trade` 内等待小程序完成 HTTP 链路的超时（毫秒；**默认 60s**） |
| `WECHAT_E2E_P0_RELAUNCH_MS` | 单次 `reLaunch` 上限（默认 **25s**；工具卡住时在此时间内失败退出） |
| `WECHAT_E2E_P0_LOGIN_FLOW_MS` | `runLoginFlowOnce` 上限（默认 **55s**） |
| `WECHAT_E2E_P0_ASSERT_MS` | `assertUserCenterLoggedIn` 上限（默认 **45s**） |
| `WECHAT_E2E_P0_POLL_BTN_MS` | 查找「执行 P0 全链路」按钮（默认 **35s**） |
| `WECHAT_E2E_P0_CURRENT_PAGE_MS` | 单次 `currentPage()` 上限（默认 **8s**） |
| `E2E_API_BASE_URL` / `WECHAT_E2E_API_BASE` | P0 脚本在 Node 侧二次校验订单时的后端 origin（默认 `http://127.0.0.1:8080`） |
| `WECHAT_E2E_TENANT_ID` / `TENANT_ID` | P0 Node 校验请求头 `X-Tenant-Id`（默认与小程序 `app.config` 一致） |

详见 **`frontend/e2e/README.md`**。

---

## 6. 自定义命令（Cursor / OpenCode）

| 命令 | 作用 |
|------|------|
| **`/op-e2e`** | 运营后台 Playwright：说明见第 4 节 |
| **`/mp-e2e`** | 小程序 E2E：说明见第 5 节 |

命令正文位于 **`.agents/commands/`**。

---

## 7. CI 与代理

- Playwright 在 CI 中通常为 **无头**；不要默认依赖本机 Chrome。
- 中国大陆：`playwright install` / `pnpm install` 前设置代理；**勿**让本机 `localhost` 走代理（设 `NO_PROXY`）。

---

## 8. 关联文档

- `.agents/rules/kangdou-testing-coverage.md` — 全栈测试门槛与 E2E 纪律
- `docs/dev/wechat-miniprogram-ship-quality.md` — 小程序构建与 WXSS
- `AGENTS.md` — 项目命令表与前端排障顺序
- `docs/architecture/backend-logging-executable-plan.md` — 后端 **`local` 双写 / `test` 仅控制台 / `prod` 文件** 与滚动容量（与 §3.1 互补）
- `.agents/skills/architecture-review-e2e-tdd/SKILL.md` — 架构审查与 E2E 门禁

---

## 9. Agent 自检（执行 E2E 任务结束前）

1. 是否已按第 3 节顺序排查过失败（若失败）？
2. 是否未擅自修改约定默认账号 / bail 策略？
3. 是否在对应子项目目录执行了文档中的命令并保留终端输出？
4. 是否遵守 **§2.5**（无假绿、无未授权降级、执行中未擅自改测；纯格式化除外）？

---

---

## 经验：mock-login 租户 ID 必须与项目配置一致

### 场景
H5 E2E 测试通过 `request` fixture 直调 `/api/dev/mock-login`，使用 `X-Tenant-Id: 1`。后端返回 "Tenant not found"，所有测试登录失败。

### 根因
项目默认租户 ID 是 `t_eb78751bae84`（定义在 `src/tenant/config.ts` 和 `.env.dev`），不是 `"1"`。硬盘编码的 `"1"` 在数据库中不存在。

### 解决方案
```ts
// E2E 测试中
const apiResp = await request.post("http://127.0.0.1:8080/api/dev/mock-login", {
  headers: { "X-Tenant-Id": "t_eb78751bae84" }, // 使用真实租户 ID
  data: { userId: "u_xxx", nickname: "xxx" },
});
```

### 预防
- 永远不要硬编码 `X-Tenant-Id: "1"`
- 从项目配置 `src/tenant/config.ts` 获取默认租户 ID：`TENANT_ID: "t_eb78751bae84"`
- E2E 测试文件顶部声明常量 `const TENANT_ID = "t_eb78751bae84"`

---

## 修订记录

| 日期 | 说明 |
|------|------|
| 2026-05-08 | §3.1：强调 local 双写与控制台为同一事件；`ts=` 与终端格式差异；关联 `backend-logging-executable-plan.md` |
| 2026-05-11 | 新增 **§2.5 E2E 执行契约**（高优先级）：禁止假绿与降级、执行会话内测试冻结、新会话不自动解冻、格式化豁免、plan 跨端主路径、收口汇报；与 `docs/dev/kangdou-e2e-execution-contract.md` 对齐 |
