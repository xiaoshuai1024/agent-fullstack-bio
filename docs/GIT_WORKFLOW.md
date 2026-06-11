# Git 工作流

本文档定义 Agent 必须遵守的 Git 工作流规范。

---

## 〇、克隆与子模块：SSH 检测与 HTTPS 备选

仓库与子模块默认使用 **SSH**（见仓库根目录 `.gitmodules`）。在开始 `git clone` / `git submodule update` 前，Agent 与用户应先确认本机是否具备可用的 SSH 密钥；若克隆或子模块更新出现 `Permission denied (publickey)` 或类似认证失败，应优先引导完成 SSH 配置，而不是反复重试命令。

### 〇.0 交互式脚本（推荐）

在主仓库根目录执行：

```bash
./scripts/git-auth-setup.sh
```

脚本会：检测是否存在 `~/.ssh/id_ed25519.pub` 或 `id_rsa.pub`；若无公钥且你选择 SSH，则打印云效 SSH 配置步骤并退出（避免无效重试）；若选择 HTTPS，则提示按云效文档配置 HTTPS 克隆账号；随后为本机设置 `frontend` / `backend` 子模块 URL（**只改本地配置**，不修改已提交的 `.gitmodules`），并执行 `git submodule update --init --recursive`；失败时按协议给出对应文档链接。

非交互（CI 或脚本调用）：`GIT_AUTH_MODE=ssh ./scripts/git-auth-setup.sh` 或 `GIT_AUTH_MODE=https ./scripts/git-auth-setup.sh`。

### 〇.1 是否已配置 SSH 公钥（自检）

在终端执行其一即可：

```bash
# 若文件存在且能打印出以 ssh-ed25519 或 ssh-rsa 开头的公钥，通常表示已生成密钥
test -f ~/.ssh/id_ed25519.pub && cat ~/.ssh/id_ed25519.pub
test -f ~/.ssh/id_rsa.pub && cat ~/.ssh/id_rsa.pub
```

可选连通性测试（需已把公钥添加到云效/Codeup）：

```bash
ssh -T git@codeup.aliyun.com
```

### 〇.2 未配置或未在云效绑定公钥时的建议

1. **生成密钥（推荐 ED25519）**：`ssh-keygen -t ed25519 -C "你的邮箱或备注"`  
2. **将公钥完整复制**（从 `ssh-` 开头到行末）。  
3. **登录云效** → 右上角头像 → **个人设置** → **SSH 公钥** → 添加并保存。

