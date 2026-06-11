#!/usr/bin/env bash
set -euo pipefail

# agent-fullstack-bio 项目配置增强器
# 用法:
#   init.sh                    # 基础注入
#   init.sh --detect           # 自动检测技术栈 + 配置
#   init.sh --detect --force   # 覆盖已有文件

BIO_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$(pwd)"
PROJECT_NAME="$(basename "$TARGET_DIR")"
FORCE=false
DETECT=false

# ── 参数解析 ──
for arg in "$@"; do
  case "$arg" in
    --detect) DETECT=true ;;
    --force)  FORCE=true ;;
    --help|-h)
      echo "用法: init.sh [--detect] [--force] [--help]"
      echo ""
      echo "  (默认)     基础注入：复制 .agents/ .claude/ docs/"
      echo "  --detect   自动检测技术栈并生成定制化配置"
      echo "  --force    覆盖已有文件（默认跳过）"
      echo "  --help     显示帮助"
      exit 0
      ;;
  esac
done

COPY_FLAG="-n"  # 默认不覆盖
if $FORCE; then COPY_FLAG="-f"; fi

echo "🚀 Agent Fullstack Bio - 项目配置增强器"
echo "   源: $BIO_DIR"
echo "   目标: $TARGET_DIR ($PROJECT_NAME)"
echo "   模式: $(${DETECT} && echo '自动检测' || echo '基础注入')"
echo ""

# ════════════════════════════════════════
# 第 1 步：基础注入
# ════════════════════════════════════════

echo "📦 [1/4] 注入 .agents/ ..."
if [ -d "$TARGET_DIR/.agents" ]; then
  cp -r "$BIO_DIR/.agents/"* "$TARGET_DIR/.agents/" 2>/dev/null || true
  echo "   ✅ 合并完成"
else
  cp -r "$BIO_DIR/.agents" "$TARGET_DIR/.agents"
  echo "   ✅ 复制完成"
fi

echo "📦 [2/4] 注入 .claude/ ..."
if [ -d "$TARGET_DIR/.claude" ]; then
  cp $COPY_FLAG "$BIO_DIR/.claude/settings.json" "$TARGET_DIR/.claude/" 2>/dev/null || true
  cp $COPY_FLAG "$BIO_DIR/.claude/mcp.json" "$TARGET_DIR/.claude/" 2>/dev/null || true
  # settings.local.json 始终不覆盖（含本地配置）
  if [ ! -f "$TARGET_DIR/.claude/settings.local.json" ]; then
    cp "$BIO_DIR/.claude/settings.local.json" "$TARGET_DIR/.claude/"
  fi
  echo "   ✅ 合并完成（保留本地配置）"
else
  cp -r "$BIO_DIR/.claude" "$TARGET_DIR/.claude"
  echo "   ✅ 复制完成"
fi

echo "📦 [3/4] 注入 docs/ ..."
if [ -d "$TARGET_DIR/docs" ]; then
  for doc in SUPERPOWERS.md GIT_WORKFLOW.md AGENT_RULES.md PROJECT_DOCUMENT_WRITING_SPEC.md UI_SPEC_FOR_AGENTS.md interaction-preferences.md; do
    cp $COPY_FLAG "$BIO_DIR/docs/$doc" "$TARGET_DIR/docs/" 2>/dev/null && echo "   + docs/$doc"
  done
  mkdir -p "$TARGET_DIR/docs/dev" "$TARGET_DIR/docs/superpowers/templates"
  cp -r "$BIO_DIR/docs/dev/"* "$TARGET_DIR/docs/dev/" 2>/dev/null || true
  cp -r "$BIO_DIR/docs/superpowers/"* "$TARGET_DIR/docs/superpowers/" 2>/dev/null || true
  cp $COPY_FLAG "$BIO_DIR/docs/claude-code-setup-guide.md" "$TARGET_DIR/docs/" 2>/dev/null || true
  echo "   ✅ 文档合并完成"
else
  cp -r "$BIO_DIR/docs" "$TARGET_DIR/docs"
  echo "   ✅ 文档复制完成"
fi

# ════════════════════════════════════════
# 第 2 步：技术栈检测（--detect）
# ════════════════════════════════════════

