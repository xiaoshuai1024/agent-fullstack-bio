<!--
description: 微信小程序/uni-app 前端交付前必须零控制台报错、无 WXSS 编译失败
globs: frontend/**
alwaysApply: false
-->

# 微信小程序交付质量（用户强约束）

用户要求：**功能交付后，用微信开发者工具打开工程时，Console 不得出现因本次改动引入的红色报错**；亦不得出现 **WXSS / WXML 编译错误**。禁止「功能看似完成、工具里一片红」再交给用户。

## Agent 在收尾前必须做到

1. **构建门禁**：凡改动 `frontend/` 下可能影响小程序的代码（`.vue` 样式、模板、`pages.json`、`manifest`、静态资源路径等），在宣称完成前在仓库内执行
   `cd frontend && pnpm run build:mp-weixin`
   并确认 **命令成功退出**（编译失败 = 未完成）。

2. **WXSS 能力子集**：微信小程序 WXSS 与完整 CSS 不等价。禁止依赖 **通用选择器 `*`**、以及文档未列明的选择器/属性；复杂渐变、伪元素若在真机或工具中报错，应改为 MP 兼容写法或简化（参见已修复的 `KdPageShell` 用包裹层替代 `> *`）。

3. **人工验证说明**：自动化无法替代开发者工具 Console。Agent 若无法在本环境打开 IDE，须在回复中明确列出 **已执行的构建命令与结果**，并提醒合并前由作者在开发者工具中 **再扫一眼 Console + 问题面板**；若 Agent 能执行构建，则不得以「仅单测通过」作为小程序侧完成的唯一依据。

4. **与 `verification-before-completion` 一致**：凡对外声称「已修好 / 已完成」小程序相关项，须具备 **构建成功** 的证据；否则只描述为「已改代码，待你在本地 build + 真机/模拟器确认」。

---

## 经验：pages.json style 中禁止配置 enableShareAppMessage/enableShareTimeline（2026-05-23）

### 场景
启动微信小程序开发者工具时 Console 报错：
```
pages/circle/post-detail: invalid page.json ["enableShareAppMessage"]
pages/goods/detail: invalid page.json ["enableShareAppMessage"]、page.json ["enableShareTimeline"]
```

### 根因
微信小程序中 `enableShareAppMessage` 和 `enableShareTimeline` 是页面生命周期配置，**不属于 `pages.json` 中每个 page 的 `style` 属性**。它们在 uni-app 中应通过 Vue 页面的 `onShareAppMessage` / `onShareTimeline` 生命周期钩子实现（从 `@dcloudio/uni-app` 导入）。

### 修复
移除 `pages.json` 中 `style` 下的这两个字段：
```diff
 {
   "path": "post-detail",
   "style": {
-    "navigationBarTitleText": "动态详情",
-    "enableShareAppMessage": true
+    "navigationBarTitleText": "动态详情"
   }
 }
```

兼容处理：`@dcloudio/uni-app` 的 `onShareAppMessage(() => {})` 写法同时兼容 h5 和 mp-weixin，无需条件编译。

### 预防
- 在 `pages.json` 中搜索 `enableShare` 相关配置，只应在 `globalStyle` 或页面 `style` 中配置微信小程序**原生支持**的字段
- 分享功能统一用 `@dcloudio/uni-app` 生命周期钩子实现

---

## 经验：小程序 CSS 兼容性 — 禁止 clip-path/inset

### 场景
用纯 CSS 绘制 Tabbar 图标（`clip-path`、`inset`、`::before/::after` 绝对定位），运行后图标全部堆叠在左上角。

### 根因
微信小程序 WebView 不支持 `clip-path` 和 `inset` 属性，`::before`/`::after` 伪元素在部分情况下定位异常。

### 解决方案
- 图标统一用 `<text>` 字符（⌂⊞✉◎）或 PNG/SVG 文件
- 主题变色场景：字符图标自动继承 CSS `color`，无需额外处理
- 禁用 CSS `clip-path: polygon(...)`（小程序不支持）
- 禁用 `inset` 简写（用 `top/right/bottom/left` 代替）

### 预防
- Tabbar/按钮等图标优先考虑 `<text>` 字符或 PNG
- 需要主题跟随颜色时 → `<text>` 字符（`color` 继承）
- 不需要主题跟随 → PNG/SVG
- 禁止使用 `clip-path`、`inset` 等 ES2022+ CSS 属性

---

## 经验：分包页面 pages.json 中 enableShareAppMessage/enableShareTimeline 无效

### 场景
编译后控制台出现 warning：
```
enableShareAppMessage is not a known config for this page
enableShareTimeline is not a known config for this page
```
涉及 `pages/circle/post-detail` 和 `pages/goods/detail`。

### 根因
`enableShareAppMessage` 和 `enableShareTimeline` 仅在 **主包 pages** 的 `globalStyle` 或主包页面 `style` 中有效；**分包（subpackage）页面**的 `style` 配置中写这两个字段会被微信小程序框架忽略并报 warning。

### 解决方案
1. 从 `src/pages.json` 分包页面的 `style` 中移除 `enableShareAppMessage` 和 `enableShareTimeline`
2. 在页面组件中用 Vue 生命周期钩子实现分享：

```typescript
import { onShareAppMessage, onShareTimeline } from "@dcloudio/uni-app";

onShareAppMessage(() => ({
  title: "分享标题",
  path: "/pages/xxx/detail?id=...",
}));

onShareTimeline(() => ({
  title: "分享标题",
}));
```

### 预防
1. `enableShareAppMessage` / `enableShareTimeline` 只能放在主包 `pages` 数组的页面 `style` 中，禁止放在 `subPackages` 内
2. 分享功能统一用 `onShareAppMessage` / `onShareTimeline` 生命周期钩子（兼容 H5 和小程序）
3. 修改 pages.json 后运行编译检查 warning

---

## 经验：新建页面必须注册路由

### 场景
新建 uni-app `.vue` 页面后，忘记在 `pages.json` 对应分包中注册路由，导致 `uni.navigateTo` 跳转失败（页面不存在错误）。

### 根因
uni-app 不走文件系统路由，所有页面路径必须在 `pages.json` 的 `pages` 或 `subPackages[].pages` 中显式声明。

### 解决方案
```bash
# 新建页面后立即检查
grep "新页面路径" src/pages.json
```

在对应分包中添加：
```json
{
  "path": "新页面名",
  "style": {
    "navigationBarTitleText": "页面标题"
  }
}
```

### 预防
1. 新建 `.vue` 页面后立即检查 `pages.json` 注册
2. 使用 `pnpm run build:mp-weixin` 验证编译通过（未注册页面在构建时不会报错，但运行时会 404）
3. Agent 创建新页面的 prompt 中必须包含「在 pages.json 中注册路由」步骤

---

## 经验：uni-app 组件未找到错误的排查

WeChat devtools 报 "Component is not found in path" 时：

1. 检查组件文件是否存在于 `src/components/` 对应路径
2. uni-app 的 Easycom 自动注册（`@dcloudio/vite-plugin-uni`）无需手动 import
3. 大概率是 devtools 缓存/构建产物问题 → `pnpm run build:mp-weixin` 重新构建
4. 若仍报错 → "工具" → "清除缓存" → "全部清除" + 重新导入 dist 目录

---

## 经验：核销二维码全链路修复 — canvas 渲染 + URL Scheme 编码 + 扫码提取（2026-05-28）

### 场景
联合套卡订单的核销码打开后二维码不展示；万能核销需要二维码支持微信扫一扫跳转核销页。

### 根因
三个独立问题叠加：

1. **QrCodeImage.vue canvas 离屏渲染**：canvas 被 CSS 设为 `position: fixed; left: -9999px; top: -9999px; opacity: 0`，微信小程序中不可见的 canvas 无法渲染内容，`uni.canvasToTempFilePath` 返回空。
2. **二维码内容为裸核销码**：`RedeemCodeDisplay.vue` 把裸 `redeemCode` 传给 `QrCodeImage`，二维码被微信扫一扫后只得到字符串，无法跳转到小程序核销页。
3. **扫码结果未从 URL Scheme 提取裸码**：`verify.vue` 的 `handleScannedCode` 收到 `uni.scanCode` 返回的完整 URL Scheme 字符串后，直接传给 `loadPreview()`，后端无法识别。

### 解决方案

**修复 1 — QrCodeImage.vue**：
```diff
- .qr-canvas {
-   position: fixed;
-   left: -9999px;
-   top: -9999px;
-   opacity: 0;
- }
+ .qr-canvas { display: block; }
```
- 移除离屏 CSS，canvas 改为内联可见渲染
- 绘制完成并转换成 image 后才隐藏 canvas（`showCanvas = false`）
- 传入组件上下文：`uni.createCanvasContext(canvasId, instance?.proxy)`
- 包裹 `uni.nextTick()` 确保 canvas 已渲染到 DOM

**修复 2 — RedeemCodeDisplay.vue**：
- 添加 watcher 监听 `currentInstance.redeemCode` 变化
- 调用 `jcApi.getQrContent(code)` 获取微信 URL Scheme
- 将 `qrUrlScheme` 传给 `QrCodeImage` 而非裸 code

```typescript
watch(() => currentInstance.value?.redeemCode, async (code) => {
  if (!code) { qrUrlScheme.value = ""; return; }
  try {
    const res = await jcApi.getQrContent(code);
    qrUrlScheme.value = res.qrContent;
  } catch {
    qrUrlScheme.value = code; // fallback
  }
}, { immediate: true });
```

**修复 3 — verify.vue handleScannedCode**：
- 收到扫码结果后先用 `parsePlatformScanPayload(scanned)` 从 URL Scheme 提取裸核销码
- 用提取后的 `bareCode` 调用 `loadPreview()`

```typescript
const scanPayload = parsePlatformScanPayload(scanned);
const bareCode = scanPayload?.code || scanned;
state.code = bareCode;
await loadPreview(bareCode);
```

### 预防
1. **canvas 可见性**：小程序中使用 canvas 绘图时，canvas 必须可见且在视口内，禁止使用 `position: fixed + left: -9999px` 隐藏；应保持可见绘制，完成后再隐藏
2. **canvas 上下文**：uni-app 组件中调用 `uni.createCanvasContext()` 和 `uni.canvasToTempFilePath()` 必须传入 `getCurrentInstance()?.proxy` 作为第二参数
3. **nextTick**：canvas 绘制操作须包裹在 `uni.nextTick()` 中，确保 DOM 已渲染
4. **二维码内容**：需被微信扫一扫识别并跳转小程序的二维码，内容必须是 `weixin://dl/business/` 格式的 URL Scheme，而非裸数据
5. **扫码结果处理**：`uni.scanCode` 的返回值可能是 URL Scheme，消费者函数须先解析提取裸参数再使用

---

## 经验：圈子管理分包拆分减小小程序体积

### 场景
微信小程序构建时 `pages/circle/` 分包达 **1,148 KB**，接近单分包 2 MB 限制。

### 根因
圈子有 80+ 页面文件（含管理后台），全部集中在 `pages/circle/` 一个分包中。

### 解决方案
将 21 个圈子管理页面（`circle-merchant-*`、`circle-cross-placement-audit`、`circle-benefit-placement-list`、`chamber-sub-applications-owner`）从 `pages/circle/` 移到新的 `pages/circle-manage/` 分包。

```bash
# 移动文件
mkdir -p src/pages/circle-manage
mv src/pages/circle/circle-merchant-*.vue src/pages/circle-manage/
mv src/pages/circle/chamber-sub-applications-owner.vue src/pages/circle-manage/
mv src/pages/circle/circle-cross-placement-audit.vue src/pages/circle-manage/
mv src/pages/circle/circle-benefit-placement-list.vue src/pages/circle-manage/
```

```json
// pages.json 新增分包
{
  "root": "pages/circle-manage",
  "pages": [ /* 18 个管理页配置 */ ]
}
```

更新所有 `navigateTo` 路径：
```bash
sed -i '' 's|pages/circle/circle-merchant-|pages/circle-manage/circle-merchant-|g' src/**/*.{vue,ts}
```

结果：`pages/circle` **1,148 KB → 978 KB**（-15%），新增 `pages/circle-manage` **198 KB**

### 预防
- 新增圈子页面时区分「核心功能」和「管理后台」：核心放 `pages/circle/`，管理放 `pages/circle-manage/`
- 单分包超过 1 MB 时考虑进一步拆分

---

## 经验：微信第三方平台代注册小程序 API 已下线

### 场景
运营后台「SaaS → 代开小程序管理」中的「代注册」功能，调用微信开放平台 `fastregisterweapp` API 为租户快速注册企业小程序。

### 根因
微信已下线第三方平台快速注册企业小程序能力（`fastregisterweapp` API）。调用后返回错误或不可用。`MiniAppProxyOpenService.registerMiniApp()` 及对应的前端对话框（`regDlgVisible`、`submitRegister`、`pollRegisterStatus`）已无实际用途。

### 解决方案
替代流程：**租户自主注册**小程序后，通过运营后台「授权」按钮走扫码授权流程绑定到第三方平台。

代码层面（暂保留不删）：
- `MiniAppProxyOpenService`：`registerMiniApp()` / `queryRegisterStatus()` / `searchRegisterStatus()` 方法保留但不再调用
- 前端 `DelegatedMiniappManageView.vue`：代注册按钮（`v-if="row.delegateStatus !== 'registered'"`）和对话框仍存在，但实际无法使用
- 测试用例中「全新注册」相关用例已删除

### 预防
- 不再依赖 `fastregisterweapp` API，不投入时间修复相关错误
- 新租户接入流程改为：自主注册 → 扫码授权 → 配置推送 → 上线
- 若微信未来重新开放此能力，代码和测试用例可从 git 历史恢复

---

## 经验：微信支付 V3「商家转账到零钱」API 路径与字段正确性

### 场景
达人提现走 `WechatPayoutChannel` 调微信 V3 商家转账接口，生产调用出现 404（路径不存在）或 PARAM_ERROR。分账 `WechatSplitService` 调 `/v3/profitsharing/orders` 报缺字段。

### 根因（逐字段对照官方文档后发现的 3 个错误）
1. **路径单复数错误**：普通商户转账路径是 `/v3/fund-app/mch-transfer/transfer-bills`（**复数 bills**），代码误写 `transfer-bill`（单数）→ 404。partner 路径 `partner/transfer-bills` 本身是对的，但普通商户路径漏了 `s`。
2. **`user_name` 加密阈值错误**：官方要求转账金额 **≥2000 元（200000 分）**才必须传加密后的 `user_name`，代码误写 `200_00`（=20000 分=200 元）。
3. **分账缺必填字段 `appid`**：`/v3/profitsharing/orders`（请求分账）官方必填 `appid`，代码两个分账请求体都漏了（但 `/orders/unfreeze` 完结分账和 `/return-orders` 回退**不需要** appid）。

### 解决方案
```java
// WechatPayoutChannel — 路径改复数
private static final String TRANSFER_BILL_PATH = "/v3/fund-app/mch-transfer/transfer-bills"; // 不是 transfer-bill

