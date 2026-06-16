---
description: 运营后台租户 UI — 列表页不展示租户、未选工作租户时顶栏引导
globs: operation-backend/src/**/*
alwaysApply: false
---

# 运营后台 · 工作租户 UI 约定

## 原则

1. **功能列表/业务页内不展示租户**：禁止页内 `OpsPageTenantField`、筛选区「租户」标签、列表列「租户」、文案「当前租户：xxx」等（平台级租户管理、审计等例外见下）。
2. **租户只在顶栏选**：超级管理员通过 `AdminLayout` 顶栏 **工作租户**（`OpsPlatformTenantSelect`）代入；非超管使用账号绑定租户，无需页内选择。
3. **未选租户须引导**：超管平台模式且 `effectiveTenantId` 为空时，由布局层展示 `OpsTenantRequiredPrompt`，勿静默空表或自动选中租户列表第一项。

## 实现要点

| 项 | 位置 |
|----|------|
| 作用域 | `useOpsPageTenant`：`needsTenantSelection`、`hasEffectiveTenant`；`showPageTenantSelector` 恒为 `false` |
| 布局拦截 | `AdminLayout` + `routeRequiresWorkTenant`（`opsRoutesWithoutWorkTenant.ts` 白名单） |
| 空状态 | `OpsTenantRequiredPrompt.vue` |
| 页内字段 | `OpsPageTenantField` 已废弃，勿新增引用 |

## 例外（可不拦截工作租户）

- 平台租户 CRUD：`tenantList`、`tenantCreate`、`tenantDetail` 等
- 系统 RBAC：`systemUserList` 等
- 操作审计：`auditLogList`（可查平台级日志）
- 全局敏感词：`searchSensitiveWord`（无 `tenant_id`）

新增例外路由须写入 `OPS_ROUTE_NAMES_WITHOUT_WORK_TENANT` 并注明原因。

## 创建人 / 操作人展示

- 列表与详情展示 **用户姓名**（`sys_user.display_name` / `OpsSecurityContext.displayName`），**禁止**展示登录账号（`username`）。
- 写入 `created_by`、`operator_id` 等审计字段时用 `OpsActorLabels.currentActorLabel()`；列表读出时用 `OpsActorLabelResolver.enrichActorFields` 或 SQL `COALESCE(u.display_name, …)`。
- 前端兜底：`operation-backend/src/utils/opsActorLabel.ts`。

## 自检

- [ ] 新列表页未出现租户筛选项/列
- [ ] 超管未选顶栏租户时见引导文案，而非误加载第一个租户数据
- [ ] `initPageTenant` 未默认 `tenantOptions[0]`（除非 `preferId` 来自 URL）
- [ ] 「创建人」「操作人」列不为登录账号

---

## 经验：运营后台详情/列表字段展示规范

### 字段中文标签
所有后端 API 返回的 snake_case 字段名必须在 `operationDetailFieldLabels.ts` 的 `SNAKE_LABELS` 中注册中文映射。未注册的字段会显示为"扩展字段（xxx）"，属于缺陷。

### 金额显示（分→元）
- 详情页 `formatDetailField` 通过正则 `/_fen$|Fen$/` 自动对 `_fen`/`Fen` 后缀的数值字段做 ÷100
- 详情页同时硬编码了 `key === "amount"` 的处理
- **列表页 `formatCellValue` 也需要单独处理 `amount` prop**（列表后端返回的是 `amount` 而非 `total_amount_fen`，因为后端 `orderRow()` 把 `total_amount_fen` 映射到了 `amount` 键）

### 字段值中文映射
`formatDetailField` 需要处理以下非纯文本字段的类型映射：
- `created_at`/`updated_at`（snake_case）也要匹配，不能只处理 camelCase
- `order_status`/`payment_status`/`refund_status` → `mapRawStatusToChineseLabel()` 将英文枚举转中文
- `order_kind`：`NORMAL`→普通订单、`JOINT_CARD_MAIN`→套卡主单、`JOINT_CARD_CHILD`→套卡子单
- `fulfillment_type`：`PICKUP`→到店自提、`DELIVERY`→快递配送、`MAIL`→快递配送、`SELF_PICKUP`→到店自提、`NEXT_DAY`→次日达

### 列表列标签约定
金额列标签应加单位，如 `"订单金额（元）"`，直观提示已从分转换。

---

## 经验：运营后台订单列表增加用户过滤

后端 `OpsPlatformOperationService.listOrders` 的 keyword 仅搜索 `order_no`。如需按用户信息过滤，必须：
1. 后端新增 `userKeyword` 参数
2. INNER JOIN `tenant_user`，按 `user_id` / `nickname` / `mobile` 做 LIKE 查询
3. 使用参数化查询（`?` 占位符），禁止字符串拼接防 SQL 注入
4. 前端 `loadOperationModuleList` params + `OperationModuleListView.vue` 加输入框

---

## 经验：运营后台重复 CSS 消除 — CPS 三视图相同 loading-spinner

