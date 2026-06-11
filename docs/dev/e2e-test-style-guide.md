# E2E 测试编写规范

> 本规范将优化成果固化为可执行规则，所有 agent 和开发者在编写 E2E 测试前必须阅读。

## 1. 超时约定

| 场景 | 推荐值 | 说明 |
|------|--------|------|
| 全局 per-test timeout | 60s | `playwright.config.ts` 全局，特殊情况显式覆盖 |
| `page.goto()` | 30s | 本地 SPA 导航应在 3-5s 内完成 |
| `toBeVisible()` | 15s | 首屏/重要元素可见性断言 |
| `toContainText()` | 15s | 异步数据加载后的文本断言 |
| `toBeHidden()` | 10s | 弹窗/抽屉关闭 |
| expect 默认 | 15s | `playwright.config.ts` 全局，一般不必覆盖 |
| `auth.setup` 登录等待 | 60s | 涉及 OAuth 重定向，保留缓冲 |
| 后端异步操作 | 45s | 涉及后端异步任务的测试 |

**核心认知：** 缩小超时不影响绿跑（测试通过时速度不变），但能让红跑（有问题时）更快失败，缩短调试反馈周期。不要随意放大超时掩盖问题。

## 2. 禁止反模式

### ❌ `page.waitForTimeout()`
必须用 Playwright 自动等待（`toBeVisible` / `waitFor` / `toHaveURL`）替代。

**例外：** retry 退避循环中的延迟（须加 `// eslint-disable-next-line playwright/no-wait-for-timeout` 注释）。

### ❌ 在有 `storageState` 的 spec 中重复调用 `loginAsAdmin()`
`auth.setup.ts` 已预认证并写入 `storageState`，每个 spec 共享认证状态。

### ❌ CSS class 选择器（`.el-table`、`.el-menu-item`）
优先 `getByTestId`、`getByRole`、`getByText`。测试专用 data-e2e 属性格式：
- 运营后台：`ops-*`（如 `ops-module-data-table`）
- 联合套卡：`joint-card-*`（如 `joint-card-governance-table`）

### ❌ 跨端 Playwright 测试拆成多次 `npx playwright test` 调用
合并到同一次 Playwright 调用内，避免 ~20s setup overhead。

### ❌ 小程序测试的每个 `it()` 内独立 `automator.launch()`
用 `beforeAll` 启动一次，`afterAll` 关闭，`afterEach` 用 `reLaunch` 重置状态。

## 3. 数据创建原则（禁止 SQL）

所有 E2E 测试数据**必须通过 API 动态创建**，禁止写 SQL INSERT 语句。

### 理由

- SQL 绕过业务逻辑层，可能建立不符合真实约束的数据（如缺少必要关联记录）
- SQL 语句直接依赖数据库 schema，重构或迁移后容易失效
- API 创建的数据经过完整校验和默认值填充，更接近真实用户场景
- SQL 硬编码 ID，违反「所有 ID 由服务端自动生成」原则

### 允许的 API 方式

| 数据类型 | 方式 | 示例 |
|----------|------|------|
| 店铺/SPU/SKU | 运营 merchant-center API | `POST /api/platform/merchant-center/shops` |
| 用户 | tenant-core API | `POST /api/tenant-core/users` |
| 会话 | E2E helper API | `POST /api/platform/joint-cards/e2e/session` |
| 店铺成员关系 | E2E helper API | `POST /api/platform/joint-cards/e2e/user-mobile` |
| 用户手机号 | tenant-core API | `PATCH /api/tenant-core/users/{id}/mobile` |

### 例外

- **E2E 基础设施**的 setup/teardown 脚本（如 `auth.setup.ts` 中的健康检测、`globalSetup` 中的环境检查等不与业务数据直接相关的操作）
- **业务数据清理**可通过 API 或 SQL TRUNCATE（仅测试结束后清理，且须由独立脚本执行）

### 强制要求

- 测试代码中出现 `INSERT INTO`、`db.execute`、`mysql.*execute` 等 SQL 构造且非 exception 注释的，Review 必须驳回
- 辅助函数中也不得包含 SQL（如 `createJointCardPrerequisites` 中创建店铺必须走 API）

## 4. Tag 分档约定

Playwright 测试使用 tag 过滤，支持 `--grep @tagname` 选择性执行。

