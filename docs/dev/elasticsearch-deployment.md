# Elasticsearch 部署文档

## 1. 概述

搜索平台基于 ELK 构建：

- **Elasticsearch**：数据存储与搜索
- **Logstash**：JDBC 增量同步 MySQL → ES（`deploy/elk/pipeline/business-sync.conf`）
- **Kibana**：数据可视化（调试/分析）

| 环境 | ES 版本 | 部署方式 | 配置入口 |
|------|---------|----------|----------|
| 开发 | 7.17.24 | `deploy/docker-compose.yml` + `deploy/setup-elk.sh` | `kddev` @ `192.168.100.67`（**ES 无密码**） |
| 生产 | 8.7.0 | 宝塔 `dk_elk` Docker 栈 | `dayuancheng` @ `8.152.101.216` |

仓库内 ELK 文件索引：[deploy/README.md](../../deploy/README.md)

## 2. 索引列表

| 索引名 | 来源 | 同步方式 | 用途 |
|--------|------|----------|------|
| `goods_v1` | `merch_product_spu` + `shop` | Logstash JDBC 每 30s | C 端商品搜索 |
| `circle_post_v1` | `tenant_circle_post` | Logstash JDBC 每 30s | C 端帖子搜索 |
| `shop_v1` | `shop` | Logstash JDBC 每 30s | C 端店铺搜索 |
| `joint_card_v1` | `joint_card` | Logstash JDBC 每 30s | C 端套卡搜索 |
| `audit_log_v1` | 应用日志 | Filebeat → Logstash | 操作审计日志 |
| `search_log_v1` | 搜索 API | 应用层异步写入 | 搜索看板数据 |

## 3. 索引 Mapping 要求

Logstash JDBC 写入时自动创建索引，应用层通过 `SearchDocument` 子类声明的 `@Field` 注解定义 mapping。

### 3.1 联合套卡映射（`joint_card_v1`）

`JointCardDocument.java` 定义了索引映射。下表列出了每个字段在 MySQL 中的来源及 Logstash SQL 的映射处理：

| ES 字段 | MySQL 列 | Logstash SQL 处理 | ES 类型 | 用途 |
|---------|----------|-------------------|---------|------|
| ES `_id` | `jc.joint_card_id` | 作为 `id`（`keyword` 类型） | `keyword` | 文档 ID，前端详情页跳转使用 |
| `id` | `jc.joint_card_id` | `jc.joint_card_id AS id` | `keyword` | 搜索结果的卡片 ID，传递给详情页 |
| `tenant_id` | `jc.tenant_id` | 直接映射 | `keyword` | 租户隔离 |
| `title` | `jc.title` | 直接映射 | `text` (ik_max_word/ik_smart) | 搜索匹配（权重 3x） |
| `description` | `jc.description` | 直接映射 | `text` (ik_max_word/ik_smart) | 搜索匹配 |
| `cover_url` | `jc.cover_url` | 直接映射 | `keyword` | 展示 |
| `owner_shop_id` | `jc.owner_shop_id` | 直接映射 | `keyword` | 归属店铺 |
| `card_status` | `jc.card_status` | 直接映射（ES 自动创建 `.keyword` 子字段） | `text` + `keyword` | 过滤：仅搜索 `ON_SHELF` 状态的卡 |
| `price_fen` | `jc.price_fen` | `CAST(COALESCE(jc.price_fen, 0) AS UNSIGNED)` | `long` | 价格展示（分） |
| `valid_from` | `jc.valid_from` | 直接映射 | `date` | 有效期起始 |
| `valid_to` | `jc.valid_to` | 直接映射 | `date` | 有效期截止（过滤） |
| `sold_quantity` | `jc.sold_quantity` | 直接映射 | `long` | 已售数（库存过滤） |
| `total_quantity` | `jc.total_quantity` | 直接映射 | `long` | 总库存（0=无限） |
| `enabled` | 常量 1 | `ruby filter` 转为 `boolean` | `boolean` | 软删除标志 |
| `updated_at` | `jc.updated_at` | 直接映射 | `date` | 增量同步追踪列 |

### 3.2 商品映射（`goods_v1`）

`GoodsDocument.java` 定义映射；Logstash SQL（`goods` 标签）要点：

