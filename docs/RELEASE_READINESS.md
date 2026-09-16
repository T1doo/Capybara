# Release Candidate 准备度

本文件跟踪 `capybara-rc1` 的证据状态。除非全部项目为 `Passed`，或明确标记为目标契约允许的用户侧 Steam 后台事项，否则不得宣告 RC1 完成。

状态：`Not Started` / `In Progress` / `Blocked — User Action` / `Passed`

## 当前概览

- 当前 Stage：3（环境与角色视觉原型，尚未通过美术质量门）。
- 当前结论：`Not Ready`。
- 历史本地Stage2稳定标签：`capybara-stage-02`，仅本地旧历史审计，不作为公开RC版本。
- 当前构建：开发期灰盒与独立视觉原型；接管初轮在资产步骤失败，修复dirty工作树本地18/18、754/754及Debug短启动通过；02ac远程CI又因导入顺序失败，尚无Release。详见[Stage0.5日志](stages/stage-00-5/LOG.md)。

## 功能与内容

| 要求 | 状态 | 证据 |
|---|---|---|
| 新游戏到主要结局完整可玩 | Not Started | — |
| 8 个主要地区可访问 | Not Started | — |
| 确定性程序化外围可探索 | Not Started | — |
| 建设、水生态、农业、制作、钓鱼、探索、NPC、任务连通 | Not Started | — |
| 正式流程无需开发者控制台 | Not Started | — |
| 达到内容目标下限或有同等深度替代理由 | Not Started | [Stage9计划](stages/stage-09/PLAN.md)，制作/接入/实玩逐项核验 |

## 画面与音频

| 要求 | 状态 | 证据 |
|---|---|---|
| 高分辨率、非像素、统一绘本 2D/2.5D | Not Started | Stage 3 建立正式视觉基线 |
| 正式流程无灰盒/默认 UI/AI 瑕疵 | Not Started | — |
| 主要地区独立地标、色彩、天气和音频身份 | Not Started | — |
| 主角与主要 NPC 动画一致 | Not Started | — |
| 水体、植被、粒子、灯光与遮挡展示质量 | In Progress | [Stage3原型历史](stages/stage-03/LOG.md#historical-records)，正式四氛围和全场景未通过 |
| 完整基础音乐、环境音、关键反馈与音量设置 | Not Started | — |

## 操作与无障碍

| 要求 | 状态 | 证据 |
|---|---|---|
| 键鼠独立完成完整流程 | In Progress | Stage 1 移动、交互、区域往返、暂停与 UI 已验证；完整游戏流程尚未存在 |
| 手柄独立完成完整流程 | Not Started | `QA-001` |
| 输入重映射与关键辅助选项 | In Progress | [历史Stage2](stages/stage-02/LOG.md#historical-records)的9动作双设备重映射、动态提示、减少动态、高对比和震动消费者通过；完整 RC 流程仍待后续 Stage |
| 1280×720 / 1920×1080 / 2560×1440 / 1280×800 | In Progress | [历史Stage2](stages/stage-02/LOG.md#historical-records)的4×3×5 modal/焦点矩阵通过；真实 UI 完成 720p→全屏→720p→1280×800；正式全内容仍待 Stage 11 |

## 稳定性与数据

| 要求 | 状态 | 证据 |
|---|---|---|
| 全部自动测试通过 | In Progress | [历史Stage2](stages/stage-02/LOG.md#historical-records)616/616；[历史Stage3](stages/stage-03/LOG.md#historical-records)752/752。接管初轮资产exit22；后续dirty本地754/754但02ac远程CI失败，见[本轮记录](stages/stage-00-5/LOG.md)，不构成RC全测 |
| 2 小时 soak 无崩溃/显著内存增长 | Not Started | — |
| 存档、备份、损坏恢复、迁移 | In Progress | 历史Save v1/迁移/首次backup回退与世界差量重开有记录；R-SAVE-01组合序列、ST2-017和chunk差量仍需验证 |
| chunk 重载与玩家差量一致 | Not Started | — |
| diff、内容、缺失资源与本地化key检查 | In Progress | 当前文档/代码批次待统一验证；历史局部通过不替代RC |
| 无 Blocker/Critical | In Progress | [历史Stage2审查](stages/stage-02/LOG.md#historical-records)当时0/0/0；当前审阅回归与RC全内容仍未完成，见[ISSUES](ISSUES.md) |

## 性能与构建

| 要求 | 状态 | 证据 |
|---|---|---|
| 目标分辨率帧预算 | Not Started | — |
| 可复现 Windows Release 构建 | Not Started | — |
| 干净 Windows 环境启动 | Not Started | — |
| 构建无密钥、缓存、SDK 私密文件 | Not Started | — |
| manifest 与 checksum | Not Started | — |

## 法律与资产

| 要求 | 状态 | 证据 |
|---|---|---|
| 正式资产来源/AI/修改/权利登记完整 | In Progress | 旧未核验参考链已隔离；`player_capybara_v1` 七张 clean visual concept 已逐文件登记 prompt/reference/hash/review；已有批准为原型用途的材质集成；主角生产母图与正式全场景仍未批准 |
| 无未授权 IP、商标、音乐、字体或角色参考 | In Progress | 永久政策已建立；逐文件清洁链和原型用途已登记；完整RC资产权利门未通过 |
| 第三方依赖许可证和固定版本 | In Progress | 当前零插件；CI 使用 GitHub 官方 actions 与 Godot 官方构建 |
| Steam AI 内容说明与实际一致 | Not Started | — |

## Git 与交付

| 要求 | 状态 | 证据 |
|---|---|---|
| RC 工作树 clean | Not Started | — |
| RC 代码和批准资产已 commit | Not Started | — |
| main 与 release tag 安全同步 | Not Started | 远程public/ADMIN已核验；GIT-002旧历史禁推，安全生产线后续显式同步及RC尚未执行 |
| `capybara-rc1` 注释标签 | Not Started | — |
| RC1 ZIP、checksum、发布说明与已知问题 | Not Started | [Stage12计划](stages/stage-12/PLAN.md) |

## 必须由用户本人完成的 Steam 后台事项

| 事项 | 状态 |
|---|---|
| Steamworks 登录、双重验证与协议签署 | Blocked — User Action |
| Steam Direct 费用 | Blocked — User Action |
| 身份、税务和银行信息 | Blocked — User Action |
| 最终公开商店提交与发布时间确认 | Blocked — User Action |

这些用户侧事项不阻止本地技术、美术、内容和构建准备持续进行。