| Tag | 用途 | 预估数量 | 执行时间 |
|-----|------|---------|---------|
| `@smoke` | 核心功能冒烟，开发迭代时必跑 | 5-10 | <1min |
| `@cross` | 跨端串联测试 | 5-10 | ~2min |
| 无 tag | 全量验证（默认），提交/CI 前必跑 | 全部 | ~5-8min |

在测试名称中添加 tag：
```ts
test("治理页可访问 @smoke", async ({ page }) => { ... });
test("跨端搜索验证 @cross", async ({ page }) => { ... });
```

NPM 脚本：
```bash
pnpm run test:e2e:smoke   # --grep @smoke
pnpm run test:e2e:cross   # --grep @cross
pnpm run test:e2e         # 全量
```

## 5. 小程序 E2E 模式

### 测试结构

```ts
let miniProgram: MiniProgram;

beforeAll(async () => {
  miniProgram = await automator.launch(flowOpts);
}, 60_000);

afterAll(async () => {
  await miniProgram.close();
}, 10_000);

afterEach(async () => {
  await miniProgram.reLaunch('/pages/index/index');
}, 15_000);
```

### 导航方式

- 首次进入页面或测试间重置：`reLaunch`（销毁所有页面栈重新加载）
- 同一测试内跳转：`navigateTo`（轻量，保留页面栈）
- 返回上一页：`navigateBack`

### 独立 runner 模式

- 每个 runner 自行 launch/close，互不影响
- 全量验证：`pnpm run e2e:mp-weixin:all` 共享一次 DevTools 实例

## 6. Playwright E2E 模式

### 基本结构

```ts
import { expect, test } from "./fixtures";
import { isBackendReady } from "./helpers/healthFlag";

test.describe("功能模块名称", () => {
  test.beforeEach(() => {
    if (process.env.SKIP_OPS_E2E === "1" || !isBackendReady()) {
      test.skip();
    }
  });

  test("用例描述", async ({ page }) => {
    // ...
  });
});
```

### 配置

- `playwright.config.ts` 已配置 `webServer`（`reuseExistingServer: true`），服务已运行时不重复启动
- 默认 `workers: 1`（安全），可通过 `OPS_E2E_WORKERS=2` 启用并行
- 失败自动重试 1 次（`retries: 1`）
- Trace 保留到 `test-results/`，CI 中 `on-first-retry`

### 选择器优先级

1. `getByTestId()` — 最可靠
2. `getByRole()` + `getByText()` — 次优
3. `locator()` with CSS — 最后手段（必须有注释说明为何无法用前两者）

## 7. 超时值速查

Playwright 配置层全局默认值已覆盖大部分场景。spec 文件中只在需要**大于**全局值的场景显式设置 timeout：

```ts
// ✅ 需要大于全局默认值时显式设置
await expect(table).toContainText(text, { timeout: 25_000 });

// ❌ 不需要等于或小于全局默认值
await expect(page).toHaveURL(/pattern/, { timeout: 15_000 }); // 15s 是全局 expect timeout，可以省略
```

## 8. 验证 Checklist

提交 E2E 测试代码前检查：

- [ ] 是否避免了 `waitForTimeout`？如有，加 eslint-disable 注释说明理由
- [ ] 是否使用了 `getByTestId` / `getByRole` 而非 class 选择器？
- [ ] **列表/详情页是否断言了关键 API 200（§11）？**
- [ ] timeout 是否在约定范围内？
- [ ] 小程序多测试是否共用了 `beforeAll` 中的 `launch`？
- [ ] Playwright 测试是否依赖了 `loginAsAdmin`？在 `storageState` 模式下不应调用
- [ ] 是否添加了合适的 tag（`@smoke` / `@cross`）？
- [ ] 是否运行过 `pnpm run lint` 且无 error？

## 9. eslint-plugin-playwright 规则

项目已集成 `eslint-plugin-playwright`，自动检测：

| 规则 | 级别 | 说明 |
|------|------|------|
| `no-wait-for-timeout` | error | 禁止 `waitForTimeout` |
| `prefer-native-locators` | warn | 优先使用 `getByTestId`/`getByRole` |
| `no-force-option` | warn | 谨慎使用 `force: true` |
| `valid-expect` | error | 确保 expect 正确使用 |

运行方式：`pnpm run lint`

## 10. 跨端 E2E 规范

### 环境变量

