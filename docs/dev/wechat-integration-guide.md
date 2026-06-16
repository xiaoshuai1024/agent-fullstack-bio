# 康豆微信集成开发指南

> 本文档是康豆全栈项目的微信生态集成知识库，涵盖登录、支付、第三方平台代开发、提现、消息推送等全部微信能力的调用链、配置方式与常见踩坑。

---

## §1 本项目微信能力清单

| 微信能力 | 后端核心文件路径 | 核心方法名 | 微信 API 端点 | 前端调用方式 |
|---------|----------------|-----------|-------------|------------|
| 小程序登录（code2Session） | `backend/src/main/java/com/kangdou/tenant/auth/MiniAppAuthService.java`<br/>`DefaultWechatMiniProgramCodeExchange.java`<br/>`DefaultWechatMiniProgramPhoneNumberClient.java` | `login()`<br/>`openIdForCode()` | `GET https://api.weixin.qq.com/sns/jscode2session` | `frontend/src/api/auth.ts` — `getWechatLoginCode()`<br/>`frontend/src/auth/useLogin.ts` — `login()` |
| 手机号获取（getuserphonenumber） | `backend/src/main/java/com/kangdou/tenant/auth/MiniAppAuthService.java`<br/>`DefaultWechatMiniProgramPhoneNumberClient.java` | `bindPhoneWithWechatCode()`<br/>`purePhoneNumberForCode()` | `POST https://api.weixin.qq.com/wxa/business/getuserphonenumber` | `<button open-type="getPhoneNumber">` → code → 后端解密 |
| JSAPI 支付（直连 + 服务商双模式） | `backend/src/main/java/com/kangdou/tenant/pay/WechatJsapiTenantPayService.java`<br/>`WechatJsapiPayEligibility.java` | `prepayJsapi()`<br/>`resolvePayMode()` | 直连: V3 `payments.jsapi`<br/>服务商: V3 `partnerpayments.jsapi` | `frontend/src/composables/useOrderPay.ts`<br/>`frontend/src/utils/payTenantOrder.ts` |
| 退款（V3） | `backend/src/main/java/com/kangdou/tenant/pay/WechatRefundService.java`<br/>`WechatJsapiTenantPayService.java` | `submitWechatRefund()`<br/>`refundWechat()`<br/>`handleRefundNotify()` | V3 `RefundService.create()` | 运营后台审批触发 |
| 商家转账到零钱（提现） | `backend/src/main/java/com/kangdou/ops/trade/payout/WechatPayoutChannel.java`<br/>`PayoutChannelRouter.java` | `pay()`<br/>`resolveChannel()` | `POST https://api.mch.weixin.qq.com/v3/fund-app/mch-transfer/transfer-bill` | 运营后台/用户发起提现 |
| 订阅消息 | `backend/src/main/java/com/kangdou/notification/channel/WechatSubscribeAdapter.java` | `send()` | `POST https://api.weixin.qq.com/cgi-bin/message/subscribe/send` | 前端 `wx.requestSubscribeMessage()` |
| 公众号模板消息 | `backend/src/main/java/com/kangdou/notification/channel/OfficialAccountAdapter.java` | `send()` | `POST https://api.weixin.qq.com/cgi-bin/message/template/send` | 无需前端配合 |
| 第三方平台代开发（component_access_token 全链路） | `backend/src/main/java/com/kangdou/tenant/auth/WechatThirdPartyPlatformService.java`<br/>`WechatAuthCodeService.java`<br/>`AuthorizerTokenRefreshScheduler.java` | `getComponentAccessToken()`<br/>`buildAuthUrl()`<br/>`refreshAllAuthorizerTokens()` | `POST .../component/api_create_preauthcode`<br/>`POST .../component/api_query_auth`<br/>`POST .../component/api_get_authorizer_info` | 运营后台生成授权链接 |
| 小程序代注册（fastregisterweapp） | `backend/src/main/java/com/kangdou/ops/wechatproxy/MiniAppProxyOpenService.java` | `fastRegisterWeApp()` | `POST .../cgi-bin/account/fastregisterweapp` | 运营后台触发 |
| 代码模板管理 + 提审 + 发布 | `backend/src/main/java/com/kangdou/ops/wechatproxy/WechatCodeTemplateService.java` | `addToTemplate()`<br/>`syncTemplateList()`<br/>`commitCode()`<br/>`submitAudit()`<br/>`release()` | `/wxa/commit`<br/>`/wxa/submit_audit`<br/>`/wxa/release` | 运营后台触发 |
| 特约商户进件（电商收付通） | `backend/src/main/java/com/kangdou/merchantcenter/SubMerchantOnboardingService.java` | `applySubMerchant()` | `POST https://api.mch.weixin.qq.com/v3/ecommerce/applyments` | 运营后台触发 |
| 账单下载 | `WechatJsapiTenantPayService.java`（账单相关方法） | 对账单下载方法 | `/v3/bill/tradebill`<br/>`/v3/bill/fundflowbill` | 定时任务 / 运营后台 |
| URL Scheme 生成 | `WechatThirdPartyPlatformService.java` | 生成 URL Scheme 方法 | `POST https://api.weixin.qq.com/wxa/generatescheme` | H5 跳转小程序 |
| 服务商分账（V3 电商分账） | `backend/src/main/java/com/kangdou/ops/split/WechatSplitService.java` | `sendSplit()` / `unfrozenSplit()`<br/>`ensureReceiverAdded()` | `POST .../v3/profitsharing/orders`<br/>`POST .../v3/profitsharing/receivers/add` | 后端自动触发（订单完成/售后退款时） |

