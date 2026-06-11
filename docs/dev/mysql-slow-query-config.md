# MySQL 慢查询配置

## 1. 简介

本文档描述康豆平台 MySQL 慢查询日志的配置方案，涵盖：

- MySQL 服务端 `my.cnf` 配置
- Spring Boot 侧 slow query 感知（配置日志、慢查询阈值声明）
- 慢查询日志解析与持久化策略
- 告警规则

参考 PRD 第 9.6 节（慢查询监控与索引优化），`long_query_time` 设置为 **500ms**。

---

## 2. MySQL 服务端配置（my.cnf）

在 MySQL 配置文件 `my.cnf`（或 `mysqld.cnf`）的 `[mysqld]` 节添加：

```ini
[mysqld]
# ============================================================
# 慢查询日志配置
# ============================================================

# 开启慢查询日志
slow_query_log = ON

# 慢查询日志文件路径（确保 MySQL 运行用户有写入权限）
slow_query_log_file = /var/log/mysql/mysql-slow.log

# 慢查询阈值：超过 500ms 的 SQL 被记录
long_query_time = 0.5

# 记录未使用索引的查询（用于排查缺少索引的 SQL）
log_queries_not_using_indexes = ON

# 每分钟最多记录多少条未使用索引的查询（避免日志暴增）
log_throttle_queries_not_using_indexes = 60

# 记录慢管理语句（ALTER TABLE 等 DDL）
log_slow_admin_statements = ON

# 记录从库的慢查询（如果有只读从库）
log_slow_slave_statements = ON

# 记录实际使用到的索引信息（便于分析 EXPLAIN）
log_output = FILE

# 慢查询日志输出格式（FILE 或 TABLE，推荐 FILE + mysqldumpslow / pt-query-digest 分析）
# 也可同时写入 mysql.slow_log 表：log_output = FILE,TABLE
```

### 2.1 配置文件位置

| 环境 | 推荐路径 | 备注 |
|------|---------|------|
| 开发联调 | 需联系 DBA 操作 | 共享库 `192.168.100.67` 由 DBA 统一配置 |
| 生产 | `/etc/my.cnf` 或 `/etc/mysql/mysql.conf.d/mysqld.cnf` | 重启 MySQL 后生效 |

### 2.2 验证配置

```sql
-- 查看当前慢查询配置
SHOW VARIABLES LIKE 'slow_query%';
SHOW VARIABLES LIKE 'long_query_time';
SHOW VARIABLES LIKE 'log_queries_not_using_indexes';

-- 结果示例：
-- slow_query_log                ON
-- slow_query_log_file           /var/log/mysql/mysql-slow.log
-- long_query_time               0.500000
-- log_queries_not_using_indexes ON
```

### 2.3 运行时修改（无需重启）

```sql
SET GLOBAL slow_query_log = ON;
SET GLOBAL long_query_time = 0.5;
SET GLOBAL log_queries_not_using_indexes = ON;
SET GLOBAL log_throttle_queries_not_using_indexes = 60;
```

> 注意：`long_query_time` 的 `SET GLOBAL` 只对新连接生效，已有连接不受影响。可通过重连或 `SET SESSION long_query_time = 0.5` 立即生效。

---

## 3. 慢查询日志轮转

### 3.1 MySQL 自带日志轮转（推荐）

启用 MySQL `log_slow_extra`（MySQL 8.0.14+）获得更详细的信息：

```sql
SET GLOBAL log_slow_extra = ON;
```

配合 Linux `logrotate` 配置 `/etc/logrotate.d/mysql`：

```
/var/log/mysql/mysql-slow.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 640 mysql mysql
    postrotate
        # 告诉 MySQL 重新打开日志文件
        mysqladmin flush-logs -uroot -p[password] 2>/dev/null || true
    endscript
}
```

### 3.2 保留策略

| 环境 | 保留天数 | 说明 |
|------|---------|------|
| 开发联调 | 3 天 | 空间有限，仅保留近期 |
| 生产 | 30 天 | 满足问题回溯和容量规划需求 |

---

## 4. 分析工具

### 4.1 pt-query-digest（推荐）

Percona Toolkit 的 `pt-query-digest` 是分析慢查询日志的首选工具：

```bash
# 分析慢查询日志并按总耗时排序
pt-query-digest /var/log/mysql/mysql-slow.log

# 输出 JSON 格式（便于程序解析入库）
pt-query-digest --format json /var/log/mysql/mysql-slow.log > /tmp/slow-query-report.json

# 只看最近 1 小时的慢查询
pt-query-digest --since "1 hour ago" /var/log/mysql/mysql-slow.log
```

### 4.2 mysqldumpslow（MySQL 自带）

```bash
# 按平均耗时排序 TOP 10
mysqldumpslow -s t -t 10 /var/log/mysql/mysql-slow.log

# 按执行次数排序 TOP 10
mysqldumpslow -s c -t 10 /var/log/mysql/mysql-slow.log
```

---

## 5. Spring Boot 侧配置

### 5.1 慢查询日志在应用层的感知

