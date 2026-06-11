> ⚠️ **已废弃（2026-06-06）**：从即日起所有新建迁移使用 **时间戳版本号**（`V{YYYY}{MMDD}{NN}`），不再使用三人号段制。详见 [`kangdou-flyway-migration-standards.md`](kangdou-flyway-migration-standards.md)。
>
> 本文保留作为历史参考，其中 §3（号段制）、§3.6（gap buffer）、§7（PR 自检）不再适用。
>
> # Flyway 多人全栈协作手册（已废弃）

本文说明在多名研发并行、共用或接近共用数据库环境时，如何减少 **版本号疯涨**、**迁移撞号**、**脚本无法执行** 与 **SQL 文件合并冲突**。总则与「必须先查库」等强制条款仍以 **`docs/dev/kangdou-flyway-new-migration.md`** 为准；本页为**协作策略**与**三人号段制（正式实行）**的补充。

---

## 1. 问题现象与根因


| 现象              | 根因（简述）                                                                                                                         |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| 版本号「疯涨」         | Flyway 版本迁移在语义上是**全局单调递增**的一条时间线；多人并行时每人倾向取「当前分支最大 `V{n}` + 1」，合入后数字持续增大属常见结果，真正痛点是**并行撞号**与**未对齐主分支**。                        |
| 无法执行 SQL / 启动失败 | 同一 `V{n}` 两文件；或 `**n` 不大于** 目标库 `flyway_schema_history` 已成功应用的最大版本（默认 `**out-of-order: false`** 时脚本被跳过）；或 checksum 与已执行记录不一致等。 |
| Flyway 报 **Corrupted schema history: multiple delete entries for version …** | 共享库 `flyway_schema_history` 对同一 `version` 存在多条 **`type = DELETE`**（常见：`repair` 误跑或 locations 不一致）。**按库手工去重**，见 **`docs/dev/flyway-repair-schema-history-corruption.md`**。 |
| Flyway 报 **`Schema … contains a failed migration to version X`** | 目标库存在 **`success = 0`** 的迁移记录，或同一 **`version`** 与当前仓库脚本状态不一致。按 **`docs/dev/flyway-repair-schema-history-corruption.md` §5** 排查（先查 **`version = X`** 与全表 **`success = 0`**）。 |
| SQL 文件冲突        | 多人改同一 `V{n}__*.sql`；或基于旧 `main`/`dev` 编写与现网结构不一致的 DDL。                                                                         |


核心事实：`**flyway_schema_history` 按数据库实例维护**，不是按 Git 分支；仓库里的文件名必须与**目标库已应用历史**一致且全局唯一。

---

## 2. 不可省略的基础动作（与标准文档一致）

1. **新建或重命名 `V{version}__*.sql` 之前**，在**与 `SPRING_DATASOURCE_`* / `application-local.yml` 一致**的目标库执行：

```sql
SELECT version, description, script, success, installed_on
FROM flyway_schema_history
WHERE success = 1
ORDER BY installed_rank DESC
LIMIT 15;
```

1. 新版本 `**version**` 的定稿规则见本页 §3 号段制与 `docs/dev/kangdou-flyway-new-migration.md`（须结合号段、`out-of-order` 与是否生产环境）；勿仅用 `MAX(version)` 字符串排序误判非纯整数版本（如 `**V6.1**`）。
2. `**mvn validate**` 与 `**backend/scripts/verify_flyway_migration_versions.py**` 仅校验仓库内**文件名不重复**，**不能**代替查库。

---

## 3. 三人号段制（正式约定）

将 `V{version}` 视为**全库唯一**；**新迁移一律使用下表号段内的版本号**，不再与历史脚本抢 `V59`、`V60` 等连续小号。历史脚本（约 `**V58` 及以前**，含 `**V6.1` / `V7.1` / `V7.2`** 等）**保持不动**。

### 3.1 号段与认领人


| 代号    | 版本号区间（闭区间）      | 认领人 | Git 账号（解析用）   | 说明                                 |
| ----- | --------------- | --- | ------------- | ---------------------------------- |
| **甲** | **1000 – 1999** | 肖帅  | **xiaoshuai** | 区间内从小到大取下一个未占用号，首条示例 `V1000__...`。 |
| **乙** | **2000 – 2999** | 文华  | **wenhua**    | 同上，首条示例 `V2000__...`。              |
| **丙** | **3000 – 3999** | 浩天  | **haotian**   | 同上，首条示例 `V3000__...`。              |


