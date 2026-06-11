---
description: 全自动审查循环：并行派发 ~20 个窄范围审查 subagent → 结果到达即派修复 → 持续循环直到零问题收敛（🔴 🟡 🔵 全部清零）
---

触发：**`/review`**。

## 工作流

执行自动化审查 → **streaming 修复** → 再审查 → 收敛的循环，直到零问题。

核心思路：将变更拆成 ~20 个窄范围 bucket，**全部同时审查**，**第一个结果回来就立刻派修复**，审查和修复重叠执行，最大限度压缩 wall-clock time。

### 第 1 步：确定审查范围 & 拆分为 ~20 个窄范围 bucket

从上下文或用户输入确定审查对象：

- 若用户给出了具体的路径/功能名，使用之
- 否则默认审查当前分支上最近完成的功能改动（`git diff master...HEAD --name-only`）

然后自动将变更文件分组为以下 bucket，**有变更的才派发，无变更的跳过**：

**后端 (~10 个):**
1. Ops 服务 + 控制器（安全、RBAC、XSS、跨租户）
2. Tenant 服务 + 控制器（C 端 API、校验、分页）
3. Order 服务（事务、并发、幂等、库存）
4. Refund 服务（幂等、FOR UPDATE、优惠券释放、回滚）
5. Verification 服务（核销、TOCTOU、审计日志）
6. Coupon 服务（schema 检测、折扣、释放）
7. Expiry 调度器（批次、分布式锁、索引）
8. IT 测试（覆盖度、fixture 去重、边界用例）
9. 单元测试（mock、架构测试、匹配器）
10. Flyway 迁移（版本顺序、COLLATE、schema 冲突）

**横切 (~3 个):**
11. 搜索集成（ES mapping、native query、字段命名）
12. 配置与部署（pom.xml、docker-compose、ELK pipeline）
13. 横切规范（CLAUDE.md、全局规则、注解一致性）

**前端 (~5 个):**
14. 核心页面（detail、goods-detail、confirm、checkout）
15. 列表与子页面（orders、after-sale、feed、match、center）
16. 商家页面（create wizard、cooperation-detail、verify）
17. API 层 + store（jointCard.ts、jointCardMerchant.ts、Pinia store）
18. E2E 测试 + 单元测试

**运营后台 (~2 个):**
19. Views（governance、settlement、create、detail、dialog）
20. E2E 测试（sidebar、tenant config、search、false green）

若某个 bucket 涵盖大量文件，按以下策略处理以避免 agent context 超限：

- 每个审查 agent 的文件数建议控制在 **1–5 个**，超出则拆分为多个子 agent
- 拆分的子 agent 加入**待办队列**，在当前轮全部 agent 派发后、依序派发后续子 agent
- 在 `round-N.jsonl` 的 `review_start` 事件中记录每个文件的 `status: "pending"`，子 agent 完成后通过 `review_result` 事件标记 `"reviewed"`
- 如果当前轮塞不下（超时窗口不够），**剩余待审文件自动转入下一轮**的首批审查，不丢失不跳过

## 状态文件系统

所有持久化状态存储在项目根 `.kd-review/` 目录中，按分支隔离。会话启动时创建，每轮结束更新。

### 目录结构

```
.kd-review/
├── .gitignore              # 仅保留目录本身（已提交）
├── manifest.json           # 累积总清单（分支隔离）
├── round-001.jsonl         # 每轮状态（append-only JSONL）
├── round-002.jsonl
├── known-issues.json       # 已知问题注册表（🔵 建议去重）
└── reviews/
    ├── review-模块-YYYY-MM-DD-round-N.md
    └── review-模块-YYYY-MM-DD-convergence.md
```

### manifest.json

各轮次累积总清单，分支维度隔离。每轮结束更新 `cumulativeStats`、`convergence`、`rounds` 和 `fileStates`。

```json
{
  "branch": "feature/xxx",
  "sessionId": "<uuid>",
  "createdAt": "2026-05-20T10:00:00Z",
  "totalFiles": 42,
  "cumulativeStats": {
    "🔴": { "found": 3, "fixed": 3 },
    "🟡": { "found": 8, "fixed": 7 },
    "🔵": { "found": 5, "fixed": 1 }
  },
  "convergence": {
    "cleanContinuous": 0,
    "exited": false
  },
  "rounds": [
    { "round": 1, "reviewAgents": 4, "fixAgents": 3, "status": "completed" }
  ],
  "fileStates": {
    "backend/src/.../FileA.java": {
      "status": "fixed",
      "consecutiveClean": 2,
      "lastRoundReviewed": 1,
      "lastRoundWithIssues": null
    }
  }
}
```

