<!--
description: 前端交互组件选择决策树 + 枚举/状态值中文显示映射（MUST）
globs: frontend/**/*.vue, operation-backend/src/**/*.vue
alwaysApply: false
-->

# 前端 UX 与枚举显示规范（MUST）

## 组件选择决策树

以下场景必须使用对应的组件，禁止省事用 `<el-input>` / `<input>` 替代：

| 场景 | operation-backend | frontend（小程序） |
|------|-------------------|-------------------|
| 选项 ≤ 10 的固定集合（状态、类型、角色、审核结果等） | `<el-select>` | `<picker>` |
| 日期/时间选择 | `<el-date-picker>` / `<el-time-picker>` | `<uni-datetime-picker>` |
| 布尔值切换 | `<el-switch>` | `<switch>` |
| 多选固定集合 | `<el-select multiple>` | `<checkbox-group>` |
| 长文本/数字/搜索（仅此用输入框） | `<el-input>` | `<input>` |

## 枚举值中文显示（MUST）

所有 `status` / `type` / `state` / `enum` 类字段在 UI 展示时：

- **`operation-backend/`**：`<el-table-column>` 须用 `formatter` 映射为中文，禁止直接 `prop="status"`；`<el-select>` 选项用 `{ value, label }` 数组；优先复用共享常量文件而非在每个 view 重复定义 `statusLabel()`
- **`frontend/`**（小程序）：须用 computed 或 `formatXxx()` 函数映射为中文，禁止 `{{ rawValue }}` 输出
- **空值/未定义**：显示 `-` 或 `"未知"`，禁止留空白单元格

## 参考文档

- Plan 阶段须在 `docs/superpowers/PLAN_WRITING_CONTRACT.md` §4 中写明枚举显示方案
- 验收阶段须在 `AGENT_WORKFLOW_CONSTRAINTS.md` §5.2 中逐项核对

---

## 经验：C端订单列表全部显示"暂无商品信息"

### 场景
C端小程序订单列表页 (`frontend/src/pages/order/unified-list.vue`) 所有订单都显示"暂无商品信息"，无法看到商品标题。前端模板有三级 fallback：
```vue
<text v-if="item.goodsName">{{ item.goodsName }}</text>
<text v-else-if="item.items && item.items.length">{{ item.items[0].skuName }}</text>
<text v-else>暂无商品信息</text>
```
三个条件全部命中 `v-else`。

### 根因
后端 `OrderQueryBuilder` 的 SQL 只 `SELECT` 了 `trade_order` 表的列（无 `goods_name`），`orderListRow()` 也未输出 `goodsName`。`trade_order` 表本身不存储商品名，`trade_order_item` 只有 `sku_code`。

商品名存储链路：`trade_order_item.sku_code` → `merch_product_sku.sku_code` → `merch_product_spu.title`

### 解决方案
**后端 SQL 增加关联子查询**（`OrderQueryBuilder.java`）：
```sql
SELECT o.id, o.order_no, ...,
       (SELECT COALESCE(spu.title, sku.spec_label, item.sku_code, '')
        FROM trade_order_item item
        LEFT JOIN merch_product_sku sku ON sku.sku_code = item.sku_code AND sku.delete_time = 0
        LEFT JOIN merch_product_spu spu ON spu.id = sku.spu_id AND spu.delete_time = 0
        WHERE item.tenant_id = o.tenant_id AND item.order_no = o.order_no
        ORDER BY item.id ASC
        LIMIT 1) AS goods_name
FROM trade_order o
WHERE ...
```

**后端 RowMapper**（`TenantCoreService.java`）：
```java
String goodsName = rs.getString("goods_name");
if (goodsName != null && !goodsName.isBlank()) {
    row.put("goodsName", goodsName);
}
```

