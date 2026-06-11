<!--
description: 云效 MUST 规则（工作项、PR/MR、MCP 优先），详见 docs/dev/yunxiao-agile-agent.md
alwaysApply: false
-->

# 云效敏捷管理（MUST）

**全文见 `docs/dev/yunxiao-agile-agent.md`**，文首「约定总览（MUST，不可违反）」为硬约束。

## 核心要求

1. **Token 已配置**：拉取/缓存/MR 默认直接执行；**工作项开始/完成/工时须先询问用户**
2. **推断 + 询问**：不要求用户口头说「开始/完成」，根据实质进展推断 → **必须 AskQuestion 弹窗（中文）** → 用户同意后再写入
3. **缓存**：`.cursor/state/yunxiao/`（不提交 Git）
4. **无 token**：按 `AGENTS.md` 完成引导后再写入

## MCP 优先（所有云效相关）

当用户意图涉及 **云效 / Codeup / 合并请求 / 代码库 / 工作项 / 流水线** 时：

1. **MUST 优先使用 Yunxiao MCP Server**（除非用户明确要求非 MCP 路径）
2. **禁止**使用 GitHub CLI（`gh pr create` 等）处理本仓库的 PR/MR
3. 若 MCP 不可用/鉴权失败/缺少工具，仅允许回退到 `scripts/codeup/` 下的文档化 OpenAPI 路径
4. 任何回退**必须在最终消息中说明原因**

## PR/MR 创建（额外约束）

当用户意图为"提交 PR"、"创建 PR"、"创建 MR"或等价语义时：

1. **MUST 使用 Yunxiao MCP Server** 作为创建 PR/MR 的首选路径
2. 若 MCP 不可用，仅允许回退到 `scripts/codeup/create-mr.sh` 或 `scripts/codeup/create-pr-all.sh`
3. **分支策略**：`feature/* -> dev`，禁止直接面向 `master`（热修复除外）
4. **禁止**在用户确认 token 配置且预检通过前创建 PR/MR
5. 后续再次触发 PR/MR 时，若曾出现"首次无 token"场景，必须再次提醒初始化要点

---

## 经验：云效 Codeup MR 合并（MCP 无工具，须脚本回退）

### 场景
需要将已创建的 MR 合并（accept/merge）时，MCP Server 无对应工具。

### 根因
`alibabacloud-devops-mcp-server` v0.3.14 仅暴露 `create/get/list_change_request`，**没有** `merge_change_request` 或类似工具。

### 解决方案
使用 `scripts/codeup/merge-mr.sh` 通过 OpenAPI 回退：

```bash
scripts/codeup/merge-mr.sh --local-id <id> --merge-type rebase --merge-message "msg" --remove-source-branch --allow-fallback
```

API 端点：`POST /oapi/v1/codeup/organizations/{orgId}/repositories/{repoId}/changeRequests/{localId}/merge`
认证：`x-yunxiao-token` 请求头（与 `create-mr.sh` 一致）

### 已验证的 merge-type
- `rebase` ✅ 正常工作
- `no-fast-forward` ❌ "不支持"
- `squash` ❌ "不支持"
- `ff-only` ❓ 未充分验证

### 预防
- 用户请求"合并 MR"时，直接使用 `merge-mr.sh`，无需尝试调用 MCP（已知无工具）
- 创建 MR 时记录 `localId`，后续合并需要此 ID
- `removeSourceBranch=true` 会在合并后自动删除源分支

---

## 经验：merge-mr.sh 返回 404 时须显示指定仓库 ID 和组织 ID

### 场景
`merge-mr.sh --local-id 53 --merge-type rebase --allow-fallback` 返回：
```
Merge MR request failed (HTTP 404).
{"code":404,"errorCode":"SYSTEM_NOT_FOUND_ERROR",
 "errorDescription":"can not find code review by local id:53"}
```
但 MR #53 确实存在（已通过 `create-mr.sh` 创建，`status: UNDER_REVIEW`），且重新创建 MR 时报 409 冲突说明 MR 已存在。

### 根因
`merge-mr.sh` 通过 `git remote get-url origin` 自动检测仓库 ID（调用 `resolve_repository_id()`），但在某些 Git 上下文（子模块、多个 origin 等）中可能解析出不同的仓库 ID，导致 API 查找 MR 时使用错误的仓库。

### 解决方案
显示指定 `--repository-id` 和 `--organization-id`：
```bash
bash scripts/codeup/merge-mr.sh \
  --local-id 53 \
  --repository-id 6638169 \
  --organization-id 69e0392d29ad98af40661eef \
  --merge-type rebase \
  --allow-fallback
```

仓库 ID 可从首次创建 MR 时的返回值获取，或通过 API 查询：
```bash
# 查询仓库 ID（路径 URL-encode）
curl -sS -H "x-yunxiao-token: $YUNXIAO_TOKEN" \
  "https://openapi-rdc.aliyuncs.com/oapi/v1/codeup/organizations/${ORG_ID}/repositories/$(python3 -c 'import urllib.parse; print(urllib.parse.quote("org/repo-path", safe=""))')"
```

### 预防
1. `create-mr.sh` 创建成功后记录 `repositoryId`（可从返回值或日志中提取）
2. 合并时优先使用记录的 `repositoryId` 而非依赖自动检测
3. 如果遇到 404，先确认 MR 是否存在：`409 CONFLICT - 存在进行中的合并请求` 说明存在

