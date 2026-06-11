---
description: 运营后台 Playwright 端到端（operation-backend，默认无头，TDD 与失败先收集再分析）
---

在**主仓库根目录**或 **`operation-backend/`** 执行（需本机 **`8080` 后端** + **`5174` Vite**，或让 Playwright 自动 `webServer` 起 dev）：

**后端未监听或健康检查失败时**：`pnpm run test:e2e` **会非零退出**（`globalSetup` 抛错），**禁止**依赖「未起后端 → 全体 skip → 退出码 0」。须先在 **`backend/`** 启动本地后端（典型 **`mvn spring-boot:run`**），待 **`${OPS_E2E_API_BASE:-http://127.0.0.1:8080}/actuator/health`** 可用后再跑。**TDD 中若改过 `backend/`**，再次跑 E2E 前 **须重启后端**。

```bash
cd operation-backend && pnpm run install:e2e   # 首次：本机须已装 Google Chrome；playwright install chrome
cd operation-backend && pnpm run test:e2e
```

- **浏览器（MUST）**：运营 E2E **一律本机 Google Chrome**（`channel: "chrome"`），无头/有头相同；详见 `docs/dev/e2e-testing-agent-guide.md` **§4.0**。CI 无 Chrome：`pnpm run test:e2e:ci`。
- **默认无头**（`playwright.config`）。需要**有界面**调试：`pnpm run test:e2e:headed` 或 `OPS_E2E_HEADED=1 pnpm exec playwright test`。
- **登录账号**：`dev01` / `kangdou`（勿为通过测试改 `tests/e2e` 默认）；仅临时覆盖用 `OPS_E2E_USERNAME`、`OPS_E2E_PASSWORD`。
- **首个失败即停**：默认 `maxFailures: 1`；要看全部失败列表时 **`OPS_E2E_NO_BAIL=1`**。
- **`OPS_E2E_API_BASE`**：`globalSetup` 探测 **`/actuator/health`** 与浏览器内登录 API 所连后端根 URL（默认 `http://127.0.0.1:8080`）；后端不在本机 8080 时设置，须与 Vite 代理目标一致。
- **并行加速**：默认多 worker **跨 spec 文件**并行（`playwright.config.ts` 内 `resolveWorkers()`；本地最多 4、CI 最多 2）。显式控制：`OPS_E2E_WORKERS=6 pnpm run test:e2e`；强制串行排障：`pnpm run test:e2e:serial` 或 `OPS_E2E_WORKERS=1`。详见 `docs/dev/e2e-testing-agent-guide.md` §4.3。
- 已有 Vite 且不想再起：`SKIP_OPS_E2E_SERVER=1`。
- **`SKIP_OPS_E2E=1`**：**仅**流水线等无法在 Job 内启动 `8080` 时使用（PR 须说明）；**禁止**本地/Agent 默认用来逃避联调；**禁止**将「全体 skip」当运营 E2E 通过。

### TDD 与失败处理（MUST）

1. 先**红**后**绿**：改行为前先补/调测试，再最小实现。任一条红则**先修该条**，单条/单文件重跑**绿**后再跑**完整** `pnpm run test:e2e`。
2. 失败时**先收集再分析**（与 `AGENTS.md` 一致）：**Console** → **Network** → **后端日志**（终端或 **`backend/logs/kangdou-local.log`**；**优先 `requestId`**，`ts=` 含义见 `docs/dev/e2e-testing-agent-guide.md` §3.1）；禁止未看证据就改断言或改约定账号。

**你必须：** 在 `operation-backend` 下执行并贴出**完整终端结果**；若红，按上条顺序说明已收集的线索再动代码或配置。

策略：阿里云 Codeup 与本地服务无关；禁止 `gh`。
