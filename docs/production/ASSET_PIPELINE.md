# 04 AI 素材生产流程

版本：2.0
日期：2026-08-30

> Stage 0 之后以 `CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md` 为最高优先级。Codex 与独立视觉审查代理按本文件证据链自主筛选、修整和批准常规资产；只有权利/相似性风险、付费、公开发布或用户明确保留的最终品牌选择属于升级事项。

## 1. 基本原则

AI 是概念探索和素材生产工具，不是自动美术总监。所有最终视觉资产必须经过选择、编辑、测试与证据化审查；记录实际执行者/审查角色，不虚构人工参与。

v1.0 的游戏运行期间不调用图像、文本或语音生成 API。所有 AI 输出都在开发期预先生成并作为普通文件打包。

## 2. 资产状态机

```text
BRIEF
  -> GENERATED_RAW
  -> VISUAL_CONCEPT
  -> TECHNICAL_CANDIDATE
  -> APPROVED_CONCEPT
  -> HUMAN_EDITED_SOURCE
  -> GAME_READY
  -> INTEGRATED
  -> RELEASE_APPROVED
```

目录映射：

```text
art/generated_raw/    原始输出，默认不提交 Git
art/candidates/       候选联系表和选择记录
art/approved/         已批准概念与母图
art/source_layers/    Krita、Blender 等可编辑源文件
game/assets/          处理完成并实际使用的资产
```

禁止跳过状态。

`VISUAL_CONCEPT` 可以使用统一中性背景来比较造型，不要求 Alpha，也不得被称为游戏尺寸证据。`TECHNICAL_CANDIDATE` 必须为真实透明、无烘焙阴影、视角/朝向/光向统一的候选，并完成角色本体尺寸和多底色边缘检查。二者必须在逐文件 manifest 中明确区分。

## 3. 每项素材的标准流程

### 3.1 创建资产 brief

写清楚：

- `asset_id`。
- 游戏用途。
- 游戏内尺寸。
- 视角和方向。
- 光照。
- 色板。
- 必须保持的特征。
- 禁止出现的内容。
- 是否需要透明背景。
- 是否需要方向或状态变体。
- 验收方法。

### 3.2 生成少量候选

- 角色概念：首轮 6–12 张。
- 普通道具：首轮 4 张。
- Tile 或 UI 图标：首轮 4–8 张。
- 不为“碰碰运气”一次生成数百张。
- 原始文件自动命名并保留元数据。

### 3.3 创建联系表

Codex 或工具脚本将候选缩略图放入带编号的联系表。常规候选由实现者和独立视觉审查代理依据 brief、风格母图、技术检查和游戏内截图记录选择理由；权利不确定、明显相似性风险或用户明确保留的最终品牌选择才提交项目负责人决定。

### 3.4 锁定母图

角色、建筑套系和 UI 组件需要批准的母图：

- `PLAYER_MASTER_V1`
- `NPC_OTTER_MASTER_V1`
- `HOUSE_SET_MASTER_V1`
- `UI_MASTER_V1`

后续变体优先使用编辑模式和母图作为参考，不重新从零生成。

### 3.5 人工编辑

至少检查和修正：

- 结构错误。
- 额外肢体。
- 不一致的服装细节。
- 透视和光向。
- 透明边缘。
- 色板。
- 尺寸和 pivot。
- 与其他素材的风格差异。

保留 `.kra`、`.blend` 或其他可编辑源文件。

### 3.6 技术处理

- 裁切透明边距。
- 检查 alpha。
- 按正确尺寸缩放。
- 导出 PNG/WebP；透明角色默认 PNG。
- 生成缩略图。
- 必要时拆分动画部件。
- 导入 Godot 并检查纹理过滤、mipmap 与压缩设置。

### 3.7 游戏内审核

必须在真实场景中检查：

- 与 64px 网格比例是否正确。
- 是否遮挡玩家。
- 颜色是否过亮或过暗。
- 交互状态是否清楚。
- 手柄焦点和 UI 图标是否易读。
- 动画时是否漂移。

### 3.8 登记

更新 `docs/production/ASSET_MANIFEST.csv`，记录：

