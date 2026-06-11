# 压测方案 — 康豆 v2

## 环境
- 后端：本地 dev 启动（profile=local），或部署服务器
- 数据库：MySQL `kddev`（与联调共用）
- 监控：Prometheus `http://localhost:9090` + Grafana `http://localhost:3000`

## 场景

### 场景 1：订单创建
```bash
# 使用 wrk 或 ab
wrk -t4 -c20 -d30s --latency http://localhost:8080/api/order/create
```

### 场景 2：商品搜索
```bash
wrk -t4 -c20 -d30s --latency "http://localhost:8080/api/search?keyword=五常大米"
```

### 场景 3：首页加载（混合接口）
```bash
wrk -t4 -c20 -d30s --latency http://localhost:8080/api/home/feed
```

## 观察指标
- Prometheus：`http_job_duration_seconds`、`jvm_memory_used_bytes`
- Grafana：JVM 面板 + 业务指标面板
- 后端日志：`backend/logs/kangdou-local.log`

## 通过标准
| 场景 | P95 响应时间 | 错误率 |
|------|-------------|--------|
| 订单创建 | ≤ 500ms | ≤ 1% |
| 商品搜索 | ≤ 300ms | ≤ 1% |
| 首页加载 | ≤ 800ms | ≤ 1% |
