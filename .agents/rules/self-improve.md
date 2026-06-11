<!--
description: 根据 KangDou 项目出现的模式和新经验持续改进 docs/dev/ 知识文档
globs: "**/*"
alwaysApply: false
-->

# 规则自我改进（Self-Improve）

## 触发条件

本文件收集未匹配到专项规则文件的跨域经验。以下为各次会话沉淀。

---

## 📑 目录

- [触发条件](#触发条件)
- [经验：高保真原型 mobile-frame 结构规范](#经验：高保真原型-mobile-frame-结构规范)
- [经验：运营后台原型必须使用 Element Plus 蓝色主题](#经验：运营后台原型必须使用-element-plus-蓝色主题)
- [经验：数据共享原型概念纠正——商家端不涉及](#经验：数据共享原型概念纠正商家端不涉及)
- [经验：积分豆体系原型边界——无签到无积分商城](#经验：积分豆体系原型边界无签到无积分商城)
- [经验：kd-review 全自动审查循环实践](#经验：kd-review-全自动审查循环实践)
- [经验：FeatureGate 三层特征系统架构](#经验：featuregate-三层特征系统架构)
- [经验：Operation-Backend Vite Build 中的 async/await 错误](#经验：operation-backend-vite-build-中的-asyncawait-错误)
- [经验：公告弹窗分级分端设计](#经验：公告弹窗分级分端设计)
- [经验：灰度管理设计规范](#经验：灰度管理设计规范)
- [经验：经营闭环描述禁止出现在原型中](#经验：经营闭环描述禁止出现在原型中)
- [经验：架构优化与可观测性实施模式](#经验：架构优化与可观测性实施模式)
- [分析流程](#分析流程)
- [规则添加标准](#规则添加标准)
- [规则过时判定](#规则过时判定)
- [规则质量检查](#规则质量检查)
- [经验：Codeup PR 创建 — ORG ID 与 create-pr-all.sh 行为](#经验：codeup-pr-创建-org-id-与-create-pr-allsh-行为)
- [经验：Codeup OpenAPI 不支持 MR 自动合并](#经验：codeup-openapi-不支持-mr-自动合并)
- [经验：kd-review worktree isolation 修复后的 merge-back 流程](#经验：kd-review-worktree-isolation-修复后的-merge-back-流程)
- [经验：Spring Boot/JdbcTemplate 升级导致测试 `ambiguous query` 批量修复](#经验：spring-bootjdbctemplate-升级导致测试-ambiguous-query-批量修复)
- [经验：Linter 持续还原前端文件修改](#经验：linter-持续还原前端文件修改)
- [经验：Mermaid 图在飞书文档渲染报错 — DELETE 保留关键字与圆柱体括号冲突](#经验：mermaid-图在飞书文档渲染报错-delete-保留关键字与圆柱体括号冲突)
- [经验：KdSkeleton 批量添加导致模板标签结构损坏](#经验：kdskeleton-批量添加导致模板标签结构损坏)
- [经验：Java `Map.of()` 10 条目上限 — `ACTION_LABELS` 超限编译错误](#经验：java-mapof-10-条目上限-action_labels-超限编译错误)
- [经验：Flyway stale target/ 残留 + 后端合并后启动失败](#经验：flyway-stale-target-残留-后端合并后启动失败)
- [经验：Git 子模块 detached HEAD + pull-all 后处理](#经验：git-子模块-detached-head-pull-all-后处理)
- [经验：401 自动跳转重入锁必须为模块级变量](#经验：401-自动跳转重入锁必须为模块级变量)
- [经验：merge-mr.sh 段错误时直接用 curl 调用 Codeup API](#经验：merge-mrsh-段错误时直接用-curl-调用-codeup-api)
- [经验：代码引用数据库中不存在的列，未创建对应 migration](#经验：代码引用数据库中不存在的列，未创建对应-migration)
- [经验：401 自动跳转白名单改为接口级配置项](#经验：401-自动跳转白名单改为接口级配置项)
- [经验：运营后台侧栏菜单 parent_id 错乱导致子菜单消失](#经验：运营后台侧栏菜单-parent_id-错乱导致子菜单消失)
- [经验：mapOpsMenusToSidebar 缺少 visible 过滤导致隐藏菜单泄露](#经验：mapopsmenustosidebar-缺少-visible-过滤导致隐藏菜单泄露)
- [经验：联合套卡核销任意子单后整单不可退款](#经验：联合套卡核销任意子单后整单不可退款)
- [经验：吸底栏必须使用 KdBottomBar 的 design token 规范](#经验：吸底栏必须使用-kdbottombar-的-design-token-规范)
- [经验：uni-app 内联 SVG 禁用 rpx 属性](#经验：uni-app-内联-svg-禁用-rpx-属性)
- [经验：KdBottomBar 必须在 KdPageShell 外部](#经验：kdbottombar-必须在-kdpageshell-外部)
- [经验：operation-backend 中文编码损坏 — UTF-8 误存为 Latin-1](#经验：operation-backend-中文编码损坏-utf-8-误存为-latin-1)
- [经验：C端禁止展示「发起方」「参与方」角色标签](#经验：c端禁止展示「发起方」「参与方」角色标签)
- [经验：MySQL tinyint(1) JDBC 映射为 Boolean 导致 ClassCastException](#经验：mysql-tinyint1-jdbc-映射为-boolean-导致-classcastexception)
- [经验：审计事件 module 名不一致导致查询不到记录](#经验：审计事件-module-名不一致导致查询不到记录)
- [经验：CSS 未闭合块导致 uni-app H5 PostCSS 编译失败](#经验：css-未闭合块导致-uni-app-h5-postcss-编译失败)
- [经验：Maven `.mvn/maven.config` BOM 字符导致 Unrecognized entry](#经验：maven-mvnmavenconfig-bom-字符导致-unrecognized-entry)
- [经验：E2E audit-chinese-display 缺失 action label](#经验：e2e-audit-chinese-display-缺失-action-label)
- [经验：Figma MCP 双工具协作 — figma-mcp-go + 官方 MCP](#经验：figma-mcp-双工具协作-figma-mcp-go-官方-mcp)
- [经验：Figma 官方 MCP Starter 计划配额限制及替代方案](#经验：figma-官方-mcp-starter-计划配额限制及替代方案)
- [经验：高保真原型多角色分佣提现设计模式](#经验：高保真原型多角色分佣提现设计模式)
- [经验：kd-review 收敛策略 — 🔵 建议也要修复 + 连续清理轮](#经验：kd-review-收敛策略-建议也要修复-连续清理轮)
- [经验：JdbcTemplate 被项目规范禁止，须替换为 MyBatis-Plus Repository](#经验：jdbctemplate-被项目规范禁止，须替换为-mybatis-plus-repository)
- [经验：动态 SQL 构建 — COUNT 与 LIST 查询的 JOIN 策略](#经验：动态-sql-构建-count-与-list-查询的-join-策略)
- [经验：API URL 契约不一致导致 404 — refundReject colon vs slash](#经验：api-url-契约不一致导致-404-refundreject-colon-vs-slash)
- [经验：@RequestBody 不安全转型必须添加类型检查](#经验：requestbody-不安全转型必须添加类型检查)
- [经验：审计日志 metadata_json 必须使用 JSON 转义](#经验：审计日志-metadata_json-必须使用-json-转义)
- [经验：CSV 导出必须防止公式注入](#经验：csv-导出必须防止公式注入)
- [经验：URL query 同步禁止 spread route.query](#经验：url-query-同步禁止-spread-routequery)
- [经验：Tab 表格内状态值必须使用中文映射](#经验：tab-表格内状态值必须使用中文映射)
- [经验：批量写操作必须记录审计日志](#经验：批量写操作必须记录审计日志)
- [经验：@RequirePerm 必须放在方法级别而非类级别](#经验：requireperm-必须放在方法级别而非类级别)
- [经验：FeatureGate 新逻辑上线时必须废弃旧入口](#经验：featuregate-新逻辑上线时必须废弃旧入口)
- [经验：前端字段名必须与后端实体一致](#经验：前端字段名必须与后端实体一致)
- [经验：kd-review 应包含 🔵（建议级别）修复](#经验：kd-review-应包含-（建议级别）修复)
- [经验：Figma MCP 读取设计稿用于前端实现](#经验：figma-mcp-读取设计稿用于前端实现)


## 经验：高保真原型 mobile-frame 结构规范

### 场景
开发康豆 v2 高保真 HTML 原型时，C端/商家端 375px 手机框内的 sticky-bottom 按钮和 bottom-nav tabbar 出现错位、宽度不足、与手机框不对齐等问题。多次修复才找到根因。

### 根因
`sticky-bottom` 和 `bottom-nav` 放在 `scroll-content` 内部时，`overflow-y:auto` 会隐式将 `overflow-x` 设为 `auto`，裁剪了子元素的负 margin，导致宽度不足和对齐错位。

### 解决方案
`sticky-bottom` 和 `bottom-nav` 必须作为 `mobile-frame` 的直接子元素，与 `scroll-content` 平级，不能嵌套在 `scroll-content` 内部。

```html
<div class="mobile-frame">
  <div class="status-bar">...</div>
  <div class="scroll-content" style="flex:1;overflow-y:auto;">...</div>
  <div class="sticky-bottom" style="width:375px;min-width:375px;box-sizing:border-box;">...</div>
  <div class="bottom-nav" style="width:375px;">...</div>
</div>
```

### 预防
1. `sticky-bottom` 永远是 `mobile-frame` 的子元素，不是 `scroll-content` 的子元素
2. `sticky-bottom` 显式设置 `width:375px;min-width:375px;box-sizing:border-box`
3. `bottom-nav` 显式设置 `width:375px`
4. `div` 闭合时要检查是否多了一个 `</div>` 导致结构断裂

---

## 经验：运营后台原型必须使用 Element Plus 蓝色主题

### 场景
高保真原型中运营后台使用了绿色 `#00B341` 品牌色和 `#304156` 深色侧边栏，与实际已实现的 Element Plus 风格严重不符。

### 根因
C端使用绿色品牌色，运营后台错误地沿用了同样的配色方案。实际运营后台使用 Element Plus 默认蓝色 `#409EFF` 主题 + 白色侧边栏。

### 解决方案
运营后台配色必须使用：
- 主题色：`#409EFF`（蓝色，Element Plus 默认）
- 侧边栏：白色 `#ffffff`，`border-right: 1px solid #e5e7eb`
- 背景：`#f5f6f8`
- 菜单激活态：蓝色 `#409EFF` 文字 + `#ecf5ff` 背景
- 表格：表头 `#fafafa`，行 `border-bottom: 1px solid #ebeef5`
- 按钮 Primary：`background: #409eff`

### 预防
1. 运营后台禁用绿色品牌色，使用蓝色 Element Plus 风格
2. 侧边栏必须是白色，不能是 `#304156` 深色
3. HTML 标记 `data-type="运营后台"` 的区块颜色必须与 C端区分

---

## 经验：数据共享原型概念纠正——商家端不涉及

### 场景
data-sharing.html 最初设计为商家端可以"新建共享"和查看共享数据，但用户指出商家在租户之下，商家端不对数据共享进行任何操作和查看。

### 根因
混淆了租户和商家的层级关系。实际层级为：`平台 → 租户（平台级租户 + 普通租户）→ 商家`。数据共享是运营后台在租户层面的配置能力。

### 解决方案
1. 商家端完全删除数据共享相关页面和功能
2. 平台级租户是现有租户编辑页的一个属性开关，不是独立分类
3. 数据共享采用引用式共享（非数据复制），避免同步问题
4. C端完全透明——不显示来源标记
5. 用户数据不可共享

### 预防
1. 任何数据共享功能只出现在运营后台，不出现在商家端
2. 平台级租户是普通租户的属性，不需要升级流程和审批
3. 共享是双向的（平台级↔普通），但商家端不涉及

---

## 经验：积分豆体系原型边界——无签到无积分商城

### 场景
points-system.html 最初包含了签到领积分和积分商城页面。用户指出这些在 PRD 中明确列为 Out（本期不做）。

### 根因
没有仔细阅读 PRD 的 §3.2 Out 部分。PRD 明确写了：
- "豆的活动/签到领豆（本期仅返佣和消费返豆，签到等非交易场景留后续）"
- "积分商城（本期不做纯豆兑换）"

### 解决方案
删除签到和积分商城相关内容，改为：
- C端：豆余额展示、豆流水明细、订单确认页混合支付（优惠券+豆抵扣+费用明细+提交）
- 运营后台：积分配置（租户级预设规则表，含消费返豆/返佣转豆/运营赠豆/豆抵扣限制/豆有效期）

### 预防
1. 积分豆的获取途径仅限于交易场景：消费返豆、返佣转豆、运营赠豆
2. 豆当现金使用（混合支付），不设纯豆兑换商品
3. 积分规则是租户级配置，商家端不涉及积分管理

---

## 经验：kd-review 全自动审查循环实践

### 场景
执行 whitelist/announcement/grayscale 功能模块开发后，通过 `/kd-review` 触发全自动审查循环。9 个窄范围审查 agent 并行启动，Streaming 修复模式让修复与审查重叠执行。

### 根因
传统人工 code review 只能覆盖少量文件且无法在单个会话内迭代收敛。kd-review 解决了"改了不敢合"的问题。

### 关键发现
1. **WhitelistLoginFilter 路径不匹配** — Filter 拦截的路径（`/api/tenant/auth/`）与实际 Controller 路径（`/api/tenant-core/auth/`）不一致，导致过滤器完全无效。必须通过 grep 或 Read 验证实际 Controller 的 `@RequestMapping`。
2. **snake_case/camelCase 不匹配** — 后端 `JdbcTemplate.queryForList()` 返回的 Map key 是原始 SQL 列名（snake_case），前端 TS 类型用 camelCase 声明时，运行时永远为 `undefined`。View 中使用 `Record<string, unknown>` 转型会绕过 TS 编译检查。
3. **`queryForMap` 空结果返回 500** — `JdbcTemplate.queryForMap()` 查不到数据时抛出 `EmptyResultDataAccessException`，不返回 null。必须 catch 处理或改用 `queryForList().isEmpty()`。
4. **ConcurrentHashMap 缓存穿透** — 不存在的 key 不会被缓存，每次穿透到 DB。使用 `computeIfAbsent()` 并缓存空集合防止穿透。
5. **Phone 日志 PII** — 日志直接输出 `phone={}` 违反个保法。必须用 `maskPhone()` 脱敏。

### 预防措施
1. `WhitelistLoginFilter` 类 Filter 的 `matches()` 路径必须与 Controller `@RequestMapping` + `@*Mapping` 拼接结果完全一致，用 Read 验证后再提交。
2. 后端用 `JdbcTemplate.queryForList()` 时，前端 API 类型声明必须用 snake_case（如 `created_at`），或添加运行时驼峰映射层。
3. 所有 `queryForMap` 调用必须 catch `EmptyResultDataAccessException`，推荐改用 `queryForList` 判空。
4. 本地缓存用 `ConcurrentHashMap` 时必须用 `computeIfAbsent()` 原子操作，并缓存空集合防止穿透。
5. 日志中出现手机号/邮箱等 PII 时，必须添加脱敏方法处理。

---

## 经验：FeatureGate 三层特征系统架构

### 场景
开发灰度分组功能时，初始设计采用简单的 phone-based grayscale 检查（`@FeatureGate` → `GrayscaleGroupService`）。后续自动升级为 `FeatureManager` + `FeatureRegistry` 三层特征管理系统。

### 架构
1. **feature_registry 表** — 功能注册中心（状态：DEVELOPMENT/GRAYSCALE/RELEASED/DISABLED）
2. **tenant_feature_switch 表** — 租户级开关，允许/禁用特定功能
3. **feature_group + feature_group_member 表** — 灰度分组，支持按用户/手机号分批

### 根因
简单 phone-based 灰度无法支持租户级开关和发布流程控制。三层架构解耦了"功能定义"、"租户配置"、"灰度范围"三个维度。

### 预防
新功能灰度需求应直接使用 `@FeatureGate` 注解 + `FeatureManager` API，无需自行实现 phone 查询逻辑。

---

## 经验：Operation-Backend Vite Build 中的 async/await 错误

### 场景
在 Vue SFC 中，`handleCreate()` 函数内使用了 `await`，但函数声明缺少 `async` 关键字，导致 Vite 构建失败：
```
[vite:vue] [vue/compiler-sfc] Unexpected reserved word 'await'. (100:6)
```

### 解决方案
添加 `async` 关键字：`async function handleCreate() { ... }`

### 预防
在 Vue 组件中使用 `await` 时，检查外层函数是否已声明为 `async`。

---

## 经验：公告弹窗分级分端设计

### 场景
用户要求在 whitelist-announce.html 中实现公告弹窗功能，且弹窗需要按等级区分样式，按端区分展示范围。

### 解决方案
1. **等级**：普通（绿色按钮）、重要（蓝色双按钮）、紧急（红色双按钮）
2. **端**：C端（绿色横幅）、商家端（蓝色横幅）、平台级（全部展示）
3. **弹窗频率**：每天一次（用户每天首次打开任意页面自动弹出）
4. **横幅**：在 status-bar 上方，mobile-frame 顶部始终展示

### 预防
1. 公告横幅在 mobile-frame 内、status-bar 之前，确保始终可见
2. 弹窗使用 position:fixed，需要确保 .hidden 的 display:none 正常工作
3. 弹窗演示使用 setTimeout 模拟"每天一次"的自动弹出

---

## 经验：灰度管理设计规范

### 场景
用户要求实现灰度管理功能，最初使用弹窗方式实现新建/编辑，但用户要求改为独立页面（同一 HTML 内的 prototype-section）。

### 解决方案
1. 灰度管理使用独立的 prototype-section 页面，不是弹窗
2. 编辑灰度分组时直接集成人员名单管理（双栏布局）
3. 灰度功能 = 租户已开通的功能模块，不需要单独注册
4. 人员名单支持复制粘贴（从一个分组复制手机号，粘贴到新分组）
5. 使用 showS() 进行页面间导航，不产生新标签页

### 预防
1. 灰度管理的创建/编辑都应该是独立页面（prototype-section），不是弹窗
2. 人员管理整合在编辑页内，不拆分为独立页面
3. 列表页→编辑页→返回列表 使用 showS() 导航

---

## 经验：经营闭环描述禁止出现在原型中

### 场景
商家端企业中心首页包含了"经营闭环"描述（发布商品→投放→发货→结算），用户明确要求删除并记住此类描述不应出现。

---

## 经验：架构优化与可观测性实施模式

### 场景
执行架构优化与可观测性方案，涉及 Actuator 增强、Micrometer 业务指标、Prometheus+Grafana、定时任务监控 AOP、飞书告警等。

### 解决方案
1. AOP + Micrometer — `JobMonitorAspect.java`：`@Around("@annotation(org.springframework.scheduling.annotation.Scheduled)")` 自动捕获所有定时任务
2. 业务指标 — `MicrometerMetricsConfig.java`：注册 `Counter` / `Timer` Bean，自动暴露到 `/actuator/prometheus`
3. 飞书告警 — `FeishuAlertService.java`：使用 `java.net.http.HttpClient` 发送 Webhook，配置项 `kangdou.alert.feishu-webhook`
4. 监控栈 — `infrastructure/docker-compose.yml`：Prometheus + Grafana 容器编排，抓取 `host.docker.internal:8080`

### 预防
1. 所有 `@Scheduled` 定时任务自动被 JobMonitorAspect 监控，无需额外配置
2. Micrometer 指标 Bean 在 `@Configuration` 类中注册，随应用启动生效
3. 飞书 Webhook URL 为空时不发送告警，仅日志警告，不阻塞主流程
4. Actuator 端口和 Prometheus 抓取路径在 `application.yml` 中统一管理

### 根因
"经营闭环"是内部运营概念，不适合在原型/面向客户的内容中展示。

### 解决方案
立即删除原型中所有"经营闭环"相关内容，并在代码中添加注释标记已删除位置。

### 预防
所有原型中禁止出现"经营闭环"、"闭环"等面向内部运营的概念描述。

以下情况提示现有规则可能需要更新：

1. **会话中反复出现同类型问题**（如 Flyway 版本冲突、Mockito 排序错乱）
2. **修复方式与现有规则建议不一致**（说明规则过时了）
3. **新增技术栈或库**（如新引入的 Maven 插件、测试工具）
4. **用户主动纠正你的做法**（说明规则没有正确约束你的行为）
5. **代码审查中发现的高频问题模式**（5 次以上同类问题应考虑加到规则中）

## 分析流程

1. **定位规则文件**：按 `write-ex.md` 的归类映射表确定目标文件
2. **确认问题是规则缺失还是执行不力**：
   - 规则缺失 → 新增章节
   - 执行不力 → 在该规则文件中增加 hard constraint 标记
3. **检查已有规则是否矛盾**：新经验和现有规则冲突时，标记冲突并询问用户
4. **最小更新**：只追加必要内容，不重写整个文件

## 规则添加标准

| 条件 | 行动 |
|------|------|
| 用户在 ≥3 次不同会话中纠正同一件事 | 新增硬约束（MUST） |
| 代码审查连续 5+ 次发现同类问题 | 新增检查清单项 |
| 新引入的依赖/工具/模式 | 新增参考说明 |
| 单向破坏性操作（如删除表、改 schema） | 新增确认流程 |

## 规则过时判定

- 路径引用返回 404 → 更新路径
- 依赖的库/框架已升级 → 更新命令版本
- 用户明确说"不用再这样做" → 删除该规则
- 规则与当前 CLAUDE.md 或 `AGENTS.md` 矛盾 → 标记冲突

## 规则质量检查

- 必须包含 Java/Vue 的**具体命令或代码示例**
- 路径引用必须是 `.agents/` 下的实际路径
- 避免泛泛而谈（如"注意安全"），要具体（如"使用 `@RequirePerm` 注解"）

---

## 经验：Codeup PR 创建 — ORG ID 与 create-pr-all.sh 行为

### 场景
`scripts/codeup/create-pr-all.sh` 创建 MR 时报错：
```
Error: failed to resolve repository id for xxx: Forbidden.InvalidUser.UserNotInCurrentOrganization
```
或因 ORG ID 不匹配导致只有部分子模块创建 MR。

### 根因
1. `.env.example` 中的 `CODEUP_ORGANIZATION_ID=60d54f3daccf2bbd6659f3ad` 是示例值，实际组织 ID 须通过 API 查询
2. `create-pr-all.sh` 的 `collect_changed_submodules` **仅检测有本地未提交变更的仓库**——已推送但干净的仓库不会创建 MR
3. `create-mr.sh` 从当前目录的 `git remote get-url origin` 自动检测仓库，需在子模块目录执行

### 解决方案
```bash
# 1. 查询真实组织 ID
curl -sS -H "x-yunxiao-token: $YUNXIAO_TOKEN" \
  "https://openapi-rdc.aliyuncs.com/oapi/v1/platform/organizations"

# 2. 对于已推送但无本地脏状态的仓库，手动创建 MR
cd frontend && \
CODEUP_ORGANIZATION_ID=正确ID \
bash scripts/codeup/create-mr.sh \
  --allow-fallback --mode center \
  --source feature/xxx --target dev \
  --title "[frontend] feat: xxx"

# 3. 或直接在 create-pr-all.sh 中依赖自动检测，运行前确认 org ID 正确
```

### 预防
1. 首次使用前运行 `curl` 确认 `CODEUP_ORGANIZATION_ID` 并写入 `.env`
2. 对于已推送的仓库，用 `create-mr.sh` 单独创建 MR
3. 记住：`create-pr-all.sh` 的 `--auto-commit` 会自动提交脏状态并推送

---

## 经验：Codeup OpenAPI 不支持 MR 自动合并

### 场景
尝试通过 Codeup OpenAPI 自动合并 MR 时，无论旧版 `/oapi/v1/codeup/` 还是新版 `/api/v4/projects/` 的 merge 端点均不可用：
- 旧版：`POST/PUT .../merge_requests/{id}/merge` → 404
- 新版：`POST .../projects/{id}/merge_requests/{id}/merge` → 307 重定向到登录页

### 根因
Codeup OpenAPI（`openapi-rdc.aliyuncs.com`）当前只支持 MR 的 CRUD 创建/查询操作（`create-pr-all.sh` / `create-mr.sh` 已封装），**不支持 merge/accept 操作**。

### 解决方案
确认无冲突后，引导用户在各 MR 页面手动点击「合并」按钮。已推送的 MR URL 格式：
```
https://codeup.aliyun.com/{orgId}/{namespace}/{repo}/reviews/{localId}
```

### 预防
1. `/pr-all` 完成后直接输出 MR 链接，不尝试自动合并
2. **绝不直接 push 到 dev 分支**——只能通过 MR 合入 dev。如果有人已手动解决冲突，在对应 MR 页面点击合并即可。

---

## 经验：kd-review worktree isolation 修复后的 merge-back 流程

### 场景
kd-review R1 修复 agent 使用 `isolation: worktree` 独立工作。修复完成后需要将改动合并回主分支。执行 `git merge worktree-agent-xxx` 时提示 "Already up to date"。

### 根因
`isolation: worktree` 创建的 agent 直接在 backend 子模块的 worktree 中修改文件并提交。这些提交在 worktree branch 上，但后端子模块的 git 指针可能已经指向了相同的 commit（因为 worktree 和主仓库共享同一个 submodule 的 gitdir）。

经实测，在当前版本中，worktree agent 的修改**直接出现在主仓库的工作树中**，无需额外的 merge 步骤。`git merge` 的 "Already up to date" 说明两者已经指向同一个 HEAD。

### 解决方案
1. 修复 agent 完成后：直接在主仓工作树中验证改动是否存在（grep 关键改动）
2. 若改动存在 → 直接 `mvn -q compile` 验证编译，无需 merge
3. 若改动不存在 → 在对应子模块中执行 `git merge <worktree-branch>`

### 预防
1. worktree agent 完成后不要盲目 merge，先 grep 验证改动是否已在工作树
2. 编译验证是决定性的——编译通过且关键改动存在，说明修复已生效
3. 工作树 agent 残留的 worktree branch 在完成后可安全忽略（后续 `git gc` 会自动清理）

---

## 经验：Spring Boot/JdbcTemplate 升级导致测试 `ambiguous query` 批量修复

### 场景
合并分支后 `mvn test-compile` 报 10+ 个测试文件的 `reference to query is ambiguous` 错误。错误信息为：
```
both method query(String, RowCallbackHandler, Object...) and
method <T>query(String, RowMapper<T>, Object...) match
```

### 根因
Spring Boot 3.x 升级引入了 JdbcTemplate 新重载（`query(sql, RowCallbackHandler, args)` vs `query(sql, RowMapper, args)`），Mockito 的 `any()` 匹配器对两个函数式接口无法区分。无类型约束的 `any()` 导致编译器无法抉择重载。

### 解决方案

**批量查找受影响文件：**
```bash
/usr/bin/grep -rl 'jdbcTemplate.query' src/test/ | xargs /usr/bin/grep -l 'any()'
```

**批量修复（分模式）：**

```bash
# 模式 1: query(anyString(), any(), eq( → 加 ResultSetExtractor.class
for f in $(/usr/bin/grep -rl "jdbcTemplate.query(anyString(), any(), eq(" src/test/); do
  sed -i '' 's/jdbcTemplate\.query(anyString(), any(), eq(/jdbcTemplate.query(anyString(), any(org.springframework.jdbc.core.ResultSetExtractor.class), eq(/g' "$f"
done

# 模式 2: query(anyString(), any(RowMapper.class), any()) → 加 Object.class
for f in $(/usr/bin/grep -rl "query(anyString(), any(RowMapper.class), any())" src/test/); do
  sed -i '' 's/query(anyString(), any(RowMapper\.class), any())/query(anyString(), any(RowMapper.class), any(Object.class))/g' "$f"
done

# 模式 3: queryForList(anyString(), any()) → 加 Object.class
# 模式 4: update(anyString(), any()) → any(Object.class)
```

**linter 优先级**：项目的 linter 会自动将 `any()` → `any(ResultSetExtractor.class)`。建议先让 linter 处理一轮，再手动修复 linter 未覆盖的模式。

### 预防
1. 升级 Spring Boot 版本前检查 JdbcTemplate API 变更
2. 测试中尽量使用 `any(RowMapper.class)` 或 `ArgumentMatchers.<RowMapper<X>>any()` 代替裸 `any()`
3. 合并分支后第一时间 `mvn test-compile` 验证

---

## 经验：Linter 持续还原前端文件修改

### 场景
修改 `KdCustomTabbar.vue` 后用 `pnpm run build:mp-weixin` 编译，发现修改被还原。多次修改后再次编译又被还原。

### 根因
项目配置了 pre-commit / pre-push linter 钩子，运行 `uni build` 时触发了代码格式化/检查，自动还原了与项目规范不一致的改动。`node scripts/ensure-tokens.mjs` 虽然不直接改 Vue 文件，但构建链中可能有其他校验步骤。

### 解决方案
1. 用 `Write` 完整文件覆盖替代 `Edit` 局部替换（避免 linter 保留旧结构）
2. 改完后先查看文件确认 `grep "改动关键词" target.file | wc -l` 是否匹配预期
3. 编译后再次确认改动未被还原
4. 对关键文件（pages.json、tabbar 组件等）在同一个会话里一次性完成所有改动

### 预防
- 对易被还原的文件（Vue 组件、pages.json、路由配置）优先用 `Write` 整文件改写
- 改完后立即 `grep` 验证，不要假设写入成功
- 一次改动完成后不要在同一文件上反复 Edit

---

## 经验：Mermaid 图在飞书文档渲染报错 — DELETE 保留关键字与圆柱体括号冲突

### 场景
PRD 文档中的 Mermaid flowchart 图上传飞书后报渲染错误（同文档其他图正常）。问题图为 "平台共享关闭流程"，包含节点 ID `DELETE` 和圆柱体节点 `DB_INSERT[(INSERT enabled=0, disabled_at=NOW)]`。

### 根因
1. **`DELETE` 是 Mermaid 保留关键字**：Mermaid flowchart 语法中 `DELETE` 被保留（用于删除边等操作），用作节点 ID 导致解析错误
2. **`[(...)]` 圆柱体内嵌括号冲突**：圆柱体语法 `[(text)]` 内不能再嵌套括号，`[(INSERT enabled=0, disabled_at=NOW)]` 中包含逗号分隔的括号内参数，解析器混淆
3. **飞书 Mermaid 渲染器更严格**：飞书内嵌的 Mermaid 渲染器比标准 Mermaid 更严格，本地 IDE 预览可能正常但飞书报错

### 解决方案
```mermaid
flowchart TD
    # 1. DELETE → DEL_RULE（避免保留关键字）
    # 2. 圆柱体 [(...)] → 斜方形 [/.../]（避免内嵌括号）
    # 3. 节点文本中不用冒号+引号的复杂格式
    
    CLICK_ENABLE --> CONFIRM2[弹窗确认操作]
    CONFIRM2 --> DEL_RULE[DELETE 接口删除关闭行]
    DEL_RULE --> DB_DEL[/DB: 删除关闭行\n恢复默认开启/]
    DB_DEL --> RESULT2[共享已重开]
```

### 预防
- Mermaid 节点 ID 禁止使用 SQL/编程语言保留字：`DELETE`、`INSERT`、`UPDATE`、`SELECT`、`DROP`、`ALTER`、`END`、`SUBGRAPH`
- 圆柱体 `[(text)]` 内不放括号、逗号分隔的参数列表；用斜方形 `/text/` 或矩形 `[text]` 替代
- 飞书上传前用 `\n` 换行拆分长文本，避免单节点文本含特殊字符
- 遵循 `docs/dev/飞书文档上传MUST规范.md` §三 Mermaid 图渲染原则

---

## 经验：KdSkeleton 批量添加导致模板标签结构损坏

### 场景
批量给 uni-app 页面添加 KdSkeleton 骨架屏时，多个 agent 独立工作后出现模板结构错误，构建时 `build:mp-weixin:prod` 报错：
```
[vite:vue] src/pages/circle/members.vue (1:1): Element is missing end tag.
[vite:vue] src/pages/goods/detail.vue (4:7): Element is missing end tag.
```

### 根因
1. **KdSkeleton 开闭标签嵌套层级错误**：KdSkeleton 标签必须在其父容器 `</view>` 之前关闭。常见错误是将 `</KdSkeleton>` 放在父容器 `</view>` 之后
2. **缺少 `</template>` 结尾**：替换 `</view>` 为 `</KdSkeleton>` 时连带删除了 `</template>`
3. **残留 `</view>` 悬空标签**：KdSkeleton 添加后旧的容器 `</view>` 未被移除，悬空在 `</KdPageShell>` 之外

### 解决方案
```bash
# 1. 构建验证——快速暴露所有模板错误
pnpm run build:mp-weixin:prod

# 2. 批量排查模式——查找 </KdPageShell> 后的悬空 </view>
for f in $(grep -rl 'KdPageShell' src/pages/ --include='*.vue' | xargs grep -l 'KdSkeleton'); do
  after=$(grep -A3 '</KdPageShell>' "$f" | tail -3)
  if echo "$after" | grep -q '</view>' && ! echo "$after" | grep -q '</template>'; then
    echo "STRAY </view>: $f"
  fi
done

# 3. 修复（python 批量替换）
python3 -c "
import re, glob
files = [...]
for f in files:
    with open(f) as fh:
        content = fh.read()
    content = re.sub(r'(  </KdPageShell>\n)\s*</view>\n\n(<script setup)', r'\1</template>\n\n\2', content)
    with open(f, 'w') as fh:
        fh.write(content)
"

# 4. 修复 KdSkeleton 在父 view 之后关闭的问题
# 确保结构为：...content...</KdSkeleton></view> 而非 ...content...</view></KdSkeleton>
```

### 预防
1. KdSkeleton 的 `</KdSkeleton>` **必须**在父容器 `</view>` 之前关闭，正确顺序：`... </KdSkeleton> </view> </KdPageShell>`
2. 替换旧的 loading spinner 时保留 `</template>` 标签——它是独立的，不与任何 container 的 `</view>` 共享
3. agent 批量修改后必须运行 `build:mp-weixin:prod` 全量编译验证，不要依赖单个文件的 grep 检查
4. 模板编辑遵循 "先闭内部，再闭外部" 原则：`</KdSkeleton>` → `</view>` → `</KdPageShell>` → `</template>`

---

## 经验：Java `Map.of()` 10 条目上限 — `ACTION_LABELS` 超限编译错误

### 场景
操作审计日志中 `JOINT_CARD_GOVERNANCE` 模块和 `CONFIRM_ALL` 等行为仍显示英文 code。添加中文映射后发现编译失败，原因是 `ACTION_LABELS` 已有 10 个 entry 再加第 11 个时 `Map.of()` 拒绝编译。

### 根因
`Map.of(K1,V1, K2,V2, ..., K10,V10)` 最多接受 10 个键值对参数（Java 11-21 均如此）。`ACTION_LABELS` 原本有 10 个模块映射（system.perm, system.role, system.user, system.menu, merchant.staff, merchant.demo, merchant.product, ops.operation, ops.jointCard, delivery-point），新增 `JOINT_CARD_GOVERNANCE` 后变成 11 个，但外层仍用 `Map.of(...)`。

同样，内部 map 若有超过 10 个 action 也需要用 `Map.ofEntries(...)` 而非 `Map.of(...)`。

### 解决方案
将外层 `Map.of(...)` 替换为 `Map.ofEntries(...)`，每个模块用 `Map.entry(key, value)` 包裹：

```java
// ❌ 编译失败：Map.of() 最多 10 个 entry
private static final Map<String, Map<String, String>> ACTION_LABELS = Map.of(
        "system.perm", Map.of(...),           // 1
        ...
        "delivery-point", Map.of(...),         // 10
        "JOINT_CARD_GOVERNANCE", Map.of(...)); // 11 → 编译错误

// ✅ 正确：Map.ofEntries() 无上限
private static final Map<String, Map<String, String>> ACTION_LABELS = Map.ofEntries(
        Map.entry("system.perm", Map.of(...)),
        ...
        Map.entry("JOINT_CARD_GOVERNANCE", Map.ofEntries(...)));
```

### 预防
1. 静态 `Map` 超过 5 个条目时直接使用 `Map.ofEntries()`，避免后续追加时再重构
2. 内部嵌套 map 同样注意 10 条目限制——`ops.jointCard` 和 `JOINT_CARD_GOVERNANCE` 都有 12 个 action，内部也要用 `Map.ofEntries()`
3. 添加新 entry 前检查目标 map 的条目数 + 工厂方法类型（`Map.of()` vs `Map.ofEntries()` vs `new HashMap<>()`）
4. 编译错误 `reason: no instance(s) of type variable(s) exist` 往往是 `Map.of()` 超限的信号

---

## 经验：Flyway stale target/ 残留 + 后端合并后启动失败

参阅 `.agents/rules/kangdou-flyway-new-migration.md` — 包含 target/ 残留导致 Flyway 重复迁移和合并后 MyBatis 类加载异常的解决方案。

---

## 经验：Git 子模块 detached HEAD + pull-all 后处理

参阅 `.agents/rules/kangdou-git-merge-pull.md` — 包含 `pull-all-dev.sh` 后子模块 detached HEAD 处理、`publish-to-dev.sh all` vs 逐个仓库模式区别。

---

## 经验：401 自动跳转重入锁必须为模块级变量

### 场景
多个并发 API 请求同时收到 401 响应，每个请求各自尝试 `redirectUnauthorized()`，导致死循环或多个跳转重叠。

### 根因
`loginRedirectPending` 变量被声明在 `defaultRequester()` 函数内部，每个并发调用有自己的函数作用域锁变量，无法互斥。实际上前一次 401 还未完成跳转，后一次 401 又开始新的跳转。

### 解决方案
将 `loginRedirectPending` 从 `defaultRequester()` 函数内部提升到模块级（文件顶层）：

```typescript
// ❌ 错误：函数内部，每个并发请求独立
async function defaultRequester<T>(...): Promise<T> {
  let loginRedirectPending = false; // 每个请求都有自己的锁
  // ...
}

// ✅ 正确：模块级，所有请求共享同一锁
let loginRedirectPending = false;

function redirectUnauthorized(): void {
  if (loginRedirectPending) return;
  loginRedirectPending = true;
  setTimeout(() => { loginRedirectPending = false; }, 5000);
  // ...
}
```

同时新增 `skipAuthRedirect?: boolean` 选项到 `HttpRequestOptions`，允许特定接口（如轮询、登录态检查）跳过 401 跳转逻辑。

### 预防
1. 模块级重入锁/状态变量必须放在函数外部，不可在函数作用域内声明
2. HTTP 拦截器中涉及页面跳转的逻辑必须考虑并发请求场景
3. 每个条件判断（如 `skipAuthRedirect`）必须在所有请求分支中一致实现（uni.request / wx.request / fetch）

---

## 经验：merge-mr.sh 段错误时直接用 curl 调用 Codeup API

### 场景
`scripts/codeup/merge-mr.sh --local-id 80 --merge-type rebase --allow-fallback` 在 macOS 上退出码 139（segfault），无法合并 MR。

### 根因
`merge-mr.sh` 通过 `source lib/resolve-python.sh` 创建 `python3()` shell 函数覆盖系统 python3。macOS 上该函数与 `set -euo pipefail` 结合时，可能在子 shell 调用中出现递归或兼容性问题导致 SIGSEGV（139）。

### 解决方案
跳过脚本，直接用 curl 调用 Codeup OpenAPI：

```bash
YUNXIAO_TOKEN="pt-xxxx"

# 合并 MR
curl -sS -X POST \
  "https://openapi-rdc.aliyuncs.com/oapi/v1/codeup/organizations/{orgId}/repositories/{repoId}/changeRequests/{localId}/merge" \
  -H "Content-Type: application/json" \
  -H "x-yunxiao-token: ${YUNXIAO_TOKEN}" \
  --data '{"mergeType":"rebase"}'

# 参数说明
# orgId: 组织 ID（如 69e0392d29ad98af40661eef）
# repoId: 仓库 ID（主仓 6638169, 前端 6638222, 后端 6638225）
# localId: MR 编号（如 80, 89）
# mergeType: 仅 rebase 可用（no-fast-forward / squash 不支持）
```

### 预防
1. `merge-mr.sh` 在 macOS 上不稳定，优先直接用 curl
2. 仓库 ID 和 ORG ID 存在 `scripts/codeup/.env` 的注释中
3. mergeType 只传 `rebase`，其他类型会报错

---

## 经验：代码引用数据库中不存在的列，未创建对应 migration

### 场景
生产日志报 `Unknown column 'dim0_value' in 'field list'`，发生在 `GET /api/tenant-core/merchant/shops/4/spus/8`。查询 `merch_product_sku` 表，但 `dim0_value`/`dim1_value` 列不存在。

### 根因
开发在 `MerchTenantStaffSpuService.listSkuMaps()` 中添加了对 `dim0_value`/`dim1_value` 的 SELECT 和 INSERT 引用，但 `merch_product_sku` 表从未通过 Flyway migration 添加过这两列（V75 创建的是 `shop_sku` 表，不同表）。

这是典型的"改代码忘改数据库"场景 — 代码已部署但列不存在。

### 解决方案
```sql
-- 条件式加列（已包装为 V3308）
ALTER TABLE merch_product_sku ADD COLUMN dim0_value VARCHAR(128) NULL COMMENT '规格维度0值' AFTER sku_code;
ALTER TABLE merch_product_sku ADD COLUMN dim1_value VARCHAR(128) NULL COMMENT '规格维度1值' AFTER dim0_value;
```

新建 migration 并注册到 flyway_schema_history：
```bash
# 计算 checksum
python3 -c "import binascii; crc = binascii.crc32(open('V3308__...sql','rb').read()) & 0xFFFFFFFF; print(crc if crc < 2**31 else crc - 2**32)"

# 注册到生产 history（新 migration 需要提前标记已执行）
INSERT INTO flyway_schema_history (installed_rank, version, description, type, script, checksum, installed_by, installed_on, execution_time, success)
VALUES ((SELECT MAX(installed_rank)+1 FROM flyway_schema_history h), '3308', 'merch product sku add dim columns', 'SQL', 'V3308__merch_product_sku_add_dim_columns.sql', -1254188919, 'dayuancheng', NOW(), 0, 1);
```

### 预防
- **改 SQL 查询字段 → 检查对应表有无该列 → 无则创建 migration**（不能只改代码）
- 新增列后立即创建对应 Flyway migration，和代码一起提交
- 部署前用 `grep` 扫描代码中查询的字段名，与 `DESCRIBE 表` 做交叉验证
- 条件式 DDL（IF column NOT EXISTS）是 safe pattern，推荐用于修复类 migration

---

## 经验：401 自动跳转白名单改为接口级配置项

### 场景
`api/tenant-core/im/conversations` 会话过期后返回 401，虽然该 URL 不在跳转白名单中，但仍触发了登录页跳转。

### 根因
`TRADE_AUTH_WHITELIST` 包含过宽的 `"/api/tenant-core/"` 前缀，导致所有 `tenant-core` 路径（IM、圈子、用户资料等）都会被匹配。本意是覆盖 trade 接口（orders/payments/refunds）但前缀匹配太粗糙。

### 解决方案
去掉全局 URL 前缀白名单，改为在具体 API 调用处通过 `redirectOnUnauthorized: true` 显式声明：

```typescript
// before: 全局前缀白名单（脆弱、隐含覆盖）
const TRADE_AUTH_WHITELIST = ["/api/trade/", "/api/tenant-core/", "/api/tenant/joint-card"];

// after: 明确在调用点声明
client.request("/api/trade/orders", { redirectOnUnauthorized: true });
client.request("/api/tenant-core/im/conversations"); // ← 没有 flag，不跳转
```

涉及 16 个 API 文件的修改，覆盖 orders/payments/refunds/coupons/joint-card/merchant-trade/settlement/asset/verify 各模块。

相关历史：[401 自动跳转重入锁](#经验401-自动跳转重入锁必须为模块级变量)

### 预防
1. 禁止使用全局 URL 前缀匹配控制 401 跳转行为
2. 新写交易接口 API 时在 `client.request()` 选项中显式设置 `redirectOnUnauthorized: true`
3. 非交易接口（IM、圈子、用户资料、商品浏览）即使返回 401 也不应触发登录跳转，调用方自行处理 `HttpApiError`
4. 代码审查时检查：`redirectUnauthorized()` 的条件只能来自选项参数，不能依赖 URL 字符串匹配

---

## 经验：运营后台侧栏菜单 parent_id 错乱导致子菜单消失

### 场景
搜索管理(id=1210)被提升为根菜单后，其子菜单（热搜词管理、敏感词管理、联想词管理、搜索看板）从侧栏消失。词典管理(id=1260)正常显示，其余子菜单不显示。

### 根因
搜索子菜单（id=122-125）的 `parent_id` 指向了 `121`（联合套卡治理），而非 `1210`（搜索管理）。这是历史 migration 中 ID 分配错误——菜单 122-125 本应属于搜索管理，但被错挂到联合套卡治理下。词典管理(id=1260)是后来新增的正确条目，所以正常。

V2 迁移将 搜索管理 从 运营管理 提升为根节点（`SET parent_id = NULL`），但只通过 `WHERE parent_id = 1210` 更新了子菜单的 `sort_order`，而 122-125 的 `parent_id=121` 不满足条件，未被修正。

### 解决方案
```sql
-- 修正搜索子菜单的 parent_id
UPDATE sys_menu SET parent_id = 1210, sort_order = 1 WHERE id = 122 AND code = 'menu_search_hot_words';
UPDATE sys_menu SET parent_id = 1210, sort_order = 2 WHERE id = 123 AND code = 'menu_search_sensitive_words';
UPDATE sys_menu SET parent_id = 1210, sort_order = 3 WHERE id = 124 AND code = 'menu_search_suggestions';
UPDATE sys_menu SET parent_id = 1210, sort_order = 4 WHERE id = 125 AND code = 'menu_search_dashboard';

-- 验证
SELECT id, parent_id, code, name, sort_order FROM sys_menu WHERE parent_id = 1210 ORDER BY sort_order;
```

### 预防
- 修改菜单层级（`parent_id`）时，必须同时检查并修正该节点下所有子菜单的 `parent_id`
- 使用递归查询或按 parent_id 分组验证来发现错挂节点
- 菜单 ID 段分配（1210 vs 121）一目了然，相差大的 ID 段应警惕 parent_id 是否匹配
- 修改前先 `SELECT * FROM sys_menu WHERE parent_id IN (target_id, wrong_id)` 确认所有受影响记录

---

## 经验：mapOpsMenusToSidebar 缺少 visible 过滤导致隐藏菜单泄露

### 场景
后端 API `/api/platform/menu/my` 返回所有 `status=1` 的菜单（包括 `visible=0` 的编辑/新建类菜单），但前端的 `mapOpsMenusToSidebar` 函数没有按 `visible` 字段过滤，导致应隐藏的菜单在侧栏中出现。

### 根因
`OpsMenuService.java` 中 `menuTreeForUser()` 的 SQL 只过滤 `WHERE status = 1`，未过滤 `visible`。这本身是合理的——`visible=0` 的菜单仍需用于权限绑定。但前端 `mapOpsMenusToSidebar` 在构建侧栏时，只检查 `HIDDEN_SIDEBAR_MENU_KEYS` 集合，没有检查 `node.visible` 字段，导致 `visible=0` 的菜单泄露到侧栏。

### 解决方案
```typescript
// mapOpsMenu.ts — 在遍历时跳过不可见菜单
for (const n of nodes ?? []) {
  if (!n.visible) {
    continue;  // ← 新增
  }
  // ...
}
```

同时将编辑类菜单的 code 和 routeName 加入 `HIDDEN_SIDEBAR_MENU_KEYS` 作为兜底：
```typescript
// menu.ts
export const HIDDEN_SIDEBAR_MENU_KEYS = new Set([
  // ...
  "merchantProductNew", "menu_merchant_product_new",
  "merchantProductEdit", "menu_merchant_product_edit",
  "merchantFreightTemplateNew", "menu_merchant_freight_template_new",
  "merchantFreightTemplateEdit", "menu_merchant_freight_template_edit",
  "jointCardCreate", "menu_ops_joint_cards_create",
  "jointCardDetail", "menu_ops_joint_cards_detail",
  "menu_merchant_product"
]);
```

### 预防
- `mapOpsMenusToSidebar` 必须始终将 `visible` 作为第一道过滤（这是 `sys_menu.visible` 列的设计意图）
- `HIDDEN_SIDEBAR_MENU_KEYS` 作为防御性兜底而非主要过滤手段
- 新增菜单若为编辑/新建/详情类（需带参数跳转），必须在 `sys_menu` 设 `visible=0`，同时在 `HIDDEN_SIDEBAR_MENU_KEYS` 注册
- 后端新增 migration 时要确认：只设 `status=1` 是不够的，`visible=0` 才真正从侧栏隐藏

---

## 经验：联合套卡核销任意子单后整单不可退款

### 场景
运营需求：联合套卡订单中，一旦有任意子项到店核销（REDEEMED/USED），整单无论其他子项是否核销，均不再支持退款。

### 根因
原退款校验只检查被退款的子项或子订单是否已核销，未做整单级扫描。一个子项已核销后，其他未核销子项仍可退款，不符合运营规则。

### 解决方案

**后端 — `JointCardRefundService.java`：**

在 `checkRefundRule()`（租户级配置检查）之后、子项级检查之前，新增 `checkParentAnyLineRedeemed()`：

```java
private void checkParentAnyLineRedeemed(String tenantId, String parentOrderNo) {
    Long count = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM joint_card_line_instance " +
            "WHERE tenant_id = ? AND child_order_no IN (" +
            "  SELECT order_no FROM trade_order WHERE tenant_id = ? AND parent_order_no = ?" +
            ") AND instance_status IN ('REDEEMED', 'USED') " +
            "AND child_order_no IS NOT NULL AND child_order_no != '' AND child_order_no != 'null'",
            Long.class, tenantId, tenantId, parentOrderNo);
    if (count != null && count > 0) {
        throw new AppException(ApiErrorCode.HTTP_CONFLICT, "该套卡已有子项核销，整单不可退款");
    }
}
```

在 `refundByLineInstance` 和 `refundFullChildOrder` 两个入口方法中均需调用此检查。

**前端 — `JointCardOrderDetail.vue`：**
- 新增 `hasRedeemedInstance` computed（基于 `usedCount > 0`）
- 已核销时显示红色横幅「已有子项核销，整单不可退款」
- "申请退款" 按钮替换为灰色「已核销，不可退款」标签

**前端 — `after-sale.vue`：**
- 遍历 `orderTree.lineInstances` 判断 `hasRedeemedInstance`
- 顶部显示红色横幅「该套卡已有子项核销，整单不可退款」
- 隐藏选择子项、退款预览、提交退款区域（退款进度仍显示）

### 预防
1. 联合套卡业务规则变更时，需同步修改后端校验 + 前端显示
2. 新规则影响两个退款入口：`refundByLineInstance`（按子项）和 `refundFullChildOrder`（按子单）
3. 前端涉及三个展示点：订单详情、售后页、退款弹窗
4. `JointCardLineInstance` 类型缺少字段需同步补齐（`shopId`、`paidAmountFen`）

---

## 经验：吸底栏必须使用 KdBottomBar 的 design token 规范

### 场景
`create-step3.vue` 的底部按钮栏虽然已 `position: fixed` 吸底，但缺少 `box-shadow` 毛玻璃投影，且 CSS 变量无 fallback 值，与 `KdBottomBar` 组件的外观不一致。

### 根因
手写底部栏时只使用了 `var(--kd-glass-bg-top)`、`var(--kd-glass-blur)`、`var(--kd-glass-border)` 三个 token，遗漏了：
- `box-shadow: var(--kd-glass-shadow)` — 毛玻璃投影
- CSS 变量的 fallback 值 — 组件独立运行时 token 可能未加载

### 解决方案
```css
/* ❌ 缺少 box-shadow 和 fallback */
.jm-step3__bottom {
  background: var(--kd-glass-bg-top);
  backdrop-filter: blur(var(--kd-glass-blur));
  border-top: 1rpx solid var(--kd-glass-border);
  padding: 20rpx 32rpx;
}

/* ✅ 对齐 KdBottomBar 标准 */
.jm-step3__bottom {
  background: var(--kd-glass-bg-top, rgba(255, 255, 255, 0.52));
  backdrop-filter: blur(var(--kd-glass-blur, 26px));
  border-top: 1rpx solid var(--kd-glass-border, rgba(255, 255, 255, 0.85));
  box-shadow: var(--kd-glass-shadow, 0 -4rpx 24rpx rgba(19, 59, 35, 0.04));
  padding: 24rpx 32rpx;
  padding-bottom: calc(24rpx + env(safe-area-inset-bottom, 0px));
}
```

### 预防
1. 手写吸底栏优先使用 `KdBottomBar` 组件，避免重复造轮子
2. 必须手写时，参考 `KdBottomBar.vue` 的 design token 完整集：`bg-top`、`blur`、`border`、`shadow`、padding + safe-area
3. 所有 CSS 变量必须带 fallback 值，确保组件在 token 未加载时仍可正常显示
4. 标准 bottom bar padding: `24rpx 32rpx`；底部安全区: `calc(24rpx + env(safe-area-inset-bottom, 0px))`

---

## 经验：uni-app 内联 SVG 禁用 rpx 属性

### 场景
套卡详情页收藏和分享 SVG 图标在 uni-app 中完全不可见。

### 根因
SVG 元素 `width`/`height` 属性使用了 `rpx` 单位（如 `width="36rpx"`），uni-app 的 SVG 渲染引擎不识别 `rpx` 单位，导致图标实际渲染尺寸为 0×0。同时 `currentColor` 在 uni-app SVG 上下文中可能不级联。

### 解决方案
```vue
<!-- ❌ 不可见 -->
<svg width="36rpx" height="36rpx" fill="currentColor">
  <path d="..." />
</svg>

<!-- ✅ 修复后 -->
<svg class="detail-icon-svg" viewBox="0 0 24 24">
  <path class="detail-icon-heart" d="..." />
</svg>
```
```css
/* SVG 尺寸必须通过 CSS 设置 */
.detail-icon-svg {
  width: 48rpx;
  height: 48rpx;
  display: block;
}
/* 路径颜色直接用 CSS 类控制，避免 currentColor */
.detail-icon-heart {
  fill: none;
  stroke: var(--kd-color-text-secondary, #999);
  stroke-width: 1.8;
}
```

### 预防
1. 禁止在 SVG 元素属性中使用 `rpx` 单位（仅支持 CSS 级 `rpx`）
2. SVG 尺寸统一用 CSS `width`/`height` + `display: block` 控制
3. 路径颜色用 CSS 类设置 fill/stroke，避免依赖 `currentColor` 级联

---

## 经验：KdBottomBar 必须在 KdPageShell 外部

### 场景
套卡详情页改用 `<KdBottomBar>` 组件时底部栏定位异常。

### 根因
`KdPageShell` 的容器元素设置了 `isolation: isolate` CSS 属性，会为内部元素创建新的层叠上下文（stacking context），破坏内部 `position: fixed` 元素的定位行为。

### 解决方案
```vue
<!-- ❌ 错误：放在 KdPageShell 内部 -->
<template>
  <KdPageShell>
    <view class="content">...</view>
    <KdBottomBar>...</KdBottomBar>  <!-- fixed 定位异常 -->
  </KdPageShell>
</template>

<!-- ✅ 正确：放在 KdPageShell 外部 -->
<template>
  <view class="page-wrap">
    <KdPageShell>
      <view class="content">...</view>
    </KdPageShell>
    <KdBottomBar>...</KdBottomBar>  <!-- fixed 正常 -->
  </view>
</template>
```

### 预防
1. 任何 `position: fixed` 的吸底栏（KdBottomBar 或手写）必须放在 KdPageShell 外部
2. 参照 confirm.vue 的结构：`<外层view> → <KdPageShell> + <KdBottomBar>`

---

## 经验：operation-backend 中文编码损坏 — UTF-8 误存为 Latin-1

### 场景
`operation-backend/src/router/menu.ts` 全部中文标题显示为乱码，如 `绉熸埛绠＄悊`（应为`租户管理`）、`鍟嗘埛涓績`（应为`商户中心`）。运营后台侧栏菜单标题全部显示乱码。

`mapOpsMenu.ts` 的 `mapOpsMenusToSidebar` 在父菜单所有子项均被隐藏时，错误地将父菜单一并过滤掉，导致「联合套卡治理」在侧栏中消失。

### 根因
1. **编码损坏**：文件以非 UTF-8 编码保存，中文字符的 UTF-8 字节被错误解释为 Latin-1 字符。这是编辑器或 git 合并工具写入了错误的编码。
2. **菜单过滤缺陷**：`mapOpsMenusToSidebar` 在 `n.children?.length && !children?.length` 时跳过整个节点。父节点如果自身有 `routeName`（可独立导航），即使所有子项被隐藏，也应保留。

### 解决方案

**修复编码**：用 Python 修复已知乱码字符串映射：
```python
fixes = {
    '绉熸埛绠＄悊': '租户管理',
}
for garbled, correct in fixes.items():
    content = content.replace(garbled, correct)
```

**修复菜单过滤**：
```typescript
// mapOpsMenu.ts
const children = n.children?.length ? mapOpsMenusToSidebar(n.children) : undefined;
if (routeName && routeName.length > 0) {
  // 父节点自身有 routeName，保留
} else if (n.children?.length && !children?.length) {
  continue;
}
```

### 预防
1. 所有 `.ts` / `.vue` 文件必须使用 **UTF-8 without BOM** 编码保存
2. 中文文本写入后立即用 `grep` 验证，出现 `锟`、`绉`、`鍟`、`埛` 等字符说明编码损坏
3. `mapOpsMenusToSidebar` 修改过滤逻辑时，需考虑父菜单自身有路由的场景
4. 编辑 `operation-backend/` 下的文件时特别注意编码设置，确认编辑器状态栏显示 "UTF-8"

---

## 经验：C端禁止展示「发起方」「参与方」角色标签

### 场景
用户反馈套卡详情和确认订单页的"发起方"/"参与方"标签难以理解，要求全部替换为商品名称。

### 根因
`DetailShopList.vue` 展示合作店铺时使用了 `shopRoleLabel()` 函数（返回"发起方"/"参与方"），该标签对 C 端消费者无意义，属于运营管理术语。

### 解决方案
```vue
<!-- ❌ 原设计：角色标签 -->
<view class="detail-shop-role">{{ shopRoleLabel(listing.shopRole) }}</view>

<!-- ✅ 新设计：展示该店铺的商品清单 -->
<view class="detail-shop-goods">{{ itemNamesByShop[listing.shopId] }}</view>
<view class="detail-shop-badge">{{ countByShop[listing.shopId] }} 件</view>
```
传入 `lines` 数据，按 `shopId` 聚合各店铺的商品名列表，替换角色标签。

### 预防
1. C 端展示优先使用商品名称、店铺名称等用户可理解的字段
2. 禁止在 C 端页面使用运营管理术语（发起方、参与方、角色、审核等）

---

## 经验：MySQL tinyint(1) JDBC 映射为 Boolean 导致 ClassCastException

### 场景
联合套卡订单创建时报 `java.lang.ClassCastException: class java.lang.Boolean cannot be cast to class java.lang.Number`。调用栈：`JointCardOrderService.createMainOrder()` 中 `((Number) card.get("per_user_limit")).intValue()`。

### 根因
MySQL JDBC Connector/J 默认将 `tinyint(1)` 列映射为 `java.lang.Boolean`，而非 `Integer`。当 `jdbcTemplate.queryForList()` 返回 `Map<String, Object>` 时，`tinyint(1)` 列的值是 `Boolean`，直接 `(Number)` 转型抛 `ClassCastException`。

同为 `tinyint(1)` 的还有 `cps_enabled`、各种 `tinyint(1)` 标记列。

### 解决方案
```java
// ❌ 错误：直接 Number cast
int perUserLimit = ((Number) card.get("per_user_limit")).intValue();

// ✅ 正确：instanceof 安全转换
Object limitRaw = card.get("per_user_limit");
int perUserLimit = limitRaw instanceof Number ? ((Number) limitRaw).intValue() : 0;

// 同样的模式适用于 Boolean
Object cpsObj = card.get("cps_enabled");
boolean cpsEnabled = cpsObj instanceof Number && ((Number) cpsObj).intValue() == 1;
```

### 预防
1. 凡是 `jdbcTemplate.queryForList()` 返回的 `Map<String, Object>`，对 `tinyint(1)` 列的取值必须用 `instanceof Number` 安全转换
2. `tinyint(1)` 列：`per_user_limit`、`cps_enabled`、各种 flag/boolean 标记
3. `int`/`bigint` 列（如 `total_quantity`、`sold_quantity`、`price_fen`）不受影响
4. 新表的 `tinyint(1)` 列在设计时考虑改为 `tinyint(4)` 或 `smallint` 避免此问题

---

## 经验：审计事件 module 名不一致导致查询不到记录

### 场景
运营端 E2E 测试 `AE-003` 套卡审计记录查询返回 0 条。创建套卡 → 确认后显然应有审计事件，但按 `JOINT_CARD_GOVERNANCE` 筛选查不到。

### 根因
`OpsAuditService.recordSuccess()` 写入的 `module` 值为 `"ops.jointCard"`，但 E2E 测试查询时用了 `module=JOINT_CARD_GOVERNANCE`。两个值不匹配，导致 SQL WHERE 过滤掉所有记录。

另：`display_outcome` 字段在 `enrichRow()` 中没有映射，返回空字符串。

### 解决方案
```java
// recordSuccess 写入时统一用 "ops.jointCard"
opsAuditService.recordSuccess("ops.jointCard", "CONFIRM_ALL", ...);

// 查询时须匹配同一 module 值
GET /api/platform/audit-events?module=ops.jointCard

// enrichRow 中补充 display_outcome 映射
row.put("display_outcome", "success".equals(outcome) ? "成功" : "失败");
```

### 预防
1. `recordSuccess()` 的 `module` 参数与查询的 `module` 参数必须一致
2. 新增审计事件时确认 module 值已注册到 `OpsAuditMetadata.java` 的 `MODULE_LABELS` 和 `ACTION_LABELS`
3. `enrichRow()` 新增 display 字段时同步更新前端模板

---

## 经验：CSS 未闭合块导致 uni-app H5 PostCSS 编译失败

### 场景
H5 前端开发服务器报 PostCSS 异常，页面无法加载：
```
[plugin:vite:css] [postcss] DetailShopList.vue:41:1: Unclosed block
```
错误指向 `.detail-shop-role { ... .detail-shop-goods {` 两个 CSS 块之间缺 `}`。

### 根因
Vue SFC 的 `<style>` 块中 CSS 规则块未闭合。`.detail-shop-role` 的最后一个声明后缺少 `}` 就开始了 `.detail-shop-goods`，PostCSS 解析时认为前一个块未终止。

### 解决方案
```css
/* ❌ 错误：缺闭合 } */
.detail-shop-role {
  font-size: var(--kd-font-2sm);
  padding: 4rpx 14rpx;
  border-radius: var(--kd-radius-sm);
.detail-shop-goods {

/* ✅ 正确 */
.detail-shop-role {
  font-size: var(--kd-font-2sm);
  padding: 4rpx 14rpx;
  border-radius: var(--kd-radius-sm);
}
.detail-shop-goods {
```

### 预防
1. 编辑 `.vue` 文件 `<style>` 块后检查所有 CSS 规则块的 `{` `}` 配对
2. 可运行 `pnpm run dev:h5` 验证 PostCSS 编译——Vite 即时报错
3. 编辑器开启 CSS 大括号匹配高亮 / linter
3. `shopRoleLabel()` 仅用于商家端页面

---

## 经验：Maven `.mvn/maven.config` BOM 字符导致 Unrecognized entry

### 场景
`mvn spring-boot:run` 报错：`Unrecognized maven.config file entries`
文件第一行看起来是注释 `# Windows 中文用户目录下...`

### 根因
`backend/.mvn/maven.config` 文件开头有 UTF-8 BOM（`U+FEFF`）字符，Maven 3.9.9 尝试把它当作配置选项解析，但 BOM + 注释行不是合法选项。

### 解决方案
```bash
# 将 maven.config 重写为仅包含有效选项
echo '-Dmaven.repo.local=../../m2-repo' > backend/.mvn/maven.config
```

### 预防
- 编辑 `maven.config` 时使用纯 ASCII 编码，避免编辑器写入 BOM
- 文件只包含 `-Dkey=value` 选项行，不加注释

---

## 经验：E2E audit-chinese-display 缺失 action label

### 场景
Playwright 测试 `audit-chinese-display.spec.ts` 报错：`行为筛选项 XXX 的 label"XXX" 应为中文`

### 根因
审计事件 DB（`audit_event` 表）中存在某 module + action 组合，但 `OpsAuditMetadata.ACTION_LABELS` 中缺少该 action 的中文 label 映射。

`getFilters()` 方法从 `audit_event` 表查询 `DISTINCT module, action`，然后通过 `OpsAuditMetadata.actionLabel(module, action)` 查 label。未映射的 action 返回原始英文值。

### 解决方案
在 `OpsAuditMetadata.java` 的 `ACTION_LABELS` 中，往对应 module 添加缺失的 action 映射：
```java
Map.entry("ADJUST_STOCK", "调整库存"),
```

### 预防
- 新增审计操作时同步更新 `OpsAuditMetadata.ACTION_LABELS`
- 运行 `pnpm test:e2e -- --max-failures=0` 可一次跑完所有 E2E 测试暴露全部缺失项
- 排查缺失项：从 API 获取 `/api/platform/audit-events/filters`，对照 `ACTION_LABELS` 逐一补齐

---

## 经验：Figma MCP 双工具协作 — figma-mcp-go + 官方 MCP

### 场景
需要使用 Figma 进行组件库/原型设计时，单个 MCP 工具无法满足需求：
- figma-mcp-go 不能导入 SVG 图标，CSS 渐变只能近似模拟
- 官方 MCP Code to Canvas 可以将 HTML 变成 Figma 可编辑图层但读工具有 6 次/月限制

### 根因
两个工具互补但各有局限，单一工具无法完美覆盖「组件生成 + Token 绑定 + 设计读取」全流程。

### 解决方案

**工具分工**：
- **官方 MCP → Code to Canvas**：生成带 SVG 图标、CSS 渐变、真实图片的 Figma 图层（不限次数）
- **figma-mcp-go**：绑定 kd-* 设计 Token、精细修改、截图导出（无限制）
- 两者操作同一 Figma 文件无冲突（Figma 支持多人协作）

**Code to Canvas 操作步骤**：
```bash
# 1. HTML 中注入 capture.js
<script src="https://mcp.figma.com/mcp/html-to-design/capture.js" async></script>

# 2. 启动本地 HTTP 服务（不能 file://）
python3 -m http.server 8899 --bind 127.0.0.1

# 3. Claude 生成 captureId → 打开浏览器 → 轮询完成
```

**Token 绑定步骤**：
```javascript
// 1. 创建变量集合
create_variable_collection("kd-color", "Green (默认)")

// 2. 创建变量
create_variable("kd-color", "color/primary", COLOR, "#00B341")

// 3. 绑定到节点
bind_variable_to_node("1:3", cornerRadius, "radius/lg")
bind_variable_to_node("1:24", fillColor, "color/primary")
```

### 已知限制
1. 渐变填充无法绑定 COLOR 变量 — 需先用 `set_fills` 改为纯色
2. 官方 MCP 免费版每月 6 次读调用（get_screenshot 等），写工具不限
3. Figma 变量按文件隔离，跨文件需重新创建
4. Code to Canvas 每次生成独立 captureId，一次性使用，不可重复
5. 导入的图层需要人工转为 Figma Component

### 预防
1. 初始化时按 `docs/dev/figma-mcp-init-guide.md` 配置 + 安装插件
2. 开发流程参照 `docs/dev/figma-mcp-workflow.md` 双 MCP 协作规范
3. Token 同步用 `node scripts/sync-tokens-to-figma.mjs --sync`
4. 确保 HTML `<img>` 来自同一 HTTP 服务，否则图片无法导入 Figma

---

## 经验：Figma 官方 MCP Starter 计划配额限制及替代方案

### 场景
使用 `generate_figma_design` 将 HTML 转为 Figma 可编辑图层时，Starter 计划提示配额上限。无法生成新 Capture 或使用 `use_figma`。已导入的旧 capture 保留。

### 根因
Figma 官方 MCP Starter 计划有月度调用限额。达到上限后所有写操作被拒绝，直到下个月重置或升级 Professional。

### 解决方案

| 方法 | 可编辑 | 有限额 | 说明 |
|------|--------|--------|------|
| `generate_figma_design`（官方 MCP） | ✅ 矢量/文字 | ❌ Starter 月度限 | 首选 |
| `html.to.design` Figma 插件 | ✅ 矢量/文字 | ⚠️ 独立配额 | 不走 MCP |
| `import_image`（figma-mcp-go） | ❌ 扁平图片 | ✅ 无限制 | 截图导入 |
| figma-mcp-go 逐层重建 | ✅ 完全可控 | ✅ 无限制 | 30-50 次调用/section |

**配额用完后的操作**：
```bash
# 用 wkhtmltopdf 渲染（已安装）
brew install wkhtmltopdf
python3 -m http.server 8899 --bind 127.0.0.1

# figma-mcp-go 搜索并更新已有节点
search_nodes(query, nodeId)
set_text(nodeId, text)  # 更新文本
set_fills(color, nodeId)  # 更新颜色
bind_variable_to_node(nodeId, field, variableId)  # 绑定 Token
```

**用 figma-mcp-go 手动重建的典型流程**：
```
create_frame → create_text → set_fills → set_corner_radius → set_effects
```
注意：手机页面（375x667）逐层重建需 30-50 次工具调用，效果不如 capture 精准（CSS 毛玻璃/flex 布局无法完美还原）。

### 预防
1. 集中批处理 capture，配额留给最关键的模块
2. 次要模块用截图导入或 figma-mcp-go 更新已有节点文字
3. 升级 Professional 可解除配额

---

## 经验：高保真原型多角色分佣提现设计模式

### 场景
交易结算原型需覆盖商家经营收益提现、达人佣金提现、圈子负责人收益提现三种角色。以前的原型遗漏了达人分佣和圈子分佣。

### 根因
SaaS 平台的商业化模式依赖多角色分润（平台抽佣 + 达人带货分佣 + 圈子分佣），三者必须同时覆盖才能体现完整的资金链路。

### 解决方案

**角色收益划分**：

| 角色 | 收益类型 | 提现方式 | 结算周期 |
|------|---------|---------|---------|
| 商家 | 经营收益（商品销售） | 银行卡 | T+1 |
| 达人/KOL | 推广佣金（带货分佣） | 微信零钱 | T+7 |
| 圈子负责人 | 圈子分佣（圈子内交易） | 银行卡 | T+3 |

**原型设计要点**：
```html
<!-- 商家端入口：经营收益与佣金分开 -->
<div class="glass-card" style="display:flex;">
  <div onclick="showS('merchant-withdraw')">经营收益可提: 8,560</div>
  <div onclick="showS('merchant-commission-wd')">佣金可提: 3,280</div>
</div>

<!-- 运营后台审核：三角色分 tab -->
<div class="el-tab-item active">商家提现</div>
<div class="el-tab-item">达人提现</div>
<div class="el-tab-item">圈子提现</div>
```

**运营后台必须覆盖的页面**：
1. 计佣模板管理（平台费率/达人分佣/圈子分佣三列配置）
2. 分佣规则配置（独立的达人/圈子规则 tab）
3. 提现审核（按角色分 tab 筛选）
4. 资金流水（含收入/支出/余额）

### 预防
1. 设计结算类功能时先识别所有资金分配的角色
2. 每个角色独立入口、独立提现方式、独立手续费规则

---

## 经验：kd-review 收敛策略 — 🔵 建议也要修复 + 连续清理轮

### 场景
多租户数据共享功能开发完成后，kd-review 经历了 10 轮+ 修复循环才达到退出门禁（cleanContinuous >= 3）。

### 根因
- R1-R3：🔴🟡修复后以为清空，但残留 🔵 未修复导致后续轮次被重新发现
- R6 因 2 个未使用的 import（预存代码）被标记 🟡，cleanContinuous 归零
- 🔵 问题被忽略的情况下，审查 agent 仍可能将其升级为 🟡（"未使用的 import" 等代码规范问题）

### 解决方案
在 kd-review 流程中，**🔵 建议同样需要主动修复**：

```markdown
# kd-review 改进版流程
1. R1: 全量审查（含 🔴🟡🔵）
2. R1 修复：🔴🟡 立即修 + 🔵 批量修（安全/规范类优先）
3. R2-R3: 验证 + 处理残留
4. R4 onwards: 只出现 🔵 且全修了 → 快速收敛
```

常见 🔵 问题及修复方式：
| 🔵 问题类型 | 常见修复 | 优先级 |
|-----------|---------|-------|
| 未使用的 import | 删除 | 高（易升级 🟡） |
| 缺少 @Transactional(readOnly) | 添加类级别注解 | 中 |
| 缺少 LIMIT | Repository 加 LIMIT 1000 | 中 |
| 缺少枚举校验 | 添加 @Pattern 或 Enum | 中 |
| JdbcTemplate（被禁） | 替换为 MyBatis-Plus @Mapper | 高（规范违规） |

### 预防
- kd-review 第 1 轮后，立即提取全部 🔵 建议并判断：**"不修复会不会在下一轮被重新发现？"** 会则立即修
- 代码规范类（import、命名、注解）优先处理，避免被升级
- 在 manifest.json 中统一追踪 🔵 修复状态

---

## 经验：JdbcTemplate 被项目规范禁止，须替换为 MyBatis-Plus Repository

### 场景
创建 `SharingQueryHelper` 时直接注入 `JdbcTemplate` 查询 `tenant` 表，被审查 agent 标记为 🔵 规范违规。项目规范 `alibaba-java-development-manual.md` 明确"**禁止 JdbcTemplate**：所有 SQL 必须通过 XML Mapper 或 MyBatis-Plus @Mapper 统一管理"。

### 根因
习惯性使用 JdbcTemplate 做简单查询，忽略了项目的 MyBatis-Plus 规范约束。SharingQueryHelper 作为新文件（非存量代码），按规范不应使用 JdbcTemplate。

### 解决方案
创建专用的 MyBatis-Plus `@Mapper` Repository 接口替代 JdbcTemplate：

```java
@Mapper
public interface TenantSharingRepository {
    @Select("SELECT id FROM tenant WHERE is_platform_level = 1 AND deleted = 0")
    List<String> findPlatformLevelTenantIds();

    @Select("SELECT COUNT(1) FROM tenant WHERE id = #{tenantId} AND is_platform_level = 1 AND deleted = 0")
    int countPlatformLevelTenant(@Param("tenantId") String tenantId);
}
```

然后通过 Spring 注入替换 `jdbcTemplate.queryForList()` / `jdbcTemplate.queryForObject()`。

### 预防
- **所有新增 Repository 层代码必须使用 MyBatis-Plus `@Mapper` + `@Select` 注解或 XML Mapper**
- `JdbcTemplate` 仅允许在存量代码中使用，修改存量代码时同步迁移
- 项目检查清单：创建新 Service 时检查是否间接使用了 `JdbcTemplate`
3. 运营后台必须按角色分类审核

---

## 经验：动态 SQL 构建 — COUNT 与 LIST 查询的 JOIN 策略

### 场景
重构 `OpsPlatformOperationService.listOrders()` 时，从 4 路 if-else 分支改为动态 WHERE 条件构建。需要同时支持 COUNT 查询和 LIST 查询，且 phone/userKeyword 筛选需 JOIN `tenant_user` 表。

### 根因
COUNT 查询只需精确计数，可用 INNER JOIN；LIST 查询始终需要 `buyer_nickname`，必须用 LEFT JOIN。用同一个 JOIN 变量 `needUserJoin` 控制两者会导致 LIST 查询行数被 INNER JOIN 过滤。

### 解决方案
```java
// COUNT 查询：无筛选时才用 INNER JOIN
String countSql = "SELECT COUNT(*) FROM trade_order o"
    + (needUserJoin
       ? " INNER JOIN tenant_user tu ON tu.tenant_id = o.tenant_id AND tu.user_id = o.user_id"
       : "")
    + " WHERE " + whereClause;

// LIST 查询：始终 LEFT JOIN（需要 buyer_nickname）
String listSql = "... FROM trade_order o LEFT JOIN tenant_user tu ... WHERE " + whereClause;
```

**关键原则**：
- JOIN 方式不由同一个 boolean 控制——COUNT 按需 INNER，LIST 固定 LEFT
- `params` 数组在 COUNT 查询和 LIST 查询间复用（条件相同），LIST 额外追加 LIMIT/OFFSET

### 预防
1. 动态 SQL 的 COUNT 和 LIST 查询使用不同的 JOIN 策略（COUNT 精确，LIST 包容）
2. 复用 `params` 列表时，LIST 查询必须 `new ArrayList<>(params)` 再追加 LIMIT/OFFSET

---

## 经验：API URL 契约不一致导致 404 — refundReject colon vs slash

### 场景
运营后台退款驳回功能一直报 404。排查发现前端 `actionSuffixMap` 使用 `refundReject: ":reject"`（冒号前缀），而后端 `@PostMapping` 使用 `"/refunds/{refundNo}/reject"`（斜杠前缀）。

### 根因
前后端 URL 风格不一致。`refundApprove` 使用冒号对应后端冒号路径，但 `refundReject` 也使用冒号而后端实际用斜杠。同时 `refundReject` 缺少 `queryOnlyPost` 标记。

### 解决方案
```typescript
// 前端：修正 URL 后缀
const actionSuffixMap: Record<OperationActionKey, string> = {
  refundReject: "/reject",      // ❌ 原是 ":reject"
};

// 前端：添加 queryOnlyPost + 参数提取
const queryOnlyPost: OperationActionKey[] = ["refundReject", "withdrawApprove", ...];
if (actionKey === "refundReject" && payload.reason != null) {
  query.reason = String(payload.reason);
}
```

### 预防
1. 前端 `actionSuffixMap` 与后端 `@PostMapping` URL 逐个验证
2. `@RequestParam` 参数通过 URL query 传递（`queryOnlyPost`），`@RequestBody` 用 JSON body
3. 添加新 action 时同步检查 URL 风格和参数传递方式

---

## 经验：@RequestBody 不安全转型必须添加类型检查

### 场景
`@RequestBody Map<String, Object>` 直接 `(List<String>) body.get("orderNos")` 抛出 `ClassCastException`。

### 解决方案
```java
@SuppressWarnings("unchecked")
private static List<String> safeStringList(Object raw, int maxSize) {
    if (!(raw instanceof List)) return List.of();
    List<?> list = (List<?>) raw;
    if (list.size() > maxSize) list = list.subList(0, maxSize);
    for (Object item : list) {
        if (!(item instanceof String)) return List.of();
    }
    return (List<String>) list;
}
```

### 预防
从 `@RequestBody Map<String, Object>` 获取列表值时使用 `safeStringList()`。

---

## 经验：审计日志 metadata_json 必须使用 JSON 转义

### 场景
字符串拼接 JSON 只转义了双引号，未处理换行符/反斜杠，可能写入非法 JSON。

### 解决方案
```java
private static String jsonEscape(String value) {
    if (value == null) return "null";
    return "\"" + value.replace("\\", "\\\\").replace("\"", "\\\"")
            .replace("\n", "\\n").replace("\r", "\\r")
            .replace("\t", "\\t").replace("\b", "\\b")
            .replace("\f", "\\f") + "\"";
}
```

### 预防
手动 JSON 构造使用 `jsonEscape()`，优先使用 Jackson ObjectMapper。

---

## 经验：CSV 导出必须防止公式注入

### 场景
CSV 字段以 `=+-@` 开头时 Excel 解释为公式，可能造成数据泄露。

### 解决方案
```java
private static String csvEscape(String value) {
    if (value == null) return "";
    if (!value.isEmpty() && "+-=@\t".indexOf(value.charAt(0)) >= 0) {
        value = "'" + value;
    }
    // ... 标准 CSV 转义
}
```

### 预防
CSV 导出统一使用 `csvEscape()`。

---

## 经验：URL query 同步禁止 spread route.query

### 场景
`router.replace({ query: { ...route.query, ...q } })` 导致已清除的筛选条件被旧 URL 值还原。

### 解决方案
```typescript
// ❌ 可能带回旧值
void router.replace({ query: { ...route.query, ...q } });
// ✅ 从空白构建
void router.replace({ query: { tenantId, ...q } });
```

### 预防
`router.replace({ query })` 始终从空白构建。

---

## 经验：Tab 表格内状态值必须使用中文映射

### 场景
Tab 页内 `el-table-column` 直接 `prop="payStatus"` 显示英文 code。

### 解决方案
```vue
<el-table-column label="状态">
  <template #default="{ row }">
    {{ mapRawStatusToChineseLabel("orderManagement", String(row.payStatus ?? "")) }}
  </template>
</el-table-column>
```

### 预防
所有状态显示字段使用 `mapRawStatusToChineseLabel`，不在 Tab 内使用 `prop` 直接绑定。

---

## 经验：批量写操作必须记录审计日志

### 场景
批量备注/标签操作没有审计事件，违规操作无法追溯。

### 预防
所有批量写操作 `INSERT INTO audit_event` 记录操作信息。

---

## 经验：@RequirePerm 必须放在方法级别而非类级别

### 场景
在 Controller 类级别使用 @RequirePerm，所有 API 端点无权限检查。

### 根因
RequirePermAspect 的 @annotation 切入点只匹配方法级别注解，不匹配类级别。

### 解决方案
将 @RequirePerm 放到每个方法上，确保 AOP 捕获。

### 预防
代码审查检查 @RequirePerm 位置。

---

## 经验：FeatureGate 新逻辑上线时必须废弃旧入口

### 场景
FeatureGateAspect 用了旧 GrayscaleGroupService，跳过了新 3 层判定逻辑。

### 根因
引入新表的同时，旧表调用入口未被替换。

### 解决方案
统一委托 FeatureManager.isEnabled() 作为唯一出口。

### 预防
引入新逻辑时 grep 所有调用入口，逐一替换。

---

## 经验：前端字段名必须与后端实体一致

### 场景
前端用 modules，后端用 moduleFlags，字段名不一致导致数据静默丢失。

### 根因
Spring Boot FAIL_ON_UNKNOWN_PROPERTIES=false 不报错。

### 解决方案
前端 Interface 直接映射后端字段名，不自行发明。

### 预防
前后端契约以后端 Java 实体为准。

---

## 经验：kd-review 应包含 🔵（建议级别）修复

### 场景
搜索服务优化的 kd-review 中，用户要求修复所有级别问题包括 🔵。R1 发现 41 个问题（10🔴 15🟡 16🔵），全部修复后代码质量显著提升。

### 根因
🔵 建议通常涉及代码可维护性、防御性编程、文档完善等"软性"质量。积少成多会成为 tech debt。

### 解决方案
在 kd-review 的 fix agent prompt 中不按严重度过滤，对所有级别问题自动修复。🔵 修复也必须遵循最小改动原则、也必须编译验证。

### 预防
kd-review 循环中，默认全级别修复除非用户明确说"只修 🔴"。

---

## 经验：Figma MCP 读取设计稿用于前端实现

### 场景
企业认证前端页面需还原 Figma 设计。使用 figma-mcp-go.get_document + export_tokens 读取节点结构和设计 Token。

### 解决方案
```bash
get_document                    # 获取完整节点树
export_tokens format=json       # 导出设计 Token
save_screenshots items=[...]    # 截图到 prototype/
```

### 预防
前端 Task 启动前先读取 Figma 数据 + 导出 Token 作为输入。截图存 prototype/ 并 .gitignore。
