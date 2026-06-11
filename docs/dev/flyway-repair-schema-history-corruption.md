# Flyway：`flyway_schema_history` 损坏与失败迁移修复说明

本文针对 `Corrupted schema history: multiple delete entries for version …` 提供操作步骤；**§5** 补充共享库常见故障（`failed migration`、同版本多行、JDBC/SQL 混用）。

## 现象（`multiple delete entries`）

Spring Boot 启动或 `mvn verify` 时在 **Flyway 初始化** 阶段失败，日志或栈中出现：

```text
Corrupted schema history: multiple delete entries for version 51
```

（`51` 仅为示例，实际数字以报错为准。）

## 根因（简述）

自 Flyway 引入带 **`type`** 列的 **`flyway_schema_history`** 后，同一 **`version`** 下 **`type = 'DELETE'`** 的记录**至多应有一条**。若多次执行 **`repair`**、或 `repair` 时 **locations 与当时 classpath 不一致** 导致误将已存在版本标为「缺失」并多次写入 **`DELETE`**，就会出现该校验错误。

本仓库当前 `db/migration/` 中**可能已不存在** `V51__*.sql`（历史上删过文件或合并不再携带），但**共享库**里仍残留多条针对 `51` 的 **`DELETE`** 行，同样会触发上述错误。

## 修复原则（MUST）

1. **在目标库上操作前备份**（至少导出 `flyway_schema_history` 相关行或整表）。
2. **在停写或低峰**执行；修复后由**同一人**先在本机跑一次 `mvn -q verify` 或启动应用确认 Flyway 通过。
3. **只删「重复的 `DELETE`」**，不要随意删 **`VERSIONED`** 且 **`success = 1`** 的成功记录，除非已与 DBA/负责人确认该版本对应的 DDL 在库里已不存在或已由后续迁移接管。

## 1. 只读排查

在**与 `application-local.yml` / `SPRING_DATASOURCE_*` 一致**的库执行（将 `51` 换成报错中的版本号）：

```sql
SELECT installed_rank, version, description, type, script, checksum, installed_on, success
FROM flyway_schema_history
WHERE version = '51'
ORDER BY installed_rank;
```

关注：

- **`type = 'DELETE'`** 是否出现 **2 行及以上**；
- 是否仍存在同一 `version` 的 **`VERSIONED`** 且 **`success = 1`**（表示该版本曾成功执行）。

## 2. 推荐修复：删除多余的 `DELETE` 行（保留一条或零条）

### 2.1 MySQL 8+（窗口函数，推荐）

将下方 **`'51'`** 换成实际版本号；在**事务**中执行，先 `SELECT` 子查询结果再 `DELETE`：

```sql
START TRANSACTION;

-- 预览：将被删除的 installed_rank（应仅为「多出来的」DELETE）
SELECT h.installed_rank, h.version, h.type, h.script, h.installed_on
FROM flyway_schema_history h
JOIN (
  SELECT installed_rank,
         ROW_NUMBER() OVER (
           PARTITION BY version, type
           ORDER BY installed_rank ASC
         ) AS rn
  FROM flyway_schema_history
  WHERE version = '51' AND type = 'DELETE'
) t ON h.installed_rank = t.installed_rank
WHERE t.rn > 1;

-- 确认无误后再执行删除
DELETE h FROM flyway_schema_history h
JOIN (
  SELECT installed_rank,
         ROW_NUMBER() OVER (
           PARTITION BY version, type
           ORDER BY installed_rank ASC
         ) AS rn
  FROM flyway_schema_history
  WHERE version = '51' AND type = 'DELETE'
) t ON h.installed_rank = t.installed_rank
WHERE t.rn > 1;

COMMIT;
```

含义：对 **`version = '51' AND type = 'DELETE'`** 的多行，**按 `installed_rank` 升序保留第一条**，删除其余重复 **`DELETE`**。

### 2.2 若确认该版本在仓库与库中均已废弃

在**负责人确认**「无对应 `V51__*.sql`、且库结构不依赖该次迁移」的前提下，可改为删除该 **`version`** 下**所有** `DELETE` 行（或整组相关行）；此操作**风险更高**，不在此文档给出一键脚本，避免误删。

## 3. 修复后验证

1. 再次执行：

```sql
SELECT installed_rank, version, type, script, success
FROM flyway_schema_history
WHERE version = '51'
ORDER BY installed_rank;
```

2. 在 `backend/` 使用与联调一致的 **`SPRING_DATASOURCE_*`** 执行：

```bash
mvn -q flyway:validate
# 或
mvn -q verify
```

