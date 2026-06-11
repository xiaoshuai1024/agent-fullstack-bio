---
description: 对有改动的子模块与主仓库依次 git add、commit、push 当前分支（无 MR）；默认按仓自动 conventional commit，可选绑定需求文档
---

**Agent：** 执行本命令前加载 skill **[kangdou-push-all-commit](mdc:.agents/skills/kangdou-push-all-commit/SKILL.md)**（路径推断 + 脚本行为）。若用户要 **语义级 commit 说明**（读懂 diff 再写），加载 **[kangdou-push-all-semantic-commit](mdc:.agents/skills/kangdou-push-all-semantic-commit/SKILL.md)** 并按其逐仓 `commit` + `push`，勿依赖脚本默认标题。

在主仓库根目录执行：

```bash
# 推荐：绑定当前方案/需求 Markdown（提取首个 # 标题参与各仓自动 commit 摘要）
export PUSH_ALL_REQUIREMENT_FILE="$PWD/docs/superpowers/plans/你的方案.md"
bash scripts/git/push-all-changes.sh
```

或固定说明（所有仓同一条）：

```bash
bash scripts/git/push-all-changes.sh -m "feat: 你的改动说明"
```

关闭自动推断、使用旧版固定 chore：

```bash
bash scripts/git/push-all-changes.sh --plain
```

**行为简述**

1. **顺序**：`frontend` → `backend` → `operation-backend` → **主仓库**（与 `create-pr-all` 一致，便于主仓最后推送子模块指针更新）。
2. **何时处理**：某仓库存在未提交变更（含未跟踪且未被 ignore 的文件）时才执行 `git add -A`、`git commit`、`git push -u origin HEAD`；否则跳过并打印 `skip`。
3. **跳过**：子仓库处于 **detached HEAD** 时仅告警并跳过（避免误提交）。
4. **默认提交说明**（无 `-m`、无 `--plain`）：**每个仓库单独**根据暂存路径 + 可选 `PUSH_ALL_REQUIREMENT_FILE` / `docs/superpowers/plans` 最近方案生成 `type(scope): subject`（见 `scripts/git/push-all-commit-msg.lib.sh`）。
5. **`--plain`**：各仓使用 `chore: push-all 同步本地改动 (UTC日期)`。

**与 `/pr-all` 的区别**：本命令**不创建合并请求**，仅本地提交并推送当前分支。

**你必须：** 在终端执行上述脚本并汇总每个仓库的 skip/commit 说明/push 结果及报错。

策略：阿里云 Codeup；禁止 `gh`。
