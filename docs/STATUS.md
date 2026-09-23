# 当前恢复点

> 用户已在 2026-09-23 明确继续。Stage 3 的完整质量门通过后，按此前约定保存证据并暂停，等待用户再次恢复；RC1 范围不变。

- observed_at: 2026-09-23T15:08:44+08:00
- safe_branch: codex/production-clean-20260916
- review_baseline: 79092c078c63c1e1d5a6d056ebcedf8401a9ac59
- observed_head: 05d1484ac872017a71ae97716fe10cd619439dac（本地与远程安全分支一致；本批拒绝样本记录和网格idle探针尚未提交）
- 产品 Stage：3，主角母图、正式场景/UI、四氛围和入口整合均未通过。

## 安全与已核对事实

唯一工程 E:\Capybara；当前分支从指定审阅提交的干净祖先链继续。旧本地 main/autonomous-v1/标签禁推禁合并。远程 T1doo/Capybara 为 public，当前身份 ADMIN；远程生产分支与本地 05d1484 一致。原交接附件仍未跟踪且保留。Git LFS fsck HEAD 通过，AG3/AG4及补面已提交 PNG 为 LFS 对象。

## 最近证据

- dd4af4b 的 exact Windows CI 35075003214 成功；实际 1200 秒 Stage 1 soak run 20260916T084039617Z-p43072-dd264577 通过：8378轮、2095转场/输入、524选择、20心跳、零诊断。[Stage 1 LOG](stages/stage-01/LOG.md)。
- Stage 3 本地 WIP 50f4cf7 的候选/来源专项通过：AG3→AG4→清洁 AG1 哈希链、真实 Alpha、清单状态，25/25 负向 fixture。A/B 两路线仅技术样件；正式绘本视觉审查仍失败。[独立审查](../art/candidates/player_animation_ab_v001/REVIEW.md)。
- 恢复后的完整门首次 run 20260923T060728633Z-p27292-a46077f3 在治理阶段真实失败：绝对路径检查把正则转义当作路径，Godot 步骤未执行。修复并保留磁盘/UNC 负例后，治理 21/21 通过；本地完整 run 20260923T061456741Z-p8340-ca5fdddc 通过 19/19、827/827、61 个加载事务检查、零 Godot 诊断及 Windows Debug 导出。受测来源是 50f4cf7 + 当时未提交的两项治理脚本修复，运行前后源指纹一致。随后提交 ddd2742 的 [exact Windows CI run 35827040265](https://github.com/T1doo/Capybara/actions/runs/35827040265)实际成功，GOV-007关闭。
- AG4 新身体补面保留清洁引用链、原尺寸和真 Alpha，独立检查允许其作为未批准局部毛面来源。原画布头/围巾宽遮罩的抬头探针暴露肩背斜接缝和围巾残影，已登记 ART3-006；它不能晋级动画或角色母图。[受控候选审查](../art/candidates/player_ag4_body_plate_v001/REVIEW.md)。
- 上批 05d1484 的 [exact Windows CI run 35829068210](https://github.com/T1doo/Capybara/actions/runs/35829068210)已成功。一次独立头层生成因尺度/位置漂移及边框Alpha异常拒绝。直接使用原AG4纹理的Godot网格小幅idle探针在本机Compatibility GPU真实家园场景通过运行，未发现前述明显硬接缝，但动作幅度与连续性仍未验收；[Stage 3 LOG](stages/stage-03/LOG.md)。
- 上述工程/技术门不批准角色母图，不证明实体手柄、完整动画、正式入口或 RC1。

## 下一动作

1. 审查拒绝头层记录与GPU网格idle探针，实际跑完整本地门并安全提交/单分支推送；新 SHA 的远程 CI 必须单独核验。
2. 按[Stage 3 PLAN](stages/stage-03/PLAN.md)推进：以现有原AG4与技术补面、网格探针为诊断源，做可编辑头/围巾/四足及真实连续idle/walk/pickup/soak。ART3-006未关闭；保持游戏当前240移动速度并实际测脚底漂移，再验证另外三个独立方向、八向移动。
3. 同批推进 NPC、统一 UI、环境四氛围与默认玩法入口；只有实景/输入/保存恢复/视觉门逐项通过才通过 Stage 3，届时暂停。
4. [ISSUES](ISSUES.md)保留实体手柄、后续 chunk/layer 和环境视觉缺口。历史失败、原型和本机 build 证据不被重写为正式验收。
