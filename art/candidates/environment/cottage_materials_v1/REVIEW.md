# 主屋材质板与映射审查

日期：2026-09-12
状态：通过 Stage 3 原型材质集成；未批准整栋房屋正式美术。

## 生成和处理

使用内置 ImageGen 按 `BRIEF.md` 中唯一完整提示词生成一次：1536×1024 RGB，左/中/右各512px为灰泥、纵木纹、青绿屋瓦。没有输入外部照片或角色。原始文件按 raw → candidate → approved → source_layers → 原型场景依次保留，精确路径和 SHA-256 见 `MANIFEST.json`。批准只覆盖材质采样用途。

两张原生 SVG 遮罩按原有房屋结构指定表面：红色=灰泥，绿色=纵木纹，青色=横木纹，蓝色=屋瓦，黑色=保留原绘制。材质不覆盖窗玻璃、雨链、门把和结构边线。Shader 保留源 Alpha 并乘图层 modulate，支持现有屋顶淡化。纹理采样内缩边界，不跨三分区取色；屋瓦按两块屋面分别做双线性逆 UV 映射。

初次仿射映射曾因钳制边界将右侧瓦片拉成横条；已改为分面双线性映射。最终实际 GPU 输出不再出现该横条。

## 验收结果

- 独立审查 `material_review` 实际查看材质板、shader 与五张 GPU 对照图，Blocker/Critical/High=0/0/0。
- 同机位 `unpainted_control.png` 与 `door_approach.png` 证明屋瓦、暖木纹和灰泥色差有可见改善，门窗仍清晰。
- `roof_opaque.png` / `roof_faded.png` 验证玩家遮挡与墙体独立性；实际 overlap=1、淡化 Alpha=0.28。
- 四底合成改为使用 SubViewport 实际 GPU 材质输出；白、黑、草绿、水蓝底无可见矩形背景或明显彩边。
- 在1024×1024合成结果上每4像素取样，与原图层合成 Alpha 比较：65,536点、超过0.01容差的差异为0。
- 最终 GPU 命令退出0，`failures=0`，无 Godot ERROR/WARNING。
- 最终项目门 `20260912T052054450Z-p30196-0ee4fdee`：16/16、695/695、退出0、零 diagnostics，含Windows导出/启动。治理脚本最初误把PNG压缩字节按文本扫描成UNC路径；改为代码/文本配置扩展名扫描后通过，未更改原路径正则。

执行入口：

```powershell
& $env:GODOT_BIN --path game --rendering-method gl_compatibility --resolution 1280x720 --script res://tests/cottage_visual_fixture.gd
```

产物位于忽略目录 `build/art-pipeline/cottage_review/`；`four_backgrounds.png`、`assembled.png` 使用实际材质，单层 PNG 则是底图，二者不混淆。

## 保留问题

1. 右坡瓦片比正坡密集，角部压缩较强；正式美术需统一两坡物理瓦片尺度和屋脊衔接。
2. 烟囱、花箱和粗边线仍较简化，和有绘本纹理的屋瓦/木梁存在细节密度差。

以上为两个 Medium，不阻止本批原型材质集成。整栋主屋依然未达到锁定 A1 的完整水粉质感，ART3-005 保持开放。仅一次材质生成与一次映射修复，没有重画既定角色或家园构图。
