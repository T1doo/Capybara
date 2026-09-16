# PLAYER_CAPYBARA_V1 透明技术轮与 2D cutout 记录

日期：2026-09-03
状态：`technical_exploration`
活动透明候选：`0`

本轮只使用原创文字与一般水豚解剖事实，U2B 额外使用已核验的 `REF-CAPYBARA-ANATOMY-CC0-001`。没有使用旧隔离图、用户临时照片或任何第三方角色/风格图。

## ImageGen 尝试

| ID | 技术结果 | 视觉结果 | 决定 |
|---|---|---|---|
| U2 | 1536×1024 真 RGBA，角落 Alpha 0；有半透明棕/青光晕 | 腿过长、身体离地、眼睛偏宠物化 | rejected raw |
| AA2 | 1536×1024 真 RGBA，角落 Alpha 0；有光晕 | 极短脚与小眼方向可用，但身体过高圆、头身分离生硬 | rejected raw |
| AA2 halo edit | ImageGen 去光晕后退化为烘焙棋盘 RGB | 角色基本保持，但技术门失败 | rejected raw |
| V2 | 真 RGBA；有光晕 | 腿长、眼大、耳朵偏鼠类 | rejected raw |
| U2B | 贴地体态、短脚和口鼻成立；输出烘焙棋盘 | 过于自然史插画，不够卡通 | rejected raw |
| AA2B | 真 RGBA；有光晕 | 比 AA2 更低，但仍偏圆、围巾头带化 | rejected raw |

原图保存在 Git 忽略目录 `art/generated_raw/character/player_capybara_v1_clean_technical_round_01/`，不计入活动候选，也不得进入 approved/game。Git-visible 的 `REJECTED_TECHNICAL_MANIFEST.csv` 与 `REJECTED_TECHNICAL_PROMPTS.md` 逐图固定路径、完整提示词、时间、格式、参考、拒绝状态和 SHA-256；素材门禁止这些 hash 进入活动候选或原型。

结论：ImageGen 可以生成真 Alpha，但在“透明技术资产”约束下会反复产生光晕、长腿、宠物眼或头带式围巾。连续失败后停止盲抽，转向参数可控的原创 2D cutout 技术样板。

## CUTOUT-PROTO-V001

2D cutout 原型 v001。

源文件：`vector_prototypes/chr_player_cutout_down_right_v001.svg`
逐文件登记：`PROTOTYPE_MANIFEST.csv`

分层组：

- `body`
- `head`
- `ears`
- `rear-feet`
- `front-feet`
- `face`
- `muzzle`
- `scarf`
- `bag-strap`
- `satchel`

实际渲染命令：

```powershell
pwsh -NoProfile -File .\tools\render_svg_preview.ps1
```

结果：Godot 4.7.2 headless 解析并输出 1024×768 RGBA PNG，退出码 0。Alpha 内容边界为 `(125,203)–(933,639)`，角色本体 808×436。

渲染包装器会捕获 Godot stdout/stderr，任何行首 `ERROR` / `SCRIPT ERROR` / `WARNING` 都以退出码 20 失败；失败输出只写 staging 并清理，不覆盖最后通过的 PNG。沙箱诊断路径实测退出 20、最终 hash 保持不变，正常环境实测退出 0。

四底与 144 px 检查：

```powershell
pwsh -NoProfile -File .\tools\make_alpha_review_sheet.ps1 `
  -InputPath .\build\art-pipeline\chr_player_cutout_down_right_v001.png `
  -OutputDirectory .\build\art-pipeline\cutout-review `
  -Label 'Cutout V1' `
  -ManifestPath .\build\art-pipeline\vector_preview_manifest.csv `
  -Force
```

实际结果：退出码 0；白、黑、草绿、湖蓝四底无明显彩边，角色本体高 144 px 时身体、眼睛、耳朵、短脚、围巾和睡莲包均可辨。

当前优点：

- 长低体态和极短脚由参数固定，不会漂移成狗。
- 真透明、无烘焙阴影、无光晕。
- 各部件可独立调整，适合 cutout、四方向和换装。
- 小豆眼、宽钝口鼻、低位围巾和叶包在 144 px 可读。

当前不足：

- 仍是技术样板，水粉材质与边缘层次不足以作为正式美术。
- 身体后段偏大，头身交界和俯角还需优化。
- 围巾结仍略靠下巴，睡莲包侧厚度不足。
- 尚未有 idle/walk 绑定或 Godot 实景比例截图。

决定：保留为 `vector_technical_prototype`，不计入 transparent candidate，不锁定 `PLAYER_MASTER_V1`，不进入 `art/approved` 或 `game/assets`。