| ES 字段 | 来源 | 处理 |
|---------|------|------|
| `id` | `spu.id` | `CAST(spu.id AS CHAR) AS id`（**必须字符串**） |
| `tenant_id` | `shop.tenant_id` | JOIN `shop` |
| `owner_shop_id` | `spu.shop_id` | `CAST(spu.shop_id AS CHAR)` |
| `updated_at` | `spu.update_time` | `FROM_UNIXTIME(update_time)`；JDBC 追踪列用 `update_time` |
| `enabled` | 常量 1 | ruby filter → boolean |

### 3.3 圈子帖子映射（`circle_post_v1`）

| ES 字段 | 来源 | 处理 |
|---------|------|------|
| `id` | `p.id` | `CAST(p.id AS CHAR) AS id` |
| `content` | `p.content` | 搜索匹配 |
| `updated_at` | `p.updated_at` | timestamp，直接追踪 |

### 3.4 店铺映射（`shop_v1`）

| ES 字段 | 来源 | 处理 |
|---------|------|------|
| `id` | `shop.id` | `CAST(id AS CHAR) AS id` |
| `title` / `summary` | `name` / `intro` | 别名映射 |
| `updated_at` | `update_time` | `FROM_UNIXTIME(update_time)`；追踪列 `update_time` |

## 4. ES 搜索查询注意事项

### 4.1 `card_status` 过滤

`card_status` 在 ES 索引模板中定义为 `keyword` 类型，可以直接用 `term` 精确匹配：

```java
// 正确（card_status 为 keyword 类型）
b.must(m -> m.term(t -> t.field("card_status").value("ON_SHELF")));

// 错误（keyword 字段没有 .keyword 子字段）
b.must(m -> m.term(t -> t.field("card_status.keyword").value("ON_SHELF")));
```

详见 `SearchService.buildJointCardQuery()`。

**注意**：如果通过 Logstash JDBC 自动创建索引（无预定义模板），ES 会推断 `card_status` 为 `text` 类型，此时需使用 `card_status.keyword`。当前使用预定义模板确保字段类型正确。

### 4.2 搜索过滤条件

联合套卡搜索的 ES `bool` 查询包含以下 must 子句：

1. `tenant_id` 匹配
2. `enabled: true`（排除软删除）
3. 关键词多字段匹配（`title^3` + `description`，ik_smart 分词器）
4. `card_status.keyword: ON_SHELF`（仅上架的卡）
5. `valid_to >= now()` 或 `valid_to` 不存在（未过期）
6. `total_quantity = 0`（不限量）或 `sold_quantity < total_quantity`（有库存）

## 5. Logstash 同步配置

### 5.1 Pipeline 文件

Logstash pipeline 配置位于 `deploy/elk/pipeline/`：

- `business-sync.conf` — 业务数据 JDBC 同步（goods / circle_post / shop / joint_card）
- `audit-log.conf` — Beats 输入 → ES（审计日志）
- `search-log.conf` — 搜索日志索引

### 5.2 同步字段完整性问题（已知坑）

Logstash JDBC 输入通过 SQL 语句手动选取字段，因此**字段列表与 Java 侧的 `*Document.java` 类必须保持一致**。

如果 SQL 漏选了某个 ES 索引需要的字段：

- ES 索引中将缺失该字段
- 搜索时的 term/range 查询对该字段会因字段不存在而失败
- 该字段对应的过滤条件将无法生效

**典型案例**：`joint_card` 表同步 SQL 最初只选了 `id, tenant_id, title, description, cover_url, enabled, updated_at`，缺少 `card_status`、`valid_to`、`sold_quantity` 等字段，导致联合套卡全量搜索（full-text search）结果始终为空。

**新增字段或修改字段类型时**：

1. 修改 `deploy/elk/pipeline/business-sync.conf` 并提交仓库
2. 在仓库根目录执行（推荐）：

```bash
./scripts/deploy/sync-elk-pipeline-reindex.sh prod   # business-sync.conf（带 ES 认证）
./scripts/deploy/sync-elk-pipeline-reindex.sh dev    # business-sync.noauth.conf（无 ES 密码）
```

开发须在 `.env.dev` 填写 `DEV_ELK_SSH_PASSWORD`；**勿填** `DEV_ELASTICSEARCH_PASSWORD`。

脚本会：上传 pipeline 与 `deploy/elk/mapping/*.json`、删除业务索引与模板、注册模板、清空 JDBC sincedb、重启 Logstash。

手动步骤等价于：

1. `DELETE /_index_template/{index_name}`、`DELETE /{index_name}`
2. `docker exec <logstash> rm -f .../logstash_jdbc_last_run*`
3. `docker restart <logstash>`

