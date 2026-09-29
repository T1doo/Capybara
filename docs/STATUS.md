# 当前恢复点

> 用户已在 2026-09-29 明确继续开发。Stage 3 尚未完成，原v2契约与RC1范围不变。

- observed_at: 2026-09-29T22:48:00+08:00
- safe_branch: codex/production-clean-20260916
- review_baseline: 79092c078c63c1e1d5a6d056ebcedf8401a9ac59
- observed_head: 0a50dce（本地已提交玩家v002；远端安全线仍f5fb86a，TLS握手失败，未取得新exact CI；毛色材质候选批次dirty）
- 产品 Stage：3，主角母图、正式场景/UI、四氛围和入口整合均未通过。

## 安全与已核对事实

唯一工程 E:\Capybara；当前分支从指定审阅提交的干净祖先链继续。旧本地 main/autonomous-v1/标签禁推禁合并。远程 T1doo/Capybara 为 public；远程生产分支仍为 f5fb86a，本地领先已提交的0a50dce；两次push均TLS握手失败，OpenSSL只读ls-remote也遇TLS EOF，未修改持久Git配置或关闭证书验证。原交接附件仍未跟踪，SHA-256 `72ab12633bd4f9a585d502ee1dcf9aa34526e9e0ec3472882d5e159d39e5f3b1`未变化。Git LFS fsck HEAD 通过，AG3/AG4、补面及NPC PNG已提交为LFS对象。

## 最近证据