### 配置与凭证核心文件

| 文件路径 | 作用 |
|---------|------|
| `backend/src/main/java/com/kangdou/tenant/TenantWechatProfileService.java` | 租户微信配置 CRUD |
| `backend/src/main/java/com/kangdou/tenant/WechatMiniappCredentialsResolver.java` | AppId/AppSecret 解析（DB 优先 → 环境变量兜底） |

---

## §2 微信登录完整调用链

### 2.1 前端调用

| 文件 | 方法 | 说明 |
|------|------|------|
| `frontend/src/api/auth.ts` | `getWechatLoginCode()` | 调用 `uni.login()` / `wx.login()` 获取临时 code |
| `frontend/src/auth/useLogin.ts` | `login()` | 登录 composable，组装登录请求 |
| `frontend/src/auth/silentLogin.ts` | `silentLogin()` | 静默自动登录（页面加载时触发） |
| `frontend/src/auth/wechatMiniLogin.ts` | `runWechatMiniLogin()` | 微信小程序登录主流程 |

### 2.2 后端处理流程

```
wx.login() → code
  │
  ▼ POST /api/tenant-core/auth/wechat/login
  │
  MiniAppAuthService.login()
  │
  ├─► WechatMiniappCredentialsResolver (tenant_wechat_profile 或环境变量)
  │
  ├─► DefaultWechatMiniProgramCodeExchange.openIdForCode()
  │     │
  │     ▼ GET https://api.weixin.qq.com/sns/jscode2session
  │          ?appid=APPID&secret=SECRET&js_code=CODE&grant_type=authorization_code
  │     │
  │     └─► 返回 { openid, session_key, unionid? }
  │
  ├─► findOrCreateUser() → 根据 openId 查找或创建用户
  │
  ├─► finalizeLoginSession()
  │     │
  │     ▼ INSERT tenant_user_session
  │          (token, refresh_token, tenant_id, user_id, expire_at)
  │
  └─► 返回 { token, refreshToken }
```

### 2.3 AppId 解析优先级

`WechatMiniappCredentialsResolver.java` + `WechatCredentialSource` enum 的解析逻辑：

| 优先级 | 来源 | 说明 |
|--------|------|------|
| 1 | `tenant_wechat_profile` 表 | `mini_program_app_id` + `app_secret_cipher`（租户级，优先） |
| 2 | 环境变量 | `WECHAT_MINIAPP_APP_ID` + `WECHAT_MINIAPP_APP_SECRET`（全局兜底） |
| 3 | 都没有 | 抛出 `WECHAT_JSAPI_PAY_CONFIG_INCOMPLETE` 错误 |

### 2.4 手机号获取流程

```
前端 <button open-type="getPhoneNumber">  → 获取 phoneCode
  │
  ▼ POST /api/tenant-core/auth/phone/bind
  │
  MiniAppAuthService.bindPhoneWithWechatCode()
  │
  ├─► DefaultWechatMiniProgramPhoneNumberClient.purePhoneNumberForCode()
  │     │
  │     ├─► GET cgi-bin/token (获取 access_token)
  │     │     └─ 缓存: ConcurrentHashMap<String, TokenCacheEntry>
  │     │         key: appId, TTL: expires_in - 300s (提前5分钟过期)
  │     │
  │     ▼ POST https://api.weixin.qq.com/wxa/business/getuserphonenumber
  │          ?code=phoneCode
  │     │
  │     └─► 返回 purePhoneNumber（纯手机号，不含区号）
  │
  └─► 绑定手机号到用户记录
```

