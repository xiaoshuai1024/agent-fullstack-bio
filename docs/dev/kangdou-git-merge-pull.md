<!--
description: 禁止自动合并；冲突须询问用户；pull 前先 commit 未提交改动
globs: "**/*"
alwaysApply: false
-->

# Git 合并与拉取（MUST）

全文与流程细节见 [GIT_WORKFLOW.md](docs/GIT_WORKFLOW.md) **〇.6**。

## 必须遵守

1. **不要自动合并代码**
   - 不得在用户未逐步明确授权的情况下，自行完成会产生合并结果的 `git merge` / `git rebase` / `git cherry-pick` 等并推送。
   - 不得用「全接受本地/远端」等方式静默解决冲突并提交。

2. **发现冲突时**
   - **停止**继续写 Git 历史。
   - 向用户说明冲突上下文，**询问用户希望如何合并**。
   - **在得到用户明确指示前**，不提交合并、不假定策略。

3. **用户要求 pull / 拉代码时**
   - 若存在**未提交**的本地改动：须先与用户确认并完成 **`git commit`**（仅当用户**明确**要求时才用 `stash` 等代替），**再**执行 `pull`。
   - 禁止在未处理工作区改动时直接 `pull`。

## 关联

- [AGENT_RULES.md](docs/AGENT_RULES.md) §1
- [AGENTS.md](AGENTS.md)「Git 硬约束」

---

## 经验：detached HEAD 合并后子模块指针丢失

### 场景
在 detached HEAD 上向子模块执行 merge 并提交后，切回 feature 分支时，子模块 gitlink 条目（mode=160000）可能丢失，导致 git status 显示 `M backend/frontend/operation-backend` 但 `git ls-files --stage` 无对应条目，子模块目录变成空。

### 根因
detached HEAD 上执行 `git rm --cached` 清理 worktree gitlink 时可能误删真实子模块条目；切回分支时这些条目未随分支恢复。

### 解决方案
用 `git update-index --add --cacheinfo` 恢复子模块指针：
```bash
git update-index --add --cacheinfo 160000,<commit-hash>,backend
git update-index --add --cacheinfo 160000,<commit-hash>,frontend
git update-index --add --cacheinfo 160000,<commit-hash>,operation-backend
```

### 预防
1. 清理 worktree gitlink 时限定路径：`git ls-files --stage .claude/worktrees/ | awk '{print $4}' | xargs git rm --cached`
2. 合并前先 `git checkout feature/xxx` 切换到有名字的分支，避免在 detached HEAD 上操作
3. 合并完成后验证 `git ls-files --stage backend frontend operation-backend` 三条目均存在

---

## 经验：worktree gitlink 阻断 `git submodule update --init`

### 场景
`git submodule update --init --recursive` 报错：
```
fatal: No url found for submodule path '.claude/worktrees/agent-xxx' in .gitmodules
```
导致子模块无法初始化，后续 merge 受阻。

### 根因
Claude Code `isolation: worktree` 创建的 worktree 目录被记录为 gitlink（mode=160000）进入 index，但 `.gitmodules` 中没有对应条目。这些残留条目会递归传导到子模块内部。

### 解决方案
```bash
# 主仓库 + 各子模块均须清理
git ls-files --stage .claude/worktrees/ | awk '{print $4}' | xargs git rm --cached --ignore-unmatch

# 清理子模块内的 worktree 残留
for mod in backend frontend operation-backend; do
  git -C "$mod" ls-files --stage .claude/worktrees/ 2>/dev/null | \
    awk '{print $4}' | xargs git -C "$mod" rm --cached --ignore-unmatch
done
```

### 预防
1. `isolation: worktree` 的 agent 结束后，检查是否有残留 worktree gitlink
2. merge 前先执行 `git submodule update --init --recursive` 验证初始化正常

---

## 经验：merge 后未解决的冲突标记残留（2026-05-22）

### 场景
`git merge origin/dev` 后 `git status` 显示 clean，但代码中存在 11 个文件含 `<<<<<<< HEAD` / `=======` / `>>>>>>> origin/dev` 冲突标记。前端单测报 `Unexpected token` (Vue SFC compiler) 和 `TS1185: Merge conflict marker encountered` 错误。

