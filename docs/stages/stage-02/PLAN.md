# Stage 2 — 数据、库存、设置、双语与可靠存档

- stage_id: "2"
- status: historical_passed
- 目标依据: [v2 契约](../../../CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md) §13 Stage 2，相关 §7–12 与 §14
- 前置门: [Stage 1 退出门](../stage-01/PLAN.md#退出质量门)；跨阶段具体能力依任务表。
- 历史依据: [开发日志](LOG.md#historical-records)
- evidence: historical_report: [历史日志](LOG.md#historical-records)

## 目标与本阶段边界

完整保留注册表和稳定 ID、24 格背包、堆叠/拆分/整理/丢弃、快捷栏、箱子、工具装备、设置/输入重映射、无障碍基础、zh_CN/en、存档版本/恢复/迁移。

近期任务纳入 R-SAVE-01、R-HOTBAR-01、R-INTERACT-01、ST2-017 与加载失败注入；依归属引用 Stage 1/3 的联动测试，不复制问题状态。

退出证据：物品守恒、操作序列、装备语义、跨区域及跨进程存档、恢复后保存、损坏/中断/迁移有效；设置消费者真实存在，未实现的控件不提前展示成可用功能。旧合法存档不因去掉 placeholder 名字而无声失效。

## 当前能力与差距

历史数据/库存/设置/双语/Save v1通过；本次审阅提出备份轮换、快捷栏语义、交互提交及安全落点回归，未验证前保持开放。

## 任务

| ID | 交付任务 | 优先级 | 依赖 ID | 验收与证据要求 | 状态 | 证据 |
|---|---|---|---|---|---|---|
| CAP-0201 | ItemDefinition 与内容注册表 | P0 | CAP-0102 | 稳定 ID 可加载且重复/缺失会报错 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0202 | 背包与堆叠 | P0 | CAP-0201 | 容量、堆叠、溢出和任务物品规则通过测试 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0203 | 快捷栏与储物箱 | P1 | CAP-0202 | 键鼠手柄可操作，状态可保存 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0204 | SaveManager v1 | P0 | CAP-0202,CAP-0104 | 原子写入、备份、读取与错误提示通过 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0205 | zh_CN/en 本地化框架 | P1 | CAP-0005 | 玩家可见文字不写死，切换语言后 UI 正常 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0206 | 音量、窗口、UI 缩放与输入设置 | P1 | CAP-0005 | 重启后设置保留，1280x800 无出屏 | done | historical_report: [历史日志](LOG.md#historical-records) |
| ST2-R001 | 恢复后保存保护最后好备份 R-SAVE-01 | P0 | CAP-0204 | A→B→语义坏main→回退A→save→新main损坏→再恢复；跨进程和写入/轮换/rename失败注入通过；隔离失败→直接保存也不得污染备份 | done | [整合验收](LOG.md#reliability-integration) |
| ST2-R002 | 整理与转移保持快捷栏装备语义 R-HOTBAR-01 | P0 | CAP-0203 | 选中/未选中、整理、拆分合并、箱转移、空格、重复绑定、耗尽及旧档重开一致 | done | [整合验收](LOG.md#reliability-integration) |
| ST2-R003 | 交互反馈以真实提交结果决定 R-INTERACT-01 | P0 | CAP-0202,CAP-0102 | 全满和部分容量无成功事件/震动/计数；全量成功才扣资源；错误工具/取消/重复输入无复制 | done | [整合验收](LOG.md#reliability-integration) |
| ST2-R004 | 碰撞安全落点及加载整体事务 ST2-017 | P0 | CAP-0204,ST2-R001 | 越界/墙内/深水/桥层级/旧图确定性安全回退；失败注入验证inventory/player/world/zone/pending全部一致；Stage4再扩失效chunk | done | [整合验收](LOG.md#reliability-integration) |

## 退出质量门

交付：

- 内容注册表和稳定 ID。
- 背包、堆叠、快捷栏、储物箱、丢弃/拆分/排序。
- 工具装备和上下文操作。
- 设置、音量、显示、输入重映射、可访问性基础。
- zh_CN 与 en 本地化框架。
- Save v1、备份、损坏恢复、迁移测试。
- 自动化随机物品和存档回归。

退出标准：大量随机增减物品不丢失，保存/加载/损坏恢复通过，旧 schema 测试可迁移。

共同门见 [QUALITY_GATES](../../QUALITY_GATES.md)。本阶段任务与上述场景、运行、体验验收全部有适用证据才可晋级；历史报告不代表当前 HEAD 通过。

## 风险与关联问题

关联 [ISSUES](../../ISSUES.md)：R-SAVE-01、R-HOTBAR-01、R-INTERACT-01、ST2-017 / R-POS-01、ST2-016。局部设备/工具/授权缺口只阻止对应验收，继续其他独立任务。

## 下一批执行顺序

R-SAVE-01最小复现与跨进程 → 快捷栏/提交反馈 → 安全落点与完整加载失败注入。
