# AGENTS.md

本文件是 Codex 在本仓库中的长期工作规则。任何任务都必须遵守。

## 最高优先级目标契约

- Stage 0 之后，根目录的 `CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md` 是本仓库最高优先级项目执行契约。
- 本文件、`PLANS.md` 或 `docs/` 与目标契约冲突时，以目标契约为准；永久有效的安全、原创性、密钥和实际测试规则仍不可降低。
- 恢复自治工作时必须依次读取：目标契约、`AGENTS.md`、`PLANS.md`、`docs/AUTONOMOUS_STATUS.md`、最近 20 条 Git 提交、当前 Git 状态和当前测试结果。
- Stage 质量门通过后自动 commit、merge、tag，并在远程身份、可见性和权限可安全确认时非强制 push；不得因常规设计选择停下等待批准。
- 只有目标契约第 4 节的硬阻塞或 RC1 全部 Definition of Done 已满足时，才允许暂停长期 Goal。

## 项目概述

- 项目代号：Capybara。
- 固定仓库根目录：`E:\Capybara`；不得在其他位置创建第二份工程。
- 类型：原创 2D 温馨家园、轻建造、种植、钓鱼、NPC 社交。
- 首发平台：Windows / Steam。
- 引擎：Godot 4.7.2 Standard。
- 脚本：静态类型 GDScript。
- 渲染：Compatibility。
- 地图：64×64 像素逻辑网格；高密度手工核心地区、分块流送与确定性程序化外围组合的大型开放世界。
- AI：仅开发期间生成预制资产，v1.0 不包含运行时 AI。

## 绝对规则

1. 不使用或模仿任何未授权角色、IP、Logo、宣传图、音乐、字体或素材。
2. 不使用上传的“水豚噜噜”图片作为生成参考，除非以后提供了明确书面授权。
3. 不在图像提示词中要求模仿具体 IP 或在世艺术家。
4. 不把 API 密钥、Steam 凭据、证书或个人信息写进仓库。
5. 不自动升级 Godot 版本。
6. 优先零第三方插件；确有必要时必须完成许可证、安全、维护性审查并锁定版本。
7. 不一次实现多个大型系统。
8. 不在没有实际运行的情况下声称测试通过。
9. 不覆盖 `art/source_layers` 中的源文件。
10. 不把 `art/generated_raw` 中的图片直接复制到 `game/assets`。

## 开始任务前

- 确认当前工作区根目录为 `E:\Capybara`，并直接包含本文件与 `docs/`。
- 读取最高优先级目标契约、`PLANS.md` 和 `docs/AUTONOMOUS_STATUS.md`；缺失时先执行 Stage 0.5 治理恢复。
- 阅读与任务相关的 `docs/` 文件。
- 检查当前 Git 状态。
- 识别未提交修改，避免覆盖用户工作。
- 输出不超过 8 条的实施计划。
- 明确本任务的验收标准。

## 代码规范

- 所有函数参数、返回值、成员变量尽量使用明确类型。
- 使用 `snake_case`：文件、变量、函数。
- 使用 `PascalCase`：`class_name` 与资源类型。
- 使用 `SCREAMING_SNAKE_CASE`：常量。
- 使用稳定 ID，不用显示名称作为存档键。
- 玩家可见文本使用本地化键和 `tr()`，不得写死。
- 单个脚本原则上不超过 350 行；超过时优先拆分职责。
- 避免深层节点路径；优先使用导出节点引用、组件或明确接口。
- 避免全局单例膨胀；Autoload 只保留跨场景且确有必要的服务。
- 使用信号解耦 UI 与游戏逻辑。
- 纯数据优先使用自定义 `Resource`；存档使用版本化 JSON。
- 不直接序列化整个节点树。
- 公共接口和非显然算法写简短注释，避免逐行废话注释。

## 目录规则

```text
game/autoload/              跨场景服务
game/core/                  通用类型与纯逻辑
game/data/definitions/      Item、Crop、Fish、NPC 等 Resource 定义
game/scenes/                场景
game/systems/               独立游戏系统
game/tests/                 无第三方依赖的自动测试
game/assets/                已批准并处理完成的游戏资产
art/generated_raw/          原始 AI 输出，不直接进游戏
art/candidates/             候选与联系表
art/approved/               已批准视觉方案
art/source_layers/          Krita/Blender 等可编辑源文件
tools/                      Windows PowerShell 与资产处理脚本
build/                      导出构建，不提交 Git
```

## 默认运行命令

优先从 Windows 环境变量读取 Godot：

```powershell
$env:GODOT_BIN
```

项目检查：

```powershell
& $env:GODOT_BIN --headless --path game --import
```

运行测试：

```powershell
& $env:GODOT_BIN --headless --path game --script res://tests/run_all.gd
```

运行游戏：

```powershell
& $env:GODOT_BIN --path game
```

如果命令因当前 Godot 版本参数差异而失败，先查看本机 Godot 帮助，再以最小方式修正脚本，同时记录变更。

## 每个任务的完成标准

- 功能满足明确验收条件。
- 没有新增解析错误或明显警告。
- 自动检查实际执行。
- 涉及 UI 时测试键鼠和手柄导航。
- 涉及存档时测试保存、加载、缺失数据、旧版本迁移和损坏备份。
- 涉及地图时测试碰撞、遮挡、排序和边界。
- 更新受影响文档与变更记录。
- 报告所有改动文件和手工测试步骤。

## 素材工作流

状态只能按以下顺序前进：

```text
generated_raw -> candidates -> approved -> source_layers/game_ready -> game/assets
```

每项素材必须登记到 `docs/ASSET_MANIFEST.csv`。需要记录：来源方式、提示词版本、引用的原创母图、人工修改、许可证或权利依据、批准状态与游戏路径。

## 永久禁止与长期允许范围

永久不做：

- 联机或多人。
- 战斗。
- 真正任意形状的连续地形雕刻。
- 运行时 AI。
- 手机或主机移植。
- 大量付费插件。
- 复杂脚本语言式对话编辑器。

按目标契约和 Stage 质量门长期实现，不再视为禁止范围：

- 大型开放世界、分块流送和确定性程序化外围。
- 昼夜、丰富天气和四季视觉/内容变化。
- 8 个主要地区、程序化远野、生态响应和多层地形。
- 高分辨率、非像素、统一绘本 2D/2.5D 正式美术。

## 自治执行与恢复

- 当前计划、质量证据和下一个任务以 `PLANS.md` 与 `docs/AUTONOMOUS_STATUS.md` 为准。
- 每个可验证小批次完成后运行统一检查，进行自审，更新状态并原子提交。
- 每个 Stage 通过后合并到稳定 `main`，创建注释标签，再自动进入下一 Stage。
- GitHub 身份或仓库可见性无法安全确认时继续本地开发与提交，把待同步范围写入自治状态；不得盲目 push。
- 当前公开历史安全限制见 `GIT-002`：原开发历史包含已隔离素材对象，禁止直接push该历史或把其祖先merge回公开审阅分支。当前tree的独立快照可供审阅；长期同步迁移须另行验证历史可达对象，不得force push。
- 所有阶段问题统一登记在 `docs/KNOWN_ISSUES.md`，发布证据统一登记在 `docs/RELEASE_READINESS.md`。

## 最终报告格式

```text
任务目标
实施摘要
修改文件
新增文件
删除文件
执行的检查与结果
手工测试步骤
风险与已知问题
文档更新
建议的下一项小任务
```
