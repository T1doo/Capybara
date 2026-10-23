# v004 同源 A/B · 下右 walk 与 pickup

2026-10-23 实际执行。制作源与64秒B样板完全相同：packed blend SHA `089bdb4cfb5c3f3d9af5a9c6a4f75467a62cc04c489c580ae854a3c200e09677`。这是 ART3-100 的小规模连续对照，仍为 **technical_unapproved**，不批准母图或 Stage 3。

[原速并排视频](ab_same_source.mp4)：左A cutout，右B正交预渲染。每侧原1280×720，合成2560×720，60fps、335个画面帧/5.583秒；两侧同起点、同实际Player轨迹、原240速度、同相机/尺寸/晴天预设。真实动作330物理帧/5.5秒，其中2–3.2秒为walk、4–4.9秒为明显低头拾取。5个附加画面帧来自Movie Maker启停。没有把某侧放大、换机位或用旧占位A作对手。

![从实际并排录像按同帧抽取的原像素裁图](ab_ordered.png)

## 两条路径实际做了什么

A从同一可编辑模型导出4个完整足层、躯干、头部/围巾各5档替换、静态包层，共16张RGBA；足层使用63顶点二维网格，髋部保留、脚掌按同一实际位移对应的足点变形。头颈有重叠覆盖，远足保留静止时被挡住的像素。它不是把B的完整精灵帧换个名称。全部16层共645494个PNG文件字节，可在[cutout_layers](cutout_layers)取得，未进入game/assets。

B的完整64秒样板见[主审阅页](README.md)。为了对比制作成本，另在相同CPU/8线程、Cycles32采样、同源/同相机下重新渲染前330tick所需68个完整姿态。68张PNG文件哈希因Date/RenderTime元数据不同而变化；逐张解码比较RGBA后 **全部像素完全相同**，不是放宽视觉阈值后通过。B新渲染只标subset_complete，不冒充全64秒新银行。

| 本轮可比的实测/配置 | A 分层 | B 完整帧 |
|---|---|---|
| 离线输出数量 | 16张部分图层 | 前330tick的68张完整姿态 |
| 本机离线生成墙钟 | 27.188秒 | 123.937秒 |
| PNG文件字节 | 645494 | 7998312 |
| 当前未优化运行纹理像素预算 | 16张全部加载，25MiB | 最多缓存24张，37.5MiB |
| 动作范围 | 下右walk/pickup；idle静止 | 同段walk/pickup，另含量化微呼吸 |

表格是这两个样件的实际工作量，不是完整角色量产效率或性能胜负。A没有idle呼吸，B有；透明留白尚未裁成紧凑图集，二者都能继续优化。渲染墙钟不含人工美术修整、服装设计、初次编写工具或整套方向生产成本；本次没有做这些成本的虚假外推。录制的GPU/CPU均受Movie Maker影响，不拿不同长度的平均帧时间排名。原始机器数据见[成本](evidence/ab_cost.json)、[A重播](evidence/ab_a_playback.json)、[A配置](evidence/ab_a_cutout.json)、[B子集](evidence/ab_b_render_manifest.json)和[转码来源](evidence/ab_encode.json)。

## 当前观察与决定

同帧实景中，两侧头躯、配件和表面能对应，A没有重新退化为旧平涂占位。walk的二维腿形与B仍有差别；A只有5档低头替换，不能据几张近似截图宣称时间连续性合格，极值之间仍需审查跳变/肩颈/围巾。B的步态更依赖完整姿态库，当前仍绑定一条轨迹。主线程看过实际GPU关键帧和解码后的并排序列，不声称独立美术批准或真人原速验收已经完成。

保留Blender为共同可编辑制作源；下一批只沿“少量2D分层＋必要转体替换”的候选运行方式做一个背侧转向样件，B完整帧作同源对照/必要替换源。不要再扩建两条全量动作产线。最终路线需通过转向与自由起停、绘本质量及实际服装修改/运行开销验证，ART3-100仍in_progress。完整四独立方向、八向、idle/walk/pickup/soak及正式入口范围不变。

## 仅凭仓库即可运行A

不需要本机未提交的.blend、完整B帧库或Blender。先确保LFS下载的是实体PNG，GODOT_BIN为Godot4.7.2 Standard：

```powershell
git lfs pull
pwsh -NoProfile -File tools/replay_player_cutout_review.ps1 -OutputDirectory build/cutout_review_fresh
```

脚本验证公开文件的EVIDENCE哈希，把2份轨迹/足点JSON和16层复制到新的build目录，实际导入Godot并运行原Player/拾取330tick，保存AVI与报告。输入是脚本注入，保存关闭，不是实体键鼠/手柄体验验收。2026-10-23已在本机新的输出目录实际成功，位置误差0、拾取1、Godot诊断0；不是另一台干净主机重测。全B从源重建入口仍见[主审阅页](README.md)。

保留的失败：首轮远侧脚被静止身体holdout裁空；首次录像用了相对路径，Godot返回0但Movie Maker连续ERROR，该次不计通过；首次公开目录重播因Windows斜杠混用误拒路径，规范化后在新目录重跑通过。原始失败均留在build，未删检查或弱化路径/Alpha/哈希条件。
