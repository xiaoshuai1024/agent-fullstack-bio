---
name: kd-review-exit-gate-red-yellow-separate
description: kd-review 退出门禁 — 🔴 连续 2 轮零 + 🟡 连续 3 轮零，分开计数
metadata:
  type: feedback
---

kd-review 的终止条件采用 🔴/🟡 分离计数：

- **🔴 阻断**：连续 2 轮零即可收敛（阻断修复明确）
- **🟡 主要**：需要连续 3 轮零才收敛（主要问题偏设计/质量，需要更多验证）
- 🔴 和 🟡 分开计数，互不影响
- 退出条件：`red_continuous >= 2` **且** `yellow_continuous >= 3`
- 至少 1 轮必须是全量审查
- 🔵 建议不影响终止判定
- **文件级追踪**：`manifest.json` 中每个文件维护 `consecutiveClean`，连续两轮零问题的文件下一轮可跳过审查

**Why:** (1) 阻断问题修复明确，2 轮足够确认；(2) 主要问题修复依赖判断，需要 3 轮；(3) 问题类型分开计数，一次 🟡 不会清零 🔴 进度；(4) 文件级 `consecutiveClean` 避免同一文件反复审查浪费 token

**How to apply:** 维护两个独立计数器。每轮汇总后：有 🔴→red=0，无🔴→red+1；有 🟡→yellow=0，无🟡→yellow+1。同时更新 `manifest.json.fileStates` 中每个文件的 `consecutiveClean`。两者都达标才退出。文件 `consecutiveClean >= 2` 时可跳过审查。

---

## 经验：合并大分支后的 kd-review — 700+ 文件如何有效收敛

### 场景
合并 `feature/global-search` 分支后 `/kd-review`，`git diff master...HEAD` 显示 707 个 Java 文件 + 运营后台文件。按标准 ~20 bucket × 35 文件每个 agent 放不下。

### 根因
分支名称是 `feature/global-search` 但实际合并了多个特性（joint-card、CPS、配送、圈子、达人），每个特性都有独立的大量 commit。标准的 ~20 agent 全覆盖策略在超大规模合并场景下 agent context 超限。

### 解决方案
1. **优先级分层**：Controller/Service/Repository > Entity/DTO/Config > 测试 > 脚本
2. **文件聚焦**：每 agent 3-16 个最关键文件（而非试图覆盖所有），重点覆盖写操作路径
3. **两轮快收敛**：R1 13 agent 全覆盖 → R2 4 agent 增量修复 → R3+ grep 验证（不再启动 agent）
4. **R1 发现 47🔴 中**，36 项可在 2 轮内修复，剩余 11 项为设计级变更（需单独方案，不阻断合并）
5. **审查深度与广度的 tradeoff**：Controller 安全（RBAC/XSS/租户）和 Service 事务（FOR UPDATE/幂等/并发）优先于 DTO 命名、测试覆盖度

---

## 经验：kd-review 跨层审查 — 首页重新设计

### 场景
对首页重新设计的 18 个文件执行 kd-review（后端 4 + 前端 4 + 运营后台 7 + 跨层 3）。

### 根因
前后端各由不同 agent 开发，类型契约容易不一致（如 `orderCount` vs `salesCount`、`mainImageUrl` vs `coverUrl`、`id` String vs number）。

### 解决方案
1. **6 个并行审查 agent**（后端端点 + IT + 前端组件 + index.vue + 运营后台 + 跨层契约）
2. **Streaming 修复**：审查结果一到就派修复，不等待全部完成
3. R1 发现 **14🔴 + 42🟡** → 5 个并行修复 agent → R2 全部清零
4. 跨层审查 agent 发现的关键问题：前后端字段名不一致、SQL 租户隔离遗漏、订单双算

### 预防
- 涉及前后端契约时，必须包含跨层审查 agent
- 前后端 API 类型定义后先交叉比对再写消费代码
- 需要运行 `mvn -q compile` + `pnpm run build:mp-weixin` 双重验证

### 预防
1. 合并后审查前，先 `git diff --stat` 了解总变更量
2. 若 >300 文件，采用分层策略：先审 Controller/Service，再审关键 Repository，最后 Flyway
3. 修复 round 用 worktree isolation 隔离，修复后 grep 验证比重新启动审查 agent 效率高 5-10x
4. 设计级 🔴 问题（如 DriverAuth 系统、settlement_batch 重设计）标注为"需单独方案"，不在此流程中阻塞

