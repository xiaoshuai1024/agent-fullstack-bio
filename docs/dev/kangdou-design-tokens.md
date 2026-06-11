<!--
description: KangDou v1.0 设计 Token 与组件使用强制规范（MUST）。所有前端 UI 改动前须加载，禁止硬编码样式值替代 Token。
globs: frontend/**/*.vue
alwaysApply: false
-->

# 设计 Token 与组件规范（MUST）

**任何 UI 改动前**，须先读取以下参考源：
1. `frontend/src/styles/tokens/generated/variables.css` — 生成的 CSS 变量 Token 定义（SSOT）
2. `frontend/src/styles/tokens/json/` — JSON 源（DTCG 格式，手动编辑入口）
3. `frontend/scripts/build-tokens.mjs` — 构建脚本

## 1. 架构概览：三层 Token 体系

```
JSON 源（DTCG 格式）
├── global/color-space.json   — 全局色板（green/amber/red/blue 等 ramp）
├── alias/core.json           — 语义别名（引用 global 色板）
├── comp/semantic.json        — 组件级 token（button/input/card）
└── themes/{name}.json        — 主题覆盖（只输出差异）

    ↓  node scripts/build-tokens.mjs

生成 CSS
├── variables.css             — 默认绿色主题（page {}）
├── theme-{name}.css          — 各主题覆盖（.kd-theme-{name} {}）
├── utilities.css             — 工具类（.kd-glass-card, .kd-skeleton 等）
└── theme-catalog.ts          — 主题元数据（TypeScript）
```

**构建命令**：`cd frontend && pnpm run build:tokens`

## 2. 完整 Token 速查（生成值，以 `variables.css` 为 SSOT）

### 2.1 品牌色

| Token | 当前值 | 用途 |
|-------|--------|------|
| `--kd-color-primary` | `#00B341` | **品牌绿**，主按钮、选中态、聚焦环、价格、链接 |
| `--kd-color-primary-light` | `#34D399` | 绿 400，hover 态底色 |
| `--kd-color-primary-dark` | `#047857` | 绿 800，按压态 |
| `--kd-color-primary-subtle` | `rgba(0, 179, 65, 0.08)` | 极淡绿底 |
| `--kd-color-primary-soft` | `rgba(0, 179, 65, 0.12)` | 淡绿底 |
| `--kd-color-primary-glow` | `rgba(0, 179, 65, 0.18)` | 绿色发光 |
| `--kd-color-primary-rgb` | `0, 179, 65` | RGB 通道值（用于 `rgba(var(--kd-color-primary-rgb), .1)`） |

### 2.2 语义色

| Token | 当前值 | 用途 |
|-------|--------|------|
| `--kd-color-accent` | `#FFD554` | 活力黄，促销、次要强调 |
| `--kd-color-accent-rgb` | `217, 119, 6` | 琥珀色通道 |
| `--kd-color-danger` | `#DC2626` | 警示、错误、删除 |
| `--kd-color-danger-rgb` | `220, 38, 38` | 红色通道 |
| `--kd-color-info` | `#2563EB` | 信息提示 |
| `--kd-color-info-rgb` | `37, 99, 235` | 蓝色通道 |
| `--kd-color-success` | `#27AE60` | 成功 |
| `--kd-color-warning` | `#F59E0B` | 警告 |
| `--kd-color-warning-rgb` | `245, 158, 11` | 警告通道 |
| `--kd-color-text` | `#1a1a2e` | 主文案 |
| `--kd-color-text-secondary` | `#737373` | 次要文案 |
| `--kd-color-text-tertiary` | `#A3A3A3` | 辅助文案、占位符 |
| `--kd-color-text-quaternary` | `#525252` | 描述文案 |
| `--kd-color-text-inverse` | `#FFFFFF` | 反色文案 |
| `--kd-color-text-link` | `#00B341` | 链接色 |
| `--kd-color-border` | `rgba(0, 0, 0, 0.06)` | 边框 |
| `--kd-color-border-light` | `rgba(0, 0, 0, 0.04)` | 浅边框 |

### 2.3 面 & 背景

