<!--
description: 新建 Flyway 迁移用秒级时间戳命名；查库 flyway_schema_history 确认不冲突
globs: backend/src/main/resources/db/migration/**/*.sql
alwaysApply: false
-->

## KangDou：新建 Flyway 迁移清单（MUST 按序执行）

> 权威规范：`docs/dev/kangdou-flyway-migration-standards.md`（v3，秒级时间戳）。本清单是其速查版。
> 号段制 / `make flyway-next` / `pnpm run flyway:next:json` / `resolve_flyway_segment.py` 已**全部废弃**（2026-06-11 起）。

新建 `backend/src/main/resources/db/migration/V*.sql` 前必须按以下步骤操作。

---

### □ Step 1 — 用秒级时间戳创建文件

```bash
touch backend/src/main/resources/db/migration/V$(date +%Y%m%d%H%M%S)__your_description.sql
```

- 文件名格式：`V{YYYYMMDDHHmmss}__{英文下划线描述}.sql`（14 位时间戳，如 `V20260611185900__add_user_index.sql`）
- 时间戳取**创建那一刻**，秒级精度天然唯一，**无需取号、无需预约号段**
- 同一秒内连续创建多个迁移：第二个等 1 秒后重新取时间戳
- 描述用英文，单词间下划线

### □ Step 2 — 查库确认（不可省略）

在与本地配置一致的目标 MySQL 上执行：

```sql
SELECT version, description, script, success, installed_on
FROM flyway_schema_history
WHERE success = 1
ORDER BY installed_rank DESC
LIMIT 15;
```

确认：
- ✅ 所选版本号不存在于已执行记录（时间戳理论上不会撞，但仍按惯例核对）
- `mvn validate` 只校验文件名不重复，**不能代替查库**

### □ Step 3 — 实现后验证

```bash
mvn validate           # 校验文件命名正确
mvn -q compile         # 编译通过
```

---

### 参考文档

- 权威规范：`docs/dev/kangdou-flyway-migration-standards.md`（v3）
- 多人共用 MySQL 规范：`docs/dev/JAVA_DEV_STANDARDS.md`
- ~~号段配置 `flyway-segment-assignments.json`~~ / ~~`flyway-multi-dev-playbook.md`~~ 已废弃

---

## 经验：prod profile 启动时 Flyway validate 失败

### 场景

以 `make prod`（prod profile）在本地启动后端连接预发库，Flyway 因 `out-of-order: false` 报 `Validate failed: Migrations have failed validation`，应用无法启动。

### 根因

- **prod profile 默认 `out-of-order: false`**：生产安全策略，迁移必须严格按版本顺序执行
- **预发库与代码库版本有 gap**：feature 分支开发期间积累的迁移未逐版本部署到预发库
- **旧迁移文件已删除但 DB 仍有 SQL 记录**：V37、V38 的 SQL 文件已从目录删除，`flyway_schema_history` 中仍存有 `type=SQL` 记录

### 解决方案

```sql
-- 修复已删除迁移的记录
UPDATE flyway_schema_history SET type='DELETE'
WHERE version IN ('37', '38') AND type='SQL';
```

```bash
# 预发库允许 out-of-order 执行
SPRING_FLYWAY_OUT_OF_ORDER=true make prod
```

### 预防

- 预发库启动始终加 `SPRING_FLYWAY_OUT_OF_ORDER=true`
- 删除迁移文件后同步执行 `flyway repair` 或在 DB 标记 `type=DELETE`

---

## 经验：INSERT IGNORE + 硬编码 ID 导致菜单静默丢失

### 场景

V3034 用 `INSERT IGNORE INTO sys_menu (id=121, ...)` 创建"搜索管理"菜单树，但 V56.1 已先用 ID=121 创建了"联合套卡治理"。`INSERT IGNORE` 静默跳过，**整个搜索管理菜单（121-125）从未创建**，侧边栏完全不显示。

### 根因

- `INSERT IGNORE` 对主键冲突不做任何提示，成功/失败返回值相同
- 硬编码 ID 跨多个分支并行开发时极易冲突（121-125 被搜索/套卡/商户模块争抢）
- 迁移执行顺序依赖 `installed_rank`，先到先得，后到者静默失败

### 解决方案

```sql
-- ✅ 正确：使用 ON DUPLICATE KEY UPDATE 确保幂等
INSERT INTO sys_menu (id, parent_id, type, code, name, ...)
VALUES (1210, 1210_parent, 'directory', 'nav_search_management', '搜索管理', ...)
ON DUPLICATE KEY UPDATE
    name = VALUES(name),
    component = VALUES(component),
    route_name = VALUES(route_name),
    updated_at = NOW();

-- ❌ 错误：INSERT IGNORE 静默丢数据
INSERT IGNORE INTO sys_menu (id, ...) VALUES (121, ...);
```

