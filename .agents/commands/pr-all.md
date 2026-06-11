---
description: 对有改动的子仓库与主仓库依次 commit → push → 创建并自动合并 MR 到 dev（有冲突则等待手动处理）
---

在主仓库根目录执行（至少需要 `YUNXIAO_TOKEN`；`CODEUP_ORGANIZATION_ID` 与单仓库 MR 相同——令牌仅关联一个组织时可不写，多组织时需在 `scripts/codeup/.env` 中指定）：

```bash
bash scripts/pr/publish-to-dev.sh all
```

可选统一标题与提交说明：

```bash
bash scripts/pr/publish-to-dev.sh all -m "chore: 同步各端改动" -t "chore: 同步各端改动"
```

**行为：** 依次处理 frontend → backend → operation-backend → 主仓库，每个仓库执行：
1. commit 本地改动
2. push 到远端
3. 调用 Codeup API 创建 MR 到 dev
4. **尝试自动合并**（API 自动合并）
5. 如果存在冲突 → 输出 MR 链接，等待用户在浏览器手动解决后按 Enter 继续

**你必须：** 各仓库当前分支均符合 `feature/*`、`bugfix/*` 或 `hotfix/*`。执行完整终端输出并汇总每个 MR 链接。

策略：阿里云 Codeup；禁止 `gh`。若脚本报「multiple organizations」，再在 `.env` 中设置 `CODEUP_ORGANIZATION_ID`。
