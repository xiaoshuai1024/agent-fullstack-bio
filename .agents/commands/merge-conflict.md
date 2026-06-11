---
description: 解决当前项目中的合并冲突。原则：默认保留双方代码；逐文件展示方案并需用户确认；合并后构建+测试；一个项目一个项目进行
---

# /merge-conflict

## 核心原则

1. **默认保留双方代码** — 冲突解决方案默认采用双方代码都保留的策略（`--ours` 和 `--theirs` 都不丢），除非冲突性质决定必须二选一
2. **逐文件确认** — 每个冲突文件都先展示合并方案给用户，用户确认后再执行，**禁止批量自动合并所有文件**
3. **合并后构建+测试** — 每个项目合并完成后，跑对应的构建和单元测试
4. **一个项目一个项目进行** — 先根仓库（fullstack），再按 backend → frontend → operation-backend 顺序逐个处理子模块

---

## 工作流程

### 第 0 步：检查冲突状态

```bash
# 根仓库
git status
git diff --name-only --diff-filter=U        # 所有未合并的冲突文件
git submodule status                         # 子模块指针状态

# 每个子模块
cd frontend && git status && git diff --name-only --diff-filter=U
cd ../backend && git status && git diff --name-only --diff-filter=U
cd ../operation-backend && git status && git diff --name-only --diff-filter=U
cd ..
```

**先判断冲突分布**：确定冲突在根仓库（`frontend`/`backend`/`operation-backend` 子模块指针），还是分布在子模块内部（各自有未合并的文件）。以此决定处理路线。

---

### 第 1 步：展示冲突概况

向用户汇报：
- 总冲突文件数（含各子模块）
- 按项目分组列出冲突文件清单
- 冲突类型（内容冲突 / 子模块指针冲突 / 双方修改等）

等待用户确认要开始处理。

---

### 第 2 步：逐文件处理冲突

对**每一个冲突文件**：

1. **读取冲突内容**：`cat` 或 `git diff` 展示冲突标记（`<<<<<<<`, `=======`, `>>>>>>>`）
2. **展示合并方案**：分析冲突双方，给出推荐的解决方案（遵循「默认保留双方代码」原则）
3. **等待用户确认**后再执行
4. **执行合并**：
   - **内容冲突**：用 `git add <file>` 暂存已合并文件，或用 `git checkout --ours` / `--theirs` 根据方案做选择
   - **双方代码都保留**：手工编辑文件，去除 `<<<<<<<` / `=======` / `>>>>>>>` 标记，保留双方内容
   - **子模块指针冲突**：`git add <submodule-path>`（即选择正确的子模块 commit）

---

### 第 3 步：一个项目完成后构建+测试

当**一个项目**（根仓库或某个子模块）的所有冲突处理完毕后：

| 项目 | 构建+测试命令 |
|------|--------------|
| 根仓库(fullstack) | 无独立构建，确认 `git diff --cached` 正确即可 |
| `backend/` | `mvn -q verify -pl .`（或 `cd backend && mvn -q verify`） |
| `frontend/` | `pnpm test && pnpm run build:mp-weixin` |
| `operation-backend/` | `pnpm test && pnpm run build` |

如果构建/测试失败，**修复后再继续下一个项目**。

---

### 第 4 步：最终验证

所有项目和子模块的冲突都处理完毕后：

1. `git status` — 确认工作区干净
2. 根仓库 `git diff --cached` — 确认暂存内容正确
3. 汇总变更清单汇报给用户