| Token | 当前值 | 用途 |
|-------|--------|------|
| `--kd-surface` | `#FFFFFF` | 白色面板 |
| `--kd-surface-elevated` | `#FAFAFA` | 抬高面 |
| `--kd-surface-hover` | `#F5F5F5` | hover 态 |
| `--kd-surface-dim` | `#E5E5E5` | 沉底面 |
| `--kd-surface-inverse` | `#171717` | 反色面 |
| `--kd-surface-success-bg` | `#ECFDF5` | 成功背景 |
| `--kd-surface-warning-bg` | `#FFFBEB` | 警告背景 |
| `--kd-surface-danger-bg` | `#FEF2F2` | 危险背景 |
| `--kd-surface-info-bg` | `#EFF6FF` | 信息背景 |
| `--kd-bg-gradient` | `linear-gradient(170deg, #e6eeea 0%, ..., #fafdfb 100%)` | **页面默认铺底渐变** |
| `--kd-bg-gradient-warm` | `linear-gradient(170deg, #f5efe6 0%, ..., #fafdfb 100%)` | 暖色铺底渐变 |

### 2.4 玻璃拟态（毛玻璃）

| Token | 当前值 |
|-------|--------|
| `--kd-glass-bg-top` | `rgba(255, 255, 255, 0.52)` |
| `--kd-glass-bg-bottom` | `rgba(255, 255, 255, 0.18)` |
| `--kd-glass-bg-tint-top` | `rgba(255, 255, 255, 0.38)` |
| `--kd-glass-bg-tint-bottom` | `rgba(236, 253, 245, 0.22)` |
| `--kd-glass-border` | `rgba(255, 255, 255, 0.85)` |
| `--kd-glass-border-mint` | `rgba(0, 179, 65, 0.12)` |
| `--kd-glass-blur` | `26px` |
| `--kd-glass-shadow` | `0 8rpx 32rpx rgba(19, 59, 35, 0.06)` |
| `--kd-glass-inset` | `inset 0 1rpx 0 rgba(255, 255, 255, 0.78)` |

### 2.5 间距

| Token | 值 | 适用场景 |
|-------|-----|---------|
| `--kd-page-padding` | `40rpx` | 页面水平边距 |
| `--kd-space-xs` | `8rpx` | 极小间距 |
| `--kd-space-sm` | `12rpx` | 紧凑间距 |
| `--kd-space-md` | `16rpx` | 中等间距 |
| `--kd-space-lg` | `24rpx` | 宽松间距 |
| `--kd-space-xl` | `32rpx` | 大间距 |
| `--kd-space-component` | `32rpx` | 组件间距 |
| `--kd-space-list` | `24rpx` | 列表项间距 |

### 2.6 圆角

| Token | 值 | 适用场景 |
|-------|-----|---------|
| `--kd-radius-sm` | `8rpx` | 小控件、标签 |
| `--kd-radius-md` | `14rpx` | 输入框、按钮 |
| `--kd-radius-lg` | `20rpx` | 卡片 |
| `--kd-radius-xl` | `28rpx` | 大弹窗 |
| `--kd-radius-full` | `9999rpx` | 药丸形 |

### 2.7 字体

| Token | 值 | 适用场景 |
|-------|-----|---------|
| `--kd-font-xs` | `20rpx` | 辅助文字 |
| `--kd-font-sm` | `22rpx` | 小标签 |
| `--kd-font-base` | `26rpx` | 正文 |
| `--kd-font-md` | `28rpx` | 标题/高亮 |
| `--kd-font-lg` | `32rpx` | 大标题 |
| `--kd-font-xl` | `38rpx` | 页面标题 |
| `--kd-font-2xl` | `46rpx` | 金额大号 |
| `--kd-font-3xl` | `56rpx` | 超大号 |
| `--kd-font-weight-regular` | `400` | 常规 |
| `--kd-font-weight-medium` | `500` | 中等 |
| `--kd-font-weight-semibold` | `600` | 半粗 |
| `--kd-font-weight-bold` | `700` | 粗体 |

### 2.8 阴影

| Token | 值 |
|-------|-----|
| `--kd-shadow-sm` | `0 1rpx 3rpx rgba(0,0,0,0.04), 0 1rpx 2rpx rgba(0,0,0,0.02)` |
| `--kd-shadow-md` | `0 4rpx 12rpx rgba(0,0,0,0.05), 0 2rpx 4rpx rgba(0,0,0,0.03)` |
| `--kd-shadow-lg` | `0 8rpx 28rpx rgba(0,0,0,0.07), 0 3rpx 8rpx rgba(0,0,0,0.04)` |
| `--kd-shadow-xl` | `0 12rpx 48rpx rgba(0,0,0,0.09), 0 4rpx 12rpx rgba(0,0,0,0.05)` |
| `--kd-shadow-glow` | `0 4rpx 20rpx rgba(0, 179, 65, 0.18)` |

### 2.9 组件语义 Token

