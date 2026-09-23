# 当前恢复点

> 用户已在 2026-09-23 明确继续。Stage 3 的完整质量门通过后，按此前约定保存证据并暂停，等待用户再次恢复；RC1 范围不变。

- observed_at: 2026-09-23T14:25:22.2144944+08:00
- safe_branch: codex/production-clean-20260916
- review_baseline: 79092c078c63c1e1d5a6d056ebcedf8401a9ac59
- observed_head: 50f4cf77b20969bcb8b67a5e8b67b59222715310（本地 WIP 基线；本次治理修复尚未提交）
- 产品 Stage：3，主角母图、正式场景/UI、四氛围和入口整合均未通过。

## 安全与已核对事实

唯一工程 E:\Capybara；当前分支从指定审阅提交的干净祖先链继续。旧本地 main/autonomous-v1/标签禁推禁合并。远程 T1doo/Capybara 为 public，当前身份 ADMIN；远程生产分支仍是 dd4af4b，本地领先一提交。原交接附件仍未跟踪，哈希与暂停清单一致。Git LFS fsck HEAD 通过，AG3/AG4 已提交 PNG 为 LFS 对象。

## 最近证据

- dd4af4b 的 exact Windows CI 35075003214 成功；实际 1200 秒 Stage 1 soak run 20260916T084039617Z-p43072-dd264577 通过：8378轮、2095转场/输入、524选择、20心跳、零诊断。[Stage 1 LOG](stages/stage-01/LOG.md)。
- Stage 3 本地 WIP 50f4cf7 的候选/来源专项通过：AG3→AG4→清洁 AG1 哈希链、真实 Alpha、清单状态，25/25 负向 fixture。A/B 两路线仅技术样件；正式绘本视觉审查仍失败。[独立审查](../art/candidates/player_animation_ab_v001/REVIEW.md)。
- 恢复后的完整门首次 run 20260923T060728633Z-p27292-a46077f3 在治理阶段真实失败：绝对路径检查把正则转义当作路径，Godot 步骤未执行。修复并保留磁盘/UNC 负例后，治理 21/21 通过；完整 run 20260923T061456741Z-p8340-ca5fdddc 通过 19/19、827/827、61 个加载事务检查、零 Godot 诊断及 Windows Debug 导出。受测来源是 50f4cf7 + 未提交的两项治理脚本修复，运行前后源指纹一致；新提交的 exact CI 尚未取得。
- 上述工程/技术门不批准角色母图，不证明实体手柄、完整动画、正式入口或 RC1。

## 下一动作

1. 审查治理修复 staged diff、LFS 和安全祖先；原子提交、显式单分支 push，核验新 SHA 的 Windows CI。
2. 按[Stage 3 PLAN](stages/stage-03/PLAN.md)推进：以 AG4 作为受控 DR 绘本质感锚点，补身体/颈/包下毛面、可编辑四足与连续动作；保持游戏当前 240 移动速度并实际测脚底漂移。随后验证另外三个独立方向、八向移动。
3. 同批推进 NPC、统一 UI、环境四氛围与默认玩法入口；只有实景/输入/保存恢复/视觉门逐项通过才通过 Stage 3，届时暂停。
4. [ISSUES](ISSUES.md)保留实体手柄、后续 chunk/layer 和环境视觉缺口。历史失败、原型和本机 build 证据不被重写为正式验收。