### 根因
合并提交已创建（`Already up to date`），但某次合并操作未正确完成三方合并，导致冲突标记被提交到仓库中。`git status` 不显示冲突因为冲突已在历史提交中"解决"（实际未解决）。

### 解决方案
```bash
# 1. 发现所有冲突
grep -rn '<<<<<<< HEAD' src/ --include='*.vue' --include='*.ts' --include='*.js'

# 2. 逐文件取正确版本（本例取 origin/dev 版本）
git show origin/dev:path/to/file.vue > path/to/file.vue

# 3. 验证无残留
grep -rn '<<<<<<< HEAD' src/ e2e/ test/
```

### 预防
- **合并后强制检查**：每次 `git merge` 或 `git pull` 后执行：
  ```bash
  grep -rn '<<<<<<< HEAD' src/ e2e/ test/ --include='*.vue' --include='*.ts' --include='*.js' --include='*.java' --include='*.xml' --include='*.sql'
  ```
- 发现冲突标记即阻止继续，先解决冲突再运行任何测试
- 前端 `.vue` 文件的冲突标记会导致整个组件解析失败（Vue SFC compiler），而非仅单行报错

---

## 经验：worktree 分支合并后子模块指针停留在旧 commit

### 场景
在 worktree 分支中开发 frontend 子模块改动（设计 token 系统 3 个 commit），worktree 主仓子模块指针正确指向 `91b6f85`。
`git merge worktree-branch` 到当前分支后，frontend 子模块指针仍停留在旧 commit `69f63c6`，
design token 文件在工作区不可见。

### 根因
`git merge` 默认合并策略在子模块冲突时倾向于保留当前分支的指针（merge base 一侧的值）。
合并提交虽创建成功，但子模块指针字段采用了错误侧的值，worktree 分支的正确指针在冲突解析中丢失。

### 解决方案
```bash
# 1. 查看 worktree 中子模块的正确 commit
git -C .claude/worktrees/<name>/frontend rev-parse HEAD

# 2. 手动更新 index 中的子模块指针
git update-index --cacheinfo 160000,<correct-hash>,frontend
git add frontend && git commit -m "chore: update frontend submodule pointer"
```

### 预防
1. merge 后必检：`git submodule status --cached frontend` 确认指针正确
2. worktree 开发完先 push 子模块再合并主仓
3. 子模块指针提交独立一个 commit，便于发现和恢复
4. `git merge-base --is-ancestor` 判断分支关系后再决定是否需要 MR

---

## 经验：Codeup API 拒绝已合并分支的 MR——源分支无新改动

### 场景
worktree 分支已 merge 到目标分支后，`create-mr.sh --source worktree-branch --target target-branch` 返回：
`400 BAD_REQUEST - 源分支相对目标分支没有改动，不能新建代码评审`

### 根因
`git merge-base` 返回源分支 HEAD 本身（已 merge），Codeup API 判断两个分支在历史中无差异。

### 解决方案
已合并的分支直接 push target 即可，无需额外 MR。
如需 MR，必须从包含新 commit 的分支（非祖先）发起。

### 预防
创建 MR 前：`git merge-base --is-ancestor source target && echo "already merged"`

---

## 经验：superproject merge 子模块报 "commits don't follow merge-base"

### 场景
主仓库执行 `git merge dev-vnext2` 时，子模块全部报错：
```
Failed to merge submodule backend (commits don't follow merge-base)
CONFLICT (submodule): Merge conflict in backend
Recursive merging with submodules currently only supports trivial cases.
Please manually handle the merging of each conflicted submodule.
```
同时提示需 merge 的具体 commit hash：`go to submodule (frontend), and either merge commit 733c62a or update to an existing commit which has merged those changes`

### 根因
各子模块的 feature 分支缺少目标分支（如 dev-vnext2）的最新提交（`c6d62a9` / `733c62a` / `17db4ae`），子模块指针与目标分支指针分叉，superproject 无法自动递归合并。

### 解决方案
逐子模块 fetch + merge 目标分支：
```bash
# 进入每个冲突的子模块
git fetch origin dev-vnext2
git merge <commit-hash>    # 或用 --strategy-option theirs 全收 incoming
# 合并完成后
git add . && git commit -m "chore: merge dev-vnext2 using incoming changes"

# 全部完成后在主仓库提交指针更新
git add frontend backend operation-backend
git commit -m "chore: resolve submodule merge conflicts"
```