#### fileStates 字段

为每个文件维护独立追踪，支持增量审查决策。

| 字段 | 类型 | 说明 |
|------|------|------|
| `status` | pending丨reviewed丨fixed | 当前状态 |
| `consecutiveClean` | int | 连续零问题轮次（>= 2 时可跳过审查） |
| `lastRoundReviewed` | int | 最后一次审查的轮次号 |
| `lastRoundWithIssues` | int丨null | 最后一次发现问题的轮次号（null=从未有问题） |

### round-N.jsonl（单轮事件流，append-only）

JSONL 格式——每行一个独立 JSON 对象，`write` + `flush` 原子追加，无需文件锁。

**事件类型：**

| 事件 | 触发时机 | 关键字段 |
|------|---------|---------|
| `round_start` | 轮次开始 | round, agents, files[] |
| `review_start` | 审查 agent 启动 | agent, bucket, files[] |
| `review_result` | 审查 agent 完成 | agent, bucket, issues[], reviewedFiles[] |
| `fix_start` | 修复 agent 启动 | agent, issueIds[] |
| `fix_result` | 修复 agent 完成 | agent, fixed, fixedFiles[] |
| `round_end` | 轮次结束 | round, stats, convergence |

**reviewedFiles 元素结构：**

```json
{
  "path": "backend/src/.../FileA.java",
  "status": "reviewed",
  "consecutiveClean": 0,
  "issuesFound": 1
}
```

**示例：**

```jsonl
{"type":"round_start","round":1,"timestamp":"2026-05-20T10:00:00Z","agents":5,"files":["OpsController.java","OrderService.java"]}
{"type":"review_result","agent":"ops-001","bucket":"Ops 服务+控制器","timestamp":"...","issues":[{"severity":"🔴","file":"OpsController.java","line":42,"description":"缺少 RBAC 校验","category":"security"}],"reviewedFiles":[{"path":"OpsController.java","status":"reviewed","consecutiveClean":0,"issuesFound":1}]}
{"type":"fix_result","agent":"fix-ops-001","timestamp":"...","fixed":1,"fixedFiles":[{"path":"OpsController.java","status":"fixed"}]}
{"type":"round_end","round":1,"timestamp":"...","stats":{"🔴":{"found":3,"fixed":2},"🟡":{"found":5,"fixed":3},"🔵":{"found":2,"fixed":0}},"convergence":{"cleanContinuous":0}}
```

### known-issues.json

用于 🔵 级别建议的去重——同一建议在不同轮次重复上报时递增 `reportCount` 并更新 `lastReportedAt`，不新增条目。活跃问题在 `expiresAt` 后自动过期。

```json
{
  "issues": [
    {
      "id": "<uuid>",
      "severity": "🔵",
      "description": "方法名称稍长，建议缩短",
      "file": "path/to/File.java",
      "line": 85,
      "firstReportedAt": "2026-05-20T10:00:00Z",
      "lastReportedAt": "2026-05-20T11:00:00Z",
      "reportCount": 2,
      "status": "active",
      "expiresAt": "2026-06-20T10:00:00Z"
    }
  ]
}
```

### 审查 MD 文件

审查 agent 完成时输出结构化审查报告。

- 命名：`reviews/review-{模块}-{YYYY-MM-DD}-round-{N}.md`
- 包含 YAML frontmatter：模块名、轮次、严重性统计
- 问题清单按 🔴/🟡/🔵 分组，每条含文件、行号、描述、建议修复方式

收敛报告（循环终止时输出）：
- 命名：`reviews/review-{模块}-{YYYY-MM-DD}-convergence.md`
- 所有轮次汇总 + 累计修复统计 + 最终状态声明

### 第 2 步：Streaming 派发 — 所有审查 agent 一次性并行启动

使用 `subagent-driven-development` 模式，**一次性并行启动所有有变更的 bucket**：