---

## 经验：design token 系统 kd-review 四类高频问题

### 场景
kd-review R1 并行 4 agent 审查 design token 系统（14 个前端文件），发现 5 个 🔴 阻断问题、
6 个 🟡 主要问题、5 个 🔵 建议。

### 高频问题模式

| 类别 | 典型问题 | 根因 | 修复 |
|------|---------|------|------|
| **CSS 选择器作用域** | `page.kd-theme-dark` 不匹配 `<view>` 元素 | 小程序中 `page` 是宿主容器，Vue 只能绑 `<view>` | 双选择器 `page.kd-theme-dark, .kd-theme-dark` |
| **JSON 引用未解析** | `{alias.color.surface.value}` 在 CSS 中保留为占位符 | 引用路径 `color.surface` 与 alias 扁平 key `surface` 不一致 | 引用路径必须与 JSON 结构完全对应 |
| **toKebab 命名漂移** | `font2xl` → `font-2-xl`（多一 `-`） | 正则 `(\d)([a-z])` 误在数字后插 `-` | 只保留 letter→digit 边界 |
| **硬编码颜色** | settings.vue 11 处 `#hex`、MineSupportFooter 2 处 | 新建页面未遵循 token 规范 | 改为 `var(--kd-*)` token 引用 |
| **init() 时序** | settings 页先亮后暗 FOUC | pinia store 惰性初始化，首次渲染后 `mode` 才更新 | `onMounted → themeStore.init()` 同步读取 |
| **环境光暗色** | `::before` 亮色光斑在暗色下刺眼 | KdPageShell 伪元素无暗色覆盖 | `.kd-theme-dark .kd-page-shell::before/after` |

### 关键教训

1. **小程序和 H5 的 CSS 选择器模型不同**：H5 可以 `document.querySelector("page")` 动态加 class，
   小程序 `<page>` 是黑盒容器，所有 class 操作必须落在 `<view>` 上，CSS 选择器需双写兼容
2. **生成的 CSS 每次 build 后 grep 检查**：`grep '{' variables.css` 发现未解析占位符；
   `diff <(old vars) <(new vars)` 发现命名漂移
3. **JSON token 引用是字符串，无编译时校验**：依赖 build 脚本的 `inlineRefs` 正确性，
   必须在引用和定义两端保持命名空间一致（扁平引用扁平，嵌套引用嵌套）
4. **kd-review 并行 agent 全量扫描效率高**：4 agent 并行审查 14 文件，6 分钟完成首轮

### 预防
1. build:tokens 后执行 `grep '{' generated/variables.css` 确认无未解析占位符
2. 定期执行 `check-design-tokens.mjs --all` 扫描硬编码颜色
3. 每次添加 CSS class 选择器时评估小程序兼容性（能否匹配 `<view>`？）

见 `.agents/commands/kd-review.md` 终止条件节。

---

## 经验：分离门禁计数（review 收敛条件通用模式）

🔴/🟡 分离计数的终止条件可复用于任何 review 系统：

- 🔴 阻断修复明确 → 连续 2 轮零即可收敛
- 🟡 主要偏设计/质量 → 需要连续 3 轮零
- 各自独立计数，互不影响
- 首轮强制全量审查，后续可增量

---

## 经验：kd-review 单轮全量收敛 — 19 issue 循环直到零

### 场景
对前端 loading/骨架屏 + design token 实现执行 `/kd-review`。首轮 4 agent 并行探索（前端 + 运营后台各两个方向），发现 6🔴 + 8🟡 + 5🔵 = 19 个问题。用户要求"所有红色黄色蓝色问题都修复，不要停下来询问"。

### 执行策略
1. **探索阶段**：4 个 Explore agent 并行（前端 loading、前端 token、运营 loading、运营 token），覆盖 4 个代码库区域
2. **修复阶段**：按 P0→P1→P2 优先级依次修复，每项修复后无需单独审查轮
   - P0 (6 issues)：broken imports、duplicate CSS、dead dependency → 并行 Edit
   - P1 (8 issues)：glassmorphism、composable、CSS naming → 创建新组件/文件
   - P2 (5 issues)：KdSkeleton 迁移、token 同步 → 批量代码修改
