<!--
description: 运行或修改 E2E（Playwright、小程序 automator、Jest e2e）前必读 docs/dev/e2e-testing-agent-guide.md
globs: "**/*"
alwaysApply: false
-->

# E2E 执行门禁（MUST）

凡**运行、调试、编写或修改**仓库内端到端测试（包括但不限于：`pnpm run test:e2e`、`playwright test`、`e2e:mp-weixin`、`jest --roots e2e`，以及编辑 `**/tests/e2e/**`、`**/e2e/**`、`playwright.config.ts`、`scripts/e2e/**`），必须先 **完整阅读**：

**[`docs/dev/e2e-testing-agent-guide.md`](docs/dev/e2e-testing-agent-guide.md)**

并遵循其中的 **§1.1 小程序 E2E 须走正式产品页面**、**TDD / 首个失败即停**、**§2.5 E2E 执行契约（高优先级：禁止假绿与降级、执行中测试冻结、新会话不自动解冻、纯格式化可豁免）**、**Console → Network → 后端日志** 排障顺序（含 **`kangdou-local.log` 与 `requestId`/时间 读法 §3.1**）、**运营登录 dev01/kangdou**、**Playwright 默认无头** 与 **运营后台 E2E 须使用本机 Google Chrome（§4.0）**、**执行前保证 `8080` 后端已启动（未启动则先在 `backend/` 拉起；TDD 改后端后须重启）**、**禁止无后端时全体 skip 冒充通过**（详见该文档 **§2**、**§2.5**、**§4.1**）等约定。另须遵守 [`.cursor/rules/kangdou-e2e-execution-contract.mdc`](./kangdou-e2e-execution-contract.md)。

禁止在未阅读该文档的情况下：擅自修改 `tests/e2e` **默认登录账号**、关闭 bail/maxFailures（除文档允许的临时 `OPS_E2E_NO_BAIL` 等）、或跳过证据收集直接改断言；**禁止**在验收已开始后无用户授权修改测试语义（§2.5.2）。

---

## 经验：E2E 测试可靠性

- 浏览器上下文级别的测试（`chromium.launch` + 手动登录）比 fixture 自动登录更可靠，不受 storageState 过期影响
- `input[type="datetime-local"]` 替换为 `el-date-picker` 后，选择器需从 `input[type="datetime-local"]` 改为 `.el-date-editor input`
- 测试验证步骤导航时使用 `is-process` 而非 `is-active`

---

## 经验：小程序 E2E 热词轮播实现经验

### miniprogram-automator 环境稳定性

- `automator.launch()` 的 WebSocket 连接极易断裂（`Connection closed` / `page destroyed`）
- **连续跑多轮测试后** HTTP 端口会失联，必须杀进程 + 物理重启微信开发者工具 + 等待 10-15s
- 不能在同一 Jest 进程中反复 run 测试——每次 run 间需要重启工具

### afterEach 是崩溃放大器

- `afterEach` 里的 `reLaunch` 超时（默认 5s hook timeout）会导致 `mp` 对象连接失效
- **修复**：`afterEach` 内 `try/catch` 包裹 `reLaunch`，并设 `30_000` 超时参数
```typescript
afterEach(async () => {
  if (mp) {
    try { await mp.reLaunch("/pages/index/index"); } catch {}
  }
}, 30_000);
```

### WXML 选择器策略

- `data-e2e` 属性选择器在 `.mjs` 测试中被大量使用，理论上可用
- 但 `$('[data-e2e="xxx"]')` 在 `wx:if` 条件不满足或渲染时序未完成时返回 null
- **兄弟元素不保证同时渲染**——`search-home-entry` 存在不代表 `search-btn` 也已渲染
- 策略：先 `page.waitFor('[data-e2e="xxx"]')` 确保存在，再 `$()` 查询；兄弟元素用 `setTimeout(r, 3000)` 等待
- `page.waitFor('[data-e2e="search-btn"]')` 会卡 60s 超时——**避免用 waitFor 等兄弟元素**

### Vue scope class 在小程序中的表现