- 每个 agent **只审查少量文件**（建议 1–5 个），超出则拆分并由 reviewItems 追踪
- 每个 agent **独立工作**（`isolation: worktree`）
- 每个 agent **禁止修改文件**（review only）
- 每个 agent 执行：加载对应技能 + 合同 → 输出结构化报告（按 🔴/🟡/🔵 分级）
- 每个 agent 的 prompt 头部附加 `[effort=max] 已生效：本会话按 max 执行。` 以启用最大推理强度
- 所有 agent **并行启动**（`run_in_background: true`）
- **不等待全部完成** — 进入下一步 streaming 模式

### 第 3 步：Streaming 修复 — 结果到达即派修复 agent（🔴 阻断自动修复）

**关键优化：不要等全部审查完成。** 每个审查 agent 一返回结果就立即处理：

1. 收到结果后 **立即** 解析报告，提取 🔴、🟡 和 🔵 问题
2. **🔴 阻断问题一律直接修复，不询问用户、不等待确认**——包括但不限于：
   - 库存超卖、并发竞态、幂等缺失等数据安全问题
   - 权限缺失（RBAC、XSS）
   - 非法 SQL 引用、编译阻断
   - 任何影响生产正确性的阻断级问题
   - Flyway 迁移冲突（重复/损坏）直接删除冗余版本或增加幂等条件
   - 当修复需要新增 DB 列（如幂等键）时，**同时创建 Flyway 迁移文件**并立即修复代码
3. **🟡 主要问题和 🔵 建议同理直接修复**——无需询问，按审查报告的建议方式修复
4. **立即** 派发一个**修复 agent**（`subagent-driven-development`，`isolation: worktree`）：
   - 包含审查 agent 发现的具体问题清单（文件路径、行号、期望修复方式、验证命令）
   - 🔵 建议按类型聚合为窄 scope 修复 agent（如"前端 CSS 清理"、"后端死代码清理"、"命名统一"、"类型安全加固"），每个 agent 处理 1-5 个同类建议，避免碎片化
   - 修复 agent **禁止修改审查范围外的文件**
   - 修复 agent 的 prompt 头部附加 `[effort=max] 已生效：本会话按 max 执行。` 以启用最大推理强度
5. 多个修复 agent **可同时运行**（各自在独立 worktree 中）
6. **修复与剩余审查重叠执行** — 不等待还在跑的审查

这样 wall-clock time ≈ `max(all reviews) + max(all fixes)`，而非 `sum(reviews) + sum(fixes)`。

### 第 4 步：修复完成后记录

每个修复 agent 完成时：

1. 确认编译通过（或运行指定验证命令）
2. 记录修复摘要（修复了哪些问题、影响范围）
3. 更新 `round-N.jsonl` 中对应文件的 `status` 为 `"fixed"`（追加 `fix_result` 事件）

### 第 5 步：持续循环直到完全收敛（强规则：连续 3 轮零任何问题，🔴 自动修复不询问）

当**本轮所有审查 agent 返回结果** 且 **所有修复 agent 完成** 后：

1. 汇总本轮次的问题统计（🔴+🟡+🔵）
2. **统一计数**：只要本轮有任何一个问题（🔴 或 🟡 或 🔵）→ `clean_continuous` 清零；完全没有问题 → `clean_continuous` +1
3. 更新 `manifest.json`：
   - `convergence.cleanContinuous`
   - 将本轮有问题的文件 `consecutiveClean` 重置为 0，无问题的 +1
4. **退出条件**：`clean_continuous >= 3`
5. **至少 1 轮必须全量审查**：如果所有轮次都是增量审查，即使计数达标也不退出，强制安排下一轮为全量
   - 第二轮起只需重新审查**上一轮出过问题的 bucket**
   - 在 bucket 内部，利用 `fileStates.consecutiveClean` 跳过连续两轮零问题的文件
   - 跨轮去重：相同 bucket 且内部所有文件 `consecutiveClean >= 2` 时跳过该 bucket
   - 但每 5 轮或候选退出轮必须全量一次

### 第 6 步：收敛报告

输出：
- 总迭代轮数
- 每轮派发 agent 数（审查 + 修复）
- 每轮发现问题数（🔴/🟡/🔵）
- 每轮修复问题数
- 累计修复统计
- 最终审查状态（必须是"零问题"）

### 第 7 步：自动提交并推送

收敛条件达成（clean_continuous >= 3 且至少一轮全量审查）后，自动执行提交和推送：

