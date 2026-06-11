# SSOT 任务图

任务图 JSON 文件存储在 `docs/superpowers/tasks/<featureId>.json`，是任务依赖与状态的唯一事实源（SSOT）。

## Schema

```json
{
  "featureId": "xxx",
  "title": "特性名称",
  "planPath": "docs/superpowers/plans/...md",
  "tasks": [
    {
      "id": "task-001",
      "title": "任务描述",
      "status": "pending",
      "dependsOn": ["task-000"],          // 前置依赖的任务ID列表，空数组=无依赖可并行
      "group": "A",                        // 并行组：同组可并行执行，A→B→C表示先后顺序
      "subsystem": "backend"               // 所属子系统：backend/frontend/operation/cross
    }
  ]
}
```

## 校验

```bash
node scripts/verify-plan-ssot.mjs validate <path-to-json>
```