### 预防
- **后端列表 API MUST 返回商品标题**：任何列表 API 展示"标题"类字段，必须确认数据源（DB 表/子查询）已经覆盖，不能依赖前端猜测字段
- **单元测试守护**：`OrderQueryBuilderTest.build_sqlContainsGoodsNameSubquery()` 断言 SQL 包含 `goods_name`、`trade_order_item`、`merch_product_sku`、`merch_product_spu`、`COALESCE`，删除或改动子查询会立即失败
- **前端 fallback 路径要透明**：三级 fallback（`goodsName` → `items[0].skuName` → "暂无商品信息"）要明确，开发时用 E2E 断言验证实际数据链路是否畅通

---

## 经验：recruitment 全栈验收常见问题

### 场景
商家端套卡招募流程的全栈 Review 发现多处前端/后端/DB 层联动问题。

### 问题清单

#### 1. SPU ID 误当 SKU code 提交
- **现象**：创建招募时，前端 `create-step3` 把 `goodsId`（SPU ID）当 `skuCode` 传给后端，后端存入 `joint_card_recruitment_sku.sku_code`
- **根因**：前端接口层未区分 SPU 级别（商品）和 SKU 级别（规格），`GoodsItem.id` 是 SPU ID，但招募业务需要具体的 SKU code
- **解决方案**：`create-step1` 改为 SKU 粒度选择，加载 `GoodsDetail.skus` 后显示子规格，提交 `skuCode` 而非 `goodsId`
- **预防**：任何涉及"选择商品"的流程，先确认业务需要的是 SPU 还是 SKU 粒度，前者传 `goodsId`/`spuId`，后者传 `skuCode`。接口层类型定义须明确命名（如 `skuCode` vs `spuId`）

#### 2. 字段语义错配（perUserLimit 重载）
- **现象**：`perUserLimit`（每人限购）被前端用作招募商家数量上限（`recruitMax`），后端的 `listMatchPool` 还用它计算剩余名额
- **根因**：两个不同的业务概念共用一个 DB 字段，未在方案阶段明确区分
- **解决方案**：新增 `recruit_max_slots` 列，前端 `createRecruitment` 中 `perUserLimit` 传 0（不限购），`recruitMaxSlots` 传招募商家上限
- **预防**：CRUD API 的字段必须有且仅有一个语义，如果需求方说"差不多的意思"就是危险信号。方案评审时每个字段标注中文含义和取值范围

#### 3. 套卡定价应为自动计算而非手动输入
- **现象**：step2 的"套卡定价"做成手输输入框，但业务上定价 = 所有参与商家 SKU 价格之和
- **根因**：前端理解偏差，把聚合值当成独立输入
- **解决方案**：改为只读显示，从 step1 storage 的 `skus` 数组计算 `sum(priceFen * quantity) / 100`
- **预防**：聚合/汇总类字段在 UI 上永远是只读的，不提供输入控件

#### 4. 旧合作流程 API 路径未迁移
- **现象**：`match.vue` 的 `matchFeed()` 和 `createMatchInvite()` 指向 `/api/tenant/joint-card-match/*`，但后端实际路径是 `/api/tenant/joint-cards/*`
- **根因**：合作流程从旧 `joint_card_cooperation` 表迁移到 recruitment 表时，前端页面未同步更新 API 路径
- **解决方案**：删除或标记废弃页面，API 路径统一为新 recruitment 制的 `/api/tenant/joint-cards/recruitments/*`
- **预防**：后端 DROP 旧表的迁移必须同步排查前端和前端 API 层是否有对应的调用路径未更新

---

## 经验：ES2022 `.at(-1)` 在 TypeScript/Vue 项目中编译失败

### 场景
运营后台 `TalentUserListView.vue` 使用 `talentLevels.value.at(-1)` 取数组最后一个元素。`pnpm run build` 时报错：
```
error TS2550: Property 'at' does not exist on type '...[]'. 
Do you need to change your target library? Try changing the 'lib' compiler option to 'es2022' or later.
```

### 根因
项目 `tsconfig.app.json` 继承 `@vue/tsconfig/tsconfig.dom.json`，其 `lib` 默认不包含 `ES2022`。`.at()` 是 ES2022 新增的数组方法。