官方步骤与多密钥、`~/.ssh/config` 配置见阿里云文档：[在 Codeup 中配置和使用 SSH 密钥进行代码推拉](https://help.aliyun.com/zh/yunxiao/user-guide/configure-ssh-key)。

### 〇.3 子模块能否选择 SSH 或 HTTPS？

**Git 不会在每次操作时弹出「选 SSH 还是 HTTPS」的交互菜单。** 鉴权方式由 **远程 URL 的协议** 决定：

| 来源 | 作用 |
|------|------|
| **`.gitmodules`（提交到仓库）** | 记录团队默认的子模块 URL（本项目为 SSH）。所有人 `git submodule update --init` 时会按该 URL 拉取。 |
| **本地覆盖（推荐用于个人偏好）** | 不在仓库里改 `.gitmodules`，仅在当前克隆内改用 HTTPS，例如：`git submodule set-url frontend <https-url>`、`git submodule set-url backend <https-url>`，然后执行 `git submodule sync --recursive` 与 `git submodule update --init`。也可用 `git config submodule.<name>.url <url>`，效果类似，均只写入本地 `.git/config`。 |

因此：**可以让不同开发者在本机分别使用 SSH 或 HTTPS**，做法是各自在克隆主仓库后，用上述命令把子模块 URL 改成 HTTPS（或反过来改回 SSH），无需修改主仓库已提交的 `.gitmodules`。使用 **HTTPS** 拉取子模块时，凭据与克隆方式见：[配置 HTTPS 克隆账号密码](https://help.aliyun.com/zh/yunxiao/user-guide/configure-https-clone-account-password)。

与本项目路径一致的示例（主仓库与各子模块路径与 SSH 形态一致，仅协议与主机写法不同）：

```text
# SSH（默认，与 README / .gitmodules 一致）
git@codeup.aliyun.com:<organization-id>/<group>/<repository>.git

# HTTPS（仅供未配置 SSH、选择 HTTPS 的用户在本地使用）
https://codeup.aliyun.com/<organization-id>/<group>/<repository>.git
```

将占位符替换为你所在组织的真实路径。

### 〇.4 Agent / 自动化修改代码前的分支（强制）

**背景**：本项目维护者通常已经在正确的工作分支中打开 workspace。Agent 自动新切 `feature/*` 分支会把改动写到错误位置，打断维护者的分支节奏。

**规则**：凡将变更写入 Git 跟踪的文件（含 `docs/`、`frontend/`、`backend/`、`operation-backend/`、`scripts/` 等），在**第一次保存/写入前**，必须在**被修改文件所属的 Git 仓库**内确认当前分支：

1. 先执行并汇报当前仓库路径与 `git branch --show-current`。
2. **用户分支优先**：默认留在用户当前工作分支写代码；本项目当前约定默认工作分支为 `dev-vnext3`（各子模块同名分支）。
3. **不得自动新切分支**：除非用户在本轮对话中明确要求创建/切换分支，否则 Agent 不得执行 `git checkout -b feature/...`、不得从 `dev` 自动切出 feature。
4. **分支不匹配时先问**：若当前分支不是用户指定分支（例如不是 `dev-vnext3`），必须暂停并询问用户希望切到哪个分支或是否继续在当前分支写入。
5. **子模块**：若修改 `backend/`、`frontend/`、`operation-backend/` 等独立子模块仓库，应在对应子模块仓库内分别确认分支；多仓任务默认使用用户指定的同名工作分支。
6. **禁止**：在 **`master`** 上直接开发式提交（热修复也须先取得用户明确指令并按 hotfix 流程）。
7. **例外**：用户明确要求「新建 feature 分支」「从 master 切 hotfix」「就在当前分支提交」等，按用户指令执行，并在回复中注明分支策略。

### 〇.5 任务级分支规则（MUST）

为避免 Agent 误改分支，新增以下硬规则：

1. **单系统任务**：任意任务开始前，确认该系统仓库当前分支；默认在用户当前工作分支写入。  
2. **多系统任务**：涉及两个及以上系统（如主仓 + 子仓、frontend + backend、frontend + operation-backend）时，相关系统默认使用用户指定的同名工作分支（当前为 `dev-vnext3`）。  
3. **任务切换**：不得因任务切换自动创建新分支；若 Agent 判断需要隔离分支，必须先说明原因并取得用户明确同意。  
4. **执行顺序**：`git branch --show-current` → 确认是用户指定分支 → 开始首次写入。  
5. **违规则处理**：若发现已切到非用户指定分支或产生了新任务改动，必须立即停止继续开发，切回/迁移前先向用户说明并确认。

Agent 在开始写代码前应简要汇报：**当前仓库路径、`git branch --show-current` 显示的分支名**；若无法执行 git（只读沙箱等），须说明并请求用户确认分支后再继续。

### 〇.6 合并冲突与拉取（Agent MUST）

1. **禁止自动合并**  
   - 不得在未获用户**逐步、明确**授权的情况下，自行完成会产生合并提交的 `merge` / `rebase` / `cherry-pick` 等并推送到远端。  
   - 不得使用「自动接受某一方」类策略静默解决冲突并提交。

2. **发现冲突时**  
   - **立即停止**相关 Git 写操作，向用户说明冲突涉及的大致路径与命令上下文。  
   - **必须询问用户**希望如何处理（例如：保留本地、保留远端、逐文件手工、中止合并等）。  
   - **在得到用户明确指示前**，不得提交合并结果、不得假定用户选择某一策略。

3. **用户要求 pull / 拉代码时**  
   - 若当前仓库存在**未提交**的本地改动（含已暂存或未暂存）：**须先**与用户确认后完成 **`git commit`**（或用户**明确**要求时用 `stash` 等等价方式），**再**执行 `pull`；禁止在未处理工作区改动时直接 `pull`，以免丢失或产生难以追溯的冲突。  
   - 若无任何可提交改动，可按常规流程 `pull`。

---

## 一、分支结构

```
master (发布分支)
  ↑
dev-vnext3 (当前用户工作分支)
  ↑
hotfix/xxx (热修复分支) → 直接合入 master 和 dev
```

---

## 二、分支说明

| 分支 | 用途 | 生命周期 | 合并目标 |
|------|------|----------|----------|
| `master` | 生产发布 | 长期 | - |
| `dev` | 开发主干 | 长期 | `master` (发布时) |
| `dev-vnext3` | 当前用户工作分支 | 按迭代周期 | 用户指定目标 |
| `feature/xxx` | 可选隔离分支（仅用户明确要求时创建） | 短期 | 用户指定目标 |
| `hotfix/xxx` | 生产紧急修复 | 短期 | `master` + `dev` |
| `bugfix/xxx` | 非紧急缺陷修复 | 短期 | `dev` |
| `release/xxx` | 发版准备 | 短期 | `master` + `dev` |

---

## 三、工作流程

### 3.1 功能开发流程

```
1. 确认用户当前工作分支（默认 dev-vnext3）
   │
2. 在当前工作分支开发 + commit
   │
3. 功能完成 → 用户选择是否 push / 创建 MR
   │
   ├── [选项A] 保留在当前工作分支
   │   (Agent: "已 commit 到 dev-vnext3，是否 push?")
   │
   └── [选项B] 按用户指定目标创建 MR
       (Agent: "是否从 dev-vnext3 创建到目标分支的 MR?")
```

### 3.2 热修复流程

```
1. 从 master 切出 hotfix 分支
   │
2. 修复并 commit
   │
3. 提交 PR 到 master + dev
```

---

## 四、Commit 规范

### 4.1 提交信息格式

```
<type>: <subject>

<body>

<footer>
```

### 4.2 Type 说明

| 类型 | 说明 |
|------|------|
| `feat` | 新功能 |
| `fix` | 缺陷修复 |
| `docs` | 文档 |
| `style` | 格式（不影响逻辑）|
| `refactor` | 重构 |
| `test` | 测试 |
| `chore` | 工具链、依赖 |

### 4.3 示例

```
feat: 添加圈子成员管理功能

- 新增成员列表接口
- 新增添加/移除成员功能
- 支持批量操作

Closes #123
```

---

## 五、Commit 提交时机

**禁止自动 commit**，除非满足以下条件之一：

1. **完成完整需求后** - 用户验收通过，发出提交询问
2. **用户明确要求提交** - 用户主动要求 commit 代码

## 六、Commit 时 Agent 行为

功能完成后，Agent 必须询问用户：

```
## 选项 A：保留在当前分支
> "已 commit 到 dev-vnext3。是否 push 到远程？"

## 选项 B：按用户指定目标创建 MR
> "是否从 dev-vnext3 创建到目标分支的 MR？"
```

用户确认前，**禁止**执行 push 或创建 PR。

当用户在对话中明确提出「提交代码」「提交修改」或语义等价请求时，Agent 应按当前分支策略执行完整提交流程：`commit + push`（不只 commit 不 push）；若分支/远程状态不满足 push 前置条件，应先向用户说明并完成必要准备后再 push。

---

## 七、禁止行为

- ❌ 未经用户确认就 commit
- ❌ 未经用户确认就 push
- ❌ 直接提交到 dev 或 master
- ❌ 跳过 PR 直接合并
- ❌ 强制覆盖远程分支
- ❌ **在任何情况下 push 到 master 分支**
- ❌ **MUST NOT 在任意时间直接 commit 到 master 分支**（热修复也必须走 `hotfix/*` → PR 流程）
- ❌ 用户请求创建 PR/MR 时跳过云效 MCP 环境初始化检查
- ❌ 在本仓库用 `gh pr create` 或 GitHub CLI 代替云效 MCP 创建 PR/MR

---

## 十、云效集成：MCP 优先

### 10.1 总原则（所有云效相关能力）

凡涉及 **云效 / Codeup** 的操作（含合并请求、代码库、工作项、流水线等），**优先使用云效 MCP Server**。仅在 MCP 未就绪、鉴权失败或 MCP 未暴露对应该动作的工具时，才回退到本仓库已约定的脚本或官方 OpenAPI，并在回复中**写明回退原因**。环境与排障见 `docs/dev/yunxiao-mcp-troubleshooting.md`。

### 10.2 PR/MR 创建（在总原则之上）

当用户出现「提交PR / 创建PR / 创建MR / 合并请求」或语义等价表达时，Agent 必须：

1. **先做环境初始化确认**：询问是否协助检查/安装创建 PR 所需环境（Cursor Agent 登录、MCP server 配置启用、YUNXIAO token、组织权限）。
2. **优先走云效 MCP Server**：使用 MCP 创建 PR/MR，并遵守用户指定源分支 -> 目标分支；本项目当前默认源分支为 `dev-vnext3`，不得擅自改为 `feature/*`。
3. **仅在 MCP 不可用时回退**：可回退到 `scripts/codeup/create-mr.sh` 或 `scripts/codeup/create-pr-all.sh`，并在回复中说明回退原因。
4. **禁止目标为 master**：除非用户明确要求并走 hotfix 例外流程。
5. **首次使用且无 token 必须增强引导**：若检测到首次 MCP 初始化且缺失/无效 `YUNXIAO_TOKEN`，必须提供可点击入口 URL（token 创建页、MCP 接入文档/初始化入口）+ 明确步骤（登录、创建 token、配置到环境、重载 MCP、校验连通性）后再继续。
6. **完成确认前不得继续创建**：用户未确认“token 已配置并校验通过”前，不得进入 PR/MR 创建动作；应先完成一次校验并回报结果。
7. **后续触发必须再次提醒**：同一会话或后续会话再次触发 PR/MR 意图时，如历史上出现过“首次无 token”场景，仍需再次提醒初始化要点（URL + 步骤摘要），避免遗漏。

> 门禁建议：在项目 hooks 中启用「危险 shell 命令拦截」（如 `gh pr`、直推 master）；PR/MR 流程以仓库规则与 Agent 文档为准。勿使用 `beforeSubmitPrompt` 拦截「助手是否已提 MCP」——该时机拿不到针对本轮 PR 的助手回复，且易与 Cursor 期望的 JSON 字段不一致导致报错。

### 10.3 PR/MR 合并

当用户需要 **合并已创建的 MR** 时：

1. **yunxiao MCP Server 未暴露合并工具**：当前 `alibabacloud-devops-mcp-server`（v0.3.14）中 **没有** `merge_change_request` 或类似工具。合并 MR 须通过脚本回退。
2. **使用 `scripts/codeup/merge-mr.sh`**：
   ```bash
   # 合并 MR #1（默认 rebase）
   scripts/codeup/merge-mr.sh --local-id 1 --allow-fallback
   
   # 合并 + 自定义提交信息 + 删除源分支
   scripts/codeup/merge-mr.sh --local-id 1 --merge-message "feat: xxx" \
     --remove-source-branch --allow-fallback
   ```
3. **API 机制**：`POST .../changeRequests/{localId}/merge`（与 create-mr.sh 同域、同认证方式）。已验证 `rebase` 类型可正常工作。
4. **获取 localId**：创建 MR 时脚本输出的 `localId` 字段，或从云效控制台 MR 详情 URL 末尾的数字。

---

## 八、双仓（前后端）

- 前后端使用**用户指定的同名工作分支**（当前默认 `dev-vnext3`）
- 提交时同步通知两仓库

---

## 九、常用命令参考

```bash
# 确认当前分支
git branch --show-current

# 如需切到用户指定工作分支（示例：dev-vnext3）
git checkout dev-vnext3

# 推送当前工作分支
git push origin dev-vnext3
```
