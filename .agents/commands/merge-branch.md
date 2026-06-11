---
description: 交互式多仓库合并助手：e2e-archi review → merge → 修复 → changelog
---

# /merge-branch

合并远端 feature 分支（主仓库 + 全部子模块），先 review 后合并，统一修复，输出 changelog。

**工作流：** fetch → 预检 → e2e-archi review（仅报告）→ merge + 冲突 → 修复 + 全量测试 → changelog 与报告

---

## 用法

```
/merge-branch <branch-name>
```

参数 `<branch-name>` 为远端分支名，默认主仓库 + 各子模块均使用同名分支。

---

## 工作流

### Step 0：检查参数与环境

```bash
# 使用 set -euo pipefail 确保脚本安全性
set -euo pipefail

# 确认在主仓库根目录
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "${ROOT}" ]]; then
  echo "错误：不在 git 仓库中"
  exit 1
fi
cd "${ROOT}"

# 检查参数
if [[ -z "${1:-}" ]]; then
  echo "错误：缺少分支名参数"
  echo "用法：/merge-branch <branch-name>"
  exit 1
fi
BRANCH="$1"

# 工作区清洁检查
if [[ -n "$(git status --porcelain)" ]]; then
  echo "⚠️  工作区有未提交的变更："
  git status --short
  echo ""
  echo "请先 commit 或 stash 后再合并。"
  exit 1
fi

# 记录合并前的基点，供 changelog 和回滚使用
MERGE_BASE="$(git rev-parse HEAD)"
```

- 未传分支名 → 报错退出
- 工作区不干净 → 提示先 commit/stash 后退出
- 确认当前在主仓库根目录

### Step 1：发现子模块 + Fetch 并检查分支存在性

#### 1.1 从 .gitmodules 发现子模块

```bash
SUBMODULES=()
if [[ -f ".gitmodules" ]]; then
  while IFS= read -r rel; do
    [[ -z "${rel}" ]] && continue
    SUBMODULES+=("${rel}")
  done < <(git config --file .gitmodules --get-regexp '^submodule\..*\.path$' | awk '{ print $2 }' | sort -u)
fi
```

不再硬编码 3 个子模块，动态从 `.gitmodules` 发现。

#### 1.2 初始化子模块工作树

```bash
git submodule update --init --recursive
```

#### 1.3 检查分支存在性

对 **主仓库 + 各子模块** 依次执行（各子模块先 cd 进入再操作）：

```bash
# 在主仓库
git fetch origin "${BRANCH}"

# 在子模块目录
cd frontend && git fetch origin "${BRANCH}" && cd ..
cd backend && git fetch origin "${BRANCH}" && cd ..
```

检查各仓库 `origin/${BRANCH}` 是否存在。汇总输出：

```
kangdou-fullstack  → ✅ 分支存在
frontend           → ✅ 分支存在
backend            → ✅ 分支存在
operation-backend  → ❌ 无此分支，跳过
```

- 若子模块无该分支 → 跳过该仓库，继续
- 若主仓库无该分支 → 报错退出

**询问用户是否继续**，等待确认（Y/n）。

### Step 2：Review（e2e-archi）

对 **每个存在目标分支的仓库** 执行代码审查，**仅报告，不修复**。

#### 2.1 收集变更信息

获取每个仓库的 commit 列表和文件变更：

```bash
git log --oneline HEAD..origin/${BRANCH}
git diff --stat HEAD...origin/${BRANCH}
```

#### 2.2 并行审查

使用独立的 subagent（`isolation: worktree`）并行审查每个仓库：

- 加载 skill：`.agents/skills/architecture-review-e2e-tdd/SKILL.md`
- 审查内容：远端分支相对于当前分支的变更（diff + 新增文件 + 修改文件）
- 输出：结构化的审查报告，含 🔴 阻断 / 🟡 主要 / 🔵 建议 三级问题
- 每个仓库独立 subagent，并行启动

#### 2.3 汇总展示

所有审查完成后，汇总展示：

```
━━━ 审查报告 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

backend
  🔴 新增库存 API 缺少事务注解
  🟡 库存扣减未做幂等校验

frontend
  🟡 库存负数未做输入校验
```

- 有 🔴 阻断问题 → 提示风险，询问「是否仍继续合并？风险问题将在修复阶段处理」
- 用户确认后继续，拒绝则退出

### Step 3：Merge + 冲突处理

合并顺序：**子模块 → 主仓库**（先合并子模块确保子模块指针就绪）

对每个仓库：

#### 3.1 执行 Merge

```bash
current_branch="$(git symbolic-ref -q --short HEAD 2>/dev/null || true)"

if [[ -z "${current_branch}" ]]; then
  # detached HEAD：仅更新本地 dev，跳过 merge
  git branch -f dev "origin/${BRANCH}" 2>/dev/null || true
  echo "[${label}] detached HEAD: updated local dev; skip merge"
elif [[ "${current_branch}" == "dev" ]]; then
  # dev 上仅快进
  git merge --ff-only "origin/${BRANCH}"
else
  # 其他分支普通合并
  git merge --no-edit "origin/${BRANCH}"
fi
```