### 解决方案
```typescript
// Before (breaks build)
const lastLevel = talentLevels.value.at(-1);

// After (compatible)
const arr = talentLevels.value;
const lastLevel = arr[arr.length - 1];
```

**不推荐升级 tsconfig lib**，因为 `.at()` 在某些小程序/H5 运行时 polyfill 不完整，索引访问更安全。

### 预防
1. 避免使用 `.at()`、`Object.hasOwn()`、Top-level await 等 ES2022 特性
2. 不确定特性支持度时，先检查 `tsconfig.json` → `compilerOptions.lib`
3. 构建门禁：`vue-tsc -b && vite build` 会捕获此类错误

---

## 经验：禁止箭头符号表示可点击链接

### 场景
"我的"页面的"个人资料"入口行使用 `›` 箭头装饰表示可点击。用户要求移除并明确禁止这种模式。

### 根因
箭头符号在移动端 UI 中属于视觉噪音，不符合现代卡片式交互风格。用户希望点击区域通过整行热区而非箭头指示。

### 解决方案
```diff
- <text class="profile-entry-row__chev" aria-hidden="true">›</text>
+ <!-- 移除，整行作为点击热区 -->
```

替代方案：
- 整行卡片/行作为点击热区（`@tap` 绑在根元素上）
- 使用按钮文字作为行动点（如"查看店铺"）
- 通过 hover/press 反馈暗示可点击（`hover-class="kd-press"`）

### 预防
- kd-review 时 `grep -rn '›\|__chev\|__arrow' src/ --include="*.vue"` 检查
- 新建页面禁止用 `›` 或 `>` 文字表示跳转

---

## 经验：我的页面空状态独立 block 间距模式

### 场景
"MineAssetsSection"在未登录/加载失败/无数据时显示引导文字，但文字在卡片内缺乏良好间距。用户要求空状态作为独立 block 展示。

### 解决方案

```html
<!-- 空状态：独立的 empty block -->
<view v-if="authLocked" class="mine-assets-empty kd-glass-card kd-glass-card--tint">
  <view class="mine-assets-empty__body">
    <text class="mine-assets-empty__text">登录后查看资产明细</text>
  </view>
</view>
<!-- 数据态：原有标题+行布局 -->
<view v-else class="mine-assets kd-glass-card kd-glass-card--tint">
  <view class="mine-assets__title">标题</view>
  <view v-for="item in items">...</view>
</view>
```

```css
/* 外层 wrapper 保证区块上下间距 */
[data-e2e="mine-assets-section"] {
  margin: 20rpx 0;
}

/* 空状态 block 内部 */
.mine-assets-empty__body {
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 32rpx 24rpx;
}

.mine-assets-empty__text {
  font-size: 26rpx;
  color: var(--kd-color-text-tertiary);
  text-align: center;
  line-height: 1.55;
}
```

### 关键要点
1. 空状态与数据态用不同的模板分支，v-if 区分
2. 区块间距由外层 wrapper 的 `margin: 20rpx 0` 统一控制，不依赖内部组件
3. 空状态文字居中 + 充足 padding（32rpx 上下），视觉上是一个完整 block
4. 空状态隐藏标题，避免"有标题无内容"的奇怪感

### 预防
- 所有"我的"页面的数据区块应当区分空状态和数据态的模板结构
- 空状态不应只是文字 + 小 padding，而是独立 block 布局

---

## 经验：el-input-number 的值绑定

`el-input-number` 使用 `v-model` 时会直接修改绑定值。当需要分/元转换时（数据库存分，界面显元），必须用 `:model-value` + `@update:model-value` 手动转换，不能直接用 `v-model`。

---

## 经验：Element Plus 步骤条 CSS 类名

`el-step` 当前活动步骤的类名是 `is-process`，不是 `is-active`。已完成步骤是 `is-finish`，待处理步骤是 `is-wait`。

---

## 经验：日期时间选择器

- Element Plus `el-date-picker type="datetime"` 比原生 `<input type="datetime-local">` 更可控，有 `value-format` / `format` 属性
- `value-format="YYYY-MM-DDTHH:mm"` 保持与后端字符串格式兼容
- 快捷选择时必须区分开始和结束时间，不能把结束时间同时赋给开始时间

