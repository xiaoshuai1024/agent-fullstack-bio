# 运营后台（operation-backend）开发规范

适用范围：`operation-backend/` Vue 运营控制台及其依赖的后端运营 API（`/api/platform/**` 中与运营菜单对应的读模型）。

**Agent 门禁**：执行 **`/super-pm`**、**`/ux-product-review`** 或加载 **`ux-product-review`** 且审查对象涉及上述范围时，须将本文作为**运营后台交互与展示**的权威对照，并同时满足 [`docs/superpowers/KANGDOU_PRODUCT_DELIVERY_CONTRACT.md`](../superpowers/KANGDOU_PRODUCT_DELIVERY_CONTRACT.md) 中 **运营主区通栏**等条款；在 rubric 中单列 **「运营后台交互规范对照」**（见 `.agents/skills/ux-product-review/SKILL.md`），对不符合项归入阻断／建议并提出可执行优化。

### 0. 环境与测试数据源（MUST）

- **本地联调、后端集成测（`*IT.java`）与运营 E2E 所连后端**：数据源与 `backend/src/main/resources/application-local.yml` / `backend/src/test/resources/application.yml` 对齐；团队约定使用 **MySQL 开发库 `kddev`**（或经 `SPRING_DATASOURCE_URL` 显式覆盖的等价库）。**勿**在文档或脚本中再引入与 `kddev` 脱节的「另一套默认测试库名」以免与 `mvn verify`、Playwright 门禁不一致。
- 跑 **`pnpm run test:e2e`** 前须 **`8080` 已指向上述库且 Flyway 已迁移**；连接失败时先修库与配置，**禁止**用全量 `skip` 冒充通过。

### 0.1 字体：禁止 Google Fonts 外链（MUST）

- **`operation-backend/index.html`**：**禁止**使用 `fonts.googleapis.com`、`fonts.gstatic.com` 的 `<link rel="preconnect">` / `<link rel="stylesheet">` 或等价外链（合规、内网环境、CI 与外网抖动；亦避免拖慢 `window.onload` / E2E）。
- **默认实现**：全壳与小程序首页运营主题使用 **系统字体栈**（`system-ui`、`ui-sans-serif`、`-apple-system`，中文回退 **`PingFang SC` / `Hiragino Sans GB` / `Microsoft YaHei`** 等），见 `src/styles/miniapp-home-theme.css`。
- **若必须与指定品牌字体一致**：将 **woff2** 放入 **`public/fonts/`** 并用 **`@font-face`** 自托管，**不得**再指向 Google CDN。

---

## 1. 列表展示：禁止「裸代码」作为主信息

### 1.1 原则（MUST）

- **状态、渠道、类型、审核结果等枚举字段**：列表**主列**必须展示**运营可读的中文业务语义**（可用 `el-tag` + 颜色区分），**不得**仅展示数据库/API 中的英文枚举值（如 `PENDING`、`PAID`、`WECHAT`）作为主文案。
- **权限点 key、审计 module.action、内部路由名、驼峰模块 key**：**不得**作为列表唯一或首要展示；若排障需要，放在 **tooltip**、次要列标题为「技术标识」、或详情页「调试信息」区域。
- **金额**：列表中展示须有明确单位语境（如「元」与后端「分」字段需在接口或前端格式化一致），避免裸整数误导。
- **租户**：下拉与列表**主文案为租户名称**；`tenantId`、租户编码可作副标、`tooltip` 或次要列，对齐 `AGENTS.md` 既有表述。

### 1.2 允许例外（ALLOWED）

- **业务单号**（订单号、支付单号、退款单号等）：可作为主列或关键词列展示，视为运营可追溯的业务标识。
- **`requestId` / 日志追踪号**：可独占列用于排障；列标题标明用途。
- **搜索框 / 筛选条件**：可使用编码或 ID 作为输入值（与用户明示占位文案）。

### 1.3 实现偏好

- **优先后端给展示字段**：列表 DTO 增加 `displayStatus`、`displayChannel` 等，与枚举同源映射（Java 枚举/`LinkedHashMap` 单源），前端只做兜底格式化。
- **禁止**：用「占位文案」「假数据行」冒充真实列表；无数据时用空态说明 + 引导，而非 skeleton 无限加载冒充有数据（与项目 UX 红线一致）。

### 1.4 过滤与查询交互（MUST）

