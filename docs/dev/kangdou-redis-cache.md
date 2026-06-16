<!--
description: 后端 Redis 缓存（Spring Cache）命名、TTL、失效与接入方式
globs: backend/src/main/java/**/*.java, backend/src/main/resources/application.yml
alwaysApply: false
-->

## 原则

- **读路径**：对「可接受短暂不一致、读明显多于写」的接口，在 **Service** 上用 `@Cacheable`（`sync = true` 防击穿），不要写在 Controller。
- **写路径**：凡持久化会改变缓存语义的数据，必须在同一业务事务提交成功后调用 **`KangdouCacheInvalidator`** 做 **精确 key 失效**；不要只依赖 TTL 保证正确性。

- **分布式系统禁止本地内存缓存**：系统未来为分布式部署，**禁止**在 Service 中使用 `ConcurrentHashMap`、`CopyOnWriteArraySet`、`HashMap` 等 JVM 本地缓存作为业务缓存层。所有缓存必须走 **Redis + MySQL 回退** 模式：
  - 读路径：Redis Hash → 未命中 → MySQL → 写入 Redis（设 TTL）
  - 写路径：写入 MySQL → 删除 Redis key
  - 禁止 `@PostConstruct` 将全量数据加载到内存常驻
  - 例外：WebSocket 会话、API 客户端 token 等**连接级别状态**可维持内存（非业务缓存）
- **TTL**：仅作「上限」与兜底；默认值在 `application.yml` 的 `kangdou.cache.ttl`；可按环境调大/调小。
- **键语义**：租户维度用 `tenantId`；策略文档用 `tenantId + "|" + policyType`（与 `KangdouCacheInvalidator.POLICY_KEY_SEP` 一致）；**禁止**在业务 id 中随意使用 `|`，以免与策略键冲突。

## 已注册的缓存名（`KangdouCacheNames`）

| 名称 | 用途 | 默认 TTL |
|------|------|----------|
| `tenantBootstrap` | 公开 `GET .../bootstrap` | 2m |
| `tenantMiniappConfig` | 公开 `GET .../tenant-config` | 2m |
| `policyActiveJson` | 平台 `GET .../policies/{type}` 当前生效 JSON | 5m |

新增缓存名时：在 `KangdouCacheNames` 与 `KangdouCacheConfiguration` 的 per-cache TTL 中登记，并在 `ConcurrentMapCacheManager` 的 `ALL` 数组中加入（测试无 Redis 时走内存缓存）。

## 失效清单（与实现对齐）

- **策略发布**（`PolicyController.publishPolicy`）：`evictActivePolicy` + `evictTenantPublicCaches`。
- **特征配置保存/回滚**（`TenantFeatureConfigService`）：`evictTenantPublicCaches` + `evictAllActivePoliciesForTenant`。
- **租户状态/资料变更**（`TenantAdminController`）：`evictTenantPublicCaches`。
- **微信资料 upsert**（`TenantWechatProfileService`）：`evictTenantPublicCaches`。

若新增写库路径会影响上述读模型，必须扩展 `KangdouCacheInvalidator` 的调用点。

## 测试

- 集成测试 profile 排除 Redis 时，使用 `ConcurrentMapCacheManager`；**仍须**走失效逻辑，避免「测到假绿」。

---

## 经验：CopyOnWriteArraySet 本地缓存迁移 Redis 后的单元测试适配

### 场景
将 `SensitiveWordService` 的 `CopyOnWriteArraySet<String> localCache` 改为 Redis Set（`redisTemplate.opsForSet()`）后，原有 15 个单测 9 个失败。测试通过 `service.addWord()` 写入、`service.containsSensitive()` 读取，但 Mockito mock 不维护 add/members 之间的状态。

### 根因
1. `addWord()` → `setOps.add(REDIS_KEY, word)` 被 stub 为无操作
2. `containsSensitive()` → `setOps.members(REDIS_KEY)` 返回 null（Mockito 默认）
3. Mockito `when().thenReturn()` 不维护 mock 内部状态——add 和 members 是独立调用

### 解决方案
用 **Answer-based mock** 维护内存 HashSet 状态（参见 `kd-review-five-rounds-gate.md` 中 mock Redis Answer 模式）。

关键点：
- `any()` 而非 `anyString()` 作为 varargs 匹配器（`add(K, V...)` 的 V... 编译为数组）
- `Set.copyOf(redisBacking)` 返回不可变快照，与 Redis `SMEMBERS` 语义一致
- `refresh()` 方法中 `redisTemplate.delete(REDIS_KEY)` 需要额外 stub `thenAnswer` 清空 backing set

### 预防
1. 移除本地缓存前先检查测试是否依赖其内存状态
2. 分布式缓存整改必须在同一 PR 中更新测试（否则合并会还原测试 → 覆盖修复）
3. `containsSensitive()` 改造为 Redis 优先、DB 降级的双路径后，测试需覆盖两条路径
