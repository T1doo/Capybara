# v005 · 实时混合角色候选

2026-10-23。状态 **technical_unapproved**。本批沿用v003形体和已登记的前/后绘制颜色来源，验证实时移动与转身；没有批准PLAYER_MASTER、完整动作或Stage3。

[64.08秒实际GPU视频](live_motion.mp4) · [逐文件来源/哈希](EVIDENCE.json) · [独立复算结果](evidence/live_check.json) · [原始运行记录](evidence/live_motion.json)

## 这一版实际改变了什么

候选显示组件只接收现有Player的实际位置、朝向和交互信号。它不读取预录位置、离线姿态索引或v004的375姿态库。原Player仍负责Input、240px/s移动、碰撞和真实拾取提交；正常正式入口尚未换成未批准资源。

运行素材固定为20张上半身图（16个转面，加下右4张低头替换）与64张足层。上半身保留原生头颈、围巾/包带的遮挡；四足是独立实时变形的2D网格。该方法含预渲染的上半身替换，但没有把完整角色帧序列重新命名为cutout。实时变形腿部和近似地影仍需视觉验收。

35°相机下，模型等角不等于屏幕八向；16个转面包含八个精确游戏朝向和八个中间姿态。角色、相机、640画布、pivot=(320,480)、0.5显示比例固定，配件不镜像。运行时仅在内存裁去透明留白，保留原生像素位置和脚底pivot，84张纹理的实际像素数据为6658132字节（约6.35MiB）；这不是全场景/驱动总内存或最终性能门。

![八个精确朝向实际行走，按原像素裁取GPU画面](eight_directions.png)

![行走／拾取／背侧转身／反向／墙边及四氛围片段](turn_and_stop.png)

图中标签为实际Player朝向；转身过程中身体尚在转向，所以中间帧不一定已经面向目标方向。八向图则取转身完成后的实际行走帧。[裁图映射与原生分层Alpha对照](evidence/diagnostics.json)保存帧号/坐标；四个中性方向分层合成的Alpha IoU为0.999958以上，只说明静止轮廓没有被拆层丢掉，不证明运动自然。

## 实际执行与证据边界

- 新序列为3840个实际60Hz物理帧/64游戏秒，Movie Maker另有5个启停画面帧，视频64.083秒、1280×720、60fps。最终公开素材复跑捕捉墙钟67.04秒；固定帧率录像不是实时性能测试或长时soak。
- 同一角色完成初始walk/明显低头拾取、露出背侧的原地转向、快速反向，以及每个八向先转身再真实行走。拾取1次，492帧实际受阻，原速度240、圆碰撞半径22、预览scale3、safe_margin0.08保留。
- 独立检查器不相信报告中的passed；重新检查84张RGBA/hash/Alpha、实际位置差、八向相机投影、真实移动时的朝向、实际ArrayMesh UV三角形还原的足点，以及9874次着地比较。最大网格足点误差0.00005774px、着地漂移0.00005502px；仍是作者足点，不是从画面识别真实脚掌接触。标记门<0.02px、漂移门<0.25px未放宽。
- 受阻后身体可能仍在转向，脚要完成支撑换步；检查器在身体对齐后再要求停止空走。首次检查将tick513尚差20.84°的转身误判为空走，失败保留并修正语义条件；没有删掉受阻检查或放宽足点容差。
- [8组纯步态状态检查](evidence/gait_tests.json)实际通过：堵停、行走、反向、原地转向、八向、30/60/120Hz步长和位置跳变。它们不等于图像或实体手柄验收。

检查实景时还发现正式拾取组件只改数量/可交互性，没有同步图形。已在PickupInteractable和正式场景配置修复：消耗后隐藏、部分拾取保留、世界状态恢复时按数量恢复显示；旧v004夹具的单独隐藏补丁移除。新增8个世界状态/显示断言，先实际复现2/835失败，再835/835通过，见[红绿证据](evidence/pickup_regression.json)。库存事务/存档格式未变。最终视频及公开素材复跑都要求库存增量1、消耗图形不可见，不仅统计成功信号。

![同一最终录像的拾取前/后；黄框为诊断标注，画面未重绘](pickup_visible_then_consumed.png)