| Token | 值 | 适用场景 |
|-------|-----|---------|
| `--kd-button-height` | `80rpx` | 标准按钮 |
| `--kd-button-height-lg` | `96rpx` | 大按钮（主 CTA） |
| `--kd-button-height-sm` | `60rpx` | 小按钮 |
| `--kd-button-radius` | `14rpx` | 按钮圆角 |
| `--kd-button-radius-pill` | `999rpx` | 药丸形按钮（仅首页 banner 等特例） |
| `--kd-button-font-size` | `28rpx` | 按钮字号 |
| `--kd-input-height` | `80rpx` | 输入框高度 |
| `--kd-input-radius` | `14rpx` | 输入框圆角 |
| `--kd-input-padding-x` | `24rpx` | 输入框水平内边距 |
| `--kd-card-padding` | `24rpx` | 卡片内边距 |
| `--kd-card-radius` | `20rpx` | 卡片圆角 |

### 2.10 动画

| Token | 值 |
|-------|-----|
| `--kd-duration-fast` | `150ms` |
| `--kd-duration-normal` | `250ms` |
| `--kd-duration-slow` | `400ms` |
| `--kd-easing-in` | `cubic-bezier(0.4, 0, 1, 1)` |
| `--kd-easing-out` | `cubic-bezier(0, 0, 0.2, 1)` |
| `--kd-easing-in-out` | `cubic-bezier(0.4, 0, 0.2, 1)` |
| `--kd-easing-spring` | `cubic-bezier(0.34, 1.56, 0.64, 1)` |

### 2.11 IM（即时通讯）

| Token | 值 | 用途 |
|-------|-----|------|
| `--kd-im-bubble-self` | `#00B341` | 自己气泡 |
| `--kd-im-bubble-self-text` | `#FFFFFF` | 自己气泡文字 |
| `--kd-im-bubble-other` | `#FFFFFF` | 对方气泡 |
| `--kd-im-bubble-other-text` | `#1a1a2e` | 对方气泡文字 |
| `--kd-im-panel-bg` | `#FAFAFA` | 面板背景 |
| `--kd-im-input-bg` | `#FFFFFF` | 输入框背景 |
| `--kd-im-input-radius` | `28rpx` | 输入框圆角 |

## 3. 可复用组件（优先使用，禁止手写替代）

### 3.1 页面骨架

| 组件 | 路径 | 用途 |
|------|------|------|
| **KdPageShell** | `frontend/src/components/KdPageShell.vue` | **所有页面最外层骨架**，自动处理导航栏 + 安全区 + 底栏 + 环境光 |
| KdCustomNavbar | `frontend/src/components/KdCustomNavbar.vue` | 自定义导航栏 |
| KdCustomTabbar | `frontend/src/components/KdCustomTabbar.vue` | 自定义底栏 |

**强制规则**：所有新页面必须以 `KdPageShell` 为最外层容器，禁止手写 `padding-top` 避让导航栏。

### 3.2 玻璃卡片（utilities.css）

| 类名 | 用途 |
|------|------|
| `.kd-glass-card` | 标准毛玻璃容器 |
| `.kd-glass-card--tint` | 带薄荷底色的玻璃 |
| `.kd-glass-card--padded` | 带 28rpx 内边距 |
| `.kd-glass-card--radius-md` | 中圆角变体 |

**强制规则**：所有卡片式容器优先使用 `.kd-glass-card`，禁止手写纯灰实底背景。

### 3.3 动画工具类

| 类名 | 效果 |
|------|------|
| `.kd-fade-in` | 淡入 + 上移 |
| `.kd-stagger-enter` | 错开入场（配合 `--stagger-index`） |
| `.kd-tab-fade-in` | Tab 切换淡入 |
| `.kd-press` | 按压缩放（`scale(0.97)`） |
| `.kd-press-subtle` | 按压降透明度 |
| `.kd-glass-card` | 脉冲骨架 |
| `.kd-spinner` / `.kd-spinner--small` / `.kd-spinner--large` | 旋转加载 |

### 3.4 KdSkeleton 骨架屏

配置驱动的骨架屏组件，支持 7 种块类型：`title` / `row` / `avatar` / `card` / `grid` / `banner` / `row-horizontal`。

**新建页面禁止手写骨架屏**，必须使用 `KdSkeleton` 组件。

## 4. 页面结构约束

```
<KdPageShell title="页面标题" nav-variant="solid">
  <!-- 页面内容 -->
  <view class="cashier-content">
    <!-- 各区块用 kd-glass-card 包裹 -->
    <view class="kd-glass-card kd-glass-card--padded">
      ...
    </view>
  </view>

  <!-- 吸底提交栏 -->
  <view class="cashier-submit-card">
    <button class="cashier-submit-btn">...</button>
  </view>
</KdPageShell>
```

