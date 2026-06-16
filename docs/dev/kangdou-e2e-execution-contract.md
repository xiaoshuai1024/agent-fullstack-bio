<!--
description: 高优先级 — E2E 禁止假绿与降级；小程序主路径须走正式页面（见 e2e guide §1.1）；执行会话内测试代码冻结；方案须列跨端主流程；详文见 e2e-testing-agent-guide §2.5
globs: "**/*"
alwaysApply: false
-->

# E2E 执行契约（高优先级 · MUST）

本规则与 [`docs/dev/e2e-testing-agent-guide.md`](../../docs/dev/e2e-testing-agent-guide.md) **§2.5**、[`.agents/rules/kangdou-testing-coverage.md`](../../.agents/rules/kangdou-testing-coverage.md)、[`docs/superpowers/PLAN_WRITING_CONTRACT.md`](../../docs/superpowers/PLAN_WRITING_CONTRACT.md) **§7**、[`docs/dev/AGENT_WORKFLOW_CONSTRAINTS.md`](AGENT_WORKFLOW_CONSTRAINTS.md) **§2.4** 一致；执行 E2E、写 plan、TDD 收口时**必须**遵守。冲突时以**更严格**条文为准。

## 摘要（Agent 不可跳过）

1. **已纳入合入门禁或文档默认路径的 E2E**：不得**降级**（关 bail、滥用 `SKIP_*`、批量 skip、弱化断言、改默认账号、用子集命令冒充全量等）。
2. **一旦为当前验收任务开始执行**约定 E2E 命令：在**用户明确书面允许**前，**不得**改 `tests/e2e/**`、`**/e2e/**`、与断言/超时/skip 相关的 Playwright·Jest 配置及测试辅助逻辑（**纯格式化除外**，见 §2.5 详文）。
3. **仅新开 Cursor 聊天、同一分支同一需求**：**不**视为解除冻结；须**用户换任务声明**或**授权改测**才可改测试代码。
4. **红**：先排环境与实现（8080、DB、Flyway、重启后端、Console→Network→日志），**禁止**未排查就以改测骗绿。
5. **Plan**：须含跨端 **E2E 主路径**（若涉及多系统）及 **§7.2 脚本保障逻辑**，见 `PLAN_WRITING_CONTRACT.md` §7。
6. **小程序 E2E**：主路径须走 **正式产品页面**；禁止新增 `pages/e2e/*` 专测页作为新特性主载体；详见 `e2e-testing-agent-guide.md` **§1.1**。

完整条款、示例与汇报要求见 **`docs/dev/e2e-testing-agent-guide.md` §2.5**。

---

## 经验：异步退款管线的 E2E 断言注意事项（2026-05-27）

### 场景
`joint-card-refund.spec.ts` 中 `POST /api/tenant/joint-card-refunds/full-child` 接口返回 `refundStatus: "COMPLETED"` 断言失败，实际返回 `"REFUNDING"`。

### 根因
退款管线是异步的：PENDING → (微信API) → REFUNDING → (微信回调) → REFUNDED。同步 API 返回的 refundStatus 永远是 `"REFUNDING"`，从不返回 `"COMPLETED"`。最终 `"REFUNDED"` 状态只能通过微信异步回调到达。

### 解决方案
1. 断言改为 `expect(refundBody.refundStatus).toBe("REFUNDING")` — 匹配实际同步返回值
2. 幂等性处理：重复调用返回 `200` 而非 `409`，body 中含 `idempotent: true`

### 预防
- 写退款 E2E 前先查后端源码确认同步状态值（`REFUNDING` 非 `COMPLETED/REFUNDED`）
- 微信支付回调触发的异步状态变更在 E2E 环境中不可用，不要断言终态
- 幂等性：重复退款调用返回 200+`idempotent:true`，非 HTTP 409

---

## 经验：E2E 假绿 — 测试全绿但功能不存在

### 场景
部署时发现公告功能没有对应后端 Controller 和 DB 表，但运营后台单测（`announcementOps.test.ts`）全部通过，E2E 测试也未报错——测试报告全绿。

### 根因
1. **API 层测试 mock 了整个 HTTP 层**：`announcementOps.test.ts` 使用 `vi.mock("../api/jsonClient", () => ({ runRequest: mockRunRequest }))`，测试只验证 URL 拼接格式，不发送真实 HTTP 请求。后端不存在对应 Controller 时测试依然通过。
2. **E2E 测试未覆盖该功能模块**：Playwright E2E 只覆盖了核心业务流程（交易、租户管理），公告功能不在 E2E 用例范围内。
3. **单元测试不验证后端存在性**：前端 API 层测试默认只测自身代码，不验证后端的路由注册情况。

### 解决方案
1. API 层测试至少验证后端路由存在性（HTTP 200/401 而非 404），而非纯 mock
2. 合约一致性检查脚本 `scripts/contract-check.sh` 自动比对前端 URL ↔ 后端路由
3. 每个新功能模块至少一条 Playwright E2E 冒烟用例（页面能打开 + 列表能加载）

### 预防
- API 层测试中，`vi.mock` 覆盖 HTTP 客户端时不等于覆盖了"后端存在性"——这是两层完全不同的验证
- E2E 必须端到端：不 mock 网络层，请求真实抵达后端
- 新功能上线前审查：Flyway DDL、Controller 注册、前端 API 路径三者对齐

---

## 经验：E2E 测试禁止以环境/数据问题为借口中断

### 场景
测试过程中遇到页面加载失败、API 返回错误、数据不存在等情况时，本能反应可能是跳过测试。

### 根因
项目有完整的开发环境、测试账号、`.env.dev` 配置。H5 Playwright 和运营后台 E2E 已经过充分验证是可用的。任何"环境不可用""依赖不可达""数据缺失"的说法本质上是没有先排查。

### 规则

| 借口 | 正确的排查/修复方式 |
|------|-------------------|
| "H5 环境不可用" | `lsof -i :5173` 检查端口 → `pnpm run dev:h5` 启动 → 读日志修 |
| "后端没启动" | `cd backend && KANGDOU_IM_RABBITMQ_ENABLED=false mvn spring-boot:run -Dspring-boot.run.profiles=local -Dmaven.test.skip=true` |
| "MySQL 不可达" | `mysql -h 192.168.100.67 -u root -proot123456 kddev -e "SELECT 1"` |
| "Redis/ES/RabbitMQ 不可用" | 后端禁用：`KANGDOU_IM_RABBITMQ_ENABLED=false MANAGEMENT_HEALTH_RABBIT_ENABLED=false` |
| "缺少数据（SKU/商品等）" | 运营后台创建 / SQL INSERT / CREATE TABLE |
| "表不存在/列不兼容" | Flyway 迁移没执行？手动补 `ALTER TABLE` / `CREATE TABLE` |
| "Playwright 没装" | `pnpm exec playwright install chromium` |

三不原则：不跳过、不绕行、不找借口——先排查再说话。所有 `.env.dev` 配置的组件必须视为可用，连不上就排查那个组件。
