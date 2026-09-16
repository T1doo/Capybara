# HOME_VISUAL_V1 功能 blockout

日期：2026-09-03
场景：`game/scenes/visual_prototypes/home_visual_blockout.tscn`
状态：`stage_3_functional_blockout / not_final_art`

## 固定尺度

- 逻辑网格：64×64 px。
- 玩家目标显示高度：144 px；当前几何玩家以 3× 缩放显示，轮廓高度约 138 px，落在目标值 ±8 px 内。
- 世界范围：1920×1200 px。
- 桥面通行带：192 px，足以容纳当前放大碰撞体并保留两侧余量。

## 稳定站位

| ID | 坐标 | 用途 |
|---|---:|---|
| `Spawn` | `(0, 0)` | 玩家出生与桥西侧主路 |
| `HouseMainDoor` | `(-576, -192)` | 住宅主门交互位 |
| `GardenEntrance` | `(-576, 448)` | 菜地入口 |
| `BridgeWest` | `(128, 0)` | 桥西端 |
| `BridgeEast` | `(640, 0)` | 桥东端 |
| `WaterwheelService` | `(768, -192)` | 水车维修/闸门操作位 |
| `DockStand` | `(768, 192)` | 码头交互位 |
| `PrimaryPathRest` | `(-256, 0)` | 主路停留位 |
| `CameraBoundaryReference` | `(896, 512)` | 相机/世界边界参考 |

所有坐标均对齐 64px 网格。上下游使用与视觉水面相同的 `CollisionPolygon2D` 多边形；桥下水面保持可见，但碰撞在桥面通行带处断开。

## 实际检查

- Godot 4.7.2 import：退出码 0。
- 独立场景 headless smoke：退出码 0、无 diagnostics。
- 自动测试实际驱动玩家从陆地撞向上游水面，确认不能进入；随后从 `(0,0)` 向右移动穿越桥面，确认能到达东岸。
- 首轮测试发现 `DockStand` 未对齐网格且 128px 桥隙会夹住约 138px 玩家；站位改为 `(768,192)`、桥面通行带改为 192px 后通过。
- Godot Movie Maker 以 Compatibility 渲染 1280×720 三帧，预览写入忽略目录 `build/art-pipeline/home_visual_blockout_capture*.png`；没有把截图当正式资产提交。
- `game/assets/shaders/storybook_water.gdshader` 为上下游提供独立世界坐标水粉流动层；两段水共享场景本地材质，碰撞多边形与动画层保持分离。
- 首次 GPU 渲染发现错误设置字段 `high_contrast` 并产生 `SCRIPT ERROR`；改为项目真实字段 `high_contrast_interactions` 后重新渲染，退出码 0 且零 diagnostics。
- 首轮水纹频率过高、接近泳池光纹；将波长放大并把叠加透明度从 0.46 降到 0.30，保留轻微流动而不压过地标。
- 自动回归证明减少动态会把 `motion_strength` 设为 0；恢复普通动态后回到 1；高对比交互设置会增强水陆分离。
- `home_storybook_style_v1.tres` 集中固定 35° 俯角、左上光、下右接触阴影、64px/144px 尺度和家园地面/路径/水岸色板；Resource 自带不变量验证。
- 主路树冠是独立 `Area2D` 前景遮挡层；真实玩家进入时淡至 0.34、离开恢复 1.0，减少动态时立即切换而不播放 Tween。
- 房屋、桥、水车和码头使用样式资源定义的半透明下右接触阴影；GPU 捕获确认阴影不改变碰撞或封堵路径。
- `storybook_ground.gdshader` 用世界坐标生成低频水粉洗色与极弱纸粒，取代整图平涂；镜头移动时纹理不会贴屏滑动。
- StyleProfile 固定 18px 岸边浅水带与 8px 内侧高光；视觉线与原有水体碰撞多边形共用拓扑，桥面仍覆盖岸线端点。
- `AmbientMotes2D` 只绘制 12 个确定性花粉/微光点；同一索引与时间得到同一位置，减少动态会冻结内部时间，恢复后继续漂移。
- Compatibility GPU 以 1280×720 捕获地表、双层岸线和微粒，退出码 0、零 diagnostics；捕获文件位于忽略目录 `build/art-pipeline/home_visual_ground_capture_v001*.png`。

## 手工运行

```powershell
& $env:GODOT_BIN --path game res://scenes/visual_prototypes/home_visual_blockout.tscn
```

这是可玩的布局与碰撞骨架。简单色块、网格、几何玩家和锚点圆环都属于明确的 Stage 3 中间证据，必须在 Stage 3 退出前由正式地面、水岸、水面、建筑、植物、交互物和角色素材替换。