**背景约束**：所有页面须使用 `--kd-bg-gradient` 作为背景。

## 5. 运营后台

运营后台使用 Element Plus，遵循其组件库规范。**不可**在运营后台使用 `--kd-*` Token（仅限小程序）。

## 6. JSON Token 源编辑指南

### 6.1 文件结构

```
frontend/src/styles/tokens/json/
├── global/color-space.json    — 色板 ramp（green 50-900, amber, red, blue…）
│                               + dimension(space/radius/font), font weight, duration, cubicBezier
├── alias/core.json            — 语义别名（引用 global 色板 → 生成 --kd-color-*）
├── comp/semantic.json         — 组件语义 token（引用 alias）
└── themes/{dark,coral,blue,purple,amber}.json  — 主题覆盖
```

### 6.2 引用路径注意

`alias/core.json` 使用**扁平** key（如 `alias.color.primary`），引用时路径必须匹配：

```json
// ✅ 正确 — 与扁平 key 匹配
"bg": { "value": "{alias.surface.value}" }
"shadow": { "value": "{alias.shadowMd.value}" }

// ❌ 错误 — 多了一层嵌套
"bg": { "value": "{alias.color.surface.value}" }
```

### 6.3 主题 JSON 格式

主题 JSON 只需覆盖与默认不同的属性，直接写值（非 `{ value }` 包装）:

```json
{
  "theme": "coral",
  "alias": {
    "color": {
      "primary": "#E8604C",
      "primaryRgb": "232, 96, 76"
    }
  }
}
```

### 6.4 构建后验证

```
# 验证无未解析引用
grep '{' frontend/src/styles/tokens/generated/variables.css

# 验证 --kd-color-primary 无漂移
grep -- '--kd-color-primary:' frontend/src/styles/tokens/generated/variables.css

# 验证 var() 语法正确（无裸 hex 拼接）
grep -rn 'var(--kd-[^)]*)[0-9a-f]\+' frontend/src/ --include='*.vue'
```

## 7. 主题系统

### 7.1 主题选择器

```css
/* ✅ 兼容 H5 和小程序 */
.kd-theme-dark { ... }

/* ❌ 小程序不生效（page 不是 Vue DOM） */
page.kd-theme-dark { ... }
```

所有全局 CSS class 选择器默认不加 `page` 前缀，直接用 `.kd-*`。

### 7.2 可用主题

| 主题名 | 标签 | 主色 |
|--------|------|------|
| `green` | 希望绿 | `#00B341`（默认） |
| `coral` | 珊瑚 | `#E8604C` |
| `blue` | 海蓝 | `#2563EB` |
| `purple` | 紫色 | `#7C3AED` |
| `amber` | 琥珀 | `#D97706` |
| `dark` | 暗色 | `#2ECC71` |

### 7.3 dark.json 必须包含所有 `*Rgb` 通道

新增颜色 token 时成对定义 `{name}Rgb`。dark.json 必须覆盖所有 `*Rgb` 变量，否则暗色模式下 `rgba(var(--kd-color-danger-rgb), .1)` 穿透回读 light 主题值。

## 8. 强制规则

1. **所有颜色使用 `var(--kd-*)`**，禁止硬编码 `#xxxxxx`
2. **页面以 `KdPageShell` 为骨架**，禁止手写 `padding-top` 避让导航栏
3. **卡片容器使用 `.kd-glass-card`**，禁止纯色实底背景
4. **选中态一律绿色体系**，非蓝色
5. **圆角使用 `var(--kd-radius-*)`**，禁止硬编码 rpx
6. **按钮圆角使用 `var(--kd-button-radius)`**（14rpx），药丸形用 `var(--kd-button-radius-pill)`
7. **页面使用 `--kd-bg-gradient` 背景**
8. **间距使用 `--kd-space-*`**，禁止硬编码 rpx
9. **字体大小 / 字重使用 `--kd-font-*` / `--kd-font-weight-*`**，禁止硬编码
10. **新建页面必须用 `KdSkeleton` 组件**，禁止手写骨架屏

## 9. RGB 通道使用规范

当需要 `rgba()` 透明度时，引用通道 token 而非硬编码 RGB 值：

```css
/* ✅ 正确 */
background: rgba(var(--kd-color-primary-rgb), 0.08);

/* ❌ 错误 — 硬编码 RGB 通道值 */
background: rgba(0, 179, 65, 0.08);
```

**预定义通道 token**：

