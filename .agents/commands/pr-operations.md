---
description: 提交 operation-backend（运营后台）子仓库并创建合并到 dev 的 Codeup MR（只产生 MR，禁止直接推送 dev）
---

对应子模块路径：`operation-backend`。在仓库根目录执行：

```bash
bash scripts/pr/publish-to-dev.sh operations
```

可选提交说明：

```bash
bash scripts/pr/publish-to-dev.sh operations -m "feat(ops): 说明本次改动"
```

**你必须：** 在主仓库根目录运行；确认 **operation-backend** 子模块当前分支为 `feature/*`、`bugfix/*` 或 `hotfix/*`（禁止在 `dev`/`master` 上操作）；**禁止切换分支**；执行后输出 MR 结果。

**约束：** 本命令只产生 MR 到 dev，绝不直接 push 代码到 dev 分支。Codeup MR、目标 **dev**；禁止 `gh`。需要 `scripts/codeup/.env` 中的 `YUNXIAO_TOKEN`。
