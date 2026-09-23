# Stage 0.5 — 治理、CI 与恢复

- stage_id: "0.5"
- status: in_progress
- 目标依据: [v2 契约](../../../CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md) §13 Stage 0.5，相关 §7–12 与 §14
- 前置门: [Stage 0 退出门](../stage-00/PLAN.md#退出质量门)；跨阶段具体能力依任务表。
- 历史依据: [开发日志](LOG.md#historical-records)

## 目标与本阶段边界

交付本次接管要求的安全续开发线、docs 重整、每阶段 PLAN/LOG、唯一任务真源、有效依赖检查、结构化日志和可靠 CI。

新增迁移/修复任务挂在本阶段，不抹掉上一轮治理的历史完成。旧本地 commit、公开快照、当前分支各自标注作用域。

退出证据：新会话仅凭 AGENTS、短 STATUS、当前 PLAN 和最近 LOG，能确定安全分支、下一任务、最近有效检查与阻塞；文档检查正反例、统一检查和相应 CI 通过。不再继续建设复杂“项目管理平台”。

## 当前能力与差距

历史治理本地通过；新接管安全线已经建立，SVG检出失败、过期文档/检查器与exact SHA远程CI仍在修复。

## 任务

| ID | 交付任务 | 优先级 | 依赖 ID | 验收与证据要求 | 状态 | 证据 |
|---|---|---|---|---|---|---|
| AUT-0050 | 纳入长期目标契约并更新 AGENTS 优先级 | P0 | CAP-0006 | 恢复会话先读契约且冲突规则明确 | done | historical_report: [历史日志](LOG.md#historical-records) |
| AUT-0051 | 创建 PLANS 和自治状态恢复点 | P0 | AUT-0050 | 仅读仓库即可确认 Stage、证据、问题和下一任务 | done | historical_report: [历史日志](LOG.md#historical-records) |
| AUT-0052 | 创建质量门、已知问题和发布准备文档 | P0 | AUT-0050 | Stage 与 RC 证据状态可审计 | done | historical_report: [历史日志](LOG.md#historical-records) |
| AUT-0053 | 统一检查日志、JSON 结果和治理自检 | P0 | AUT-0051 | 单一脚本覆盖治理、导入、测试、烟雾和 diff | done | historical_report: [历史日志](LOG.md#historical-records) |
| AUT-0054 | 建立固定 Godot 4.7.2 Windows CI | P1 | AUT-0053 | CI 使用锁定官方 actions 并上传检查日志 | done | historical_report: [历史日志](LOG.md#historical-records) |
| AUT-0055 | 建立安全备份、回退和远程失效流程 | P0 | AUT-0051 | 可从 commit/tag 恢复且不依赖 hard reset | done | historical_report: [历史日志](LOG.md#historical-records) |
| AUT-0056 | 完成独立治理审查和 QA 审查 | P0 | AUT-0052,AUT-0053,AUT-0054,AUT-0055 | High 以上问题为 0 | done | historical_report: [历史日志](LOG.md#historical-records) |
| AUT-0057 | 建立 Stage 0.5 恢复点并安全同步 | P0 | AUT-0056 | 原子 commit；远程不可确认时记录待同步 | done | historical_report: [历史日志](LOG.md#historical-records) |
| AUT-0058 | 建立并审计安全续开发线 | P0 | AUT-0057 | 保留工作树/暂存区/未跟踪hash；review祖先正确且无旧开发祖先混入；显式ref安全推送 | done | [接管验证](LOG.md#takeover-validation) |
| AUT-0059 | 修复 SVG 检出字节与诊断 R-CI-01 | P0 | AUT-0058 | Windows新检出与autocrlf正反例、篡改/隔离负例；exact SHA完整CI成功 | done | [干净CI确认](LOG.md) |
| AUT-0060 | 迁移唯一任务真源与14阶段计划日志 | P0 | AUT-0058 | 原70任务、全部开放问题与v2范围有归属；删除重复入口；有效引用和正负治理fixture通过 | done | [接管验证](LOG.md#takeover-validation) |
| AUT-0061 | 恢复门整合与 CI 证据审阅 | P0 | AUT-0059,AUT-0060,AUT-0062 | 统一本地门、stage审阅包和exact SHA远程check runs有结果；未通过不得通过本轮治理门 | todo | - |
| AUT-0062 | 修复干净 CI 的 Godot 导入顺序 R-CI-02 | P0 | AUT-0059 | 所有Godot脚本在版本验证/导入后执行；无全局类缓存时SVG渲染/全部断言/导出可运行；exact SHA完整CI成功 | done | [干净CI确认](LOG.md) |
| AUT-0063 | 修正绝对路径检查对候选工具正则的误判 | P0 | AUT-0060,AUT-0062 | 字面量正则不误报，真实盘符与UNC路径仍被负例拒绝；治理门、全套Windows门及新HEAD CI有效 | done | [本地失败、修复与exact CI](LOG.md) |

## 退出质量门

交付：

- 将本契约纳入仓库规则。
- `PLANS.md`、自治状态、质量门、已知问题、发布准备文档。
- 统一检查入口、日志和测试结果输出。
- 安全 Git 分支/commit/push 流程。
- 如果远程和权限允许，建立 CI：解析、测试、lint/格式、构建烟雾测试。
- 建立自动备份/回退说明。

退出标准：中断会话后，新的 Codex 会话仅阅读仓库即可准确恢复下一任务。

共同门见 [QUALITY_GATES](../../QUALITY_GATES.md)。本阶段任务与上述场景、运行、体验验收全部有适用证据才可晋级；历史报告不代表当前 HEAD 通过。

## 风险与关联问题

关联 [ISSUES](../../ISSUES.md)：GIT-001、GIT-002 / R-GIT-01、R-CI-01/02、R-DOC-01。局部设备/工具/授权缺口只阻止对应验收，继续其他独立任务。

## 下一批执行顺序

修复R-CI-01 → 文档/检查器同批迁移 → 本地门/exact SHA CI → 继续Stage2回归。