> **注意**：此处的 `access_token` 是小程序的 `client_credential` 类型，不是用户的 token。

### 2.5 Session 管理

| 项目 | 值 / 说明 |
|------|----------|
| Session TTL | 30 天 |
| Refresh Token TTL | 30 天 |
| Token 格式 | Base64 URL-safe，32 random bytes |
| 存储 | `tenant_user_session` 表 |
| Rate Limit | Redis `ratelimit:login:{tenantId}:{clientIp}`，20 次/分钟 |
| OpenID Cache | Redis `miniapp:code:openid:{appId}:{code}`，5 分钟（防止 code 重复使用） |

### 2.6 错误码处理

| errcode | 含义 | 本项目处理 |
|---------|------|-----------|
| 40029 | code 无效/过期 | "微信登录凭证失效，请重试" |
| 40163 | code 已被使用 | 同 40029 |
| 40125 | appSecret 错误 | "微信登录失败，请稍后重试" |
| 40013 | appid 无效 | "微信登录失败，请稍后重试" |
| 85079 | 手机号授权过期 | "手机号授权已失效，请重试" |

---

## §3 微信支付完整调用链

### 3.1 两种支付模式

| 模式 | 说明 | 凭证来源 |
|------|------|---------|
| **DIRECT** | 租户用自己的商户号 | `tenant_wechat_profile.mch_id` + 商户证书 |
| **SERVICE_PROVIDER** | 平台服务商号 + 租户子商户号 | `service_provider_credential` + `tenant_wechat_profile.sub_mch_id` |

决定逻辑：`WechatJsapiPayEligibility.resolvePayMode()` 读取 `tenant_wechat_profile.pay_mode` 字段。

### 3.2 支付流程

```
前端调用 prepay
  │
  ▼ POST /api/tenant/trade/orders/buy-now (或类似下单接口)
  │
  内部调用 WechatJsapiTenantPayService.prepayJsapi()
  │
  ├─► resolvePayMode()
  │     ├─► DIRECT → prepayJsapiDirect()
  │     │     使用 com.wechat.pay.java.service.payments.jsapi.*
  │     │
  │     └─► SERVICE_PROVIDER → prepayJsapiServiceProvider()
  │           使用 com.wechat.pay.java.service.partnerpayments.jsapi.*
  │
  └─► 返回 { paymentNo, appId, timeStamp, nonceStr, package, signType, paySign }
        │
        ▼
前端 wx.requestPayment({ provider:"wxpay", timeStamp, nonceStr, package, signType, paySign })
        │
        ▼
微信回调 → POST /api/public/wechat-pay/notify/{tenantId}
        │
  WechatPayNotifyController
        │
        ▼ WechatJsapiTenantPayService.handlePayNotify()
        │
        ├─► NotificationParser 验签 + 解析 Transaction
        │
        └─► TenantCoreService.finalizeWechatJsapiPaymentSuccess()
              └─► 更新订单状态、积分、库存等
```

### 3.3 退款流程

```
运营审批退款
  │
  ▼ WechatJsapiTenantPayService.refundWechat()
  │  或 WechatRefundService.submitWechatRefund()
  │
  ├─► RefundService.create() (WeChat V3 SDK)
  │
  ▼
微信回调 → POST /api/public/wechat-pay/refund-notify/{tenantId}
  │
  WechatRefundNotifyController
  │
  ▼ WechatRefundService.handleRefundNotify()
  │
  └─► processRefundSuccess(): 12步财务结算
        1. 更新退款状态
        2. 余额退回
        3. 分账回退
        4. 积分回退
        5. 优惠券回退
        6. ... (共12步)
```

### 3.4 SDK 信息

| 项目 | 说明 |
|------|------|
| 依赖 | `wechatpay-java` v0.2.15 (`com.github.wechatpay-apiv3`) |
| 证书管理 | `RSAAutoCertificateConfig` 自动下载平台证书 |
| 直连支付 | `JsapiServiceExtension` (`payments.jsapi`) |
| 服务商支付 | `JsapiServiceExtension` (`partnerpayments.jsapi`) |
| 退款 | `RefundService` |