- `class="search-btn"` → WXML 变成 `class="search-btn data-v-83a5a03c"`
- `.search-btn` class 选择器仍有效（子字符串匹配）
- 但 uni-app 自定义组件（如 `<swiper>`）的 querySelector 有边界，需注意

### navigateTo 后 page 引用失效

- `tap()` 触发 `navigateTo` 后，原 `page` 对象指向旧页面
- 用 `mp.currentPage()` 获取新页面引用
- production build 中 `tap()` 可能不触发 Vue 事件（已知限制），测试需有 fallback 分支

### 构建时序

- `pnpm run dev:mp-weixin` 需等 `DONE Build complete` 再停止
- 不能用 `sleep 30 && kill %1`——应等 `DONE` 标志出现
- E2E 前必须确认构建完成，否则用旧产物跑测试会出假阳性/假阴性

### Flyway DDL 幂等性

- `ALTER TABLE ADD COLUMN` 重复执行必须加条件判断（`INFORMATION_SCHEMA.COLUMNS` 检查）
- `INSERT IGNORE` 对重复数据安全，但 DDL 需要手动防重
```sql
SET @col_exists = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tenant' AND COLUMN_NAME = 'deleted');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE tenant ADD COLUMN deleted TINYINT NOT NULL DEFAULT 0',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;
```

### HOTWORD-002/004 未通过的待查根因

- `$('[data-e2e="search-btn"]')` 和 `$(".search-btn")` 均返回 null
- HOTWORD-001（同一页面）能成功找到 `search-home-entry`
- 可能原因：`wx:if="{{o}}"` 的变量 `o`（searchModuleEnabled）与 `search-home-entry` 的 `i`（searchPlaceholder && searchModuleEnabled）不同
- **下一步排障**：用 `page.evaluate()` 打印 `searchModuleEnabled` 实际值，或 `page.wxml()` dump DOM 确认 `search-btn` 是否在 DOM 中

---

## 经验：登录+搜索全栈审查经验（2026-05-21）

### 跨层模块名一致性是审查的必检项

#### 场景
前后端/运营后台的模块 key 必须一致，否则功能异常但不报错。本次发现的不一致：

| 运营后台 | 前端搜索 API | 问题 |
|---------|-------------|------|
| `circle` | `circlePosts` | 联想词按模块筛选会失效 |
| `shop` | `shops` | 搜索结果模块 key 不匹配 |
| `joint_card` | `jointCards` | 同上 |

#### 检查清单
审查搜索功能时，逐项核对 `TABS` / `MODULE_LABELS` / API 响应的 `SearchResult` 字段名 / 运营后台 module 枚举值是否一致。

---

### 后端 jscode2session 禁止所有 mock/fallback 降级

#### 场景
微信小程序登录的 `jscode2session` 失败时，**禁止**降级为确定性 openid（即使是开发/CI 环境）。

#### 规则
- `wx.login()` code 是一次性的，mock openid 可被攻击者 5 分钟内推算
- 凭证配置不完整 → throw `HTTP_SERVICE_UNAVAILABLE`，不静默降级
- 凭证存在但调用失败 → throw 原异常，不 fallback
- 开发环境必须配真实微信凭证，不再有 `wechat-mock` 模式
- 详见 `docs/dev/auth-security-policy.md`

---

### ES @Id 类型一致性

#### 场景
Spring Data Elasticsearch 的 `ElasticsearchRepository<XxxDocument, T>` 中，泛型 `T` 必须与 Document 类的 `@Id` 字段类型一致。

#### 规则
- `SearchDocument` 的 `@Id private String id` → Repository 必须是 `ElasticsearchRepository<Xxx, String>`
- 不能用 `Long` 声明（即使 ES 自动转换能工作，`findById` 语义会出错）
- `SearchService` 未使用 Repository 做查询（走 `ElasticsearchOperations`），但未来若有人调 Repository 方法会出 bug

---

### 搜索联想词 prefix 过滤必须在 DB 层

#### 场景
C 端搜索 suggest 接口的运营配置联想词，必须在 SQL 中 `WHERE word LIKE CONCAT(?, '%')` 做前缀过滤，不能全量加载后在 Java 内存过滤。

