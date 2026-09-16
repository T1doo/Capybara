# Release Candidate 准备度

本文件跟踪 `capybara-rc1` 的证据状态。除非全部项目为 `Passed`，或明确标记为目标契约允许的用户侧 Steam 后台事项，否则不得宣告 RC1 完成。

状态：`Not Started` / `In Progress` / `Blocked — User Action` / `Passed`

## 当前概览

- 当前 Stage：3（环境与角色视觉原型，尚未通过美术质量门）。
- 当前结论：`Not Ready`。
- 最近稳定版本：`capybara-stage-02`。
- 当前构建：开发期 Godot 灰盒；Windows debug 导出与启动烟雾通过，尚无 Release 导出。

## 功能与内容

| 要求 | 状态 | 证据 |
|---|---|---|
| 新游戏到主要结局完整可玩 | Not Started | — |
| 8 个主要地区可访问 | Not Started | — |
| 确定性程序化外围可探索 | Not Started | — |
| 建设、水生态、农业、制作、钓鱼、探索、NPC、任务连通 | Not Started | — |
| 正式流程无需开发者控制台 | Not Started | — |

## 画面与音频

| 要求 | 状态 | 证据 |
|---|---|---|
| 高分辨率、非像素、统一绘本 2D/2.5D | Not Started | Stage 3 建立正式视觉基线 |
| 正式流程无灰盒/默认 UI/AI 瑕疵 | Not Started | — |
| 主要地区独立地标、色彩、天气和音频身份 | Not Started | — |
| 主角与主要 NPC 动画一致 | Not Started | — |
| 完整基础音乐、环境音、关键反馈与音量设置 | Not Started | — |

## 操作与无障碍

| 要求 | 状态 | 证据 |
|---|---|---|
| 键鼠独立完成完整流程 | In Progress | Stage 1 移动、交互、区域往返、暂停与 UI 已验证；完整游戏流程尚未存在 |
| 手柄独立完成完整流程 | Not Started | `QA-001` |
| 输入重映射与关键辅助选项 | In Progress | 9 动作双设备重映射、动态提示、减少动态、高对比和震动消费者已通过；完整 RC 流程仍待后续 Stage |
| 1280×720 / 1920×1080 / 2560×1440 / 1280×800 | In Progress | Stage 2 的 4×3×5 modal/焦点矩阵通过；真实 UI 完成 720p→全屏→720p→1280×800；正式全内容仍待 Stage 11 |

## 稳定性与数据

| 要求 | 状态 | 证据 |
|---|---|---|
| 全部自动测试通过 | In Progress | Stage 2 exact clean `c7f91fe`：616/616；run `20260903T041100794Z-p23616-cf38b6eb`；后续 Stage 继续扩展 |
| 2 小时 soak 无崩溃/显著内存增长 | Not Started | — |
| 存档、备份、损坏恢复、迁移 | In Progress | Save v1 文件事务、v0→v1、正式入口、main→backup、跨区域与拾取/资源世界差量三进程重开通过；chunk 差量后续扩展 |
| chunk 重载与玩家差量一致 | Not Started | — |
| 无 Blocker/Critical | Passed | Stage 2 `c7f91fe` 最终独立代码/QA 审查均为 Blocker 0、Critical 0、High 0 |

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
| 正式资产来源/AI/修改/权利登记完整 | In Progress | 旧未核验参考链已隔离；`player_capybara_v1` 六张 clean visual concept 已逐文件登记 prompt/reference/hash/review；尚无 approved/game-ready 资产 |
| 无未授权 IP、商标、音乐、字体或角色参考 | In Progress | 永久政策已建立；正式资产尚未生产 |
| 第三方依赖许可证和固定版本 | In Progress | 当前零插件；CI 使用 GitHub 官方 actions 与 Godot 官方构建 |
| Steam AI 内容说明与实际一致 | Not Started | — |

## Git 与交付

| 要求 | 状态 | 证据 |
|---|---|---|
| RC 工作树 clean | Not Started | — |
| RC 代码和批准资产已 commit | Not Started | — |
| main 与 release tag 安全同步 | Not Started | `GIT-001` 当前阻止远程确认 |
| `capybara-rc1` 注释标签 | Not Started | — |

## 必须由用户本人完成的 Steam 后台事项

| 事项 | 状态 |
|---|---|
| Steamworks 登录、双重验证与协议签署 | Blocked — User Action |
| Steam Direct 费用 | Blocked — User Action |
| 身份、税务和银行信息 | Blocked — User Action |
| 最终公开商店提交与发布时间确认 | Blocked — User Action |

这些用户侧事项不阻止本地技术、美术、内容和构建准备持续进行。
