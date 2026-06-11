---
description: 提交 backend 子仓库改动并创建合并到 dev 的 Codeup MR（只产生 MR，禁止直接推送 dev）
---

在仓库根目录执行：

```bash
bash scripts/pr/publish-to-dev.sh backend
```

可选提交说明：

```bash
bash scripts/pr/publish-to-dev.sh backend -m "feat(api): 说明本次改动"
```

**你必须：** 在主仓库根目录运行；确认 **backend** 子模块当前分支为 `feature/*`、`bugfix/*` 或 `hotfix/*`（禁止在 `dev`/`master` 上操作）；**禁止切换分支**；执行后输出 MR 结果。

**约束：** 本命令只产生 MR 到 dev，绝不直接 push 代码到 dev 分支。Codeup MR、`--allow-fallback`、目标分支 **dev**；禁止 `gh`。缺 token 时指引 `scripts/codeup/.env`。
