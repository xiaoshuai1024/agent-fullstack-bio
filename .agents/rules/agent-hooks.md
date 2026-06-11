<!--
description: Keep hooks 配置文件 and hook scripts in sync (avoid failClosed 127)
alwaysApply: true
-->

# Agent Hooks Hygiene

When editing **hooks 配置文件** or adding/removing scripts under **hooks 脚本目录**:

1. Every `command` path that points at a repo file **must exist** before you finish (missing files with `failClosed: true` can block tools with exit **127**).
2. **`beforeSubmitPrompt`** must return **`continue` / `user_message`** (not `permission`). Do not reuse `beforeShellExecution` response shapes.
3. After changes, run from the repo root: `python3 scripts/verify_cursor_hooks.py` and fix any reported missing paths.
4. Prefer **project-relative** commands like `hooks/my-hook.js` (workspace root is the cwd for project hooks).
