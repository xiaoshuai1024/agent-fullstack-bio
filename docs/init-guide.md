# init.sh 项目配置增强器 — 使用指南

> `init.sh` 是 agent-fullstack-bio 的初始化脚本，能自动检测项目技术栈并注入最佳配置。

## 快速使用

```bash
# 克隆 bio 仓库
git clone https://github.com/xiaoshuai1024/agent-fullstack-bio.git

# 进入你的项目
cd /your-project

# 基础注入
/path/to/agent-fullstack-bio/init.sh

# 或：自动检测技术栈 + 定制化配置（推荐）
/path/to/agent-fullstack-bio/init.sh --detect

# 或：覆盖已有文件
/path/to/agent-fullstack-bio/init.sh --detect --force
```

## 三种模式

### 模式 1：基础注入（默认）

```bash
init.sh
```

**做什么**：复制通用文件到你的项目

| 注入内容 | 行为 |
|---------|------|
| `.agents/` | Skills + Commands + Rules |
| `.claude/` | settings.json, settings.local.json, mcp.json |
| `docs/` | SUPERPOWERS.md, GIT_WORKFLOW.md, AGENT_RULES.md 等 |
| `CLAUDE.md` | 基础模板（如果不存在） |

**适合**：任何项目，快速注入 Agent 能力。

### 模式 2：自动检测（推荐）

```bash
init.sh --detect
```

**做什么**：在基础注入之上，自动检测项目技术栈并生成定制化配置。

#### 检测能力

| 检测项 | 识别方式 | 生成内容 |
|--------|---------|---------|
| **Java + Spring Boot** | `pom.xml` 中有 `spring-boot` | CLAUDE.md 中添加 Maven 命令 |
| **Java + Maven** | `pom.xml` 存在 | CLAUDE.md 中添加 Maven 命令 |
| **Go** | `go.mod` 存在 | CLAUDE.md 中添加 Go 命令 |
| **Python** | `requirements.txt` / `pyproject.toml` | CLAUDE.md 中添加 Python 命令 |
| **Vue 3 前端** | 子目录 `package.json` 含 `vue` | CLAUDE.md 中添加 pnpm 命令 |
| **React 前端** | 子目录 `package.json` 含 `react` | CLAUDE.md 中添加 pnpm 命令 |
| **uni-app 小程序** | 子目录 `package.json` 含 `uni-app` | CLAUDE.md 中添加小程序命令 |
| **Vue 3 运营后台** | `operation-backend/package.json` | CLAUDE.md 中添加运营后台命令 |
| **Docker** | `Dockerfile` / `docker-compose.yml` | 检测报告 |
| **MySQL** | `pom.xml` 中有 `mysql` | 检测报告 |
| **pnpm / yarn / npm** | lock 文件检测 | CLAUDE.md 权限配置 |

**适合**：已有项目，想让 Agent 自动理解技术栈。

### 模式 3：强制覆盖

```bash
init.sh --detect --force
```

**做什么**：覆盖已有文件（默认跳过已存在文件）。

> ⚠️ 会覆盖 CLAUDE.md、settings.json。settings.local.json 始终不覆盖（含本地敏感配置）。

---

## 检测输出示例

### Spring Boot + uni-app 全栈项目

```
🚀 Agent Fullstack Bio - 项目配置增强器
   源: /path/to/agent-fullstack-bio
   目标: /Users/me/my-project
   模式: 自动检测

📦 [1/4] 注入 .agents/ ...
   ✅ 合并完成
📦 [2/4] 注入 .claude/ ...
   ✅ 合并完成（保留本地配置）
📦 [3/4] 注入 docs/ ...
   + docs/SUPERPOWERS.md
   + docs/GIT_WORKFLOW.md
   + docs/AGENT_RULES.md
   ✅ 文档合并完成

🔍 [4/4] 检测技术栈 ...
   后端: Java + Maven (Spring Boot)
   前端: uni-app 小程序 (在 frontend/)
   运营后台: Vue 3 (在 operation-backend/)
   Docker: ✅
   Makefile: ✅
   数据库: MySQL
   包管理器: pnpm

📝 生成 CLAUDE.md ...
   ✅ CLAUDE.md 已生成

✅ 初始化完成！

下一步：
  1. 编辑 CLAUDE.md 填写项目信息
  2. 运行 claude 启动 Claude Code
  3. 输入 / 查看可用命令

检测到的技术栈：
  后端: java-springboot
  前端: uniapp
  运营: vue
  包管理: pnpm
```

