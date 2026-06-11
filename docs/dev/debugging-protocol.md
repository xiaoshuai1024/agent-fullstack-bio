# 调试协议 — 测试失败处理流程

> 2026-06-09 从行业模板拖拽排序 bug 复盘沉淀。**测试失败≠测试脚本有问题**，根因通常在后端。

## 第一条铁律：禁止修改测试脚本来让测试通过

测试失败时，**永远不要**第一反应去改测试脚本。除非你 100% 确认是测试代码和实现不匹配（比如接口字段变更），否则**禁止修改测试**。

## 正确的排查顺序

```
测试失败
    ↓
1. Console 有没有报错？      ← Playwright `page.on('console')` 或 `assertNoError`
    ↓
2. 后端日志有没有错误？       ← tail -f logs/kangdou-local.log | grep -i error
    ↓
3. 用 curl 直接调 API 复现   ← 绕过浏览器，确认是前端还是后端问题
    ↓
4. 后端日志再查一遍          ← 找到具体异常栈
    ↓
5. 定位根因                  ← 代码实现问题 / 环境问题 / 配置问题
    ↓
6. 修复根因                  ← 改后端代码 / 配环境 / 修配置
    ↓
7. 验证                      ← curl → Playwright → E2E
```

## 历史案例

### 案例 1：行业模板 reorder API 500（2026-06-09）

**表象**：E2E 测试断言 `resp.ok()` 返回 false，测试失败。

**错误操作**：连续 3 次修改测试脚本（加 waitForTimeout、换 token 获取方式、加 console.log），浪费 40 分钟。

**正确操作**：应该第一时间用 curl 调 API、看后端日志。

**根因**：`@PutMapping("/{id}")` 和 `@PutMapping("/reorder")` 路由冲突。Spring Boot 把 "reorder" 解析成 `{id}` 抛 `NumberFormatException`。

**修复**：`@PutMapping → @PostMapping("/reorder")`

**教训**：所有 PUT/DELETE 的路径参数 `/{id}` 会**贪婪匹配**。如果同 Controller 有 `PUT /{id}` 和 `PUT /reorder`，后者永远不会被命中。

### 案例 2：feed_posts topic 列缺失（2026-06-08）

**表象**：内容挂载商品 E2E 7 条全部 500。

**错误操作**：先怀疑前端代码，排查了 30 分钟。

**正确操作**：直接看后端日志 → `Unknown column 'topic' in 'field list'`。

**根因**：生产 DB 少迁移版本。

**修复**：`ALTER TABLE tenant_user_feed_post ADD COLUMN topic...`

### 案例 3：assertNoError 没捕获到 500

**表象**：后端返回 500，但 `expectNoUiError` 通过了。

**根因**：前端没有就 500 弹 Element Plus 错误消息。`expectNoUiError` 只查 `.el-message--error`，后端 500 不一定会触发 UI 弹窗。

**改进**：组合使用 `collectConsoleErrors` + `assertNoConsoleError` 捕获所有 console error。