3. **验证阶段**：两项目构建 + 测试验证，无新增编译错误

### 关键教训
1. **单轮收敛可行的条件**：问题边界清晰（仅 loading/token 两个主题）、探索充分（4 agent 全覆盖）、自动修复为主（无设计决策阻塞）
2. **不适合单轮收敛的场景**：设计级变更（如"运营后台加 token 体系"）、跨团队决策、需要产品确认的 UX 变更
3. **探索 agent 输出质量决定修复效率**：agent 给出文件路径 + 行号 + 代码片段，修复只需精确 Edit，无需二次定位
4. **并行度最大化**：独立 Edit 操作可以一次发送多个（本 session 最多一次发送 9 个 Edit）
5. **build:tokens 管线修复后 ensure:tokens 自动保持同步**：每次 dev/build 前执行 `ensure:tokens.mjs`，检查 JSON 源是否比 generated/ 新，自动增量构建

### 预防
1. 审查前用 `grep` 预检（如 `grep -r "loading-spinner" --include="*.vue"` 可快速发现重复 CSS）
2. 修复顺序：先解决阻断性问题（编译错误、缺失文件），再做代码质量改进
3. 每次 `build:tokens` 后检查 JSON → CSS 的值一致性

---

## 经验：kd-review R1 全量审查后修复→编译→测试收敛工作流

### 场景
在 `feature/global-search` 分支执行全栈 kd-review：10 个并行审查 agent 发现 24🔴 + 79🟡 + 78🔵，然后 5 个并行修复 agent 分模块修复。修复后必须经过编译门禁 + 全量单测验证才能算收敛。

### 根因
1. 修复 agent 在独立上下文中修改代码，编译验证是唯一可靠的质量门禁
2. 用户合并代码可能引入额外编译问题（本次遇到：JdbcTemplate 升级导致 10+ 测试文件 `ambiguous query`，`Map.of()` 超 10 对参数，`pages/index/index.vue` 合并冲突缺 `};`）
3. linter 会自动修正 `any()` → `any(ResultSetExtractor.class)` 等类型问题，修复 agent 应依赖 linter 而非手动猜测

### 解决方案

**修复 agent 完成后的标准流程：**
```bash
# 1. 后端编译验证
mvn -f /Users/john/codes/kangdou-fullstack/backend/pom.xml -q compile

# 2. 前端编译验证
cd /Users/john/codes/kangdou-fullstack/frontend && pnpm run build:mp-weixin

# 3. 运营后台编译验证
cd /Users/john/codes/kangdou-fullstack/operation-backend && pnpm run build-only

# 4. 全量测试（清理缓存后重跑）
mvn -f /Users/john/codes/kangdou-fullstack/backend/pom.xml clean test
```

**测试 mock Redis Answer 模式（CopyOnWriteArraySet → Redis 后测试适配）：**
```java
private final Set<String> redisBacking = new HashSet<>();

@BeforeEach
void setUp() {
    when(setOps.add(eq(REDIS_KEY), any())).thenAnswer(inv -> {
        Object arg = inv.getArgument(1);
        if (arg instanceof String s) { redisBacking.add(s); return 1L; }
        if (arg instanceof String[] arr) { for (String w : arr) redisBacking.add(w); return (long) arr.length; }
        return 0L;
    });
    when(setOps.remove(eq(REDIS_KEY), anyString())).thenAnswer(inv -> {
        redisBacking.remove(inv.getArgument(1)); return 1L;
    });
    when(setOps.members(REDIS_KEY)).thenAnswer(inv -> Set.copyOf(redisBacking));
    when(redisTemplate.delete(REDIS_KEY)).thenAnswer(inv -> { redisBacking.clear(); return 1L; });
}
```

### 预防
1. 编译失败时先用 `mvn clean` 清除缓存再试，避免 stale .class 文件误导
2. linter 修改文件后先读再写（`Read → Edit`），确认当前状态
3. 修复 agent 完工后必须更新测试文件适配新实现，否则后续合并会覆盖修复

---

## 经验：kd-review 大规模并行审查 — 320 文件 8 agent 全量收敛

### 场景
对 `feature/platform-gap-fill` 分支执行 kd-review，变更覆盖 320+ 文件（后端 120+、运营后台 180+、前端 20+）。使用标准 ~20 bucket 策略，但实际按模块聚焦为 8 个窄范围 agent。

