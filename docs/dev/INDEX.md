# docs/dev/ 知识文档按需加载索引

关键词 → 文档映射，用于 agent 按需读取相关规范。

| 关键词 | 文档 | 说明 |
|--------|------|------|
| flyway, migration, sql, 迁移 | `docs/dev/kangdou-flyway-new-migration.md` | Flyway 版本迁移规范 |
| e2e, playwright, automator | `docs/dev/kangdou-e2e-agent-guide.md` | E2E 测试执行指南 |
| e2e-contract, 禁止假绿 | `docs/dev/kangdou-e2e-execution-contract.md` | E2E 禁止假绿与降级 |
| git, merge, pull, conflict, 冲突 | `docs/dev/kangdou-git-merge-pull.md` | Git 工作流 |
| redis, cache, ttl | `docs/dev/kangdou-redis-cache.md` | Redis 缓存规范 |
| frontend, ux, enum, 中文显示, 枚举 | `docs/dev/kangdou-frontend-ux-enum.md` | 前端 UX 与枚举规范 |
| testing-coverage, 单测, 覆盖率 | `.agents/rules/kangdou-testing-coverage.md` | 测试覆盖率门禁 |
| wechat, miniprogram, 小程序 | `docs/dev/wechat-miniprogram-ship-quality.md` | 小程序交付质量 |
| design-tokens, token, 样式 | `docs/dev/kangdou-design-tokens.md` | 设计 Token 规范 |
| hooks | `.agents/rules/agent-hooks.md` | Agent hooks 配置 |
| cross-cutting, 全栈审查 | `docs/dev/kangdou-cross-cutting-standards.md` | 全栈交叉检查 |
| yunxiao, 云效, 工作项 | `docs/dev/yunxiao-agile-agent.md` | 云效 Agile 规范 |
| kd-review, review, 审查 | `docs/dev/kd-review-five-rounds-gate.md` | kd-review 退出门禁 |
| daily-dev, daily, 日常 | `docs/dev/kangdou-daily-dev-sync.md` | 日常开发同步 |
| java, 阿里巴巴, 编码规范 | `docs/dev/alibaba-java-development-manual.md` | Java 开发规范 |
| plan, superpowers, task-graph | `docs/dev/kangdou-superpowers-plan-contract.md` | 方案编写契约 |
| plan-agent, mode, agent模式 | `.agents/rules/kangdou-plan-agent-mode-triggers.md` | Plan/Agent 模式切换 |
| ops-tenant, 运营后台 | `docs/dev/kangdou-ops-tenant-ui.md` | 运营后台租户 UI |
| experience, 教训, badsql, filter-order, 鉴权, 图片, 飞书表格, docx, 商家后台 | `docs/dev/kangdou-experience-lessons.md` | 开发经验教训（含鉴权链、图片、飞书Docx、商家页） |
| flyway-repair, 损坏修复, corrupted | `docs/dev/flyway-repair-schema-history-corruption.md` | Flyway history 表损坏修复 |
| ops-auth, badsql, flyway-经验 | `docs/dev/ops-auth-flyway-mysql-lessons.md` | 运营登录 BadSqlGrammar 复盘 |
| hbuilderx, cachedDataRejected, uni_helpers | `docs/dev/hbuilderx-cachedDataRejected-uni_helpers.md` | HBuilderX 字节码缓存不兼容 |
| feishu-mcp, 飞书配置 | `docs/dev/feishu-mcp-setup.md` | 飞书 MCP 初始化配置 |
| figma-init, figma-mcp, figma安装 | `docs/dev/figma-mcp-init-guide.md` | Figma MCP 初始化指南 |
| figma-workflow, figma协作 | `docs/dev/figma-mcp-workflow.md` | 双 MCP 协作开发规范 |
| no-speculation, 禁止臆测 | `.agents/rules/kangdou-no-speculation-no-blind-dev.md` | 核心原则 |
| dev-no-prototype, 原型文档 | `docs/dev/kangdou-dev-no-prototype-docs.md` | 禁止修改原型 |
| prototype, 超级力量 | `docs/dev/kangdou-superpowers-plan-contract.md` | Superpowers 契约 |
| publish-to-dev, pr-all, 误推 dev | `docs/dev/incidents/2026-05-28-pr-all-dev-push-accident.md` | pr-all 误推 dev 事件分析 |
| wechat, wx, 小程序, 登录, 支付, 服务商, 提现, 代开发, errcode, 商户号, component_access_token | `docs/dev/wechat-integration-guide.md` | 微信集成全链路知识库 |

## alwaysApply（始终加载）

以下文件标记 `alwaysApply: true`，每次会话自动加载：

- `.agents/rules/kangdou-no-speculation-no-blind-dev.md` — 核心原则
- `.agents/rules/kangdou-plan-agent-mode-triggers.md` — 模式切换
- `.agents/rules/kangdou-testing-coverage.md` — 测试门禁

其余文档按需读取。