1. **主仓库提交**：
   - 若有未提交的改动，使用 `git add` 暂存所有改动文件
   - 提交消息格式：
     ```
     chore(kd-review): {简单描述改动的业务性质}

     kd-review 收敛结果：{totalRounds} 轮 | 🔴 {fixed} 🟡 {fixed} 🔵 {fixed}
     ```
   - 其中描述从当前分支名和审查上下文推断（如 `global search`、`joint card`）

2. **子模块提交**（若有子模块改动）：
   - 对 `frontend`、`backend`、`operation-backend` 三个子模块分别执行：
     - 检查是否有未提交改动
     - 若有则 `git add -A && git commit -m "chore: kd-review 修复"`（在子模块目录内）
     - `git push origin HEAD:<当前分支名>`
   - 主仓库更新子模块指针：
     - `git add frontend backend operation-backend`（仅对确有提交的子模块）
     - `git commit -m "chore(fullstack): 合并 kd-review 子模块指针"`

3. **主仓库推送**：
   - `git push origin HEAD:<当前分支名>`
   - 若推送失败（远程有新的提交），提示用户并建议 `git pull --rebase`

4. **推送成功后**，在收敛报告中附加：
   ```
   ✅ 代码已自动提交并推送至远端。
   分支：{branchName}
   提交：{commitHash}
   ```

5. **回退机制**：若任一子模块提交或推送失败，记录具体失败原因到状态文件，**不阻塞推送已完成的部分**。在最终报告中列出推送失败的模块供用户手动处理。

### 终止条件（强规则 — 连续 3 轮零 🔴 且零 🟡）

- 🔴/🟡/🔵：只要一轮中有任何一个问题 → `clean_continuous` 归零，循环继续
- **退出条件**：`clean_continuous >= 3`（连续 3 轮没有任何 🔴 和 🟡 和 🔵 问题）
- 🔵 建议不影响终止判定，但应在本轮内处理完毕（认领或关闭）
- **退出条件**：`clean_continuous >= 3`（连续 3 轮没有任何 🔴 和 🟡 问题）
- **至少 1 轮必须是全量审查**（不能全增量通过就退出）
- **禁止提前终止**——未达到上述条件就停止的，视为违反强规则
- **禁止中途暂停询问用户**——整个循环一口气跑完，所有 🔴 问题自动修复，所有决策点（Flyway 冲突、幂等键列等）直接按最佳实践处理
- 连续 10 轮问题总量不减少 → 终止并告警（可能陷入死循环）
- **收敛轮次优化**：
  - 第二轮起只需重新审查**上一轮出过问题的 bucket**
  - 利用 `fileStates.consecutiveClean` 跳过连续两轮零问题的文件
  - 每 5 轮必须全量一次（防止增量审查产生盲区）

## 重要约束

1. 所有审查 agent 使用 `isolation: worktree` 以避免干扰工作区
2. 修复 agent 同样使用 `isolation: worktree`
3. 禁止修改与审查范围无关的文件
4. **审查 agent 永远不修改文件**（review only）
5. **状态文件防并发**：写入 `.kd-review/` 使用 JSONL append-only 模式（每行独立原子写），避免多 agent 同时写同一文件的覆盖问题
6. **E2E 测试不与收敛循环耦合**：E2E 在后台与审查并行运行，结果加入下一轮问题列表。仅在退出（收敛）前跑一次全量 E2E 作为最终确认

## 修复 agent 完成后强制验证

每个修复 agent 完成后，主会话必须执行：

1. 在主仓对修复涉及的项目执行编译验证：
   - 后端改动：`cd backend && mvn -q compile`
   - 前端改动：`cd frontend && pnpm run build:mp-weixin`
   - 运营后台改动：`cd operation-backend && pnpm run build-only`
2. 若编译失败 → 立即派发新的修复 agent，带入编译错误信息
3. **最多重试 3 次**，仍失败则标记为 🔴 阻断问题进入下一轮

## 修复 agent 约束（新增）

修复 agent 的 prompt **必须包含**以下语句：

```
## 修复约束
1. 最小改动原则：只改必须改的，禁止"顺便重构"或"顺手优化"
2. 禁止修改审查范围外的文件
3. 修复后必须在 worktree 内运行对应编译命令验证（后端：mvn -q compile；前端：pnpm run build:mp-weixin）
4. 编译通过后再退出
```

## 与 /super-pm 和 /e2e-archi 的关系

