# 当前恢复点

- observed_at: 2026-10-23
- safe_branch: codex/production-clean-20260916
- review_baseline: 79092c078c63c1e1d5a6d056ebcedf8401a9ac59
- 唯一工程：`E:\Capybara`；安全分支：`codex/production-clean-20260916`。
- 指定审阅祖先：`79092c078c63c1e1d5a6d056ebcedf8401a9ac59`；本批基线：`307aa46ed440330069b8143234d9ee5005ae3a84`。恢复时以实际Git为准，禁止回退有效后继或合入旧main/autonomous-v1。
- 最近已核验祖先：[307aa46 exact CI39919871695](https://github.com/T1doo/Capybara/actions/runs/39919871695)成功；下述v005为新批次，不能继承旧绿灯。原交接附件仍未跟踪，哈希未变。
- 产品阶段：Stage3进行中，Goal active；角色母图、路线、完整代表动作、NPC/环境/UI和正式入口未验收，RC1未完成。

## 当前批次

[v005实时混合候选](reviews/stage-03-v005/README.md)已完成新64秒GPU样板，不读旧轨迹/帧银行：八个精确朝向实际行走、背侧转向、起停/反向、真实拾取1次及受阻，原240速度/碰撞保留。84张运行纹理裁边后约6.35MiB。主要实现集中Blender共同源＋有界上半身替换＋实时四足，不再扩建轨迹银行。

完整-LiveHybrid源构建已在本机新目录实际通过；只用审阅副本的自动入口复跑1400tick也通过独立检查，自由分支180画面帧启动/退出诊断0。不是实体输入验收或另一台干净主机重测。当前审阅包待本批安全提交、远端CI和匿名回读；图像未获独立视觉批准。

附带修复ST2-020正式拾取物消耗/恢复后图形不同步：8项新断言先红2/835，修后835/835；最新源构建、录像与公开素材复跑都验证库存增量1且地面图形消失。数据格式/事务不变，不再由夹具单独隐藏。

最终本地run20261023T094005288Z-p69352-be2526a8已20/20、835/835、步态8组、61事务及Windows导出/启动通过，源指纹前后一致。受测307aa46+dirty；待提交后的exact CI及分发核验，不用旧绿灯代替。

## 证据入口与限制

- 当前任务/验收：[Stage3 PLAN](stages/stage-03/PLAN.md)；执行/失败/外审边界：[Stage3 LOG](stages/stage-03/LOG.md)。历史过程仅在LOG，不在此重复。
- [v005实测/限制](reviews/stage-03-v005/README.md)、[前序同源A/B](reviews/stage-03-v004/AB_REVIEW.md)、[共享技术决定](design/PLAYER_ANIMATION_V004_DECISION.md)。原始失败与旧版本范围在各LOG/审阅页，不在此重复。
- [ISSUES](ISSUES.md)维护问题状态；GOV-011已关闭，复用既有PNG检查，不扩建治理。实体手柄未测，不阻止独立工作。
- 仅精选审阅副本走已授权仓库渠道，原始AVI/.blend仍在build。不得把本机产物称外部送达，不上传整个build或建立正式Release。

## 接下来

1. 完成本批20项统一门（新增真实步态状态回归）、安全提交/推送、exact CI与公开回读；原有PNG治理不扩建。
2. 在已选技术实现上精修角色体块/笔触/脚掌与急反向，补其他方向pickup/soak；母图、NPC、环境/UI与正式入口仍待原Stage3门，不降低标准。
3. 全14阶段102任务已实际对照v2及源码，未删未来范围；继续原Stage3及v2/RC1，不创建第二份backlog或工程。
