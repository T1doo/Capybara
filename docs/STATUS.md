# 当前恢复点

- observed_at: 2026-10-23
- safe_branch: codex/production-clean-20260916
- review_baseline: 79092c078c63c1e1d5a6d056ebcedf8401a9ac59
- 唯一工程：`E:\Capybara`；安全分支：`codex/production-clean-20260916`。
- 指定审阅祖先：`79092c078c63c1e1d5a6d056ebcedf8401a9ac59`；最近干净检查点：`91c00f1d36808f42fb4c6d448940fc3d6bf11b58`。恢复时以实际Git为准，禁止回退有效后继或合入旧main/autonomous-v1。
- 最近有效远端证据：[91c00f1 exact Windows CI36590899032](https://github.com/T1doo/Capybara/actions/runs/36590899032)成功；该证据不覆盖下面的dirty批次。原交接附件仍未跟踪，哈希未变。
- 产品阶段：Stage3进行中，Goal active；角色母图、路线、完整代表动作、NPC/环境/UI和正式入口未验收，RC1未完成。

## 当前批次

用户2026-09-29的外部审阅已完整读取；是源码/CI审阅，不是独立视觉签收。下一交付为同一版角色的连续walk、明显低头拾取、背侧转向及至少60秒真实Player序列，不以投射局部绿灯结束。

在制：evaluated surface机制12项夹具通过，后背来源已登记。v004第一版64秒真实GPU片段已完成，但有腿部过伸；摆脚目标由错误的完整时长改为剩余时长后，正在生成修正版`build/art-pipeline/player_motion_v004/render_20261023_c`（恢复需查实际进程/产物，不按旧描述假定仍运行）。原240速度/碰撞保留；原图sRGB回传误差≤1色阶。样板尚未锁定路线或批准母图。

## 证据入口与限制

- 当前任务/验收：[Stage3 PLAN](stages/stage-03/PLAN.md)；执行/失败/外审边界：[Stage3 LOG](stages/stage-03/LOG.md)。历史过程仅在LOG，不在此重复。
- [现有A/B审查](../art/candidates/player_animation_ab_v001/REVIEW.md)、[v002步态范围](production/PLAYER_MESH_V002_REVIEW.md)、[v003来源与限制](../art/candidates/player_v003_paintover_v001/REVIEW.md)。v002单方向0.6秒结果不是后继动画证据。
- [ISSUES](ISSUES.md)维护问题状态；GOV-011已关闭，复用既有PNG检查，不扩建治理。实体手柄未测，不阻止独立工作。
- `build/review_packets/stage3_progress_20260929_3e28d1e.zip`只在本机生成，外部GPT未取得，不能称已对外交付。后续小型审阅媒体通过已授权仓库渠道提供可访问副本，不上传整个build或建立正式Release。

## 接下来

1. 完成v004修正版64秒GPU录制、关键帧/四向/四底/覆盖/四氛围审查及可访问分发。代码原子提交后核验exact CI。
2. 保存60秒GPU普通速度片段、少量关键帧、四底/覆盖/四氛围与复现入口；检查A/B真正可比项后作路线决定。
3. 校正文档职责与全阶段PLAN实际审计，结果写回原文件；继续原Stage3及v2/RC1范围，不创建第二份backlog或工程。