#### 规则
- 运营可能配置数十上百个联想词
- 每个搜索输入变化的请求都全量加载 → 不必要的 DB 压力
- C 端接口 QPS 高，性能差异会被放大

---

### Vue 3 Template 中不可用顶层对象

#### 场景
Vue 3 template 只能访问到组件暴露的响应式状态和方法，以下对象**不可用**：

- `Promise` → 把 `Promise.all(...)` 提取到 script 中定义为函数
- `Math` / `Date` / `JSON` → 需要用 computed 或方法包裹
- `Object.assign` 修改响应式对象 → 虽然在 template 中可调用（作为表达式），但不推荐，建议提取到 script

---

### 敏感词管理是全局（跨租户）词库

敏感词为平台级全局词库，不按租户隔离。运营后台操作敏感词时无需选择租户，搜索命中敏感词时按全局规则处理。

---

## 经验：H5 Playwright page.request 跨域 401 — 用 page.evaluate(fetch) 替代

### 场景
Playwright 测试中，page 导航到 OPS (localhost:5174) 后，使用 `page.request.post(url, { headers })` 或 `context.request.post` 调用后端 API (127.0.0.1:8080) 持续返回 401。通过 `curl` 直接调用 API 正常。

### 根因
Playwright 的 `page.request` 在 page 跨域导航后（5174 OPS → 8080 backend），内部的 APIRequestContext 会丢失或失效部分认证状态。浏览器上下文中的原生 `fetch` 不受此影响。

### 解决方案
在 `page.evaluate()` 中使用浏览器原生 `fetch` 发起 API 请求：

```typescript
const result = await page.evaluate(async (apiUrl) => {
  const res = await fetch(apiUrl + "/api/trade/shops/2001/buy-now", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Tenant-Id": TENANT,
      "Authorization": "Bearer " + token
    },
    body: JSON.stringify({ spuId: 999001, skuId: 999001, qty: 1, fulfillmentType: "MAIL", shippingAddressId: 999002 })
  });
  return await res.json();
}, API);
```

### 预防
1. H5 E2E 中若 page 已导航到 OPS (5174)，调后端 API 优先用 `page.evaluate(fetch)`
2. 或用独立 BrowserContext 的 `context.request`（但同样可能遇到跨域认证问题）
3. 避免在 page 跨域后使用 `page.request` 调非当前 origin 的 API

---

## 经验：uni-app H5 session 不可用 — loadSession 需 localStorage fallback

### 场景
goods/detail.vue 的 `onBuyNow()` 调用 `getAccessToken()` 恒返回 `""`，导致"立即购买"按钮点击后 SPA 不导航到确认页。

### 根因
`frontend/src/auth/session.ts` 中 `getStorage()` 检查 `uni.setStorageSync` 是否存在。H5 环境下：
- `uni.setStorageSync` **存在**（typeof === "function"）
- 但 `uni.getStorageSync("KD_MINIAPP_SESSION")` 返回 **null**
- localStorage 中有 session 数据但 `getStorage()` 优先返回 `uniRuntime`，而 `uni.getStorageSync` 使用 uni-app 内部独立存储空间，不读取浏览器 localStorage

### 解决方案

在 `session.ts` 中增加 localStorage fallback（四重修改）：

```typescript
// 1. getStorage() 尾部增加 localStorage 兜底
const localStorageStorage: StorageLike = {
  setStorageSync(key, value) { localStorage.setItem(key, JSON.stringify(value)); },
  getStorageSync(key) { return JSON.parse(localStorage.getItem(key) || "null"); },
  removeStorageSync(key) { localStorage.removeItem(key); },
};

// 2. getStorage() 返回值逻辑
if (typeof localStorage !== "undefined") { return localStorageStorage; }

// 3. loadSession() — 主存储未命中时尝试 localStorage
const value = storage.getStorageSync(SESSION_KEY);
if (!value || typeof value !== "object") {
  // fallback to localStorage, sync back to primary
}

// 4. saveSession() / clearSession() — 双写到 localStorage
if (typeof localStorage !== "undefined") {
  localStorage.setItem(SESSION_KEY, JSON.stringify(session));
}
```

