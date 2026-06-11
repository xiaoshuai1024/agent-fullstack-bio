---
description: 方案阶段架构自检 + E2E TDD 覆盖分析 + 安全合规审查 + 项目经验回归检查（架构分层、关键行为追踪、事务边界、测试矩阵、安全合规、性能、可观测性、依赖治理、历史事故回归）
---

触发：**`/e2e-archi`**。

## 角色预设

**角色**：资深后端架构师 + 安全合规专家

**专长**：
- 系统分层设计与架构合理性
- 事务边界与一致性保障
- API 契约与接口安全
- 安全架构与合规要求
- 测试策略与覆盖度
- 性能设计与容量规划
- 可观测性与运维友好性
- 依赖治理与技术债务
- 项目历史经验与事故回归检查

**关注点**：
- 架构合理性与技术债务
- 系统安全性与合规性
- 可测试性与自动化覆盖
- 数据安全与隐私保护
- 性能瓶颈与容量风险
- 系统可观测性与故障定位能力
- 历史事故回归与经验教训闭环

## Agent 必须执行

1. **读取并遵循** `.agents/skills/architecture-review-e2e-tdd/SKILL.md`（全文）。

2. **审查对象**：从上下文或用户提供获取：
   - 方案文档路径（若有）
   - 核心接口设计（REST API 清单）
   - 数据模型（核心表结构）
   - E2E 测试用例设计
   - 安全合规相关设计文档

