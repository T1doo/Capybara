# 水岸家园码头模块

日期：2026-09-12。状态：`technical_prototype_integrated`，不等于 Stage 3 正式美术批准。

## 结构与来源

`painted_dock.tscn` 位于世界 `(704,352)`，桥面范围 `(512,256)` 至 `(896,448)`，尺寸 384×192。八块独立木板、前封边、岸侧入口踏板、桩柱、绳栏、支撑与接触阴影均为可编辑的原生结构。替换了原来的平面矩形码头及重复阴影，没有删除文件。

只复用已审查 `cottage_material_atlas_v001` 中部木纹，哈希 `91d24b01d68737484e0b4b66e5fb4f158eddb79c5a339ff1d321bb16eb070382`。UV 保持 x=520..940、y=80..930，不跨入灰泥或屋瓦区；无新增生图、外部参考或第三方素材。

## 水岸与碰撞

- 原有视觉河面完整保留在平台下方。只从下游水体碰撞中裁去实际 deck 占地，裁剪必须得到一条岸边连通凹口，否则明确报错。
- 入口为北侧 x=672..864，宽192；当前玩家半径66，中心有60px横向余量。`DockStand=(768,192)` 不变。
- 东、西、南三侧与北侧非入口段有独立实体护栏；护栏位于 deck 外缘，未缩小实际桥面。
- 当前固定场景排序：支撑Z2、桥面Z4、北栏Z20、玩家Z50、前侧/侧栏Z55。不是任意父层级、任意相机或通用建造系统的排序方案。
- 这是 Stage 3 环境样板，不实现 Stage 5 水生态或 Stage 7 钓鱼。

## 实际验证

首轮 `run_all.gd` 为739/739、退出0。之后按独立审查建议补北侧护栏真实碰撞及638点水域分类检查，最终计数与统一门编号见 `docs/AUTONOMOUS_STATUS.md`。

```powershell
& $env:GODOT_BIN --headless --path game --import
& $env:GODOT_BIN --headless --path game --script res://tests/run_all.gd
& $env:GODOT_BIN --path game --rendering-method gl_compatibility --resolution 1280x720 --script res://tests/dock_visual_fixture.gd
```

GPU命令实际退出0，五张1280×720截图位于 `build/art-pipeline/dock_review/`：岸侧入口、桥面中心、临水侧、前绳栏、东侧。三方面复核：入口和临水空间清楚；木纹/奶油绳沿用当前桥屋语言；透明轮廓、前后遮挡与边缘无明显技术破损。独立代码/视觉审查无阻止原型集成的High/Medium。

仍需整体美术统一：木结重复和纹理对比偏强；周围植物与玩家仍为占位，不能拿此组截图宣称达到正式发布质量。

## 手工试玩

运行 `tools/run_game.ps1 -VisualPreview`，从出生点过桥，沿右岸道路向下走到码头。经北入口进入后向左移动到河面上方，再尝试东、西、南和北侧封闭栏杆；应被阻挡，且仍可从北入口返回道路。站近前栏杆时绳索在玩家前，入口后方栏杆在玩家后。