3. 若仍报 checksum 或其它历史问题，见 **`docs/dev/ops-auth-flyway-mysql-lessons.md`** 与 **`docs/dev/flyway-multi-dev-playbook.md`**，**禁止**在未理解后果时对生产库执行 `repair`。

## 4. 预防

- 对共享库执行 **`flyway repair`** 时，保证 **`locations`** 与当前仓库 **`db/migration`** 一致，避免误标「缺失」。
- 删除或重命名已合并到共享库的 **`V{n}__*.sql`** 前，走团队流程（必要时用**新号段**上的修复迁移，而非改历史文件）。

---

## 5. 共享开发库综合处置（除「多条 `DELETE`」以外）

多人共用 **`kddev`**（或与联调一致的库）时，`flyway_schema_history` 除 **`multiple delete entries`** 外，常见还有以下几类；**先按 Flyway 日志里的版本号 `X` 做只读查询，再动手**。

### 5.1 `Schema … contains a failed migration to version X`

- **含义**：该库存在 **`success = 0`** 的版本迁移记录，Flyway 拒绝继续迁移直至历史状态被处理。
- **只读排查**：

```sql
SELECT installed_rank, version, type, script, success, installed_on
FROM flyway_schema_history
WHERE success = 0
ORDER BY version, installed_rank;

SELECT installed_rank, version, type, script, success, installed_on
FROM flyway_schema_history
WHERE version = 'X'
ORDER BY installed_rank;
```

（将 **`'X'`** 换成日志中的版本字符串。）

- **处置思路（择一，须与负责人/DBA 共识）**：
  1. **删除失败行并允许重跑**：适用于仓库里仍存在 **`VX__*.sql`**，且脚本**幂等**（例如 **`CREATE TABLE IF NOT EXISTS`**、**`INSERT … ON DUPLICATE KEY UPDATE`**），并确认库中对象状态与「重放整段脚本」不冲突。删除 **`success = 0`** 对应行后，下次 **`mvn verify` / 启动** 会再次执行该版本。
  2. **手工修复库结构后标记成功**：若迁移已执行一半、删失败行会导致重复 DDL 报错，需先对齐真实表结构，再按团队规范更新历史表或走 **`repair`**（**`repair` 可能产生 `DELETE` 行**，需对照本文 **§2** 避免再次堆积）。
  3. **禁止**：在未理解 checksum 与团队流程时，对**生产**库盲跑 **`repair`** 或盲删成功行。

### 5.2 同一 `version` 多条成功记录、或 `script` 与仓库不一致

典型来源：历史上同一 **`V{n}`** 曾对应**不同文件名**；或曾注册 **JDBC** 迁移与 **SQL** 文件混用；合并分支后仓库只保留**一条**权威 **`V{n}__*.sql`**。

- **原则**：以**当前分支** `backend/src/main/resources/db/migration/` 下**真实存在的** **`V{n}__*.sql` 文件名**为对照；历史表在该 **`version`** 上应能解释为**一条**与上述文件名一致的、**`success = 1`** 的 **`SQL`**（或团队约定的单一路径），并去掉：
  - 重复的 **`SQL`/`JDBC`** 成功行；
  - **无对应成功 `SQL` 行**的孤立 **`DELETE`**；
  - 与当前仓库文件名**不一致**的旧 `script` 记录（删除前确认库结构已由正确迁移覆盖）。

### 5.3 推荐排查顺序（按版本迭代）

1. 用日志定位 **版本 `X`**（或 corruption 报错的版本）。
2. 对该 **`version`** 执行 **§1** 同类 **`SELECT … ORDER BY installed_rank`**，对照仓库 **`VX__*.sql`** 内容。
3. 先处理 **`success = 0`**（**§5.1**），再处理 **`multiple delete entries`**（**§2**），再收敛**重复成功行**（**§5.2**）。
4. 本地使用与联调一致的 **`SPRING_DATASOURCE_*`** 执行 **`mvn -q verify`**；若 Flyway 报**下一版本**，对下一版本重复本流程。

### 5.4 案例备忘（`kddev`，开发排障）

- **`V1001__commission_policy_ledger_export_ops_circle_option.sql`**（甲号段；曾误用 **`V59`** 已迁出）：历史仅一条 **`success = 0`** 的失败记录时，在确认脚本为 **`IF NOT EXISTS` + `ON DUPLICATE KEY`** 等幂等写法后，**删除该失败行**即可让 Flyway 在下次启动时成功重放；若你的环境失败原因不同（例如半途中断在非幂等语句），仍须回到 **§5.1** 分支 2。

