# 当前恢复点

> 用户已在 2026-09-26 明确恢复续开发。Stage 3 尚未完成，原v2契约与RC1范围不变。

- observed_at: 2026-09-27T00:00:17+08:00
- safe_branch: codex/production-clean-20260916
- review_baseline: 79092c078c63c1e1d5a6d056ebcedf8401a9ac59
- observed_head: 51d463cbb736884db8bf13e829189dd73f0bcda6（本地与远程安全分支一致；UI框A/B候选仍为dirty工作树）
- 产品 Stage：3，主角母图、正式场景/UI、四氛围和入口整合均未通过。

## 安全与已核对事实

唯一工程 E:\Capybara；当前分支从指定审阅提交的干净祖先链继续。旧本地 main/autonomous-v1/标签禁推禁合并。远程 T1doo/Capybara 为 public，当前身份 ADMIN；远程生产分支与本地 51d463c 一致。原交接附件仍未跟踪，SHA-256 `72ab12633bd4f9a585d502ee1dcf9aa34526e9e0ec3472882d5e159d39e5f3b1`未变化。Git LFS fsck HEAD 通过，AG3/AG4、补面及NPC PNG已提交为LFS对象。

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
- 上述工程/技术门不批准角色母图，不证明实体手柄、完整动画、正式入口或 RC1。

## 下一动作

1. 本批先跑完整门并安全提交/显式单分支push手工UI A/B候选及验证器；核新SHA的exact CI，不以两张面板截图批准正式UI。
2. 针对B的矢量感、四分辨率/实体手柄和图标字体做下一轮设计/审查，符合正式资产工作流后才接游戏Theme；UI3-004仍开放。
3. 继续NPC-A/A2可编辑结构/转面、玩家AG4可编辑四足及真实连续idle/walk/pickup/soak、环境与正式玩法入口；保持240移动速度，缺独立视觉/QA前不宣称Stage3通过。[ISSUES](ISSUES.md)保留未结项。