- **dev 分支**：使用 `--ff-only`（仅快进，非快进则报错）
- **其他分支**：使用 `--no-edit`

#### 3.2 无冲突

记录已合并的 commit 列表，继续下一个仓库。

#### 3.3 有冲突 → 逐文件处理

```bash
git diff --name-only --diff-filter=U   # 列出冲突文件
```

对每个冲突文件：

**① 读取冲突内容**

识别 `<<<<<<< HEAD` … `=======` … `>>>>>>> origin/<branch>` 标记。

**② 判断能否保留双方代码**

| 情况 | 判定 | 处理 |
|------|------|------|
| 双方改不同区域（函数/行） | ✅ 可保留双方 | 编辑文件，保留双方代码，去除冲突标记 |
| 双方改同区域但语义不冲突（如同一个 import 块加不同导入） | ✅ 可保留双方 | 合并后去重，去除冲突标记 |
| 双方改同区域且语义冲突（如同个函数不同实现、同个配置不同值） | ❌ 不可保留 | 展示给用户，等待决策 |
| 双方加了重复代码（如同个方法/配置出现两次） | ⚠️ 去重后可保留 | 去重后保留一份，去除冲突标记 |

**③ 执行**

- 可保留双方 → 自动编辑文件 → `git add <file>`
- 不可保留 → 展示冲突 + 推荐方案 → **等待用户确认**后再执行
- 重复代码 → 去重后保留一份 → `git add <file>`

**④ 全部解决后完成 merge**

```bash
git commit --no-edit
```

**⑤ 主仓库特殊处理：子模块指针冲突**

主仓库 merge 时若子模块指针有冲突（双方都改了指针），按「保留远端分支的指针」优先（因为子模块本身已经合完）：

```bash
# 检测子模块指针冲突（通过 git ls-files --stage 检查 mode=160000）
git diff --name-only --diff-filter=U | while IFS= read -r f; do
  # mode 160000 = gitlink（子模块指针）
  if git ls-files --stage "${f}" 2>/dev/null | grep -q "^160000"; then
    # 子模块指针冲突，接受远端版本（子模块本身已合完）
    git checkout --theirs "${f}"
    git add "${f}"
  fi
done
```

#### 3.4 每个仓库合并完成后

记录合并结果（变更摘要留到 Step 5 统一生成 changelog）：

- 合并结果（成功 / 冲突 / 跳过）
- 冲突文件清单及处理方式（如有）
- 子模块合并后，若有指针变更，记录其路径和 commit

### Step 4：修复 + 全量测试

汇总 Step 2 发现的所有 🔴 阻断 和 🟡 主要 问题。

#### 4.1 修复问题

- 按 后端 → 前端 → 运营后台 顺序修复
- 每个修复遵循 TDD（先写失败测试 → 实现 → 验证）
- 对跨仓库的问题，可从受影响最深的仓库开始

#### 4.2 跑全量测试

每个子项目按以下命令执行：

| 项目 | 命令 | 说明 |
|------|------|------|
| root | `git diff --cached` | 确认暂存内容正确 |
| backend | `mvn -q verify` | 单测 + 集成测 |
| frontend | `pnpm test` | Vitest 单测 |
| frontend | `pnpm run build:mp-weixin` | 小程序构建验证 |
| operation-backend | `pnpm test` | Vitest 单测 |

- 若测试失败 → 修复直到全部通过
- 上一个通过后才进入下一个
- 前端特例：**必须同时跑通单测和构建**，两项都通过才视为完成

#### 4.3 后端启动验证

使用后台模式启动后端，验证可正常启动后自动关闭（兼容 macOS/Linux）：

```bash
cd backend

# 后台启动
mvn -q spring-boot:run -Dspring-boot.run.profiles=local &
BACKEND_PID=$!

# 看门狗：60 秒后自动关闭（兼容 macOS，不需要 timeout 命令）
(sleep 60 && kill "${BACKEND_PID}" 2>/dev/null) &
WATCHDOG_PID=$!

# 等待健康检查通过（最多 50 秒，每秒探测一次）
BACKEND_READY=false
for i in $(seq 1 50); do
  if curl -sf http://127.0.0.1:8080/actuator/health >/dev/null 2>&1; then
    echo "✅ 后端启动成功"
    BACKEND_READY=true
    break
  fi
  sleep 1
done

# 关闭后端和看门狗
kill "${BACKEND_PID}" 2>/dev/null || true
kill "${WATCHDOG_PID}" 2>/dev/null || true
wait "${BACKEND_PID}" 2>/dev/null || true
wait "${WATCHDOG_PID}" 2>/dev/null || true

if [[ "${BACKEND_READY}" != "true" ]]; then
  echo "⚠️  后端未在 50 秒内就绪，请检查日志"
fi
cd ..
```