BACKEND_TYPE="none"
FRONTEND_TYPE="none"
OPS_TYPE="none"
HAS_DOCKER=false
HAS_MAKEFILE=false
DB_TYPE="none"
PKG_MANAGER="none"

if $DETECT; then
  echo ""
  echo "🔍 [4/4] 检测技术栈 ..."

  # ── 后端检测 ──
  if [ -f "pom.xml" ]; then
    BACKEND_TYPE="java-maven"
    grep -q "spring-boot" pom.xml 2>/dev/null && BACKEND_TYPE="java-springboot"
    echo "   后端: Java + Maven (Spring Boot)"
  elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
    BACKEND_TYPE="java-gradle"
    echo "   后端: Java + Gradle"
  elif [ -f "go.mod" ]; then
    BACKEND_TYPE="go"
    echo "   后端: Go"
  elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
    BACKEND_TYPE="python"
    echo "   后端: Python"
  elif [ -f "package.json" ] && grep -q '"express\|koa\|fastify\|nest"' package.json 2>/dev/null; then
    BACKEND_TYPE="node"
    echo "   后端: Node.js"
  fi

  # ── 前端检测 ──
  for dir in frontend src/web src/app; do
    if [ -d "$dir" ]; then
      if [ -f "$dir/package.json" ]; then
        grep -q 'uni-app\|vue' "$dir/package.json" 2>/dev/null && FRONTEND_TYPE="vue" && echo "   前端: Vue (在 $dir/)"
        grep -q 'react\|next' "$dir/package.json" 2>/dev/null && FRONTEND_TYPE="react" && echo "   前端: React (在 $dir/)"
        grep -q 'uni-app' "$dir/package.json" 2>/dev/null && FRONTEND_TYPE="uniapp" && echo "   前端: uni-app 小程序 (在 $dir/)"
      fi
    fi
  done

  # ── 运营后台检测 ──
  for dir in operation-backend admin ops-admin admin-web; do
    if [ -d "$dir" ] && [ -f "$dir/package.json" ]; then
      OPS_TYPE="vue"
      echo "   运营后台: Vue 3 (在 $dir/)"
      break
    fi
  done

  # ── 基础设施检测 ──
  [ -f "Dockerfile" ] || [ -f "docker-compose.yml" ] && HAS_DOCKER=true && echo "   Docker: ✅"
  [ -f "Makefile" ] && HAS_MAKEFILE=true && echo "   Makefile: ✅"
  [ -f "pom.xml" ] && grep -q "mysql" pom.xml 2>/dev/null && DB_TYPE="mysql" && echo "   数据库: MySQL"
  [ -f "pom.xml" ] && grep -q "postgresql" pom.xml 2>/dev/null && DB_TYPE="postgresql" && echo "   数据库: PostgreSQL"

  # ── 包管理器检测 ──
  [ -f "pnpm-lock.yaml" ] && PKG_MANAGER="pnpm"
  [ -f "yarn.lock" ] && PKG_MANAGER="yarn"
  [ -f "package-lock.json" ] && PKG_MANAGER="npm"
  echo "   包管理器: ${PKG_MANAGER:-未检测到}"

  # ── 生成 CLAUDE.md ──
  if $FORCE || [ ! -f "$TARGET_DIR/CLAUDE.md" ]; then
    echo ""
    echo "📝 生成 CLAUDE.md ..."
    generate_claude_md
    echo "   ✅ CLAUDE.md 已生成"
  else
    echo ""
    echo "📝 CLAUDE.md 已存在，跳过（用 --force 覆盖）"
  fi

  # ── 生成 .gitignore 补充 ──
  if [ ! -f "$TARGET_DIR/.gitignore" ]; then
    echo "📄 生成 .gitignore ..."
    cp "$BIO_DIR/.gitignore" "$TARGET_DIR/.gitignore"
    echo "   ✅ .gitignore 已生成"
  fi

else
  echo "📝 [4/4] 生成 CLAUDE.md 模板 ..."
  if [ ! -f "$TARGET_DIR/CLAUDE.md" ]; then
    generate_claude_md
    echo "   ✅ 基础模板已生成（用 --detect 生成定制版本）"
  else
    echo "   ⏭  已存在，跳过"
  fi
