# 运营登录 `BadSqlGrammarException` 复盘

`BadSqlGrammarException` 在 MySQL + Flyway 场景下**最常见根因是表/对象在库里不存在**（未建表、连错库、迁移未跑），而非 SQL 语法错误。

## 1. 排查顺序

### A. 表不存在 / 结构不完整（最高频）
```sql
SHOW TABLES LIKE 'sys\_user';
SELECT installed_rank, version, success FROM flyway_schema_history ORDER BY installed_rank;
```

---

## 2. 根因分类（按优先级排查）

### A. 表不存在 / 结构不完整（最高频）

| 情况 | 说明 |
|------|------|
| Flyway 未跑或失败 | `spring.flyway.enabled=false`、启动失败导致迁移中断、脚本错误使 V6 等未应用。 |
| 多数据源 / 多库 | 应用连的是 **库 A**，手工或旧环境只在 **库 B** 建表；或本地 `.env` 的 `MYSQL_DATABASE` 与预期不一致。 |
| 存量库早于 RBAC 功能 | 老库从未执行含 `sys_user` 的版本；或从备份恢复时丢了 `flyway_schema_history` 之后的版本。 |

**自检命令（MySQL）**：

```sql
SHOW TABLES LIKE 'sys\_user';
SELECT installed_rank, version, success FROM flyway_schema_history ORDER BY installed_rank;
```

若 `sys_user` 不存在或 V6/V9 未成功：属于 **迁移/环境问题**，不是业务代码「语法写错」。

### B. 保留字 / 列名歧义（次频）

- MySQL 中 **`status`** 等可能被解析为保留或高冲突标识；不同版本、SQL_MODE 下表现不一。
- **实践**：在 JDBC 字符串 SQL 里对表名、易冲突列名使用 **反引号**（如 `` `sys_user` ``、`` `status` ``），降低环境差异风险。
- 本项目已对 `OpsAuthService` 等关键路径做反引号加固（与排障同期变更）。

### C. 权限与 SQL 语法无关

- `SELECT` 缺表通常是「不存在」而非「无 GRANT」；无权限常见是另一类错误信息。仍建议确认 DB 用户具备 DDL 已由 Flyway 执行、DML 正常。

---

## 3. 已落地的工程修复（供对照）

1. **Flyway 幂等补丁 `V9__repair_ops_core_tables_if_missing.sql`**  
   在「仅缺核心表」或 V6 未完整应用时，**补建** `sys_user`、`sys_role`、`sys_user_role`、`sys_user_session`、`sys_login_log` 的最小结构，并 **UPSERT** 默认 `admin` 与超级角色绑定（与 V6 种子对齐）。  
   **注意**：V9 **不包含** `sys_permission`、`sys_menu`、`sys_role_permission`、`sys_role_menu`；若只跑到 V9，登录校验密码通过后会在 **加载权限** 阶段报错：`Table 'xxx.sys_role_permission' doesn't exist`。

2. **Flyway 幂等补丁 `V10__repair_ops_rbac_relation_tables_if_missing.sql`**  
   补建上述关联表并写入与 **V6 一致** 的权限点、菜单、角色-权限、角色-菜单及 admin 绑定。与 V9 组合后，即使从未成功执行 V6，也能恢复完整 RBAC 最小可用集。

3. **`GlobalExceptionHandler` 对 `BadSqlGrammarException` 单独处理**  
   返回明确文案：提示检查 Flyway、`sys_*` 表、库连接；若底层信息含 `doesn't exist` / `Unknown table` 等，附带原始片段便于运维检索。

4. **`OpsAuthService` SQL 反引号**  
   降低与 MySQL 保留字、标识符解析的摩擦。

---

## 4. 发布与本地开发检查清单（MUST）

在合并或发布「含运营后台 / RBAC」的后端版本前，至少完成：

- [ ] 目标环境执行 **`mvn flyway:info`** 或等价方式，确认 **V6 或至少 V9+V10** 已成功（`success=1`）。
- [ ] 在**实际连接串指向的库**执行 `SHOW TABLES LIKE 'sys_user';`，确认存在。
- [ ] 新环境首次部署：**空库**跑一次应用或 `flyway:migrate`，再测 **`POST /api/platform/auth/login`**（`admin`/`admin` 或你们约定的种子）。
- [ ] 若多 profile（`local`/`prod`），分别核对 **Flyway 开关** 与 **数据源 URL** 是否指向同一逻辑库。

---

## 5. Agent / 开发协作约定

- 新增或修改 **`/api/platform/**`**、任何 **`sys_*`** 表访问时：若集成测试未覆盖该路径，须补充 **IT 或最小可重复的手动步骤**（见 `.agents/rules/kangdou-testing-coverage.md`）。
- 文档与代码**以 Flyway 为唯一结构真源**；禁止「只在某环境手工建表」而不补迁移脚本（紧急止血后须补正式版本或修复脚本并登记修订记录）。

