# Flyway 整理与重置

在三个全栈研发并行、累计 111 个 migration 文件（含 10 个 repair 脚本）后，对 Flyway 迁移做一次整理和重置。本文档说明从决策到执行的完整操作流程。

---

## 1. 何时需要整理

| 状态 | 建议 |
|------|------|
| migration 文件 50–150 个，并行碰撞可控 | **不需要整理**。Spring Boot 启动增加 ~1–3s，可接受 |
| migration 文件 >200 个，或合入经常撞号 | **可整理一次**。重置后续版本体系 |
| 本地开发库频繁冲突，影响效率 | **建议整理**。DROP DATABASE 是最低成本路径 |
| 生产环境 | **不建议整理**。111 个文件对生产无影响 |

**当前状态**：111 个文件。号段制 + gap buffer 已运行良好，后续新 migration 碰撞概率低。整理不是必须的，但如果希望清理历史、重置版本体系，可以按以下步骤操作。

---

## 2. 整理后的效果

整理后仓库结构：

```
backend/src/main/resources/db/migration/
├── archived/                  # 旧的 migration 文件（保留供追溯）
│   ├── V1__init_multi_tenant_tables.sql
│   ├── V2__init_tenant_trade_core_tables.sql
│   ├── ...
│   └── V3002__shop_dynamic_type.sql
├── V1__squashed_baseline.sql  # 合并后的 baseline
└── V1000__...                 # 保留当前开发分支的新 migration
```

仓库里保留 `archived/`（git 可追溯原文），仅 `V1__squashed_baseline.sql` 在 Flyway 加载路径中。

---

## 3. 核心原则

1. **整理不是必须的** — 不影响功能，仅降低文件数量和启动时间
2. **整理不涉及数据迁移** — 数据库表结构不变，只改 migration 文件的组织方式
3. **整理后继续用号段制** — 甲 1000–1999，乙 2000–2999，丙 3000–3999 不变
4. **已应用到共享库/生产的 migration 文件禁止删除** — 必须保留 `archived/` 供 checksum 追溯
5. **`archived/` 不在 Flyway 加载路径**中，不会被执行

---

## 4. 操作流程

### 4.1 本地开发库（个人 Docker / local MySQL）

由脚本 `scripts/flyway-squash-local.sh` 自动执行（`make flyway-squash`）：

```
第 1 步：归档旧 migration 文件 → backend/src/main/resources/db/migration/archived/
第 2 步：合并所有非 repair 的 DDL 为 V1__squashed_baseline.sql
第 3 步：DROP DATABASE + CREATE DATABASE（本地数据全丢！）
第 4 步：启动应用，Flyway 自动应用新的 V1 baseline
```

脚本已包含：
- 自动检测数据库名（从 `application-local.yml` 读取）
- `--dry-run` 预览模式
- 执行前二次确认（需输入数据库名确认）
- 自动排除 repair / rollback 脚本

**执行**：

```bash
# 先 commit/push 所有改动
git status                          # 确认干净
make flyway-squash                  # 执行 squash
# 然后在新终端启动应用
make dev-backend                    # 观察 Flyway 日志
```

验证成功的标志：
```
FlywaTarget  : Migrate
Action       : Success
Version      : 1 (squashed_baseline)
```

### 4.2 共享开发库（多人共用）

**不能 DROP DATABASE**。需要分步操作：

```bash
# 第 1 步：在 PR 中提交归档 + V1 代码
# 审批合入后，部署到共享 dev 环境

# 第 2 步：在共享 dev 库执行 flyway repair（让 Flyway 接受 checksum 变化）
cd backend
mvn flyway:repair \
  -Dflyway.url=jdbc:mysql://<host>:3306/kangdou \
  -Dflyway.user=<user> \
  -Dflyway.password=<pass>

# 第 3 步：启动应用，观察 migration 日志
```

**注意事项**：
- 执行前通知同组人员暂停操作
- repair 只更新 `flyway_schema_history` 的 checksum，不修改数据
- 如果 repair 后启动仍有 migration 错误，按 `docs/dev/flyway-repair-schema-history-corruption.md` 排查

### 4.3 预发布 / 生产环境

**不建议整理**。如确需操作：

1. 申请维护窗口（业务低峰期）
2. 参考 §4.2 共享库步骤，逐个环境执行
3. 每个环境执行后验证关键链路
4. 先灰度一个环境，观察 24h 后再操作其他环境

---

## 5. 整理后的版本号体系

整理前：
```
V1 V2 ... V75  V1000-V1019  V3000-V3002   ← 新旧混杂，版本号不连续
```

整理后：

| 版本范围 | 说明 |
|----------|------|
| V1 (squashed_baseline) | 所有历史的 DDL 合并到此文件 |
| V1000–V1999 | 甲号段（继续使用） |
| V2000–V2999 | 乙号段（继续使用） |
| V3000–V3999 | 丙号段（继续使用） |

**号段制完全不受影响**。`make flyway-next` 继续返回号段内版本号 + gap buffer。新 migration 从 V1000、V2000、V3000 开始接续——因为这些文件在 squash 过程中没有被归档（如果这些号段内有未合入的 feature 分支文件），或者已经从归档中恢复。

**如果所有文件都被归档了**（即整理时没有进行中的 feature 分支），新 migration 从号段内最小值开始：
- 甲：V1000
- 乙：V2000
- 丙：V3000

**如果整理时 feature 分支文件需要保留**：
```bash
# 从归档中恢复当前分支的 migration 文件
cp backend/src/main/resources/db/migration/archived/V10XX__*.sql \
   backend/src/main/resources/db/migration/
# 确认版本不冲突后 commit
```

---

## 6. 将 squash 纳入团队工作流（可选）

如果决定定期整理（如每 200 个 migration），可以建立以下节奏：

```
第 1 天：合并 squash PR（归档旧文件 + V1 baseline）
第 2 天：
  - 本地：跑 make flyway-squash
  - 共享 dev：跑 flyway repair → 重启验证
第 3 天：其他环境逐级 repair
第 4 天：观察，无问题则关闭维护窗口
```

--- 

## 7. 参考文档

| 文档 | 内容 |
|------|------|
| `scripts/flyway-squash-local.sh` | 本地库自动 squash 脚本（DROP DATABASE） |
| `.agents/commands/flyway-squash.md` |  `/flyway-squash` 命令（含完整手册） |
| `docs/dev/flyway-multi-dev-playbook.md` | 三人号段制 + gap buffer 协作策略 |
| `docs/dev/flyway-repair-schema-history-corruption.md` | checksum / schema_history 损坏修复 |
| `docs/dev/kangdou-flyway-new-migration.md` | 新建 migration 规则（agent 自动加载） |
