# Stage 1 — 开发日志

## 2026-09-16T15:35:34+08:00 · DOC-MIGRATE-stage-01 · 阶段记录迁移

- 来源类型：executed_now（仅文档迁移）；历史实现单独标为 historical_report。
- 受测基线：`79092c078c63c1e1d5a6d056ebcedf8401a9ac59` + 本次文档工作树改动；本条不声明游戏验证通过。
- 本轮交付：建立本阶段唯一 PLAN/LOG，保留原任务 ID、设计范围、证据和失败；[迁移映射](../stage-00-5/MIGRATION_MAP.csv)。
- 验证：本阶段原任务身份及依赖静态审查；统一检查与治理正负 fixture 由本批集成验证记录补充，不预写通过。
- Git：未提交的迁移工作树，最终 SHA 由后续检查点记录，避免自引用。
- 下一动作：见 [PLAN](PLAN.md#下一批执行顺序)。

## historical-records

来源类型：historical_report。来源基准 `79092c078c63c1e1d5a6d056ebcedf8401a9ac59`；旧本地实现 SHA 仅本地审计，不保证远程可达。历史原始日志/截图在被忽略的 build 中，本次未逐项验证可取性；原日期保留，旧条目未提供精确时刻/时区者记为未知。以下记录只描述当时覆盖范围，不作为新 HEAD、GPU/硬件或 RC1 通过证明。失败与修正均保留。

## 2026-08-30 — Stage 1 独立审查修复

Fixed
- SceneFlow 在同一会话缓存已访问区域，返回后保留拾取、资源次数、箱子和其他节点运行时状态。
- Main 退出时显式清理活动/缓存区域；错误根场景实例在拒绝时释放。
- 真实住宅地/林地集成测试先修改拾取、资源和箱子，再往返逐项验证状态保持。
- Player 持久保存 active task ID，InteractionSensor 刷新不再清空任务上下文。
- 传感器公共读取会清理已释放目标，候选退出树时立即注销；真实玩家多帧任务优先测试通过。
- SceneFlow 以单槽队列处理门请求；暂停期间保留请求和世界状态，恢复后只执行一次。
- 添加重复请求、paused frame 区域/位置保持和恢复后单次转场竞态回归。
- 重写 Stage 1 soak：每次门转场强制经过真实 Player/Sensor 目标与 E/A 输入入口。
- soak 动态构造真实碰撞重叠候选并反转加入顺序，持续验证任务/类型排序和区域状态。
- soak runner 添加目标时长加宽限 watchdog、进程树终止、UTC 唯一日志和工作量指标校验。
- 区域激活前拒绝空/重复 spawn 与 interaction ID，并释放错误根实例。
- 第二个 bootstrap 会自清理且不替换当前世界；空 spawn 门在交互层直接返回 Invalid。
- 输入设备仅响应按下且非 echo 的事件，最后手柄断开时自动回退键鼠提示。
- 未 pack 的空 PackedScene 在实例化前返回稳定错误，不再触发引擎诊断；测试失败总标题更新为 CAPYBARA。

## 2026-08-30 — Stage 1 调试覆盖层

Added
- 添加 F3 可切换调试覆盖层，显示区域、玩家状态/朝向、当前目标、输入设备和实例数量。
- 添加 `zh_CN` / `en` 调试字段本地化和 F3 默认输入映射。
- 自动测试覆盖显示内容与切换；真实窗口复核覆盖布局、F3 和暂停兼容。

## 2026-08-30 — Stage 1 正式 Soak 与审查闭环

Added
- 添加默认 1200 秒 Stage 1 soak runner，循环移动、门往返、暂停探测和运行时不变量。
- 流式保留每 60 秒心跳与日志；原生退出码、诊断扫描和 PASS marker 共同决定结果。
- 最终 `a9eb836` 正式运行 1200 秒：8378 循环、2095 次真实 E/A 转场、524 轮重叠候选、8378 次状态检查、20 心跳、零诊断。
- 两轮独立代码与 QA 审查关闭全部 Stage 1 Blocker/Critical/High；实体手柄继续登记为 `QA-001 / Not Verified`。

## 2026-08-30 — Stage 1 SceneFlow 与区域往返

Added
- 创建 WorldZone、WorldSpawnPoint 和 SceneFlowService，使用稳定区域/出生点 ID。
- 转场失败保留当前区域；区域场景含玩家节点时拒绝加载，保护单玩家不变量。
- 添加初始转场、往返、同区重定位、未知出生点和重复玩家测试。
- 将住宅地与林地拆为独立灰盒区域；主场景只保留持久玩家、UI 和区域容器。
- DoorInteractable 的 typed 请求通过延迟信号接入 SceneFlowService，住宅地/林地可双向往返。
- 真实主场景回归验证两个指定出生点、单活动区域和单玩家不变量。

## 2026-08-30 — Stage 1 输入设备提示

Added
- 创建 InputDeviceService，识别键鼠和手柄输入，只在设备类型变化时发出信号。
- 摇杆死区内的轻微漂移不会错误切换到手柄提示。
- 创建本地化交互提示，按最后输入设备显示 E 或手柄南键。

## 2026-08-30 — Stage 1 玩家状态与 8 方向 facing

Added
- 创建可测试的 Idle、Move、Interact、Disabled 玩家状态机和显式转换规则。
- 创建稳定的 8 方向 facing 值、向量和 ID 转换。
- 扩展真实玩家场景测试，覆盖状态互斥、交互/禁用移动阻断和 facing。

Changed
- 玩家移动现在驱动 Idle/Move 状态，并在非零输入时更新 8 方向 facing。
- 自动测试通过标记升级为全项目 `CAPYBARA TESTS PASSED`。

## 2026-08-30 — Stage 1 typed 交互协议基础

Added
- 创建 typed `InteractionContext`，携带 actor、位置、归一化 facing 和活动任务 ID。
- 创建 `InteractionResult`，区分 Success、Blocked 和 Invalid，并只传递稳定本地化 key。
- 创建 `InteractableComponent` 安全基类，定义稳定 ID、prompt、优先级和公共交互入口。
- 添加协议测试，覆盖有效/无效上下文、禁用原因和基类默认阻断。
- 创建确定性交互候选排序，固定任务匹配、类型优先级、朝向、距离和稳定 ID 的比较顺序。
- 将交互专项测试拆出主入口，保持测试文件职责和行数边界。
- 创建玩家 `InteractionSensor`，管理 Area2D 候选进入/离开、当前目标变化、prompt 和 typed interact 入口。
- 创建拾取物和资源点灰盒协议实现、几何场景及 E/手柄南键公共交互入口，不提前依赖背包。
- 创建床、箱子和门灰盒协议实现与几何场景，仅发出 typed 请求/最小状态，不提前实现时间、库存或场景流服务。
- 创建原创几何 NPC 灰盒协议实现，仅发出稳定 NPC/对话 ID，不提前实现关系、日程或任务系统。

- 历史检查表：Stage 1 第一批强制门；run `20260830T080600788Z-p23400-3d26af41`；0；43/43；Windows 导出并启动；`required_checks_satisfied=true`

- 历史检查表：Stage 1 typed 协议门；run `20260830T080921461Z-p1612-703e0422`；0；51/51；零泄漏诊断；Windows 导出并启动

- 历史检查表：Stage 1 候选选择门；run `20260830T081236950Z-p45044-28ebf28f`；0；57/57；确定性排序；Windows 导出并启动

- 历史检查表：Stage 1 玩家传感器门；run `20260830T081509675Z-p22892-10a1a477`；0；62/62；候选生命周期；Windows 导出并启动

- 历史检查表：Stage 1 拾取/资源门；run `20260830T081838224Z-p32036-fbee69fd`；0；73/73；typed payload 与耗尽；Windows 导出并启动

- 历史检查表：Stage 1 床/箱子/门门禁；run `20260830T082436050Z-p32304-359fd07c`；0；83/83；最小状态与 typed 请求；Windows 导出并启动

- 历史检查表：Stage 1 NPC 协议门；run `20260830T082733208Z-p40284-3efc5de4`；0；85/85；稳定 NPC/对话 ID；Windows 导出并启动

- 历史检查表：Stage 1 输入提示门；run `20260830T083335249Z-p45480-210e962e`；0；94/94；键鼠/手柄选择；Windows 导出并启动

- 历史检查表：Stage 1 输入提示窗口复核；当前 `Capybara (DEBUG)`；不适用；启动显示 `拾取 [E]`；按 E 后提示清除

- 历史检查表：Stage 1 SceneFlow 核心门；run `20260830T084158751Z-p36884-fae2aaa3`；0；111/111；失败转场回滚、稳定出生点与单玩家不变量；Windows 导出并启动

- 历史检查表：Stage 1 区域往返强制门；run `20260830T084653545Z-p15116-8475ed6b`；0；123/123；真实住宅地/林地门往返、指定出生点、单活动区域和单玩家；Windows 导出并启动

- 历史检查表：Stage 1 调试覆盖层强制门；run `20260830T084931068Z-p41080-54f12c80`；0；129/129；F3、本地化诊断内容和计数；Windows 导出并启动

- 历史检查表：Stage 1 调试覆盖层窗口复核；`Capybara (DEBUG)` 真实窗口；不适用；布局无关键遮挡；F3 隐藏/恢复；Esc 暂停与焦点正常；Player/活动区域均为 1

- 历史检查表：Stage 1 soak runner 早期短验证；`tools/run_stage_1_soak.ps1 -DurationSeconds 5`；0；初版 runner 的短验证历史；最终证据以后续正式 soak 为准

- 历史检查表：Stage 1 最终 clean 强制门；run `20260830T101336067Z-p43328-864878c0`；0；commit `a9eb836`；168/168；Windows 导出并启动；`required_checks_satisfied=true`；零诊断

- 历史检查表：Stage 1 最终正式 soak；`stage-1-soak-20260830T101359995Z-p7144-14111a30.log`；0；1200 秒；8378 循环；2095 inputs/transitions；524 selections；8378 state checks；20 心跳；零诊断

- 历史检查表：Stage 1 最终独立代码/QA 复核；两个只读复核任务；不适用；`a9eb836`：Blocker 0、Critical 0、High 0；实体手柄保持 `QA-001 / Not Verified`

- 历史任务 `CAP-0101`：原状态 `done`，原阶段 `1`；43 项回归覆盖纯逻辑与真实玩家场景。

- 历史任务 `CAP-0102`：原状态 `done`，原阶段 `1`；拾取物、资源点、床、箱子、门和 NPC 共用 typed 协议与选择器。

- 历史任务 `CAP-0103`：原状态 `done`，原阶段 `1`；94 项回归和真实键盘窗口提示通过；实体手柄见 QA-001。

- 历史任务 `CAP-0104`：原状态 `done`，原阶段 `1`；123 项回归覆盖住宅地/林地门往返、指定出生点与单玩家不变量。

- 历史任务 `CAP-0105`：原状态 `done`，原阶段 `1`；129 项回归与真实窗口验证 F3 隐藏/恢复、暂停兼容和单玩家/单区域计数。

- 历史任务 `CAP-0106`：原状态 `done`，原阶段 `1`；a9eb836: 1200s, 8378 cycles, 2095 real inputs/transitions, 524 overlapping selections, 8378 state checks, 20 heartbeats, zero diagnostics。

- 历史决定：DEC-014；2026-08-30；Stage 1 仅在同一会话缓存两个已访问灰盒区域实例以保持运行时状态；在存档/chunk 差量尚未建立前，先可靠保留拾取、资源和箱子状态；这是 Stage 1 过渡方案；Stage 2–4 必须迁移为稳定 ID 驱动的稀疏 runtime state/chunk delta，不能无界缓存大型世界；Accepted

- 历史决定：DEC-015；2026-08-30；门转场使用单槽 pending 队列，暂停期间不执行，恢复后仅执行一次；消除 E/A 与 Esc/Start 同帧竞态和重复请求叠加；SceneFlow 使用 ALWAYS 观察恢复；unconfigure 清空 pending；Accepted