---

## 6. `audit_event` / 操作审计 API 报缺表（V15、V16）

- **现象**：`Table 'kddev.audit_event' doesn't exist`、或运营 E2E 探测 `GET /api/platform/audit-events` 非 200。
- **根因**：联调库 **`flyway_schema_history` 未到 15+**（未拉代码后重启、迁库失败、连错库），或迁到一半失败。
- **自检（MySQL）**：

```sql
SHOW TABLES LIKE 'audit_event';
SELECT version, description, success FROM flyway_schema_history WHERE version IN ('15','16') OR script LIKE '%audit%';
```

- **修复（推荐）**  
  1. `git pull` 含 **`V15__audit_event.sql`**、**`V16__ops_audit_menu_and_perm_label.sql`** 的后端分支。  
  2. 在能访问该库的机器上，于 `backend/` 目录执行 **`./scripts/flyway-local-db.sh`**（先按 **`backend/.flyway.local.env.example`** 复制为 **`.flyway.local.env`** 并填写 `FLYWAY_URL` / `FLYWAY_USER` / `FLYWAY_PASSWORD`，与 `application-local.yml` 的 `spring.datasource` **同一库**）。  
  3. `./scripts/flyway-local-db.sh info` 确认 **Pending** 中含 V15/V16 后执行 **`./scripts/flyway-local-db.sh migrate`**。  
  4. 或直接 **`mvn spring-boot:run`**（默认 `local` profile）：启动时 Flyway 会 **自动 migrate**（前提：进程能连上库且未禁用 `spring.flyway.enabled`）。

- **checksum / 校验失败**：若有人改过**已执行**过的脚本内容，需按团队流程 **`flyway:repair`** 或出修复迁移；**禁止**在未协调时改历史脚本内容。

### 6.1 共享 `kddev` 上 V15/V16「撞号」但语义不同（小程序菜单 vs 审计）

- **现象**：`mvn flyway:migrate` 报 **`Migration checksum mismatch for migration version 6 … 16`**；`flyway:info` 里 **V15/V16 的 description** 为 *miniapp home menu …* 等，而本仓库 `V15__audit_event.sql` / `V16__ops_audit_menu_and_perm_label.sql` 从未在该库执行；`SHOW TABLES LIKE 'audit_event'` 为空。
- **根因**：同一版本号在不同分支/时期执行过**不同 SQL 文件**；Flyway 以版本号 + checksum 为准，不会自动用本仓库的 V15/V16 覆盖已落库历史。
- **补救（仓库已带幂等脚本）**：拉取含 **`V24__audit_event_and_ops_audit_menu.sql`** 的后端，先 **`mvn compile`**（确保插件 classpath 含 `target/classes/db/migration`），再执行：
  - `FLYWAY_RELAXED_VALIDATE=1 ./scripts/flyway-local-db.sh migrate`  
  - 或：`mvn flyway:migrate -Dflyway.validateOnMigrate=false …`（**仅联调止血**；生产须另议基线/新库）。
- **结果**：库版本升至 **24**，补建 **`audit_event`** 并刷新 **`menu_system_audit` / `ops:audit:list`** 文案与路由；**全新空库**走 V1→V16 时 V24 为重复 DDL/UPDATE，**安全**。
- **长期**：减少共用脏历史库；或 DBA 基线到新库后全队切换；见 **`docs/dev/flyway-multi-dev-playbook.md`**「多人共用一个 MySQL 开发库」。

---

## 7. `tenant_circle_activity` / 租户活动 API（V52、V55、V209）

- **现象**：`GET /api/tenant-core/activities` 等返回 **`DB_SCHEMA_INCOMPATIBLE`**，原始错误含 `Table 'kddev.tenant_circle_activity' doesn't exist`；启动日志里 Flyway 却显示 **`Current version ...: 208`**（或更高）。
- **根因**：共享联调库曾执行过**仅含 `trade_cart` 的旧 `V52`**，合并进圈内活动 DDL 后 **Flyway 不会重跑** 已成功的版本；或 **`V55` 幂等补建未在该库执行**、表被**手工删除**。此时「历史版本号已高」与「物理表缺失」并存，**重启无法自愈**。
- **工程修复**：拉取含 **`V209__repair_tenant_circle_activity_if_missing.sql`** 的后端，**重启应用**（或对该库执行 `flyway migrate`），由 **V209** 在末序 **`CREATE TABLE IF NOT EXISTS`** 补建活动表与报名表。
- **防再犯**：合并进**会改已发布版本号脚本语义**的变更时，优先用**新版本幂等补丁**（如 V55/V209），勿指望所有人重做空库；新活动相关接口合并前在**实际连接串指向的库**执行 `SHOW TABLES LIKE 'tenant_circle_activity';`。

---