Spring Boot 侧通过 `spring.jpa.properties.hibernate.session.events.log.LOG_QUERIES_SLOWER_THAN_MS` 可监控 Hibernate 层面的慢查询，但本项目使用 MyBatis-Plus，故在 MyBatis 层面配置：

```yaml
# application.yml (已存在)
logging:
  level:
    org.springframework.jdbc.core: ${LOGGING_LEVEL_JDBC:DEBUG}
```

生产环境建议设置为 `INFO` 以避免过多日志。

### 5.2 慢查询阈值声明配置

在 `application.yml` 中声明慢查询阈值常量（供文档和团队参考）：

```yaml
kangdou:
  datasource:
    slow-query-threshold-ms: 500
```

> 该配置仅为声明性配置，表示本项目的 MySQL `long_query_time` 目标值为 500ms。

### 5.3 Java 配置类：MySQL 慢查询日志启动时检查

已存在的 ES 慢查询配置类见 `com.kangdou.search.config.EsSlowQueryConfig.java`。

对于 MySQL，可参考以下方式在启动时输出慢查询配置状态：

```java
// 方案：通过 Datasource 的 HikariCP 指标监控连接池超时，
// 慢查询本身由 MySQL server 侧配置和 pt-query-digest 分析，
// 不在应用层重复拦截（避免性能损耗）
```

> **设计决策**：MySQL 慢查询日志由 MySQL Server 侧配置和 `pt-query-digest` 分析，不在应用层通过 AOP 拦截 SQL。理由是：
> 1. MyBatis-Plus 拦截器会带来额外性能开销（反射 + 字符串处理）
> 2. MySQL server 侧的慢查询日志更精准（含锁等待时间、扫描行数等真实执行信息）
> 3. `pt-query-digest` 的 SQL 指纹归一化能力远强于自研实现

---

## 6. 定时任务采集（可选）

如需将慢查询记录入库到 `sys_slow_query_record` 表以便运营后台查询，可通过定时任务（如 `@Scheduled`，每 10 分钟）执行 `pt-query-digest --format json` 并将结果解析入库。

### 6.1 入库表结构（设计参考）

```sql
CREATE TABLE IF NOT EXISTS `sys_slow_query_record` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `sql_fingerprint` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'SQL 指纹（归一化文本）',
  `max_query_time` decimal(10,3) NOT NULL COMMENT '最大执行时间(秒)',
  `avg_query_time` decimal(10,3) NOT NULL COMMENT '平均执行时间(秒)',
  `exec_count` int(11) NOT NULL COMMENT '执行次数',
  `lock_time` decimal(10,3) NOT NULL DEFAULT '0.000' COMMENT '锁等待时间(秒)',
  `rows_examined_avg` int(11) NOT NULL DEFAULT '0' COMMENT '平均扫描行数',
  `rows_sent_avg` int(11) NOT NULL DEFAULT '0' COMMENT '平均返回行数',
  `first_seen` timestamp NOT NULL COMMENT '首次发现时间',
  `last_seen` timestamp NOT NULL COMMENT '最近发现时间',
  `index_hint` varchar(512) DEFAULT NULL COMMENT '索引建议',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_slow_query_last_seen` (`last_seen`),
  KEY `idx_slow_query_exec_count` (`exec_count`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='慢查询记录表';
```

### 6.2 告警规则

| 规则 | 阈值 | 通知方式 | 说明 |
|------|------|---------|------|
| 单日新增慢查询超过阈值 | 10 条/天 | 飞书 Webhook | 识别突发的性能劣化 |
| 单条慢查询超过 5s | 1 次 | 飞书 Webhook (紧急) | 严重影响用户体验的慢查询 |
| 同一 SQL 指纹执行频率突增 | 较昨日增长 > 200% | 飞书 Webhook | 识别新增全表扫描 |

---

## 7. 配置清单（部署检查项）

| # | 检查项 | 期望值 | 验证命令 |
|---|--------|-------|---------|
| 1 | slow_query_log | ON | `SHOW VARIABLES LIKE 'slow_query_log'` |
| 2 | long_query_time | 0.5 | `SHOW VARIABLES LIKE 'long_query_time'` |
| 3 | slow_query_log_file | 存在且可写 | `ls -la /var/log/mysql/mysql-slow.log` |
| 4 | log_queries_not_using_indexes | ON | `SHOW VARIABLES LIKE 'log_queries_not_using_indexes'` |
| 5 | logrotate 配置 | 存在且测试通过 | `logrotate -d /etc/logrotate.d/mysql` |
| 6 | pt-query-digest 可执行 | 版本正常 | `pt-query-digest --version` |
| 7 | 慢查询告警规则已配置 | Grafana Alerting 中已配置 | Grafana Alerting 页面确认 |

---

## 8. 关联文档

| 文档 | 路径 | 说明 |
|------|------|------|
| 架构优化与可观测性 PRD | `docs/products/v2/架构优化与可观测性-PRD.md` | 慢查询监控需求规格 |
| Flyway 迁移指南 | `docs/dev/kangdou-flyway-new-migration.md` | 索引变更迁移文件编写规范 |
| 索引优化迁移 | `backend/src/main/resources/db/migration/V1159__five_domain_index_optimization.sql` | 5 大域索引优化 SQL |