// user_name 阈值：200_00 → 200_000（2000元）
if (name != null && !name.isBlank() && request.amountFen() >= 200_000) {
    body.put("user_name", encryptUserName(name));
}

// WechatSplitService — 分账请求体补 appid（两个分账方法都要）
body.put("appid", resolveSpAppId());  // 必须传
body.put("sub_mchid", subMchId);
body.put("transaction_id", transactionId);
body.put("out_order_no", ...);
body.put("receivers", receiverList);
```

**生产只读验证法（零转账风险，对接后必做）**：
用服务商凭证 GET 查询一个**不存在的转账单号**，根据返回码判断：
- `404 NOT_FOUND`（记录不存在）→ ✅ 产品已开通、签名通过、路径正确
- `当前商户号未开通该产品`类 → ❌ 产品未开通
- `SIGN_ERROR` → ⚠️ 私钥/证书序列号不匹配
- `PARAM_ERROR`（单号格式）→ ✅ 已到达参数校验层（产品已开通）

脚本：`scripts/verify/wechat-transfer-check.sh`，在生产服务器执行。注意 3 个坑：
1. `tenant_wechat_profile.mch_private_key_cipher` 以**字面 `\n`** 存储，需 `sed 's/\\n/\n/g'` 转真实换行 openssl 才能解析
2. `out_bill_no` **只能数字+字母**（不含下划线），用 `KDVERIFY$(date +%s)`
3. 签名串格式：`GET\n{path}\n{ts}\n{nonce}\n\n`（GET body 为空，末尾两个 `\n`）

### 关于出资账户（fund_source）
- 微信 V3「商家转账到零钱」请求体**没有 `fund_source` 参数**，出资账户由平台自动按"运营账户（经营账户）优先，未开通则基本账户"决定。
- 代码层无法指定出资账户；资金在哪个账户属于微信商户后台配置（经营账户自动划拨规则）。
- 达人提现的资金从**服务商号的运营账户**出，转入达人微信零钱。

### 预防
- 对接任何微信 V3 API 前，逐字段对照 [官方文档](https://pay.weixin.qq.com/doc/v3/merchant/4012716434)，不能凭记忆写路径/阈值/字段名
- 单复数路径错误（`transfer-bill` vs `transfer-bills`）极易发生，partner 路径对的但普通商户路径漏 `s` 是典型坑
- 对接完成后必须用「只读 GET 验证法」在生产实测产品是否开通，不要等真实提现才发现 404

---

## 经验：服务商 JSAPI 下单 APPID_MCHID_NOT_MATCH（特约商户未配置服务商AppID）

### 场景
特约商户（sub_mchid）已进件签约、绑定了小程序 AppID，服务商 JSAPI 下单（partnerpayments.jsapi）发出四要素 `sp_appid / sp_mchid / sub_appid / sub_mchid`，微信返回 `400 APPID_MCHID_NOT_MATCH`。本场景：用户在**服务商自己的小程序**（908b）里付款，即「服务商AppID代收」模式，`sub_appid = sp_appid`。

### 根因
特约商户后台看到的「小程序appid」只是进件时填的经营场景 AppID（展示字段），**不是**「服务商AppID代收款授权」。partner JSAPI 校验的是 `(sub_appid, sub_mchid)` 配对——特约商户必须在微信商户平台**单独完成「配置服务商AppID」授权**，否则 sp_appid 不能替它收款。

### 解决方案（微信侧，不用改代码）
登录**服务商账号** → 微信支付商户平台：
```
合作伙伴功能 → 开发参数配置 → 找到子商户号 → 点「开发配置」→ 特约商户APPID配置 → 添加 sp_appid
```
配置后可能需 AppID 管理员在公众平台（mp.weixin.qq.com）确认，或特约商户在「产品中心 → AppID账号管理 → 服务商为我关联的AppID账号」确认。每个特约商户最多 5 个 AppID。

官方文档：
- [管理商户号绑定的APPID账号_通用规则（服务商）](https://pay.weixin.qq.com/doc/v3/partner/4016329059)
- [sub_appid 使用说明（V2服务商）](https://pay.weixin.qq.com/doc/v2/partner/4011981636.md) — 「哪个小程序拉起支付就配哪个 sub_appid」

### 预防
- 排查 `APPID_MCHID_NOT_MATCH` 时，先区分是 `(sp_appid, sp_mchid)` 还是 `(sub_appid, sub_mchid)` 配对失败——服务商自有小程序代收场景两者 appid 相同
- 特约商户「签约完成」≠「AppID授权完成」，是两步独立操作；绑定已有子商户（EXISTING）后必须人工去微信后台配 AppID
- 微信没有公开的「查特约商户 AppID 绑定」API（`GET /v3/apply4sub/sub_merchants/{id}` 返回 404），绑定状态只能人工在后台确认

---

## 经验：特约商户绑定 shop_id 落库为 NULL（populateApply 漏写字段）

### 场景
运营后台「绑定已有子商户」（EXISTING）提交后，`sub_merchant_apply.shop_id` 落库为 NULL。后果：`activateBinding` 拿到 `targetId=null` 跳过 → `shop_sub_merchant` 无 ACTIVE 记录 → 下单 `resolveShopSubMchIdByOrder` 找不到特约商户号 → 报「该店铺尚未绑定微信特约商户号」。

### 根因
`SubMerchantOnboardingService.populateApply()` 完全没有写 `shopId / deliveryCenterId / bindTargetType`；`ApplySubMerchantRequest` record 根本没这三个字段。前端发了但后端 DTO 不接收，落库恒为 NULL。`bind_target_type` 显示 SHOP 是 DB 列默认值，不是代码写入。

### 解决方案
1. `ApplySubMerchantRequest` record 增加 `bindTargetType / shopId / deliveryCenterId` 三字段（加在 `subMchId` 之后，同步更新兼容构造器的 `this(...)` 参数顺序）
2. `populateApply` 补：
```java
a.setBindTargetType(nz(req.bindTargetType(), "SHOP"));
a.setShopId(req.shopId());
a.setDeliveryCenterId(req.deliveryCenterId());
```
3. 前端 EXISTING 表单加店铺选择器 + `shopId` 必填校验（formRules 按 `bindTargetType` 动态加 `shopId` / `deliveryCenterId` required）

### 预防
- 加新字段到 record 后，**必须**在 `populateApply` / upsert SQL / loadXxx 三处同步；只改 DTO 不改写入逻辑是隐蔽 bug
- 绑定类表单的「关联目标 ID」必须前端必填校验，不能依赖后端 NOT NULL（很多列有 DB 默认值或允许 NULL，不会报错但数据是脏的）
- 排查「绑定了但下单找不到」类问题，先查 `shop_sub_merchant WHERE shop_id=? AND status='ACTIVE'`（下单真正读的表），不是 `sub_merchant_apply`

---

## 经验：微信 applyment_id 大整数精度丢失（SDK Map 反序列化为 Double）

### 场景
`WechatSubMerchantApiImpl.submitApplication` 用 `client.execute(httpRequest, Map.class)` 解析微信响应，`applyment_id`（16 位大整数）落库为科学记数法 `2.000002801673519E15`，导致后续 `queryApplication(applymentId)` 调微信查询接口失败。

### 根因
SDK 反序列化 `Map<String,Object>` 时，大整数被解析为 `Double`，`String.valueOf(Double)` 输出科学记数法。16 位以内的整数虽能被 double 精确表示，但 `Double.toString` 仍输出科学记数法，且 17 位以上会丢精度。

### 解决方案
```java
private static String bigIntToString(Object raw) {
    if (raw == null) return null;
    if (raw instanceof Number n) {
        if (n instanceof Double || n instanceof Float) {
            return java.math.BigDecimal.valueOf(n.doubleValue()).toBigInteger().toString();
        }
        return n.toString();
    }
    return String.valueOf(raw);
}
```
解析微信返回的 ID 字段时统一走 `bigIntToString`，不要直接 `String.valueOf`。

### 预防
- 任何用 `Map.class` / `Object.class` 反序列化微信/三方 API 的响应，涉及 ID/金额等大数字段，必须用 `BigDecimal` 还原，不能用 `String.valueOf`
- 微信 V3 的 `applyment_id`、`transaction_id`、商户号等都是长数字串，按字符串处理最安全