- 生成工具或模型。
- 提示词 ID。
- 使用的原创参考资产 ID。
- 原始、源文件和游戏路径。
- 人工修改说明。
- 权利/许可证。
- 审核人和日期。
- 是否需要在 Steam AI 内容说明中披露。

## 4. Codex 生图规则

当 Codex 有图像生成技能时：

1. 先读取 `docs/design/ART_BIBLE.md` 与 本文件的可复用提示词模板。
2. 先生成 brief 和文件命名计划。
3. 每次只生成一个资产组。
4. 输出进入 `art/generated_raw/<category>/<asset_id>/`。
5. 原始目录默认创建 `metadata.json`；若原始输出被 Git 忽略，可由 Git-visible 的逐文件 `CANDIDATE_MANIFEST.csv` 与完整 prompt record 作为权威等价证据，但必须逐图记录精确路径、提示词 ID、完整提示词、尺寸、生成时间、工具、参考资产 ID、状态和 SHA-256，不能用宽目录行代替。
6. 创建联系表。
7. 更新 manifest 状态为 `generated_raw` 或 `candidate`。
8. 完成独立视觉审查、记录选择证据并继续流水线；仅在目标契约第 4 节硬阻塞时暂停。

如果工具不可用：

- 创建待执行提示词和目录。
- 使用明显的几何占位图继续程序开发。
- 不声称已经生成图片。
- 不从网络随意下载替代素材。

## 5. 批量 Images API 规则

只有在视觉风格已锁定、单项流程已验证后才使用批量 API。

- 密钥从 `OPENAI_API_KEY` 环境变量读取。
- `.env` 必须被 Git 忽略。
- 脚本不得输出完整密钥到日志。
- 设置每次任务最大生成数量和预算保护。
- 失败时保留请求 ID 与错误，不无限重试。
- 脚本生成的文件仍需独立视觉审查和证据化批准，不得自动越级进入 `game/assets`。
- API 输出不得直接写入 `game/assets`。

当前工具：

```text
tools/validate_png_assets.ps1
tools/make_contact_sheet.ps1
tools/make_alpha_review_sheet.ps1
tools/check_art_assets.ps1
tools/render_svg_preview.ps1
tools/check_svg_cutout_alpha.ps1
```

以上脚本只使用 PowerShell 7 与 Windows/.NET 自带的 `System.Drawing`，不引入 Python 图像库或运行时依赖。`check_art_assets.ps1` 已接入 `tools/check_project.ps1`，并实际验证候选 PNG、CC0 参考哈希、manifest 关键字段、联系表烟雾以及假 Alpha、重复内容和错误输出目录三条拒绝路径。

## 6. 一致性策略

### 6.1 角色

- 使用批准母图作为唯一主要视觉参考。
- 固定不可变特征和色板。
- 一次编辑一个姿势或表情。
- 与母图叠加对比轮廓。
- 需要动画时先拆分或绑定，不独立生成每一帧。

### 6.2 场景

AI 可以生成氛围概念图，但可探索地图必须拆为：

- 地面 Tile。
- 水岸 Tile。
- 道路 Tile。
- 植物和石头。
- 房屋和桥梁。
- 前景遮挡。
- 独立碰撞和交互区域。

完整场景插画只用于加载画面、宣传或不可交互背景。

### 6.3 UI

- 图形与框体可生成。
- 文字、数字、按键名称和本地化内容由 Godot 渲染。
- 同一 UI 套系先批准一张组件板，再批量扩展。

## 7. 质量检查脚本建议

现有 `tools/validate_png_assets.ps1` 至少检查：

- 文件可打开。
- 宽高符合约定。
- 模式包含 alpha（需要透明的资产）。
- 透明边界是否存在异常非透明像素。
- 文件名是否匹配命名规范。
- 是否有重复哈希。
- 是否在 manifest 中登记。

自动检查不能替代视觉审查。

## 8. 预算控制

每周设置生图额度：

- 概念阶段优先少量高差异候选。
- 风格未批准前不批量生产。
- 相似候选超过 3 次仍未通过时，先修改 brief，而不是继续盲抽。
- 对常用小物件优先制作模块化套系。
- 记录废弃原因，避免重复生成同样错误。