> **索引模板陷阱**：当后端 Spring Data Elasticsearch 启动时，会根据 `*Document.java` 的 `@Field` 注解自动创建或更新索引模板。如果初次启动时某个字段类型推断错误（如 `id` 被映射为 `long` 而非 `keyword`），该模板会持续影响后续索引。删除索引不删除模板的话，重新创建时仍会用旧模板。
>
> 删除索引模板后，下次后端启动时 Spring Data ES 会重新创建模板。
>
> **典型案例 2**：`jc.id`（自增主键）被作为 ES `_id` 使用并映射为 `long`。但前端详情页需要的是 `joint_card_id`（UUID 字符串）。修复方案：Logstash SQL 改为 `SELECT jc.joint_card_id AS id`，同时删除旧模板使 `id` 重新映射为 `keyword`，最后重新全量同步。

**典型案例 3**：`goods_v1` / `shop_v1` 的 Logstash SQL 使用 `spu.id`、`shop.id`（MySQL BIGINT），ES 推断为 `long`，Spring Data 映射到 `SearchDocument.id`（`String`）时触发 `MappingConversionException`，搜索降级为空。修复方案：SQL 使用 `CAST(spu.id AS CHAR) AS id`、`CAST(id AS CHAR) AS id`，`owner_shop_id` 同理；重建索引后验证 `_source.id` 为字符串。

**典型案例 4**：`update_time` 直接映射为 `updated_at` 时 ES 存为 long，后端 `SearchDocument.updatedAt`（`LocalDateTime`）反序列化失败。修复：`update_time` 作 JDBC 追踪列，`FROM_UNIXTIME(update_time) AS updated_at` 写入 ES。

**Logstash → ES 认证**：ES 8.x 开启 xpack 时，`business-sync.conf` 的 elasticsearch output 须配置 `user => logstash_internal` 与 `password => ${LOGSTASH_INTERNAL_PASSWORD}`（与 `audit-log.conf` 一致）。

### 5.3 `price_fen` 字段处理

Logstash 中 `price_fen` 须通过 `CAST(COALESCE(x, 0) AS UNSIGNED)` 确保 ES 中存储为数值类型（`long`），与 `JointCardDocument.priceFen` 的 `@Field(type = FieldType.Long)` 匹配。如果直接映射不带类型转换，ES 可能推断为 `text` 类型导致后续 price 展示异常。

## 6. ES 日常运维

### 6.1 查看索引状态

```bash
# 查看所有索引
curl -s http://localhost:9200/_cat/indices?v

# 查看索引 mapping
curl -s http://localhost:9200/{index_name}/_mapping?pretty

# 搜索测试
curl -s -X GET "http://localhost:9200/joint_card_v1/_search" -H "Content-Type: application/json" -d '{
  "query": { "bool": { "must": [
    { "term": { "tenant_id": "t_xxx" } },
    { "multi_match": { "query": "关键词", "fields": ["title^3", "description"], "analyzer": "ik_smart" } },
    { "term": { "card_status.keyword": "ON_SHELF" } }
  ]}}
}'
```

### 6.2 重建索引

```bash
# 仓库根目录（自动读 .env.prod / .env.dev）
./scripts/deploy/sync-elk-pipeline-reindex.sh prod
./scripts/deploy/sync-elk-pipeline-reindex.sh dev
```

验证 `_source.id` 为字符串、`updated_at` 为 ISO 时间字符串：

```bash
curl -s -u elastic:$ES_PASS 'http://127.0.0.1:9200/goods_v1/_search?size=1' | jq '.hits.hits[0]._source | {id, updated_at}'
```

### 6.3 查看 Logstash 日志

```bash
docker logs logstash --tail 50
# 查看错误
docker logs logstash 2>&1 | grep -iE "error|exception|warn"
# 查看 JDBC 同步情况
docker logs logstash 2>&1 | grep "jdbc.*joint_card"
```

### 6.4 查看 Logstash JDBC 追踪时间戳

```bash
docker exec logstash cat /usr/share/logstash/data/plugins/inputs/jdbc/logstash_jdbc_last_run
```

返回值是最后一条同步记录的 `updated_at` 时间戳。如果该时间远早于最新数据时间，说明有同步延迟；如果为 1970-01-01 则表示刚清除 sincedb、正在全量重建。

## 7. Kibana 使用

