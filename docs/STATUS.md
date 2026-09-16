# 当前恢复点

- observed_at: 2026-09-16T16:06:23+08:00
- safe_branch: codex/production-clean-20260916
- review_baseline: 79092c078c63c1e1d5a6d056ebcedf8401a9ac59
- observed_head: aa2b8aeb0bb0e3083c1166dd22091a7f6a091403（受测实现；本次仅文档暂停检查点另行提交）
- 产品 Stage：3；实际批次：Stage0.5文档/CI及Stage2可靠性整合已通过本地门，实现已提交并push；用户已明确恢复；Goal现场查询active，正在修复soak并继续Stage3。

## 安全与当前事实

唯一工程E:\Capybara；Godot4.7.2。生产线从review创建，旧本地main、codex/autonomous-v1与旧标签保留且禁止推送/merge回公开线。原9未跟踪文件SHA256保持，用户附件未修改/提交。远程T1doo/Capybara是public且ADMIN；02ac9b3已显式单分支push，祖先与LFS已核验。整合实现aa2b8ae已提交并显式push；仅原用户附件未跟踪。恢复必须先读git status/HEAD，不能盲切本页SHA。

[Stage0.5 PLAN](stages/stage-00-5/PLAN.md)：14组PLAN/LOG、原70ID完整保留、共100任务；29旧源迁移映射可审计。治理20正负例和SVG10检出/hash用例通过。

[Stage2 LOG](stages/stage-02/LOG.md#reliability-integration)：备份污染、装备重排、交互提交顺序已复现并修复；当前地图碰撞/连通安全落点与整体加载rollback通过，Stage4真正chunk/layer恢复尚未验证。

## 最新证据

- 本地run `20260916T080216355Z-p8148-b860280a`：19/19、827/827、61事务检查、零Godot诊断、Windows Debug导出/短启动，required=true。受测02ac9b3+dirty实现/治理工作树，前后指纹一致；不是exact commit。随后仅更新日志/任务状态，另跑治理/格式门。[验证说明](stages/stage-00-5/LOG.md#takeover-validation)。
- 保留失败：原基线run073251的SVG CRLF失败；远程02ac run35069530550/artifact10435003811在导入前脚本解析失败；整合run075728因runner354行失败。现已固定LF、前置导入并原样拆分测试职责，未删测试降门。
- 本地机器产物在build/logs及build/takeover/20260916（被忽略，不保证新检出可取）。aa2b8ae远程CI成功产物10436797343已下载核验，R-CI-01/02、R-DOC-01关闭。自动断言/headless/合成手柄/Debug不证明GPU、实体硬件、Release或RC1。

## 下一动作与缺口

aa2b8ae精确CI35072291907现已查询成功；soak初始化10秒与统一19步通过，先完成实际1200秒长测；同时继续[Stage3 PLAN](stages/stage-03/PLAN.md)的主角生产母图、动画A/B、NPC/UI、同场景四氛围及正式入口。Blender4.5.13官方便携包已校验并实际启动，ART3-004缺工具前置已解除，但比较尚未执行。[Stage3工具记录](stages/stage-03/LOG.md)。

[ISSUES](ISSUES.md)保留ST2-017后续chunk/layer、QA-001实体手柄以及ART3/ENV3视觉缺口。没有阻止全部本地开发的硬阻塞；没有通过Stage3或RC1，不因文档/CI完成停下。


## 当前执行批次

用户已恢复；上次暂停历史见Stage1 LOG。基线83409ac仅有用户原附件未跟踪。新soak初始化通过真实输入完成资源获取；当前10秒及完整run20260916T083458202Z-p40852-5e3d745c通过，1200秒仍待，不提前关闭ST1-006。新commit后继续长测和Stage3小规模动画方案准备。
