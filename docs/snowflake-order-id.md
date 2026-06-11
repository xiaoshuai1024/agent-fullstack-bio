## 订单编号生成规则：Snowflake ID

### 为什么从 UUID 改为 Snowflake

| 对比项 | UUID 随机截断（旧） | Snowflake（新） |
|--------|-------------------|----------------|
| 长度 | `o_` + 16 hex = 18 字符 VARCHAR | `BIGINT` 整数，8 字节 |
| 排序 | 完全随机，无法按 ID 排序 | 趋势递增，天然时间序 |
| 数据库索引 | UUID 随机插入导致页分裂 | BIGINT 顺序插入，索引高效 |
| 时序可读 | 不可读 | 可反解出生成时间 |
| 并发 | 无碰撞风险 | 不同 workerId 无碰撞 |

### 位段结构（64-bit）

```
 0 | 0000000000 0000000000 0000000000 0000000000 0 | 00000 | 00000 | 000000000000
 ↑                          ↑                          ↑       ↑           ↑
符号位(1bit)           时间戳(41bit)              数据中心(5bit) 机器(5bit) 序列号(12bit)
始终为0              自定义纪元起的毫秒数         各 5 bit          同毫秒内自增，最多 4096 个
```

- **符号位**：1 bit，始终为 0（正数）
- **时间戳**：41 bit，从 `2024-01-01 00:00:00 UTC` 到当前毫秒差，可用约 69 年
- **数据中心 ID**：5 bit，最多 32 个数据中心
- **工作节点 ID**：5 bit，每个数据中心最多 32 台机器
- **序列号**：12 bit，同一毫秒内同一节点自增，到 4095 后等待下一毫秒

### 部署方案

**workerId 分配**：

```yaml
# 多环境配置
local:    datacenterId=0, workerId=0   # 本地开发
dev:      datacenterId=0, workerId=1   # 测试环境
prod-01:  datacenterId=1, workerId=1   # 生产实例 1
prod-02:  datacenterId=1, workerId=2   # 生产实例 2
```

**数据库适配**：订单号字段从 `VARCHAR` 改为 `BIGINT`，适用于 `trade_order.order_no`、`trade_payment.payment_no` 等主键&外键字段。

**前端注意事项**：JavaScript 的 `Number.MAX_SAFE_INTEGER`（2^53）小于 Snowflake 最大值的 2^63，因此 API 返回订单号时**必须使用字符串类型**传输，前端展示和复制也基于字符串。