### 3.5 凭证完整性检查

`WechatJsapiPayEligibility.tenantPayCredentialsComplete()` 检查以下 7 个字段：

1. `mch_id` — 商户号
2. `api_v3_key_cipher` — API V3 密钥
3. `cert_serial_no` — 证书序列号
4. `mch_private_key_cipher` — 商户私钥
5. `mini_program_app_id` — 小程序 AppId
6. `app_secret_cipher` — 小程序 AppSecret
7. `notify_url` — 回调通知地址

任一字段缺失 → 返回 `WECHAT_JSAPI_PAY_CONFIG_INCOMPLETE` (503)。

### 3.6 Mock 模式

| 配置项 | 说明 |
|--------|------|
| Profile | `mock-wechat` |
| 环境变量 | `KANGDOU_WECHAT_PAY_MOCK_ENABLED=true` |
| 配置文件 | `application-mock-wechat.yml` 提供假 WeChat profile |
| 行为 | 跳过真实微信调用，直接标记支付成功 |

### 3.7 前端支付调用

| 文件 | 方法 | 说明 |
|------|------|------|
| `frontend/src/composables/useOrderPay.ts` | `uni.requestPayment({ provider:"wxpay", ... })` | 支付 composables |
| `frontend/src/utils/payTenantOrder.ts` | `invokeWxRequestPayment()` | 支付 helper |
| `frontend/src/tenant/runtime.ts` | `isWechatJsapiPayLive()` | 判断是否真实支付环境 |

---

## §4 第三方平台代开发全链路

### 4.1 架构概览

```
微信服务器                    本项目后端                           运营后台
  │                            │                                  │
  │ component_verify_ticket    │                                  │
  │ (每10分钟推送) ──────────→ WechatThirdPartyMsgHandler       │
  │                            │  ↓ 存储 to DB                    │
  │                            │  wechat_third_party_platform     │
  │                            │                                  │
  │                            │ AuthorizerTokenRefreshScheduler   │
  │                            │ (每30分钟刷新 token)              │
  │                            │                                  │
  │                            │ ←─── 生成授权链接 ────────────── │
  │                            │ WechatAuthCodeService            │
  │                            │ .buildAuthUrl()                  │
  │                            │                                  │
  │  商家扫码授权 ─────────────→ WechatAuthCallbackController     │
  │                            │ .callback()                      │
  │                            │  ↓ handleAuthCallback()           │
  │                            │  ↓ api_query_auth + api_authorizer_info
  │                            │  ↓ INSERT wechat_authorizer       │
  │                            │  ↓ UPDATE tenant_wechat_profile   │
```

### 4.2 Token 管理链

| Token | 存储位置 | TTL | 刷新策略 | 代码位置 |
|-------|---------|-----|---------|---------|
| component_verify_ticket | `wechat_third_party_platform.component_verify_ticket` | ~10min | 微信每10分钟推送 | `WechatThirdPartyMsgHandler.java` |
| component_access_token | `wechat_third_party_platform.component_access_token` | 7200s (2h) | 超过 6900s 自动刷新 | `WechatThirdPartyPlatformService.java` |
| pre_auth_code | 临时生成 | 600s (10min) | 每次授权前重新生成 | `WechatAuthCodeService.java` |
| authorizer_access_token | `wechat_authorizer.authorizer_access_token` | ~7200s | 每30分钟调度刷新（提前30分钟） | `AuthorizerTokenRefreshScheduler.java` |
| authorizer_refresh_token | `wechat_authorizer.authorizer_refresh_token` | 长期有效 | 不刷新，用于刷新 authorizer_access_token | `WechatAuthCodeService.java` |

### 4.3 授权流程 API 调用顺序

```
步骤 1: 生成预授权码
  POST api.weixin.qq.com/cgi-bin/component/api_create_preauthcode
  └─► 返回 pre_auth_code

步骤 2: 构建授权 URL
  https://mp.weixin.qq.com/cgi-bin/componentloginpage
    ?component_appid=COMPONENT_APPID
    &pre_auth_code=PRE_AUTH_CODE
    &redirect_uri=REDIRECT_URI
    &auth_type=1
  └─► 运营后台展示给商家扫码

步骤 3: 商家扫码后回调
  GET /api/public/wechat-auth/callback/{tenantId}?auth_code=xxx
  └─► WechatAuthCallbackController.callback()

步骤 4: 使用 auth_code 换取授权信息
  POST api.weixin.qq.com/cgi-bin/component/api_query_auth
  └─► 返回 authorizer_access_token + authorizer_refresh_token

步骤 5: 获取授权方详情
  POST api.weixin.qq.com/cgi-bin/component/api_get_authorizer_info
  └─► 返回授权方昵称、头像、权限列表等
```

