# HBuilderX：`cachedDataRejected` / `failed to load config from vite.config.ts`

## 现象

在 HBuilderX 中「运行到微信小程序」或发行时，控制台出现类似：

```text
failed to load config from ...\frontend\vite.config.ts
Error: Invalid or incompatible cached data (cachedDataRejected)
    ... plugins\uni_helpers\lib\bytenode\...
```

## 根因（与仓库内 `vite.config.ts` 内容基本无关）

HBuilderX 自带的 **`uni_helpers`** 插件用 **Bytenode** 加载预编译的 **`.jsc`** 字节码。`cachedDataRejected` 表示 **当前进程里的 Node/V8 与这份字节码不兼容**（常见：升级 HBuilderX 后缓存未对齐、内置 Node 切换、插件损坏、极少数情况下自定义 Node 与插件不匹配）。

本仓库在 **`frontend/`** 下执行 **`pnpm run build:mp-weixin`** 或 **`pnpm run dev:mp-weixin`** 能成功时，说明 **Vite / uni 工程配置正常**，问题在 **HBuilderX 运行环境或 HB 插件缓存**。

## 推荐工作流（团队与 CI 一致）

在 **`frontend/`** 目录：

```bash
pnpm install
pnpm run dev:mp-weixin
```

用 **微信开发者工具** 导入 **`frontend/dist/dev/mp-weixin`**。日常开发不必依赖 HBuilderX 内置编译器。

## 若必须使用 HBuilderX：按顺序尝试

1. **运行前清理构建缓存**  
   打开运行控制台（如 `Ctrl+R` 相关入口），在运行配置里勾选 **「清理构建缓存」** 后再运行（DCloud 社区常见有效步骤）。

2. **清理项目生成目录**  
   关闭 HBuilderX 后，删除项目下的 **`unpackage`**（若存在）、以及 **`frontend/dist`**，再重新打开工程并 **`pnpm install`** 后重试。

3. **检查是否改过「自定义 Node」**  
   若曾在 HBuilderX 中指定过外部 Node，先改回 **内置 Node** 试一次；或改为与本机 **LTS 版本** 一致且 DCloud 当前文档推荐的路径（避免 V8 与 `.jsc` 不一致）。

4. **升级或重装 HBuilderX**  
   - 优先升级到官网 **当前最新正式版**（你日志中的 `4.66.2025051912` 若偏旧，升级后常能消除插件与字节码不匹配）。  
   - 若仍失败：**完全卸载** 后重装到**新目录**（不要叠在旧目录上覆盖升级），再试。

5. **校验 `uni_helpers` 插件完整性**  
   确认安装目录下存在：  
   `HBuilderX\plugins\uni_helpers\`  
   若缺失或怀疑损坏：用**同版本** HBuilderX 安装包修复安装，或从同版本另一台机器拷贝该目录（官方问答中常见做法）。

## 路径说明（次要因素）

工程路径含中文（如 `D:\共享家\...`）在少数环境下会放大路径/编码类问题。**若以上步骤仍失败**，可临时将仓库克隆到 **仅 ASCII 路径**（如 `D:\work\kangdou-fullstack`）再于 HBuilderX 中打开，用于判断是否与环境有关。

## 参考链接（DCloud 社区）

- [运行和发行微信小程序报 `Invalid or incompatible cached data (cachedDataRejected)`](https://ask.dcloud.net.cn/question/219028)  
- [HBuilderX 如何清除缓存](https://ask.dcloud.net.cn/question/217616)
