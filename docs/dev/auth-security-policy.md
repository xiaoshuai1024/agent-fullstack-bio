# 认证与安全策略

## C 端小程序登录安全

### 微信 jscode2session 凭证交换

- **必须**使用真实微信 AppID + AppSecret 进行 `jscode2session` 调用
- **禁止**使用 mock/fallback openid，包括本地开发环境、CI 环境
- 微信凭证缺失时，登录接口直接返回 503 错误并提示"微信登录配置不完整，请联系运营配置"
- `jscode2session` 调用失败时（凭证不匹配 / code 无效），直接抛出原异常，**不静默降级**

### 为什么禁止 fallback openid

1. fallback openid 会导致同一用户在不同环境/时间产生不同标识，破坏用户身份一致性
2. fallback 数据可能被写入生产数据库，造成脏数据
3. 掩盖了凭证配置问题，增加排查难度

### 运维排查指引

登录失败时，日志中会记录：
```
wechat miniapp credentials not configured for tenantId={}; hint: 运营后台 → 租户列表 → 租户配置 → 微信集成
```

前往 **运营后台 → 租户列表 → 租户配置 → 微信集成** 页面检查：
- AppID 是否已填写
- AppSecret 是否已填写
- 填写后需重启后端服务

## 昵称安全

- 昵称输入过滤控制字符（U+0000-U+001F，不含 U+000A/LF）
- 过滤 HTML 标签（`<[^>]*>`），防止存储型 XSS
- 过滤后与原文不一致则拒绝，返回"昵称包含无效字符"

## Session 管理

- Session TTL：30 天
- 每天凌晨 3 点自动清理：
  - 已过期超过 7 天的 session
  - 已吊销（`revoked=1`）且创建超过 7 天的 session
