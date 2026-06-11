---
description: 微信小程序端到端（frontend 子模块 miniprogram-automator，依赖 backend 8080；含环境预检与 TDD）
---

**说明：** `/mp-e2e` 跑的是 **`frontend/` 微信小程序** 自动化（`e2e:mp-weixin` / `wechat-login` 脚本），**不是** `backend` 的 `mvn verify`。若需要 **Java 接口集成测**，在 **`backend/`** 执行 `mvn -q verify`。

### 1. 环境初始化（Agent 须协助用户完成）

在 **`frontend/`** 下：

1. `pnpm install`
2. 安装/配置 **微信开发者工具**，开启 **设置 → 安全设置 → 服务端口**
3. 设置 **CLI** 环境变量（二选一）：
   - `export WECHAT_CLI_PATH="/Applications/wechatwebdevtools.app/Contents/MacOS/cli"`（macOS 示例）
   - 或 `WECHAT_WEB_DEVTOOLS_CLI`
4. 构建小程序产物：`pnpm run build:mp-weixin`（或 `dev` 产物在 `dist/dev/mp-weixin` 时保证已编译）
5. 启动 **后端** `http://127.0.0.1:8080`（登录、jscode2session 等依赖）
6. 国内网络：为终端设置 `HTTPS_PROXY` / `HTTP_PROXY`，并 `NO_PROXY=localhost,127.0.0.1,::1`

**预检（推荐先跑）** — 在**主仓库根**或 `frontend`：

```bash
bash scripts/e2e/mp-weixin-preflight.sh
# 或
cd frontend && pnpm run e2e:mp:preflight
```

通过后再跑 E2E。

### 2. 执行小程序 E2E

在主仓库根或 `frontend`：

```bash
cd frontend && pnpm run e2e:mp-weixin
```

可见窗口排障（可选）：

```bash
cd frontend && pnpm run e2e:wechat-login:visible
```

### TDD 与失败处理（MUST）

1. **首个失败即停**（`run.mjs` 一次失败即退出；`wechat-login:visible` 默认同理，连续重试需 **`WECHAT_E2E_NO_BAIL=1`**）。先修当前步，再全量重跑。
2. 失败时**先收集再分析**：**微信开发者工具 Console** → **Network**（或 automator 日志）→ **后端日志**（终端或 **`backend/logs/kangdou-local.log`**（`local` profile）；**优先 `requestId`** 对齐，`ts=` 为服务端写日志时刻，见 `docs/dev/e2e-testing-agent-guide.md` §3.1）。禁止未看日志就改脚本断言。

**你必须：** 执行预检 + E2E 命令并贴**完整输出**；若红，按上条列出已收集的 Console/Network/日志要点。

策略：与 Codeup 无关；禁止 `gh`。