fi

echo ""
echo "✅ 初始化完成！"
echo ""
echo "下一步："
echo "  1. 编辑 CLAUDE.md 填写项目信息"
echo "  2. 运行 claude 启动 Claude Code"
echo "  3. 输入 / 查看可用命令"
if $DETECT; then
  echo ""
  echo "检测到的技术栈："
  echo "  后端: $BACKEND_TYPE"
  echo "  前端: $FRONTEND_TYPE"
  echo "  运营: $OPS_TYPE"
  echo "  包管理: $PKG_MANAGER"
fi

# ════════════════════════════════════════
# 函数：生成 CLAUDE.md
# ════════════════════════════════════════
generate_claude_md() {
  cat > "$TARGET_DIR/CLAUDE.md" << CLAUDEOF
# CLAUDE.md

## 项目概述
TODO: 填写项目描述

## 技术栈
CLAUDEOF

  # 后端
  case "$BACKEND_TYPE" in
    java-springboot)
      cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'
- 后端: Java 17, Spring Boot 3.x, Maven, MySQL
- DB 迁移: Flyway
CLAUDEOF
      ;;
    java-maven)
      cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'
- 后端: Java, Maven
CLAUDEOF
      ;;
    go)
      cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'
- 后端: Go
CLAUDEOF
      ;;
    python)
      cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'
- 后端: Python
CLAUDEOF
      ;;
    node)
      cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'
- 后端: Node.js
CLAUDEOF
      ;;
  esac

  # 前端
  case "$FRONTEND_TYPE" in
    vue) cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'
- 前端: Vue 3, TypeScript, Vite
CLAUDEOF
      ;;
    react) cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'
- 前端: React, TypeScript
CLAUDEOF
      ;;
    uniapp) cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'
- 前端: uni-app (Vue 3), TypeScript, 微信小程序
CLAUDEOF
      ;;
  esac

  # 运营后台
  if [ "$OPS_TYPE" = "vue" ]; then
    cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'
- 运营后台: Vue 3, Element Plus, Pinia
CLAUDEOF
  fi

  # 通用部分
  cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'

## Agent 工具集
- **Skills**: `.agents/skills/` — 80+ AI 技能
- **Commands**: `.agents/commands/` — 28 个斜杠命令
- **Rules**: `.agents/rules/` — 行为约束
- **规范**: `docs/dev/` — 开发规范文档
- **工作流**: `docs/SUPERPOWERS.md` — 工作流总纲
- **Claude Code 设置**: `docs/claude-code-setup-guide.md`
CLAUDEOF

  # 添加构建和测试命令
  case "$BACKEND_TYPE" in
    java-springboot|java-maven)
      cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'

## 快速命令
### 后端
```bash
mvn -q verify                  # 单测 + 集成测
mvn spring-boot:run            # 本地启动
mvn clean package -DskipTests  # 构建
```
CLAUDEOF
      ;;
    go)
      cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'

## 快速命令
### 后端
```bash
go test ./...    # 测试
go build         # 构建
go run .         # 启动
```
CLAUDEOF
      ;;
  esac

  case "$FRONTEND_TYPE" in
    vue|react)
      cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'
### 前端
```bash
pnpm run dev      # 开发
pnpm test         # 测试
pnpm run build    # 构建
```
CLAUDEOF
      ;;
    uniapp)
      cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'
### 小程序前端
```bash
pnpm run dev:h5          # H5 开发
pnpm run dev:mp-weixin   # 微信小程序开发
pnpm run build:mp-weixin # 构建微信小程序
pnpm test                # 测试
```
CLAUDEOF
      ;;
  esac

  # 文件编码
  cat >> "$TARGET_DIR/CLAUDE.md" << 'CLAUDEOF'

## 文件编码
所有文件 UTF-8 without BOM。禁止 GBK / Latin-1。

## 开发规范
1. 修改前必须 Read 确认当前内容
2. 修改后必须运行构建+测试验证
3. 涉及 3+ 文件改动时先列出范围等待确认
CLAUDEOF
}
