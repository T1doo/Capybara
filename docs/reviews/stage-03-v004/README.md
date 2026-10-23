# Stage 3 · v004 连续实景动作审阅

日期：2026-10-23。实现源码固定于 [`75bac70558257feb1088e0c9c84eb243cd41f7bb`](https://github.com/T1doo/Capybara/commit/75bac70558257feb1088e0c9c84eb243cd41f7bb)；媒体提交 [`9257d8db7df3d9f67371d87d52963e2f4ff1d583`](https://github.com/T1doo/Capybara/commit/9257d8db7df3d9f67371d87d52963e2f4ff1d583)的 [exact Windows CI39915780544](https://github.com/T1doo/Capybara/actions/runs/39915780544)为 completed / success。已实际下载其原始日志，19/19工程门通过、前后工作树干净且指纹相同；[完整机器摘要](evidence/ci_9257d8d.json)可公开读取。素材为 **technical_unapproved**；本页是审阅包，不是角色母图、路线或 Stage 3 签收。

## 先看连续片段

[修正版原速视频：64.08 秒、1280×720、60fps](https://media.githubusercontent.com/media/T1doo/Capybara/9257d8db7df3d9f67371d87d52963e2f4ff1d583/docs/reviews/stage-03-v004/motion_corrected.mp4)。[GitHub 文件页](motion_corrected.mp4)也可 Download raw file。文件通过本仓库 LFS 分发；不是本机 build 路径。文件 SHA-256：`fcb38512358bc17551654d042beadd65b4765dfe0b37fd8f4a3ce43026290e64`。2026-10-23 已用无 Authorization/cookie 的匿名请求回读固定提交的全部9项媒体，均 HTTP 200、字节长度和 SHA 一致；分发核验记录见 [public_delivery](evidence/public_delivery.json)。这只证明外部可以取得，不声称外部审阅者已经看过。

| 片段位置（约） | 实际内容与观察重点 |
|---|---|
| 0–2 秒 | 同一版角色站立、微呼吸；镜头固定 |
| 2–3.2 秒 | 下右完整行走和停步；看脚掌、围巾与包带 |
| 4–4.9 秒 | 一次真实拾取提交，随后明显低头形变；看口线、肩颈与配件接缝 |
| 6–12 秒 | 暴露背侧的转向、上左与下右行走、起停 |
| 13.2–16.2 秒 | 向右接触可见测试墙，受原碰撞阻挡；看被阻挡时脚掌是否继续空走及身体探出 |
| 17–64 秒 | 起停、对角线与转向反复；后半段包含晴天上午、黄昏、雨天、夜晚预设 |

片长包含 Movie Maker 启停的 5 个附加画面帧；实际 Player 序列为 3,840 个 60Hz 物理帧，即 64 游戏秒。GPU 捕捉耗时 71.33 秒，固定帧率录制；这是普通速度播放证据，不是实时性能测量或长时 soak。输入由测试脚本注入现有 Input actions，并非实体键盘/手柄操作录像。

![实际视频按帧号顺序抽帧；裁图只用于看清动作](ordered_motion.png)

[拾取低头峰值原始 GPU 图](pickup_peak.png) · [墙边接触原始 GPU 图](wall_contact.png) · [修正前完整片段，保留腿部过伸失败](motion_before_leg_fix.mp4)。修正前的摆脚落点错误地每帧预测完整摆脚时长，恒速落地超前 32.0625px；改为剩余时长后是设计的 12px。未降低 240px/s 速度、放宽足底容差或绕过碰撞。修正版的最大踝部偏移 24.48px，仍需审查腿形；数值改善不自动批准动作。

## 同尺度、边缘与覆盖

后续已完成[同源分层A与正交B的下右walk/pickup连续对照](AB_REVIEW.md)：含5.58秒原速并排片段、实际制作成本，以及只依赖公开仓库素材的Godot复现入口。该小样仍不代表转向/全动作和最终路线通过。

![四个独立方向，原始 GPU 画面按 2×2 拼接，不逐方向缩放](four_directions.png)

四向是同一 v004 几何、双来源材质及固定相机的中性姿态，不是镜像。原始四张均 1280×720，pivot=(320,480)、display_scale=0.5、camera=(0,-96)、zoom=1；下右参考本体约 144px。640×640 帧画布来自 512×512 四周加留白并相应扩大正交画幅，像素密度不变，没有逐帧裁切归一化。此静态组早于腿部修正，使用独立 still bank；它不继承修正版动作报告。

![同位置、同姿态的晴天上午／黄昏／雨天／夜晚实际 GPU 图](four_atmospheres.png)

![四底 Alpha 诊断](alpha_four_backgrounds.png)

![静止／低头／背侧的覆盖诊断](coverage.png)

覆盖图绿色表示有绘制权重，红色表示毛/布原材质回退，蓝色是本次覆盖统计排除的其他细节材质。可见鼻下、掠射边缘和背侧仍有回退区；绿色也不证明色差、笔触或接缝合格。四氛围为既有视觉预设，不是完整天气/四季系统。覆盖与四底是诊断图，不是最终游戏素材；其独立来源见 [EVIDENCE](EVIDENCE.json)。

## 真实执行与可核查边界

- 场景复用现有 GameBootstrap、Player、WorldZone 和拾取/库存提交链；只有一名 Player，树枝拾取成功 1 次。复用既有 HomePreview 的 scale=3、圆碰撞半径=22、速度=240，safe_margin=0.08；记录有 178 个输入被阻挡的帧。正式默认入口未接入未批准角色。
- 修正版 GPU 重播重新执行实际物理和输入，3,840 帧位置误差均为 0；不是把 Player 节点按录像坐标直接搬动。角色姿态库则离线按该条轨迹生成，375 个姿态、运行时最多缓存 24 张 640×640 RGBA 纹理，约 37.5MiB 原始像素（不含其他资源/驱动开销）。**它还不是可自由输入、可量产的正式动画组件。**
- 可见性在同一 evaluated surface、世界坐标中比较目标点与首个命中深度，并处理同网格/异物遮挡、背面、掠射、clip 和细分/厚度。12 个 Blender 回归通过；工作副本烘焙静态修饰器并保留形态键，未覆盖原控制模型。原身份判断会放行同网格后层，反例保存在 [visibility](evidence/visibility.json) 首项及对应测试源码。
- 独立检查器重新读取 PNG/hash/Alpha、实际位置差和 Blender 足点，9,388 次连续着地比较最大漂移 0.006711px，足点重建误差 0.004705px。对象是作者足点，不是从图像识别的真实脚掌；地影也是足点驱动的近似影子，不能替代视觉接地验收。
- 角色导出为 sRGB 输入、线性混合、Standard 输出。7 色块回传最大 0 色阶；原图 Alpha 接入的实际 shader roundtrip 在 294,779 个近不透明像素上最大差 1 色阶。AgX 对照最大差 48。未据此宣称所有半透明边缘/混合材质或全世界色彩都已批准。H264/原始 AVI 还会有有损压缩误差。

执行环境：Windows、Godot 4.7.2 Standard / Compatibility、NVIDIA GeForce RTX 4060 Laptop GPU；Blender 4.5.13 LTS / Cycles CPU。录制源为 91c00f1 加本批在制代码，之后原子提交为 75bac70；逐文件哈希和当时源码快照随包提供。记录时的 world 与重播时只改了预览 z_index 的 world 不同，二者均保留，最终重播已逐帧核实位置不变。没有以一个 HEAD 名称掩盖来源差异。

[EVIDENCE.json](EVIDENCE.json)列出全部媒体/报告的原始字节哈希与本机来源；[motion_record](evidence/motion_record.json)、[motion_bank](evidence/motion_bank.json)、[playback](evidence/playback.json)、[marker_check](evidence/marker_check.json)、[encode](evidence/encode.json)可供外部复算。375 张完整帧库、原始 AVI 与 .blend 不随包发布；银行中的 PNG 哈希可在复现后核对，不能声称外部已下载这些未发布的文件。source/*.txt 是冻结的执行证据，不是第二份维护代码。

## 路线决定与未通过项

本轮决定：**保留可编辑 B 路线作为下一小样的主要制作源；不锁定正式运行路线，不批准 PLAYER_MASTER，不关闭 ART3-100 或 Stage 3。** 依据是同一角色已能完成 walk、明显低头与背侧转向，固定 UV 的一致性有实际连续证据；仍有以下可见或生产限制：

1. 墙边根节点受阻，但身体/鼻部可探出原圆碰撞范围；生产碰撞占地和场景遮挡仍需设计与验证，不能靠遮罩隐藏或关闭碰撞假装解决。
2. 当前材质仍偏统一毛纹与简化体块，掠射/下侧覆盖、重叠区颜色、脚掌与肩颈极值需要进一步视觉校准；未取得独立视觉批准。
3. 姿态库绑定这条轨迹。375 张的缓存/制作方式不直接扩成全游戏；没有自由转向、完整八向、soak/工具等全动作的生产证据。
4. 旧 A cutout 与当前 B 的母图/动作质量不同，不能据旧 A 更弱宣布 B 胜出。[同源A/B首段](AB_REVIEW.md)现已实际完成，但仅下右walk/pickup；后续集中验证少量分层加必要转体替换，不建设两条全量产线，最终仍需背侧转向、视觉与服装/运行成本证据。

NPC、统一环境/UI、正式入口和 Stage 3 全部退出条件仍由 [阶段 PLAN](../../stages/stage-03/PLAN.md)维护；本页不是任务表。旧失败与源素材继续保留，不因目录整理删除。

## 复现入口

在包含 LFS 实体文件的干净检出中，先固定上述提交或其经核验的后继，并安装同版本官方工具。环境变量指向实际可执行文件：

```powershell
git lfs pull
# GODOT_BIN: Godot 4.7.2 Standard console executable
# BLENDER_BIN: Blender 4.5.13 LTS executable
pwsh -NoProfile -File tools/build_player_motion_sample.ps1 -OutputDirectory build/review_v004_fresh
```

该脚本在新 build 目录顺序执行 native→v003→双来源 Standard→64 秒实际记录→姿态库→GPU 录像→MP4。各组成步骤已实际执行；**尚未从另一台干净主机完整执行这个组合脚本**，不冒称跨机复现已通过。脚本只生成候选夹具，不修改正式入口。

PNG 输入字节须精确匹配：前源 `06781018de02905d017667e0bb03c3a3fde82a2c164ba8153dfa281ab3a4201a`；后源 `c7c384daf098b66950df8d42c124708a40304989b717193174449affa14b2d1b`。重新生成的 .blend/录像可能因时间/编码/机器不同而有不同二进制哈希；逐帧 Player 位置容差 0.01px、作者足点重建 <0.02px、同次着地漂移 <0.25px、原图回传最大 1 色阶、PNG 至少 1px 透明留白。图像外观仍须实审。

```powershell
python tools/art/check_player_motion.py build/review_v004_fresh/bank/motion_manifest.json build/review_v004_fresh/record/motion.json
python tools/art/test_player_motion_plan.py
```

机制专项入口为 `tools/art/test_player_paint_visibility.py`，需要通过 Blender 的 `--background --factory-startup --python-exit-code 1 --python ... -- --output-dir build/visibility_fresh` 执行。当前报告与对应源文件可从固定提交读取，CI 绿灯只覆盖工程门，不代替本页视觉判断。
