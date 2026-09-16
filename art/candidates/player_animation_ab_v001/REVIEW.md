# 主角动画 A/B 最终技术样件独立审查

- 审查时间：2026-09-16T17:17:42.4895189+08:00。
- 审查角色：Codex 独立视觉审查代理 `docs_migration`；不是人工审核声明。
- 观察源码基准：`dd4af4b808f2451cbd7efe0b3db10eb027d90efd` + 本轮未提交制作工具/样件；具体受审来源以本页manifest和内容哈希为准，不把此HEAD当全部产物已提交。
- A 路线：cutout `final-20260916`，12个技术帧。
- B 路线：Blender `run_20260916T085550085Z`，9个技术帧，工具记录4.5.13 LTS。
- 状态：两条技术制作及Godot实景显示路径已有实际产物；两条绘本视觉门均失败；动画路线门仍未完成，不锁定胜出路线。

## 本次证据范围

本次实际查看：

1. `build/art-pipeline/player_ab_v001/review_ab_final_v004/fixed_scale_contact_sheet.png`，21个技术帧统一比例联系表。
2. `build/art-pipeline/player_ab_v001/world_cutout_clear/candidate_00.png`，A路线无遮挡Compatibility GPU实景。
3. `build/art-pipeline/player_ab_v001/world_blender_clear/candidate_00.png`，B路线无遮挡Compatibility GPU实景。

同时读取两份最终render manifest、两份clear capture manifest与v004原生像素Alpha报告，重新计算全部21个PNG哈希，并复核A路线逐帧SVG源哈希及两个制作脚本、GPU夹具脚本哈希，均与最终manifest对应。未在本审查代理中再次启动Blender或GPU捕获；实际执行事实由主线程运行记录和这些输出共同定位。

以上build产物仅本机可取，不提交Git，干净检出需重新生成。早先的 `world_cutout_final` / `world_blender_final` 被树冠部分遮挡，只能用于遮挡样本观察；不能拿其遮挡后的可见面积评判完整角色形体。本次形体结论依据无遮挡clear组。

## 公同比较条件

| 项目 | 最终证据 |
|---|---|
| 画布 | 两路线均512×512 |
| 相机俯角 | 两份manifest均声明35°；A为参数投影，B为正交渲染 |
| 固定pivot | 两者均(256,384)，定义为固定rig地面原点/四足支撑中心；不是逐帧裁切后的最低像素 |
| 标定尺度 | down-right站立参考Alpha本体高度均288px；一次参考标定后固定，不逐方向/逐帧归一化 |
| 联系表/实景比例 | 固定0.5，因此DR参考角色本体144px；其他姿势允许真实投影/姿态高度变化 |
| 实景夹具 | 1280×720，camera_position=(0,-96)，zoom=1，player_position=(64,0)，Compatibility GPU |
| 配饰定义 | 两份manifest均记录解剖左侧围巾结、右侧包；最终还需连续转面与遮挡审查，不能只靠字段证明 |

上视图的A本体高度319px、B约271–272px，反映当前造型/投影差异。本联系表没有把它们逐帧缩成同高，因此这种差异没有被展示工具掩盖；也不能把单一DR标定等同于全方向造型一致性已经通过。

## 精确来源与哈希

| 来源 | SHA-256 |
|---|---|
| A最终render manifest | `c3da9e43cdf223f99fa78c4c5249a699f7149ca5ab60408ada296cc09cf50311` |
| A制作脚本 tools/art/build_player_cutout_v002.py | `be1f9f293e7b9f250a9886b5c4ae4e3f339c657c428f8f18a1d4dfeef57eec2f` |
| A最终DR站立SVG源 | `d06988438dc98db5a32240c4d72d9795379d2fbb813429304f3313d4c194397a` |
| A最终DR站立PNG | `4ac971142cb3022de69006154cc27723d20fd144e475c91b05a7728bb156971a` |
| B最终render manifest | `7a4f2d1b1f0940fcbea15ac29a16b0cb185bb28ab9dfe8176577a07ac3586b3f` |
| B制作脚本 tools/art/build_player_mesh_v001.py | `06824c351484a69a5426474d79babbecc99e78e47bbb93630a935e463975328f` |
| B最终DR idle PNG | `bebc33c3d3a3234cd0060f965e1cd4a2f024737475c077f62093316993c84f4b` |
| 公共GPU夹具 tools/art/capture_character_candidate.gd | `cdc6deead2c26ea4b9c042cdfae2796207ddf92d531f87ff71bdf9e0b01be997` |
| v004 Alpha报告 | `392431e422d0ddf987be4e79ebbd195d76e6d20d39891cfdc3a84b19984e8ebe` |
| v004固定比例联系表 | `2456a90457f34b8cf07a16462b16e8fa714fdef158fdf678539629964b4cea11` |
| A无遮挡实景candidate_00 | `5bde027c0c5046c1c9c81e670a91ee7895ea98198351e83c1dc2bcd283cfc5a9` |
| B无遮挡实景candidate_00 | `5858a756d32e001afbb36088c9c80e8631886ca0ddd0fa78baa1de1447548705` |

