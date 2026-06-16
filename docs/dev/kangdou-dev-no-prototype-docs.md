<!--
description: 开发阶段禁止修改 docs/products/v1 产品原型与高保真目录
globs: docs/products/v1/**/*
alwaysApply: false
-->

- **约束：** 在本仓库进行功能开发、联调、Bug 修复、重构或任务执行时，**不得修改** `docs/products/v1/` 下**任何**文件（含 `.html`、`.md`、`.json`、静态资源、子目录等）。
- **例外：** 仅当用户**明确**要求修改该目录下的具体文件时，方可改动；默认一律视为禁止。
- **例外（联合套卡体验发布 · 高保真，已授权）：** 当执行 **`docs/superpowers/plans/2026-05-13-joint-card-hifi-prototype-plan.md`** 及其任务图 **`docs/superpowers/tasks/joint-card-hifi-prototype.json`** 时，**允许**在 `docs/products/v1/` 内修改该 plan **§3 受控文件清单**所列路径，以及 **`docs/products/v1/联合套卡-体验发布-高保真/**`**；清单含 **`客户端/小程序-店铺.html`、`客户端/小程序-商品频道.html`、`客户端/小程序-平台订单中心.html`** 等与本特性互链之页。**不得**借机批量改动与本特性无关的其它 v1 原型。其它任务仍默认禁止触碰 `docs/products/v1/`。
- **替代做法：** 原型相关变更应落在独立分支/工单或由产品侧发起；实现代码放在 `backend/`、`operation/`、小程序工程等非原型目录。
