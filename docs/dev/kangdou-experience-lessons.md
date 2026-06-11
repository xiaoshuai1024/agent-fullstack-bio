<!--
description: 仅保留领域特有经验（联合套卡字段、基础设施）。通用经验已迁移至对应分类文件（见下方索引）。
globs: **/*
alwaysApply: false
-->

# 领域特有经验

> 本文件仅保留无法归类到其他主题文档的经验。通用经验已迁移：
> - 前端 UX/组件 → `kangdou-frontend-ux-enum.md`
> - 运营后台 → `kangdou-ops-tenant-ui.md`
> - E2E 测试 → `kangdou-e2e-agent-guide.md` / `kangdou-e2e-execution-contract.md`
> - Git 合并 → `kangdou-git-merge-pull.md`
> - 通用流程 → `kangdou-cross-cutting-standards.md`
> - 方案/任务图 → `kangdou-superpowers-plan-contract.md` / `kangdou-superpowers-task-graph-ssot.md`
> - kd-review → `kd-review-five-rounds-gate.md`
> - 小程序质量 → `wechat-miniprogram-ship-quality.md`

---

## 经验：MyBatis-Plus 3.5.9 新增 batch 方法导致 `any()` 编译歧义

### 场景
`mvn -q verify` 报 COMPILATION ERROR：
```
reference to insert is ambiguous
  both method insert(T) in BaseMapper and method insert(Collection<T>) in BaseMapper match
```

同样问题也出现在 `updateById()` 和 JdbcTemplate 的 `query()` 方法。

### 根因
MyBatis-Plus 3.5.9 在 `BaseMapper` 中新增了批量方法 `insert(Collection<T>)` 和 `updateById(Collection<T>)`。Mockito 的 `any()` 无类型信息，编译器无法区分 `insert(T)` 和 `insert(Collection<T>)`。

### 解决方案
将模糊的 `any()` 替换为带类型的 `any(EntityClass.class)`：

```java
// 修复前
when(mapper.insert(any())).thenReturn(1);
verify(mapper).updateById(any());

// 修复后
when(mapper.insert(any(TaskEntity.class))).thenReturn(1);
verify(mapper).updateById(any(TaskEntity.class));
```

JdbcTemplate `query()` 歧义需指定 `any(RowMapper.class)`：

```java
// 修复前
when(jdbcTemplate.query(anyString(), any())).thenReturn(Collections.emptyList());

// 修复后
when(jdbcTemplate.query(anyString(), any(RowMapper.class))).thenReturn(Collections.emptyList());
```

Mockito strict stubbing 冲突时使用 `lenient()`：

```java
lenient().when(jdbcTemplate.query(anyString(), any(RowMapper.class)))
    .thenReturn(Collections.emptyList());
```

### 预防
- 所有 `any()` matcher 优先使用带类型的 `any(T.class)` 而非裸 `any()`
- JdbcTemplate stub 注意 `query()` 有 void 和 List 两种返回类型
- `doAnswer` 模拟 MyBatis-Plus 的 ID 回填行为：`invocation.getArgument(0).setId(x)`

---

## 经验：前端 Jest `import.meta` 与全局 `uni` mock

### 场景
Jest 运行报 `SyntaxError: Cannot use 'import.meta' outside a module`，或 `uni.switchTab is not a function` 等 uni API 缺失错误。

### 根因
- Jest 运行在 CommonJS 模式，`import.meta` 是 ESM 语法
- `tsconfig.jest.json` 设 `module: "commonjs"`，ts-jest 输出中保留 `import.meta` 导致无法解析
- 各个测试文件独立 mock `uni` 导致重复代码和遗漏（如 `switchTab` 没被 mock）

### 解决方案

**1. 全局 `uni` mock（推荐）：**
在 `test/jest-setup-after-env.cjs` 中添加：

```javascript
if (typeof globalThis.uni === "undefined") {
  const mockStorage = {};
  globalThis.uni = {
    navigateTo: jest.fn(),
    switchTab: jest.fn(),
    reLaunch: jest.fn(),
    redirectTo: jest.fn(),
    showToast: jest.fn(),
    showLoading: jest.fn(),
    hideLoading: jest.fn(),
    showModal: jest.fn(),
    setStorageSync: jest.fn((key, value) => { mockStorage[key] = value; }),
    getStorageSync: jest.fn((key) => mockStorage[key] ?? null),
    removeStorageSync: jest.fn((key) => { delete mockStorage[key]; }),
    getSystemInfoSync: jest.fn(() => ({})),
  };
}
```

**2. `import.meta` 处理：**
- 运行 `jest --no-coverage` 可以绕过 Istanbul 对 `import.meta` 的插桩问题
- 或创建 mock 文件并用 `moduleNameMapper` 替换 `useVersionAnnounce` 等含 `import.meta` 的模块
- 或直接在测试文件中用 `jest.mock("../src/composables/useVersionAnnounce", () => ({...}))`

**3. 测试文件写法：**
```typescript
beforeEach(() => {
  localStorage.clear(); // 清理 H5 localStorage fallback 污染
});
// 覆盖全局 uni mock 中特定的方法
(globalThis as any).uni.getStorageSync = jest.fn(() => mockValue);
```

### 预防
- 新增 composable 使用 `import.meta` 时添加对应的 `jest.mock` 或 `moduleNameMapper`
- 优先使用全局 `uni` mock，避免每个测试文件重复设置

### 场景
`pnpm run build` 报 chunk 超过 600 kB 警告：`element-plus`（780 kB）和 `echarts`（903 kB）。

### 根因
- `main.ts` 中 `import ElementPlus from "element-plus"`（全量导入）
- 各页面 `import * as echarts from "echarts"`（全量导入，13 个页面文件）
- chunkSizeWarningLimit 设 600 kB，两个库都超过

### 解决方案

**Element-Plus 按需加载：**
```ts
// vite.config.ts
import AutoImport from "unplugin-auto-import/vite";
import Components from "unplugin-vue-components/vite";
import { ElementPlusResolver } from "unplugin-vue-components/resolvers";
import ElementPlusPlugin from "unplugin-element-plus";

plugins: [
  AutoImport({ resolvers: [ElementPlusResolver()] }),
  Components({ resolvers: [ElementPlusResolver()] }),
  ElementPlusPlugin.vite({ useSource: false }),
]
```
- 删除 `main.ts` 中的 `import ElementPlus from "element-plus"` 和 `import "element-plus/dist/index.css"`
- 在 `App.vue` 中通过 `<el-config-provider :locale="zhCn">` 设置中文

**ECharts 按需加载：**
创建 `src/utils/echarts.ts`，仅注册实际用到的图表类型：
```ts
import { init, use, graphic, type ECharts } from "echarts/core";
import { BarChart, LineChart, PieChart } from "echarts/charts";
import { TitleComponent, TooltipComponent, GridComponent, LegendComponent } from "echarts/components";
import { CanvasRenderer } from "echarts/renderers";
use([BarChart, LineChart, PieChart, TitleComponent, TooltipComponent, GridComponent, LegendComponent, CanvasRenderer]);
export type { ECharts };
export { init, graphic };
```
- 13 个页面从 `import * as echarts` 改为 `import { init, type ECharts } from "../utils/echarts"`
- 构建结果：echarts **903 kB → 374 kB**（-59%）

### 预防
- 新增页面需用 ECharts 时，从 `utils/echarts` 导入而非 `echarts`
- 如需新增图表类型，在 `utils/echarts.ts` 的 `use()` 数组中追加注册
- `unplugin-element-plus` 的 ElementPlusResolver 会自动处理组件按需导入，无需手动 import

---

## 经验：joint_card_line.display_title 存角色描述而非商品名

### 场景
联合套卡会场和首页展示子SKU时，SKU名称显示为"发起方"、"参与方"等店铺角色描述，而非商品名称（如"双人火锅套餐"）。

### 根因
`joint_card_line.display_title` 字段存储的是店铺角色标签，不是商品名称。`merch_product_sku` 表无 `title` 字段（只有 `spec_label` 规格标签），商品名称唯一来源是 `merch_product_spu.title`。

### 解决方案
```sql
-- 后端 SQL 优先用 SPU 商品名
COALESCE(spu.title, l.display_title) AS title

-- 关联 SPU 表
LEFT JOIN merch_product_spu spu ON sku.spu_id = spu.id AND spu.delete_time = 0
```

涉及文件：
- `JointCardTenantService.listOnShelfSaleCards()` — 会场列表
- `HomeFeedExtendService.loadJointCardSkus()` — 首页瀑布流

### 预防
1. 多表关联查询展示数据时，确认关联表中有哪些字段可用（商品名在 SPU 不在 SKU）
2. `display_title` 等"人读"字段可能被设置为非预期值，需要验证实际库中数据
3. 方案阶段列清 `merch_product_sku` 与 `merch_product_spu` 的字段差异

---

## 经验：MySQL Docker 容器时区设置

Docker MySQL 容器的 `system_time_zone` 默认 UTC，不随宿主机 timedatectl 变更。修改方式：

```bash
docker exec mysql bash -c "ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo Asia/Shanghai > /etc/timezone"
docker restart mysql
```

或者在启动容器时加 `-e TZ=Asia/Shanghai`。

---

## 经验：商家后台小程序页修复（2026-04-30）

### 已验证问题
1. **多文档拼接** — 单个 HTML 出现多个 `<!doctype html>`、`<html>`、`</html>`，导致样式错乱、变量重复声明。
2. **同目录页面形态不一致** — 部分页面是小程序壳（手机视图），部分是桌面运营台（三栏/侧栏）。
3. **跨平台跳转** — 商家页内仍跳转到运营后台、客户端等。
4. **并发写回覆盖** — 修复后的文件被再次追加旧版本。

### 修复策略
1. **止血** — 关闭并发写回，锁定文件为单一文档（`<!doctype html>` 仅 1 次）。
2. **统一壳规范** — 顶部状态栏 + 44px 导航栏 + 单栏卡片流 + 本页内切换。
3. **收口** — 入口文案与页面形态一致化。

### 必做校验
- `<!doctype html>` / `<html>` / `</html>` 各出现 1 次
- 无跨平台跳转（`../运营后台/`、`../司机端/`、`../客户端/`）
- 无桌面中台结构（`opsSidebar`、三栏 grid）
- 关键按钮本页内完成

### 预防
修复前先做结构去重检查（doctype/html 计数），修复后停止并发写回。

---

## 经验：HTTP 鉴权 Filter 顺序与 RBAC 执行链

### Servlet Filter 顺序（数字越小越早）
| Order | 组件 | 作用域 |
|------:|------|--------|
| 1 | `RequestTraceFilter` | `/*`：生成/透传 `X-Request-Id` |
| 2 | `TenantFilter` | 校验 `X-Tenant-Id`，写入 `TenantContext` |
| 3 | `OpsAuthFilter` | `/api/platform/**`：解析 Bearer，建立 `OpsSecurityContext` |
| 4 | `TenantShopAuthFilter` | `/api/tenant-core/shop/**`：加载 SHOP realm |

### 需要 `X-Tenant-Id` 的路径
- `/api/tenant-core/**`
- `/api/platform/tenant-admin/tenants/{id}/policies/`、`/quotas`、`/industries`、`/storage/qiniu`

### Controller 层 RBAC
注解 `@RequirePerm("perm:key")` → `RequirePermAspect` 切面：
1. 有 `ShopSecurityContext` → 校验 SHOP realm
2. 有 `OpsSecurityContext` → 校验平台权限
3. 否则 → `OPS_SECURITY_UNAUTHENTICATED`

### 原则
平台与店铺 realm 不得复制第二套 `@Aspect`；新增受保护 API 应通过 `@RequirePerm`。

---

## 经验：图片获取与生成实践

### 推荐方案
真实图下载（loremflickr）→ 本地落盘 → JSON 配置接入。

```bash
bash scripts/images/download-real-images.sh
```

### 标准目录
`docs/products/v1/mock/assets/images/real/`

### 校验
```bash
file docs/products/v1/mock/assets/images/real/*.jpg
# 期望输出包含：JPEG image data
```

### 缓存
`scripts/data-source.js` 写入 localStorage。更新 JSON 后页面未变化需 `window.DataSource.clear("miniapp-home")` 再 `load()`。

### 合规
原型阶段可用公开图源演示；对外发布/商用前必须替换为可商用授权素材。

---

## 经验：飞书 Docx 表格拆行与批量编辑

### 要点
1. **`document_id` ≠ Wiki 节点 token** — 正文读写必须以 `/open-apis/docx/v1/documents/{document_id}/...` 为准。
2. **表格单元格多段** — 同一单元格可能有多个段落块，不能只读 `children[0]`。
3. **表格写入用 `user_access_token`** — `PATCH .../blocks/batch_update`（`insert_table_row` 等）若 403 可切换为用户授权令牌。
4. **推荐操作顺序**：`insert_table_row` → 删除冗余子块 → `batch_update_feishu_block_text`。
5. **验收**：调用 `get_feishu_document_blocks` 拉全量块，逐行列核对。

### 相关文档
- `docs/dev/飞书文档上传MUST规范.md`
- `scripts/feishu/` 下脚本

---

## 经验：Mockito TransactionTemplate.execute() 在单元测试中的 NPE（2026-06-04）

### 场景
`SettlementPayoutServiceTest` 和 `ReconciliationEngineTest` 在构造器增加 `TransactionTemplate` 参数后报 NPE。

### 根因
`@Mock TransactionTemplate.execute()` 默认返回 `null`，而服务代码将其返回值解引用（如 `Object[] txResult = transactionTemplate.execute(...); txResult[0]`）。

### 解决方案
```java
when(transactionTemplate.execute(any())).thenAnswer(invocation -> {
    TransactionCallback<?> callback = invocation.getArgument(0);
    return callback.doInTransaction(null);
});
```

### 预防
- `TransactionTemplate.execute()` 的测试必须 stub 回调执行，不能依赖默认 null 返回值
- `ReconciliationEngine`、`SettlementPayoutService`、`CommissionReversalService` 均使用此模式

---

## 经验：RequestConfig 类型改版—旧格式兼容层

### 场景
运营后台将 `RequestConfig` 类型从 `{url, method?, params?, data?}` 改为 `{url, init: RequestInit}`。修改后旧代码中使用 `runRequest({url, method: "GET"})` 的 13+ 个视图全部编译失败。

### 根因
新 `RequestConfig` 要求 `init` 为必填字段，所有旧格式的调用方必须改为 `runRequest({url, init: {method: "GET"}})`。但旧代码分布在 13+ 个文件中，逐个修改代价高。

### 解决方案
**方案 A（不推荐——逐个修改旧文件）：** 成本高、影响范围大、导致冗余 diff。

**方案 B（推荐——类型定义加兼容层）：** 修改 `RequestConfig` 类型和 `runRequest` 函数：

```typescript
// tenant.ts — 旧格式字段保留为 optional
export type RequestConfig = {
  url: string;
  init?: RequestInit;          // 新格式（optional）
  method?: string;             // 旧格式（optional）
  params?: Record<string, unknown>;
  data?: unknown;
  responseType?: string;
};

// jsonClient.ts — 运行时转换
function resolveLegacyConfig(config: RequestConfig): Required<Pick<RequestConfig, 'url' | 'init'>> {
  if (config.init) {
    return { url: config.url, init: config.init };
  }
  const init: RequestInit = {};
  if (config.method) init.method = config.method;
  if (config.data) {
    init.headers = { ...init.headers as HeadersInit, 'Content-Type': 'application/json' };
    init.body = JSON.stringify(config.data);
  }
  return { url: config.url, init };
}
```

### 预防
1. 破坏性类型变更前先 `grep -rn "runRequest\|RequestConfig" src/ --include="*.ts" --include="*.vue"` 评估影响面
2. 如果影响面 > 5 个文件，优先在类型加兼容层而非逐个修改调用方
3. 兼容层在运行时处理旧格式，避免编译错误 + 执行正确双重保障

---

## 经验：并行 V2 全量推进 — 5 个 agent × worktree 隔离

### 场景
`feature/platform-gap-fill` 分支有 47 个任务需要完成。使用 5 个并行 agent + worktree 隔离，覆盖后端/运营/前端/数据库。

### 根因
传统串行执行需要大量时间，且不同任务修改同一项目的不同文件，无法串行并发。

### 方案
```
主会话（协调+验证）
  ├── fix-op-build     → 运营后台 RequestConfig 类型兼容
  ├── fix-backend-files → 5 个缺失后端 Java 文件  
  ├── fix-op-views      → 2 个缺失运营视图 + 路由注册
  ├── fix-frontend      → 3 个前端组件/composables
  └── fix-flyway        → 1 个缺失 Flyway DDL + 验证
```

### worktree isolation 须知
- 每个 agent 用 `isolation: "worktree"` 自动创建独立 git worktree
- 修改完成后需手动合并回主仓（agent 在 worktree 中修改的文件不自动同步）
- 合并方式：`cp` 或 `ExitWorktree(action: "keep")` 后手动 merge
- worktree 自动清理未提交文件——有变更退出前需要确认

### 验证门禁链
```bash
mvn -q compile                    # backend
pnpm run build                    # operation-backend
pnpm run build:mp-weixin          # frontend
mvn test -Dexec.skip=true         # backend unit tests
pnpm test                         # operation tests
pnpm run test:unit                # frontend tests
```

### 预防
1. 每个 agent 明确指定修改范围（文件列表），避免重复修改同一文件
2. 不同子仓（backend/operation-backend/frontend）的 agent 可无隔离运行
3. 同一子仓内的并行 agent 必须用 worktree isolation
4. agent 完成后在主仓执行 `git diff --stat` 确认变更已合并

---

## 经验：v2-round2-full-fix 安全修复—探索先行 + 并行派发模式（2026-06-05）

### 场景
`v2-round2-full-fix.json` 有 38 项安全/功能修复任务，涉及 backend + operation-backend 两个仓库。初始状态 0/38 completed，需全部解决。

### 方法论

**Step 1: 探索先行** — 不等用户给更多信息，先用 3 个并行 Explore agent 扫完整个代码库：
- Agent 1: 审计日志/AppSecret/登录限流/Token刷新/错误处理/圈子内容
- Agent 2: 退款冲正/库存恢复/银行代付/DB迁移/认证渠道/结算调度
- Agent 3: 敏感词模块/FeatureGate/缓存/feature_switch/错误码/HikariCP

**Step 2: 标记已完成** — 探索发现 8 项已实现（AppSecret 加密、Token 刷新、@RequirePerm、库存恢复、阿里云 OCR、FeatureGate 等），直接跳过，节省改动量。

**Step 3: 并行派发** — 按 Phase 分三路并行执行：主线程 Phase1（安全加固），backend agent Phase2（功能补全），ops agent Phase3+4（运营后台页面）。

**Step 4: 收口验证** — 两个 agent 完成后，进一步发现 P3-05/06 和 P4-03 的页面已经存在。最终 38 项：36 完成 + 2 跳过。

### 关键教训

1. **基础设施存在但未接入** — `CommissionReversalService.reverseOnRefund()` 方法完整存在，但 `RefundLifecycleService.approveRefund()` 从未调用它。`EsSyncConsumer` 删除分支只打日志不调 `handleDelete()`。这类 bug 的特点是"单个文件看起来都对，多个文件交互才漏"——**跨文件功能链路必须逐级 grep 验证调用链**。

2. **重复错误码跨模块蔓延** — `CIRCLE_ACTIVITY_FULL` 和 `ACTIVITY_FULL` 语义完全相同，分布在 6+ 个调用方中。清理时需 `grep` 全量搜索 + 逐个替换 + 编译验证。**新增错误码前先搜索是否有语义相同的已有值**。

3. **双缓存写入不一致** — `HomeFeedExtendService` 手动写 Redis Key 格式为 `homeJointCards::<tenantId>`，但 `KangdouCacheInvalidator` 通过 Spring `CacheManager` 失效另一个 key 格式。**同一缓存的所有读写必须使用统一抽象层**。

4. **任务图不等于真实状态** — 38 项中有 13 项实际已实现但任务图显示 `pending`。实现前先探索验证，不盲信任务图的 status 字段。

5. **运营后台构建阻塞** — `TenantSplitConfigView.vue` 的 import 路径少了一级 `../`，导致 `pnpm run build` 失败。修复只需改 2 处 import 路径。**构建门禁应作为 CI 常驻检查**。

### 文件变更
- backend: ~17 文件（新增 2 + 修改 ~15）
- operation-backend: 2 文件（ShopDetailView 死代码 + TenantSplitConfigView import）
- 编译验证: `mvn -q compile` ✅ · `pnpm run build` ✅

### 预防
1. 安全修复轮次前必须先跑 3 个 Explore agent 并行扫全库，标记已实现项
2. 跨模块功能链路必须 grep 验证调用链是否完整接入
3. 新增错误码/枚举前先 `grep` 已有值，确认无语义重复
4. 缓存读写统一用 Spring `@Cacheable` 或统一用手动 RedisTemplate，不混用两套

---

## 经验：Java Text Block SQL 拼接缺空格

### 场景
`SlowQueryController.java` 中 `""" + where + """\nORDER BY` 拼接后 WHERE 条件的参数 `?` 与 `ORDER BY` 之间无空格，生成 `WHERE avg_timer_wait_ns >= ?ORDER BY`，MySQL 报语法错误。

### 根因
Java text block `"""` 精确保留内容，不自动补空格。`where` 变量结尾的 `?` 与下一行 `ORDER BY` 直接粘连。

### 解决方案
```java
// ❌ 错误
""" + where + """
ORDER BY last_seen DESC

// ✅ 正确
""" + where + " "
+ """
ORDER BY last_seen DESC
```

### 预防
text block 拼接 SQL 时，在拼接点两侧显式加空格 `" "` 或 `" WHERE "`。

---

## 经验：audit_event.risk_tier 列长度限制

### 场景
`OpsProxyOrderService` 调用 `opsAuditService.recordSuccess()` 时传入 `"MANUAL_REVIEW"`（13 字符）作为 `riskTier`，但 `audit_event.risk_tier` 列定义为 `varchar(8)`，INSERT 时 `Data truncation: Data too long for column 'risk_tier'`。

### 根因
`risk_tier` 列的 `varchar(8)` 只允许 `"LOW"`（3）、`"MED"`（3）/ `"MEDIUM"`（6）、`"HIGH"`（4）等标准级别。`"MANUAL_REVIEW"`（13）超出长度。

### 解决方案
```java
// 传入标准 risk_tier 值，不用业务状态代替
opsAuditService.recordSuccess(..., needsApproval ? "HIGH" : "LOW");
```

### 预防
1. `opsAuditService.recordSuccess()` 的 `riskTier` 参数只允许 `LOW`/`MED`/`MEDIUM`/`HIGH`，禁止传入业务状态枚举
2. 传入前确认该列长度约束

---

## 经验：FeatureGate 权限种子须跟随功能一起发布

### 场景
运营代下单 API（`ops:trade:proxy-order:create`）、实体共享开关（`ops:sharing:entity-config:view`）、慢 SQL 查看（`ops:stats:slow-query:list`）三个功能的 `@RequirePerm` 注解在代码中存在，但权限未通过 Flyway 种子到 `sys_permission` 表，导致 `dev01` 超级管理员也被 403 拒绝。

版本公告（`ops:feature:announcement:version:manage`）正确运行因为 V3884 已种子。

### 根因
新增 `@RequirePerm` 时只写了注解，没写种子迁移。权限系统不自动注册——每个权限 key 必须在 `sys_permission` 表中有对应记录。

### 解决方案
```sql
INSERT IGNORE INTO `sys_permission` (`perm_key`, `name`, `group_key`, `description`, `builtin`) VALUES
('ops:trade:proxy-order:create', '代下单创建', 'ops', '运营创建代下单订单', 0);
```

建议统一用一个迁移文件集中种子，避免碎片化。参考 V3885。

### 预防
新增 `@RequirePerm("ops:xxx:yyy")` 时，必须同时：
1. 检查 `sys_permission` 表是否有该 key 的种子迁移
2. 没有则在本批次建一个 V 迁移集中种子
3. 重启后端让 Flyway 执行后验证

---

## 经验：大屏 Three.js + D3 + TweenJS 集成

### 场景
运营后台数据大屏（ScreenView.vue）从纯 ECharts 升级为 Three.js 粒子背景 + D3 图表 + TweenJS 数字动画。

### 关键集成点

| 技术 | 用途 | 文件 |
|------|------|------|
| Three.js | 粒子星空背景（1200 粒子，鼠标视差，呼吸闪烁） | `useScreenParticles.ts` |
| D3.js | 24h 柱状图、租户排行条形图（渐变填充、动态入场） | `useScreenD3Charts.ts` |
| TweenJS | KPI 数字从 0 动画到目标值（Cubic.Out 缓动） | `useScreenNumberTween.ts` |

### CSS 大屏特效（无额外依赖）

| 特效 | 实现方式 | 说明 |
|------|---------|------|
| 网格背景 | `background-image: linear-gradient` 叠加 | 60px 间距，3% 透明度 |
| 扫描线 | `@keyframes scanDown` 动画 | 2px 渐变线 8s 从上到下扫描 |
| 四角装饰 | `.corner-tl/tr/bl/br` 伪绝对定位 | 2px 边框，14x14px，蓝青色 |
| 卡片光晕 | `radial-gradient` + `glowRotate` 动画 | 8s 慢速旋转 |
| 入场动画 | `fadeInUp` / `fadeInDown` | 0.6s ease-out，stagger 间隔 |

### 依赖安装

```bash
pnpm add three @tweenjs/tween.js d3
pnpm add -D @types/three @types/d3
```

### D3 TypeScript 常见陷阱
- D3 回调参数必须显式标注类型（`(d: H) => ...`），否则 ts 隐式 any 报错
- `d3.NumberValue` 是联合类型，`>=` 操作符需要先 `const v = +d` 转为 number
- 渐变定义用两个 `stop` 分别定义 0% 和 100% 的 opacity

---

## 经验：Redis 大屏计数器在重启后丢失

### 场景
后端重启后，大屏所有 KPI 显示 ¥0。Redis 中 `screen:daily:*` 计数器数据丢失。

### 根因
大屏计数器存储在 Redis 内存中（`INCR`/`SADD`），TTL 24 小时。Redis 服务重启或 key 过期后数据丢失。

### 解决方案
```python
r = redis.Redis(host='192.168.100.67', port=3379, db=0)
today = datetime.date.today().isoformat()
r.set(f'screen:daily:gmv_fen:{today}', 2865000, ex=86400)
r.set(f'screen:daily:order_count:{today}', 85, ex=86400)
r.sadd(f'screen:daily:active_users:{today}', 'user_001', 'user_002')
r.set(f'screen:daily:new_user_count:{today}', 12, ex=86400)
r.set('screen:daily:mau', 18560, ex=1200)
```

### 预防
- 大屏数据应有汇总表回退：Redis miss 时从 `stat_daily_summary` 读取
- 关键时刻（演示/验收）前检查 Redis 计数器是否存活

---

## 经验：MySQL 5.7 子查询 JOIN ON 不能引用外层列

### 场景
生产环境 MySQL 5.7，联合套卡订单详情页（`/api/tenant/joint-card-orders/{no}/tree`）报错：`Unknown column 'l.tenant_id' in 'on clause'`

```sql
-- 子查询中 JOIN ON 引用外层别名 l，MySQL 5.7 不允许
SELECT i.id,
  (SELECT spu2.main_image_url FROM trade_order_item oi
   JOIN shop_sku ss2 ON ss2.sku_code = oi.sku_code AND BINARY ss2.tenant_id = BINARY l.tenant_id
   WHERE oi.order_no = i.child_order_no LIMIT 1) AS image_url
FROM joint_card_line_instance i
LEFT JOIN joint_card_line l ON ...
```

### 根因
MySQL 5.7 限制：**子查询（subquery）的 `JOIN ON` 子句中不能引用外层查询的表别名**。外层列只能在子查询的 `WHERE` 子句中引用。

### 解决方案
将条件从 `JOIN ON` 移到子查询的 `WHERE` 子句中：

```sql
JOIN shop_sku ss2 ON ss2.sku_code = oi.sku_code
WHERE oi.order_no = i.child_order_no AND oi.sku_code = l.sku_code
  AND BINARY ss2.tenant_id = BINARY l.tenant_id
```

### 预防
- 写子查询时，所有引用外层表的条件统一放 `WHERE` 子句
- 本地开发可能用 MySQL 8+ 测不出，部署到 MySQL 5.7 生产才暴露

---

## 经验：MySQL 5.7 不支持 `ADD COLUMN IF NOT EXISTS`

### 场景
Flyway 迁移 `V3887__add_staff_review_dimensions.sql` 在生产 MySQL 5.7 上执行失败：
```
You have an error in your SQL syntax; check the manual ... near 'IF NOT EXISTS staff_attitude_rating TINYINT NULL'
```

### 根因
`ADD COLUMN IF NOT EXISTS` 是 MySQL 8.0.16+ 的语法。生产 MySQL 5.7 不认识 `IF NOT EXISTS`。

### 解决方案
改用 `information_schema.COLUMNS` 条件判断：
```sql
SET @db = (SELECT DATABASE());
SET @c1 = (SELECT COUNT(*) FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = @db AND TABLE_NAME = 'trade_spu_review' AND COLUMN_NAME = 'staff_attitude_rating');
SET @s1 = IF(@c1 = 0, 'ALTER TABLE trade_spu_review ADD COLUMN staff_attitude_rating TINYINT NULL', 'SELECT 1');
PREPARE stmt1 FROM @s1; EXECUTE stmt1; DEALLOCATE PREPARE stmt1;
```

### 预防
- 项目已使用 MySQL 5.7，新 Flyway 迁移避免使用 MySQL 8+ 独有语法
- 迁移脚本用 `information_schema` 做幂等判断

---

## 经验：生产数据库列名与代码不一致的排查思路

### 场景
部署新版 JAR 后多个页面报 `Unknown column 'xxx' in 'field list'`：
- `sp.wholesale_price` → 实际列名 `wholesale_price_cent`
- `pay_status` → 实际列名 `payment_status`
- `shop_id` 在 `tenant_demand` 不存在
- `stock` 在 `merch_product_spu` 不存在
- `price_fen` 在 `joint_card_line` 不存在
- `paid_at` 在 `trade_order` 不存在

### 根因
- **列名重命名/改造**：开发库和生产库的列名不同（`wholesale_price` vs `wholesale_price_cent`）
- **Flyway 迁移未覆盖**：有些列是代码直接引用的，但从未在生产库建过
- **代码先于迁移**：新代码引用新列，但对应迁移未在生产运行

### 排查命令
```sql
-- 查看表结构对比代码引用
DESC trade_order;
SHOW COLUMNS FROM trade_order LIKE '%pay%';

-- 查看生产迁移历史
SELECT version, description, installed_on, success FROM flyway_schema_history ORDER BY installed_on DESC;
```

### 预防
- 新字段必须通过 Flyway 迁移添加，禁止手改生产库结构
- 部署前对比 `flyway_schema_history` 确认所有迁移已执行
- 代码中的列名先查生产 `DESC table` 确认

---

## 经验：Stale fat JAR 导致运行时 NoClassDefFoundError

### 场景
生产环境后端 Java 进程启动方式 `java -jar target/backend-0.0.1-SNAPSHOT.jar`，本地 `mvn compile` 后类文件更新到 `target/classes/` 但 JAR 没重建。运行时报：
```
NoClassDefFoundError: com/kangdou/tenant/WechatFieldMasker
NoClassDefFoundError: org/springframework/web/ErrorResponse$Builder
NoClassDefFoundError: com/mysql/cj/result/AbstractDateTimeValueFactory$1
```

### 根因
- 后端以 fat JAR（`java -jar`）运行，不是 `mvn spring-boot:run`
- `mvn compile` 只更新 `target/classes/`，fat JAR 不会被重新打包
- `spring-boot-devtools` 重启对 fat JAR 无效

### 解决方案
```bash
# 完整重打包并重启
mvn clean package -DskipTests -Dmaven.test.skip=true
java -jar target/backend-0.0.1-SNAPSHOT.jar --spring.profiles.active=prod
```

### 预防
- 确认启动方式：`ps aux | grep java` 看是 `java -jar` 还是 `mvn spring-boot:run`
- 如果启动方式为 fat JAR，修改代码后必须 `mvn package` 再部署
- `mvn compile` 仅对 `mvn spring-boot:run` 有效

---

## 经验：新增 MyBatis-Plus Mapper 须注册到 @MapperScan

### 场景
新增 `FeatureRegistryMapper` 后后端启动失败：
```
Parameter 0 of constructor in FeatureRegistryController required a bean of type 
'FeatureRegistryMapper' that could not be found.
```

### 根因
Spring Boot 的 `@MapperScan` 配置了显式包列表（在白名单内的包才扫描 Mapper），新 Mapper 所在包不在列表中。

### 解决方案
在 `BackendApplication.java` 的 `@MapperScan` 中添加包名：
```java
@MapperScan(basePackages = {
    // ... 已有包 ...
    "com.kangdou.ops.feature",  // 新增
    "com.kangdou.supplydemand.repository",  // 预存缺漏
})
```

### 预防
- 新增 Mapper 接口时确认其包名已包含在 `@MapperScan` 中
- 新增功能模块的 repository/mapper 包记得注册扫描路径

---

## 经验：MySQL Docker 容器崩溃后从生产恢复数据

### 场景
Docker MySQL 容器 `Exited (255)`，重启后无响应。重新创建容器后数据卷为空，所有表丢失。

### 恢复步骤
```bash
# 1. 在远程服务器上获取生产数据源信息
ssh root@prod-server
docker exec mysql mysql -uroot -p'password' -e "SHOW DATABASES;"

# 2. 从生产库 mysqldump → pipe → 导入开发库
sshpass -p 'pwd' ssh root@prod-server \
  "mysqldump -u user -p'pass' --single-transaction \
    --ignore-table=db.flyway_schema_history db" | \
  mysql -h dev-host -u root -proot123456 dev_db

# 3. 恢复 Flyway 版本记录
sshpass -p 'pwd' ssh root@prod-server \
  "mysqldump -u user -p'pass' db flyway_schema_history" | \
  mysql -h dev-host -u root -proot123456 dev_db

# 4. 补跑 V2024+ 迁移
cd backend && mvn flyway:migrate -Dflyway.url='...' -Dflyway.user=root -Dflyway.password=root123456
```

### 预防
- Docker MySQL 容器应挂载持久化数据卷（`-v mysql-data:/var/lib/mysql`）
- 定期备份 `flyway_schema_history` 表（版本记录丢失比数据丢失更麻烦）
- 开发环境本地 Docker Compose 配置添加 `volumes:` 声明

---

## 经验：生产启动脚本进程冲突 — 旧进程未停就启动新进程

### 场景
`/deploy-prod-be-ops` 重启后端后，出现两个 Java 进程同时运行：旧进程占用 8081 端口，新进程因端口冲突启动失败（`Port 8081 was already in use`）。

### 根因
`start-backend.sh` 用 `pkill -f` + `sleep 2` 停旧进程，但：
1. Spring Boot 优雅关闭可能需要 > 2 秒
2. 不验证旧进程是否真正退出
3. 不检查端口是否释放
4. 启动失败时无感知（nohup 后台运行，无 health check）

### 解决方案
重写 `start-backend.sh`，分为 5 步：SIGTERM 等待 → SIGKILL 兜底 → 端口释放校验 → 启动新进程 → health check 轮询：

```bash
#!/bin/bash
set -e
APP_NAME="backend-0.0.1-SNAPSHOT.jar"
PORT=8081
LOG_DIR="/www/wwwroot/kangdouv1/logs"
JAVA_OPTS="-Xmx1024M -Xms256M -Dmanagement.health.elasticsearch.enabled=false"

# 1. SIGTERM 优雅停止（最多等 15 秒）
OLD_PIDS=$(pgrep -f "$APP_NAME" 2>/dev/null || true)
if [ -n "$OLD_PIDS" ]; then
  kill $OLD_PIDS 2>/dev/null || true
  WAIT=0
  while [ $WAIT -lt 15 ] && pgrep -f "$APP_NAME" > /dev/null 2>&1; do
    sleep 1; WAIT=$((WAIT + 1))
  done
  # 超时 SIGKILL
  pgrep -f "$APP_NAME" > /dev/null 2>&1 && kill -9 $(pgrep -f "$APP_NAME") 2>/dev/null || true
fi

# 2. 确保端口释放（最多等 10 秒，端口被占则强杀占用者）
WAIT=0
while ss -tlnp | grep -q ":${PORT} " && [ $WAIT -lt 10 ]; do
  HOLD_PID=$(ss -tlnp | grep ":${PORT} " | grep -oP 'pid=\K[0-9]+' | head -1)
  [ -n "$HOLD_PID" ] && kill -9 "$HOLD_PID" 2>/dev/null || true
  sleep 1; WAIT=$((WAIT + 1))
done
ss -tlnp | grep -q ":${PORT} " && { echo "ERROR: Port ${PORT} still in use, aborting!"; exit 1; }

# 3. 启动 + 4. health check 轮询（最多 60 秒）
nohup $JAVA $JAVA_OPTS -jar "$APP_NAME" --server.port=${PORT} --spring.profiles.active=prod >> "$LOG_DIR/startup.log" 2>&1 &
NEW_PID=$!
WAIT=0
while [ $WAIT -lt 60 ]; do
  ! kill -0 "$NEW_PID" 2>/dev/null && { echo "ERROR: Process died during startup!"; tail -20 "$LOG_DIR/startup.log"; exit 1; }
  curl -sf "http://127.0.0.1:${PORT}/actuator/health" > /dev/null 2>&1 && { echo "Started OK (PID=$NEW_PID)"; exit 0; }
  sleep 2; WAIT=$((WAIT + 2))
done
```

### 预防
- 启动脚本必须包含：进程停止确认 → 端口释放确认 → 启动后 health check
- `pkill` + 固定 `sleep` 不可靠，必须轮询确认进程退出
- 生产部署流程自动化后，禁止手动 `nohup java -jar`

---

## 经验：微信 SDK 选型 — 支付已用官方 SDK，开放平台代注册用 WxJava

### 场景
项目中微信集成涉及两大领域：微信支付（JSAPI/退款/子商户入驻/打款）和开放平台（代注册/代授权/代码模板管理）。需要确认 SDK 选型是否合理。

### 现状分析

| 领域 | 当前方案 | 覆盖情况 |
|------|----------|----------|
| 微信支付（直连） | `wechatpay-java` 官方 SDK | ✅ 已覆盖（6 个文件） |
| 微信支付（服务商） | `wechatpay-java` partnerpayments 模块 | ✅ 已覆盖 |
| 开放平台代注册/代授权 | curl + ProcessBuilder | ❌ 手写，6 个文件 |
| 代码模板管理 | curl + ProcessBuilder | ❌ 手写 |

### 结论

**`wechatpay-java` 不需要动**。它已在 pom.xml 中，覆盖了 `payments.jsapi`、`partnerpayments.jsapi`、`service.refund`、`apply4sub`（子商户入驻）、打款、账单下载、通知验签。

**开放平台部分用 `weixin-java-open`（WxJava 的 open 模块）是正确选择**：
- Java 生态中微信开放平台唯一成熟方案（GitHub 28k+ stars）
- 微信官方没有出开放平台 Java SDK
- 覆盖 component_access_token 管理、预授权码、代小程序代码管理、代注册等

```xml
<!-- 已有：微信支付 -->
<dependency>
    <groupId>com.github.wechatpay-apiv3</groupId>
    <artifactId>wechatpay-java</artifactId>
</dependency>

<!-- 需新增：开放平台代注册/代授权 -->
<dependency>
    <groupId>com.github.binarywang</groupId>
    <artifactId>weixin-java-open</artifactId>
</dependency>
```

### 注意事项
1. **curl 问题根源**：当年用 curl 是因为 Java HTTP 客户端与微信 CDN 有 412 兼容性问题。`weixin-java-open` 底层用 OkHttp，需验证在服务器环境下是否复现——建议逐接口替换而非一次性大改
2. **token 管理**：WxJava 内置 `WxOpenInMemoryConfigStorage` 自动处理 component_verify_ticket 刷新，但需配置成从数据库/Redis 读写
3. **渐进迁移**：先换 token + 预授权码 → 再换代小程序代码管理 → 最后换代注册

### 预防
- 不需要为微信支付引入额外 SDK，`wechatpay-java` 已完整
- 开放平台迁移时保留 curl 作为 fallback，逐接口验证后再移除

---

## 经验：Controller JdbcTemplate → Service/Repository 重构模式

### 场景
kd-review 审查发现 Controller 层直接使用 `JdbcTemplate` 操作数据库，违反分层架构（Controller → Service → Repository）。

### 根因
早期快速开发时为便利直接在 Controller 中注入 JdbcTemplate，后续未重构。典型模式：
- `TradeController`：`confirmReceipt` 使用 `FOR UPDATE` + UPDATE
- `WechatOpenPlatformNotifyController`：多处 `queryForList` / `queryForMap` / `update`

### 解决方案

**重构三步法**：

1. **识别 DB 操作归属的 Service**：
   - 订单状态变更 → `TenantCoreService`（已有 JdbcTemplate）
   - 履约任务查询 → `NextDayHandoverTaskService`（已有 JdbcTemplate）
   - 批发层级逻辑 → `WholesalePriceService`（需新增 JdbcTemplate）
   - 微信平台 DB 操作 → 新建 `WechatOpenPlatformNotifyService` + Repository

2. **Service 方法签名返回业务语义**（而非 `List<Map>`）：
   ```java
   // TenantCoreService: 返回更新前状态
   @Transactional(rollbackFor = Exception.class)
   public String confirmReceipt(String tenantId, String orderNo) { ... }

   // NextDayHandoverTaskService: 返回 Map（空 Map 表示无记录）
   public Map<String, Object> getTrackingByOrderNo(String tenantId, String orderNo) { ... }
   ```

3. **同步修复测试构造函数**：
   Controller 构造函数参数变更后，所有 `@Mock` 测试的 `new Controller(...)` 调用必须同步更新。

### 预防
- 新功能开发时 Controller 禁止注入 JdbcTemplate，只用 Service
- `mvn -q compile` 可捕获代码编译错误，但测试文件需要单独跑 `mvn test` 才能发现构造函数签名不匹配
- 重构后先跑 `mvn -q compile`，再跑受影响的单测确认

---

## 经验：凭据外化到 .env.dev + 测试同步

### 场景
`application-local.yml` 中硬编码了 Qiniu AK/SK、AMAP key、tenant-secrets master key 等敏感凭据作为 `${ENV_VAR:默认值}` 的默认值。

### 根因
本地开发便利性导致 yml 文件中嵌入了真实密钥，被 git 跟踪。

### 解决方案

1. **移除 yml 中的硬编码默认值**（保留 env var 引用）：
   ```yaml
   # Before
   access-key: ${QINIU_ACCESS_KEY:N2ubisgZnef0YEsLtBeYjibZBBTVxuIS7J1YDCP_}
   # After
   access-key: ${QINIU_ACCESS_KEY:}
   ```

2. **在 `.env.dev`（gitignored）中配置真实值**，在 `.env.dev.example` 中补充条目模板。

3. **非敏感默认值可保留**：如 `QINIU_BUCKET:zhaokang666`、`QINIU_PUBLIC_BASE_URL:https://...` 不含密钥。

### 预防
- `application-local.yml` 中只保留非敏感默认值（bucket 名、URL）
- AK/SK/token/key 类字段默认值设为空，开发者首次启动需配置 `.env.dev`
- Code review 时检查 yml 文件是否引入新的硬编码凭据