### 根因
1. 后端变更分散在 15+ 个 package（ops、tenant、search、analytics、masking 等），每个 package 审查关注点不同
2. 运营后台涵盖 API 层、路由、20+ 视图、E2E 测试，需要多个特化 agent
3. 🔴 安全问题（缺少 @RequirePerm、SQL 注入、WebSocket 无认证）分布在多个文件中

### 解决方案

**组织策略：**
```
8 个并行审查 agent × 各自 worktree isolation
    │
    ├── 后端 Ops 控制器 (27 files) → 发现 4🔴 + 8🟡 + 8🔵
    ├── 后端 Search+Analytics (30+ files) → 发现 6🔴 + 12🟡
    ├── 后端 Flyway+Tests (12 SQL + 19 test files) → 发现 3🔴
    ├── 运营 API+路由 (10 files) → 发现 3🔴 + 5🟡
    ├── 运营 Feature+Analytics 视图 (8 files) → 发现 2🔴
    ├── 运营 Marketing+Notification (20+ files) → 发现 5🔴
    ├── 运营其余视图 (25 files) → 发现 3🔴
    └── 运营 E2E 测试 (6 files) → 发现 4🔴
```

**Streaming 修复策略（结果一到就派发）：**
```
审查结果 ├→ 第1批修复: Ops 控制器 🔴 问题 (4 issues)
        ├→ 第2批修复: Search+Analytics 🔴 (5 issues)  
        ├→ 第3批修复: Flyway COLLATE + 中文显示 (3 SQL + 3 Vue)
        └→ 第4批修复: API 路由泛型 (5 TS files)
```

**验证门禁链（每批修复后执行）：**
```bash
# 后端
mvn -q compile -DskipTests          # 编译验证
mvn test -Dexec.skip=true           # 全量单测

# 运营后台
pnpm run build                      # 构建验证
pnpm test                           # 全量测试
```

**关键发现：**
- **修复 agent 常见遗漏**：添加依赖后不更新测试构造器（`TenantAdminService` 加 `OpsAuditService` 但 `TenantAdminServiceTest` 未适配）
- **worktree 变更合并**：agent 在 worktree 中修改，完成后需手动合并回主仓（`cp` 或 `ExitWorktree`）
- **tmpfs 空间耗尽**：多个 agent 并行产生大量 task output 文件，临时 filesystem 可能跑满，需定期清理

### 修复统计

| 轮次 | 审查 agent | 修复 agent | 🔴 发现/修复 | 🟡 发现/修复 | 验证结果 |
|:----:|:----------:|:----------:|:------------:|:------------:|:--------:|
| R1 | 8 | 4 | 13/13 | 15/15 | `mvn test` BUILD SUCCESS |
| R2 | 0 (增量验证) | 0 | 0 | 0 | 1144 tests passed |

### 预防
1. 🔴 修复后必须检查测试文件是否同步更新（新依赖 → 新 mock 参数）
2. 每个修复 agent 完成后在主仓执行 `git diff --stat` 确认变更已合并
3. 并行 agent 过多时检查 tmpfs 余量（`df -h /private/tmp`）
4. 修复验证用 `grep` 确认修复到位后再跑全量测试（速度提升 5-10x）
5. 修复顺序：安全（@RequirePerm/SQL注入）> 数据（脱敏）> 审计 > 代码质量 > 测试

### 场景
在方案阶段对设计文档（.md）进行 `/kd-review`，而非对已实现的代码 diff。方案文档无 branch diff，无法按文件 bucket 拆分，且修复是在同一文档上 Edit（不能并行 worktree）。

### 根因
kd-review 的标准流程为代码审查设计（~20 个 bucket 并行、worktree 隔离、streaming 修复、文件级 `consecutiveClean` 追踪）。但方案文档是单体 Markdown，不能按文件拆分，修复也不能并发。

### 解决方案
**Round 1（全量多维度并行审查）：**
- 拆分为 6 个维度 agent：架构设计、数据模型、安全合规、性能缓存、可维护性、API+前端设计
- 每个 agent 审查整个方案的对应维度，互不冲突
- 全部并行启动（`run_in_background: true`）

**Round 2+（增量修复+再审）：**
- 主会话串行修复（同一文件不能并发 Edit）
- 修复完成后启动 1-4 个 agent 验证修复项
- 被验证通过的维度可以合并审查