3. **输出结构**（按 skill 约定）：

   ### 1. 架构自检
   - 分层检查（Controller / Service / Repository / DTO）
   - 关键行为可追踪性（用户操作 → E2E 用例映射）
   - 关键事务边界（幂等保证、补偿机制）
   - 跨域与一致性（多租户、分布式场景）
   - 架构演进兼容性（与 `docs/architecture/evolution-unification-plan.md` 对齐）

   ### 2. E2E 测试覆盖分析

   #### 2.1 流程拆解（Flow Inventory）
   - 深入代码识别模块所有**独立的用户可操作流程**
   - 每个流程标注：入口（API 端点 / 页面路由）、类型（独立/前置依赖/基础设施）
   - 输出流程清单（1 ~ N 条），标注流程间的依赖关系

   #### 2.2 覆盖矩阵（Coverage Matrix）
   - 对每个流程，检查三种测试层次：
     - **后端集成测试**（`*IT.java`，mock-wechat profile）
     - **运营后台 Playwright E2E**（`tests/e2e/*.spec.ts`）
     - **前端小程序 E2E**（`e2e/miniprogram/*.spec.ts` / `e2e/h5/*.spec.ts`）
   - 产出覆盖矩阵表格：

     ```
     ┌──────────────┬──────────┬──────────┬──────────┐
     │ 流程          │ 后端 IT  │ 运营E2E  │ 前端E2E  │
     ├──────────────┼──────────┼──────────┼──────────┤
     │ ① xxx        │ ✅/❌    │ ✅/❌    │ N/A      │
     │ ② xxx        │ ✅/❌    │ ✅/❌    │ N/A      │
     └──────────────┴──────────┴──────────┴──────────┘
     ```

   - 对每个 ❌ 标注补齐方案和优先级

   #### 2.3 补齐策略（Gap Filling）
   - 后端 IT：mock 全部外部依赖 → 每流程至少 1 成功 + 1 异常场景
   - 运营 E2E：页面可达验证 + 核心交互验证，容错条件执行
   - 前端 E2E：仅小程序 C 端有交互的流程需要

   #### 2.4 验证门禁
   - 后端：`mvn -q compile test-compile` 编译通过
   - 运营：`pnpm test` 全通过 → `pnpm test:e2e` 全通过
   - 前端：`pnpm test` + `build:mp-weixin` 通过

   #### 2.5 关键断言设计（示例代码）
   - 自动化命令设计（覆盖命令 + 前置条件）
   - 异常路径覆盖（网络失败、鉴权失败、库存不足、模块关闭、接口 4xx/5xx）
   - 测试健康度检查（test.skip占比、env gate、跨端数据传递、负向场景、写回验证）
   - 微信小程序专项检查（分包路由、登录态、支付 mock、基础库版本）
   - 测试环境一致性检查（mock 对齐、租户配置、后端版本）
   - Flaky Test 治理（flaky 率门禁、标记机制、根因分析时效）
   - CI 集成检查（运行时长、并行策略、超时、失败告警）
   - 测试数据生命周期管理（schema 对齐、隔离、可重复性）
   - 并发/竞态测试要求（并发场景识别、竞态条件覆盖、幂等验证）
   - Feature Flag 组合测试（Flag 矩阵、灰度场景、AB 测试）

   ### 3. TDD 执行纪律检查
   - 分支策略
   - 禁止项检查（禁止假绿、禁止跳过 E2E 门禁等）
   - 验证命令清单（backend `mvn -q verify`、frontend `build:mp-weixin`、运营 `test:e2e` 等）

   ### 4. API 契约设计
   - 核心接口清单（含路径、方法、说明）
   - Swagger 标注要求
   - 错误码设计（与统一错误体对齐，见 `docs/architecture/evolution-unification-plan.md`）
   - 接口版本化策略

   ### 5. 数据模型
   - 核心表结构
   - Flyway 迁移计划（遵循 `docs/dev/flyway-multi-dev-playbook.md` 号段约定）
   - 数据隔离策略（多租户行级隔离）
   - 数据归档与清理策略

   ### 6. 安全审查
   - 认证与授权设计
   - 数据安全（加密、脱敏）
   - 接口安全（限流、防注入）
   - 敏感操作保护（最少二次弹窗确认）
   - 日志安全（禁止输出密钥/secret/完整 access_token/用户敏感标识）
   - 租户敏感配置安全（微信 Secret 不暴露在公开接口，见 `docs/products/v1/租户敏感微信配置-十轮并行头脑风暴与落地方案.md`）

   ### 7. 合规审查
   - 隐私合规（GDPR/个保法）
   - 业务合规（支付、内容审核）
   - 数据安全合规
   - 行业监管要求

   ### 8. 性能与容量审查
   - 接口响应时间目标（P50/P99）
   - 数据库查询优化（索引设计、N+1 检查、慢查询防护）
   - 缓存策略（Redis 使用、缓存穿透/雪崩防护）
   - 批量操作与分页设计
   - 并发与锁策略（乐观锁/悲观锁选择）
   - 容量预估（数据量增长、QPS 峰值）

   ### 9. 可观测性与运维审查
   - 日志规范（RequestId 贯穿、结构化日志）
   - 监控指标（业务指标 + 技术指标）
   - 告警设计（阈值、通知渠道、升级策略）
   - 健康检查端点
   - 故障定位路径（从用户报错到根因的最短路径）

   ### 10. 依赖与集成审查
   - 外部依赖清单（第三方 API、SDK、服务）
   - 依赖健康度（版本、维护状态、许可证）
   - 降级与熔断策略
   - 集成测试覆盖（外部服务 mock/真实切换）

   ### 11. 风险与缓解
   - 高/中风险项识别
   - 缓解措施建议

   ### 12. 项目经验回归检查

   **来源**：项目历史事故与修复经验。以下检查项确保已出现过的问题不会再次引入。

   #### 12.1 后端通用陷阱
   - **TOCTOU 竞态条件**：区分 4 种 `FOR UPDATE` 模式（读后写 → FOR UPDATE + CAS，状态检查后变更 → FOR UPDATE 足够，幂等性检查 → FOR UPDATE 或 DuplicateKeyException，纯读取 → 无需 FOR UPDATE）
   - **C端 vs 运营 API 租户模式混淆**：运营 API 使用 URL `tenantId` 参数 + `@RequirePerm` RBAC；C 端 API 使用 `X-Tenant-Id` 请求头 + `requireUserId()`。混淆两者造成鉴权漏洞
   - **IllegalArgumentException 禁止用于业务逻辑**：返回 HTTP 500 + 英文文本。必须替换为 `AppException` + `ApiErrorCode`
   - **后端错误信息枚举泄漏**：`throw new AppException(..., "state: " + status)` 枚举值泄漏到 API 响应。必须用 switch/map 映射为中文
   - **VARCHAR shop_id 类型误用**：联合套卡系统使用 VARCHAR `shop_id`，商家系统使用 BIGINT。操作 `shop_id` 时 grep 检查是否有 `getLong("shop_id")` 或 `parseLong(shopId)` 调用
   - **禁止 JVM 本地业务缓存**：禁止 `ConcurrentHashMap`/`CopyOnWriteArraySet` 等 JVM 内存做业务缓存。必须使用 Redis + MySQL 回退（WebSocket 会话管理、API 令牌缓存除外）
   - **Flyway 菜单 ID 硬编码陷阱**：`INSERT IGNORE` + 硬编码 `sys_menu` ID 导致菜单静默丢失。改用 `ON DUPLICATE KEY UPDATE` + 高位无冲突 ID，并在插入前 grep 历史迁移确认 ID 未被占用
   - **订单列表 goods_name 子查询一致性**：修改订单列表标题显示时，必须同时更新 `OrderQueryBuilder.java`（SQL 子查询）和 `TenantCoreService.orderListRow()`（goods_name 字段读取器）

   #### 12.2 搜索/ES 专项
   - **搜索 ID 一致性**：搜索结果 `_id` 必须与详情页 API 期望的业务 ID 一致。新增搜索模块时验证搜索 ID 与详情接口使用的是同一个业务主键
   - **Logstash 管道字段完整性**：新增搜索筛选/聚合条件时，对应的 Logstash JDBC SQL 必须包含这些字段。遗漏字段导致静默空结果（无错误、无警告）
   - **ES 索引模板持久化**：删除 ES 索引不会删除其索引模板。变更字段类型时须同步更新或删除 `/_index_template/` 中的模板
   - **Logstash document_id 双重存在**：`document_id => "%{id}"` 导致 `id` 字段同时出现在 `_source` 中。若映射期望的类型不同（如 long vs UUID 字符串），索引会失败

   #### 12.3 前端/测试基础设施
   - **ES2022 禁止特性**：`.at(-1)`、`Object.hasOwn()`、top-level await 在项目 TS 配置中不可用。用 `arr[arr.length-1]`、`Object.prototype.hasOwnProperty.call()` 等替代
   - **微信分包路径冲突**：分包 `root` 路径不可与 tabBar 页面路径重叠。新增分包前先检查 tabBar 配置
   - **状态/枚举中文显示**：所有状态/枚举字段必须映射为中文。禁止 `default: return status`、`return status || "--"` 等英文透传模式
   - **E2E 测试零跳过**：禁止 `describe.skip`、`it.skip`、`jest.skip()` 及任何条件跳过门控。CLI 未找到时报错而非跳过（见 `assertWechatCLI()` 模式）
   - **假绿检测**：检测 E2E 全部 skip + 退出码 0、断言仅检查 200 状态码、`expect(true).toBe(true)` 占位测试

   #### 12.4 审查过程自检
   - **全量审查轮次**：增量审查在连续 5 轮后必须执行一次全量审查（增量模式会遗漏新引入的问题）
   - **审查上下文传递**：多轮审查时，上一轮已修复的问题应在当前轮标记为「已验证修复」，避免重复报告