#### 机器可读映射（Agent / 脚本）

- **权威配置**：`**docs/dev/flyway-segment-assignments.json`**。匹配规则（见 JSON 顶部 `comment`）：`**gitEmails**` 全邮箱 → `**gitLogins**` 与 `**git config user.name**` 全等（忽略大小写）→ `**gitLogins**` 与邮箱 `**@` 前 local-part** 全等（故 `wenhua@公司.com` 可归 **乙**）。`**displayName`** 与上表认领人应一致。
- **认领人变更**：同时改**本表**与 **JSON**（`gitLogins` / `gitEmails` / `displayName`），避免 Agent 与人工各信一套。
- **解析命令**（仓库根或 `backend/` 下均可）：
  - `python3 backend/scripts/resolve_flyway_segment.py` — 默认 `**git config user.email`** + `**git config user.name**`
  - `python3 backend/scripts/resolve_flyway_segment.py --email-from last-commit --name-from last-commit` — 最近一次提交作者邮箱 + 作者名（适合 Agent 结合 `git log`）
  - `python3 backend/scripts/resolve_flyway_segment.py --json` — 单行 JSON
  - `FLYWAY_SEGMENT_EMAIL=... FLYWAY_SEGMENT_NAME=...` 或 `--email` / `--name` 覆盖
  - `make -C backend flyway-segment`
  - `make flyway-next` — 获取版本号（推荐人类用）
  - `make flyway-next-json` — JSON 输出（推荐 Agent 用）
  - `make flyway-reserve` — 获取版本号 + 创建预留桩文件
- **gap buffer 机制**（详见 §3.6）：新版本 = 当前最高版本 + gap（默认 50）。例：号段内最高 V1050，则下一版本为 V1100（而非 V1051），留下 V1051-V1099 作为并行分支的插入空间。gap 值由 `**/.flywayrc` 配置。
- **origin/dev 自动检查**：脚本同时检查本地文件和 `**origin/dev**` 的 migration 文件，取两者最高值。这样即使自己号段内已有未合入的文件，也保证不与主干已合入的版本冲突。
- **预留桩文件**：`--reserve` 参数在 `.flyway/reservations/` 下创建 git-tracked 空文件。合并时若两人 claim 了同一版本号，git 会报告冲突 → 删掉桩文件 rerun 即可恢复。
- **脚本不做的事**：不连接 MySQL；输出仅为**建议**；**定稿前仍须查 `flyway_schema_history`**（已考虑 origin/dev 和本地文件）。

#### 如何确认「谁用哪一号段」（人类）

号段与真人的对应关系以**本表 + JSON** 为 SSOT；可再镜像到群公告，但以**仓库内已合并内容**为准。

1. **一次拍板**：负责人写入上表与 JSON（`gitLogins` / `gitEmails`），merge 主干。
2. **拿不准时**：发迁移前在团队频道确认由谁占号。

- **跨域 / 跨人改表**：优先由**表责任方**所在号段的人出迁移；或当面/群里约好由谁占号，避免两人各写一段 DDL 互相覆盖。
- **号段用尽**：在团队频道同步后扩区（例如 **4000–4999**），并**更新本表、JSON** 与修订记录。
- **9000+**：保留给「仅开发 / 种子数据」类脚本（若进仓库）；是否进生产须单独评审。

### 3.2 与 `out-of-order` 的关系（必读）

在 Spring Boot 默认 `**spring.flyway.out-of-order: false`** 时，待执行迁移若版本号 **小于等于** 该库已成功应用的最大版本，会被**跳过**。

为让**三人各占千位号段、合入顺序任意**仍能补跑未执行的迁移，本仓库在**非生产**默认 `**spring.flyway.out-of-order: true`**（见 `**backend/src/main/resources/application.yml**`）；**生产**在 `**application-prod.yml`** 中显式 `**out-of-order: false**`，与 `validate-on-migrate: true` 配套。`**application-local.yml**` 中重复写明 `true`，便于只读该片段时仍可见约定。

### 3.3 生产发布（`prod`）

