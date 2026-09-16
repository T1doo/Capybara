# PLAYER_CAPYBARA_V1 首轮拒绝记录

日期：2026-09-03
状态：`rejected`

## A — rejected

- 优点：围巾与睡莲叶包清楚，透明背景基本成立。
- 拒绝原因：整体偏写实宠物肖像；四肢明显过长，身体离地过高；左耳被画成下垂犬耳；大眼与高眉弓削弱水豚特征；不符合绘本游戏剪影。
- 文件：`art/generated_raw/character/player_capybara_v1/chr_player_concept_a_raw_v001.png`。

## B — rejected

- 优点：水粉笔触比 A 更明显，围巾和编织包有材质差异。
- 拒绝原因：腿更长、足部更像犬科；口鼻收窄；两耳形成犬类轮廓；生成了非透明光晕背景；三项硬约束同时失败。
- 文件：`art/generated_raw/character/player_capybara_v1/chr_player_concept_b_raw_v001.png`。

## A2 — rejected

- 优点：身体已经降到更接近水豚的低矮桶状轮廓，腿和耳朵不再明显犬科化。
- 拒绝原因：整体仍接近写实动物插画，角色过大、质感偏真实，背景带有不透明棕色光晕，不符合“可爱卡通、透明游戏角色”的目标。
- 文件：`art/generated_raw/character/player_capybara_v1/chr_player_concept_a2_raw_v001.png`。

## Cute C1 — candidate

- 优点：真实水豚的短腿、低腹线、小圆耳、宽钝口鼻均成立；湖水青围巾和睡莲叶包有清楚身份点；整体已经明显卡通化且不再像狗。
- 技术修正：首张输出把棋盘格烘焙进 RGB 背景；随后通过定向背景移除得到真实 RGBA，验证结果为角落 Alpha `0`、角色中心 Alpha `253`。
- 晋级决定：透明修正版进入候选目录，等待 144 px 预览、四方向一致性和独立视觉审核；不得直接进入 `art/approved` 或 `game/assets`。
- 候选文件：`art/candidates/player_capybara_v1/chr_player_concept_c1_v001.png`。
- 原始文件：`art/generated_raw/character/player_capybara_v1/chr_player_concept_cute_c1_raw_v001.png` 与 `chr_player_concept_cute_c1_alpha_raw_v001.png`。

## Cute C2 — rejected

- 优点：短腿、小耳、宽口鼻继续成立，卡通感进一步增强。
- 拒绝原因：头部与眼睛偏大，身体被压缩，开始靠通用萌宠比例制造可爱；棋盘格被烘焙进 24-bit RGB 背景。
- 文件：`art/generated_raw/character/player_capybara_v1/chr_player_concept_cute_c2_raw_v001.png`。

## Cute C3 — rejected

- 优点：体态接近 C1，笔触更简化，轮廓可读性良好。
- 拒绝原因：眼部仍略偏宠物化；原图与定向去背景尝试都保持为 24-bit RGB，棋盘格未被真正移除，因此技术门禁失败。
- 文件：`art/generated_raw/character/player_capybara_v1/chr_player_concept_cute_c3_raw_v001.png` 与 `chr_player_concept_cute_c3_alpha_attempt_raw_v001.png`。

## D1 — candidate

- 优点：在已登记 CC0 实拍解剖和内部原创 C1 方向基础上生成；长低身体、短腿、小耳和宽钝口鼻成立，轻微笑意使卡通感更强；配饰结构与 C1 有清楚差异。
- 技术修正：定向去背后验证为 1448×1086 `Format32bppArgb`，角落 Alpha `0`、角色中心 Alpha `253`。
- 晋级决定：进入候选目录并通过 144 px 初筛；尚未进入 approved 或游戏资产。
- 候选文件：`art/candidates/player_capybara_v1/chr_player_concept_d1_v001.png`。

## E1 / F1 / H1 / J1 — visual pass, technical reject

- 视觉优点：分别提供温柔圆润、灰棕困倦、小豆眼极简和贴纸式微笑方向；水豚短腿、小圆耳、宽钝口鼻基本成立。
- 拒绝原因：原始输出均将棋盘格烘焙进 RGB；ImageGen 定向去背仍产生不透明棋盘或光晕，未通过真实 Alpha 门禁。
- 处理：只保留在 `art/generated_raw` 作为视觉与失败证据，不复制到候选目录，不计入 6–12 个有效候选数量。

## G1 / I1 — visual reject

- G1：重新出现偏大的宠物式亮眼，削弱安静水豚神态。
- I1：出现大眼、深色背景光晕和偏动态插画构图，不符合透明游戏角色与小尺寸剪影目标。
- 处理：只保留原始输出，不再做去背或晋级。

## 根因与下一轮修正

- “修长”“前倾”和“折耳”措辞被模型放大，造成犬科结构。
- 下一轮使用水豚解剖优先级：水平桶状身体、腹线低、极短粗腿、宽钝矩形口鼻、小圆耳。
- 左耳身份点改为耳缘轻微折痕或小缺口，禁止任何下垂耳瓣。
- 候选差异主要来自围巾打结、包结构、毛色块与姿态节奏，不再通过拉长腿或尖化头部制造差异。
- A/B 仅作失败证据，不作为后续生成参考，不进入联系表晋级候选。
- 可爱感应主要来自真实水豚特征：低矮桶状身体、短粗腿、小圆耳、宽钝口鼻和安静神态；不得用犬科大眼、长腿或夸张婴儿头身比替代。
- 后续正式生成只使用已登记的 CC0 实拍图观察解剖，并以 C1 的原创配饰语言继续探索。
- 当前有效候选数为 2（C1、D1）；仍需至少 4 张真实透明且有实质造型差异的候选，才能制作正式联系表。