### 预防

1. **菜单 ID 永远不硬编码**：让 AUTO_INCREMENT 自分配，或使用高位无冲突区间（1210+）
2. **禁止 `INSERT IGNORE`**：改用 `INSERT ... ON DUPLICATE KEY UPDATE`，冲突时至少能更新
3. **新迁移前必须** `grep -rn "($id," backend/src/main/resources/db/migration/` 确认 ID 不被占用
4. **Flyway 迁移中涉及 `sys_menu` 的 INSERT**：必须验证目标 ID 在所有历史迁移中未被使用

---

## 经验：生产 JAR 内 Flyway 版本号重复导致启动失败

### 场景

生产部署后端 JAR，重启后 `FlywayException: Found more than one migration with version 3281`，Tomcat 无法启动，`/actuator/health` 无法访问。

### 根因

1. `target/classes/` 中残留了已重命名/删除的旧 Flyway 文件（如 `V3281__cps_selection_product.sql`），打包进 JAR
2. 源文件 `src/main/resources/db/migration/V1633__circle_post_visibility.sql` 与 `V1633__normalize_miniapp_home_surface.sql` 共享版本号 1633
3. 同样问题还有 V3289 被两文件共用
4. `mvn clean` 不全时，target 中残留旧文件，`mvn clean package` 才能彻底清除

### 解决方案

```bash
# 排查 JAR 内重复版本
jar tf target/backend-0.0.1-SNAPSHOT.jar | grep 'V1633\|V3281\|V3289'

# 彻底清理（必须 clean）
mvn clean package -DskipTests -DskipITs

# 服务器上从 JAR 移除重复文件（应急方案）
# zip -d backend-0.0.1-SNAPSHOT.jar BOOT-INF/classes/db/migration/V3281__cps_selection_product.sql
```

### 预防

1. **`mvn clean` 而非 `mvn compile`**：重命名/删除 Flyway 文件后必须 `clean` 再打包
2. **验证 JAR 内容**：打包后用 `jar tf JAR | grep -E 'V[0-9]+__' | sort | uniq -d` 检查重复
3. **`mvn validate` 不能代替查库**：validate 只检查文件名不重复，不检查 target 残留
4. **不要在一个版本号上放两个不同内容的 SQL 文件**

---

## 经验：生产库缺少 Flyway 迁移表导致 SQL 语法错误

### 场景

后端更新后 API 报 `DB_SCHEMA_INCOMPATIBLE` / `SQL 语法错误`，请求日志显示 `Table 'dayuancheng.tenant_home_config' doesn't exist`。

### 根因

1. V1633 迁移文件因版本号重复被删除，但该迁移在生产库上从未执行过
2. 删除 `flyway_schema_history` 记录后 Flyway 不再认为该版本已执行
3. `CREATE TABLE IF NOT EXISTS` 在新 JAR 启动时不会自动创建被删迁移中的表
4. prod profile 的 `spring.flyway.out-of-order=false` 阻止了迁移重排

### 解决方案

```sql
-- 1. 直接在目标库执行缺失迁移的 DDL
CREATE TABLE IF NOT EXISTS tenant_home_config (...);

-- 2. 手动注册到 flyway_schema_history
INSERT IGNORE INTO flyway_schema_history
  (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success)
SELECT COALESCE((SELECT MAX(installed_rank) FROM flyway_schema_history), 0) + 1,
       '1633', 'normalize miniapp home surface', 'SQL',
       'V1633__normalize_miniapp_home_surface.sql',
       -123456789, 'root', NOW(), 0, 1;

-- 3. 验证
SHOW TABLES LIKE 'tenant_home_%';
```

### 预防

1. **删除迁移文件前查库确认**：`SELECT version FROM flyway_schema_history WHERE version = 'N'`
2. **已执行的迁移禁止删除**（即使觉得是"重复"），只能标记 `type=DELETE`
3. **部署到新环境前**：对比 `flyway_schema_history` 与代码库 migration 目录
4. **迁移的删除/重命名操作**：必须同步注册 `flyway_schema_history`，保证 DDL 在目标库实际存在

---

## 经验：CREATE TABLE 中避免双重 PRIMARY KEY