## 9. Steam AI 内容记录

所有随游戏发布、由 AI 辅助生成的角色、场景、图标、音频或文本都标记为预生成 AI 内容候选，并保留实际工作流记录。

建议发布说明草稿，只有在与实际情况一致时使用：

> 开发过程中使用生成式 AI 辅助早期概念探索和部分 2D 视觉资产制作。所有随游戏发布的素材均经过人工选择、编辑、质量审查与项目内整合。游戏运行期间不会生成 AI 内容。

最终提交 Steam 前必须根据实际资产重新核对，不可照抄错误说明。

## 10. 失败处理

出现以下情况立即停止该资产组：

- 与现有 IP 高度近似。
- 多轮生成仍无法保持角色结构。
- 无法确认输入图片权利。
- 输出含水印、Logo 或可识别品牌。
- 透明背景和轮廓无法稳定修复。
- 实际尺寸下不可读。

停止后回到 brief，重新设计形状语言或改用人工绘制/3D 预渲染。

## 可复用提示词模板

这些是方法模板，不是已执行生成证据；真实prompt与lineage留在对应资产审计目录。AG1/A1已锁方向优先技术适配，不因模板而重启概念探索。

### 1. 通用风格前缀
```text
Original 2D game asset for a cozy wetland home-building game, soft hand-painted gouache storybook style, clean readable silhouette, gentle natural colors, subtle paper texture, consistent three-quarter top-down view, weak perspective, soft light from upper left, shadow direction toward lower right, production-ready shape design, no photorealism.
```

### 2. 通用透明素材后缀

```text
Full object visible, centered, isolated on a transparent background, no environment, no text, no letters, no numbers, no logo, no signature, no watermark, clean alpha edges, generous but not excessive padding.
```

### 3. 通用禁止约束

```text
Do not reference or imitate any existing character, entertainment IP, mascot, brand, or living artist. No fruit balanced on the head. No red shorts. No oversized baby-like head. No extra limbs, no duplicated features, no malformed paws, no inconsistent accessories, no baked-in ground shadow unless explicitly requested.
```

### 4. 主角首轮概念

```text
Create one of six clearly different original protagonist concepts for a cozy 2D wetland restoration game.

Species: capybara.
Personality: calm, observant, quietly enthusiastic about repairing waterways and building a home.
Required identity features: warm gray-brown fur, medium head-to-body ratio, slightly elongated muzzle, one subtly folded left ear, lake-teal waterproof scarf, a small water-lily-leaf-shaped crossbody satchel, dark oval eyes with tiny highlights.
Body language: patient and practical, standing with a slight forward lean.
Camera: three-quarter top-down game view.
Output: one full-body character only, transparent background.

Make this concept distinct in body shape, scarf tying method, satchel construction, and facial proportions while preserving all required identity features.

[APPEND COMMON STYLE PREFIX, TRANSPARENT SUFFIX, AND PROHIBITED CONSTRAINTS]
```

Codex 每次替换“concept 1/6”并写明差异，不允许只生成几乎相同的颜色变化。

### 5. 主角四方向母图

```text
Using the approved original character master reference, create a clean four-direction turnaround sheet for a 2D game: facing down, facing left, facing right, and facing up. Preserve exact body proportions, folded left ear, lake-teal scarf, water-lily satchel, muzzle shape, eye placement, and palette.

All four views must use the same three-quarter top-down camera angle and upper-left light. Neutral standing pose, full body visible, consistent scale. Separate each direction with clear spacing. Transparent background. No labels or text inside the image.
```

联系表文字由外部脚本添加，不能让模型生成方向标签。

### 6. 表情头像

```text
Using the approved original character master reference, create a single bust portrait with the expression: {expression}. Preserve exact proportions, fur colors, folded left ear, scarf and satchel strap. Soft hand-painted gouache storybook style, upper-left light, transparent background, no text.
```

一次只做一个表情，避免一张图中角色细节漂移。

### 7. NPC 概念

