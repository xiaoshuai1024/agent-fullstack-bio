#!/usr/bin/env bash
set -euo pipefail

# agent-fullstack-bio 初始化脚本
# 用法: cd your-project && /path/to/agent-fullstack-bio/init.sh

BIO_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$(pwd)"
PROJECT_NAME="$(basename "$TARGET_DIR")"

echo "🚀 Agent Fullstack Bio - 项目初始化"
echo "   源: $BIO_DIR"
echo "   目标: $TARGET_DIR"
echo ""

# 1. 复制 .agents/
if [ -d "$TARGET_DIR/.agents" ]; then
  echo "📁 .agents/ 已存在，合并..."
  cp -rn "$BIO_DIR/.agents/"* "$TARGET_DIR/.agents/" 2>/dev/null || true
else
  echo "📁 复制 .agents/..."
  cp -r "$BIO_DIR/.agents" "$TARGET_DIR/.agents"
fi

# 2. 复制 docs/
if [ -d "$TARGET_DIR/docs" ]; then
  echo "📁 docs/ 已存在，合并通用文档..."
  for doc in SUPERPOWERS.md GIT_WORKFLOW.md AGENT_RULES.md PROJECT_DOCUMENT_WRITING_SPEC.md UI_SPEC_FOR_AGENTS.md interaction-preferences.md; do
    cp -n "$BIO_DIR/docs/$doc" "$TARGET_DIR/docs/" 2>/dev/null && echo "   + docs/$doc" || true
  done
  mkdir -p "$TARGET_DIR/docs/dev"
  cp -rn "$BIO_DIR/docs/dev/"* "$TARGET_DIR/docs/dev/" 2>/dev/null || true
  mkdir -p "$TARGET_DIR/docs/superpowers"
  cp -rn "$BIO_DIR/docs/superpowers/"* "$TARGET_DIR/docs/superpowers/" 2>/dev/null || true
else
  echo "📁 复制 docs/..."
  cp -r "$BIO_DIR/docs" "$TARGET_DIR/docs"
fi

# 3. 生成 CLAUDE.md 提示（如果不存在）
if [ ! -f "$TARGET_DIR/CLAUDE.md" ]; then
  echo "📝 生成 CLAUDE.md 模板..."
  cat > "$TARGET_DIR/CLAUDE.md" << CLAUDEOF
# CLAUDE.md

## 项目概述
TODO: 填写项目描述

## Agent 工具集
- Skills 和 Commands: \`.agents/\` 目录（来自 agent-fullstack-bio）
- 开发规范: \`docs/dev/\` 目录
- 工作流总纲: \`docs/SUPERPOWERS.md\`
- Git 工作流: \`docs/GIT_WORKFLOW.md\`
- Agent 规则: \`docs/AGENT_RULES.md\`

## 可用斜杠命令
输入 \`/\` 查看完整列表，或直接使用：\`/tdd\` \`/plan-template\` \`/e2e-archi\` \`/super-pm\` \`/10-bs\`
CLAUDEOF
fi

echo ""
echo "✅ 初始化完成！"
echo ""
echo "下一步："
echo "  1. 编辑 CLAUDE.md 填写项目信息"
echo "  2. 在 Claude Code 中输入 / 查看可用命令"
echo "  3. 根据项目技术栈调整 docs/dev/ 下的规范"