**收敛条件（同代码审查）：**
- `clean_continuous >= 3`（连续 3 轮零 🔴 且零 🟡）
- Round 1 和 Round 4（或每 5 轮）做全量审查
- 中间轮次可做增量验证（针对上一轮有问题的维度）

**关键差异：**
| 维度 | 代码审查 | 方案文档审查 |
|------|---------|------------|
| 审查单位 | 按文件 bucket | 按维度（数据模型/安全/API...） |
| 修复方式 | 并行 worktree agent | 主会话串行 Edit |
| 状态追踪 | `fileStates.consecutiveClean` | 手动跟踪维度级状态 |
| 收敛轮次 | 典型 5-7 轮 | 典型 5-6 轮（本案例 6 轮收敛） |

### 预防
- 方案文档审查 agent prompt 中明确标注 "审查设计方案文档" 和具体维度，避免 agent 去读代码库文件
- 修复后立即重写 `.kd-review/round-N.jsonl` 记录状态
- 第 4 轮做全量终审（防止增量审查产生盲区）
- 方案通过后再进入代码实现阶段
---

## 经验：模块04 统一活动引擎 kd-review 收敛（2026-06-05）

### 审查范围
`frontend/src/pages/activity/` 9 个页面 + `frontend/src/api/activity.ts` + 2 个 E2E 测试文件 = 12 个文件。

### 收敛过程

| 阶段 | 审查 agent | 修复 agent | 发现 | 结果 |
|------|:--------:|:---------:|------|------|
| R1 上一轮（6/4） | 6 | 4 | 🔴43 🟡42 🔵22 | 全部修复 |
| R1 本轮（6/5） | 4 | 4 | 🔴17 🟡16 🔵12 | 全部修复 |
| R2 H5 E2E | — | — | 2 断言回归 → 微调 | 45/45 ✅ |

### 本轮发现的高频问题模式

| 类别 | 典型问题 | 根因 | 修复模式 |
|------|---------|------|---------|
| **假数据** | 头像墙硬编码8个中文姓、settlement 5个假用户、flash-detail soldCount=315 永远不变 | 后端 API 未返回值时前端用硬编码 fallback | 改为 computed 从 API 动态取值，无数据时隐藏或显示 `?` 占位 |
| **状态映射不一致** | STATUS_LABEL 3个文件各不同（4 vs 7 状态）、statusBg 只有3分支 | 文件独立开发未同步 | 全部统一为7状态 Record map |
| **价格格式不一致** | list.vue 用 `/100` 无 `.toFixed(2)`，detail/enroll/team 用 `.toFixed(2)` | 无共享工具函数 | 统一为 `.toFixed(2)`，建议后续提取共享 `fenToYuan()` |
| **表单验证缺失** | submitForm 只检查 title；NORMAL 类型无表单字段；数字输入无 NaN 防护 | 开发优先级 | 补全验证 + safeNum 辅助函数 + 防重复提交 |
| **E2E 零断言** | 8 个测试只有 console.log、4 个 OR 覆盖永远为真 | 快速开发忽略断言质量 | 逐条补 expect()，新增 APPROVAL(E5) |
| **@known-missing 滥用** | 5 项标记为缺口但实际可补齐 | 未区分前端可修复 vs 后端依赖 | A6/A7/C7/C9/D3 全部补齐源码 + E2E |

### 新增审查维度（建议所有 kd-review 包含）

1. **假数据检测**：grep 所有 `ref([{` / `ref({` 带中文/硬编码数值的初始化
2. **跨文件一致性**：STATUS_LABEL/statusBg/fenToYuan 在一组页面文件中 grep 对比
3. **E2E 断言质量**：grep `expect(true).toBe(true)` / 零 expect 测试 / 永远为真的断言
4. **@known-missing 存量**：逐条验证是否可补齐，区分"前端UI缺口" vs "后端API缺口"

### 收敛指标
- 累计修复：🔴 60 🟡 58 🔵 34
- 最终 H5 E2E：45/45 ✅（5 个 `@known-missing` 全部转正）
- 文档覆盖：e2e-prompts 04 模块 38/38 全覆盖

---

## 经验：多租户 SQL 审查 — 每个 JOIN 必须包含 tenant_id（2026-06-06）