```text
Create an original {species} NPC for a cozy wetland home-building game.
Role: {role}.
Personality: {personality}.
Silhouette goal: {silhouette_goal}.
Required tools/clothing: {required_features}.
Palette: {palette}.
The character must be immediately distinguishable from the capybara protagonist in height, width, head shape, posture, and movement potential.
Three-quarter top-down game view, full body, transparent background.

Do not reuse the protagonist's face, scarf, satchel, or body proportions.
[APPEND COMMON STYLE PREFIX AND PROHIBITED CONSTRAINTS]
```

### 8. 单件家具

```text
Create one original placeable game prop: {object_name}.
Function: {function}.
Footprint: {width_cells} by {height_cells} cells on a 64-pixel logical grid.
Material: {material}.
Palette: {palette}.
Three-quarter top-down view with weak perspective, soft upper-left light. The base and contact points must be clear for grid placement. Full object visible, transparent background, no character, no text, no built-in UI badge.
```

### 9. 建筑

```text
Create an original small wetland cottage exterior for a cozy 2D game. It must fit a {width_cells} by {height_cells} logical grid footprint. Include a clearly readable front door sized for the established character scale, modular roof, simple windows, and construction materials from wood, reeds, clay, and river stone. Three-quarter top-down weak perspective, upper-left light, clean silhouette, transparent background, no sign text, no logo.
```

先生成整体概念，批准后再按门、屋顶、墙体和装饰模块拆分，不直接把完整概念图作为可交互建筑。

### 10. 植物或资源节点

```text
Create a small set of four consistent variants of {plant_or_resource}, designed as harvestable nodes for a cozy 2D game. Same species and palette, subtle differences in leaf or branch arrangement. Three-quarter top-down view, upper-left light, each variant separated with spacing, transparent background, no text. Keep all variants readable at approximately {display_size}px in game.
```

生成后拆分为独立文件并检查每个 alpha 边缘。

### 11. UI 图标

```text
Create a single original UI inventory icon for {item_name}. Soft painted storybook icon style, simplified shape, centered composition, high readability at 48 pixels, transparent background, no frame, no text, no number, no shadow outside the icon bounds.
```

UI 框和物品图标分开生成。

### 12. Tile 概念

AI 不应直接一次生成整套可用 autotile。先生成材质概念：

```text
Create a top-down material concept for {terrain_type}, designed for a cozy hand-painted 2D game. Even lighting, minimal directional objects, no large unique landmarks, no text. The texture should suggest repeatable coverage, but this is a concept source that will be manually edited into seamless 64x64 tiles.
```

随后由人工或脚本制作真正无缝 Tile、边缘和角落。

### 13. 加载画面/宣传插画

```text
Create an original key art illustration for a cozy wetland home-building game. Show the approved capybara protagonist beside a player-built pond with reeds, a wooden bench, a small cottage, and two original animal friends relaxing nearby. Emphasize the transformation from dry land to a lively waterside home. Soft hand-painted gouache storybook style, warm evening light, no text, no logo, no imitation of existing IP.
```

只有角色和环境母图稳定后才生成宣传插画。

### 14. 编辑提示词：修复一致性

```text
Edit the supplied approved original game asset. Preserve all approved shapes, proportions, palette, camera angle, lighting direction, and accessories. Change only: {single_requested_change}. Do not redesign any other feature. Keep transparent background and clean alpha edges.
```

每次只改一个问题。

### 15. 编辑提示词：透明边缘与阴影分离

```text
Preserve the object exactly. Remove the baked ground shadow and any background color. Reconstruct clean natural edges and output the object alone on a transparent background. Do not alter color, shape, texture, perspective, or proportions.
```

阴影需要时另生成：

```text
Create only a soft semi-transparent oval contact shadow matching the supplied object's footprint and upper-left lighting. No object, no background, transparent canvas.
```

### 16. 生图任务报告模板

```text
资产组：
读取的母图 ID：
使用的提示词 ID：
生成数量：
输出目录：
联系表：
manifest 更新：
主要差异：
已知问题：
批准状态：generated_raw / candidate / selected / approved / rejected
审查证据：
需用户处理的硬阻塞（如有）：
```