全收 incoming 批量解决文件冲突：
```bash
git checkout --theirs . && git add . && git commit
```

### 预防
1. 合并前先 `git fetch origin dev-vnext2` 确认目标分支最新
2. `git submodule update --remote` 提前同步各子模块
3. 子模块指针更新独立 commit，便于排查冲突

---

## 经验：Codeup MR 409 CONFLICT（主仓库已有进行中的 MR）

### 场景
`publish-to-dev.sh all` 执行到主仓库时，脚本报 HTTP 409 CONFLICT，提示「存在进行中的合并请求」。

### 根因
Codeup 每个分支只能有一个 **OPEN** 的 MR。主仓库 MR 在前一次 `/pr-all` 时已创建（如 #60），后续再跑 `pr-all` 时脚本尝试为同一 `feature/*` 分支再创建一个，触发 409。

### 解决方案
**这不是错误**——脚本的 `push` 步骤已成功，新提交自动纳入现有 MR。

```
# 推送成功（新 commit 已在 MR 中）
To codeup.aliyun.com:kangdou-fullstack.git
   6b85b5c5..8fb26527  HEAD -> feature/global-search
# 创建 MR 报错（忽略，现有 MR #60 已包含新提交）
Error: HTTP 409 CONFLICT - 存在进行中的合并请求：...#60
```

- ✅ `push` 成功 → 新提交自动在 MR 中，无需任何操作
- ⚠️ 409 错误可忽略，不算失败

### 预防
1. 运行 `/pr-all` 前检查是否已有 open MR：`scripts/pr/publish-to-dev.sh fullstack` 会显示 `[localId]`，或在 Codeup Web UI 查看
2. 若已有 open MR，直接 `git push` 即可（脚本已自动 push，只需忽略 409）
3. 将 409 视为”已存在”的信号，而非错误

---

## 经验：多分支合并实战经验（2026-05-21）

### Flyway 版本号冲突是合并后的头号杀手

#### 场景
两个 feature 分支同时创建 Flyway 迁移，版本号重叠（如双方都用 V3050）但内容不同。

#### 解决方案
1. 合并前先 `ls migration/V30*` 检查现有版本号空间
2. 合并后用 `verify-flyway-unique-versions` Maven 插件做门禁
3. 发现冲突时，为一方重命名到空闲号段（V3064+），**不**重排原始文件

#### 预防
- Flyway `V3023.1` 风格的 decimal 版本在 Flyway Engine 中无效，会被拒绝启动

---

### worktree 隔离在多仓合并中会导致改动丢失

#### 场景
并行 subagent 使用 `isolation: “worktree”` 合并多个子仓库时，worktree 是独立的 git 工作目录，merge 结果**不会写回主仓库**。这导致所有 agent 报告”合并成功”但实际仓库未变。

#### 正确做法
直接在主仓库运行 `git merge`，不用 worktree isolation：

```bash
# 直接在主仓库的子模块目录合并
git -C /Users/john/codes/kangdou-fullstack/backend merge origin/dev-vnext2 --no-edit
git -C /Users/john/codes/kangdou-fullstack/frontend merge origin/dev-vnext2 --no-edit
git -C /Users/john/codes/kangdou-fullstack/operation-backend merge origin/dev-vnext2 --no-edit
```

---

### 合并后必须验证编译，不能只看 git status

#### 场景
合并成功（无冲突标记）不等于编译通过。

#### 常见陷阱
1. **接口方法签名变更**：A 分支改了 interface，B 分支恢复了旧实现类 → 编译报 “method does not override”
2. **import 了已删文件**：A 分支删除了 `group.ts`，B 分支 `GroupBuyOrderDetail.vue` 仍 import → 构建失败
3. **pages.json 分包残留**：A 分支删了 pages/group 子包，B 分支的 pages.json 仍引用 → `pages/group/list not found`

#### 验证命令
- 后端：`mvn -q compile -DskipTests`（最快）
- 前端：`pnpm run build:mp-weixin`
- 运营后台：`pnpm test`

---

### 移除旧功能必须清理全部引用层

#### 场景
团购功能被移除后，有 4 层残留需要逐层清理：

