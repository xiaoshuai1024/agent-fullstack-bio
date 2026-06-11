# 服务器连接指南

> 当用户提到「登录开发服务器」或「登录生产服务器」时，按本文件指引操作。

## SSH 配置文件

| 环境 | 文件 | 说明 |
|------|------|------|
| **开发** | `.env.dev` | 开发/测试服务器，含 SSH、数据库、ELK 信息 |
| **生产** | `.env.prod` | 生产服务器，需手动填写后使用 |

## 连接步骤

当用户说 **「登录开发服务器」** 时：
```bash
# 1. 读取 .env.dev 获取连接信息
# 2. 用 sshpass 或 ssh 连接
sshpass -p "$DEV_SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$DEV_SSH_USER@$DEV_SSH_HOST"
```

当用户说 **「登录生产服务器」** 时：
```bash
set -a; source .env.prod; set +a
sshpass -p "$PROD_SSH_PASSWORD" ssh -o StrictHostKeyChecking=no "$PROD_SSH_USER@$PROD_SSH_HOST"
# 兼容历史变量名：DEV_SSH_* 与 PROD_SSH_* 在 .env.prod 中同值
```

## 读取 .env 文件方式

```bash
# Source env file（仅读取不导入 shell）
set -a; source .env.dev; set +a
```

## ELK / 搜索索引

| 操作 | 命令 |
|------|------|
| 文档 | [elasticsearch-deployment.md](./elasticsearch-deployment.md)、[deploy/README.md](../../deploy/README.md) |
| 修改 pipeline 后重建索引 | `./scripts/deploy/sync-elk-pipeline-reindex.sh prod` 或 `dev` |
| 生产后端 ES 密码变更后重启 | `./scripts/deploy/restart-backend-prod.sh` |

| 文件 | 用途 |
|------|------|
| `.env.dev` | 开发 SSH + `MYSQL_*` / `ES_HOSTS`（local 自动 import） |
| `.env.prod` | 生产 SSH + 后端 `MYSQL_*` / `ES_*` + ELK `DEV_DOCKER_*` |

生产后端环境变量由 `start-backend.sh` 注入（`./scripts/deploy/restart-backend-prod.sh` 根据 `.env.prod` 生成）。`ES_PASSWORD` 须与 `/www/dk_project/dk_app/dk_elk/.env` 中 `ELASTIC_PASSWORD` 一致。

## 注意事项

- `.env.*` 已加入 `.gitignore`，不可提交
- 生产环境文件默认留空，需手动填写后再连接
- 数据库信息也在 `.env` 文件中，可直接 source 后用于 mysql 连接等操作
- 执行危险操作（如删除、数据库迁移）前必须先询问用户确认
