# KangDou Flyway 迁移规范（v3 — 秒级时间戳版本号）

从 2026-06-06 起所有新 Flyway 迁移使用**时间戳版本号**，废弃旧的三人号段制（甲 1000/乙 2000/丙 3000）。
自 2026-06-11 起格式升级为**秒级时间戳** `V{YYYYMMDDHHmmss}`（原 `V{YYYY}{MMDD}{NN}` 日期+序号格式停止使用，已创建文件不重命名）。

---

## 1. 版本号格式

```
V{YYYYMMDDHHmmss}__{英文下划线描述}.sql
```

| 段 | 说明 | 示例 |
|---|------|------|
| `YYYY` | 年份 | `2026` |
| `MM` | 月份 | `06` |
| `DD` | 日 | `11` |
| `HHmmss` | 时分秒（24h，本地时区） | `185900` |

**示例：**

```
V20260611185900__create_merchant_frozen_ledger.sql   ← 2026年6月11日 18:59:00 创建
V20260611190530__add_user_phone_index.sql            ← 2026年6月11日 19:05:30 创建
V20260612091215__seed_permissions.sql                ← 2026年6月12日 09:12:15 创建
```

### 规则

- **14 位纯数字时间戳**（年4 + 月2 + 日2 + 时2 + 分2 + 秒2）
- 用**创建那一刻**的时间戳命名，**无需序号、无需预约号段**——时间戳天然全局唯一
- **描述使用英文**，单词间下划线分隔
- 同一秒内创建多个迁移概率极低；若需在同一秒内连续创建，第二个等待 1 秒后取新时间戳即可

---

## 2. 历史迁移（已有文件）

2026-06-06 之前的 120 个迁移已整体更名为 `V2024{原版本号5位}__{描述}.sql` 格式：

```
# 旧格式                    # 新格式
V1__init_multi_tenant.sql → V202400001__init_multi_tenant_tables.sql
V1000__create_alert_rule  → V202401000__create_alert_rule.sql
V2001__create_exam_...    → V202402001__create_exam_question_bank.sql
V3887__set_shop38_industry → V202403887__set_shop38_industry.sql
```

**不要修改**这些历史文件的版本号或内容。新迁移全部按 §1 格式。

---

## 3. 新建迁移步骤

### Step 1 — 创建文件

```bash
touch backend/src/main/resources/db/migration/V$(date +%Y%m%d%H%M%S)__your_description.sql
```

文件名即创建时刻的时间戳，**无需查当天已有序号、无需预约**。

### Step 2 — 查库确认

```sql
SELECT version, description, script, success, installed_on
FROM flyway_schema_history
WHERE success = 1
ORDER BY installed_rank DESC
LIMIT 15;
```

确认：
- ✅ 所选版本号不存在于已执行记录
- ✅ 无 checksum 冲突

### Step 3 — 验证

```bash
mvn validate        # 校验文件命名正确
mvn -q compile      # 编译通过
```

---

## 4. 常见规则

| 场景 | 做法 |
|------|------|
| **多人同日创建迁移** | 各用各自创建时刻的时间戳，秒级精度天然不同，无需协调 |
| **合入顺序与创建顺序不同** | Flyway 按版本号排序执行，不受合入顺序影响。`out-of-order: true`（dev 默认开启）允许补跑低版本 |
| **修改已合入的迁移** | **禁止**。修正用新迁移文件 |
| **删除迁移文件** | 仅删除未在任何库执行过的文件；已执行的须在 `flyway_schema_history` 中标记 `type='DELETE'` |
| **两个分支同一天各加一个迁移** | 分支A: `V20260611185900`，分支B: `V20260611190530`。版本号天然不同，无冲突 |
| **同一秒内创建两个迁移** | 极低概率；第二个等 1 秒后重新取时间戳即可 |
| **`mvn clean` 再打包** | 重命名或删除迁移文件后必须 `mvn clean package`，避免 `target/` 残留旧文件 |

---

## 5. 废弃的内容

以下旧文档的内容不再适用，以本文为准：

| 旧文档 | 废弃原因 |
|--------|----------|
| `flyway-multi-dev-playbook.md` §3（三人号段制） | 时间戳版本号不再需要号段 |
| `flyway-segment-assignments.json` | 无需解析号段映射 |
| `kangdou-flyway-new-migration.md` 中所有号段相关 step | 改为本文 Step 1~3 |
| `make flyway-next` / `make flyway-reserve` 等号段脚本 | 不需要预约版本号 |

保留的有用经验（已收入本文 §4 或仍可参考）：

- `flyway-repair-schema-history-corruption.md` — 历史表损坏修复
- `flyway-squash-and-reset.md` — 迁移文件整理
- `ops-auth-flyway-mysql-lessons.md` — MySQL 字符集、checksum 等

---

## 6. 修订记录

| 日期 | 说明 |
|------|------|
| 2026-06-06 | 初版。废弃号段制，改为时间戳版本号；120 个历史迁移已统一重命名 |
| 2026-06-11 | 经验：已执行迁移重命名需联动更新 flyway_schema_history |
| 2026-06-11 | 格式升级：`V{YYYY}{MMDD}{NN}`（日期+序号）→ `V{YYYYMMDDHHmmss}`（真时间戳）。秒级精度天然唯一，彻底去掉当日序号与号段脚本 |

---

## 经验：已执行迁移文件重命名

### 场景
旧格式迁移文件 `V3993__xxx.sql` 需重命名为项目规范 `V202403993__xxx.sql`，但该迁移已在生产环境执行过。

### 根因
Flyway 通过 `flyway_schema_history.version` 列匹配迁移文件。仅重命名磁盘文件而不更新 DB 记录，会导致：
- Flyway 找不到旧版本 → 认为 `V3993` 被删除 → 校验失败
- 新文件名 `V202403993` 未在历史表中 → 当作新迁移重复执行

### 解决方案

1. 重命名磁盘文件：
```bash
mv V3993__xxx.sql V202403993__xxx.sql
```

2. 在**每个环境**的 MySQL 执行 UPDATE：
```sql
UPDATE flyway_schema_history
SET version = '202403993',
    description = 'add tenant user circle profile privacy'
WHERE version = '3993'
  AND description LIKE '%circle profile privacy%';
```

3. **开发环境**若该迁移从未执行过，则无需 UPDATE——重命名后的文件会在下次启动时自动作为新迁移执行（前提：迁移内容幂等，使用 `information_schema` 检查列是否存在）。

### 预防
- 重命名前先查询各环境 `flyway_schema_history` 确认执行状态
- 生产 UPDATE 前先 SELECT 确认记录数和 checksum
- 迁移内容始终使用幂等写法（`IF NOT EXISTS` / `information_schema` 检查）
