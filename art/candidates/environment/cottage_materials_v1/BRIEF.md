# 主屋绘本材质板

日期：2026-09-12
工作项：COTTAGE-MATERIALS-001
状态：prototype_integrated；纹理采样通过，整栋房屋正式美术未批准。

目标：一张三等宽竖向分区的不透明材质板：左侧奶油灰泥，中间蜂蜜色纵向木纹，右侧湖水青色错列瓦片。它只提供表面色彩和笔触，房屋结构、Alpha 与碰撞由已有分层场景保留。

候选命名：`tex_cottage_material_atlas_v001.png`。
原始目录：`art/generated_raw/environment/cottage_materials_v1/`。
验收：三分区可独立采样；无文字或品牌；自然低饱和色彩；材质映射后门窗清楚、屋顶和墙体透明度不变；对比实际游戏截图后决定是否采用。材质板使用不透明 RGB 合理，不需要生成 Alpha。

## COTTAGE-MATERIALS-001

```text
Use case: stylized-concept
Asset type: a single production texture atlas for an original hand-painted storybook game cottage
Create a landscape image divided into EXACTLY THREE equal-width vertical rectangular panels, filling the entire canvas edge to edge. No gutters, captions, frames, or borders. Every panel is a flat face-on material swatch, NOT an object or room.
Left third: warm cream lime plaster, hand-painted gouache, subtle ivory and warm ochre pooling, broad overlapping opaque brush shapes, restrained granulation, a few small worn patches. Flat even lighting, no directional cast shadows and no major cracks.
Middle third: honey-brown timber, 7 to 9 long VERTICAL wooden boards running top to bottom, rich hand-painted broad wood grain, a few gentle knots, muted golden edge wear and dark brown grain, no nails or hardware, no writing. Wood should feel warm and organic, not glossy.
Right third: muted lake-teal and sage-green weathered roof shingles, staggered rows, roughly 6 columns across and 12 rows down this panel. Each tile has subtle irregular hand-painted edges and watercolor/gouache variation. Soft lighter upper edges and subdued lower seams, no dramatic shadows, occasional tiny muted moss accents.
All three panels share premium non-pixel illustrated gouache texture, controlled natural colors, readable broad brushwork, moderate value variation. Designed to be sampled on existing 2D architectural meshes, not as finished architecture. Preserve approximately uniform average brightness within each panel; avoid vignettes, perspective, horizons, scenery, buildings, characters, text, watermark, logo, checkerboard, transparency and photographic/plastic rendering. Output exactly one atlas containing only these three swatches.
```