| 变量 | 用途 | 设置方 |
|------|------|--------|
| `CROSS_ORDER_NO` | 跨端订单号（统一命名） | 小程序 runner 捕获 |
| `CROSS_REFUND_ID` | 跨端退款 ID | 小程序 runner 捕获 |
| `OPS_E2E_TENANT_ID` | 运营后台租户 | 脚本统一注入 |
| `WECHAT_E2E_TENANT_ID` | 小程序租户 | 环境变量 |

### 执行顺序

1. 小程序阶段（单次 DevTools 启动）：create → pay → apply → finalize
2. 运营 Playwright（单次调用）：注入 `CROSS_ORDER_NO`，顺序执行所有运营验证

## 11. 列表页必须断言关键 API（禁止 UI 假绿）

**背景**：2026-05-18 联合套卡运营列表 API 返回 500，旧用例仅断言 `el-table` 可见仍通过。复盘见 [`incidents/2026-05-18-joint-card-ops-api-e2e-gap.md`](./incidents/2026-05-18-joint-card-ops-api-e2e-gap.md)。

凡 **依赖后端列表/详情 JSON** 的运营页，E2E **至少满足其一**：

1. **直连 API 契约**（推荐用于 smoke）：`operation-backend/tests/e2e/helpers/opsApiContract.ts` + 独立 `*-api-contract.spec.ts`，断言 HTTP 200 与 `items` 等字段。
2. **页面 + `waitForResponse`**：进入页面前 `page.waitForResponse` 匹配真实列表 URL，用 `expectOpsJsonOk`；并断言 **无** `.el-message--error`。

```ts
const listResp = page.waitForResponse(
  (r) => r.request().method() === "GET" && r.url().includes("/api/platform/joint-cards") && r.ok(),
  { timeout: 45_000 }
);
await page.goto(`/joint-cards/governance?tenantId=${tenantId}`);
await expectOpsJsonOk(await listResp, "governance list");
await expect(page.locator(".el-message--error")).toHaveCount(0);
```

**禁止**：仅 `toBeVisible(.el-table)` 或标题文案作为列表页唯一断言。

联合套卡合入门禁须包含：`pnpm run test:e2e -- joint-card-api-contract`（或全量 `test:e2e`）。

## 12. 基准 CheckList

每季度或每次大幅改动 E2E 基础设施后，运行基准测试：

```bash
time pnpm run test:e2e 2>&1 | tee /tmp/e2e-baseline-$(date +%Y%m).txt
```

与优化完成时的基线对比，若退化超过 20% 则标记回查。

## 13. 🚨 数据清理纪律（硬性要求）

E2E 测试通过 API 或 UI 操作创建的**所有业务数据**，必须保证在测试完成后被清理。违反此规约的 PR 一律驳回。

### 核心原则

1. **谁创建谁清理** — 每个测试或测试套件对自己写入的数据负责
2. **兜底优先** — `test.afterAll` 必须提供兜底清理，不依赖 `afterEach`（单个用例失败不影响其他用例）
3. **前缀隔离** — 所有 E2E 创建的数据在名称/标识中必须包含 `E2E` 前缀，便于识别和批量清理
4. **幂等清理** — 清理逻辑必须是幂等的：多次执行不会报错，已不存在的数据跳过即可

### 清理模式

```ts
// ✅ 正确：afterAll 兜底清理
test.describe("功能名称", () => {
  let createdIds: string[] = [];

  test("创建数据", async ({ request }) => {
    const res = await request.post("/api/...", { data: { name: "E2E_测试数据" } });
    const body = await res.json();
    createdIds.push(body.id);
  });

  test.afterAll(async ({ request }) => {
    for (const id of createdIds) {
      await request.delete(`/api/.../${encodeURIComponent(id)}`).catch(() => {});
    }
  });
});

// ✅ 正确：批量清理（按分组/前缀匹配）
test.afterAll(async ({ page }) => {
  const token = await page.evaluate(() => sessionStorage.getItem("kd.ops.token"));
  // 查询匹配前缀的数据并逐条删除
});
```

### 禁止行为

- ❌ 创建了数据但无 `afterAll` 兜底清理
- ❌ 用 `afterEach` 代替 `afterAll`（单用例失败会跳过 afterEach，导致残留）
- ❌ 依赖外部脚本做清理（CI 中断时脚本不执行）
- ❌ 清理失败抛异常阻断后续（应捕获异常，best effort 清理）

### 例外

- 只读测试（不创建、不修改任何数据）不需要清理
- 通过 SQL TRUNCATE 清理的独立脚本仅允许在 CI 专用数据库执行，禁止在共享开发库使用
