# 文档地图

恢复依次读[AGENTS](../AGENTS.md)、[STATUS](STATUS.md)、[总阶段索引](../PLANS.md)、当前PLAN及LOG最近条目、[ISSUES](ISSUES.md)，再核对实际Git与测试。首次接管/范围疑问完整读[v2](../CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md)。

| 文档 | 唯一职责 |
|---|---|
| STATUS | 当前安全分支、最近观察HEAD、当前批次、证据、下一动作 |
| 每阶段 PLAN / LOG | 唯一任务表及退出条件 / 实際交付、决定、失败和恢复记录 |
| ISSUES | 稳定问题ID、级别、证据和关闭条件 |
| [QUALITY_GATES](QUALITY_GATES.md) | 共同工程/运行/体验门和证据标准 |
| [RELEASE_READINESS](RELEASE_READINESS.md) | RC1逐项证据索引，历史Stage通过不等于RC通过 |
| [GAME_DESIGN](design/GAME_DESIGN.md) | 产品和共享玩法设计 |
| [TECHNICAL_DESIGN](design/TECHNICAL_DESIGN.md) | 架构、数据与消费者边界 |
| [ART_BIBLE](design/ART_BIBLE.md) | 统一视觉/动画/实际尺寸标准 |
| [CONTENT_CATALOG](design/CONTENT_CATALOG.csv) | 内容规划/接入状态，不是任务backlog |
| [ASSET_PIPELINE](production/ASSET_PIPELINE.md) | 生产方法、模板；实际prompt留资产审计目录 |
| [RIGHTS_AND_AI_POLICY](production/RIGHTS_AND_AI_POLICY.md) | 原创、参考与发布权利规则 |
| [DEPENDENCIES](production/DEPENDENCIES.md) | 固定版本、许可证和工具供应链 |
| [ASSET_MANIFEST](production/ASSET_MANIFEST.csv) | 唯一顶层资产用途/来源清单，路径按仓库根解析 |

## 阶段目录

- Stage 0：[工程基线](stages/stage-00/PLAN.md) · [日志](stages/stage-00/LOG.md)
- Stage 0.5：[治理、CI 与恢复](stages/stage-00-5/PLAN.md) · [日志](stages/stage-00-5/LOG.md)
- Stage 1：[玩家、交互与场景](stages/stage-01/PLAN.md) · [日志](stages/stage-01/LOG.md)
- Stage 2：[数据、库存、设置、双语与可靠存档](stages/stage-02/PLAN.md) · [日志](stages/stage-02/LOG.md)
- Stage 3：[高品质美术基线与正式入口集成](stages/stage-03/PLAN.md) · [日志](stages/stage-03/LOG.md)
- Stage 4：[大型世界、分块与程序化外围](stages/stage-04/PLAN.md) · [日志](stages/stage-04/LOG.md)
- Stage 5：[地形、水生态与建设](stages/stage-05/PLAN.md) · [日志](stages/stage-05/LOG.md)
- Stage 6：[农业、制作、烹饪、经济与住宅](stages/stage-06/PLAN.md) · [日志](stages/stage-06/LOG.md)
- Stage 7：[钓鱼、水域活动、拍照与收藏](stages/stage-07/PLAN.md) · [日志](stages/stage-07/LOG.md)
- Stage 8：[NPC、关系、日程、任务与社区](stages/stage-08/PLAN.md) · [日志](stages/stage-08/LOG.md)
- Stage 9：[八个正式地区与远野内容](stages/stage-09/PLAN.md) · [日志](stages/stage-09/LOG.md)
- Stage 10：[视听、动画、UI 与叙事整体精修](stages/stage-10/PLAN.md) · [日志](stages/stage-10/LOG.md)
- Stage 11：[平衡、性能、可靠性、无障碍与本地化](stages/stage-11/PLAN.md) · [日志](stages/stage-11/LOG.md)
- Stage 12：[Windows RC1 与 Steam 准备](stages/stage-12/PLAN.md) · [日志](stages/stage-12/LOG.md)

机器日志、截图、视频和构建保留在被忽略的build，LOG记录run/source SHA和可取性。任务汇总仅可从各PLAN派生至build，禁止第二份手写backlog。一次性接管附件为用户文件保留原样，不是每次恢复必读的永久master prompt。[迁移映射](stages/stage-00-5/MIGRATION_MAP.csv)只记录本次迁移，不是长期目录数据库。