### 纯 Go 项目

```
🔍 [4/4] 检测技术栈 ...
   后端: Go
   包管理器: 未检测到
```

### 纯 React 项目

```
🔍 [4/4] 检测技术栈 ...
   前端: React (在 src/)
   包管理器: pnpm
```

---

## 生成的 CLAUDE.md 结构

`--detect` 模式生成的 CLAUDE.md 包含：

```markdown
# CLAUDE.md

## 项目概述
TODO: 填写项目描述

## 技术栈
- 后端: Java 17, Spring Boot 3.x, Maven, MySQL    ← 自动检测
- DB 迁移: Flyway                                   ← 自动检测
- 前端: uni-app (Vue 3), TypeScript, 微信小程序      ← 自动检测
- 运营后台: Vue 3, Element Plus, Pinia               ← 自动检测

## Agent 工具集
- Skills: .agents/skills/ — 80+ AI 技能
- Commands: .agents/commands/ — 28 个斜杠命令
- ...                                               ← 自动注入

## 快速命令
### 后端
mvn -q verify                  # 单测 + 集成测     ← 自动检测
mvn spring-boot:run            # 本地启动
### 前端
pnpm run dev:mp-weixin         # 微信小程序开发      ← 自动检测
pnpm run build:mp-weixin       # 构建

## 文件编码
所有文件 UTF-8 without BOM                           ← 通用规范

## 开发规范
1. 修改前必须 Read 确认当前内容                       ← 通用规范
2. 修改后必须运行构建+测试验证
3. 涉及 3+ 文件改动时先列出范围等待确认
```

---

## 注入后项目结构

```
your-project/
├── .agents/                    ← 注入
│   ├── skills/                 ← 80+ AI 技能
│   ├── commands/               ← 28 个斜杠命令
│   └── rules/                  ← 行为约束
├── .claude/                    ← 注入
│   ├── settings.json           ← 权限白名单
│   ├── settings.local.json     ← 本地配置（不覆盖）
│   └── mcp.json                ← MCP 服务器
├── docs/                       ← 注入 / 合并
│   ├── SUPERPOWERS.md
│   ├── GIT_WORKFLOW.md
│   ├── AGENT_RULES.md
│   ├── claude-code-setup-guide.md
│   └── dev/                    ← 35+ 开发规范
├── CLAUDE.md                   ← 生成（--detect 时定制化）
├── .gitignore                  ← 生成（如不存在）
└── (你的原有文件 ...)
```

---

## 自定义注入内容

注入后你可以按需调整：

### 删掉不需要的 Skills

```bash
# 比如你的项目不做 E2E 测试
rm -rf .agents/skills/e2e-testing
rm -rf .agents/skills/e2e-flow-check
rm -rf .agents/commands/mp-e2e.md
rm -rf .agents/commands/op-e2e.md
```

### 添加项目专属 Skill

```bash
mkdir -p .agents/skills/my-custom-skill
cat > .agents/skills/my-custom-skill/SKILL.md << 'EOF'
# My Custom Skill

## 触发条件
用户说 /my-skill

## 执行步骤
1. 步骤一
2. 步骤二

## 输出格式
Markdown 格式的报告
EOF
```

### 调整权限

编辑 `.claude/settings.json`，按需增减：

```json
{
  "permissions": {
    "allow": [
      "Bash(go test *)",       // Go 项目
      "Bash(docker compose *)"  // 用 Docker
    ]
  }
}
```

---

## 常见问题

### Q: 重复运行 init.sh 会怎样？

安全。默认不覆盖已有文件，只合并新内容。

### Q: 支持哪些技术栈检测？

| 后端 | 前端 | 运营后台 |
|------|------|---------|
| Java + Spring Boot (Maven) | Vue 3 | Vue 3 + Element Plus |
| Java + Gradle | React | — |
| Go | uni-app 小程序 | — |
| Python | — | — |
| Node.js (Express/Koa/Nest) | — | — |

### Q: 我的项目不在列表中？

基础注入模式不依赖技术栈检测，任何项目都能用。`--detect` 只是让 CLAUDE.md 更精准，你可以手动编辑它。

### Q: 怎么更新到 bio 最新版本？

```bash
cd /path/to/agent-fullstack-bio
git pull
cd /your-project
/path/to/agent-fullstack-bio/init.sh --detect
```
