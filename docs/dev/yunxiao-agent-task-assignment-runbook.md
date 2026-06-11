# 云效 Projex：Agent 创建任务并指派（OpenAPI 运行手册）

供 Agent / 人工在**已有迭代**中新建「任务」、指定负责人、挂迭代与描述（含方案链接）。与 `docs/dev/yunxiao-agile-agent.md` 中的**开始/完成/工时**写入约束无关：本流程为**创建工作项**，不自动标「已开始」或登记工时。

**检索工作项列表、MCP 与 `workitems:search` 对照**：见 `docs/dev/yunxiao-operations-cookbook.md`。

## 1. 前置条件

| 项 | 说明 |
|----|------|
| Token | `scripts/codeup/.env` 中配置 `YUNXIAO_TOKEN`（或 `YUNXIAO_ACCESS_TOKEN`），请求头 `x-yunxiao-token`。 |
| 域名 | 默认 `https://openapi-rdc.aliyuncs.com`（与 `CODEUP_DOMAIN` 覆盖规则见 `docs/dev/yunxiao-kangdou-v1-projex-context.md`）。 |
| ID 速查 | **组织、项目、当前冲刺、常用成员 `userId`、任务类型 ID** 以 `docs/dev/yunxiao-kangdou-v1-projex-context.md` 为准；成员变更时先拉成员接口再更新该文档。 |

## 2. 标准流程（curl 示例）

### 2.1 获取「任务」类型 ID（每个空间可能不同，勿硬编码他项目）

```http
GET /oapi/v1/projex/organizations/{organizationId}/projects/{projectId}/workitemTypes?category=Task
```

响应为数组，取 `categoryId == "Task"` 且名称符合项目习惯的一条，记下其 `id` 作为 `workitemTypeId`。

**康豆新平台 v1.0（截至文档更新）**：`workitemTypeId` = `ba102e46bc6a8483d9b7f25c`（名称「任务」）。

### 2.2 创建工作项

```http
POST /oapi/v1/projex/organizations/{organizationId}/workitems
Content-Type: application/json
```

请求体常用字段：

| 字段 | 必填 | 说明 |
|------|------|------|
| `spaceId` | 是 | 项目 ID，即 `projectId`。 |
| `workitemTypeId` | 是 | 见 §2.1。 |
| `subject` | 是 | 标题。 |
| `assignedTo` | 是 | 负责人 `userId`（见上下文文档成员表或 `GET .../members`）。 |
| `sprint` | 否 | 迭代 ID，挂到当前冲刺时填写。 |
| `description` | 否 | **建议纯文本段落**（用空行分段、`【小节】` 等中文标记即可）。云效任务详情里 Markdown 标题/表格/加粗**常不按 MD 渲染**，易被当成字面量；复杂排版改附件或飞书链接。接口返回的 `formatType` 可能仍为 `RICHTEXT`，与是否使用 MD 语法无关。 |
| `customFieldValues` | 否 | 形如 `{"fieldId":"value"}`；优先级等若创建接口报错再按「创建所需字段」接口补全。 |

成功响应示例：`{"id":"<workitemId>"}`。

### 2.3 成员不在「常用成员表」时

```http
GET /oapi/v1/projex/organizations/{organizationId}/projects/{projectId}/members
```

对返回中的 `userId` 去重后指派；必要时更新 `yunxiao-kangdou-v1-projex-context.md` 表格与 `lastVerifiedAt`。

## 3. 云效控制台链接（便于人工与 IM 粘贴）

### 3.1 正确形态（康豆 / 本组织已校验）

`GetWorkitem` 等 OpenAPI **通常不返回**可分享的浏览器 `https` 链接，需按控制台真实路由拼接。对本组织（`organizationId` 见 `yunxiao-kangdou-v1-projex-context.md`），工作项详情应使用：

```text
https://devops.aliyun.com/organization/{organizationId}/project/{spaceId}/issue/{workitemId}
```

其中 `spaceId` 为项目 ID，`workitemId` 为创建接口返回的 `id`（与界面「编号」如 `NZCC-20` 不同，**链接里用 `id`**）。未登录时会经 `account-devops` 跳转登录，`next_url` 中也会体现上述路径。

### 3.2 易错（禁止再用于回复用户）