---

## 经验：TEST_PHASE_UNLOCK_UI 必须通过环境变量控制

模块绕过开关绝不能硬编码 `true`：

- 必须从 `import.meta.env.VITE_TEST_PHASE_UNLOCK` 读取
- `.env.dev` 中显式设置 `VITE_TEST_PHASE_UNLOCK=true`，使开发环境可见且可配置
- 生产构建（无该环境变量）默认 `false`，尊重服务端模块门禁

---

## 经验：小程序图标方案选择

微信小程序 WXML 不支持内联 SVG，图标方案优先级：

1. **SVG 文件**（`/static/icons/xxx.svg`）：通过 `<image src>` 加载，可维护、支持品牌色（在 SVG 文件中直接写 `stroke="#16a34a"`），适合形状固定的图标（推荐）
2. **Iconfont**：适合大量图标需要动态切换颜色的场景，但需要额外加载字体文件
3. **CSS 绘制**：适合极简形状（如搜索放大镜），无额外请求
4. **Emoji/Unicode 字符**：不清晰、风格不统一，避免用于 UI 图标

---

## 经验：占位功能提示文案规范

"敬请期待" → "功能暂未开放"：

- "敬请期待" 有假功能/画饼之嫌，不符合交付质量要求
- "功能暂未开放" 更诚实直接
- 同时在 `console.warn()` 输出调试信息，便于开发追踪
- 不要用骨架页冒充真实功能

---

## 经验：城市选择器显示上限

城市选择等列表型 UI，一次性展示过多选项会降低可用性：

- 合理上限 ~6 项，使用 `slice(0, maxItems)` 截断
- 配合「查看全部」展开或搜索功能
- 避免首屏渲染大量文本节点影响性能

---

## 经验：首页瀑布流性能优化三维策略

### 场景
首页加载慢，金刚区动画延迟 ~0.86s 逐格淡入，非首屏 section 在网络请求队首阻塞渲染。

### 根因
1. `QuickActionsSwiper` CSS `animation-delay: calc(var(--i) * 0.04s)` 导致 10 格依次出现
2. `onMounted` 和 `watch(tenantRuntime)` 重复触发同一批 8+ 网络请求
3. 非首屏 section（商会、圈子、资讯、瀑布流）在首屏渲染时阻塞带宽

### 解决方案
1. **移除动画延迟**：删除 `QuickActionsSwiper.vue` 中 `animation` + `animation-delay` + `@keyframes cell-in`
2. **watch/onMounted 去重**：`let initialLoadDone = false;` flag，watch 中 `if (initialLoadDone) return;`
3. **渐进式加载**：`onMounted` 分三批 `setTimeout` (0ms 次日达+热词+排行 / 100ms 商会+资讯 / 200ms 圈子+瀑布流)
4. **热词缓存**：`uni.getStorageSync` 缓存 30 分钟，二次进入 0ms 展示
5. **图片懒加载**：Banner/次日达/圈子/资讯等 `<image>` 添加 `lazy-load` 属性

### 预防
1. 组件中避免逐元素延迟动画，影响首屏感知速度
2. `watch(immediate: true)` + `onMounted` 组合时检查去重
3. 非首屏内容延迟加载（`setTimeout` 或 `IntersectionObserver`）
4. 低频变化数据（热词、配置类）使用 `uni.storage` 缓存

---

## 经验：Tabbar 必须无条件始终渲染

Tabbar（自定义底部导航）是核心导航元素，不能跟随模块开关或 TEST_PHASE_UNLOCK 控制：

- `applyTabBarVisibility()` 中所有 tab 必须无条件设为 `true`
- 生产环境与开发环境一致，不得隐藏
- Tabbar 不是功能模块，是导航壳层，与模块门禁解耦

---

## 经验：CategoryPicker 子分类不显示 — API 数据结构不匹配