### 场景
kd-review 审查 `RecommendationEngine.java` 时发现 3 处 SQL 查询缺少 `shop.tenant_id = ?` 过滤，导致跨租户数据泄露——一个租户可以看到其他租户的商品推荐。

### 根因
`doRecommend()`、`coldStartRecommend()` 和 pinned product lookup 三处查询都在 `LEFT JOIN shop ON shop.id = s.shop_id` 中忽略了 `tenant_id` 条件。项目既有模式（`TradeCatalogService.java`）使用 `INNER JOIN shop sh ON sh.id = sp.shop_id AND sh.tenant_id = ? AND sh.delete_time = 0`。

### 修复
```java
// 每个 JOIN 添加 tenant_id 和 delete_time
LEFT JOIN shop shop ON shop.id = s.shop_id AND shop.tenant_id = ? AND shop.delete_time = 0
```

### 预防
审查 agent prompt 必须包含多租户隔离检查清单：
1. 所有包含多租户实体表的 JOIN 都必须有 `tenant_id = ?` 条件
2. 检查 `queryForList`/`queryForMap` 的 params 数组长度是否与 SQL 中 `?` 数量一致
3. 验证 `tenantId` 方法参数确实被传递到 SQL 参数字面量中（不是只声明不使用）

---

## 经验：kd-review 提交前必须跑通测试（编译通过 ≠ 测试通过）（2026-06-11）

### 场景
联合套卡模块大量功能损坏：
- 后端 `OpsJointCardService.java` 的 270 行并发保护代码（CAS 守卫、FOR UPDATE、参数化 SQL）被 `454614f7`（搜索优化提交）从旧基线覆写删除
- 运营后台 `GovernanceView.vue` 调用 3 个后端从未实现的端点（`on-shelf`/`delete`/`force-cancel`），前端 404
- `scripts/contract-check.sh`（254 行合约检查脚本 + git hooks）被 `83009c2e`（sync changes）误删

kd-review 的 317 项修复（`b67d8480`）加了并发保护和前端调用，但 3 天后全部被冲掉。所有问题都通过了 kd-review 的「编译验证」门禁（`mvn -q compile`），因为编译不检查运行时行为和跨仓一致性。

### 根因
1. **kd-review 只做编译验证不做测试**：修复 agent 完成后只跑 `mvn -q compile` / `pnpm run build`，不跑 `mvn verify` / `pnpm test`。编译通过就自动提交，删掉的代码、调不存在的端点全漏了。
2. **无跨仓合约检查**：kd-review 逐仓审查，前端调后端不存在的端点在前端仓内看不出来。
3. **自动提交无人工审核**：317 项修复一口气提交，个别引入新问题无法逐条拦截。
4. **`contract-check.sh` 被删后无兜底**：删除后没有任何机制检测跨仓契约不一致。

### 修复
1. **kd-review 新增「第 7 步：测试门禁」**（`.agents/commands/kd-review.md`）：
   - 提交前强制执行分层测试：`mvn -q verify` / `pnpm test && pnpm run build` / E2E
   - 跨仓合约检查（`scripts/contract-check.sh` 或内联 API 路径 diff）
   - 任一层失败 → 自动派修复 agent → 最多 3 轮 → 仍失败则中止提交不推送
   - 全程无人工介入，但测试不过禁止提交
2. **恢复并增强 `contract-check.sh`**：
   - 后端路由提取：perl slurp 模式逐文件合并 class `@RequestMapping` + method `@*Mapping`（262→1312 路由）
   - 前端路径提取：新增全量 `.vue`/`.ts` 内联调用扫描 + `${...}` 归一化（157→641 URL）
   - 匹配逻辑：去掉危险的前缀回退（`/api/x/on-shelf` 不再错误匹配到 `/api/x`）

### 预防
- kd-review 提交前必须通过测试门禁（`testGatePassed == true`）
- 修复 agent 增加定向测试层（改了 `XxxService.java` → 跑 `XxxServiceTest`）
- `contract-check.sh` 纳入 git pre-commit hook 和 kd-review 第 7 步
- E2E 为硬门禁，禁止跳过、禁止占位测试
- **关键原则**：`mvn -q compile` 通过 ≠ 代码正确。只有 `mvn -q verify`（含单测+集成测+覆盖率门禁）才能确认代码质量
