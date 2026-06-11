---
description: 提交 frontend 子仓库改动并创建合并到 dev 的 Codeup MR（只产生 MR，禁止直接推送 dev）
---

在仓库根目录执行自动化脚本（依赖 `scripts/codeup/.env` 中的 `YUNXIAO_TOKEN`）：

```bash
bash scripts/pr/publish-to-dev.sh frontend
```

若用户提供了提交说明，追加参数：

```bash
bash scripts/pr/publish-to-dev.sh frontend -m "feat(ui): 说明本次改动"
```

**你必须执行的步骤：**

1. 在**主仓库根目录**执行命令。
2. 确认 **frontend 子模块**当前分支为 `feature/*`、`bugfix/*` 或 `hotfix/*`（禁止在 `dev`/`master` 上操作）。
3. **禁止切换分支**——只能在当前已检出的分支操作。
4. 脚本行为：`git add -A` → `git commit`（若有改动）→ `git push`（推送当前分支，非 dev）→ 调用 `scripts/codeup/create-mr.sh --allow-fallback` 创建指向 **dev** 的 MR。
5. 将终端输出中的 MR 链接（如有 `webUrl`）原文返回给用户。

**约束：** 本命令只产生 MR 到 dev，绝不直接 push 代码到 dev 分支。使用阿里云 Codeup / 云效 MR，禁止使用 GitHub CLI（`gh`）。若缺少 token，提示用户配置 `scripts/codeup/.env` 并参考 `docs/dev/yunxiao-mcp-troubleshooting.md`。
