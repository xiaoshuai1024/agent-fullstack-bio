# Swagger / OpenAPI（后端）

本文档约定 **`backend/`** 如何通过 **SpringDoc** 暴露 **OpenAPI 3** 与 **Swagger UI**，保证新接口可被文档收录并支持 **Try it out** 联调。

---

## 1. 现状（已初始化）

- **依赖**：`springdoc-openapi-starter-webmvc-ui`（见 `backend/pom.xml`）。
- **集中配置**：`com.kangdou.config.OpenApiConfig` — 文档标题、**Bearer** / **X-Tenant-Id** / **X-Request-Id** 安全方案说明、**ApiError** 统一错误 Schema。
- **运行配置**：`application.yml` 中 `springdoc.*`；仅收录 **`/api/**`**；Swagger UI 启用 **持久化 Authorize**（刷新页面不丢 token）。
- **生产**：`application-prod.yml` **默认关闭** `api-docs` 与 `swagger-ui`；本地 `local`  Profile 正常可用。

---

## 2. 本地访问

启动后端（默认 `spring.profiles.active=local`）后：

| 用途 | URL |
|------|-----|
| **Swagger UI（点击调试）** | `http://127.0.0.1:8080/swagger-ui.html` |
| **OpenAPI JSON** | `http://127.0.0.1:8080/v3/api-docs` |

若端口不同，请替换主机与端口。

---

## 3. 新接口必须遵守

1. **Controller**
   - 类上 **`@Tag(name = "...", description = "...")`**：分组清晰（按领域：Ops* / Tenant* / Merchant* 等）。
   - 每个对外方法 **`@Operation(summary = "...")`**，必要时 **`description`**。
   - 路径参数、查询参数使用 **`@Parameter(description = "...")`**（必填项写明）。
2. **请求/响应模型**
   - 复杂 body 或返回 DTO 使用 **`@Schema`**（字段级中文说明 + 示例值）。
   - 列表/分页返回建议在 `@Operation` 的 description 中说明字段含义；能用专用 record/class 则不要用裸 `Map`（渐进收紧）。
3. **错误**
   - 业务抛 **`AppException` + `ApiErrorCode`**；文档层面错误形状见 OpenAPI **Components → Schemas → ApiError**（由 `OpenApiConfig` 注册）。
4. **安全（Swagger UI 调试）**
   - **运营接口** `/api/platform/**`（除登录）：在 UI 右上角 **Authorize** 填入 **Bearer token**（先调 `OpsAuth` 登录）。
   - **需租户上下文**：同时配置 **`X-Tenant-Id`**（与路径 `tenantId` 或业务约定一致）。
   - **公开接口** `/api/public/**`：通常无需 Authorize。

---

## 4. Try it out 不通过时的排查

| 现象 | 处理 |
|------|------|
| 401 / 未登录 | 先 **Authorize** Bearer；登录接口为 `POST /api/platform/auth/login`。 |
| 400 / 缺租户 | 对 tenant-admin、tenant-core 等路径补充 **`X-Tenant-Id`**。 |
| 403 权限不足 | 当前账号缺少 `@RequirePerm` 对应权限点。 |
| CORS | 浏览器直连后端若被拦，属预期；Swagger UI 同源无此问题。 |

---

## 5. 修订记录

| 日期 | 说明 |
|------|------|
| 2026-05-08 | 初版：集中配置、规范与入口 URL |