| Token | RGB 值 |
|-------|--------|
| `--kd-color-primary-rgb` | `0, 179, 65` |
| `--kd-color-accent-rgb` | `217, 119, 6` |
| `--kd-color-danger-rgb` | `220, 38, 38` |
| `--kd-color-info-rgb` | `37, 99, 235` |
| `--kd-color-warning-rgb` | `245, 158, 11` |

## 10. 自检清单（交付前）

- [ ] 所有颜色使用 `var(--kd-*)`，无硬编码 `#xxxxxx`
- [ ] 页面以 `KdPageShell` 为骨架
- [ ] 卡片容器使用 `.kd-glass-card` 而非纯色背景
- [ ] 选中态一律绿色体系，非蓝色
- [ ] 圆角使用 `var(--kd-radius-*)`
- [ ] 页面使用 `--kd-bg-gradient` 背景
- [ ] 卡片的 `.kd-glass-card` 容器使用 `--padded` modifier 或自定义 padding
- [ ] 各页面 block 组件间距一致（`margin-bottom: 24rpx` 模式）
- [ ] 按钮圆角引用 `var(--kd-button-radius)` / `var(--kd-button-radius-pill)`
- [ ] 使用 `rgba()` 时通过 `--kd-*-rgb` 通道 token
- [ ] 无 `console.log` / 调试代码遗留
- [ ] 修改后 `pnpm run build:mp-weixin` 或 `pnpm run type-check` 通过

---

## 经验汇总

### 10.1 品牌色双源不同步

JSON alias 引用了 `green.500`（`#2ECC71`）但 tokens.css 手写值为 `#059669`（`green.600`）。修正后所有 alias 引用 `green.700`（`#00B341`），tokens.css 由构建脚本生成，消除双源。

**预防**：`build:tokens` 后执行 diff 确认关键色值一致；品牌色变更时同步更新 JSON global ramp + alias 映射。

### 10.2 `toKebab` 数字边界

`font2xl` → `font-2-xl`（多一个连字符）。修复：只保留 `letter→digit` 边界的连字符插入，去掉 `digit→letter`。

**预防**：`toKebab` 单元测试覆盖 `font2xl` 等组合 case。

### 10.3 批量替换后 `var()` 拼接裸 hex

agent 替换时 `#1f0` 尾随数字直接拼接：`var(--kd-surface)1f0`（CSS 语法错误）。

**检测**：
```bash
grep -rn 'var(--kd-[^)]*)[0-9a-f]\+' --include='*.vue' frontend/src/
```

### 10.4 旧品牌绿隐藏于 `rgba()`

`#2ECC71` 替换了，但 `rgba(46, 204, 113, 0.15)` 未被命中。

**检测**：品牌色替换必须同时搜索 hex + rgb 通道 + rgba 三种形式。

### 10.5 Tabbar 图标无法跟随主题

PNG 图标在深色/浅色切换时颜色不变。使用 `<text>` Unicode 字符替代，自动继承 `color`。

### 10.6 主题 JSON 缺失 `*Rgb`

dark.json 未定义 `dangerRgb` / `infoRgb` → 暗色模式 `rgba(var(--kd-color-danger-rgb), .1)` 穿透回读 light 值。

**预防**：新增颜色 token 时成对定义 `{name}Rgb`；新主题 JSON 与默认 diff 确保 `*Rgb` 已覆盖。

### 10.7 按钮 border-radius 标准化

代码库中按钮圆角存在 8 种以上不同值。统一：标准按钮 `var(--kd-button-radius)`（14rpx），药丸形 `var(--kd-button-radius-pill)`（999rpx）。首页 banner 按钮作为特例豁免药丸形。

### 10.8 运营后台不可使用 `--kd-*` token

运营后台使用 Element Plus 组件库，`--kd-*` 仅限小程序前端。

---

## JSON 源编辑示例

### 新增一个颜色 token

1. `global/color-space.json` 的 ramp 中添加色值
2. `alias/core.json` 中添加语义映射
3. `alias/core.json` 中添加 `{name}Rgb` 通道
4. 各 `themes/{name}.json` 中添加对应覆盖
5. `pnpm run build:tokens` 生成
6. 验证 `grep '{' variables.css` 无未解析引用

### 引用语法

```json
// 引用 global ramp
"primary": { "value": "{global.color.brand.green.700.value}" }

// 引用 alias 中的语义值
"bgPrimary": { "value": "{alias.color.primary.value}" }

// 直接值（不使用 value 包装的路径）
"disabledOpacity": { "value": "0.5" }
```

**注意**：alias JSON 使用**扁平** key（`alias.surface` 而非 `alias.color.surface`），comp JSON 引用时必须使用正确的扁平路径。