- **现象**：审查运营后台 loading 实现时发现 `CpsConfigView.vue`、`DashboardView.vue`、`WithdrawAuditView.vue` 三个文件中有完全相同的 ~12 行 `.loading-spinner` CSS + `@keyframes spin`，逐字复制
- **根因**：三个 CPS 视图各自独立开发，没有提取公共组件。loading 状态（spinner + "加载中…" 文案）是一个通用 UI 模式
- **解决方案**：创建 `components/LoadingSpinner.vue` 共享组件（接受 `text` 和 `testid` props），三个视图统一替换。删除 ~84 行重复 CSS
- **预防**：
  1. 开发同类功能模块（如 CPS 的 config/dashboard/audit）时，第二个视图开始就要考虑提取公共 UI 组件
  2. kd-review 时 grep 搜索相同 CSS 块（`grep -r "loading-spinner" --include="*.vue"`），发现 3+ 文件有相同样式块即应提取
  3. 新建视图时先扫描 `components/` 目录确认是否有可复用组件

---

## 经验：运营后台 Form 初始化必须包含所有字段

运营后台 `el-form` 的 `openCreate()` 初始化 `form` 对象时，**必须包含所有表单项字段**，包括后续新增的字段：

- 新增字段到 `el-form` 模板但忘记在 `openCreate()` 初始化 → TS 类型报错
- 同时检查 `openEdit()` 的回填逻辑（`row[xxx]` 映射）
- 批量 `Object.assign` 不如逐字段赋值可靠（不会漏字段）

---

## 经验：运营后台创建人展示用户姓名而非登录账号

`created_by` / 操作人列须为 `display_name`；写入用 `OpsActorLabels.currentActorLabel()`，读出用 `OpsActorLabelResolver` 或 JOIN `sys_user`。

---

## 经验：运营后台列表不展示页内租户

业务列表/筛选区/表格列勿再展示「租户」选择器或「当前租户：xxx」；超管在顶栏选 **工作租户**，未选时由 `AdminLayout` + `OpsTenantRequiredPrompt` 引导，禁止 `initPageTenant` 静默默认第一项。

---

## 经验：菜单由 `menu.ts` + `sys_menu` 数据库双重维护

### 场景
修改 `operation-backend/src/router/menu.ts` 中的菜单树后，生产环境侧边栏未变化。

### 根因
运营后台的菜单渲染逻辑（`AdminLayout.vue`）优先从后端 API（`GET /api/platform/menu/my`）获取菜单树，该 API 查询 `sys_menu` 数据库表。如果 API 返回数据，则 `menu.ts` 中的静态菜单仅作为本地开发兜底。

```
生产环境：AdminLayout → API → sys_menu 数据库表 ✅ 实际菜单源
本地开发：AdminLayout → menu.ts 静态树（API 无数据时）
```

### 解决方案
- 修改 `menu.ts` 只影响本地开发
- 生产菜单需同步更新 `sys_menu` 表（通过运营后台「系统管理 → 菜单管理」页面，或直接操作数据库）

### 预防
- 改菜单前先确认是通过 `menu.ts` 静态定义还是通过后端 `sys_menu` 数据库维护
- 两者需要保持结构一致，否则生产和本地开发看到的菜单不同
- 新增菜单项时注意同时维护权限点 `sys_permission`（`perm_key` 必须存在）

---

## 经验：数据中心菜单重组

### 场景
将散落在交易管理、运营管理、商户中心、搜索管理等处的统计看板集中到统一的「数据中心」菜单。

### 操作
1. 新增 `nav_data_center` 顶级目录（`sort_order=45`，放在平台管理和系统管理之间）
2. 下设三个子目录：平台层（平台总览/统计看板/平台台账/提现数据分析/用户分析）、业务层（商家KPI看板/搜索看板/连锁数据统计/送达率统计/考试数据统计）、工具（导出中心）
3. 从原菜单移除这些统计项
4. 在 `sys_permission` 中补充缺失的权限点（`ops:platform:view`、`ops:merchant:kpi`、`ops:chain:view`、`ops:notification:stats:view`、`ops:export:list`）

### 预防
- 新增统计类页面优先考虑放入数据中心而非各自模块
- 操作数据库 `sys_menu` 时注意外键约束 `fk_sys_menu_perm`（`perm_key` 必须先存在于 `sys_permission`）

---

## 经验：SidebarMenu route_name 与 vue-router name 不匹配

### 场景
点击侧栏菜单后 console 输出 `[SidebarMenu] Unknown route name: tradeDashboard`，页面不跳转。

### 根因
后端 `sys_menu.route_name` 的值与前端 `router/index.ts` 中 `name:` 字段不一致：
1. **语义不一致**：`automationRule` vs `MarketingAutomation`（完全不同）
2. **大小写不一致**：`conversionFunnel` vs `ConversionFunnel`
3. **路由不存在**：`tradeDashboard` 在前端无对应路由

