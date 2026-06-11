# SaaS 模块 E2E 全流程覆盖方法论

> 来自 feature/architecture-platform-dev 分支的实战经验。2026-06-06

## 问题

一个新模块（如 SaaS 代开小程序）包含多个独立流程。如何确保每个流程都被 E2E 测试覆盖，不遗漏？

## 方法论：流程拆解 → 覆盖矩阵 → 补齐 → 验证

### 第一步：流程拆解（Flow Inventory）

深入代码，识别出模块中所有**独立的用户可操作流程**。每个流程应满足：

- 有明确的入口（API 端点 或 页面路由）
- 有可观测的输出（DB 变更 / 微信 API 调用 / 页面状态变化）
- 可以独立运行，不依赖其他流程的结果

**示例**（SaaS 代开模块拆解出 10 个流程）：

| # | 流程 | 类型 | 入口 |
|---|------|------|------|
| ① | 第三方平台接入层 | 基础设施 | POST /api/public/wechat-third-party/ticket |
| ② | 代码模板管理 | 独立 | GET /saas/code-templates |
| ③ | 代注册小程序 | 独立 | POST /api/platform/wechat-proxy-open/register |
| ④ | 小程序授权 | 独立 | POST /api/platform/wechat-auth/authorize-url |
| ... | ... | ... | ... |

### 第二步：覆盖矩阵（Coverage Matrix）

对每个流程，检查三种测试层次：

```
┌──────────────┬──────────┬──────────┬──────────┐
│ 流程          │ 后端 IT  │ 运营E2E  │ 前端E2E  │
├──────────────┼──────────┼──────────┼──────────┤
│ ① 接入层      │ ✅/❌    │ ✅/❌    │ N/A      │
│ ② 代码模板    │ ✅/❌    │ ✅/❌    │ N/A      │
│ ...           │ ...      │ ...      │ ...      │
└──────────────┴──────────┴──────────┴──────────┘
```

### 第三步：补齐策略（Gap Filling）

按优先级补齐：

1. **后端集成测试（IT）** — 验证 Controller → Service → DB 全链路，外部依赖 mock
   - 每个流程至少 1 个成功场景 + 1 个异常场景
   - Mock 配置需要完整覆盖所有外部 API 调用

2. **运营后台 Playwright E2E** — 验证页面可达 + 核心交互
   - 页面加载验证（URL、标题、关键元素）
   - 操作交互验证（按钮点击、弹窗打开/关闭）
   - 有条件执行（仅当数据存在时测试操作）

3. **前端小程序 E2E（miniprogram automator）** — 验证 C 端流程

### 第四步：验证门禁（Verification Gate）

- 后端：`mvn -q compile test-compile` 编译通过
- 运营后台：`pnpm test` 单元测试全通过（1281 passed）
- 运营 E2E：`pnpm test:e2e -- saas-*` 全部通过（25 passed, 0 failed）

## 关键经验

### Mock 配置要全面

`WechatMockConfig.java` 是所有 SaaS IT 测试的基础。必须 mock：

- `WechatThirdPartyPlatformService` — 所有第三方平台 API 调用
- `WechatAuthCodeService` — 授权码交换
- `MiniAppProxyOpenService` — 代注册（微信 API + DB 写入）
- `WechatDomainConfigService` — 域名配置
- `SaaSDataSyncService` — 数据同步
- `SubMerchantOnboardingService` — 特约商户入驻
- `WechatCodeTemplateService` — 代码模板操作

### E2E 测试要容错

Playwright E2E 运行在真实后端上，数据状态不确定。使用条件执行模式：

```typescript
const btn = page.locator("button:has-text('xxx')").first();
const exists = (await btn.count()) > 0;
if (exists) {
  await btn.click();
  // ...验证交互
}
```

### 跑通是底线

"补齐"不仅写文件，还要跑通。存量测试失败也要一并修复，否则每次 CI 都红。

## 相关文件

- SaaS 代开后端 IT 测试：`backend/src/test/java/com/kangdou/*IT.java`（6 个文件）
- Mock 配置：`backend/src/test/java/com/kangdou/mock/WechatMockConfig.java`
- SaaS E2E 测试：`operation-backend/tests/e2e/saas-*.spec.ts`（6 个文件）
- `/e2e-archi` 命令：`.claude/commands/e2e-archi.md`