- **所有「过滤类」能力**（下拉、日期范围、关键词输入等）：**选择或输入后即触发查询/列表刷新**，**不得**依赖单独的「查询」「筛选」按钮作为唯一提交入口（按钮易造成「改了条件却忘了点」的运营事故）。
- **例外**：显式 **「刷新」** 仅用于在条件不变时**重新拉取当前页**（与筛选提交区分开）；若页面无单独刷新按钮，则依赖路由进入或下拉变更即可。
- **文本关键词**：须做**防抖**（建议 300–500ms），避免输入过程中连续打爆接口。
- **分页切换**：仍按既有行为在换页时请求即可。

### 1.5 页面进入与 Tab 切换时的数据请求（MUST）

- **列表页、详情页**在**进入当前路由后**须发起与本页展示一致的读请求（Vue 3 使用 **`onMounted`**；若页面被 **`keep-alive`** 缓存，还须 **`onActivated`** 中在必要时刷新，避免回到页仍显示过期数据）。
- **同一组件复用在多条路由上**（例如同一 `*.vue` 对应「订单 / 支付 / 退款」不同 `meta.moduleKey`）时，**必须 `watch` 路由标识**（如 `route.name`、`route.params`、`route.query` 中与数据相关的字段），在变化时**重置分页/关键词等本地状态**并**重新请求**，不可仅依赖 `onMounted`（组件不卸载时不会再次执行）。
- **`el-tabs` / 分段视图切换**：切换 Tab 时**必须**触发对应数据集请求（可「每次切换都拉取」或「懒加载首次进入该 Tab 再拉取」；若采用懒加载，**首次切换到该 Tab 仍须请求**）。禁止仅依赖首屏一次性请求却在其它 Tab 下永远展示空表或陈旧数据。
- **例外**：纯展示、无独立后端资源的 Tab（如仅说明文案）可不请求；须在 PR 中注明理由。

### 1.6 页内租户与顶栏「工作租户」联动（MUST）

- **数据来源**：租户作用域须使用 `useOpsPageTenant` 推导的 **`effectiveTenantId`**（顶栏代入 / 绑定租户优先于页内选择）；所有按租户请求的 API、query、`X-Tenant-Id` 与该值对齐。
- **不得重复选择器**：**已代入**（超管顶栏选中租户）或 **非超管已绑定租户** 时，**禁止**在页面工具条再放一个「选租户」下拉；须用 `OpsPageTenantField` 的只读分支或等价展示（名称 + `tenantId` 副文案）。
- **必须提供页内选择时**：仅在 **超管且顶栏未代入（平台模式）** 下展示可 **filterable** 的租户选择器；推荐 `OpsPageTenantField` + `initPageTenant(preferRouteQueryTenantId?)`。
- **`/system/audit-log`**：租户筛选遵循同一规则——代入或绑定租户时固定 `effectiveTenantId` 请求列表，勿与顶栏重复一套租户筛选。

---

## 2. 详情页

- **禁止**将整条 JSON `pre` 块作为面向运营的详情终态（调试页除外）；须结构化字段 + 标签中文。
- **`OperationModuleDetailView` 全模块（MUST）：** 不仅订单/支付/退款，**凡**经该组件渲染的运营管理详情，均不得使用 `v-else` 等路径回落为**整页** `<pre class="detail-json">`；须与交易模块一致：`el-descriptions`（或按 `moduleKey` 的专用面板）+ **默认折叠**的「原始数据 / 排障」区。
- 详见 [docs/superpowers/plans/2026-05-12-operation-trade-ops-ux-hardening.md](../superpowers/plans/2026-05-12-operation-trade-ops-ux-hardening.md)（AC3、AC6、U6、§9.1 防再犯表）。

### 2.1 审核类交互（MUST）

- 凡运营侧「审核」写操作（退款、提现、策略等）：须在同一流程（弹窗/抽屉/详情底部栏）内同时提供 **「通过」与「拒绝」**；**拒绝**须采集**原因**（长度与后端校验一致），禁止仅暴露单一 `approve` 入口而无对称 reject UI。
- 列表行仅保留单一「退款审核」类入口**允许**，但打开后必须双按钮 + 原因输入（与现有退款弹窗一致并作为模板）。

### 2.2 管理壳布局（`AdminLayout`）（MUST）

- **主内容区**：在侧栏 + 顶栏布局下须 `min-width: 0`、内容区 `overflow: auto`，宽表在**主区内**横向滚动，避免主列被挤到不可读。
- **长侧栏菜单**：侧栏区域须独立纵向滚动；**路由 `fullPath` 变化后**将主内容滚动条置顶（或滚顶 `RouterView` 容器），避免用户点击靠下菜单项后仍停留在上一屏纵向底部、误以为右侧无内容。
- 方案级验收与 E2E 映射见 `2026-05-12-operation-trade-ops-ux-hardening.md`（AC8、AC9、U8）。