### 场景
`V3010__create_service_provider_credential.sql` 同时在 `id` 列上声明 `AUTO_INCREMENT PRIMARY KEY` 和在表末尾声明 `PRIMARY KEY (id)`，MySQL 报"Multiple primary key defined"，导致 Flyway 迁移失败、后端无法启动。

### 根因
```sql
-- ❌ 双重 PRIMARY KEY
CREATE TABLE t (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,  -- 第一次
  ...
  PRIMARY KEY (id)                        -- 第二次
);
```

### 解决方案
删除表末尾冗余的 `PRIMARY KEY (id)` 行，保留列级定义。

### 预防
1. `CREATE TABLE` 中 `PRIMARY KEY` 只出现一次（列级或表级，二选一）
2. 列级 `AUTO_INCREMENT PRIMARY KEY` 与表级 `PRIMARY KEY (id)` 互斥

---

## 经验：时间戳版本号替代三人号段制

### 场景
多人并行开发时 Flyway 号段冲突（同一版本号被两人占用）、合并后低版本号无法执行、gap buffer 仍不能完全避免碰撞。生产表缺失。

### 根因
- 三人号段制（1000-1999 / 2000-2999 / 3000-3999）虽然分区，但同区段内多人仍可能撞号
- `out-of-order: true` 在 dev 开启但在生产关闭，导致低版本迁移被跳过
- gap buffer（每次+50）只能降低碰撞概率，不能彻底消除

### 解决方案
切换到秒级时间戳版本号 `V{YYYYMMDDHHmmss}__{desc}.sql`：

```
V20260611185900__add_user_index.sql   ← 2026年6月11日 18:59:00 创建
V20260611190530__create_order.sql     ← 2026年6月11日 19:05:30 创建
V20260612091215__seed_permissions.sql ← 2026年6月12日 09:12:15 创建
```

（2026-06-06 起先采用 `V{YYYY}{MMDD}{NN}` 日期+序号格式并将全部 120 个历史迁移批量重命名为 `V2024{原版本号05d}__{desc}.sql`、同步更新各环境 `flyway_schema_history.version`；2026-06-11 起升级为秒级时间戳，彻底去掉当日序号与号段脚本。）

```sql
UPDATE flyway_schema_history SET version = CASE version
  WHEN '1' THEN '202400001'
  WHEN '1000' THEN '202401000'
  ...
  ELSE version
END;
```

### 预防
- 新建迁移直接用秒级时间戳命名，无需预约号段
- 不再需要 `make flyway-next` / `make flyway-reserve` / gap buffer / 预留桩
- 多人各写迁移：时间戳到秒级天然不同，无冲突
- 详见 `docs/dev/kangdou-flyway-migration-standards.md`（v3）

---

## 经验：V202400001 DROP TABLE IF EXISTS 导致数据丢失

### 场景
Flyway 因各种原因需要重新执行 V202400001（初始建库迁移），该迁移包含 200+ 条 `DROP TABLE IF EXISTS` + `CREATE TABLE IF NOT EXISTS`。当迁移重跑时，所有业务数据被清除——用户、权限、菜单、租户、提现记录全部丢失。

### 根因
- V202400001 作为初始建库脚本，使用 `DROP TABLE IF EXISTS` 确保幂等性
- 但 `DROP` + `CREATE` 组合在已有数据的数据库上执行时，删除所有数据且无恢复手段
- 后续种子数据迁移（如 `V202402005__seed_exam_menu_permission.sql`）依赖菜单和权限表有初始数据，一旦表被清空则整个权限体系不可用

### 解决方案
```bash
# 从 V202400001 中移除所有 DROP TABLE IF EXISTS 语句
cd backend/src/main/resources/db/migration
sed -i '' '/^DROP TABLE IF EXISTS `.*`;$/d' V202400001__init_multi_tenant_tables.sql
# 验证
grep "^DROP TABLE" V202400001__init_multi_tenant_tables.sql | wc -l  # 输出 0
```

### 预防
1. V202400001 等全量建库迁移使用 `CREATE TABLE IF NOT EXISTS` 而非 `DROP+CREATE`
2. 分支合并后若涉及 V202400001 修改，检查是否引入了新的 DROP
3. 在已有数据的库上跑迁移前先用 `grep "^DROP TABLE"` 检查
4. `flyway_schema_history` 的修复优先用 `type=DELETE` 而非直接删除记录

---

## 经验：低版本迁移依赖高版本建表导致失败

### 场景
全新 MySQL 数据库执行 `flyway:migrate` 时，`V2016__seed_exam_v2_menu_permission.sql`（version=2016）失败：
```
ERROR: Table 'kddev.sys_permission' doesn't exist
```