### 场景
选择一级分类后，二级卡片永远为空。用户点击"招聘求职"看不到"全职招聘""兼职招聘""求职意向"。

### 根因
API 返回的分类树结构是嵌套 `children[]`：

```json
{ "code": "recruitment", "name": "招聘求职", "children": [
  { "code": "recruitment_fulltime", "name": "全职招聘" }
]}
```

但前端 `level2Categories` 计算属性在顶层数组按前缀匹配 `recruitment_*`，永远找不到子类。

```typescript
// ❌ 错误：按前缀在顶层数组搜
categories.value.filter((c) => c.code.startsWith('recruitment_'))

// ✅ 正确：从 parent.children 读取
const parent = categories.value.find(c => c.code === activeL1);
return parent?.children || [];
```

### 解决方案
1. `DemandCategory` 接口必须加 `children?: DemandCategory[]`
2. `level2Categories` 从选中一级的 `children` 字段读取，非全局前缀搜索
3. 对于无二级分类的一级（如"其他需求"），直接在 `selectL1` 里 emit 完成选择

### 预防
- 任何树形数据接口，前端必须先确认数据结构（嵌套 vs 扁平前缀），不要假设
- 加 `console.log` 验证 `level2Categories` 实际值

---

## 经验：design tokens 统一替换法则

### 场景
所有新增品类页面（12 个）使用了硬编码颜色、字号、圆角、阴影，与项目 design system 不一致。

### 解决方案 — 批量替换映射

| 硬编码 | Token |
|--------|-------|
| `#222`, `#111`, `#1A1A1A` | `var(--kd-color-text)` |
| `#666`, `#888` | `var(--kd-color-text-secondary)` |
| `#999`, `#BBB` | `var(--kd-color-text-tertiary)` |
| `#fff` 背景 | `var(--kd-surface-elevated)` |
| `#F7F7F7` | `var(--kd-bg-page, #F7F7F7)` |
| `font-size: 28rpx` | `var(--kd-font-base)` |
| `font-weight: 700` | `var(--kd-font-weight-bold)` |
| `font-weight: 600` | `var(--kd-font-weight-semibold)` |
| `border-radius: 12rpx` | `var(--kd-radius-md)` |
| `border-radius: 40rpx` | `var(--kd-radius-full)` |
| `linear-gradient(...)` 主按钮 | `var(--kd-gradient-primary)` |
| `#00B341` | `var(--kd-color-primary)` |
| `#FF5000` 价格 | `var(--kd-color-danger)` |
| `box-shadow: ...` | `var(--kd-shadow-card)` |

### 预防
- 品类品牌色（如招聘蓝 `#2B6DE8`）声明为页面级 CSS 变量 `--brand-xxx`，与 kd-token 共存
- 所有新文件必须在 Code Review 前跑 token 检查

---

## 经验：C 端推送状态枚举中文映射（C-end push status labels）

### 场景
kd-review 审查新增的 `push-list.vue` 和 `push-detail.vue` 时发现 `{{ c.status }}` 直接显示后端英文状态值（如 `PENDING`、`SENT`），违反项目"所有状态/枚举必须映射为中文显示"规则。

### 根因
该规则此前仅强调运营后台枚举映射（`ops-tenant` 范围），未覆盖 C 端页面。新开发的 C 端营销页面遗漏了 status-label 映射。

### 解决
C 端页面同样需要中文状态映射——映射表定义在 Vue 组件内或共享常量：

```typescript
const STATUS_MAP: Record<string, string> = {
  DRAFT: '草稿',
  PENDING: '待推送',
  SENDING: '推送中', 
  SENT: '已推送',
  CANCELLED: '已取消',
};
// template: {{ STATUS_MAP[c.status] || c.status }}
```

### 预防
1. kd-review 审查 agent 的 Vue 页面 bucket 应检查所有 `{{ x.status }}` 是否有映射表
2. 统一在 `src/constants/statusLabels.ts` 定义营销相关状态映射，C 端和运营后台共享
3. 不仅是运营后台，**所有前后端状态枚举**（包括 C 端小程序）都必须中文映射