### 4.4 代码模板 → 发布流程

`WechatCodeTemplateService.java` 提供完整的代码管理能力：

```
1. addToTemplate()       → 上传代码为草稿
2. syncTemplateList()    → 同步模板库
3. commitCode()          → 提交代码（指定模板ID + ext_json）
4. submitAudit()         → 提交审核
5. getAuditStatus()      → 查询审核状态
6. release()             → 发布上线
7. commitAndSetExperience() → 提交并设为体验版
8. getExperienceQrCode()    → 获取体验版二维码
```

### 4.5 域名配置

- `/wxa/modify_domain` → 设置 request/upload/download 域名
- `/wxa/setwebviewdomain` → 设置 webview 域名
- Source: `WechatDomainConfigService.java`
- DB: `wechat_domain_config` 表

---

## §5 提现/转账

### 5.1 API 端点

```
POST https://api.mch.weixin.qq.com/v3/fund-app/mch-transfer/transfer-bill
```

### 5.2 模式

| 模式 | 说明 |
|------|------|
| **DIRECT** | 用租户自己的商户号 |
| **SERVICE_PROVIDER** | 用平台服务商号 + 租户 sub_mch_id |

### 5.3 调用链

```
AssetAndWithdrawService (提现领域服务)
  │
  ▼ PayoutChannelRouter.resolveChannel()
  │
  │ 路由优先级:
  │   租户偏好 > SERVICE_PROVIDER WECHAT > MOCK > DIRECT WECHAT > BANK
  │
  ▼ WechatPayoutChannel.pay()
  │
  ├─► POST /v3/fund-app/mch-transfer/transfer-bill
  │
  └─► 记录 payout_channel_log 表
```

### 5.4 约束

| 项目 | 值 |
|------|-----|
| 最低金额 | 0.30 元 |
| 开关配置 | `kangdou.wechat-payout.enabled` (默认 true) |
| API 基地址配置 | `kangdou.wechat-payout.api-base-url` |

### 5.5 配置文件

```yaml
# application.yml
kangdou:
  wechat-payout:
    enabled: ${KANGDOU_WECHAT_PAYOUT_ENABLED:true}
    api-base-url: ${KANGDOU_WECHAT_PAYOUT_API_BASE_URL:https://api.mch.weixin.qq.com/v3/fund-app/mch-transfer}
```

---

## §6 错误码速查表

### 6.1 微信官方 errcode

| errcode | 含义 | 本项目处理 | 代码位置 |
|---------|------|-----------|---------|
| 0 | 成功 | 正常处理 | 所有接口 |
| -1 | 微信系统繁忙 | "微信登录失败，请稍后重试" | `DefaultWechatMiniProgramCodeExchange` |
| 40001 | access_token 无效/过期 | 清缓存 + 自动重试一次 | `WechatSubscribeAdapter` |
| 40013 | appid 无效 | "微信登录失败" | `DefaultWechatMiniProgramCodeExchange` |
| 40029 | code 无效/过期 | "微信登录凭证失效，请重试" | `DefaultWechatMiniProgramCodeExchange`<br/>`DefaultWechatMiniProgramPhoneNumberClient` |
| 40125 | appSecret 错误 | "微信登录失败，请稍后重试" | `DefaultWechatMiniProgramCodeExchange` |
| 40163 | code 已被使用 | 同 40029 | `DefaultWechatMiniProgramCodeExchange` |
| 85079 | 手机号授权过期 | "手机号授权已失效，请重试" | `DefaultWechatMiniProgramPhoneNumberClient` |

### 6.2 本项目自定义错误码

