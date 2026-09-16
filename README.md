# Capybara

原创水豚主角的温馨水岸家园游戏，采用 Godot 4.7.2 Standard、静态类型 GDScript 与 Compatibility。目标为非像素高分辨率绘本2D/2.5D、八个主要地区与可持续探索远野；通过建设、种植、钓鱼与社区故事恢复水生态。

当前开发性质：Stage3原型，尚未通过正式美术门，远未达到RC1。默认入口是两区域灰盒，已有移动/交互、库存、设置和存档；独立家园预览展示主屋、桥、水车、码头、树冠和水面，不能把这些画面当作建造/种植/钓鱼/生态系统已完成。

## 运行与检查

在唯一工程 `E:\Capybara` 使用 PowerShell 7；外部工具放 `D:\GameDev`，引擎通过 `GODOT_BIN` 调用，不复制工具/SDK进工程，不重建或解压覆盖项目。

```powershell
& $env:GODOT_BIN --version
pwsh -NoProfile -File .\tools\check_project.ps1
pwsh -NoProfile -File .\tools\run_game.ps1
pwsh -NoProfile -File .\tools\run_game.ps1 -VisualPreview
```

灰盒：WASD/方向键/左摇杆移动，E/南键交互，Tab/Back背包，Q/R/肩键切换工具，Esc/Start暂停，F3调试信息。动作以设置页当前重映射为准。预览复用暂停/设置，设置只对本进程生效、不提供正式存读档；减少动态应冻结水纹/水车而仍可移动。手柄合成路径有历史回归，实体硬件缺口见QA-001。

## 开发入口

- [执行与安全边界](AGENTS.md) → [当前恢复点](docs/STATUS.md) → [阶段索引](PLANS.md)。
- [产品契约](CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md)：完整范围与RC1标准。
- [文档地图](docs/README.md)、[当前Stage3计划](docs/stages/stage-03/PLAN.md)、[问题登记](docs/ISSUES.md)、[发布准备度](docs/RELEASE_READINESS.md)。

公开源码同步不等于面向玩家发行。安全续开发线为 `codex/production-clean-20260916`；旧本地开发/main/tag含已隔离资产祖先，只保留本地审计，禁止接回公开线。构建、截图和长机器日志在忽略的build，实际验证与失败由各阶段LOG索引。所有正式素材须有来源/AI/编辑/权利和实际视觉批准；概念图不冒充实机截图。
