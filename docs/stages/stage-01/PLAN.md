# Stage 1 — 玩家、交互与场景

- stage_id: "1"
- status: historical_passed
- 目标依据: [v2 契约](../../../CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md) §13 Stage 1，相关 §7–12 与 §14
- 前置门: [Stage 0.5 退出门](../stage-00-5/PLAN.md#退出质量门)；跨阶段具体能力依任务表。
- 历史依据: [开发日志](LOG.md#historical-records)
- evidence: historical_report: [历史日志](LOG.md#historical-records)

## 目标与本阶段边界

保留状态机、八方向面向、统一交互上下文/结果、候选选择、拾取/资源/床/箱子/门、设备提示、出生点/转场、单玩家和调试覆盖层。

后续新美术替换和场景整合不得重写交互底座，也不得产生两套玩家控制。补测试时重点覆盖真实输入链、候选生命周期、暂停穿透、连续转场和关闭/恢复 UI。

退出门仍是原契约的 20 分钟稳定灰盒操作与相关回归；八方向数据不等于八方向美术。历史记录可复用作过去证据，当前受影响部分须重跑。

## 当前能力与差距

历史玩家/交互/两区域/20分钟soak通过；合成手柄并非实体硬件。正式美术替换沿用现有玩家和交互。

## 任务

| ID | 交付任务 | 优先级 | 依赖 ID | 验收与证据要求 | 状态 | 证据 |
|---|---|---|---|---|---|---|
| CAP-0101 | 玩家状态机 | P0 | CAP-0004 | Idle/Move/Interact/Disabled 互斥且 8 方向 facing 可测试 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0102 | 通用交互接口 | P0 | CAP-0101 | 可拾取物、资源点和 NPC 使用统一协议 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0103 | 键盘/手柄提示切换 | P1 | CAP-0005 | 最后输入设备变化时提示正确 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0104 | 区域切换与玩家出生点 | P0 | CAP-0101 | 往返区域位置与状态正确 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0105 | 调试覆盖层 | P1 | CAP-0104 | 可切换查看区域/状态/目标/设备与运行时数量 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0106 | Stage 1 灰盒 soak | P0 | CAP-0103,CAP-0104,CAP-0105 | 连续 20 分钟无重复玩家/误选/暂停穿透/转场丢失 | done | historical_report: [历史日志](LOG.md#historical-records) |
| ST1-R001 | 修复接管后soak初始化并重新验证真实输入链 | P0 | CAP-0106,ST2-R003 | 回归新请求/提交路径；资源探针正确初始化，实际1200秒持续流程及非零覆盖计数通过，保留启动失败证据 | done | [1200秒长测](LOG.md) |

## 退出质量门

交付：

- 玩家状态机。
- 8 方向移动数据和面向。
- 通用 Interactable 协议。
- 稳定交互目标排序。
- 拾取物、资源点、床、箱子、门的灰盒版本。
- 输入设备自动识别和提示。
- 场景切换、出生点和调试覆盖层。
- 单元/集成测试。

退出标准：连续灰盒游玩 20 分钟，无重复玩家、目标误选、暂停穿透或转场状态丢失。

共同门见 [QUALITY_GATES](../../QUALITY_GATES.md)。本阶段任务与上述场景、运行、体验验收全部有适用证据才可晋级；历史报告不代表当前 HEAD 通过。

## 风险与关联问题

关联 [ISSUES](../../ISSUES.md)：QA-001、R-INTERACT-01。局部设备/工具/授权缺口只阻止对应验收，继续其他独立任务。

## 下一批执行顺序

由Stage2交互最终提交回归验证受影响输入链；随后随Stage3入口复核。
