# Stage 0.5 — 开发日志

## 2026-09-16T15:42:17+08:00 · CI-TAKEOVER-02 · 本地通过与干净CI新失败

- 来源类型：executed_now；关联AUT-0059/AUT-0062、R-CI-01/02。
- 本地验证：run `20260916T073558409Z-p43892-10837cab`，18/18、754/754、required_checks_satisfied=true、exit0、Windows Debug导出与短启动。已读取本机JSON和log核对计数；source为79092c078c63c1e1d5a6d056ebcedf8401a9ac59 + CI/存档修改的dirty工作树，运行中新增跨进程fixture，不能称为02ac精确提交全测。
- 证据位置：`build/logs/check_project-20260916T073558409Z-p43892-10837cab.json`与同名log；仅本机可取、build不入Git，干净检出须重新运行。
- Git：CI字节修复提交 `02ac9b37ed6eed7d8b12261c0d9772a30704d8f7`，显式单分支push成功。安全祖先仅02ac→79092c0→1731011，git lfs fsck HEAD通过；未推main/旧标签。
- 实际远程：run35069530550 / artifact10435003811对应02ac；SVG资产与10检出回归通过，svg_cutout_render退出20、166条class_name解析诊断。缺少全局类缓存时，导入之前执行依赖Autoload的Godot脚本会失败。不能把本地缓存环境绿灯当干净CI通过。
- 修复方向：主线程将引擎版本/导入放到所有Godot脚本前，workflow完整取历史供安全祖先验证；干净缓存回归及新exact SHA CI尚待结果，R-CI-01/02均不关闭。
- 文档静态复核：14 PLAN/LOG、100任务，其中原70ID无丢失；原依赖已重排，独立治理实际读取新文档schema/任务图/历史证据/索引/链接通过，其余工具消费者正在同批集成，不提前声明统一门完成。
- 下一动作：干净缓存/统一门与exact SHA CI；继续Stage2可靠性组合回归，不把治理视为终点。

## 2026-09-16T15:35:34+08:00 · DOC-MIGRATE-stage-00-5 · 阶段记录迁移

