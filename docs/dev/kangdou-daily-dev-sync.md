<!--
description: Pending daily dev sync — must use AskQuestion clickable UI before other work
alwaysApply: false
-->

# KangDou · 每日远端 dev（聊天内可点击选项）

当工作区存在 **`.cursor/state/pending-daily-dev-sync.json`** 时，表示钩子已检测到「本地 `dev` 落后于 `origin/dev`」，必须在聊天里用 **可点击选项** 完成决策，不要用纯文字代替。

## 必须遵守

1. **优先级**：在完成本文件规定的交互之前，不要执行 **Write / 终端改代码 / 长时间实现**；可以先用 **Read** 读取该 JSON（若尚未读入上下文）。
2. **交互形式**：必须调用 **`AskQuestion`**（Cursor Agent 自带的聊天内多选 / 点击回答工具），向用户展示带 **两个可点选项** 的问题，禁止只发一段「请回复同步或稍后」的纯文本作为主交互。
3. **问题内容**：
   - **title**：`远端 dev 有更新`
   - **prompt 正文**：根据 JSON 内 `repos` 逐条列出（仓库 `name`、`behind` 提交数）；可附一句「按 `docs/GIT_WORKFLOW.md`「〇.4」在各仓库同步 dev」。
   - **options**（两项，id 固定如下，便于后续逻辑）：
     - `sync_now` — **现在同步 dev**（依次进入各仓库 `checkout dev`、`pull origin dev`，子模块仓库优先，再主仓库子模块指针如有需要）
     - `later` — **稍后自行处理**（不执行 pull，继续用户当前任务）
4. **用户选择之后**：
   - 使用 **`delete_file`**（或等价删除文件能力）删除 `.cursor/state/pending-daily-dev-sync.json`，避免下次重复弹出。
   - 若用户选 `sync_now`，再按 `docs/GIT_WORKFLOW.md` 在各目录执行同步；若选 `later`，不拉取代码，直接处理用户原诉求。
5. **降级**：仅在当前会话 **无法调用 `AskQuestion`**（工具不可用）时，才用文字列出相同两个选项并请用户明确回复。

## JSON 形状（钩子写入，只读）

- `version`：固定 `1`
- `kind`：固定 `daily-dev-behind`
- `repos`：`{ name, behind }[]`