A最终manifest位于 `build/art-pipeline/player_ab_v001/cutout/final-20260916/render_manifest.json`；B最终manifest位于 `build/art-pipeline/player_ab_v001/blender/run_20260916T085550085Z/render_manifest.json`。A的SVG源位于本目录 `cutout/final-20260916/`。B的可编辑blend由其manifest定位；本次不能把“文件已产出”写成完整绑定/可动画生产门通过。

## 技术结果与更正

v004报告采用直接LockBits读取原始PNG，21帧均为 `border_alpha_pixels=0`，`alpha_failures=[]`。本审查读取报告并复核帧哈希，没有独立重跑全部像素测量。早先v002/v003用GDI重绘副本再检测造成的边缘假阳性，不能复用为最终帧存在触边瑕疵的证据；旧失败保留供工具审计，本次最终图不据此扣分。

两条技术路径已能产出带Alpha的多方向/关键姿态，并由同一GPU夹具展示。这证明管线和比较尺度已建立，不证明角色精美、步态稳定、完整连续动画、低成本量产或正式玩法集成。

## 视觉发现与严重级别

| ID | 级别 | 路线 | 实際观察与影响 | 达到下一视觉门的要求 |
|---|---|---|---|---|
| AB-VIS-001 | High | A cutout | 大块近似平涂的椭圆/圆角几何体与扁平色面构成角色，缺乏AG1的柔和水粉材质和自然体块过渡。在同一房屋/木桥/树冠实景中明显是技术占位。 | 在可编辑分层基础上完成达到AG1质感的绘本表面与体块，不把加噪点视为材质完成。 |
| AB-VIS-002 | High | A cutout | DR头部像独立圆角块接在细长后躯前；青围巾在DR主要只读成脸侧小色片，宽钝口鼻、连续肩颈、近地四足和布料识别不足。后视图比例也与DR有明显差异。 | 重构头肩连接、口鼻与四足支撑、围巾可读形体，并用固定比例四方向及无遮挡实景验证；不能以透明合格替代造型。 |
| AB-VIS-003 | High | B Blender | 造型与光照比A更有连续体积，但表面为均匀平滑的塑形/玩偶感，鼻口和身体的塑形过渡缺少AG1的绘本毛色与笔触。实景中仍是光滑模型样件。 | 受控修整轮廓、材质分区和绘本表现，在实际144px与环境中达到统一风格；不因A较弱就批准B。 |
| AB-VIS-004 | Medium | B Blender | 头躯仍偏规则圆钝，足部和表情信息简化，成年长低气质尚不足以据关键帧锁定。 | 对照AG1连续肩颈、宽钝鼻、小侧眼与低足支撑校准；检查背面/侧面轮廓，不靠放大眼睛增加可读性。 |
| AB-QA-001 | High：路线门缺项 | 两路线 | 当前只提供有限关键姿态/静态帧，不能证明完整idle/walk/pickup/soak连续动作、足底锁定、滑步、回环、遮挡与配饰漂移。 | 同场景同速度的连续播放/移动证据，记录实际方向与动作覆盖，验证接地、滑步与稳定性后再评路线。 |

本次未发现视觉来源层面的Blocker/Critical，但这不是对全部源码与所有依赖许可证的完整审计。两条技术骨架各自都有可复现用途，其当前图像均不能进入正式游戏资产，也不能用来降低AG3或既定主角标准。

## 尚缺比较数据与下一步

- 动态：连续动作、足底轨迹与实际移动速度对应关系、转向过渡、配饰遮挡和八方向运动。
- 制作成本：在同一认可造型标准下，记录新增一个方向/动作、修改配饰、修整错误所需的实际操作与时间；脚本生成帧数不是量产成本实测。
- 运行成本：相同场景/硬件下纹理内存、图集、帧时间和导入/导出影响；当前GPU截图不代表性能门通过。
- 风格生产性：先将各路线一个有代表性的方向/动作提升到目标绘本质量，再比较可维护性及服装扩展；不要同时建设两条全量流水线。

结论仍为 `technical_unapproved / comparison_incomplete`。ART3-100及动画路线门不能标为done。后续选择必须以同等认可的视觉质量、连续动作与实际成本/性能证据作出，不以本轮静态“哪张较好”或现有工具可用性宣布路线胜负。
