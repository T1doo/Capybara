# Stage 2 — 开发日志

## 2026-09-16T15:42:17+08:00 · SAVE-RECOVERY-01 · 备份污染复现与隔离失败再审

- 来源类型：executed_now（主线程实际运行报告）；关联ST2-R001 / R-SAVE-01，当前工作树基于79092c078c63c1e1d5a6d056ebcedf8401a9ac59，CI提交02ac9b37ed6eed7d8b12261c0d9772a30704d8f7之后存档修复仍未提交。
- 修复前最小回归：1/754失败，证据 `build/takeover/20260916/save-regression-before.log`，由首次backup回退延伸到再保存/再次主损坏，证实最后好恢复点可能被语义坏main覆盖。
- 初步修复：把运行时不可应用main持久隔离为.json.rejected，防止下次保存将它轮换到backup。独立seed/recover/save/verify进程及temp写、rotate、commit、isolate失败注入初轮通过，报告 `build/takeover/20260916/save-recovery-after.log`。
- 独立审阅发现：隔离操作失败后直接save的组合仍可污染backup，主线程继续加固，不因专项初轮通过关闭问题。ST2-R002快捷栏语义也已进入实现。
- 证据边界：上述路径仅本机build产物，不保证公开CI可取；保存原始失败，最终再次验证/commit由后续条目记录。没有实体手柄、全流程GPU或RC验收结论。
- 下一动作：隔离失败→直接save及跨进程的可靠拒绝/隔离策略与回归；随后快捷栏/提交反馈/安全落点。

## 2026-09-16T15:35:34+08:00 · DOC-MIGRATE-stage-02 · 阶段记录迁移