### 2.3 主内容区通栏（MUST）

与 [docs/superpowers/KANGDOU_PRODUCT_DELIVERY_CONTRACT.md](../superpowers/KANGDOU_PRODUCT_DELIVERY_CONTRACT.md) **§3** 一致。

- **右侧主内容区**（`RouterView` 承载的业务页区域）在可用视口内须 **通栏占满**（**不得**对业务页根容器使用整页级 `max-width`（如 `1100px`）+ 居中导致列表与工具条两侧大块留白；宽表允许在 **主区内** 横向滚动）。
- **禁止**：为「表单好看」将整页主列限制在固定像素宽内；局部控件（如单个 `el-input`）可设宽度，但 **不得**作为整页主容器的默认布局。
- **常见违规（MUST 禁止）**：在业务页 `*.vue` 的 `<style scoped>` 里，对**路由视图根节点**（如根 `div.page`、根 `div` 包裹整页 `el-card` 的 class）设置 **`max-width: Npx`**。`AdminLayout` 已通栏时，此类样式仍会把**业务内容**压成窄条（例如 `/trade-settlement/membership-offline` 曾长期表现为右侧大片留白），且 **仅阅读 `AdminLayout.vue` 或全局布局文件无法发现**，必须在业务视图层排查。
- **全局样式（MUST）**：`main.ts` 等入口引入的全局 CSS 中，凡作用于「运营业务主区」的宽度规则，须与 **`.miniapp-home-scope` 等设计域 class** 正确嵌套；**不得**把仅打算给小程序首页运营子模块用的 **`max-width`** 写在「无祖先选择器约束」的选择器上，以免误伤其它路由（历史问题见 `src/styles/miniapp-home-theme.css` 与 `MiniappHomeSectionView` 的 `.mh-page` 约定）。
- **正确做法（ALLOWED）**：可读性通过 **`el-form` 外包一层**设 `max-width`、`el-col` 栅格，或**单个表单项控件**的 `style="max-width: …"` 控制；**列表 / 表格 / 工具条** 仍占满主区可用宽度。
- **ALLOWED**：抽屉/弹窗/对话框内固定宽度；纯文档型只读页经 PR 说明的例外（须引用业务理由）。

#### 2.3.1 Code review / 自检时的必查动作（MUST）

审查或自检运营后台布局时，**除**阅读 `AdminLayout.vue` 外，须在 `operation-backend` 内至少执行一次以下检索（或等价搜索），并对命中行判断是否落在**页面根**或误泄漏的全局选择器上：

```bash
rg "max-width" operation-backend/src --glob "*.vue"
rg "max-width" operation-backend/src/styles --glob "*.css"
```

凡在**业务页根容器**或**无作用域前缀的全局样式**上出现「整页级」像素 `max-width`，按本节 **MUST** 处理，不得合并。

---

## 3. 审计与操作日志列表

- 全局 **`/system/audit-log`** 须使用 **`display_*`**（或与 `OpsAuditMetadata` 一致的字段）作为主展示；技术 `module`/`action` 仅 tooltip。
- 各运营管理页底部嵌入式审计表格须与上述口径一致，**不得**将 `module.action` 拼接串作为主列。

---

## 4. 自检（PR / 联调）

- [ ] 新增或变更列表列：枚举类字段是否均为中文标签？
- [ ] 是否仅在 tooltip/次要列暴露技术 code？
- [ ] 与后端契约：展示字段是否由读模型统一映射，避免前端散落魔法字符串？
- [ ] 新增或变更筛选区：是否「选/输即查」、关键词是否防抖、是否仍依赖单独「查询」按钮？
- [ ] 列表/详情：**进入页**是否请求数据？**路由参数或模块切换**是否 `watch` 并重拉？**Tab 切换**是否触发对应请求（或已声明不适用例外）？
- [ ] 本地/CI 后端是否指向约定 **`kddev`**（或文档化覆盖变量）？
- [ ] 详情页（含 **非交易** `OperationModuleDetailView`）：首屏是否结构化？整页 JSON 是否已消除？
- [ ] 审核能力：是否 **通过 + 拒绝** 同事务可见？拒绝是否必填原因？
- [ ] 管理壳：窄视口下主区是否可读？路由切换后主区是否 **滚回顶部**？
- [ ] **主区通栏（§2.3）**：业务页根节点、入口全局 CSS 是否**未**使用整页级 `max-width`？是否已按 **§2.3.1** 对 `views/**/*.vue` 与 `src/styles/**/*.css` 做过 `max-width` 检索？
- [ ] **页内租户（§1.6）**：是否统一 `effectiveTenantId`？代入/绑定租户时是否已隐藏页内选择器？平台超管未代入页是否可筛选租户？

