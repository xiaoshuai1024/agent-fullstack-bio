# 开发环境 MySQL 5.7 配置（Docker Compose）

> 本文档描述开发环境 MySQL 的标准化配置。**禁止在开发机安装非 Docker 管理的 MySQL。**
> 远端部署路径: `/home/dev/docker-compose.mysql.yml`

## 一、启动

```bash
# 部署 MySQL 5.7
docker compose -f /home/dev/docker-compose.mysql.yml up -d

# 验证
mysql -h 192.168.100.67 -P 3306 -u root -proot123456 -e "SELECT VERSION()"
# 预期: 5.7.x
```

## 二、停止 & 重置

```bash
# 停止（保留数据）
docker compose -f /home/dev/docker-compose.mysql.yml down

# 完全重置（删数据卷）
docker compose -f /home/dev/docker-compose.mysql.yml down -v
docker compose -f /home/dev/docker-compose.mysql.yml up -d
```

## 三、首次部署后播种数据

Docker MySQL 5.7 启动后是空库，需要后端 Flyway 建表 + 手动播种种子数据：

### 3.1 启动后端（自动跑 Flyway）

```bash
cd backend
MYSQL_HOST=192.168.100.67 nohup java -jar target/backend-0.0.1-SNAPSHOT.jar \
  --spring.profiles.active=local \
  --spring.devtools.restart.enabled=false \
  --spring.flyway.baseline-on-migrate=false \
  > /tmp/backend.log 2>&1 &
```

> 注意：`baseline-on-migrate=false`，让 Flyway 从第一个迁移开始完整执行。

### 3.2 播种管理员 + 权限

```bash
mysql -h 192.168.100.67 -P 3306 -u root -proot123456 kddev -e "

-- 管理员账号（密码: kangdou）
INSERT IGNORE INTO sys_user (id, username, password_hash, display_name, is_super, status)
VALUES ('u_admin_001','admin','\$2b\$10\$EdbhCCx0jBAfmq3zgf.M/.U3p.YY1VXC7Y1.mW.oKsWyoM/l4upmG','Administrator',1,1);

INSERT IGNORE INTO sys_user (id, username, password_hash, display_name, is_super, status)
VALUES ('u_dev01_001','dev01','\$2b\$10\$EdbhCCx0jBAfmq3zgf.M/.U3p.YY1VXC7Y1.mW.oKsWyoM/l4upmG','Dev01',1,1);

-- SaaS 代开权限
INSERT IGNORE INTO sys_permission (perm_key, perm_name) VALUES
('ops:saas:delegated-miniapp','代开小程序管理'),
('ops:saas:authorization','授权管理'),
('ops:saas:code-template','代码模板管理'),
('ops:saas:data-sync','数据同步管理'),
('ops:saas:thirdParty','第三方平台配置'),
('ops:saas:industry-template','行业模板管理'),
('ops:wechat:auth','微信授权管理'),
('ops:wechat:proxy-register','代注册权限');
"
```

### 3.3 修复 schema 兼容问题

```bash
# topic 列
ALTER TABLE tenant_user_feed_post
ADD COLUMN \`topic\` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '帖子话题分类'
AFTER \`content\`;

# 零日期兼容
# 已在 application.yml 加入 &zeroDateTimeBehavior=convertToNull，无需改 DB
```

## 四、验证

```bash
# 登录验证
curl -s http://127.0.0.1:8080/api/platform/auth/login -X POST \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"kangdou"}' | python3 -m json.tool

# SaaS 代开列表
curl -s http://127.0.0.1:8080/api/platform/saas/delegated-miniapps \
  -H "Authorization: Bearer $(上一步的token)" \
  -H "X-Tenant-Id: t_eb78751bae84"
```

## 五、FAQ

**Q: 为什么必须用 Docker Compose 管理？**
A: 保证环境一致，避免本地 brew 安装的 MySQL 9.x 与线上 5.7 行为差异。

**Q: 数据会丢失吗？**
A: `/home/dev/mysql-data` 是持久化卷，`docker compose down` 不会丢数据。只有 `down -v` 会清空。

**Q: 如何备份？**
A: `docker exec kangdou-mysql-5-7 mysqldump -uroot -proot123456 kddev > backup.sql`
