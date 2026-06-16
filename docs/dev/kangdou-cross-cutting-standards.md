<!--
description: 全栈实现阶段交叉检查清单：认证路径、字段映射、分页约定、权限码一致性、Flyway种子校验、E2E覆盖矩阵、可观测性链路、功能门禁完整性
globs: backend/src/main/java/com/kangdou/**/*.java, backend/src/main/resources/db/migration/*.sql, operation-backend/src/router/*.ts, operation-backend/src/api/*.ts, frontend/src/api/*.ts
alwaysApply: false
-->

# 全栈实现阶段交叉检查清单

## 来源

本文档源自 `feature/global-search` 分支 20 路并行审查发现的系统性根因总结。每次新增跨模块功能时，须按以下清单逐项检查。

---

## 🔴 检查清单（MUST，合入前必须逐项通过）

### 1. 检查 Controller 路径是否被认证过滤器覆盖

```markdown
- [ ] 运营端新 Controller 是否使用 @RequestMapping("/api/platform/...")？
- [ ] 是否确认 OpsAuthFilter.requiresOpsAuth() 匹配该前缀？
- [ ] C 端新 Controller 是否已被加入 TenantFilter.requiresTenant() 路径列表？
```

常见错误：新运营 Controller 使用 `/api/admin/` 而非 `/api/platform/`，导致所有 `@RequirePerm` 端点返回 401。

### 2. 检查 Spring Data ES 字段映射名一致

```markdown
- [ ] Java 实体类字段名（camelCase）与 ES mapping（snake_case）是否通过 @Field(name = "...") 显式映射？
- [ ] ES term query 中使用的字段名是否与 mapping 一致？
- [ ] 父类公共字段（tenantId, updatedAt 等）是否都标注了 @Field？
```

常见错误：Java 字段 `tenantId` 无 `@Field` 注解，ES 自动映射为 `tenantId`，但查询硬编码 `tenant_id` → 永远匹配不到文档。

### 3. 检查分页基值一致性

```markdown
- [ ] 新 Controller 的 page 参数是否使用 1-based（defaultValue = "1"）？
- [ ] 内部调用（ES PageRequest、JPA 等 0-based API）是否做 page-1 转换？
- [ ] 项目所有 Controller 的分页约定是否统一（本项目约定：1-based）？
```

### 4. 检查前后端权限码一致性

```markdown
- [ ] 前端路由 meta.perm 是否与后端 @RequirePerm 和 Flyway 种子数据一致？
- [ ] 前端的权限码是粗粒度（一个码控制整个页面）还是细粒度（list/add/edit/delete 各一个）？需与后端对齐。
- [ ] 运营路由的 menu.ts 配置的 routeName 是否与 router/index.ts 一致？
```

### 5. 检查 Flyway 种子数据与代码一致性

```markdown
- [ ] SQL 中的 route_name 是否与前端 router/index.ts 的路由 name 完全一致（单复数、大小写）？
- [ ] SQL 中的 component 路径是否与实际视图文件路径完全一致（文件名单复数）？
- [ ] 权限种子是否与 @RequirePerm 注解值一致？
```

### 6. 检查功能门禁完整性

```markdown
- [ ] 如果功能支持租户级开关，UI 租户配置页是否渲染了该开关？
- [ ] Controller 端点是否在入口处检查了该功能模块的启用状态？
- [ ] 运营菜单是否根据功能状态条件显示？
```

### 7. 检查数据同步链路

```markdown
- [ ] 数据写入后是否同步到了 ES / 缓存 / 其他存储？
- [ ] 如果依赖定时同步（Logstash JDBC 等），MySQL 与 ES 的延迟窗口是否在产品可接受范围内？
- [ ] 运营 CRUD 操作后是否需要立即在 C 端生效？如果是需补充事件驱动同步。
```

### 8. 检查可观测性闭环

```markdown
- [ ] 日志格式是否与 Logstash pipeline 的解析方式匹配（JSON vs KV）？
- [ ] ES 索引模板是否已定义并与日志字段匹配？
- [ ] 搜索/查询看板是否有数据来源？TODO 空壳不应展示给运营人员。
- [ ] 慢查询阈值和告警是否已定义？
- [ ] 是否暴露了必要的 Micrometer/Prometheus 指标？
```

### 9. 检查 E2E 测试覆盖矩阵

```markdown
- [ ] 是否有测试覆盖核心正路径（搜索成功、结果展示、点击跳转）？
- [ ] 是否有测试覆盖负路径（无结果、敏感词拦截、错误降级）？
- [ ] 是否有测试覆盖边界（超长输入、特殊字符、连续请求）？
- [ ] 运营后台是否有测试覆盖编辑、状态切换、批量导入？
- [ ] 集成测试（*IT.java）是否继承了 AbstractMysqlIntegrationIT？
- [ ] 单元测试断言是否与生产代码的实际返回一致（避免假绿）？
```

---

## 🟡 最佳实践（建议合入前完成）

### 10. 检查 SQL 查询字段索引覆盖

```markdown
- [ ] 所有 WHERE 条件中的字段组合是否有对应索引？
- [ ] 联合索引的列顺序是否与查询条件匹配（最左前缀原则）？
- [ ] EXISTS/NOT EXISTS 子查询中的关联字段是否有索引？
- [ ] ORDER BY 字段是否参与索引或单独建索引？
- [ ] 列表类查询接口是否设置了合理的 LIMIT 防止全表扫描？
```

**常见遗漏**：
- 状态字段（card_status、shelf_status、status）常用作筛选条件但经常无索引
- 组合条件（tenant_id + status）需建联合索引而非两个单列索引
- EXISTS 子查询中的筛选条件（如 listing_visible = 1）容易漏索引

**索引设计原则**：
- 高频查询的 WHERE 条件列必须建索引
- 复合索引列顺序：等值条件 → 范围条件 → 排序列
- 避免在索引列上使用函数或表达式运算
- 新增索引后必须通过 EXPLAIN 验证执行计划

### 11. 服务层事务边界
- 多字段更新应合并为一条 SQL 或使用 `@Transactional`
- 避免逐字段独立 UPDATE（非原子、N 次 DB 往返）

### 11. ES 索引模板
- 生产环境 `number_of_replicas` >= 1
- 统一通过 composable index template 管理
- 自动创建脚本（`init-es-indices.sh`）附带幂等性

### 12. API 请求体
- 使用 DTO record/class 替代裸 `Map<String, String>`
- 配合 Jakarta `@Valid` / `@NotBlank` / `@Size` 做编译时校验

### 13. 敏感词过滤
- 使用 AC 自动机或 Trie 替代 `String.contains()` 线性扫描
- 拦截时在响应中包含 `blocked: true` 标记和友好提示

### 14. 搜索竞态保护
- 前端搜索请求需加 requestId 序列号，旧请求结果丢弃
- 搜索发起应防抖（已有联想词防抖 300ms，搜索提交也应加上）

---

## 何时加载

| 场景 | 加载方式 |
|------|----------|
| 新增跨模块功能（涉及前后端 + DB） | 实现前逐项检查 |
| 新增运营 Controller | 检查第 1 项 |
| 新增 Spring Data ES Document | 检查第 2 项 |
| 新增 Flyway 种子数据 | 检查第 5 项 |
| 新建 E2E 测试 | 检查第 9 项 |
| 宣称功能完成/合入前 | 全量逐项检查 |

---

## 本规则的增补

---

## 经验：DB 字段语义独立性与防重约束

### 场景
招募匹配流程中 `joint_card.per_user_limit` 字段被两个业务概念共用。

### 问题

**字段语义必须一对一映射到业务概念。**  
`per_user_limit`=每人限购，「招募商家上限」须用独立字段（`recruit_max_slots`），分属两个字段，避免：
- 前端误传（`recruitMax` 发给 `perUserLimit`）
- 查询逻辑互相干扰（`listMatchPool` 用限购字段算剩余名额）
- 后续需求变更时改一个影响另一个

### 解决方案
```sql
-- 新增独立字段，不动旧字段
ALTER TABLE joint_card ADD COLUMN recruit_max_slots INT NOT NULL DEFAULT 0;
```
API 层分别映射：
- `CreateRecruitmentBody.recruitMaxSlots` → `joint_card.recruit_max_slots`
- `CreateRecruitmentBody.perUserLimit` → `joint_card.per_user_limit`

### 预防
- 方案评审阶段，每个字段标注"中文含义"和"取值范围"
- 发现一个字段可能对应两个不同含义 → 必须拆开，延迟拆分成本远高于建表时拆分
- 跨模块功能（涉及前后端+DB）必须按本规则清单逐项检查

---

## 经验：并发报名 SQL 唯一约束

### 场景
招募报名的并发防重。

### 解决方案
DB 层防重必须用唯一约束，业务代码的 COUNT 查询不等价：

```sql
-- 必须：DB 层唯一约束兜底
ALTER TABLE joint_card_recruitment_application
  ADD UNIQUE KEY uk_app_shop_once (tenant_id, joint_card_id, applicant_shop_id);

-- 业务层 COUNT 检查作为前置提示（避免抛 SQL 约束异常到前端）
Long existing = jdbcTemplate.queryForObject(
    "SELECT COUNT(*) FROM joint_card_recruitment_application WHERE tenant_id = ? AND joint_card_id = ? AND applicant_shop_id = ?",
    Long.class, tenantId, jointCardId, shopId);
if (existing != null && existing > 0) {
    throw new AppException(HTTP_CONFLICT, "已报名该招募");
}
```

### 预防
- 任何"同类数据只能存在一条"的业务规则，必须在 DB 层建 UNIQUE KEY
- 业务层 COUNT 检查作为友好提示，不依赖其防并发
- 新建迁移脚本时必须检查是否漏了 UNIQUE 约束

发现新的系统性根因时，在本文件追加检查项。参见 `.agents/rules/self-improve.md`。

---

## 经验：首页楼层架构 — 静态配置 vs 实时数据

### 场景
首页原有 10+ 楼层由 `miniapp-home-ui-defaults.json` 静态 JSON 驱动，展示"示例商品·联调用"等死数据。改造后改为真实 API 驱动。

### 根因
早期架构直接用运营后台 JSON 编辑器维护所有首页数据，Banner/金刚位等运营内容与商品/圈子等业务数据混在同一份 JSON 配置中。

### 方案
- **运营内容**（Banner、金刚位文案、精选入口）保持 JSON 配置，运营可配
- **业务数据**（商品列表、圈子列表、销售排行）走专用 API，零死数据
- 运营后台 JSON 编辑器只保留运营内容区块，业务区块显示"数据自动获取"提示

### 预防
- 新增首页楼层时先判断：这是"运营配置"还是"业务数据"？
- 运营配置 → 加到 `miniapp-home-ui-defaults.json` + 运营后台表单
- 业务数据 → 新建 API endpoint + 前端组件 + 可选运营配置（如展示数量）

---

## 经验：步骤结构调整防挂一漏万

合并/删除步骤时，必须同步更新：
- `stepLabels` 数组长度和文案
- 模板中所有 `v-show="activeStep === N"` 条件（后续步骤索引前移）
- 导航按钮条件：`activeStep < N`（最大步骤索引）和 `activeStep === N`（末步操作按钮）
- `validateCurrentStep` 中所有 `activeStep.value === N` 分支
- `nextStep` 中的 `activeStep.value < N` 上限
- `prevStep` 通常无需改（`activeStep > 0` 通用）

**检查清单**：改完后搜索文件中所有 `activeStep` 引用，逐一确认每个的语义在新结构中正确。

---

## 经验：后端 SQL/Java 变更后必须重启

任何对 `backend/` 下 Java 文件或 SQL 的修改，**必须** `mvn compile` + 重启后端进程，否则前端 API 调用会返回 500。E2E 测试可能因服务端 500 导致页面白屏或导航失败（表现为 `page.goto` 后找不到元素）。

---

## 经验：双目录文件同步（.agents/ + .claude/）

Claude Code 不支持符号链接，`claude/commands/` 和 `.claude/skills/` 中的文件必须是独立副本。

**规则**：
- 所有技能/命令的定义在 `.agents/commands/` 和 `.agents/skills/` 中维护
- Claude Code 从 `.claude/commands/` 和 `.claude/skills/` 加载
- **修改后必须同步到对应 `.claude/` 路径**，否则对 agent 不生效
- 用 `diff` 验证一致，确认 `cp` 实际执行

---

## 经验：文件编辑的 old_string 唯一性约束

Edit 工具要求 `old_string` 在文件中唯一。遇到重复字符串（如多行相同的备注标记）时：
1. 阅读更多上下文行以构造唯一匹配
2. 或者使用 `replace_all: true` 全局替换
3. 修订记录等有规律文本，**先 Read 读取精确行内容再 Edit**，不要凭猜测写 old_string

---

## 经验：SKILL.md 条件化加载模式

`<!-- LOAD: path, condition -->` 和 `<!-- IF: condition -->` 指令模式：

```
<!-- LOAD: docs/dev/operation-backend-dev-standards.md, 涉及运营后台 -->
```

- **LOAD**：路径 + 触发条件，agent 在执行时判断条件是否满足，满足则 Read
- **IF**：纯条件守卫，满足才执行该审查段落
- 避免始终加载大型文档（如 UI token 表），大幅节省 token
- 对阅读者自文档化——不用写注释说明「什么时候需要看什么」

---

## 经验：多文件审查的深度节流

审查文件数量超过阈值时自动降级，防止 token 爆炸：

- 单次审查默认 **≤ 15 个文件**，超出的截断
- **> 50 个文件** → 自动降为轻量模式（仅执行 preflight 规则）
- **纯后端变更** → 跳过 UI 样式检查（节省 70% token）
- 文件级 `consecutiveClean` 追踪 → 连续无问题的文件可跳过

---

## 经验：UI 样式检查体系分层结构

可复用的样式检查分层架构：

| 层 | 方式 | 适用场景 |
|---|------|---------|
| Preflight | 自动 grep / AST | 硬编码色彩、emoji 图标、骨架页、假数据 |
| Analysis | 混合（自动 + 人工） | 组件合规、圆角一致性、z-index 堆叠 |
| Review | 人工 LLM 判断 | 动效流畅度、交互合理性、视觉密度 |

---

## 经验：Insights 报告高频问题模式

详情见 `report-2026-05-21-110130.html` 中总结的三大 friction 类型。

### 级联修复循环

- **现象**：一次修改引入新编译错误，修复后又引入新问题，需要多轮才绿
- **根因**：修改后没有立即编译验证，多个修改叠加后才运行编译
- **预防**：每次 Edit 后立即 `mvn -q compile`（后端）或 `pnpm run build:mp-weixin`（前端），失败则回滚本次改动

### 误解请求

- **现象**：Claude 搜索错误的工具、做超出请求范围的操作（如自动创建 symlink）
- **根因**：没有先确认理解再动手
- **预防**：执行复杂操作前先 Read 当前状态，输出任务理解摘要供用户确认

### Worktree 合并遗漏

- **现象**：修复 agent 在 worktree 中改了代码但主仓看不到
- **根因**：worktree 分支未合并回主仓
- **预防**：修复 agent 完成后必须将 worktree 分支合并回主仓当前分支

### 后端修改后未重启

- **现象**：改完 Java/SQL 后，前端 API 调用 500，E2E 页面白屏
- **根因**：老 JVM 不感知文件变更
- **预防**：任何 backend 改动必须 `mvn compile` + 重启后端进程后再测

---

## 经验：worktree agent 的 router/配置修改需要显式合并

### 场景
T6（运营后台认证页面）agent 在 worktree 中修改了 `router/index.ts`、`lazyViews.ts`、`menu.ts`，但合并时只复制了 `.vue` 文件到主仓库，遗漏了路由配置，导致页面 404。

### 根因
"复制视图文件"这个操作没有覆盖路由配置。worktree 的修改范围超出预期——agent 不仅创建了新页面，还修改了配置文件。

### 解决方案
合并 worktree 时用 `diff` 或 `grep` 检查所有被修改的文件，不要只复制"预期的"新文件：
```bash
# 在 worktree 中查找所有非 worktree 创建的新修改
cd <worktree-path>
git diff --name-only HEAD  # 找出所有修改
# 然后逐项确认是否需要合并到主仓库
```

### 预防
1. worktree agent 完成后，先 `git diff --name-only HEAD` 查看完整改动清单
2. 按清单逐项复制，不遗漏配置文件
3. 复制后 `pnpm run build` / `mvn compile` 验证

---

## 经验：合约一致性检查机制（contract-check.sh + pre-commit hook）

### 场景
部署时发现公告功能（FeatureAnnouncementController）引用的 `feature_announcement` 表在 Flyway DDL 中不存在，且后端 Controller 路由与前端 API 声明未做对齐检查。后端编译通过，运营后台单测通过，但部署后该功能不可用。

### 根因
1. 前端 API 层测试 mock 了整个 HTTP 层（`vi.mock("../api/jsonClient")`），测试只验证 URL 拼接格式，不验证后端是否存在对应路由
2. E2E 测试未覆盖公告功能模块，只有主流程（交易、租户）的用例
3. 后端 Controller、前端 API 声明、Flyway DDL 三者无一致性检查
4. 迁移版本号在合并过程中丢失，`V1054__create_feature_announcement_table.sql` 未进入 dev 分支

### 解决方案
创建三层合约检查脚本 `scripts/contract-check.sh`，实现：
1. **前端 URL ↔ 后端 Controller 路由**：提取 `operation-backend/src/api/*.ts` 中的 URL 声明，与 `@RequestMapping` 注解对比
2. **后端 SQL 表引用 ↔ Flyway DDL**：提取 `ops/feature` 模块 SQL 中引用的表名，与迁移文件中 `CREATE TABLE` 声明对比
3. **@RequirePerm 权限键 ↔ 迁移脚本注册**：提取代码中 `@RequirePerm("ops:feature:*")` 的声明，与 `sys_permission` 种子数据对比
4. **Flyway 版本号唯一性**：检查 `V*.sql` 文件版本号无重复

安装方式：
```bash
make install-hooks     # 安装 git pre-commit hook
# 或手动
bash scripts/install-hooks.sh
```

### 预防
1. **所有新功能提交前**：pre-commit hook 自动运行合约检查，不通过则拦停
2. **Claude PostToolUse hook** 在 `git commit` / `mvn verify` 后自动报告
3. **`/kd-review` 第 1.5 步**：审查前先扫合约，不通过则终止
4. **API 层测试应走真实 HTTP**：至少验证后端存在对应路由，而非只测 URL 格式

---

## 🔴 租户 ID 与用户 ID 类型一致性规则（2026-06-05 新增）

### 背景

项目已全面切到字符串 ID 格式（`t_eb78751bae84`、`u_68531eed2d7f468e`、`u_mock_xxx`），但通知模块（19 个 Java 文件 + 6 张 DB 表）仍沿用旧的 `Long` 类型，导致所有通知 API 返回 400，测试被过度过滤器掩盖而未能及时发现。

### 强制规则

```
- [ ] 新增 Java 代码中的 tenantId 类型 → String（禁止 Long）
- [ ] 新增 Java 代码中的 userId 类型   → String（禁止 Long）
- [ ] 禁止使用 Long.parseLong() / Long.valueOf() 解析 ID 字段
- [ ] 禁止使用 String.valueOf(tenantId) 包装（已经是 String 直接传）
- [ ] DB 表 tenant_id 列 → VARCHAR(64)（禁止 BIGINT）
- [ ] DB 表 user_id 列   → VARCHAR(64)（禁止 BIGINT）
- [ ] 代码审查：grep -rn "Long tenantId\|Long userId\|Long.parseLong.*tenantId\|Long.valueOf.*userId"
```

### 修复代价

通知模块修复案例：19 个 Java 文件 + 6 张表 ALTER + 4 个外部调用方 + 2 轮 agent 执行 ≈ 12 分钟。预防比修复成本低得多。

### 检查命令

```bash
# Java 代码 ID 类型审计
grep -rn "Long tenantId\|Long userId\|long tenantId\|long userId" backend/src/ --include="*.java" | grep -v test | grep -v "/target/"

# DB 表 ID 类型审计
# 在 kddev 库执行：
SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA='kddev' AND COLUMN_NAME IN ('tenant_id','user_id') AND COLUMN_TYPE LIKE '%bigint%';
```

---

## 经验：活动类型路由分离 — C端 vs 商家端（2026-06-06）

### 场景
7种活动类型共用一个通用 `/pages/activity/detail` 页面，`flash-detail.vue` 和 `group-detail.vue` 已实现但从未被路由到。C端创建页暴露商户专有类型。后端 `activity_type = NULL` 查询永远返回 0 行。

### 根因
1. `list.vue`/`my.vue` 的 `goDetail()` 对所有类型导航到同一 `detail` 页
2. 后端 `UnifiedActivityController` 和 `MerchantActivityController` 都不校验类型合法性
3. MySQL `WHERE activity_type = NULL` 永远为 false（三值逻辑）
4. 商家端企业中心 hub 无活动管理入口

### 解决方案
**前端**: `goDetail()` 按 `activityType` 分叉路由；C端 `create.vue` 仅保留圈子类型；hub 新增入口
**后端**: 两个 Controller 各加 `Set.of(...)` 类型白名单校验；`findByTenantAndType` null 分支走无过滤 SQL

### 预防
- 新增类型时确认归属（C端/商家/圈子），同步更新前后端白名单
- 列表筛选 API 须处理 null 参数

---

## 经验：fen→yuan 价格必须 `.toFixed(2)`（2026-06-06）

### 场景
`detail.vue` 和 `enroll.vue` 的 `fenToYuan()` 返回原始数字（`50.5`），显示为 `"¥50.5/人"` 而非 `"¥50.50/人"`。

### 根因
本地定义缺少 `.toFixed(2)`，项目已有正确共享工具但未被引用。

### 解决方案
改为 `((fen || 0) / 100).toFixed(2)`。

### 预防
- 严禁内联 `(fen / 100)` 硬编码
- Code review 加入价格格式化检查项

---

## 经验：back-forth 联动缺失 — 商户活动创建未关联已有商品（2026-06-06）

### 场景
商户创建秒杀/团购/优惠券活动时，无法选择店铺已有商品。活动创建与原商品库完全割裂。

### 根因
`merchant-activity/create.vue` 从未接入 `merchantProduct.ts` 的商品列表 API。

### 解决方案
新增双模式创建：新建商品 ｜ 选择已有商品。选择已有商品时调用 `api.listSpus(shopId)` 列出在售商品，选中后原价锁定不可修改，活动价由商户自由设置。`typeConfigJson` 包含 `spuId`/`productTitle`/`marketPriceCent`。

### 预防
- 功能设计时检查 `A 系统 → B 系统` 的联动是否已打通
- 商户端任何与"商品"相关的功能都应与 `merchantProduct` 系统互查