- 来源类型：executed_now（仅文档迁移）；历史实现单独标为 historical_report。
- 受测基线：`79092c078c63c1e1d5a6d056ebcedf8401a9ac59` + 本次文档工作树改动；本条不声明游戏验证通过。
- 本轮交付：建立本阶段唯一 PLAN/LOG，保留原任务 ID、设计范围、证据和失败；[迁移映射](../stage-00-5/MIGRATION_MAP.csv)。
- 验证：本阶段原任务身份及依赖静态审查；统一检查与治理正负 fixture 由本批集成验证记录补充，不预写通过。
- Git：未提交的迁移工作树，最终 SHA 由后续检查点记录，避免自引用。
- 下一动作：见 [PLAN](PLAN.md#下一批执行顺序)。

## historical-records

来源类型：historical_report。来源基准 `79092c078c63c1e1d5a6d056ebcedf8401a9ac59`；旧本地实现 SHA 仅本地审计，不保证远程可达。历史原始日志/截图在被忽略的 build 中，本次未逐项验证可取性；原日期保留，旧条目未提供精确时刻/时区者记为未知。以下记录只描述当时覆盖范围，不作为新 HEAD、GPU/硬件或 RC1 通过证明。失败与修正均保留。

## 2026-09-16 — 公开安全审阅快照

- 用户要求先推送当前整体进度供GPT审阅，本轮不扩展新功能。
- 实际验证Git凭据/集成可用且远程为public；发现旧C1/D1图像仍可从开发历史到达，记录GIT-002并禁止直接公开原历史。
- 准备当前完整tree的独立审阅分支，保留本地历史，不改main、不推标签、不强推；增加明确区分原型、实际游戏循环和最终目标的REVIEW_HANDOFF。

## 2026-08-30 — Stage 0.5 自治治理与恢复

Added
- 纳入长期目标契约，创建 `PLANS.md`、自治状态、质量门、已知问题、发布准备、依赖和恢复文档。
- 创建治理/backlog 校验、全仓库格式/lint、Windows 导出并启动烟雾脚本。
- 建立 Windows 2022 CI，固定 GitHub 官方 action commit、Godot 编辑器和导出模板 SHA256。
- 为每次统一检查生成唯一 run 日志与 JSON，并记录宿主、branch、commit、超时、诊断和失败原因。

Changed
- 将旧四区域/小型路线更新为 8 个手工地区、分块流送和确定性程序化外围的 RC1 路线。
- 更新技术与美术规范为大型世界、高分辨率非像素绘本 2D/2.5D 和角色方案 A/B 实测。
- 旧 Stage 0 启动文件全部标记为历史停用；AI 资产与 QA 流程不再设置常规人工等待门。
- 自动化明确要求 PowerShell 7，恢复命令统一使用 `pwsh -NoProfile -File`。

Fixed
- 修复 Godot 输出 ERROR/WARNING 但原生退出码为 0 时的检查假绿。
- 修复并行检查交织 latest 日志、覆盖失败 JSON 的问题。
- 修复 staged/untracked/CI clean checkout 的格式检查盲区和 backlog 逆向依赖。
- 修复 CI 未校验下载内容、未安装导出模板和只导出不启动构建的问题。

Known Issues
- GitHub CLI 认证失效，远程可见性、push 和首次真实 CI 运行待 `GIT-001` 关闭；本地开发不停止。
- 实体手柄人工回归仍登记为 `QA-001`。

## 2026-08-30 — 规划包 v1.0

- 建立游戏设计、技术设计、美术规范、AI 素材流程、路线图、QA、Steam、营销和权利政策。
- 固定初始技术路线为 Godot 4.7.2 Standard + 静态类型 GDScript。
- 固定首版范围：单人、Windows/Steam、无战斗、无联机、无运行时 AI。
- 将水体改造确定为核心差异化系统。

- 历史检查表：Windows 构建烟雾；`REQUIRE_WINDOWS_BUILD_SMOKE=1` 的统一检查；0；官方模板 SHA256 匹配；debug 导出成功；EXE 实际启动 10 帧

- 历史检查表：Stage 0.5 强制门；run `20260830T075751611Z-p30944-9e547673`；0；`required_checks_satisfied=true`

- 历史任务 `AUT-0050`：原状态 `done`，原阶段 `0.5`；目标契约和 7 个历史入口边界已验证。

- 历史任务 `AUT-0051`：原状态 `done`，原阶段 `0.5`；恢复顺序和当前状态已建立。

- 历史任务 `AUT-0052`：原状态 `done`，原阶段 `0.5`；依赖和恢复文档一并纳入治理门。

- 历史任务 `AUT-0053`：原状态 `done`，原阶段 `0.5`；含超时、诊断、格式、cached diff 与并发安全。

- 历史任务 `AUT-0054`：原状态 `done`，原阶段 `0.5`；固定 SHA256 与 windows-2022；远程实跑待 GIT-001。

- 历史任务 `AUT-0055`：原状态 `done`，原阶段 `0.5`；恢复文档和待同步策略已验证。

- 历史任务 `AUT-0056`：原状态 `done`，原阶段 `0.5`；两个只读审查完成且发现已修复。

- 历史任务 `AUT-0057`：原状态 `done`，原阶段 `0.5`；本地 481a140 已建立；push 受 GIT-001 影响并已记录。

- 历史决定：DEC-011；2026-08-30；Stage 0 后采用目标契约 v2 的持续自治与 Git 分支策略；中断后可恢复，并让 `main` 只承载通过 Stage 质量门的稳定版本；使用 `codex/autonomous-v1`、原子 commit、Stage tag、非强制安全 push；Accepted

- 历史决定：DEC-013；2026-08-30；统一检查生成文本/JSON 证据，CI 使用 Windows runner、官方 Godot 4.7.2 和锁定 GitHub 官方 actions；保证本地与 CI 使用同一质量入口并降低供应链漂移；日志进入忽略的 `build/logs`；CI 失败阻止 Stage 合并；Accepted

## 2026-09-16T15:35:34+08:00 · TAKEOVER-BASELINE · 接管实测失败与迁移审计

- 来源类型：executed_now；受测source `79092c078c63c1e1d5a6d056ebcedf8401a9ac59`，基线工作树含原未跟踪用户文件，原hash由主线程保护。
- 运行：Windows / Godot4.7.2，统一检查run `20260916T073251372Z-p43016-602f2eaa`，art_asset_pipeline退出22；SVG工作树CRLF与LF清单hash不同。后续Godot断言/导出未执行；不沿用历史752作为本轮通过。
- 远程：沙箱外已核验T1doo/Capybara public、ADMIN及main/review refs；沙箱内凭据失败不是实际失效。安全线从指定review建立，旧开发/main/tag保留禁推。本记录不宣称新线已push/CI通过。
- 文档：14个PLAN/LOG；原70任务身份全部保留，CAP-0540移至授权外测并由Stage3/5内部实玩解锁生产，时间/环境条件/NPC设施/基础音频前置Stage5；远期v2每阶段范围保留，治理checker与脚本消费者由同批集成修改。
- 旧聚合稿逐行与模块化源比对：额外行均是被v2覆盖的旧上限/禁令/估时、旧CSV状态或封面/附录格式，无独有待实现系统遗漏。所有DEC-001–033保留Stage归属，DEC-011旧分支策略以新安全线取代；OPEN-004同步英文已由v2明确。
- PACKAGE_MANIFEST.json是Capybara Codex Starter Pack — E Drive Edition v1.1 / 2026-08-30，24文件的原ZIP清单，scope_note明确不是当前仓库manifest；审计原文位于上述基准，不影响资产manifest和构建manifest。
- 删除/去向/保留独有信息逐文件见[MIGRATION_MAP](MIGRATION_MAP.csv)，源仅删除Git已跟踪可恢复文本；用户交接附件与未跟踪独有文件未删除。
- 验证限制：此检查点尚未运行集成新治理门，迁移/CI任务保持in_progress；最终正负门与统一检查由后续日志补实际run。
- 下一动作：完成R-CI-01/治理同批验证后继续Stage2可靠性修复及Stage3生产，不在文档整理停下。


## takeover-validation

- 时间：2026-09-16T16:05:32+08:00；来源类型：executed_now。任务AUT-0058/0060；R-CI-01/02仍等待新提交完整CI。
- 安全接管：原9个未跟踪文件SHA256逐项保持；审阅tree/父提交吻合；安全线只含1731011→79092c0→02ac9b3，已显式单分支push、LFS fsck通过，无旧祖先/标签推送。
- 文档迁移：14个PLAN/LOG，原70任务无丢失、现100唯一任务、依赖无环；29旧源映射及blob摘要见MIGRATION_MAP.csv。额外明确前哨营地、家具变体、水域玩家状态与按住/切换辅助的任务归属。
- 新治理20正负fixture通过，10实际Git检出/hash拒绝用例通过。全部3个manifest脚本消费者与码头审查历史入口同步。
- 新CI顺序：Godot版本/导入前置脚本执行；现场保留旧缓存到build后冷导入及SVG渲染均退出0无诊断。workflow完整历史用于安全祖先检查。
- 统一门：run `20260916T080216355Z-p8148-b860280a`，19/19，827/827，61事务检查，零diagnostics，Windows Debug导出/短启动，required_checks_satisfied=true。受测base `02ac9b37ed6eed7d8b12261c0d9772a30704d8f7` + 本次文档/可靠性工作树；源码前后fingerprint一致：`3385f2cfec0826d818d26fc91d66a045dac5e0ab831055e2fa107df1dc264da5`。不是exact commit或GPU/实体硬件验收。
- 保留失败：run `20260916T075728619Z-p41992-4cea34bf` 在格式门因runner354行失败，后续游戏检查未执行；将原移动/方向/状态机断言原样拆至player_logic_test_cases后重跑通过，未删除断言/降低350行门。
- 新JSON schema3记录source_before/after、dirty、差异+未跟踪内容指纹；中文文件名NUL解析实际fixture通过。这是端点一致性检查，不声称连续监控。
- 产物在本机忽略build/logs与build/takeover/20260916，不随源码上传；CI产物另由exact SHA run索引。此条后的Markdown状态调整只跑文档/格式门，不冒称同一fingerprint。
- 下一动作：原子提交迁移与可靠性代码；精确HEAD CI验证后推进Stage3母图/动画A-B/UI/四氛围/正式入口。


## 2026-09-16T16:39:06+08:00 · clean-ci-confirmed

- 来源类型：executed_now。恢复后实际查询并下载CI产物：run35072291907，job104716383753，artifact10436797343（未过期），exact SHA `aa2b8aeb0bb0e3083c1166dd22091a7f6a091403`，结论success。
- Windows新检出JSON run `20260916T081021447Z-p1360-b2d1f3f3`：19步全部通过，required=true，source_before.dirty=false且指纹前后一致。Godot导入、资产10检出用例、治理20正负例、游戏回归、61加载事务和Debug导出启动都在同提交覆盖。
- 本机已下载至build/takeover/20260916/ci-aa2b8ae；公开日志入口https://github.com/T1doo/Capybara/actions/runs/35072291907 。据此关闭R-CI-01/02与迁移R-DOC-01；不代表后续soak或Stage3视觉门通过。
## 2026-09-23T14:24:38.1705864+08:00 · GOV-007-REPAIR · 治理路径检查误报修复

- 来源类型：executed_now。受测基线为50f4cf77b20969bcb8b67a5e8b67b59222715310加tools/check_governance.ps1与tools/test_governance.ps1工作树改动。
- 首次完整run 20260923T060728633Z-p27292-a46077f3在governance退出10：新候选工具的正则路径字符被当成UNC绝对路径；游戏/导出步骤未执行。中间修订又把visual_review_status中的s:\s识作盘符，失败记录保留。
- 修复后要求盘符字母前有非标识符边界，并要求UNC包含合法主机与共享名；保留E:\Capybara和\\server\share的真实负例。治理21/21通过，14阶段/102任务图有效。
- 最新本地完整run 20260923T061456741Z-p8340-ca5fdddc：19/19、827/827、61加载事务检查、零Godot诊断、Windows Debug导出与短启动，required=true；源指纹前后一致。本次为dirty worktree，仍待实现提交的exact SHA远程CI，AUT-0063暂不标done。
- 素材专项也已实际通过：AG3/AG4完整性、清洁引用链、SVG检出10例、新候选25/25负例与格式405文件。通过的是技术/来源门，AG4母图及Stage3视觉门仍开放。
- 下一动作：仅将本批必要修复与恢复文档原子提交、安全单分支push；核验exact SHA CI后回到Stage3的可编辑角色分层和环境整景。

## 2026-09-23T14:46:10+08:00 · AUT-0063-CLOSE · exact CI 核验

- 来源类型：executed_now。修复提交 `ddd27422d8688db851b43f93ccb810b8ba2fb65a` 沿指定 review 的安全祖先链正常推至 `codex/production-clean-20260916`，无强推/旧标签传播。
- [Windows run 35827040265](https://github.com/T1doo/Capybara/actions/runs/35827040265) 的 `headSha` 精确等于 ddd2742，`Godot 4.7.2 / Windows` 及其中 `Run unified checks`、`Upload check logs` 均 conclusion=success。此为远程 exact SHA 证据；本地先前脏树 run 20260923T061456741Z-p8340-ca5fdddc 仍按当时来源单独保留。
- `GOV-007` 与 `AUT-0063` 关闭；不据此声称 Stage 3 美术或正式入口通过。
