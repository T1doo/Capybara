# 可编辑材质来源

该目录保存经审查的原始不透明材质板。编辑源由三部分共同构成：

- 本目录 `tex_cottage_material_atlas_v001.png`，完整保留原像素。
- `game/scenes/visual_prototypes/assets/materials/cottage_*_material_mask.svg`，可独立编辑的表面分区。
- `game/assets/shaders/cottage_painted_surface.gdshader`，两块屋面 UV、灰泥/木纹混合强度与透明度组合。

材质采样和图层组合是此次人工编排/代码处理步骤；没有把整栋生成房屋的烘焙棋盘作为运行时纹理。运行时副本只在 Stage 3 原型场景消费，发布批准状态见候选目录 `MANIFEST.json`。