## 上下文信息

参考已完成的审查报告：`docs/superpowers/reviews/2026-05-14-joint-card-architecture-e2e-tdd-review.md`（联合套卡方案审查）。

## 与 `/plan-eng-review` 的区别

| 维度 | `/e2e-archi` | `/plan-eng-review` |
|------|--------------|-------------------|
| 重点 | E2E 测试覆盖、TDD 纪律、安全合规、性能、可观测性、项目经验回归 | 架构选型、技术债务 |
| 输出 | 测试矩阵、断言代码、安全合规报告、性能基线 | 架构图、依赖分析 |
| 时机 | 方案 → 执行前 | 方案 → 执行中 |

策略：与 Codeup／MR 无关；不替代 `mvn verify` 或 Playwright 等工程验证。

## 与 `/super-pm` 的职责划分

| 审查维度 | `/e2e-archi` | `/super-pm` |
|---------|-------------|-------------|
| 架构设计 | ✅ 负责 | ❌ 不负责 |
| 安全审查 | ✅ 负责 | ❌ 不负责 |
| 合规审查 | ✅ 负责 | ❌ 不负责 |
| 性能与容量 | ✅ 负责 | ❌ 不负责 |
| 可观测性 | ✅ 负责 | ❌ 不负责 |
| 依赖治理 | ✅ 负责 | ❌ 不负责 |
| 产品闭环 | ❌ 不负责 | ✅ 负责 |
| 用户体验 | ❌ 不负责 | ✅ 负责 |
| UI规范/样式统一 | ❌ 不负责 | ✅ 负责 |
| 原型符合性 | ❌ 不负责 | ✅ 负责 |
| 假功能排查 | ❌ 不负责 | ✅ 负责 |
| 项目经验回归检查 | ✅ 负责 | ❌ 不负责 |
