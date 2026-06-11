---
description: 仅提交主仓库 kangdou-fullstack 并创建合并到 dev 的 Codeup MR（只产生 MR，禁止直接推送 dev）
---

在仓库根目录执行：

```bash
bash scripts/pr/publish-to-dev.sh fullstack
```

可选：

```bash
bash scripts/pr/publish-to-dev.sh fullstack -m "docs: 说明主仓变更"
```

**说明：** 脚本会检查 `frontend`、`backend`、`operation-backend` 三个子模块工作区是否干净；若任一子模块仍有未提交变更，会报错并提示先单独提交子模块或使用 `/pr-all`。

**你必须：** 确认主仓库分支为 `feature/*`、`bugfix/*` 或 `hotfix/*`（禁止在 `dev`/`master` 上操作）；**禁止切换分支**；运行命令并返回 MR 输出。

**约束：** 本命令只产生 MR 到 dev，绝不直接 push 代码到 dev 分支。Codeup MR → **dev**；禁止 `gh`。依赖 `YUNXIAO_TOKEN`。
