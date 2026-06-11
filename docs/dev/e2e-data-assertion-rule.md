# E2E 数据层断言规范

## 规则

**所有 E2E 测试中的写操作（创建/修改/删除/审批），必须同时验证三层：**

```
操作 → API 响应 → 数据持久化
         ↓           ↓
    HTTP 状态码     DB/API 查询确认数据
```

## 性能优化规则

### 1. 禁止 waitForTimeout 硬等待

❌ **禁止：**
```typescript
await page.goto(url, { waitUntil: "domcontentloaded" });
await page.waitForTimeout(3000); // 浪费 3 秒
```

✅ **正确：**
```typescript
await page.goto(url, { waitUntil: "domcontentloaded" });
await page.waitForLoadState("networkidle"); // 等网络空闲，通常 <1s
```

### 2. 优先使用条件等待

| 场景 | 推荐方式 |
|------|---------|
| 等待页面加载完成 | `page.waitForLoadState("networkidle")` |
| 等待元素出现 | `expect(locator).toBeVisible({ timeout })` |
| 等待元素消失 | `expect(locator).not.toBeVisible({ timeout })` |
| 等待 API 响应 | `page.waitForResponse(url, { timeout })` |
| 等待自定义条件 | `page.waitForFunction(() => ..., { timeout })` |

仅在前端有 `void asyncFunc()`（未 await 的异步调用）且无法用元素状态判断时，才允许使用短时 `waitForTimeout(1000)` 作为 fallback。

### 3. 适当增加并行 workers

`playwright.config.ts` 中 workers 可通过 `OPS_E2E_WORKERS` 环境变量控制，建议值 3。每 worker 独立浏览器实例。

### 4. 每个测试后断言无错误弹窗

所有测试执行页面操作后，必须检查无错误弹窗出现：

```typescript
// 在测试末尾或 afterEach 中
await expect(page.locator(".el-message--error")).not.toBeVisible({ timeout: 3000 });
```

或全局监听（适合 fixture 级别）：
```typescript
test.afterEach(async ({ page }) => {
  const errorToast = page.locator(".el-message--error");
  const count = await errorToast.count().catch(() => 0);
  if (count > 0) {
    const text = await errorToast.first().innerText();
    throw new Error(`页面出现错误弹窗: ${text}`);
  }
});
```

## 反例（不能通过验收）

```typescript
// ❌ 只检查 HTTP 状态码
await page.getByRole("button", { name: "确认创建" }).click();
const resp = await page.waitForResponse(...);
expect([200, 409]).toContain(resp.status());
// ❌ 没有验证数据是否落盘
// ❌ 没有检查页面是否有错误弹窗
```

HTTP 200 只代表"请求没抛异常"，不代表"业务 SQL 执行成功"或"页面无报错"。

## 正例

```typescript
// ✅ 状态码 + 数据层 + 错误弹窗 三重断言
await page.getByRole("button", { name: "确认创建" }).click();
const resp = await page.waitForResponse(...);
expect([200, 409]).toContain(resp.status());

// 数据层验证：通过查询 API 确认数据已持久化
if (resp.status() === 200) {
  const body = await resp.json();
  const queryResp = await page.request.get(`/api/.../detail?id=${body.id}`);
  expect(queryResp.ok()).toBeTruthy();
  const data = await queryResp.json();
  expect(data.status).toBe("PENDING");
  expect(data.items?.length).toBeGreaterThan(0);
}

// 页面无错误弹窗
await expect(page.locator(".el-message--error")).not.toBeVisible({ timeout: 3000 });
```

## 各模块数据层验证要点

| 模块 | 写操作 | 数据层验证 |
|------|--------|-----------|
| 结算 | 创建批次 | `GET /settlement/statements?batchId={id}` 确认有结算单 |
| 结算 | 确认结算单 | `GET /settlement/statements/{id}` 确认状态变为 CONFIRMED |
| 结算 | 发起出款 | `GET /settlement/payouts` 确认出款记录创建 |
| 提现 | 审核通过 | `GET /withdraw/applications` 确认状态变为 APPROVED |
| 提现 | 审核拒绝 | `GET /withdraw/applications` 确认状态变为 REJECTED |
| 提现 | 重试出款 | `GET /withdraw/applications` 确认 attempt_count 增加 |
| CPS | 保存配置 | `GET /cps/config` 确认配置值已更新 |
| 计佣 | 发布策略 | `GET /commission/policies` 确认策略已发布 |
| 对账 | 创建批次 | `GET /reconciliation/batches` 确认批次创建 |
| 分账 | 保存规则 | `GET /profit-sharing/config` 确认规则保存 |

## Code Review 检查点

代码审查时逐条核查：

- [ ] 这个测试测的是写操作吗？
- [ ] HTTP 状态码断言后，有没有跟进数据层断言？
- [ ] 页面跳转/操作后，是否用了 `waitForTimeout` 硬等待？（应改为条件等待）
- [ ] 测试末尾是否检查了无错误弹窗？
- [ ] 如果是 409/404 等"操作未执行"的分支，是否明确记录了跳过数据验证的原因？