| 错误码 | 含义 | HTTP Status |
|--------|------|-------------|
| `WECHAT_JSAPI_CONFIRM_BLOCKED` | JSAPI 支付确认被阻止 | 409 |
| `WECHAT_JSAPI_PAY_DISABLED` | JSAPI 支付未启用 | 400 |
| `WECHAT_JSAPI_PAY_CONFIG_INCOMPLETE` | 支付配置不完整（7个字段） | 503 |
| `WECHAT_THIRD_PARTY_TICKET_NOT_READY` | component_verify_ticket 未就绪 | 503 |
| `WECHAT_THIRD_PARTY_TOKEN_FAILED` | component_access_token 获取失败 | 502 |
| `WECHAT_PRE_AUTH_CODE_INVALID` | pre_auth_code 无效 | 400 |
| `WECHAT_AUTH_CODE_INVALID` | auth_code 无效 | 400 |
| `WECHAT_TEMPLATE_NOT_FOUND` | 代码模板不存在 | 404 |
| `WECHAT_TEMPLATE_AUDITING` | 模板审核中 | 400 |
| `WECHAT_DOMAIN_CONFIG_INVALID` | 域名配置无效 | 400 |
| `WECHAT_AUTHORIZER_NOT_FOUND` | 授权方不存在 | 404 |
| `WECHAT_AUTHORIZER_DEAUTHORIZED` | 授权方已取消授权 | 400 |
| `WECHAT_PROXY_REGISTER_FAILED` | 代注册失败 | 502 |

### 6.3 通用错误处理模式

本项目所有微信 API 调用（`wechatPost()` 方法）的统一错误处理模式：

```java
if (root.has("errcode") && root.get("errcode").asInt() != 0) {
    throw new AppException(ApiErrorCode.HTTP_BAD_GATEWAY,
        "微信 API 错误 [%d] %s".formatted(errCode, errMsg));
}
```

---

## §7 常见踩坑记录

### 7.1 登录相关

| 踩坑点 | 说明 |
|--------|------|
| **wx.login() code 有效期仅 5 分钟且一次性** | 重复使用返回 errcode 40163。前端获取 code 后须立即发送后端，不可缓存 |
| **session_key 会过期** | 解密用户数据前需确保 session_key 有效，过期需重新 wx.login() |
| **"微信用户" 昵称** | 微信隐私政策调整后，未授权用户昵称返回"微信用户"。本项目通过 `WechatMiniNicknamePolicy` 处理 |
| **手机号获取需 access_token** | 此处 access_token 是小程序的 `client_credential` 类型，不是用户的 token |

### 7.2 支付相关

| 踩坑点 | 说明 |
|--------|------|
| **V2/V3 API 不能混用** | 本项目统一使用 V3，SDK 为 `wechatpay-java`。切勿引入 V2 接口 |
| **直连 vs 服务商 SDK 不同** | 直连用 `payments.jsapi`，服务商用 `partnerpayments.jsapi`，两者是不同的 Maven 包路径 |
| **服务商模式下 appid** | 使用 `authorizer_appid`（即小程序的 appid），不是平台的 `component_appid` |
| **Mock 模式** | local profile 默认 mock 支付，`wechat-pay-mock` 和 `wechat-jsapi-pay` 配置项控制。合并前 `pnpm run build:mp-weixin` 禁用 mock |

### 7.3 第三方平台相关

| 踩坑点 | 说明 |
|--------|------|
| **component_verify_ticket 约10分钟推送一次** | 服务启动后需等待首次推送才能使用第三方平台功能。冷启动后最多等10分钟 |
| **pre_auth_code 有效期 600 秒** | 授权链接生成后需及时让商家扫码，超时需重新生成 |
| **authorizer_access_token 需要定期刷新** | 本项目 `AuthorizerTokenRefreshScheduler` 每30分钟检查一次，提前30分钟刷新 |
| **授权回调是异步的** | 商家扫码后微信才回调 `WechatAuthCallbackController`，不是同步返回 |

### 7.4 代注册相关

| 踩坑点 | 说明 |
|--------|------|
| **企业付款到零钱已废弃** | 本项目使用"商家转账到零钱"接口（`/v3/fund-app/mch-transfer/transfer-bill`），不是旧版企业付款 |
| **域名配置需调两个接口** | `/wxa/modify_domain`（业务域名）和 `/wxa/setwebviewdomain`（webview 域名），缺一不可 |
| **代码模板提审是异步流程** | `submitAudit()` 后需轮询 `getAuditStatus()`，不能假设同步返回结果 |

### 7.5 特约商户进件

| 踩坑点 | 说明 |
|--------|------|
| **异步流程** | `applySubMerchant()` 创建 PENDING 记录 → 微信回调更新为 FINISHED/REJECTED |
| **回调地址** | 需要在微信服务商平台提前配置进件回调通知 URL |

### 7.6 消息相关

