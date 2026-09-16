# Stage 0 — 工程基线

- stage_id: "0"
- status: historical_passed
- 目标依据: [v2 契约](../../../CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md) §13 Stage 0，相关 §7–12 与 §14
- 前置门: 现有工程基线；不重新初始化。
- 历史依据: [开发日志](LOG.md#historical-records)
- evidence: historical_report: [历史日志](LOG.md#historical-records)

## 目标与本阶段边界

PLAN 中保留项目配置、Compatibility、移动归一化、碰撞、相机、暂停、工具退出码、忽略规则和最小测试任务的历史结果。LOG 迁入当时通过记录与来源。

当前只验证基础仍成立、资源导入和工具可运行，补真正回归。不要因为新窗口没有聊天记忆就重做 Stage 0 或重新初始化仓库。

退出证据：实际版本、导入、灰盒/主入口基础运行和回归结果；历史通过与当前验证分开。实体手柄缺项沿用 QA-001 的真实范围，不从合成事件推出硬件已测。

## 当前能力与差距

历史基础通过；接管本轮统一门在资产检查提前失败，导入/游戏回归尚未重跑，不能据历史17/17宣称当前全测。

## 任务

| ID | 交付任务 | 优先级 | 依赖 ID | 验收与证据要求 | 状态 | 证据 |
|---|---|---|---|---|---|---|
| CAP-0001 | 确认 Godot 4.7.2 可执行路径 | P0 | - | GODOT_BIN 可用于 headless 与 editor；失败时有明确说明 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0002 | 初始化 Git 与 .gitignore | P0 | CAP-0001 | 缓存、构建、密钥与 raw AI 输出不进入 Git | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0003 | 创建 Godot Compatibility 项目 | P0 | CAP-0001 | 项目可打开，无解析错误，主场景路径正确 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0004 | 创建灰盒四方向移动 | P0 | CAP-0003 | 斜向归一化，碰撞有效，最后朝向保存 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0005 | 创建暂停菜单 | P0 | CAP-0003 | 继续与退出有效，手柄可聚焦 | done | historical_report: [历史日志](LOG.md#historical-records) |
| CAP-0006 | 创建 headless 检查与测试入口 | P0 | CAP-0003 | PowerShell 返回正确退出码并实际运行 | done | historical_report: [历史日志](LOG.md#historical-records) |

## 退出质量门

Codex 不得仅相信已有文字报告，必须检查实际仓库。

完成标准：

- Godot 项目存在并可打开。
- 灰盒移动、碰撞、相机、暂停和最小测试通过。
- 工具脚本存在并返回正确退出码。
- Git 状态、忽略规则和 LFS 基线正确。
- 若 Stage 0 已完整完成，只做验证；若不完整，自主修复直到通过。

通过后创建或确认 Stage 0 commit/tag，然后立即进入 Stage 0.5。

共同门见 [QUALITY_GATES](../../QUALITY_GATES.md)。本阶段任务与上述场景、运行、体验验收全部有适用证据才可晋级；历史报告不代表当前 HEAD 通过。

## 风险与关联问题

关联 [ISSUES](../../ISSUES.md)：QA-001。局部设备/工具/授权缺口只阻止对应验收，继续其他独立任务。

## 下一批执行顺序

保持工程不重建；修复治理后重跑基础门。
