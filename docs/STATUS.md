# 当前恢复点

- observed_at: 2026-10-23
- safe_branch: codex/production-clean-20260916
- review_baseline: 79092c078c63c1e1d5a6d056ebcedf8401a9ac59
- 唯一工程：`E:\Capybara`；安全分支：`codex/production-clean-20260916`。
- 指定审阅祖先：`79092c078c63c1e1d5a6d056ebcedf8401a9ac59`；最近实现检查点：`5ed253870c34cebea6492c0aad74b99e9f68ac1b`。恢复时以实际Git为准，禁止回退有效后继或合入旧main/autonomous-v1。
- 最近有效实现证据：[5ed2538 exact Windows CI39919257839](https://github.com/T1doo/Capybara/actions/runs/39919257839)成功，已下载原始日志核对19/19、827/827、61事务、前后工作树干净/指纹相同。后继仅文档/证据检查点按实际Git/CI核验，不为写入自身SHA无限amend。原交接附件仍未跟踪，哈希未变。
- 产品阶段：Stage3进行中，Goal active；角色母图、路线、完整代表动作、NPC/环境/UI和正式入口未验收，RC1未完成。

## 当前批次

用户2026-09-29的外部审阅已完整读取；是源码/CI审阅，不是独立视觉签收。下一交付为同一版角色的连续walk、明显低头拾取、背侧转向及至少60秒真实Player序列，不以投射局部绿灯结束。

v004修正版64.08秒真实GPU片段已完成，3840物理帧位置误差0、真实拾取1，原240速度/碰撞保留；375姿态为该条轨迹专用库。evaluated surface机制12项、原图sRGB回传最大1色阶已实测。[精选审阅包](https://github.com/T1doo/Capybara/tree/9257d8db7df3d9f67371d87d52963e2f4ff1d583/docs/reviews/stage-03-v004)已推送，9项媒体匿名HTTP200回读且哈希全部一致；外部可取得，不声称已被独立视觉签收。

同源下右walk/pickup的[分层A/B首段](reviews/stage-03-v004/AB_REVIEW.md)已推送：16图层对68完整姿态，330帧重播位置误差0/拾取1；只用公开素材的新build目录复现成功。新增33项文件匿名HTTP200且全部哈希吻合，外部可取得。下一小样集中分层加必要转体替换的背侧转向；墙边身体探出、掠射覆盖/材质、自由输入/服装成本未解决，不批准母图或关闭Stage3。

## 证据入口与限制

- 当前任务/验收：[Stage3 PLAN](stages/stage-03/PLAN.md)；执行/失败/外审边界：[Stage3 LOG](stages/stage-03/LOG.md)。历史过程仅在LOG，不在此重复。
- [现有A/B审查](../art/candidates/player_animation_ab_v001/REVIEW.md)、[v002步态范围](production/PLAYER_MESH_V002_REVIEW.md)、[v003来源与限制](../art/candidates/player_v003_paintover_v001/REVIEW.md)。v002单方向0.6秒结果不是后继动画证据。
- [ISSUES](ISSUES.md)维护问题状态；GOV-011已关闭，复用既有PNG检查，不扩建治理。实体手柄未测，不阻止独立工作。
- 旧`build/review_packets/stage3_progress_20260929_3e28d1e.zip`只在本机生成，外部GPT未取得。新小型审阅媒体走已授权仓库渠道，原始AVI/.blend/完整PNG库仍只在build；不上传整个build或建立正式Release。

## 接下来

1. 64秒媒体与同源A/B已公开可取、实现exact CI已核验；不要重做这一批分发或把历史失败当当前阻塞。
2. 同源walk/pickup已完成；集中做少量分层加必要转体替换的背侧转向，修具体视觉失败并验证自由起停，再定最终路线。
3. 全14阶段102任务已实际对照v2及源码，未删未来范围；继续原Stage3及v2/RC1，不创建第二份backlog或工程。
