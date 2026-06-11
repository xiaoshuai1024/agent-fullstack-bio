---
description: 拉取目标分支（默认 dev）代码到当前检出分支，不管当前是什么分支
---

在主仓库根目录执行：

```bash
bash scripts/git/pull-all-dev.sh [BRANCH]
```

`BRANCH` 默认为 `dev`，可传入任意远端存在的分支名。

**行为简述**

1. 按 `.gitmodules` 路径逐个 `git submodule update --init`，初始化子模块目录。
2. **每个仓库（主仓 + 各子模块）**：
   - 检查 **detached HEAD** → 任一仓库处于 detached HEAD 立即报错退出
   - `git fetch origin <branch>` 拉取远端目标分支
   - 无论当前在什么分支，把 **`origin/<branch>` 合并进当前分支**
   - 若已经是最新则跳过
   - 合并冲突时 Git 会中止，需手动解决
3. **不换分支**。

**注意：** 
- 如果只是想拉取 `dev` 到当前分支，不管当前是否 feature 分支，直接 `bash scripts/git/pull-all-dev.sh`
- 不再要求本地 `dev` 指针必须与 `origin/dev` 一致（这是之前的问题根源之一）

**你必须：** 在终端运行上述命令并回报汇总结果（含报错/warn）。