生产环境 `**out-of-order: false**`。若某次上线已应用 `**V2000**`，之后版本才合入 `**V1001**`（且 `1001 < 2000`），**该脚本在生产将不会执行**。因此：**进入生产发布分支的迁移集合**，仍建议按 **version 升序** 规划合入，或保证新迁移的 `version` **大于生产库当前已成功应用的最大 version**（由发布负责人 / CI 核对）。

### 3.4 仍须遵守

- **查库**：新建脚本前仍须查询目标库已成功应用的最新记录（见第 2 节）；用于确认无**重复 `version`**、无与已执行脚本的 **checksum** 冲突。
- **禁止**修改已在共享库 / 生产成功执行过的迁移文件内容；修正用**新号**新文件。

### 3.5 常见错误（录案 · 勿再犯）

| 错误做法 | 为何不行 | 正确做法 |
| -------- | -------- | -------- |
| 见仓库最新是 `V58`，新文件写成 `V59`、`V60`、`V61`… | 违反 §3「新迁移用号段」；`validate` 不重名即通过，易漏检 | 用 **`resolve_flyway_segment.py`** 得到本人号段内版本（如甲 **`V1000`–`V1999`**），再查 **`flyway_schema_history`** |
| Agent 仅跑 `mvn compile` 通过就当版本号 OK | `compile` 不校验「是否在号段内」 | 人工/Agent 对照 **§3.1 表**与 **JSON** |

**实例（2026-05-13）**：曾将「纠偏 `sys_menu` 仍指向 `comingSoon`」写成 `V61__...`，后改为号段内 **`V1000__repair_sys_menu_audit_route_if_stale.sql`**。若某环境已误应用 `V61`，须按 checksum / repair 文档处理，**不得**仅改仓库文件名假装未发生。

### 3.6 Gap Buffer + 预留桩机制（新增）

#### 3.6.1 为什么需要 gap buffer

号段制解决了"三人抢同一个数字"的问题。但并行开发中仍有隐患：

```
origin/dev 最高 V1050

Dev A 开分支 feature/x          Dev B 开分支 feature/y
  → 脚本返回 V1051 (max+1)        → 脚本返回 V1051 (max+1)
  → 创建 V1051__x.sql              → 创建 V1051__y.sql
  → 合入 dev (成功)               → 合入 dev (冲突！V1051 已被占)
```

加上 **gap buffer** 后：

```
origin/dev 最高 V1050

Dev A 开分支 feature/x          Dev B 开分支 feature/y
  → 脚本返回 V1100 (max+50)       → 脚本返回 V1150 (max+50)
  → 创建 V1100__x.sql              → 创建 V1150__y.sql
  → 合入 dev (成功)               → 合入 dev (无冲突)
```

**原理**：gap=50 意味着每次分配跳 50 个号，留下的空位就是并行分支的安全插入区。即使 Dev A 和 Dev B 从同一 origin/dev 出发，各自 +50 的偏移让版本号天然错开。

gap 值由 `.flywayrc` 配置，全员一致。当前默认 50（约 20 次分配用完一个千位号段，足够支撑一个完整版本周期）。

#### 3.6.2 预留桩文件（`--reserve`）

当两人仍可能从同一基点出发拿到相同版本号时，**预留桩文件**提供最后的防线：

```bash
# Dev A 执行：
make flyway-reserve
# → 脚本创建 .flyway/reservations/V1100

# Dev B 执行（未看到 Dev A 的桩文件时）：
make flyway-reserve
# → 也创建 .flyway/reservations/V1100

# 合并时 git 冲突：
# CONFLICT: .flyway/reservations/V1100
# → Dev B 删除桩文件，rerun，得到 V1150
```

桩文件是 `git-tracked` 的空文件，本身无业务含义。它的唯一用途是让 git 在合并时检测到两个分支 claim 了同一版本号。

**何时用 `--reserve`**：当多人同时开发可能改到同一张表的场景，或当你预计合入时间较晚、很可能与别人的版本碰撞时。

#### 3.6.3 使用建议

| 场景 | 推荐做法 |
|------|---------|
| 短分支（1-2 天合入） | `make flyway-next` → 创建 migration 文件 |
| 长分支（>3 天） | `make flyway-reserve` → 创建 migration 文件 → 保留桩文件直到合入 |
| 简单的单文件 DDL | gap=50 已经足够，通常不需要桩文件 |
| 多文件批量 migration | 建议先 `--reserve` 连续分配多个版本 |

---

## 4. 「大功能 / 小功能」与文件命名的映射

