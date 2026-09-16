# 水车环境表现模块

日期：2026-09-12
状态：`technical_prototype_integrated`；Stage 3 环境表现，不包含 Stage 5 水生态模拟。
工作项：`WATERWHEEL-BUILD-001`。

## 来源与结构

独立 `painted_waterwheel.tscn` 替换原家园静态圆轮。木纹复用已审查 `cottage_material_atlas_v001` 中部区域，UV x=664..724、y=30..730，无新生图。原生GDScript为可编辑结构源。

固定A架、轴承、进水槽和回流槽保持不动；16组轮缘/轮叶、8根轮辐在独立旋转节点内，外层x=0.78压缩产生弱透视椭圆。水流落在左上轮叶，负角速度使该侧轮叶向下；回流槽通向左下河边涟漪。这是表现层的进出水关系，尚非水量、动力或地形高度模拟。

`set_flow_enabled()` 控制水流显示和轮子运动；现有设置服务的 `reduced_motion` 信号冻结轮子与水流相位，但保留静态水流。排序放在独立物理更新中，按被引用玩家位于南/北设置当前场景Z=8/55，停水与减少动态都不会冻结排序。

地基有独立StaticBody2D，操作站位沿用 `(768,-192)`。测试实际从道路抵达并继续向前撞到 `FrameBody`，没有把河岸阻挡当成地基实现。

## 运行与审查

首轮统一门 `20260912T053905706Z-p15704-56391939`：16/16、708/708、退出0、零诊断。随后加入北侧排序修复和两项回归，最终门见自治状态。

```powershell
& $env:GODOT_BIN --path game --rendering-method gl_compatibility --resolution 1280x720 --script res://tests/waterwheel_visual_fixture.gd
```

GPU捕获退出0、五视角保存成功、零诊断。实际两次流动角度约6.1011→5.9746rad；减少动态、停水、北侧视角期间保持5.9746rad。捕获位于 `build/art-pipeline/waterwheel_review/`：流动A/B、减少动态、停水及北侧遮挡。

独立只读审查 `waterwheel_review` 查看代码与截图，北侧玩家永远置前的Medium已通过位置排序修复。复审High=0，剩余非阻塞Medium=1：木纹密度与连接件/支架体积仍偏技术样件，留待整体美术统一。没有把此模块批准为整套正式环境美术。