- dd4af4b 的 exact Windows CI 35075003214 成功；实际 1200 秒 Stage 1 soak run 20260916T084039617Z-p43072-dd264577 通过：8378轮、2095转场/输入、524选择、20心跳、零诊断。[Stage 1 LOG](stages/stage-01/LOG.md)。
- Stage 3 本地 WIP 50f4cf7 的候选/来源专项通过：AG3→AG4→清洁 AG1 哈希链、真实 Alpha、清单状态，25/25 负向 fixture。A/B 两路线仅技术样件；正式绘本视觉审查仍失败。[独立审查](../art/candidates/player_animation_ab_v001/REVIEW.md)。
- 恢复后的完整门首次 run 20260923T060728633Z-p27292-a46077f3 在治理阶段真实失败：绝对路径检查把正则转义当作路径，Godot 步骤未执行。修复并保留磁盘/UNC 负例后，治理 21/21 通过；本地完整 run 20260923T061456741Z-p8340-ca5fdddc 通过 19/19、827/827、61 个加载事务检查、零 Godot 诊断及 Windows Debug 导出。受测来源是 50f4cf7 + 当时未提交的两项治理脚本修复，运行前后源指纹一致。随后提交 ddd2742 的 [exact Windows CI run 35827040265](https://github.com/T1doo/Capybara/actions/runs/35827040265)实际成功，GOV-007关闭。
- AG4 新身体补面保留清洁引用链、原尺寸和真 Alpha，独立检查允许其作为未批准局部毛面来源。原画布头/围巾宽遮罩的抬头探针暴露肩背斜接缝和围巾残影，已登记 ART3-006；它不能晋级动画或角色母图。[受控候选审查](../art/candidates/player_ag4_body_plate_v001/REVIEW.md)。
- 上批 05d1484 的 [exact Windows CI run 35829068210](https://github.com/T1doo/Capybara/actions/runs/35829068210)已成功。一次独立头层生成因尺度/位置漂移及边框Alpha异常拒绝。直接使用原AG4纹理的Godot网格小幅idle探针在本机Compatibility GPU真实家园场景通过运行，未发现前述明显硬接缝，但动作幅度与连续性仍未验收；[Stage 3 LOG](stages/stage-03/LOG.md)。
- 上批 aa612ef 的 [exact Windows CI run 35830878098](https://github.com/T1doo/Capybara/actions/runs/35830878098)已成功。Stage 3 UI已建立共用样板，真实GPU下暂停/设置双语与背包/储物箱可读；hover+pressed漏样式及1280px储物箱溢出先发现后修正。本地最终完整门 `20260923T075649746Z-p30628-1f5e27b3` 19/19、827/827、保存事务61项通过。UI实现提交 `a43248f` 已单分支推送，[对应exact Windows CI run 35834863552](https://github.com/T1doo/Capybara/actions/runs/35834863552)已实际success且headSha精确对应。仍缺正式9-slice/图标/字体、四分辨率与实体手柄门，CAP-0520仅in_progress。[UI方向](design/UI_STORYBOOK_V1.md)。
- 暂停文档检查点 `234ae3a` 的[exact Windows CI run 35835580503](https://github.com/T1doo/Capybara/actions/runs/35835580503)已实际success且headSha精确对应。供外部GPT复核的原快照资料与本机实景图放在忽略的 `build/review_packets/stage3_pause_20260923_234ae3a.zip`，未纳入Git；交接附件及隔离图没有放入压缩包。
- 恢复后在同一家园、同一相机与AG4比例下实际拍出晴晨/黄昏/雨天/夜晚四个Compatibility GPU技术视图。首轮CanvasModulate漏过unshaded绘本着色器：地面夜/晨亮度比1.0，失败保留；乘色层修正后五个固定样本比约0.48，夜窗局部暖光可见。本批dirty工作树完整门`20260923T094557263Z-p24164-bd4a4152`通过19/19、827/827、61事务项。[设计与边界](design/HOME_ATMOSPHERE_PROBE.md)。仅技术探针，ART3-102仍in_progress。
- 四氛围提交`9f99faf`的[exact Windows CI run 35845615402](https://github.com/T1doo/Capybara/actions/runs/35845615402)已success且headSha一致。随后小批次给桥/码头/水车木材加入共用柔化shader，原atlas不变；真实GPU各5镜头通过，局部木板纹理对比降低但重复结疤与结构仍未解决。本批dirty完整门`20260923T101123918Z-p37452-272a391c`通过19/19、827/827、61事务项，待实现提交的exact CI。[木材探针边界](design/SOFT_PAINTED_WOOD_PROBE.md)。ENV3-001仍进行中。
- 木材批次提交`e22b737`的[exact Windows CI run 35848659236](https://github.com/T1doo/Capybara/actions/runs/35848659236)与NPC首轮提交`9effef3`的[exact Windows CI run 35857952021](https://github.com/T1doo/Capybara/actions/runs/35857952021)均success且headSha精确对应。NPC四张纯文字首轮与唯一A父图的第二轮A2共5张真RGBA候选，哈希/四底/144px及A2父链检查通过；A/A2同尺度Compatibility实景已捕捉，A2笔触改善但俯角与可编辑四向结构仍未解决，所有PNG仍未批准。[NPC审查](../art/candidates/npc_river_residents_v001/REVIEW.md)。ART3-101 in_progress，无母图/四方向/日程。
- A2批次完整门首轮`20260923T135051531Z-p9768-7e20685f`在素材范围误判exit22，Godot未运行；GOV-008修正后完整重跑`20260923T142120826Z-p32320-c50accef`通过19/19、827/827、61事务项、角色负例26/26。受测为当时的`9effef3` + dirty修正，不冒充随后`51d463c`的exact CI；失败与成功均保留Stage3 LOG。
- A2暂停检查点`51d463c`已于恢复时安全单分支推送，[exact Windows CI run 36249512491](https://github.com/T1doo/Capybara/actions/runs/36249512491)已success且headSha一致。新UI 9-slice两轮手工SVG候选均512px真Alpha/精确来源并有实景截图，B仅技术shortlist，未批准或接入游戏。[UI框审查](../art/candidates/ui_storybook_frame_v001/REVIEW.md)。
- 本批UI整合门首轮`20260926T155247272Z-p14208-99456d1c`因检查器误收SVG在素材阶段exit22；GOV-009修正后`20260926T155650197Z-p47504-06a08ced`完整重跑通过19/19、827/827、61事务项及UI A/B重渲染。受测是`51d463c`+dirty变更；新实现提交的exact CI仍须单独核验。
- UI A/B实现提交`dfce033`的[exact Windows CI run 36254180422](https://github.com/T1doo/Capybara/actions/runs/36254180422)实际失败：干净检出的素材门在Godot导入前渲染SVG，缺类名缓存，原artifact已取回本地。调整统一本地门的执行顺序后，dirty本机run`20260926T163001149Z-p47464-a9fba8ae`通过19/19、827/827、61事务项；这只是修复过程的本机证据，远程结果见下一条。
- 修复提交`919c162`的[exact Windows CI run 36256258334](https://github.com/T1doo/Capybara/actions/runs/36256258334)已success且headSha一致，GOV-010关闭。官方OFL中文字体只在本机忽略build试用，299字形覆盖0缺失；小字较细，决定不接游戏。[字体候选审查](production/FONT_LXGW_WENKAI_V1_522_CANDIDATE.md)。
- 字体/CI文档检查点`f5fb86a`安全单分支推送成功（首次TLS握手失败，核远端后重试成功）；[exact Windows CI 36558684608](https://github.com/T1doo/Capybara/actions/runs/36558684608)已success且headSha一致。
- 本批玩家Blender v002重做可编辑结构，实际渲染4站立方向及下右18帧walk；固定35°/0.5比例，22张真RGBA无触边，已有四方向真实GPU家园图。原240移速/碰撞下两个周期36物理帧、64足底标记对比通过，最大漂移约0.000017px；前置夹具失败及修复保留。仍是平滑模型样件，未通过绘本视觉，不能据标记数学通过批准角色。完整dirty工程门`20260929T143238417Z-p44532-07c6636c`已19/19、827/827、61事务通过，新提交exact CI仍需另核；[审查和可重复源](production/PLAYER_MESH_V002_REVIEW.md)。
- 结构/步态批次本地commit`0a50dce`已保存，推送受上述TLS连接失败影响，不能声称有新远端CI。其后一次纯文字内置imagegen生成原创毛色笔触材质；同模型两轮混合尺度、4张Blender图与4张真实GPU图均实际完成，强档斑驳/弱档仍光滑，维持未批准。见[材质审查](../art/candidates/player_fur_gouache_v001/REVIEW.md)，没有游戏路径。本批完整dirty run `20260929T144738229Z-p38756-fdd256e8`已19/19、827/827、61事务通过；本机命令级HTTP/1.1只读Git连接已恢复，待显式push及新exact CI。
- 上述工程/技术门不批准角色母图，不证明实体手柄、完整动画、正式入口或 RC1。

## 下一动作

1. 完成毛色候选登记/检查的本地批次；网络恢复后只推安全分支并核验新exact CI，不把本地通过当成远程通过。
2. 聚焦代表方向的头脸/颊部结构与分区绘制，共同解决144px下模型感；两轮全局材质已暴露取舍，不再仅调全局噪点/纹理强度。保留已有相机/步幅校准。
3. 视觉样板通过后扩展八方向和连续idle/walk/pickup/soak，并继续NPC、正式UI矩阵、环境和玩法入口。原v2范围与240移速不变；[ISSUES](ISSUES.md)未结项仍有效。
