# 合并 MR 的正确方式

## 背景

项目使用阿里云 Codeup 管理代码，MR（Merge Request）合并需通过 Codeup API 操作。`scripts/codeup/merge-mr.sh` 脚本存在 Python heredoc 内存崩溃问题（exit 139），故推荐直接使用 curl API。

## 前置条件

- `YUNXIAO_TOKEN` 已配置在 `scripts/codeup/.env`
- 已知 Organization ID（本项目：`69e0392d29ad98af40661eef`）
- 已知仓库 ID（Repository ID）

## 仓库 ID 列表

| 仓库 | 路径 | Repository ID |
|------|------|:------------:|
| 小程序前端 | kangdou-uniapp | 6638222 |
| 后端 | kangdou-api | 6638225 |
| 运营后台 | operation-backend | 6659621 |
| 主仓库 | kangdou-fullstack | 6638169 |

## 合并单个 MR

```bash
source scripts/codeup/.env

curl -s -X POST \
  -H "x-yunxiao-token: ${YUNXIAO_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"mergeType":"rebase","mergeMessage":"feat: merge description"}' \
  "https://openapi-rdc.aliyuncs.com/oapi/v1/codeup/organizations/69e0392d29ad98af40661eef/repositories/{REPO_ID}/changeRequests/{MR_ID}/merge"
```

参数说明：
- `mergeType`：固定 `rebase`（已验证可用）
- `mergeMessage`：合并提交信息
- `REPO_ID`：上表仓库 ID
- `MR_ID`：MR 编号（如 103）

## 查看 MR 状态

```bash
curl -s \
  -H "x-yunxiao-token: ${YUNXIAO_TOKEN}" \
  "https://openapi-rdc.aliyuncs.com/oapi/v1/codeup/organizations/69e0392d29ad98af40661eef/repositories/{REPO_ID}/changeRequests/{MR_ID}" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(f'status={d.get(\"status\")} source={d.get(\"sourceBranch\")} target={d.get(\"targetBranch\")}')"
```

返回 `status=MERGED` 表示合并成功。

## 批量合并所有子模块 MR

```bash
source scripts/codeup/.env
TOKEN="$YUNXIAO_TOKEN"
ORG_ID="69e0392d29ad98af40661eef"

for args in "6638222 103" "6638225 103" "6659621 74" "6638169 104"; do
  read -r RID MID <<< "$args"
  echo "=== MR #$MID ==="
  curl -s -X POST \
    -H "x-yunxiao-token: ${TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"mergeType\":\"rebase\",\"mergeMessage\":\"feat: merge\"}" \
    "https://openapi-rdc.aliyuncs.com/oapi/v1/codeup/organizations/${ORG_ID}/repositories/${RID}/changeRequests/${MID}/merge"
  echo ""
done
```

## 完整流程（从本地到合并）

```bash
# 1. 确保分支最新
bash scripts/git/pull-all-dev.sh

# 2. 创建 PR（含自动提交）
bash scripts/pr/publish-to-dev.sh all -m "feat: 改动说明" -t "改动标题"

# 3. 从输出中获取 MR ID，逐个合并（见上）
```

## 注意事项

- 合并类型统一使用 `rebase`，其他类型（`no-fast-forward`、`squash`、`ff-only`）未经完整验证
- MR 合并顺序：frontend → backend → operation-backend → fullstack（最后更新子模块指针）
- 合并后各仓的 `feature/*` 分支不会自动删除，如需清理请在 Codeup 页面操作
- `scripts/codeup/merge-mr.sh` 脚本存在 Python heredoc 内存问题（exit 139），**不推荐使用脚本方式合并**