家园夹具的即时道路绘制层曾盖住z=0地物；地面拾取物现明确置于道路之上/角色之下，碰撞及交互距离未动。最终片段原始PNG中，同一地物中心(740,496)从拾取前RGB(131,86,51)变为拾取后的道路RGB(201,173,119)，见[诊断映射](evidence/diagnostics.json)。

环境：Godot4.7.2 Standard / Compatibility，RTX4060 Laptop GPU；Blender4.5.13 LTS / Cycles CPU、32采样、8线程。角色导出沿用Standard/sRGB，世界氛围沿用原预设。源为307aa46加本批在制实现；[EVIDENCE](EVIDENCE.json)有精确执行源码快照、原始父清单、模型/源图哈希和完整构建记录。最终提交与受测源分开登记，不冒称录像已在未来提交上重新录制。

## 复现

只需要公开仓库的LFS实体素材和Godot，无需本机私有build、Blender或旧录像。设置GODOT_BIN为4.7.2 Standard，使用新输出目录：

```powershell
git lfs pull
# 默认自由操作；使用现有移动/交互按键，关闭游戏窗口退出。
pwsh -NoProfile -File tools/play_player_hybrid_review.ps1 -OutputDirectory build/hybrid_manual
# 自动序列并记录64秒；这是脚本输入，不是实体键鼠操作。
pwsh -NoProfile -File tools/play_player_hybrid_review.ps1 -OutputDirectory build/hybrid_auto -Autoplay
```

该入口验证公开文件哈希，只复制清单和84张图到新的build目录；默认自由模式不会注入测试输入。自动短检可再传-Smoke（1400tick/23.33秒），不能把它称为完整64秒。人工/实体手柄操作尚未验收。

完整从源重建也已在本机新目录实际执行：从仓库代码和已登记的两张PNG重新生成native、v003形体、双源颜色、转面、GPU片段和MP4，全部步骤退出0，见[执行日志](evidence/source_recipe.log)。不是另一台机器的干净检出验证，也不要求含时间元数据的.blend/PNG/视频二进制哈希跨次相同。

原生素材来自该完整源构建；随后仅调整夹具地物绘制层级，主视频在只复制公开素材的新目录再次完整运行64秒。原生生成与最终场景运行来源分别留痕。较早的23.33秒短检仅作补充，不代替最终视频/原始记录。

```powershell
# 还需BLENDER_BIN指向官方Blender4.5.13 LTS。
pwsh -NoProfile -File tools/build_player_motion_sample.ps1 -OutputDirectory build/hybrid_source_fresh -LiveHybrid
python tools/art/check_player_hybrid.py build/hybrid_source_fresh/hybrid/hybrid_manifest.json build/hybrid_source_fresh/live/live_motion.json
```

Python检查器需要现有Pillow环境；构建与Godot运行本身只需固定的Godot/Blender。关键前/后源PNG仍须精确匹配06781018...和c7c384da...，完整SHA见[绘制来源](evidence/paint_manifest.json)。重新生成PNG的Date/RenderTime可不同，像素/几何结果及实际动作应按检查器和视觉标准审核。正式资源仍走原批准流程。

## 技术决定与未通过项

后续主要实现采用“Blender可编辑共同源＋有界上半身转面/动作替换＋实时四足2D网格”，停止扩建按单条轨迹烘焙全角色帧的生产方式。v004完整帧样板保留为参考和回归，详见[共享决定](../../design/PLAYER_ANIMATION_V004_DECISION.md)。这是实现方向选择；ART3-100仍受批准母图、视觉和扩展成本门约束，未标done。

侧视体块、毛色/笔触、脚掌形状与接地观感还需美术精修；急反向最大踝部偏移仍约44.81px，16转面及5档低头也不等于平滑连续体积动画。当前只有下右低头替换，其他朝向拾取动画、soak/工具等完整代表动作尚未交付。墙边身体/口鼻视觉与圆碰撞占地仍未统一。NPC、环境/UI、正式入口及Stage3其他退出门均未完成。

保留失败：等角转面先期样件、急转长腿首版、导出循环变量覆盖朝向标签的版本、上述受阻转身误判。修正标签后从源完整重建，没有改写旧产物为通过。Goal继续推进；本页不是第二份任务表。
