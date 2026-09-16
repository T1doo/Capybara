# 阶段总路线索引

产品范围只由[v2 契约](CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md)定义；任务状态只在各阶段PLAN，实际记录在对应LOG。[当前恢复点](docs/STATUS.md)记录当前事实。Stage3是产品焦点，本轮先完成Stage0.5治理/CI与Stage2可靠性回归，再回到正式美术及入口。

| Stage | 目标 / 任务入口 | 关键前置与退出证据 |
|---|---|---|
| 0 | [工程基线](docs/stages/stage-00/PLAN.md) | 既有工程不重建；版本/基础运行 |
| 0.5 | [治理、CI 与恢复](docs/stages/stage-00-5/PLAN.md) | 安全线/新文档/CI/正负治理 |
| 1 | [玩家、交互与场景](docs/stages/stage-01/PLAN.md) | 20分钟输入转场soak |
| 2 | [数据、库存、设置、双语与可靠存档](docs/stages/stage-02/PLAN.md) | 库存守恒、组合存档恢复和旧档 |
| 3 | [高品质美术基线与正式入口集成](docs/stages/stage-03/PLAN.md) | 母图/A-B/NPC/UI/四氛围/正式入口 |
| 4 | [大型世界、分块与程序化外围](docs/stages/stage-04/PLAN.md) | Stage3入口；60分钟有界流送 |
| 5 | [地形、水生态与建设](docs/stages/stage-05/PLAN.md) | chunk、时间/条件/NPC设施前置；200次生态建设 |
| 6 | [农业、制作、烹饪、经济与住宅](docs/stages/stage-06/PLAN.md) | 时间/水生态；生产/住宅成长闭环 |
| 7 | [钓鱼、水域活动、拍照与收藏](docs/stages/stage-07/PLAN.md) | 统一条件；差异活动/图鉴/水域安全 |
| 8 | [NPC、关系、日程、任务与社区](docs/stages/stage-08/PLAN.md) | 基础设施导航；4故事样板/无软锁 |
| 9 | [八个正式地区与远野内容](docs/stages/stage-09/PLAN.md) | 样板管线；八区/内容下限/主要结局 |
| 10 | [视听、动画、UI 与叙事整体精修](docs/stages/stage-10/PLAN.md) | 成套内容；完整动画/音频/四季/8环境 |
| 11 | [平衡、性能、可靠性、无障碍与本地化](docs/stages/stage-11/PLAN.md) | 全内容；2小时soak/硬件/全文/平衡 |
| 12 | [Windows RC1 与 Steam 准备](docs/stages/stage-12/PLAN.md) | 全质量门；干净Windows RC1及Steam准备 |

外部试玩CAP-0540位于Stage11并受用户授权约束；Stage3内部整合ART3-105与Stage5实玩AUT-0505支撑自主生产。基础音频、GameClock/环境条件和NPC设施使用已前置Stage5，全量故事/天气视听仍分别在Stage8/10。Stage10动画/VFX、UI、音频按真实能力并行，禁止机械长链。通过阶段后按[AGENTS](AGENTS.md)安全Git规则继续，不能从旧本地main/开发祖先合回公开线。