| 踩坑点 | 说明 |
|--------|------|
| **模板消息已废弃** | 小程序使用订阅消息，公众号使用模板消息。两者是不同的接口和机制 |
| **订阅消息需用户主动触发** | 前端需调 `wx.requestSubscribeMessage()` 让用户勾选同意后，后端才能发送 |
| **access_token 缓存** | 本项目使用 Redis 分布式锁防止惊群（thundering herd），避免大量请求同时刷新 token |

### 7.7 配置相关

| 踩坑点 | 说明 |
|--------|------|
| **tenant_wechat_profile 表** | 租户级配置，支持加密存储 appSecret、apiV3Key、privateKey。每个租户独立配置 |
| **WechatFieldMasker** | 运营后台显示脱敏值（如 `***appid`），保存时检测脱敏值不覆盖真实值 |
| **环境变量 vs DB** | AppId 优先读 DB（`tenant_wechat_profile`），环境变量作为兜底。正式环境必须配置 DB |

---

## 附录：数据库表速查

| 表名 | 作用 | 租户级 |
|------|------|--------|
| `tenant_wechat_profile` | 租户微信配置（appId, mchId, 证书等） | 是 |
| `wechat_third_party_platform` | 第三方平台配置 + component token | 否（平台级） |
| `wechat_authorizer` | 授权方信息 + authorizer token | 是 |
| `wechat_code_template` | 代码模板库 | 否（平台级） |
| `wechat_domain_config` | 域名配置 | 是 |
| `wechat_miniapp_release` | 小程序发布记录 | 是 |
| `service_provider_credential` | 服务商支付凭证 | 否（平台级） |
| `msg_wechat_subscription` | 用户订阅消息状态 | 是 |
| `trade_payment.wechat_transaction_id` | 微信支付单号 | 是 |
| `trade_refund.wechat_refund_id` | 微信退款单号 | 是 |

---

## §8 经验教训

### 经验：禁止用 curl/ProcessBuilder 调用微信 API — 改用 java.net.http.HttpClient（2026-06-13）

#### 场景
`WechatAuthCodeService.wechatPost()` 原实现通过 `ProcessBuilder` 启动 `curl` 子进程调用微信第三方平台 API（component token / 授权方 token 等），把响应写入 `/tmp/wechat_resp_*.json` 临时文件再读回。代码注释理由："Java HTTP 客户端与微信 CDN 兼容性不佳"。

#### 根因
该"CDN 兼容性差"是**未经证实的假设**——实际 `java.net.http.HttpClient` 调用微信 API 完全正常。用 curl 子进程方式存在多重问题：

- 每次调用 fork 子进程，高并发下资源开销大、无法复用连接
- 临时文件 `/tmp/wechat_resp_*.json` 在异常退出时残留，长期堆积
- 响应编码由 curl 默认行为决定，中文可能乱码
- 无法设置 connect/read 超时与重试策略
- 难以单元测试 / mock

#### 解决方案
`WechatAuthCodeService` 构造函数注入 `HttpClient httpClient = HttpClient.newHttpClient()`，`wechatPost()` 改为：

```java
HttpRequest request = HttpRequest.newBuilder()
        .uri(URI.create(url))
        .header("Content-Type", "application/json")
        .header("User-Agent", "KangDou/1.0")
        .POST(HttpRequest.BodyPublishers.ofString(bodyJson, StandardCharsets.UTF_8))
        .build();
HttpResponse<String> response = httpClient.send(request,
        HttpResponse.BodyHandlers.ofString(StandardCharsets.UTF_8));
int status = response.statusCode();
String responseBody = response.body();
```

关键：`ofString(json, StandardCharsets.UTF_8)` 与 `BodyHandlers.ofString(StandardCharsets.UTF_8)` 显式指定 UTF-8，杜绝中文乱码。

#### 预防
- **禁止在 Java 服务中用 curl/wget 子进程调 HTTP API**，一律用 `java.net.http.HttpClient`（JDK 11+ 内置）或 Spring `RestTemplate`/`WebClient`
- 不要基于"听说不兼容"的假设写 workaround，先验证再决定（见 `CLAUDE.md`「真实性」硬约束）
- 微信 API 响应统一显式 UTF-8 解码，不依赖平台默认 charset

---

## §12 服务商分账（profitsharing）

### 12.1 调用链路

