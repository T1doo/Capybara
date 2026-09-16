# 11 图像生成提示词库

版本：1.0  
日期：2026-08-30

这些模板用于 Codex 的图像生成技能或经批准的 Images API 流程。所有输出仍须遵守 `03_ART_BIBLE.md` 和 `04_AI_ASSET_PIPELINE.md`。

提示词建议使用英文主体以便固定术语，Codex 负责在 metadata 中同时记录中文 brief。

## 1. 通用风格前缀

```text
Original 2D game asset for a cozy wetland home-building game, soft hand-painted gouache storybook style, clean readable silhouette, gentle natural colors, subtle paper texture, consistent three-quarter top-down view, weak perspective, soft light from upper left, shadow direction toward lower right, production-ready shape design, no photorealism.
```

## 2. 通用透明素材后缀

```text
Full object visible, centered, isolated on a transparent background, no environment, no text, no letters, no numbers, no logo, no signature, no watermark, clean alpha edges, generous but not excessive padding.
```

## 3. 通用禁止约束

```text
Do not reference or imitate any existing character, entertainment IP, mascot, brand, or living artist. No fruit balanced on the head. No red shorts. No oversized baby-like head. No extra limbs, no duplicated features, no malformed paws, no inconsistent accessories, no baked-in ground shadow unless explicitly requested.
```

## 4. 主角首轮概念

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

## 5. 主角四方向母图

```text
Using the approved original character master reference, create a clean four-direction turnaround sheet for a 2D game: facing down, facing left, facing right, and facing up. Preserve exact body proportions, folded left ear, lake-teal scarf, water-lily satchel, muzzle shape, eye placement, and palette.

All four views must use the same three-quarter top-down camera angle and upper-left light. Neutral standing pose, full body visible, consistent scale. Separate each direction with clear spacing. Transparent background. No labels or text inside the image.
```

联系表文字由外部脚本添加，不能让模型生成方向标签。

## 6. 表情头像

```text
Using the approved original character master reference, create a single bust portrait with the expression: {expression}. Preserve exact proportions, fur colors, folded left ear, scarf and satchel strap. Soft hand-painted gouache storybook style, upper-left light, transparent background, no text.
```

一次只做一个表情，避免一张图中角色细节漂移。

## 7. NPC 概念

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

## 8. 单件家具

```text
Create one original placeable game prop: {object_name}.
Function: {function}.
Footprint: {width_cells} by {height_cells} cells on a 64-pixel logical grid.
Material: {material}.
Palette: {palette}.
Three-quarter top-down view with weak perspective, soft upper-left light. The base and contact points must be clear for grid placement. Full object visible, transparent background, no character, no text, no built-in UI badge.
```

## 9. 建筑

```text
Create an original small wetland cottage exterior for a cozy 2D game. It must fit a {width_cells} by {height_cells} logical grid footprint. Include a clearly readable front door sized for the established character scale, modular roof, simple windows, and construction materials from wood, reeds, clay, and river stone. Three-quarter top-down weak perspective, upper-left light, clean silhouette, transparent background, no sign text, no logo.
```

先生成整体概念，批准后再按门、屋顶、墙体和装饰模块拆分，不直接把完整概念图作为可交互建筑。

## 10. 植物或资源节点

```text
Create a small set of four consistent variants of {plant_or_resource}, designed as harvestable nodes for a cozy 2D game. Same species and palette, subtle differences in leaf or branch arrangement. Three-quarter top-down view, upper-left light, each variant separated with spacing, transparent background, no text. Keep all variants readable at approximately {display_size}px in game.
```

生成后拆分为独立文件并检查每个 alpha 边缘。

## 11. UI 图标

```text
Create a single original UI inventory icon for {item_name}. Soft painted storybook icon style, simplified shape, centered composition, high readability at 48 pixels, transparent background, no frame, no text, no number, no shadow outside the icon bounds.
```

UI 框和物品图标分开生成。

## 12. Tile 概念

AI 不应直接一次生成整套可用 autotile。先生成材质概念：

```text
Create a top-down material concept for {terrain_type}, designed for a cozy hand-painted 2D game. Even lighting, minimal directional objects, no large unique landmarks, no text. The texture should suggest repeatable coverage, but this is a concept source that will be manually edited into seamless 64x64 tiles.
```

随后由人工或脚本制作真正无缝 Tile、边缘和角落。

## 13. 加载画面/宣传插画

```text
Create an original key art illustration for a cozy wetland home-building game. Show the approved capybara protagonist beside a player-built pond with reeds, a wooden bench, a small cottage, and two original animal friends relaxing nearby. Emphasize the transformation from dry land to a lively waterside home. Soft hand-painted gouache storybook style, warm evening light, no text, no logo, no imitation of existing IP.
```

只有角色和环境母图稳定后才生成宣传插画。

## 14. 编辑提示词：修复一致性

```text
Edit the supplied approved original game asset. Preserve all approved shapes, proportions, palette, camera angle, lighting direction, and accessories. Change only: {single_requested_change}. Do not redesign any other feature. Keep transparent background and clean alpha edges.
```

每次只改一个问题。

## 15. 编辑提示词：透明边缘与阴影分离

```text
Preserve the object exactly. Remove the baked ground shadow and any background color. Reconstruct clean natural edges and output the object alone on a transparent background. Do not alter color, shape, texture, perspective, or proportions.
```

阴影需要时另生成：

```text
Create only a soft semi-transparent oval contact shadow matching the supplied object's footprint and upper-left lighting. No object, no background, transparent canvas.
```

## 16. 生图任务报告模板

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