### 预防
1. 新增依赖 `getAccessToken()` 的 H5 E2E 测试，注入 session 时需同时写入 uni 内部存储和 localStorage：
```typescript
await page.evaluate((session) => {
  try { uni.setStorageSync("KD_MINIAPP_SESSION", session); } catch {}
  localStorage.setItem("KD_MINIAPP_SESSION", JSON.stringify(session));
}, session);
```
2. 修改 `session.ts` 的 `getStorage`/`saveSession`/`loadSession` 时注意四者联动性

---

## 经验：黄金流程 E2E 冒烟测试模式（@smoke @e2e）

### 场景
积分豆、搜索、版本公告三个模块完成手工 E2E 测试后，需要将验证过的用户旅程固化为可重复执行的自动化冒烟测试。

### 结构规范
每个黄金流程测试文件遵循以下模式：

```typescript
/**
 * {模块名}黄金流程 E2E 冒烟测试
 *
 * 用户旅程（§4A）：
 *   ① {UI 操作 1} →
 *   ② {UI 操作 2} →
 *   ③ {API 补偿/验证} →
 *   ④ {UI 验证}
 *
 * [KNOWN] {标记已知问题}
 *
 * @smoke 覆盖核心路径
 * @e2e  完整用户旅程
 */
import { expect, test } from "@playwright/test";
import { H5_BASE_URL } from "./auth-helper";

test.describe("模块黄金流程 E2E @smoke @e2e", () => {
  test("黄金流程 {描述} @smoke @e2e", { timeout: 120000 }, async ({ page, context }) => {
    // Phase 1: UI 操作
    // Phase 2: UI 操作
    // Phase N: API 验证
    // Phase N+1: OPS 验证
  });
});
```

### 命名约定
| 文件 | 用途 |
|------|------|
| `{module}-golden-flow.spec.ts` | 冒烟测试，覆盖一条完整用户旅程 |
| `{module}-smoke.spec.ts` | 基础渲染 + API 验证 |
| `{module}-e2e.spec.ts` | 完整功能 E2E（含边界 case） |
| `{module}-payment-e2e.spec.ts` | 支付相关子模块 |

### 标签规范
- `@smoke` — 冒烟级：核心页面渲染 + 主路径操作
- `@core` — 核心级：API 验证 + 主要功能
- `@e2e` — 全量级：完整用户旅程

### 已知问题标记
```javascript
// [KNOWN-UNIAPP-SHADOW] uni-app H5 Shadow DOM 使 data-e2e 不可达
// [KNOWN-PAYMENT-DB] 支付确认接口有 DB 兼容性问题
```

### 预防
1. 每个核心模块完成手工测试后，立即创建 `{module}-golden-flow.spec.ts`
2. 先列用户旅程（§4A 格式），再写代码
3. UNKNOWN 标记必须在文件头说明原因和绕行方案

---

## 经验：auth.setup storageState origin 必须与测试 baseURL 一致

### 场景
Playwright E2E 测试中，auth.setup 成功写入了 storageState，但测试用例仍显示登录页。

### 根因
`saveAuthStorageState` 以 `origin` 为 key 存储 state 到 `state.json`。auth.setup 的 baseURL 为 `http://127.0.0.1:5174`，但测试导航到 `http://localhost:5174`。两者是不同的 origin，storageState 不共享。

### 解决方案
统一 baseURL：
- Playwright config 中 `baseURL` 固定为 `http://127.0.0.1:5174`
- 测试代码中导航也使用 `page.goto('/path')` 相对路径（自动补全 baseURL）
- 禁止硬编码 `http://localhost:...` 或 `http://127.0.0.1:...`

### 案例 2：大屏页面改造后测试断言未同步

### 场景
大屏页面加入图标和更新 label 后，E2E 测试断言失败：`expect(bodyText).toContain("订单量")` 找不到文本。

### 根因
测试断言硬编码了旧 label（"订单量"），但页面已改为"今日订单"。标签改动后测试未同步。

### 解决方案
1. 页面 UI 改造后**必须先跑一遍 E2E 测试**确认断言对齐
2. label 断言用 `toContain` 匹配子串，避免过精确匹配
3. 测试与模板标签定义共享常量，避免硬编码

