# CLAUDE.md

## 项目概述

**agent-fullstack-bio** — AI Agent 全栈开发脚手架。从生产级多租户社交电商平台中提炼的技能库、工作流模板与开发规范。

本项目不包含业务代码，仅包含：
- `.agents/` — Skills、Commands、Rules
- `.claude/` — Claude Code 配置模板
- `docs/` — 开发规范文档
- `init.sh` — 一键初始化脚本

## 修改规则

### Skills (.agents/skills/)
- 每个 Skill 是一个独立目录，至少包含 `SKILL.md`
- SKILL.md 须包含：触发条件、执行步骤、输出格式
- 修改已有 Skill 前须先 Read 确认当前内容
- 新增 Skill 后须在本文件和 README 中更新列表

### Commands (.agents/commands/)
- 每个 Command 是一个 `.md` 文件
- 第一行须包含 `description:` 描述
- Command 可引用一个或多个 Skill

### Docs (docs/)
- 所有 `.md` 文件使用 UTF-8 without BOM 编码
- 文档命名使用 kebab-case
- 新增规范文档须在 `docs/dev/INDEX.md` 中注册

### 编码规范
- 所有文件 UTF-8 without BOM
- Markdown 文件换行使用 LF（Unix 风格）
- 中文文档使用中文标点

## 测试

本项目无自动化测试。验证方式：
- 复制到目标项目，检查 Skills 是否被 Claude Code 正确识别
- 输入 `/` 查看命令列表是否完整
- 触发一个 Skill 确认执行正常

## Git 工作流

- 主分支: `main`
- 开发分支: `feature/*`
- 提交信息: conventional commit（feat/fix/docs/chore）
- 禁止直接 push 到 `main`，须通过 PR
