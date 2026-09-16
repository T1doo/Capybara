# 水岸家园木桥模块

日期：2026-09-12
状态：`technical_prototype_integrated`，尚未批准 Stage 3 整体美术。
工作项：`BRIDGE-BUILD-001`。

## 结构与材质来源

独立 `painted_bridge.tscn` 替换旧平面桥矩形。桥面跨度512px、净宽192px，放在世界 `(384,0)`，接岸范围x=128至640。14块横跨桥宽的木板、前侧封边、后栏杆、前栏杆、两根前侧可见桥墩和接触阴影分别生成。桥面保持平面可行走，扶手使用轻微弧线装饰。

纹理复用已经审查的 `cottage_material_atlas_v001` 中部木纹区，SHA-256 `91d24b01d68737484e0b4b66e5fb4f158eddb79c5a339ff1d321bb16eb070382`。UV 位于x=518..938、y=8..1016，未跨入灰泥或瓦片区，没有本批新增生图。初次栏杆每短段采满整条纹理导致细碎重复，现已按全桥X连续采样。

原生场景/脚本是可编辑结构源，已从主场景移除旧桥绘制与旧桥阴影。无文件删除。

## 碰撞与排序

- 两侧栏杆采用独立 `StaticBody2D`，足迹在y=±102，厚12px；清晰保留192px净宽。
- 当前玩家碰撞半径66px，桥内中心可横移约±30px；自动测试实际往返两岸。
- 栏杆测试在世界x=160、位于河流角外运行，确认碰撞对象为 `RailCollision`，避免把水体碰撞误当栏杆实现。
- Supports Z=2、Deck Z=4、RearRail Z=20、Player Z=50、FrontRail Z=55。此固定尺寸模块适用于当前世界Z约定；不能推广为任意父层级或任意桥长的通用排序。

## 实际证据

首轮统一门 `20260912T052641578Z-p31604-d1747774`：16/16、702/702、退出0、零Godot诊断；之后只修正栏杆取样并增加视觉捕获入口，最终门记录在自治状态。

```powershell
& $env:GODOT_BIN --path game --rendering-method gl_compatibility --resolution 1280x720 --script res://tests/bridge_visual_fixture.gd
```

GPU捕获退出0、无诊断，`BRIDGE CAPTURE PASSED: 5 views saved`。实际家园场景和玩家依次处于桥中心、前栏杆、后栏杆及两岸，等待物理和渲染后保存到 `build/art-pipeline/bridge_review/`。

独立审查 `bridge_review` 查看代码及五图，确认连续木纹、桥面通行、前后栏杆遮挡和接岸关系。复审High=0、阻止当前原型集成的Medium=0。该结论不批准Stage3正式画面；周围地形/植物、水车等仍需持续制作。