```
订单完成 → sendSplit() → 冻结资金 → 请求分账
                              └→ ensureReceiverAdded()（仅首次：预注册接收方）
                                                 └→ POST /v3/profitsharing/receivers/add

售后退款 → unfrozenSplit() → 解冻剩余资金 → 请求分账
                              └→ ensureReceiverAdded()（同上，幂等）
```

微信要求：**请求分账（`/v3/profitsharing/orders`）前必须先调用添加分账接收方（`/v3/profitsharing/receivers/add`）**。接口幂等，重复添加同一接收方不报错。

### 12.2 分账接收方 name 字段必传（MERCHANT_ID 类型）

**来源**：微信官方文档 partner/4012690944（2025.09.29 更新）

当 `type = "MERCHANT_ID"` 时，`name`（商户全称）为**必传**字段，需满足：

| 要求 | 说明 |
|------|------|
| 格式 | 商户注册企业全称，与营业执照一致 |
| 加密 | 微信支付公钥 RSAES-OAEP 加密 |
| 请求头 | 须携带 `Wechatpay-Serial` = 公钥 ID |

**错误方式**：省略 name 或传明文 → 微信接口返回非法参数错误。

### 12.3 name 来源（按 receiver 类型）

| 接收方 | name 来源 | SQL |
|-------|----------|-----|
| 平台主商户（sp_mch_id） | `tenant.name`（租户名称） | `SELECT name FROM tenant WHERE id = ?` |
| 子商户（sub_mch_id） | `sub_merchant_apply.merchant_name`（进件登记全称） | `SELECT merchant_name FROM sub_merchant_apply WHERE sub_mch_id = ? ORDER BY id DESC LIMIT 1` |

### 12.4 核心代码模式（RSA-OAEP 加密）

```java
import com.wechat.pay.java.core.AbstractRSAConfig;
import com.wechat.pay.java.core.cipher.PrivacyEncryptor;
import com.wechat.pay.java.core.http.*;

Config config = platformWechatPayConfig.buildConfig();
PrivacyEncryptor encryptor = ((AbstractRSAConfig) config).createEncryptor();
AbstractHttpClient httpClient = (AbstractHttpClient) new DefaultHttpClientBuilder().config(config).build();

Map<String, Object> body = new LinkedHashMap<>();
body.put("type", "MERCHANT_ID");
body.put("account", receiverAccount);
body.put("name", encryptor.encrypt(receiverName));   // ← RSA-OAEP 加密

HttpRequest request = new HttpRequest.Builder()
        .httpMethod(HttpMethod.POST)
        .url(WECHAT_API_BASE + PROFITSHARING_RECEIVERS_ADD_PATH)
        .addHeader("Wechatpay-Serial", encryptor.getWechatpaySerial())  // ← 必设
        .body(new JsonRequestBody.Builder().body(json).build())
        .build();
httpClient.execute(request, JsonResponseBody.class);
```

**关键**：需用 `httpClient.execute(HttpRequest, ...)` 而非 `post()` 便捷方法——只有 `execute` 能携带自定义 `Wechatpay-Serial` 请求头。

### 12.5 Name 加密 API 验证

SDK 版本：`wechatpay-java` 0.2.15

| API | 来源 | 返回 |
|-----|------|------|
| `AbstractRSAConfig.createEncryptor()` | `wechatpay-java-core/0.2.15` | `PrivacyEncryptor` |
| `PrivacyEncryptor.encrypt(String)` | 同上 | RSA-OAEP 加密后 Base64 |
| `PrivacyEncryptor.getWechatpaySerial()` | 同上 | 微信支付公钥 ID（字符串） |

### 12.6 已知踩坑

| 问题 | 表现 | 原因 | 解决 |
|------|------|------|------|
| name 省略 | 微信返回非法参数 | MERCHANT_ID 的 name 为必传 | 补 name + RSA-OAEP 加密（见 12.4） |
| name 来源用错 | 查不到对应名称 → 抛 AppException | 子商户名用 `shop_sub_merchant.sub_mch_name`（冗余字段，不确定是否全称） | 统一用 `sub_merchant_apply.merchant_name`（进件登记全称，与营业执照一致） |
| 缺少 Wechatpay-Serial 头 | 签名验证失败 | encrypt 后的 name 需指定是哪个公钥加密的 | 补 Header（见 12.4） |
| 依赖 wechatpay 便捷方法（如 `post()`） | 无法设请求头 | 便捷方法不暴露 Header 接口 | 改用 `httpClient.execute(HttpRequest, ...)` |

