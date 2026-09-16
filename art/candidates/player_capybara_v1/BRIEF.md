# PLAYER_CAPYBARA_V1 清洁参考链概念 brief

状态：`visual_concept`
资产 ID：`player_capybara_v1`
提示词族：`CHAR-CLEAN-*`
用途：Stage 3 原创主角母图探索；当前任何图片都不得直接进入 `art/approved` 或 `game/assets`

## 固定身份特征

- 原创成年水豚，温和、敏锐、安静地热爱修复水道和建设家园。
- 暖灰棕毛色，真实水豚式长低桶状躯干，腹线接近地面；四条腿必须极短、粗壮且大部分藏在身体下方。
- 头部宽厚但小于躯干，口鼻宽、钝、近矩形；深色小椭圆眼睛侧置，表情克制。
- 两耳都必须小、圆、短；左耳最终允许非常轻微的耳缘小缺口，但概念阶段不得为追求缺口生成尖耳、毛簇或破损轮廓。
- 湖水青防水围巾必须位于肩颈并低于双耳；睡莲叶形小斜挎包必须有清楚包体、肩带和木扣。
- 3/4 俯视、弱透视、朝屏幕右下、左上柔光。
- 高分辨率、非像素、柔和手绘水粉绘本质感；清楚剪影、克制毛纹、无纯黑粗描边。

## 清洁参考边界

- 允许：`REF-CAPYBARA-ANATOMY-CC0-001`，仅用于物种解剖；或完全不使用图像参考的原创文字生成。
- 禁止：`USER-SESSION-CAPYBARA-ANATOMY-20260903`、`art/candidates/_quarantine/` 中的全部图像、旧 C1/D1/P1/Q1/R1/S1、任何未授权角色/IP/品牌/艺术家或来源不明图片。
- 不得通过重生成、描摹、裁切、去背、调色或重编码把隔离图像重新纳入清洁链。
- 实拍图不提供角色配饰、姿势、构图、风格、色板或场景设计。

## 首轮六个活动视觉概念

| ID | 参考 | 主要比较轴 | 当前状态 |
|---|---|---|---|
| U1 | CC0 解剖 | 最长最低的面包体、小豆眼、圆叶包 | `visual_concept` |
| V1 | CC0 解剖 | 配饰结构、自然灰棕、折叶包 | `visual_concept` |
| W1 | CC0 解剖 | 最简图形语言、克制小眼、方叶包 | `visual_concept` |
| Z1 | 文字-only | 柔和长低轮廓、睡莲缺口包 | `visual_concept` |
| AA1 | 文字-only | 极简豆眼、最大色块、几何包 | `visual_concept` |
| AD1 | 文字-only | 暖灰平衡、极短脚、圆叶包 | `visual_concept` |

逐图完整提示词、参考 ID、尺寸和 SHA-256 见：

- `CLEAN_LINEAGE_ROUND_01.md`
- `CANDIDATE_MANIFEST.csv`

## 两级候选状态

### 视觉概念 `visual_concept`

- 用于比较体型、脸部、眼睛、围巾、包、毛色块与姿态节奏。
- 可以使用统一奶油纸背景；允许 24-bit RGB；不声称是游戏资产或透明素材。
- 不制作“游戏实际 144 px”证据，因为背景画布不能证明角色本体高度。
- 只有独立审查通过的形状语言可以进入下一步受控重做。

### 透明技术候选 `technical_candidate`

- 必须从清洁参考边界重新生成或建立可编辑源，不得把隔离图作为输入。
- 必须为真实 RGBA、无背景、无烘焙地面阴影、无彩色 halo、无孤立毛刺。
- 必须统一视角、朝向、光向、角色本体高度和接地点。
- 必须生成角色本体 144 px 预览，以及白、黑、草绿、湖蓝四底透明边缘检查图。
- 通过独立视觉、技术和原创性审查后，才可能晋级 `approved_concept`。

## 输出与命名

- 原始输出：`art/generated_raw/character/player_capybara_v1_clean_round_01/`，默认忽略。
- 活动视觉概念：`art/candidates/player_capybara_v1/visual_concepts/chr_player_clean_concept_{id}_v001.png`。
- 逐图清单：`art/candidates/player_capybara_v1/CANDIDATE_MANIFEST.csv`。
- 清洁链联系表：`art/candidates/player_capybara_v1/clean_contact_sheet_v001.png` 及 `.mapping.json`。
- 后续透明候选：`art/candidates/player_capybara_v1/chr_player_clean_candidate_{id}_v001.png`。
- 隔离记录：`art/candidates/_quarantine/player_capybara_v1_unverified_reference/`。

## 禁止项

- 犬科长腿、明显高跗关节、尖长吻部、下垂/尖耳、宠物犬式大眼、眉弓或睫毛。
- 夸张婴儿头身比、头顶水果、红色短裤、额外肢体、重复五官、畸形爪。
- 文字、字母、数字、签名、水印、Logo 或可识别品牌。
- 把视觉概念、不透明背景图、未经修边的 Alpha、联系表或隔离图直接复制到 `art/approved` / `game/assets`。

## 晋级条件

1. 6–12 张视觉概念逐文件登记，参考链清洁，差异不是简单换色或镜像。
2. 独立审查明确选择可融合的形状语言，并记录拒绝原因。
3. 重新产出至少 3 张同朝向、同俯角、同光向的真实透明技术候选。
4. 技术候选全尺寸、裁切后 144 px 和四底透明边缘预览全部通过。
5. 独立复审无 Blocker/Critical/High 后，才允许锁定 `PLAYER_MASTER_V1`。

当前状态：清洁链视觉概念 6 张，透明技术候选 0 张，`PLAYER_MASTER_V1` 尚未锁定。第二轮独立视觉审查为 Blocker/Critical/High `0/0/0`，推荐 U1、AA1、V1 进入受控透明重做。