### 根因
V2016 在 `INSERT INTO sys_permission` 之前 `sys_permission` 表由 `V202400001`（version=202400001）创建。Flyway 按版本号升序执行，V2016 先于 V202400001 运行，但 V2016 引用了尚未建的表。

这是经典的低版本 out-of-order 迁移缺乏自包含性——低版本迁移不应引用高版本迁移创建的数据库对象。

### 解决方案
1. 跳过低版本历史迁移（`flyway.baselineOnMigrate=true -Dflyway.baselineVersion=202400000`）
2. 或从已有数据的库直接 `flyway:migrate`（该库已有这些历史迁移记录）
3. 全量初始化时从生产导入数据（已含历史迁移记录），再补跑 V2024+ 迁移

### 预防
- 低版本迁移（V 号 < 202400000）必须是自包含的——它引用的所有表/列必须在自身 SQL 中创建
- 从零初始化推荐 `baselineOnMigrate=true + baselineVersion=202400000` + 生产数据导入，而非逐条跑历史迁移
- `flyway:migrate` 失败后用 `DELETE FROM flyway_schema_history WHERE version='X'` 清除失败记录后重试

---

## 经验：全量建库迁移中跨表外键创建顺序问题

### 场景
全新 MySQL 执行 `V202400001__init_multi_tenant_tables.sql` 时报错：
```
Cannot add foreign key constraint
— CONSTRAINT fk_cmf_trade_tenant FOREIGN KEY (tenant_id) REFERENCES tenant (id)
```

### 根因
`cmf_trade` 表在第 126 行创建，引用 `tenant` 表，但 `tenant` 表在第 2413 行才创建。建表顺序导致前向引用外键失败。

### 解决方案
去掉该外键约束（因为 tenant_id 是逻辑外键，VARCHAR 类型不适合物理外键）：
```sql
-- 从 CREATE TABLE cmf_trade 中移除：
-- CONSTRAINT fk_cmf_trade_tenant FOREIGN KEY (tenant_id) REFERENCES tenant (id)
```
或通过 JDBC URL 参数全局关闭外键检查：
```sql
jdbc:mysql://host/db?sessionVariables=foreign_key_checks=0,sql_mode=ALLOW_INVALID_DATES
```

### 预防
- 全量建库迁移中所有表应避免前向外键引用
- 高版本新增的外键约束使用 `ALTER TABLE ADD CONSTRAINT` 而非在 CREATE TABLE 中定义
- `VARCHAR` 类型的外键列（如 tenant_id）不推荐使用物理外键

---

## 经验：迁移文件因列已存在（MySQL 1060）导致生产部署失败

### 场景
`mvn clean package` 产出的 JAR 包含 Flyway 迁移，部署到生产后 Flyway 报错：
```
SQL State  : 42S21
Error Code : 1060
Migration of schema `dayuancheng` to version "20260611193717" failed!
Duplicate column name 'wechat_transaction_id'
```
后续每次启动都重复失败（`repair-before-migrate: true` 会删除失败行然后 migrate 重试 → 又失败 → 死循环）。

### 根因
生产中该列已存在（之前通过其他途径手动加过），但 `flyway_schema_history` 中没有该迁移的成功记录。Flyway 试图执行 `ALTER TABLE ADD COLUMN` 失败退出。

### 解决方案
1. **确认列/索引状态**（列已存在，索引可能未建 — 迁移在 ADD COLUMN 处就中止了）：
   ```sql
   SHOW COLUMNS FROM trade_payment LIKE 'wechat_transaction_id';
   SELECT COUNT(*) FROM information_schema.statistics
   WHERE table_name='trade_payment' AND index_name='idx_trade_payment_wx_txn';
   ```
2. **补建缺失的索引**（CREATE INDEX 在迁移中排在 ADD COLUMN 之后，未执行）：
   ```sql
   CREATE INDEX idx_trade_payment_wx_txn ON trade_payment (wechat_transaction_id);
   ```
3. **在 flyway_schema_history 中标记该迁移为已应用**（schema 变更已生效，修复纯历史记录）：
   ```sql
   UPDATE flyway_schema_history SET success=1, execution_time=0, installed_on=NOW()
   WHERE version='20260611193717';
   ```
4. 重启后端 → Flyway 跳过该迁移，应用正常启动

### 预防
- 生产中手动加列后，应在 `flyway_schema_history` 插入对应的成功行，或确保迁移版本号在手动加的版本号之后
- 迁移文件应考虑幂等性（通过 `INFORMATION_SCHEMA.COLUMNS` 判断列是否存在）