- 来源类型：executed_now（仅文档迁移）；历史实现单独标为 historical_report。
- 受测基线：`79092c078c63c1e1d5a6d056ebcedf8401a9ac59` + 本次文档工作树改动；本条不声明游戏验证通过。
- 本轮交付：建立本阶段唯一 PLAN/LOG，保留原任务 ID、设计范围、证据和失败；[迁移映射](../stage-00-5/MIGRATION_MAP.csv)。
- 验证：本阶段原任务身份及依赖静态审查；统一检查与治理正负 fixture 由本批集成验证记录补充，不预写通过。
- Git：未提交的迁移工作树，最终 SHA 由后续检查点记录，避免自引用。
- 下一动作：见 [PLAN](PLAN.md#下一批执行顺序)。

## historical-records

来源类型：historical_report。来源基准 `79092c078c63c1e1d5a6d056ebcedf8401a9ac59`；旧本地实现 SHA 仅本地审计，不保证远程可达。历史原始日志/截图在被忽略的 build 中，本次未逐项验证可取性；原日期保留，旧条目未提供精确时刻/时区者记为未知。以下记录只描述当时覆盖范围，不作为新 HEAD、GPU/硬件或 RC1 通过证明。失败与修正均保留。

## 2026-09-03 — Stage 2 合并与 Stage 3 启动

Milestone
- Stage 2 以本地 merge `25efe67` 合入 `main`，创建注释标签 `capybara-stage-02`；因 `GIT-001` 未执行 push。
- 开发分支快进到稳定点并进入 Stage 3 高品质视觉原型。

Added
- 建立 `player_capybara_v1` 主角概念首轮 brief，固定六个高差异方向、命名、禁止项、实际尺寸与原创性验收。

## 2026-09-03 — Stage 2 终审边界修复

Fixed
- 世界存档从“只覆盖已列出项”改为完整状态替换：保存捕获全部注册区域，读取时以 fresh 场景默认补全缺失区域和交互，再统一应用。
- 多产出资源先模拟整批加入；背包只能部分接收时 Inventory 与 Resource 均不变，完整接收时才扣一次 use。

Verified
- 616/616：覆盖 Home 保存后访问/修改 Grove 再加载旧档、缺失 Pickup entry 恢复默认、精确 yield=5/available=1 的 partial/full 容量守恒。
- exact clean run `20260903T041100794Z-p23616-cf38b6eb` 与 `c7f91fe` 精确匹配；两位独立终审均为 Blocker/Critical/High 0/0/0，并批准 Stage 2 merge/tag。

## 2026-09-03 — Stage 2 独立复审完整修复

Fixed
- 五个核心 modal 启用焦点跟随；4×3×5 矩阵在真实 24×32 Storage 内容上逐一验证末端控件自动滚入视口。
- 高对比目标改用可传递给可见子图形的父级调制；世界提示从 InputMap 动态显示 F/X 等实际绑定。
- 半推摇杆规范化为 ±1；快捷栏前后加入 9 动作重映射；键盘 modifier、设备和事件范围与 codec 对齐。
- 资源采集要求芦苇铲并以背包成功转入量提交消耗；零转入不扣次数。
- Save v1 增加 `zone_id + interaction_id` 拾取/资源差量，三进程走真实拾取和采集后验证重开不可重复获取。

Changed
- 设置/存档跨进程 fixture 使用 GUID 唯一路径并检查清理；设置读进程验证 TranslationServer、UI scale、InputMap、Camera 与精确事件值。
- Storage UI 响应模型替换；ContentRegistry 锁定运行时集合并向调用者返回定义副本。
- 存档转场在发出 `zone_changed` 前设置最终恢复位置，监听器不再观察临时 spawn。

Verified
- 专项自动回归 608/608；设置与游戏存档三进程入口通过。
- 正式 SettingsScreen/SettingsService 在隔离设置下完成 1280×720 窗口→全屏→窗口→1280×800 真实往返，布局完整且 fixture 清理。

## 2026-09-03 — Stage 2 辅助功能消费者与显示矩阵

Added
- 新增 AccessibilityService，统一消费减少动态、手柄震动和高对比交互设置。
- 成功交互按当前活动手柄 ID 请求短震动；测试可替换平台分发器，不依赖实体硬件制造假通过。
- 新增四分辨率×三缩放×五个核心 modal 的响应式布局矩阵和可复用视觉 fixture。

Changed
- 减少动态会禁用相机平滑；高对比会强化交互提示文字、轮廓和当前世界目标。
- 暂停、设置、按键重映射、背包和储物统一使用双轴响应式滚动，在高缩放小窗口仍可到达全部内容。

Verified
- 526/526 自动回归通过；1280×720 / 150% 设置与储物真实窗口无不可达内容，高对比交互提示和目标可观察。

## 2026-09-03 — Stage 2 正式存档入口与恢复提示

Added
- 暂停菜单新增正式保存、读取和本地化结果提示，使用独立默认槽位 `user://saves/slot_01`。
- 新增生产路径回归：真实暂停菜单保存、语义损坏 main 自动回退 backup、双损坏失败保持运行时不变。
- 新增隔离视觉 fixture；856×511 真实窗口完成键盘焦点、保存和读取反馈复核，关闭后清理 fixture 文件。

Fixed
- `load_and_apply` 现在把结构读取、运行时预检和完整应用视为同一候选事务；main 任一步不可应用时才尝试 backup。
- 读取成功后保持暂停菜单对暂停状态的所有权，失败时不会部分改变区域、玩家位置或背包。

## 2026-09-03 — Stage 2 背包操作与工具上下文

Added
- 背包新增格位选择、拆分一半、分配到当前快捷栏、二次确认丢弃、任务物品拒绝提示和整理入口。
- 新增原创灰盒芦苇铲 ItemDefinition 与住宅地拾取；工具不可堆叠并使用稳定 ID。
- Q/R 与手柄肩键切换 Hotbar；选中的 TOOL 进入 InteractionContext，资源结果记录实际工具 ID。
- 世界拾取改为 Inventory 接受后再提交数量，背包满时不会先禁用并吞掉物品。
- 跨进程 Save fixture 验证非默认 Hotbar 工具映射和装备恢复；自动门增至 386/386。

Verified
- 856×511 真实窗口完成树枝拆分、芦苇铲分配、二次丢弃和整理合并，所有 24+8 格与操作按钮完整可见。

## 2026-09-03 — Stage 2 独立审查首批 High 修复

Fixed
- Settings main 损坏或缺失时验证并恢复 backup；只轮换有效 main，双损坏保持当前设置。
- 输入重映射捕获移至 GUI 前 `_input`；暂停状态下存档恢复保留 pause 并取消陈旧转场。
- InventoryTransfer 在工作模型上完成事务，双侧静默提交最终快照后才通知监听器。
- Save validator 拒绝非有限玩家坐标和非 8 格 Hotbar；测试 fixture 显式关闭 Windows 文件句柄。

Changed
- 独立 QA 发现三个 Stage 2 合同级 High 仍开放；撤回过早完成的质量门，High 清零前不 merge/tag。

## 2026-09-03 — Stage 2 游戏存档跨进程恢复门

Added
- 新增 Save v1 三进程 fixture：写入、全新进程读取应用、清理隔离存档。
- 读取进程先切到林地并制造不同内存状态，再恢复住宅地 spawn、精确位置、up_left 朝向、Inventory、Hotbar 与 Storage。
- 新增 `tools/check_save_restart.ps1` 并纳入统一门；正常玩家存档不受测试影响。

## 2026-09-03 — Stage 2 Storage 双栏 UI

Added
- 新增 24 格玩家背包与 32 格 Storage 双栏界面，支持焦点导航、整组双向转移、Back/背包键/Esc 关闭。
- Bootstrap 通过 typed `InteractionResult` 和稳定 `storage_id` 打开对应模型；关闭 UI 同步复位箱子打开状态。
- 新增可复用 Storage 视觉 fixture；856×511 真实窗口完成 Enter 转入、点击转回和 Esc 关闭复核。

Fixed
- 修复完整搬空源槽后读取已清空 `item_id` 导致 `INVENTORY_TRANSFER_ROLLED_BACK`；事务现在在变更前捕获稳定物品 ID。

## 2026-09-03 — Stage 2 设置跨进程恢复门

Added
- 新增独立 Godot fixture：一个进程写入隔离设置，第二个全新进程读取验证，第三个进程清理。
- 跨进程验证英文、125% UI、0.37 主音量、关闭镜头平滑以及键盘/手柄复合绑定。
- 新增 `tools/check_settings_restart.ps1` 并纳入统一项目门；正常 `user://settings.cfg` 不受测试影响。

## 2026-09-03 — Stage 2 本地化完整性门

Added
- 新增 `tools/check_localization.ps1`，验证 catalog 键唯一、`en/zh_CN` 非空和正式引用完整解析。
- 动态输入动作键显式纳入检查；测试 fixture 排除在正式内容扫描边界之外。
- `tools/check_project.ps1` 与治理检查强制执行本地化门；当前 84 个双语键和 64 个引用全部通过。

## 2026-09-03 — Stage 2 输入重映射

Added
- 新增独立按键设置页，7 个可重映射动作分别提供键盘与手柄槽位，并保持小窗口完整布局。
- 捕获一类设备时保留另一类设备绑定；恢复默认会清空覆盖并重建 WASD/方向键、摇杆/十字键和菜单动作。
- 自动回归增至 341/341，覆盖 draft、不持久化取消、默认恢复、焦点返回和逻辑键码显示。

Fixed
- 真实窗口捕获 F 时曾把硬件扫描码误解释为 `Pause`；显示现在优先使用逻辑 `keycode`，缺失时才回退物理码。

## 2026-09-03 — Stage 2 Settings 运行时与菜单

Added
- SettingsService 将 Master/Music/SFX 音量、窗口模式、分辨率、UI 缩放、语言和自定义输入事件应用到运行时。
- Player 订阅 typed 设置变更信号并实时切换 Camera2D 平滑。
- 暂停菜单新增本地化设置入口；设置页提供语言、显示、分辨率、缩放、三类音量和基础辅助选项。
- 自动回归增至 331/331，覆盖运行时应用、音频总线、相机通知、暂停 modal、焦点返回与 1280×800 高度。
- 真实 Windows 窗口完成中英切换、纯键盘正反向焦点、应用与 Esc 返回复核；两种语言均无裁切。

## 2026-08-30 — Stage 2 Settings 数据与独立持久化

Added
- 创建版本化 SettingsProfile，覆盖音量、显示、UI 缩放、语言、镜头、震动、文字和减少动态效果等辅助选项。
- SettingsCodec 严格验证受支持的分辨率、缩放档位、语言与数值范围，并编解码键盘、手柄按键和摇杆事件。
- SettingsService 独立使用 `user://settings.cfg`，以 temp 写入、重读校验、备份轮换和 rename 提交；不混入游戏存档。
- 19 项设置回归覆盖 round-trip、输入绑定、原子写入、损坏文件拒绝和失败不污染；统一门增至 318/318。

## 2026-08-30 — Stage 2 内容定义与注册表

Added
- 创建 typed ItemDefinition Resource，验证稳定 ID、本地化 key、类别、堆叠、价格和唯一标签。
- 创建事务型 ContentRegistry Autoload；非法/null/重复定义失败时保留上一份有效注册表。
- 添加树枝与芦苇纤维内置定义及 `zh_CN` / `en` 名称、描述。
- 添加显式文本字典序查询与 22 项内容注册表回归；统一门增至 190/190。

## 2026-08-30 — Stage 2 Inventory 数据模型

Added
- 创建 24 格默认 InventoryModel、InventorySlot 与 typed InventoryTransactionResult。
- 增减事务支持完整/部分/拒绝/非法状态、simulate 和失败不变性；精确扣除保持原子性。
- 添加拆分、移动、合并、交换、类别/稳定 ID 排序与任务物品禁止丢弃规则。
- 200 次确定性随机事务保持全部 invariant 和独立账本一致；统一门增至 220/220。
- 添加 8 格 HotbarModel、稳定 ID StorageInventory 和跨容器 InventoryTransferService。
- 完整转移、目标已满拒绝和双边失败不变性通过；统一门增至 236/236。
- 添加本地化 24 格背包/8 格快捷栏 UI、Tab/手柄 Back 开关与首格焦点。
- Inventory 和 PauseMenu 进行 modal 协调；Tab 可在聚焦控件前关闭，Esc 优先关闭背包。
- 自动门增至 249/249；真实 720p 窗口验证布局、方向焦点、Tab 往返和 Esc 关闭。
- 添加 InventoryDataCodec：Inventory/Hotbar/Storage 只编码纯 Dictionary，不保存 Node/Resource。
- 解码在提交前验证 schema、capacity、slot 类型、已知 ID、堆叠上限、快捷栏映射和 Storage ID。
- 损坏数据拒绝后保持原内存状态；编解码回归使统一门增至 268/268。
- 添加 SaveManager v1 Autoload 与顶层 SaveDataValidator；运行时状态保持纯 Dictionary。
- 写入流程为 temp 写入/flush/重读验证/有效主文件轮换备份/rename 提交。
- 主文件损坏时读取备份并返回恢复标志；双损坏、无效新快照和未来 schema 明确失败。
- v0→v1、缺失可选段默认和 JSON 整数字段安全归一化通过；统一门增至 287/287。
- SaveManager 可从真实 InventoryService、Player 和 SceneFlow 组装运行时 snapshot。
- 运行时加载以新模型完整验证后原子替换 Inventory/Hotbar/Storage，恢复玩家位置/朝向并让 UI 重绑。
- snapshot 记录最近有效 spawn；SceneFlow 可在不变更运行时的前提下预检 zone/spawn。
- 跨区加载先完成预检，再切换区域并恢复精确位置与数据；未知区域失败保持内存不变，统一门增至 299/299。

- 历史检查表：Stage 2 内容注册表门；run `20260830T104042271Z-p44764-732cb675`；0；190/190；事务回滚、重复/非法定义和稳定排序；Windows 导出并启动；零诊断

- 历史检查表：Stage 2 Inventory 数据门；run `20260830T104453682Z-p12260-cc585c4c`；0；220/220；200 次随机事务、容量/堆叠/拆分/排序/任务物品；Windows 导出并启动；零诊断

- 历史检查表：Stage 2 Hotbar/Storage 数据门；run `20260830T104853795Z-p43660-122d708e`；0；236/236；8 格映射、双向选择、稳定 Storage ID、完整转移/拒绝不变性；Windows 构建通过

- 历史检查表：Stage 2 Inventory UI 门；run `20260830T105654964Z-p19772-db01e409`；0；249/249；24/8 控件、Tab/Back、首格焦点、Esc modal、720p；Windows 构建通过

- 历史检查表：Stage 2 Inventory UI 窗口复核；`Capybara (DEBUG)` 真实窗口；不适用；中文布局完整；方向焦点移动；Tab 打开/关闭；Esc 关闭且不叠加 PauseMenu

- 历史检查表：Stage 2 Inventory 编解码门；run `20260830T110036438Z-p30380-32bf4644`；0；268/268；Inventory/Hotbar/Storage round-trip、未来字段、损坏/未知 ID 原子拒绝；Windows 构建通过

- 历史检查表：Stage 2 Save v1 文件门；run `20260830T110719283Z-p21928-c97a43e5`；0；287/287；temp/backup/corruption/default/future/v0 migration；Windows 构建通过；零诊断

- 历史检查表：Stage 2 运行时恢复门；run `20260830T111134799Z-p25884-5c12775f`；0；297/297；Inventory/Hotbar/Storage/位置/朝向/UI 重绑；跨区预先拒绝；Windows 构建通过

- 历史检查表：Stage 2 跨区域恢复门；run `20260830T111616904Z-p15200-9600c94a`；0；299/299；snapshot 持久化 zone/spawn；无变更预检后跨区恢复精确位置、朝向和全部库存；未知区域失败原子；Windows 导出并启动；零诊断

- 历史检查表：Stage 2 Settings 数据门；run `20260830T112112439Z-p18040-38dec961`；0；318/318；版本化 profile、键盘/手柄事件编解码、独立 `settings.cfg` temp 校验/原子替换、损坏读取不污染当前设置；Windows 导出并启动；零诊断

- 历史检查表：Stage 2 Settings 运行时/UI 门；run `20260903T022655587Z-p2808-c80cfa2f`；0；331/331；音量、语言、UI 缩放、输入映射与镜头平滑运行时应用；暂停菜单焦点链；Windows 导出并启动；零诊断

- 历史检查表：Stage 2 Settings 窗口复核；`capybara_ci_smoke.exe` 真实窗口；不适用；856×511 窗口中中英设置页均完整；纯键盘完成暂停→设置、语言切换、反向焦点、应用和 Esc 返回；测试后恢复简体中文

- 历史检查表：Stage 2 输入重映射门；run `20260903T023218306Z-p12316-53efd5d1`；0；341/341；7 动作键盘/手柄双槽、捕获保留另一设备、恢复默认、draft/焦点链；Windows 导出并启动；零诊断

- 历史检查表：Stage 2 输入重映射窗口复核；`capybara_ci_smoke.exe` 真实窗口；不适用；856×511 全部 7 行和双设备绑定完整可见；纯键盘进入；实测发现硬件扫描码被误显示为 Pause，修复为优先逻辑 keycode，并增加回归

- 历史检查表：Stage 2 本地化完整性门；run `20260903T023423198Z-p22324-4e5d7a76`；0；84 个 `en/zh_CN` 双语键唯一且非空；64 个正式代码/场景/资源引用全部解析；统一门含此步骤；341/341 与 Windows 构建通过

- 历史检查表：Stage 2 设置跨进程门；run `20260903T023741317Z-p19344-18fe639c`；0；独立 write/read/cleanup Godot 进程验证语言、125% UI、0.37 音量、镜头平滑与键盘+手柄绑定；fixture 清理；341/341 与 Windows 构建通过

- 历史检查表：Stage 2 Storage UI 门；run `20260903T024619892Z-p31572-eb73462d`；0；356/356；24×32 双栏、typed storage payload、双向整组转移、焦点/关闭、完整源堆叠 ID 修复；88 个双语键；Windows 构建通过

- 历史检查表：Stage 2 Storage 窗口复核；`storage_visual_fixture.gd` 真实窗口；不适用；856×511 双栏完整；Enter 将树枝 ×7 转入箱内，点击箱内格转回玩家；Esc 关闭并恢复世界；无持久化 fixture

- 历史检查表：Stage 2 游戏存档跨进程门；run `20260903T024852583Z-p14928-fea33ee2`；0；独立 write/read/cleanup 进程；读进程先切林地，再恢复住宅地 spawn、位置、up_left、9 树枝、Hotbar 5、Storage 6 纤维；356/356、Windows 构建通过

- 历史检查表：Stage 2 clean 审查前门；run `20260903T025022184Z-p18168-6cf47098`；0；clean HEAD `565847f`；356/356；全部统一步骤与 Windows debug/headless smoke 通过

- 历史检查表：Stage 2 首批审查修复门；run `20260903T025835113Z-p1316-b0991dca`；0；368/368；Settings backup、GUI 输入捕获、paused restore、stale travel、双库存原子通知、finite 坐标与固定 8 格 Hotbar；零诊断

- 历史检查表：Stage 2 背包/工具上下文门；run `20260903T030932301Z-p5084-d45275cf`；0；386/386；拆分/二次丢弃/任务拒绝/排序/快捷栏分配，Q/R+肩键，芦苇铲拾取/装备/资源上下文与跨进程恢复；Windows 构建通过

- 历史检查表：Stage 2 背包操作窗口复核；`inventory_visual_fixture.gd` 真实窗口；不适用；856×511 全部控件可见；树枝 7→4+3，芦苇铲分配快捷栏，丢弃二次确认 4→3，整理合并为树枝 6；fixture 未写盘

- 历史检查表：Stage 2 Save UI 门；run `20260903T031920338Z-p34024-ca1816b8`；0；397/397；暂停菜单正式保存/读取、语义不可应用 main 回退 backup、双损坏保持内存；107 个双语键；Windows 构建通过

- 历史检查表：Stage 2 Save UI 窗口复核；`save_ui_visual_fixture.gd` 真实窗口；不适用；856×511 保存/读取按钮与状态完整；纯键盘焦点、隔离保存和读取反馈通过；退出后 fixture 文件清理

- 历史检查表：Stage 2 辅助功能与显示矩阵；run `20260903T033158363Z-p24604-3aa153e0`；0；526/526；减少动态/震动/高对比均有生产消费者；4 分辨率×3 缩放×5 modal 有界且内容可达；Windows 构建通过

- 历史检查表：Stage 2 150% 窗口复核；`display_matrix_visual_fixture.gd` 真实窗口；不适用；1280×720 / 150% 设置页上下滚动、储物页左右滚动均可达；高对比提示与当前目标明显可观察

- 历史检查表：Stage 2 `f0fed01` 独立复审；两个只读复核任务；不适用；代码审查发现 3 High，QA 发现 5 High；禁止 merge/tag；全部转为 `ST2-011`–`ST2-015` 回归驱动修复

- 历史检查表：Stage 2 复审修复专项；`run_all.gd` + 两个跨进程脚本；0；608/608；9 动作精确重映射/含 modifier 动态提示、末端焦点矩阵、正式显示 dispatcher、世界差量、资源奖励、Storage 重绑和 fixture 隔离通过

- 历史检查表：Stage 2 正式显示窗口复核；`display_matrix_visual_fixture.gd` 真实窗口；不适用；通过正式 SettingsScreen/SettingsService 与隔离设置文件完成 1280×720 窗口→全屏→窗口→1280×800；各状态布局完整，fixture 清理

- 历史检查表：Stage 2 复审修复提交前门；run `20260903T040026703Z-p32308-41e56f12`；0；dirty worktree on `f0fed01`；608/608；112/87 本地化；GUID 设置/存档三进程；Windows debug 导出与启动；零诊断；`required_checks_satisfied=true`

- 历史检查表：Stage 2 `fc2b6c5` 代码终审；独立只读代码复核；不适用；QA 判 0 High，但代码审查复现 2 High：缺失世界项非替换语义、multi-yield partial 奖励丢失；禁止 merge/tag 并继续修复

- 历史检查表：Stage 2 完整状态替换专项；`run_all.gd`；0；616/616；Home 保存后修改 Grove 再加载会恢复 Grove 默认；缺失 interaction 恢复 fresh 默认；精确断言 yield=5/available=1 零变更、完整容量 +5/扣 1 use

- 历史检查表：Stage 2 终审边界提交前门；run `20260903T040937825Z-p34152-f3581995`；0；dirty worktree on `fc2b6c5`；616/616；两组跨进程、Windows debug 导出/启动、零诊断；`required_checks_satisfied=true`

- 历史检查表：Stage 2 最终 exact clean 门；run `20260903T041100794Z-p23616-cf38b6eb`；0；commit/HEAD 均为 `c7f91fe5e93a5771ad0fdec1059cc6aa1890a795`；616/616；全部 12 步、Windows debug/headless smoke、零诊断通过

- 历史检查表：Stage 2 最终独立代码/QA 审查；两个只读终审任务；不适用；`c7f91fe`：代码审查与 QA 均为 Blocker 0、Critical 0、High 0；共同批准 merge/tag；开放 Medium 级别准确

- 历史任务 `CAP-0201`：原状态 `done`，原阶段 `2`；内置 branch/reed fiber/reed spade 启动验证；事务加载拒绝非法/重复；运行时注册表锁定且调用者只能获得定义副本。

- 历史任务 `CAP-0202`：原状态 `done`，原阶段 `2`；220/220；200 次确定性随机增减、部分/模拟/精确事务、拆分/合并/交换/排序与任务物品锁定通过。

- 历史任务 `CAP-0203`：原状态 `done`，原阶段 `2`；356/356；24×32 Storage 双栏、双向整组事务、typed 上下文和存档编解码通过；856×511 真实窗口转入/转回/Esc 复核。

- 历史任务 `CAP-0204`：原状态 `done`，原阶段 `2`；397/397；暂停菜单正式保存/读取、语义不可应用 main 自动回退 backup、双损坏不改内存和本地化提示通过；856×511 真实窗口键盘复核。

- 历史任务 `CAP-0205`：原状态 `done`，原阶段 `2`；112 个双语键唯一且非空；87 个正式引用全部解析；动态 F/X 输入提示与中英设置页通过；统一门强制检查。

- 历史任务 `CAP-0206`：原状态 `done`，原阶段 `2`；608/608；9 动作精确重映射/动态提示；四分辨率×三缩放×五界面末端焦点矩阵；辅助消费者；真实窗口→全屏→1280×800 往返。

- 历史决定：DEC-016；2026-08-30；Inventory 增减先在 slot 副本上规划，再按结果提交；精确扣除在数量不足时完全不变；让建造成本、存档和 UI 预览可复用同一事务规则，并消除半扣除状态；所有 UI/系统只能调用 InventoryModel，不直接写 slots；随机账本回归成为 Stage 2 门；Accepted

- 历史决定：DEC-017；2026-08-30；Inventory/Hotbar/Storage 先编码为版本化纯 Dictionary，完整验证后才一次性恢复模型；将存档格式与运行时 Node/Resource 解耦，并保证损坏数据不会部分污染内存；SaveManager 只消费 codec 输出；未知未来字段可忽略，未知内容 ID/非法数量必须失败；Accepted

- 历史决定：DEC-018；2026-08-30；Save v1 先写 temp 并重读验证；仅将有效旧主文件轮换为单一 backup，再 rename temp 提交；写盘中断或新快照损坏不能清空上一次有效数据，主损坏仍可恢复；无效主文件不覆盖有效 backup；加载返回明确 source/recovered flag；Steam Cloud 以后只同步稳定主/备份文件；Accepted

- 历史决定：DEC-019；2026-09-03；正式读取把文件验证、运行时预检和完整应用视为同一候选事务；main 任一步失败后才尝试 backup；JSON 结构有效不代表其中区域、出生点或内容在当前版本可应用；暂停菜单统一调用 `load_and_apply`；backup 恢复有明确本地化提示；双候选失败保持运行时不变；Accepted

- 历史决定：DEC-020；2026-09-03；UI 缩放继续使用全局内容缩放，核心 modal 统一放入双轴响应式滚动容器；辅助反馈由独立服务消费设置；150% 在 1280×720 会自然缩小逻辑视口，固定大面板必须仍可访问；震动、高对比和减少动态不能只持久化；暂停/设置/重映射/背包/储物在 4×3 矩阵内有界且内容可达；交互成功按活动手柄请求震动；减少动态关闭平滑；高对比同时强化提示与目标；Accepted

- 历史决定：DEC-021；2026-09-03；Save v1 以 `zone_id + interaction_id` 保存全部注册区域的拾取数量与资源剩余次数；读取以 fresh 场景补全缺失项后完整替换；Inventory 单独恢复会让场景物重生；增量覆盖还会让保存后的未列出 mutation 穿越到旧档；世界状态先做结构/场景语义预检；缺失区域/交互使用场景默认，不沿用当前 cache；Stage 4 迁移为具备相同替换语义的 chunk 稀疏差量；Accepted

- 历史决定：DEC-022；2026-09-03；输入捕获规范化摇杆方向，完整持久化键盘 modifier，并从实际 InputMap 生成世界提示；所有 Stage 2 gameplay action 均可重映射；UI 可产生的绑定必须能被自身 codec 重开，提示必须与当前有效动作一致；9 动作双设备页；F/X 动态提示；±1 轴值；事件类型与范围统一验证；恢复默认直接预览项目默认映射；Accepted


## reliability-integration

- 时间：2026-09-16T16:05:32+08:00；来源类型：executed_now。任务ST2-R001–004；base `02ac9b37ed6eed7d8b12261c0d9772a30704d8f7` + 本批工作树，代码commit稍后独立记录。
- R-SAVE-01：原序列1/754失败；隔离不适用main并在save轮换前运行真实库存/区域/world预检。独立审查两次补出隔离失败直接保存、capacity25语义不适用变体，均加跨进程回归通过。临时OPEN_FAILED/READ_FAILED明确拒绝，不隔离/不自动加载旧backup；temp/rotate/commit/isolate注入保留好恢复点。
- R-HOTBAR-01：原16/27失败，修复专项35/35；整理/完整移动/合并/交换重映射所有aliases；拆分/部分转移保留源，耗尽/整组箱转移清空。schema1仍保存槽索引，旧档兼容与真实跨进程装备/UI恢复通过。独立代码审阅无新增B/C/H。
- R-INTERACT-01：原3/4失败；现在REQUESTED→来源stable ID/对象/数量/工具/单次claim→库存与来源提交→最终completed/震动。资源只全量，pickup反馈实际量。暂停、取消、换工具、replay/tamper、rapid及同值读档使旧pending失效。最终63/63专项零诊断：`interaction-regression-20260916T075506074Z.log`；中间interaction-after.log虽0/56但有新类未导入诊断，明确不计通过。
- ST2-017：原最小5项失败；实际shape扫掠/多边形碰撞、连通图、固定邻点与稳定备用spawn；深水/桥面栏杆/房基/封闭墙及旧图守卫。完整事务保留inventory/hotbar/storage对象、玩家/世界/current/cache/pending/信号屏蔽，失败全部回滚；成功只发布最终坐标。安全恢复中文/英文提示已接入。
- 范围：当前两区域和真实视觉blockout碰撞；未知layer/chunk仅安全回退，不代表Stage4分块或真正桥下层已实现。裸transition_to_saved_position只承担落点通知，失败原子性由正式SaveRuntimeTransaction保障，新增无外层调用者须注意。
- 最终统一门run `20260916T080216355Z-p8148-b860280a`：19/19、827/827、61事务检查点、零诊断、全部跨进程与Windows Debug导出启动通过；源码前后指纹一致，见Stage0.5 takeover-validation。断言数不代表玩家流程或覆盖率；未新增实体手柄/GPU全流程验收。
- 证据：本机build/takeover/20260916中的*-before、save-capacity-hotbar-after、save-transaction-after及唯一命名交互专项；完整门见build/logs相同run。可由统一工具重跑，忽略产物不随Git携带。
- 下一动作：提交与exact SHA CI；Stage3正式入口时复跑这些消费者及旧档恢复；Stage4扩展chunk/layer位置策略。
