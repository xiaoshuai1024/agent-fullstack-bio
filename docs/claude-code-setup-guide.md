# Claude Code 安装、使用与配置指南

> 本文档介绍如何安装和使用 Claude Code（CC），并将 agent-fullstack-bio 注入你的项目。

## 目录

- [什么是 Claude Code](#什么是-claude-code)
- [安装](#安装)
- [首次使用](#首次使用)
- [项目配置](#项目配置)
- [与 agent-fullstack-bio 集成](#与-agent-fullstack-bio-集成)
- [常用操作](#常用操作)
- [Troubleshooting](#troubleshooting)

---

## 什么是 Claude Code

Claude Code 是 Anthropic 推出的**命令行 AI 编码工具**，直接在终端中运行，能：

- 📖 读取和理解你的整个代码库
- ✏️ 编写、修改、重构代码
- 🧪 运行测试并分析结果
- 🔍 搜索代码、追踪调用链
- 🌿 操作 Git（提交、推送、创建 MR）
- 🚀 启动和调试应用

```bash
# 启动 Claude Code
claude

# 或直接给指令
claude "帮我写一个用户注册的 TDD 测试"
```

---

## 安装

### 前提条件

- **Node.js** 18+ （推荐 20+）
- **npm** 或 **pnpm**
- **Git**
- **Anthropic 账号** 或 **API Key**

### 安装方式

```bash
# 方式一：npm 全局安装（推荐）
npm install -g @anthropic-ai/claude-code

# 方式二：npx 直接运行（免安装）
npx @anthropic-ai/claude-code

# 验证安装
claude --version
```

### 认证

```bash
# 首次运行会引导登录
claude

# 或设置 API Key（如果有）
export ANTHROPIC_API_KEY=sk-ant-xxxxx
claude
```

---

## 首次使用

### 在项目中启动

```bash
cd /your-project
claude
```

Claude Code 会自动：
1. 读取项目中的 `CLAUDE.md`（项目指令）
2. 扫描项目结构
3. 进入交互式对话模式

### 基本对话

```
> 帮我分析这个项目的架构
> 写一个 User 类的 CRUD 接口
> 跑一下测试看看覆盖率
> 帮我创建一个 feature 分支
```

### 使用斜杠命令

如果项目已注入 agent-fullstack-bio，输入 `/` 查看所有可用命令：

```
> /tdd           # 进入 TDD 模式
> /plan-template  # 编写技术方案
> /10-bs         # 十轮头脑风暴
> /kd-review     # 全自动审查
```

### 退出和继续

- 退出：`Ctrl+C` 或输入 `/exit`
- 继续上次对话：`claude --continue`
- 恢复上次会话：`claude --resume`

---

## 项目配置

### CLAUDE.md（必须）

每个项目根目录放一个 `CLAUDE.md`，Claude Code 启动时自动读取。

```markdown
# CLAUDE.md

## 项目概述
这是一个 XXX 系统，使用 Spring Boot + Vue 3。

## 技术栈
- 后端：Java 17, Spring Boot 3.x, MySQL
- 前端：Vue 3, TypeScript, Element Plus

## 开发规范
- 代码必须 UTF-8 编码
- 改码后必须跑测试
- 禁止直接 push main 分支

## 测试命令
- 后端：mvn verify
- 前端：pnpm test
```

### .claude/settings.json（权限配置）

定义 Agent 可以自动执行的命令（免确认）：

```json
{
  "permissions": {
    "allow": [
      "Bash(mvn *)",
      "Bash(pnpm run *)",
      "Bash(pnpm test*)",
      "Bash(git *)",
      "Bash(curl *)",
      "Bash(make *)"
    ]
  }
}
```

### .claude/settings.local.json（本地覆盖）

本地专用配置，**不提交到 Git**：

```json
{
  "env": {
    "CLAUDE_CODE_TMPDIR": "/var/tmp/claude-code"
  },
  "permissions": {
    "allow": [
      "Bash(docker *)",
      "Bash(npx *)"
    ]
  },
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Session started at $(date)'",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### .claude/mcp.json（MCP 服务器）

配置外部工具集成：

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {
        "MEMORY_FILE_PATH": ".claude/memory/knowledge-graph.jsonl"
      }
    }
  }
}
```

---

## 与 agent-fullstack-bio 集成

### 快速集成（3 步）

```bash
# 第 1 步：克隆
git clone https://github.com/xiaoshuai1024/agent-fullstack-bio.git

# 第 2 步：在你的项目中运行初始化
cd /your-project
/path/to/agent-fullstack-bio/init.sh

# 第 3 步：启动 Claude Code
claude
```

初始化后你的项目结构变为：

```
your-project/
├── .agents/           ← 注入的 Skills + Commands + Rules
├── .claude/           ← 注入的 Claude Code 配置
├── docs/              ← 注入的开发规范
├── CLAUDE.md          ← 生成/更新的项目指令
└── (你的原有文件...)
```

### 验证集成成功

```bash
claude
# 输入 /
# 应该能看到 /tdd /plan-template /kd-review 等命令
```

### 自定义调整

集成后，你可以：

1. **删掉不需要的 Skills**：`rm -rf .agents/skills/不需要的技能/`
2. **修改 Commands**：编辑 `.agents/commands/*.md`
3. **调整权限**：编辑 `.claude/settings.json`
4. **添加项目规范**：在 `docs/dev/` 下添加你自己的规范

---

## 常用操作

### 模式切换

```bash
# 普通模式（默认）
claude

# 自动接受模式（Agent 自动执行，不逐个确认）
claude --dangerously-skip-permissions

# 指定模型
claude --model claude-opus-4-8

# Fast 模式（更快输出）
# 进入对话后输入 /fast
```

### Hooks（钩子）

在 `settings.local.json` 中配置自动行为：

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "*",
        "hooks": [{
          "type": "command",
          "command": "bash scripts/check-branch.sh",
          "timeout": 5
        }]
      }
    ]
  }
}
```

支持的 Hook 时机：
- `UserPromptSubmit` — 用户提交消息前
- `PostToolUse` — 工具使用后
- `Stop` — Agent 停止时

### 并行 Agent

```bash
# 在对话中让 Agent 使用 worktree 并行开发
> /dispatching-parallel-agents

# 或手动指示
> 使用 worktree 并行实现以下 3 个任务：
> 1. Task A: 用户注册 API
> 2. Task B: 用户登录 API
> 3. Task C: 用户权限 API
```

### 记忆系统

Claude Code 有内置记忆，跨会话保留：

```
> 记住：这个项目使用 pnpm，不要用 npm
> 记住：所有数据库改动必须走 Flyway 迁移
```

---

## Troubleshooting

### Q: 命令不识别

```bash
# 检查 claude 是否在 PATH 中
which claude

# 重新安装
npm install -g @anthropic-ai/claude-code
```

### Q: Skills 不生效

```bash
# 检查 .agents/skills/ 目录是否存在
ls .agents/skills/

# 检查 SKILL.md 是否存在
ls .agents/skills/tdd/SKILL.md

# 确保 CLAUDE.md 中引用了 .agents/
```

### Q: 权限被拒绝

编辑 `.claude/settings.json` 添加需要的命令到 `permissions.allow` 数组。

### Q: 上下文过长被截断

```bash
# 使用 /compact 压缩上下文
> /compact

# 或使用 /clear 重置对话
> /clear
```

### Q: 临时文件目录满

```bash
# 设置临时目录到 /var/tmp
# 在 .claude/settings.local.json 中添加：
{
  "env": {
    "CLAUDE_CODE_TMPDIR": "/var/tmp/claude-code"
  }
}

# 清理旧临时文件
rm -rf /var/tmp/claude-code/*
```

---

## 参考链接

- [Claude Code 官方文档](https://docs.anthropic.com/en/docs/claude-code)
- [Anthropic API](https://docs.anthropic.com/en/api)
- [agent-fullstack-bio GitHub](https://github.com/xiaoshuai1024/agent-fullstack-bio)
