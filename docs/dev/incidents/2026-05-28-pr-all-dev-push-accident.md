# pr-all 误推 dev 事件

**日期：** 2026-05-28

---

## 现象

```bash
bash scripts/pr/publish-to-dev.sh all
```

前端仓库 `kangdou-uniapp` 在子模块处于 `dev` 分支时被自动 commit + push 到远程 dev，commit message 为当前主仓 MR 的标题而非实际变更内容。

## 根因

`scripts/pr/publish-to-dev.sh` 的 `all` 目标在遍历子模块时**未做分支检查**：

```bash
# 旧的代码（有问题的）
for sub in frontend backend operation-backend; do
  if [[ -d "${REPO_ROOT}/${sub}" ]]; then
    branch="$(git -C "${REPO_ROOT}/${sub}" rev-parse --abbrev-ref HEAD)"
    # ← 此处没有 branch_ok 检查
    git -C "${REPO_ROOT}/${sub}" add -A
    git -C "${REPO_ROOT}/${sub}" commit -m "${sub_msg}"
    git -C "${REPO_ROOT}/${sub}" push origin HEAD
    # 之后还会尝试从 dev → dev 创建 MR（必然 400）
```

对比 `run_mr_from_repo()` 函数内有 `branch_ok()` 检查，但 `all` 目标的子模块循环没有调用该函数，而是内联了 commit+push+MR 的逻辑，遗漏了分支校验。

## 后果

- 前端 `dev` 分支被 push 了一个 commit message 不匹配的提交
- MR 创建阶段因为 `dev → dev` 返回 HTTP 400（源分支和目标分支相同），脚本中断
- 主仓和其他子模块未完成 MR 创建

## 修复

在 `all` 目标的子模块循环中加入 `branch_ok()` 检查，非 `feature/*` / `bugfix/*` / `hotfix/*` 分支跳过 commit+push+MR：

```bash
if ! branch_ok "${branch}"; then
  echo "   ⚠  ${sub} 当前分支「${branch}」不是 feature/* / bugfix/* / hotfix/*，跳过（防止误推 dev）"
  continue
fi
```

**修复文件：** `scripts/pr/publish-to-dev.sh`

## 预防

- `all` 目标的子模块逻辑应与 `run_mr_from_repo()` 保持一致的校验
- 未来重构可考虑让 `all` 目标也调用 `run_mr_from_repo()` 而非内联重复逻辑
- 建议对 `dev`、`master`、`main` 等保护分支做额外防护（即使脚本跳过，git 端 pre-receive hook 也可兜底）