---

## 5. 修订记录

| 日期 | 说明 |
|------|------|
| 2026-05-15 | 新增 **§1.6** 页内租户与顶栏代入联动；自检表增加页内租户一项。 |
| 2026-05-11 | 初稿；补充过滤类「选/输即查」与关键词防抖；列表与审计展示约定。 |
| 2026-05-12 | 增补 **§0** 测试/联调使用 **`kddev`**；**§1.5** 进入页、`watch` 路由复用、`el-tabs` 切换须请求数据；自检表两项。 |
| 2026-05-12 | **§2** 扩展非交易详情禁整页 JSON；新增 **§2.1 审核双通道**、**§2.2 管理壳滚顶与宽度**；自检表三项（对齐 `operation-trade-ops-ux-hardening` 方案）。 |
| 2026-05-13 | **§2.3** 补充「scoped 根容器 `max-width`」与全局样式泄漏说明；新增 **§2.3.1** 必查 `rg` 动作；自检表增加通栏/`max-width` 项（对齐 `/trade-settlement/membership-offline` 等典型页踩坑复盘）。 |
---

## 6. 订单明细工作台样式（MUST）

- 适用范围：运营后台中以“订单明细 / 流水明细 / 结算明细”为核心任务的详情页、业绩页、对账页。
- 首屏优先级：用户进入页面后，首屏首先看到的必须是明细表格本身，或至少是明细表标题、统计 chips 与表头区域；不得先被大面积 hero、宣传头图、过高摘要区占据。
- 头部摘要：允许保留对象身份信息，但必须压缩为单行或薄摘要带，只放名称、ID、状态、等级、最近时间等高密度内容；禁止使用高占位大卡式 hero。
- 推荐结构：`页头操作区 -> 薄摘要带 -> 明细表工作台 -> 次级指标卡`。指标卡属于辅助信息，不得压过明细表的视觉优先级。
- 明细表面板：使用独立容器承载，包含标题、副说明、统计 chips、表头、空态；表格容器允许横向滚动，但必须保持统一圆角、内边距、边框和 hover 反馈。
- 表格视觉：表头使用浅底色与 12px-13px 中高字重；订单号使用等宽字体；金额列使用更高字重；状态与佣金状态使用胶囊标签，不直接裸文字堆叠。
- 信息隔离：当业务要求隐藏绑定用户、敏感对象或隐私关系时，只保留订单事实本身，不得在表格上方摘要区重新暴露这些对象。
- 空态规范：空态放在表格面板内部，使用简短结论句，不得再用大幅插画或超高留白把页面拉长。

### 6.1 已落地参考

- 达人业绩详情页：`operation-backend/src/views/talent/TalentPerformanceDetailView.vue`
- 数据大屏：`operation-backend/src/views/stats/ScreenView.vue`

## 7. 数据大屏开发规范

数据大屏（`/screen` 路由）是运营后台的特殊全屏页面，有独立的视觉和交互规范。

### 7.1 技术栈

| 能力 | 方案 | 说明 |
|------|------|------|
| 粒子背景 | Three.js | `useScreenParticles` composable，1200 粒子 + 视差 |
| 数字动画 | TweenJS | `useScreenNumberTween` composable，Cubic.Out 缓动 |
| 图表 | ECharts + D3.js | ECharts 折线/饼图；D3 柱状图/排行条形图 |
| CSS 特效 | 纯 CSS | 网格/扫描线/四角装饰/光晕，无额外依赖 |

### 7.2 CSS 大屏特效标准

```css
/* 深色背景 */
background: #0a1628;

/* 网格背景 */
background-image:
  linear-gradient(rgba(59,130,246,0.03) 1px, transparent 1px),
  linear-gradient(90deg, rgba(59,130,246,0.03) 1px, transparent 1px);
background-size: 60px 60px;

/* 扫描线动画：8s 从上到下，透明度渐变 */
/* 四角装饰：2px 边框，14px 边长，border-top/left 组合 */
/* 卡片光晕：radial-gradient + 8s rotate animation */
```

### 7.3 KPI 卡片动画

- 入场：`fadeInUp 0.6s`，`animation-delay` 按 index 递增 0.12s
- 数字：TweenJS `Cubic.Out` 1200ms 从 0 到目标值
- hover：translateY(-2px) + border-color 变化

### 7.4 页面路由

大屏是**独立全屏路由**（不继承 AdminLayout），在 `router/index.ts` 中单独声明：

```ts
{ path: "/screen", name: "screen", component: V.ScreenView, meta: { perm: "ops:stats:read" } }
```