- 每个窄范围审查 agent 内部决定执行 `super-pm`（产品 UX）立场的审查、`e2e-archi`（架构 E2E）立场的审查、或两者兼顾
- 对于 Controller/Service 文件 → 侧重 e2e-archi（事务、安全、测试）
- 对于 Vue/页面文件 → 侧重 super-pm（UX、假功能、原型符合性）
- 对于测试文件 → 侧重 e2e-archi（假绿、覆盖度、纪律）
- 对于 API/类型文件 → 两者兼顾

## 实战经验（2026-05-20 joint card 审查总结）

### 典型收敛时间线

| 轮次 | 策略 | 审查 agent | 修复 agent | 🔴 | 🟡 | clean连续 |
|:----:|------|:--------:|:---------:|:--:|:--:|:--------:|
| R1 | 全量并行 | 21 | 13 | 38 | 110 | 0 |
| R2 | streaming 修复 | 8 | 8 | 14 | 12 | 0 |
| R3 | 增量重审 | 5 | 3 | 1 | 3 | 0 |
| R4 | 修复残留 | — | 3 | 0 | 0 | 1 |
| R5 | 快速扫描 | 3 | 1 | 0 | 0 | 2 |
| R6 | 横切再审 | 2 | 2 | 1 | 0 | 0 |
| R7-R11 | 递增验证 | 1 | — | 0 | 0 | 1→5 |

### 并发限流应对

- **问题**：R1 同时 21 审查 + 13 修复 = 34 agent 并发，部分触发 API 429 限流
- **应对**：
  1. 分批派发：先 10 个审查 → 收集 → 再 10 个 → 收集 → 再启动修复
  2. 修复 agent 设置 `mode: "bypassPermissions"` 减少交互轮次
  3. 限流后重试时优先处理🔴阻断问题，🟡可延后

### worktree 分支隔离陷阱

- **问题**：修复 agent 在 `isolation: worktree` 中修改代码，但主仓（含子模块）仍指向旧提交。后续轮次扫描主仓时看到的是未合并的旧内容，导致误报"未修复"
- **应对**：
  1. 修复 agent 完成后，**必须将 worktree 分支合并回主仓当前分支**
  2. 后续验证轮次直接在主仓执行 `grep`（不依赖 worktree 的文件状态）
  3. 或在修复 agent 中使用 `mode: "auto"` 替代 `isolation: worktree`

### 递增验证轮次策略

- R7-R11 使用"直接 grep 验证"而非"启动 agent 验证"，显著缩短 wall-clock time
- 方法：在主仓直接执行 `grep "pattern" path/ --include="*.ext" | wc -l`，0 即为通过
- 仅当发现非零时才启动修复 agent
- 适合 clean_continuous 的最后几轮快速积累

### 高频问题模式（本次审查发现）

| 类别 | 典型问题 | 根因 | 修复模式 |
|------|---------|------|---------|
| **ID 泄露** | 店铺 ID / 子订单号回退展示 | 缺少 fallback 兜底 | 回退为"未知店铺"等中文 |
| **statusLabel** | 英文枚举 default 分支 | switch 未覆盖所有 case | `default: return '未知状态'` |
| **false green** | `toBeDefined()` / `expect(true).toBe(true)` | 断言太弱 | `toBeTruthy()` + 具体断言 |
| **类型安全** | `Record<string, unknown>` 泛化 | API 层未定义具体类型 | 添加 Response 接口 |
| **价格显示** | 内联 `/100).toFixed(2)` | 无共享工具函数 | 统一 `fenToYuan()` |
| **审计缺失** | 验证失败路径无日志 | 只处理了 happy path | 每个 throw 前记录日志 |
| **库存泄漏** | sold_quantity 无递减 | 只在创建时递增 | 退款成功后递减 |

### 收敛条件演进建议

当前 `clean_continuous >= 5` 要求较严格（11 轮才收敛）。实际经验表明：
- **前 3 轮**（全量审查 + 修复 + 验证）是核心价值所在
- **R4-R6**（修复残留 + 横切再审）确保修复质量
- **R7-R11**（递增验证）更多是形式性保证，实际问题已收敛

建议可考虑将收敛条件改为 `clean_continuous >= 3`，但保留"至少 1 轮全量审查"的硬性要求。

**已采纳**：终止条件已从 `>= 5` 改为 `>= 3`（见上方终止条件章节）。