1. **产品 / 模块层（给人看）**：需求、分支名、发布说明里使用模块代号 + 迭代（如 `JC-MVP`、`HOME-1.1`）。
2. **Flyway 层（给机器看）**：大功能可在本人号段内**预留连续号块**（例如甲在 `1100–1199` 只做交易域），文件名仍为 `V1101__trade_xxx.sql`，但**不得超出本人号段闭区间**。

若必须在两个已发布整数版本之间插入，可使用 **子版本**（如 `**V6.1__...`**），须全员理解排序；详见本页 §3 号段制与 `docs/dev/kangdou-flyway-new-migration.md`「合并撞号」小节。

---

## 5. 流程约定（减少合并后才发现的问题）

1. **开写迁移前**：`git pull` 最新 `**dev`/`main`**，再查 `**flyway_schema_history**`。
2. **短分支、高频对齐主干**。
3. **一人一文件一意图**；已应用到共享库 / 生产的脚本**只读**，修正用**新号**。
4. **合并撞号**：见 **`docs/dev/kangdou-flyway-new-migration.md`** 与 **`docs/dev/ops-auth-flyway-mysql-lessons.md**`（含 `repair`）。
5. **合并前自检**：`**mvn validate`** 或 `**mvn clean verify**`。

---

## 6. 环境与工具选项（按需选用）


| 手段                       | 作用                                                                                            |
| ------------------------ | --------------------------------------------------------------------------------------------- |
| **本地独立库**（Docker 等）      | 每人本地 `flyway_schema_history` 独立。                                                              |
| `**out-of-order: true`** | 非生产默认已启用（见 §3.2）；**生产**为 `false`。                                                             |
| **仅迁库、不启应用**             | 见 `**docs/dev/ops-auth-flyway-mysql-lessons.md`** 与 `**backend/scripts/flyway-local-db.sh**`。 |


---

## 7. PR / 自检清单（可复制到 PR 模板）

- 已 `git pull` 最新主干。
- 已运行 `make flyway-next` 或 `python3 backend/scripts/resolve_flyway_segment.py --json`（或等价）且 `**gitEmails` 已配置**；新 `version` 落在本人号段。
- 版本号满足 gap buffer 规则（`nextVersion >= maxUsedOverall + gap`），不是简单 max+1。
- 已在目标库查询 `flyway_schema_history`；仓库内无重复 `version`（发布生产前另见 §3.3）。
- 未修改已在共享库 / 生产执行过的迁移文件内容。
- 已运行 `**mvn validate`**（或 `**mvn clean verify**`）。

---

## 8. 相关文档索引


| 文档                                                   | 内容                                                      |
| ---------------------------------------------------- | ------------------------------------------------------- |
| **`docs/dev/kangdou-flyway-new-migration.md`** | Flyway 位置、查库 MUST、`mvn validate`、多人共用库、合并撞号             |
| `**docs/dev/flyway-segment-assignments.json**`       | 号段与 `gitEmails` 映射（Agent / `resolve_flyway_segment.py`） |
| `**docs/dev/ops-auth-flyway-mysql-lessons.md**`      | checksum、`repair`、只迁库脚本、MySQL 字符集                       |
| `**docs/dev/kangdou-flyway-new-migration.md**` | Agent 新建迁移规则                                            |


---

## 9. 修订记录


| 日期         | 说明                                                                                          |
| ---------- | ------------------------------------------------------------------------------------------- |
| 2026-05-12 | 初版；三人号段制、`out-of-order` 与生产注意；配置文件对齐                                                        |
| 2026-05-12 | 认领与 **xiaoshuai / wenhua / haotian** 号段映射：`gitLogins`、邮箱 local-part 匹配；肖帅历史邮箱写入 `gitEmails` |
| 2026-05-13 | **§3.5 录案**：禁止在 `V58` 后接龙 `V59/V60/V61` 作为新迁移；实例 `V61`→`V1000`；强化与 **`docs/dev/kangdou-flyway-new-migration.md`** 对齐 |
| 2026-05-12 | **§1 现象表**：增补 **`multiple delete entries`** 与修复文档 **`docs/dev/flyway-repair-schema-history-corruption.md`** 索引。 |
| 2026-05-12 | **§1 现象表**：增补 **`Schema … contains a failed migration to version X`**，指向 **`flyway-repair-schema-history-corruption.md` §5**。 |