### 案例 3：运营后台 401 时检查 sys_user+sys_permission 完整性

### 场景
后端重启后，Playwright auth.setup 登录失败 `OPS_AUTH_LOGIN_BAD_CREDENTIALS`。

### 根因
DB 重建后 E2E 测试用户（dev01）丢失。admin 用户存在但没有 `ops:stats:read` 等权限，因为 `sys_permission` 表缺少对应的种子数据。

### 解决方案
1. `isSuper=1` 的用户加载 `SELECT perm_key FROM sys_permission` 全量权限
2. 缺少 `ops:stats:read` 等权限 → 手动 INSERT 到 `sys_permission`
3. 长期方案：建 Flyway 迁移统一种子权限数据

---

## 经验：小程序 E2E 使用 H5 Playwright 替代 miniprogram-automator

### 场景
`miniprogram-automator` 通过 WebSocket 连接微信开发者工具，冷启动时 `automator.launch()` 经常超时、端口冲突、连接断裂。运营后台 Playwright E2E 也面临类似问题。

### 根因
- 微信开发者工具需要 GUI 交互（信任项目、登录、开启服务端口），无法完全自动化
- `miniprogram-automator` 管理 DevTools 生命周期时，已有实例导致端口冲突
- WebSocket 连接极易断裂，需要频繁重启

### 解决方案
用 H5 Playwright 替代：

```bash
# 替代 pnpm run e2e:mp-weixin
npx playwright test --config e2e/h5/playwright.config.ts
```

前提条件：
- 后端 `http://127.0.0.1:8080` 已运行
- H5 dev server `http://localhost:5173` 已运行（`pnpm run dev:h5`）
- Playwright 自动使用项目内置 Chromium，无需额外安装

H5 测试覆盖优势：
- 42 个 spec 文件，342+ 测试用例覆盖全部模块
- 运行稳定，无 WebSocket 断裂问题
- 可视化调试：`--headed` 模式可观察每一步
- CI/CD 兼容：Playwright 支持无头模式

---

## 经验：运营后台 Playwright E2E 数据从生产迁移

### 场景
运营后台 E2E 测试 auth.setup 通过后，312 个测试因数据库无业务数据而失败（圈子、考试、人才、套卡等模块数据为空）。

### 根因
dev 数据库只包含平台基础数据（租户、用户），缺少 E2E 测试依赖的业务数据（圈子、活动、商品、订单、考试、人才、套卡等）。

### 解决方案

**从生产 mysqldump 导入关键表：**

```bash
# 通过 SSH 从生产导出数据
sshpass -p '${PROD_SSH_PASSWORD}' ssh root@${PROD_SSH_HOST} \
  "mysqldump -u ${MYSQL_USERNAME} -p'${MYSQL_PASSWORD}' ${MYSQL_DATABASE} \
    --no-create-info --complete-insert --skip-add-locks \
    --where=\"tenant_id = 't_eb78751bae84'\" \
    tenant_circle exam_exam talent_info joint_card search_hot_word \
    merch_product_spu trade_order ..." | \
sed 's/^INSERT INTO /INSERT IGNORE INTO /' | \
mysql -u root -h ${DEV_MYSQL_HOST} kddev
```

**关键点：**
- 使用 `INSERT IGNORE` 跳过已存在的主键冲突
- 只在 `--where` 中筛选目标租户 `t_eb78751bae84`
- 系统配置表（`sys_menu`、`sys_permission` 等）不需要 tenant 过滤
- 店铺级数据（`merch_product_spu`）按 `shop_id IN (...)` 筛选

**迁移分 5 个阶段：**
1. 租户级业务表（圈子、考试、人才、套卡、搜索）
2. 系统配置表（菜单、权限、角色）
3. 店铺级数据（商品、订单）
4. 财务/资产数据
5. 客服/消息数据

### 预防
- 新增 E2E 测试涉及新模块时，同步确认 dev 数据库是否有对应测试数据
- 定期从生产同步基础业务数据到 dev（或建备份+恢复流程）
- 对于 exam 等生产和 dev 都无数据的模块，考虑在测试 setup 中创建测试数据