### Step 5：Changelog + 最终报告

#### 5.1 生成 Changelog

对每个仓库，使用 Step 0 记录的 `MERGE_BASE` 提取本次合入的 commit 信息：

```bash
git log --oneline --no-merges "${MERGE_BASE}..HEAD"
```

按约定分类（从 commit message 前缀识别）：

| 前缀 | 分类 |
|------|------|
| `feat` / `feature` | 新功能 |
| `fix` | 修复 |
| `chore` | 杂务 / 构建 |
| `refactor` | 重构 |
| `docs` | 文档 |
| `test` | 测试 |
| `style` | 样式/格式 |
| `perf` | 性能 |

#### 5.2 输出最终报告

格式如下：

```
━━━ 合并报告：<source> → <target> ━━━━━━━━━━━━━━━━━━━

  分支: feature/<branch-name>
  基点: ${MERGE_BASE}

  ┌─ frontend ──────────────────────────────────────┐
  │  合并 3 个 commit                                │
  │  feat: 库存设置页面                              │
  │  feat: SKU 选择器组件                            │
  │  fix: 库存负数校验                               │
  │  冲突: src/pages/inventory.vue → 保留双方        │
  └──────────────────────────────────────────────────┘

  ┌─ backend ────────────────────────────────────────┐
  │  合并 5 个 commit                                │
  │  feat: 库存管理 API                              │
  │  feat: 库存扣减接口                              │
  │  fix: 库存事务注解缺失                           │
  │  冲突: 无                                        │
  └──────────────────────────────────────────────────┘

  ┌─ operation-backend ──────────────────────────────┐
  │  跳过（无此分支）                                 │
  └──────────────────────────────────────────────────┘

  ┌─ Review 问题修复 ────────────────────────────────┐
  │  🔴 后端库存API缺少事务注解             → 已修复  │
  │  🟡 库存扣减未做幂等校验                 → 已修复  │
  │  🟡 前端库存负数未做输入校验             → 已修复  │
  └──────────────────────────────────────────────────┘

  ┌─ 构建/测试 ──────────────────────────────────────┐
  │  backend          mvn verify        ✅ PASS      │
  │  frontend         pnpm test         ✅ PASS      │
  │  frontend         pnpm build:mp-wx   ✅ PASS      │
  │  operation        pnpm test         ✅ PASS      │
  │  backend start    验证启动           ✅ OK        │
  └──────────────────────────────────────────────────┘

  合并完成。如需要创建 MR，可执行 /pr-all
```

## 回滚指引

若合并后需要回退：

```bash
# 使用 Step 0 记录的 MERGE_BASE 回退
# 查看本次合并的内容
git log --oneline --no-merges "${MERGE_BASE}..HEAD"

# 软回退（保留工作区，取消暂存）
git reset --soft "${MERGE_BASE}"

# 或完全回退（丢弃合并产生的所有改动）
git reset --hard "${MERGE_BASE}"
```

每个子模块独立回退（子模块的 MERGE_BASE 已在各自步骤中记录，或使用 ORIG_HEAD）：

```bash
cd frontend && git reset --hard ORIG_HEAD 2>/dev/null || true
cd ../backend && git reset --hard ORIG_HEAD 2>/dev/null || true
cd ../operation-backend && git reset --hard ORIG_HEAD 2>/dev/null || true
cd .. && git reset --hard "${MERGE_BASE}"
```

---

## 约束与注意事项

1. **禁止假绿** — 修复阶段测试必须真实跑通，不得跳过或 mock
2. **禁止自动提交到远端** — 本命令仅做本地合并，不 push 不创建 MR
3. **禁止静默跳过冲突** — 每个不可自动解决的冲突均需用户确认
4. **工作区卫生** — 开始前检查工作区是否干净，有未提交变更则提示先 commit/stash
5. **子模块指针** — 主仓库合并时若子模块指针有冲突（双方都改了指针），按「保留远端分支的指针」优先（因为子模块本身已经合完）
6. **修复阶段范围** — 仅修复 Step 2 发现的问题，不扩充 Scope
7. **合并顺序** — 先合并所有子模块，再合并主仓库（确保子模块指针就绪后再处理主仓库）
8. **dev 分支特殊处理** — dev 上使用 `--ff-only` 快进合并，其他分支使用 `--no-edit`

---

## 参考

- 冲突处理细则见 [merge-conflict](./merge-conflict.md)
- e2e-archi review skill: `.agents/skills/architecture-review-e2e-tdd/SKILL.md`
- 项目测试命令见 `AGENTS.md`
- 子模块管理：`.gitmodules`