以下形态曾在文档中误用，**用户反馈打开不正确**；Agent 向用户粘贴链接时 **不要使用**：

```text
https://devops.aliyun.com/projex/project/{spaceId}/issue/{workitemId}
```

若阿里云后续调整路由，以工作项详情页右上角 **「复制链接」** 为准，并回写更新本节。

### 3.3 校准方式（推荐）

在浏览器打开任意一条本项目工作项 → **复制链接** → 对照本节模板提取 `organizationId` / `spaceId` / `workitemId` 三段子路径，确认与上式一致后再固化到文档或 memory。

## 4. Agent 行为约束（与敏捷规则对齐）

- **可直接执行**：按用户明确指令创建/更新工作项标题、描述、负责人、迭代关联等（与 `docs/dev/yunxiao-agile-agent.md` §1.1 一致）。
- **必须先问再写**：工作项是否**已开始**、是否**已完成**、开始/结束时间、**实际工时** —— 仍按 `yunxiao-agile-agent` 全文执行，**禁止**根据「刚建任务」自行推断并写入开始/完成类字段。

## 5. 已登记案例（便于对照）

| 编号 | 标题 | 负责人 | workitemId | 备注 |
|------|------|--------|------------|------|
| NZCC-19 | Sentry 部署 | 宋浩天 | `d4ca597f2ad78e233feeb08dbb` | 迭代：康豆新平台冲刺01；描述中含飞书方案与仓库 Markdown 路径。 |
| NZCC-20 | 后端项目+NGINX改造 | 刘文华 | `0dc31695e15c278e1931afbdfc` | 同上；含 PHP 监控手册飞书/仓库引用；预计工时 8。 |
| NZCC-21 | 前端 Sentry 接入 + 自动化测试实现 | 宋浩天 | `377f8593dd4b96d503c2dd75d9` | 迭代：康豆新平台冲刺01；描述含飞书 Wiki 两链与仓库 Sentry 手册路径；预计工时 10（描述内说明，界面字段需人工核对）。 |
| NZCC-22 | 两周迭代计划任务拆分 | 肖帅 | `7eca00f53d58fc03f3a3ca205b` | 迭代：康豆新平台冲刺01；计划开始/完成均为当日（字段 `79`/`80`）；创建后 `PUT` `status=100010` → **处理中**（等价已开始）。 |

**直达链接（`organizationId` + `spaceId` + `workitemId`，勿用 `/projex/project/`）**：

- NZCC-19：`https://devops.aliyun.com/organization/69e0392d29ad98af40661eef/project/815366a181cb1babbf0eab6e38/issue/d4ca597f2ad78e233feeb08dbb`
- NZCC-20：`https://devops.aliyun.com/organization/69e0392d29ad98af40661eef/project/815366a181cb1babbf0eab6e38/issue/0dc31695e15c278e1931afbdfc`
- NZCC-21：`https://devops.aliyun.com/organization/69e0392d29ad98af40661eef/project/815366a181cb1babbf0eab6e38/issue/377f8593dd4b96d503c2dd75d9`
- NZCC-22：`https://devops.aliyun.com/organization/69e0392d29ad98af40661eef/project/815366a181cb1babbf0eab6e38/issue/7eca00f53d58fc03f3a3ca205b`

## 6. 官方参考

- [CreateWorkitem](https://help.aliyun.com/zh/yunxiao/developer-reference/createworkitem)
- [ListWorkitemTypes](https://help.aliyun.com/zh/yunxiao/developer-reference/listworkitemtypes)

## 7. 修订记录

| 日期 | 变更 |
|------|------|
| 2026-05-06 | 初版：OpenAPI 指派流程、控制台 URL 形态、NZCC-19 案例；与 `yunxiao-kangdou-v1-projex-context.md` 交叉引用。 |
| 2026-05-06 | **更正控制台链接**：弃用 `/projex/project/{spaceId}/issue/...`；改用 `/organization/{organizationId}/project/{spaceId}/issue/...`（用户确认）；补充 NZCC-20 与 §3.3 校准说明。 |
| 2026-05-06 | 补充 NZCC-21（前端 Sentry + 自动化测试，负责人宋浩天，预计工时 10）。 |
| 2026-05-06 | 补充 NZCC-22（两周迭代计划任务拆分，负责人肖帅；计划完成日当日；状态 **处理中** `status=100010`）。 |