Kibana 地址：`http://{服务器IP}:5601`

首次使用需创建 Index Pattern（`Management → Stack Management → Kibana → Index Patterns`），填入索引名如 `audit_log_v1`、`joint_card_v1` 等。

## 8. Docker Compose 配置（开发）

见 `deploy/docker-compose.yml` 与 `deploy/.env.example`：

```bash
cd deploy && cp .env.example .env && ./setup-elk.sh
```

| 变量 | 说明 |
|------|------|
| `JDBC_CONNECTION_STRING` | 开发默认 `kddev` |
| `JDBC_USER` / `JDBC_PASSWORD` | MySQL 账号 |
| `ES_HOSTS` | 容器内 `http://elasticsearch:9200` |
| `LOGSTASH_INTERNAL_PASSWORD` | ES 7 无安全可留空；有安全时与 `logstash_internal` 一致 |

生产 `dk_elk` 的 JDBC / 密码在服务器 `/www/dk_project/dk_app/dk_elk/docker-compose.yml` 与 `.env` 中维护，勿与开发 `.env` 混用。

## 9. 后端 ES 配置

`application.yml` / `application-local.yml` 中的 ES 配置：

```yaml
spring:
  elasticsearch:
    uris: ${ES_HOSTS:http://127.0.0.1:9200}
    username: ${ES_USERNAME:}
    password: ${ES_PASSWORD:}
```

索引由 Logstash / 索引模板创建，应用侧 `@Document(createIndex = false)`，启动时不会调用 `indices.create`。

| 变量 | 说明 |
|------|------|
| `ES_HOSTS` | ES 地址 |
| `ES_USERNAME` / `ES_PASSWORD` | 集群开启 xpack 安全时必填；**须与 ELK `.env` 中 `ELASTIC_PASSWORD` 一致** |
| `KANGDOU_ELASTICSEARCH_ENABLED` | 设为 `false` 时关闭 ES 仓库（搜索降级，可先拉起服务） |

生产进程环境由仓库根 `.env.prod` 生成 `/www/wwwroot/kangdouv1/start-backend.sh`（`./scripts/deploy/restart-backend-prod.sh`）。`ES_USERNAME` / `ES_PASSWORD` 须与 dk_elk `.env` 中 `ELASTIC_PASSWORD` 一致；修改后执行 restart 脚本即可。

`local` profile 默认 `kangdou.elasticsearch.enabled=true`（见 `application-local.yml` 与 `.env.dev`）。

### 9.1 搜索看板 `search_log_v1` 与环境一键配置

| 环境 | 环境变量文件 | 注册索引模板 | 后端 ES 地址 |
|------|--------------|--------------|--------------|
| 开发 | 复制 `.env.dev.example` → `.env.dev` | `./scripts/deploy/setup-search-elasticsearch.sh dev` | `ES_HOSTS`（默认 `http://192.168.100.67:9200`，无认证） |
| 生产 | `./scripts/deploy/sync-env-prod-from-profile.sh --merge-remote`（默认来自 `application-prod.yml`，密钥叠加 `start-backend.sh`） | `./scripts/deploy/setup-search-elasticsearch.sh prod` | `ES_HOSTS` + `ES_USERNAME`/`ES_PASSWORD`（与 dk_elk `ELASTIC_PASSWORD` 一致） |

开发机完整 ELK：`cd deploy && cp .env.example .env && ./setup-elk.sh`（含 IK 与全部 mapping）。  
业务索引重建：`./scripts/deploy/sync-elk-pipeline-reindex.sh dev|prod`。  
搜索日志由后端异步写入 `search_log_v1`（不依赖 Logstash）；Filebeat→Logstash 为可选备份链路。

## 10. 故障速查

| 现象 | 常见原因 | 处理 |
|------|----------|------|
| 搜索全空 + `degraded: true` | 后端 `ES_PASSWORD` 与 ELK 不一致 | 对齐 `ELASTIC_PASSWORD`，重启后端 |
| 商品/店铺空、套卡正常 | ES 中 `id` 为 long 或 `updated_at` 为数字 | 更新 pipeline，`sync-elk-pipeline-reindex.sh` |
| 索引一直不存在 | Logstash 写 ES 401 | 检查 `LOGSTASH_INTERNAL_PASSWORD` 与 output 中 `logstash_internal` |
| `/actuator/health` DOWN | 同上或 ES 未启动 | 修凭证 / `docker ps` 检查 dk_elk |