| 层 | 例子 |
|---|------|
| API 层 | `src/api/group.ts` 被删，但 `src/api/index.ts` 仍 `export * from “./group”` |
| 组件层 | `GroupBuyOrderDetail.vue` import 被删的 `createGroupBuyApi` |
| 页面层 | `pages/order/detail.vue` 的 `<GroupBuyOrderDetail>` 和 import |
| 路由层 | `pages.json` 的 `subPackages` 中 `pages/group` 子包引用 |

#### 检查方法
合并后执行 `grep -r “被删模块名” src/ --include=”*.vue” --include=”*.ts”` 确认零引用。

---

### Mockito 顺序敏感性与 SQL contains 匹配

#### 场景
`JdbcTemplate.queryForList(String, Object...)` 在同一个测试方法中被多次调用时：

1. `when(jdbcTemplate.queryForList(anyString(), any(Object[].class))).thenReturn(A, B, C)` 严格按调用顺序返回 A→B→C
2. 若被测方法的调用顺序变化（合并后重构），mock 序列会错位导致 NPE
3. `contains(“xxx”)` 匹配器在同一方法多次使用时会互相干扰

#### 更好的做法
- 使用 `lenient()` 避免 StrictStubbing
- 或按 SQL 片段用 `argThat` 精确区分每个调用
- 对复杂场景改用 `spy` + `doReturn` 精确控制

---

### 前端 Jest 测试 pre-existing failures

#### 场景
项目中 `pnpm test` 有 29 个 pre-existing 失败（`import.meta.env` 在 Jest 环境中不可用），这是测试基础设施的已知问题，**不是**合并引入的。

#### 区分方法
- 看错误信息 `Cannot use 'import.meta' outside a module` → 基础设施问题，非回归
- 看失败文件是否在本次改动中 → 不在则可忽略
- 保留单元测试通过的部分（23 suites, 182 tests passed）

---

### 运营后台 Vitest 31 suites 全绿

运营后台 `pnpm test` 没有 pre-existing failures，31 个 test files 全部通过（117 tests）。合并后应优先验证此结果，它比前端 Jest 更能反映回归。

---

## 经验：`pull-all-dev.sh` 脚本的 `submodule update --init` 导致子模块 detached HEAD

### 场景
执行 `/pull-all dev`（`bash scripts/git/pull-all-dev.sh dev`）时报错：
```
[backend] ERROR: detached HEAD — aborting (dir=.../backend)
```
脚本初始化的 `git submodule update --init` 把子模块 checkout 到主仓 gitlink 记录的提交，detach 了 HEAD。

### 根因
`pull-all-dev.sh` 第 1 步无条件执行 `git submodule update --init "${rel}"`，该命令会把子模块 checkout 到**主仓库 gitlink 记录的旧提交**（无论子模块 feature 分支当前在哪个 commit），导致 detached HEAD。脚本后续的 detached-HEAD 守卫立即报错退出。

关键问题变量：
- 主仓 gitlink ≠ 子模块 feature 分支头 → `update --init` 一定会 detach
- 每次在子模块 commit 新工作后，feature 头就领先 gitlink，下次 pull-all 必挂
- 在分支上开发是正常模式，脚本不应强求 gitlink == 分支头

### 解决方案
修改 `scripts/git/pull-all-dev.sh` 的 init 块，改为**仅初始化尚未检出的子模块**，已存在的跳过：

```bash
# 修改前（无条件 update --init）：
git submodule update --init "${rel}"

# 修改后（跳过已初始化的子模块）：
if [[ -e "${sub_root}/.git" ]]; then
  echo "[${rel}] already initialized, skip (avoid detaching branch)"
  continue
fi
git submodule update --init "${rel}"
```

同时需确保主仓 gitlink 与子模块 feature 分支头一致（否则 per-repo 合并循环也可能出问题）。如果发现 gitlink 落后：
```bash
# 在主仓更新子模块指针
git add backend frontend operation-backend
git commit -m "chore(submodules): update pointers to feature branch tips"
```

### 预防
- 修改 `pull-all-dev.sh` 后，测试循环：commit 子模块 → 主仓 add → pull-all 不 detach
- 保持主仓 gitlink 与子模块分支头同步（尤其是在合并 dev 后）
- 如果遇到 detached HEAD + dirty 文件，先用 `git stash -u` 保护，再切回 feature 分支，然后 `stash pop`