### 解决方案
三层兜底（`src/utils/opsMenuRouteNames.ts` + `SidebarMenu.vue`）：

```typescript
// 1. 语义映射表 — 显式记录所有历史不一致
const LEGACY_ROUTE_NAME_ALIASES = {
  automationRule: "MarketingAutomation",
  conversionFunnel: "ConversionFunnel",
  // ...
};

// 2. 首字母大写兜底 — 处理大小写不一致
export function tryUpperFirstFallback(name: string): string | undefined {
  const upper = name.charAt(0).toUpperCase() + name.slice(1);
  return upper !== name ? upper : undefined;
}

// 3. SidebarMenu 导航时最后尝试
if (!router.hasRoute(rn)) {
  const fallback = tryUpperFirstFallback(rn);
  if (fallback && router.hasRoute(fallback)) rn = fallback;
  else console.warn(`[SidebarMenu] Unknown route name: ${rn}`);
}
```

### 预防
- 新 Flyway 迁移写入 `sys_menu.route_name` **必须**直接使用 `router/index.ts` 中的 `name`
- 禁止在 seed SQL 中自创 route_name，先用前端定义路由再写入
- 新增菜单后用手工或 Playwright E2E 确认点击导航正常

---

## 经验：运营后台页面使用裸 fetch 导致 OPS_AUTH_BEARER_MISSING

### 场景
访问某运营后台页面时后端返回 401：
```json
{"code":"OPS_AUTH_BEARER_MISSING","message":"缺少 Bearer Token"}
```
但其他页面正常，登录状态有效。

### 根因
该页面使用了原生 `fetch()` 而非 `runRequest()`。原生 `fetch` 不经过 `authHooks.getExtraHeaders`，不会自动携带 `Authorization: Bearer <token>` 头。

检查方法：
```bash
grep -rn "fetch(" src --include="*.vue" --include="*.ts" | grep -v "jsonClient\|node_modules\|__tests__"
```

### 解决方案
替换为 `runRequest`：
```typescript
// ❌ 原生 fetch — 不带 Authorization
const resp = await fetch("/api/ops/notification/records");
const data = await resp.json();

// ✅ runRequest — 自动带 token
import { runRequest } from "../api/jsonClient";
const data = await runRequest<any>({ url: "/api/ops/notification/records" });
```

### 预防
- 所有后端 API 调用必须使用 `runRequest()`，禁止裸 `fetch()`
- 新页面代码审查时检查 API 调用方式

---

## 经验：微信支付模式 UI — 直连/服务商字段必须分离

### 场景
租户配置页「微信支付」Tab 中，直连模式和服务商模式的字段全部混在一个表单里，切换模式只影响 `subMchId` 是否显示，导致：
1. 用户不理解两种模式的区别
2. 服务商模式不需要填商户号/证书/私钥，但都显示出来了
3. 前端未向后端发送 `payMode` 字段（从 `subMchId` 有无推断）

### 根因
后端 `tenant_wechat_profile` 表有 `pay_mode` 列（`DIRECT` / `SERVICE_PROVIDER`），但前端：
- 加载时从 `subMchId` 是否有值推断模式，而非读 `payMode` 字段
- 保存时不发送 `payMode`，只发送 `subMchId`（null = 直连，非 null = 服务商）

### 解决方案

**前端改造**（`TenantFeatureConfigView.vue` 微信支付 Tab）：

1. **模式选择**：顶部两个卡片式 radio，带标题和说明文字（"直连商户" vs "服务商模式"），选中高亮
2. **小程序基础配置**（共用区）：AppId、公众号 AppId、原始 ID、AppSecret — 始终显示
3. **直连商户配置**（仅 `DIRECT` 时显示）：商户号、证书序列号、回调地址、API v3 密钥、私钥、公钥证书
4. **服务商模式配置**（仅 `SERVICE_PROVIDER` 时显示）：特约商户号 + 提示"SP 证书由平台统一管理"
5. **真支付开关**：底部独立区块，两种模式共用

**关键代码改动**：
```typescript
// 加载时从后端 payMode 字段读取（而非从 subMchId 推断）
wechatPayMode.value = String(p.payMode ?? "DIRECT") === "SERVICE_PROVIDER" 
  ? "SERVICE_PROVIDER" : "DIRECT";

// 保存时显式发送 payMode
const body = {
  payMode: wechatPayMode.value,
  // 直连模式才发送证书/密钥字段
  mchId: !isSp ? wechatForm.mchId : null,
  apiV3Key: !isSp ? wechatForm.apiV3Key : undefined,
  // 服务商模式才发送 subMchId
  subMchId: isSp ? wechatForm.subMchId : null,
};
```

### 预防
- 两种互斥的支付模式，其专属字段必须在 UI 和逻辑上分离，禁止混在一个表单
- 后端有显式 `pay_mode` 字段时，前端必须读写该字段，不能从其他字段推断
- 新增支付配置字段时先确认属于哪种模式

