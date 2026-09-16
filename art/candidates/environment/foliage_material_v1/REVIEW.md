# 阔叶树原型审查

日期：2026-09-12。状态：prototype_integrated，release_approved=false。

## 来源与范围

FOLIAGE-MATERIAL-001由内置ImageGen一次文字生成，无输入图和外部IP；原图1254×1254 RGB、2,312,583 bytes，SHA256见MANIFEST.json。候选、用途批准、源和运行时四份像素完全一致；透明来自原生树冠网格，不伪称RGB具有Alpha。完整提示词见BRIEF.md。

## 代码与实景

- 用160点有机轮廓及有界UV建立树冠，三个确定性变体不高频平铺、不镜像受光方向；shader降低对比并控制整体体积明暗。
- 五棵树替换圆形树冠，占地仍按原家园站位；树干、碰撞、阴影和可淡出的树冠分开，树干按实际玩家南北位置排序。
- 复用现有CanopyOccluder，并修复玩家移除组后离开/释放导致的永久淡化；实际碰撞体回归覆盖。
- 初轮自动测试752/752、退出0。GPU `foliage_visual_fixture.gd` 退出0，三个实景状态与两张独立透明渲染保存到 `build/art-pipeline/foliage_review/`；实际中心Alpha=1.0/0.34、角落=0。

```powershell
& $env:GODOT_BIN --headless --path game --script res://tests/run_all.gd
& $env:GODOT_BIN --path game --rendering-method gl_compatibility --resolution 1280x720 --script res://tests/foliage_visual_fixture.gd
```

独立foliage_review两轮检查原图、全景、近景、遮挡/恢复、Alpha及代码，无High，允许原型集成。全景叶尺度和对比基本协调，未见方框、黑边或不透明底板；shader保留节点淡化。

## 正式美术差距

树冠仍偏整块纹理剪影，外轮廓会截断部分叶片，缺独立枝叶簇空隙；树干比叶片更平面，短干大冠比例尚未证明正式统一。这些Medium纳入ENV3-002，不要求重复生图，不批准Stage3整体质量门。

手工试玩：用 `tools/run_game.ps1 -VisualPreview` 打开家园，走入主路左侧树冠下，检查树冠淡化、树干阻挡与离开恢复；设置“减少动态效果”时淡化立即完成。
