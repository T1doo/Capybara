# 当前恢复点

> 用户最新要求：立即暂停，改天再做。此前“完成Stage3后暂停”的执行安排已被这次即时暂停覆盖。等待用户明确恢复；Stage3和RC1均未完成。

- observed_at: 2026-09-16T17:50:56+08:00
- safe_branch: codex/production-clean-20260916
- review_baseline: 79092c078c63c1e1d5a6d056ebcedf8401a9ac59
- observed_head: dd4af4b808f2451cbd7efe0b3db10eb027d90efd（最后已推送实现；本地暂停检查点另行记录）
- 当前产品Stage：3，高品质美术基线与正式入口整合。
- 当前动作：已停止开发、素材生产和子代理，只保存恢复点；Goal工具最后读取仍active，不表示用户允许继续。

## 已完成且有证据

- 安全分支继承指定review；旧本地main/autonomous-v1与旧标签保留禁推。原用户附件未修改或提交。
- 接管文档14组PLAN/LOG及核心可靠性修复已提交。aa2b8ae精确CI35072291907成功；soak修复dd4af4b精确CI35075003214成功。
- 实际1200秒soak通过：run `20260916T084039617Z-p43072-dd264577`，8378cycles、2095transitions/inputs、524selections、8378state_checks、20heartbeats、零诊断。初始化回归ST1-006可据此关闭。[Stage1 LOG](stages/stage-01/LOG.md)。
- A/B技术样件：12个cutout及9个Blender代表帧，统一512/35°/pivot(256,384)/DR288像素；实际RGBA与GPU比较已运行。两条正式绘本视觉均未通过，不代表ART3-100完成。[审查](../art/candidates/player_animation_ab_v001/REVIEW.md)。
- AG3→AG4：原生RGBA及四底、本体144px、GPU静态比较；AG4下右静态独立B0/C0/H0/M1，仍technical_candidate，不是母图/游戏正式资产。[AG4审查](../art/candidates/player_ag4_v001/REVIEW.md)。

## 暂停时保留的未完成批次

当前素材/工具批次包括 `.gitattributes`、`.gitignore`、资产清单、AG3/AG4原图副本/提示词/审查、A/B最终SVG与制作脚本、QA/GPU夹具、新候选完整性检查器。已执行相关PNG、GPU、hash检查和25个候选正负例；**新资产检查器接入统一入口后的完整门尚未运行**，不得把之前19步通过套用成这批最新整合通过，也不得发布为Stage3通过。

暂停前清单：`build/takeover/20260916/pause-stage3/status-before.txt`、`untracked-sha256.json`、`tracked-diff-stat.txt`。原始生成与失败迭代、PNG/.blend和QA产物仍保留在被忽略的art/generated_raw及build；候选副本与脚本可进入本地恢复提交，暂停期间不push。

## 恢复顺序

1. 先检查真实Git HEAD/工作树，保护所有保留修改；确认本地WIP与远程dd4af4b差异。
2. 运行新资产门/格式/完整统一门，处理真实整合失败后再安全同步本批。
3. 继续AG4实景接地、隐藏结构补面、可编辑分层与连续动作。现有240移动速度与短足步态必须实际匹配，不能用慢速展示冒充正常移动下无滑步。
4. 完成四独立方向/八向运动、NPC/UI、环境统一/四氛围及正式入口保存恢复，才能通过[Stage3 PLAN](stages/stage-03/PLAN.md)。恢复后如用户没有另行改变范围，仍在Stage3完成处停下，不自动进入Stage4。

[ISSUES](ISSUES.md)保留真实视觉、实体手柄以及后续chunk/layer缺口。仅读文件或保存检查点不是阶段完成。
