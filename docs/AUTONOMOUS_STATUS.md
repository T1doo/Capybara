# 自治开发状态

更新时间：2026-09-16（Asia/Shanghai）
目标契约：`CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md`

## 当前状态

- 当前 Stage：`3 — 高品质视觉原型与美术流水线`。
- 当前子任务：主屋、木桥、水车、码头和阔叶树原型已集成。树冠实际遮挡/恢复、树干碰撞与排序、GPU Alpha已验证；下一步菜地、水生植物与ENV3-001/002美术统一仍未完成。本轮按用户要求先提供公开安全审阅快照，不继续扩展功能。
- 当前分支：`codex/autonomous-v1`。
- 最近完成的 Stage 0.5 实现 commit：`481a140 chore(governance): establish autonomous recovery and CI`。
- 最近稳定 tag：`capybara-stage-02`（Stage 2 merge `25efe67`）。
- `main` 本地状态：Stage 2 稳定合并；本次只发布独立审阅快照，不改远程main，后续公开历史同步须先解决 `GIT-002`。
- Stage 2 已完成内容注册、背包数据/UI、设置/辅助功能/显示矩阵、本地化、Save v1 正式入口、跨区域恢复与完整世界交互状态替换；加入 Stage 3 阔叶树回归后当前总计 `752/752`。

## 最近质量证据

公开审阅前复跑：`20260916T060325938Z-p17504-0dbdb919`，18/18、752/752、退出0、零 diagnostics，Windows导出和启动通过。随后仅补充审阅/历史安全文档并运行文档与Git差异检查；没有新增功能。此前结果没有冒充此次复跑。

阔叶树完整门：`20260912T062630164Z-p23008-20643cf6`，18/18、752/752、退出0、零 diagnostics，含两套绘本材质四份哈希/尺寸/登记校验及Windows导出启动。GPU三实景/两Alpha图退出0，独立两轮审查允许原型用途而非正式发布。来源、完整提示词与差距见 `art/candidates/environment/foliage_material_v1/`。

码头最终门：`20260912T060943189Z-p31340-3e944638`，17/17、741/741、退出0、零 diagnostics，Windows导出与启动通过。GPU五视角退出0；独立审查无阻止原型集成的High/Medium，北侧护栏补测与638点水体范围核对均通过。结构、来源与审查边界见 `art/candidates/environment/home_visual_v1/DOCK_REVIEW.md`。ENV3-001记录整体木纹对比/重复与结构细节差距，未批准Stage3正式美术；本批无新生图或push。

环境预览最终门：`20260912T055944017Z-p25908-e98c61f3`，17/17、730/730、退出0、零 diagnostics，含独立预览烟测、Windows导出与启动。GPU五截图及20项事件检查退出0；设备1手柄A/方向、鼠标继续、暂停冻结和设置隔离通过。首轮缺手柄映射8/728、后续鼠标测试坐标1/730均已保留并修复；独立代码复审发现的设备编号风险已实际复现和修复。参见 `docs/ENVIRONMENT_PREVIEW.md`；实体手柄仍待QA-001，本轮没有push。

水车表现最终门：`20260912T054526995Z-p33312-c0ac3f1a`，16/16、710/710、退出0、零 diagnostics，Windows导出及启动通过。GPU五视角退出0，转动→减少动态/停水冻结、操作站位碰撞及北侧遮挡有实际证据；独立复审High=0，1项材质细节Medium留待整体美术统一。详见 `art/candidates/environment/home_visual_v1/WATERWHEEL_REVIEW.md`。

木桥模块最终门：`20260912T053251245Z-p9004-cbce1545`，16/16、702/702、退出0、零 diagnostics，Windows导出及启动通过。GPU `bridge_visual_fixture.gd` 五视角捕获退出0；独立复审无High或阻止原型集成的Medium。复用范围与证据见 `art/candidates/environment/home_visual_v1/BRIDGE_REVIEW.md`。

主屋材质集成最终门：`20260912T052054450Z-p30196-0ee4fdee`，16/16、695/695、退出0、零 diagnostics，Windows导出及启动通过；GPU65,536个Alpha样本差异0、屋顶淡化有效。此前 `20260912T051855116Z-p18212-de56b4bb` 因PNG二进制被治理脚本按文本误读失败，已修复扫描文件类型后重跑。材质独立审查无Blocker/Critical/High，2个Medium见 `art/candidates/environment/cottage_materials_v1/REVIEW.md`。本轮无远程CI或push。

2026-09-12 恢复批次最终门：`20260912T050326359Z-p30260-149002e0`，16/16 步、695/695、退出 0、零 diagnostics，含暂存差异与 Windows 构建启动；GPU `cottage_visual_fixture.gd` 退出 0，实际屋顶重叠 Alpha 0.28，四底与门前截图见 `build/art-pipeline/cottage_review/`。独立复审通过技术样件提交，未批准正式美术。完整说明见 `art/candidates/environment/home_cottage_v1/LAYERED_PROTOTYPE_REVIEW.md`。

| 检查 | 命令 | 退出码 | 结果 |
|---|---|---:|---|
| Godot 版本、导入、测试 | `tools/check_project.ps1` | 0 | Godot `4.7.2.stable.official.ed1daf0bf`；Stage 1 最终 `168/168` 通过 |
| 主场景烟雾 | `& $env:GODOT_BIN --headless --path game --quit-after 10` | 0 | 无错误输出 |
| Git 空白检查 | `git diff --cached --check` | 0 | Stage 0 暂存内容通过 |
| 凭据模式扫描 | Stage 0 文件范围 `rg` 扫描 | 0 | 无凭据赋值或私钥头命中 |
| 窗口视觉复核 | 当前 `Capybara (DEBUG)` | 不适用 | 灰盒、阶段标识、暂停、焦点导航和退出通过 |
| Windows 构建烟雾 | `REQUIRE_WINDOWS_BUILD_SMOKE=1` 的统一检查 | 0 | 官方模板 SHA256 匹配；debug 导出成功；EXE 实际启动 10 帧 |
| Stage 0.5 强制门 | run `20260830T075751611Z-p30944-9e547673` | 0 | `required_checks_satisfied=true` |
| Stage 1 第一批强制门 | run `20260830T080600788Z-p23400-3d26af41` | 0 | 43/43；Windows 导出并启动；`required_checks_satisfied=true` |
| Stage 1 typed 协议门 | run `20260830T080921461Z-p1612-703e0422` | 0 | 51/51；零泄漏诊断；Windows 导出并启动 |
| Stage 1 候选选择门 | run `20260830T081236950Z-p45044-28ebf28f` | 0 | 57/57；确定性排序；Windows 导出并启动 |
| Stage 1 玩家传感器门 | run `20260830T081509675Z-p22892-10a1a477` | 0 | 62/62；候选生命周期；Windows 导出并启动 |
| Stage 1 拾取/资源门 | run `20260830T081838224Z-p32036-fbee69fd` | 0 | 73/73；typed payload 与耗尽；Windows 导出并启动 |
| Stage 1 床/箱子/门门禁 | run `20260830T082436050Z-p32304-359fd07c` | 0 | 83/83；最小状态与 typed 请求；Windows 导出并启动 |
| Stage 1 NPC 协议门 | run `20260830T082733208Z-p40284-3efc5de4` | 0 | 85/85；稳定 NPC/对话 ID；Windows 导出并启动 |
| Stage 1 输入提示门 | run `20260830T083335249Z-p45480-210e962e` | 0 | 94/94；键鼠/手柄选择；Windows 导出并启动 |
| Stage 1 输入提示窗口复核 | 当前 `Capybara (DEBUG)` | 不适用 | 启动显示 `拾取 [E]`；按 E 后提示清除 |
| Stage 1 SceneFlow 核心门 | run `20260830T084158751Z-p36884-fae2aaa3` | 0 | 111/111；失败转场回滚、稳定出生点与单玩家不变量；Windows 导出并启动 |
| Stage 1 区域往返强制门 | run `20260830T084653545Z-p15116-8475ed6b` | 0 | 123/123；真实住宅地/林地门往返、指定出生点、单活动区域和单玩家；Windows 导出并启动 |
| Stage 1 调试覆盖层强制门 | run `20260830T084931068Z-p41080-54f12c80` | 0 | 129/129；F3、本地化诊断内容和计数；Windows 导出并启动 |
| Stage 1 调试覆盖层窗口复核 | `Capybara (DEBUG)` 真实窗口 | 不适用 | 布局无关键遮挡；F3 隐藏/恢复；Esc 暂停与焦点正常；Player/活动区域均为 1 |
| Stage 1 soak runner 早期短验证 | `tools/run_stage_1_soak.ps1 -DurationSeconds 5` | 0 | 初版 runner 的短验证历史；最终证据以后续正式 soak 为准 |
| Stage 1 最终 clean 强制门 | run `20260830T101336067Z-p43328-864878c0` | 0 | commit `a9eb836`；168/168；Windows 导出并启动；`required_checks_satisfied=true`；零诊断 |
| Stage 1 最终正式 soak | `stage-1-soak-20260830T101359995Z-p7144-14111a30.log` | 0 | 1200 秒；8378 循环；2095 inputs/transitions；524 selections；8378 state checks；20 心跳；零诊断 |
| Stage 1 最终独立代码/QA 复核 | 两个只读复核任务 | 不适用 | `a9eb836`：Blocker 0、Critical 0、High 0；实体手柄保持 `QA-001 / Not Verified` |
| Stage 2 内容注册表门 | run `20260830T104042271Z-p44764-732cb675` | 0 | 190/190；事务回滚、重复/非法定义和稳定排序；Windows 导出并启动；零诊断 |
| Stage 2 Inventory 数据门 | run `20260830T104453682Z-p12260-cc585c4c` | 0 | 220/220；200 次随机事务、容量/堆叠/拆分/排序/任务物品；Windows 导出并启动；零诊断 |
| Stage 2 Hotbar/Storage 数据门 | run `20260830T104853795Z-p43660-122d708e` | 0 | 236/236；8 格映射、双向选择、稳定 Storage ID、完整转移/拒绝不变性；Windows 构建通过 |
| Stage 2 Inventory UI 门 | run `20260830T105654964Z-p19772-db01e409` | 0 | 249/249；24/8 控件、Tab/Back、首格焦点、Esc modal、720p；Windows 构建通过 |
| Stage 2 Inventory UI 窗口复核 | `Capybara (DEBUG)` 真实窗口 | 不适用 | 中文布局完整；方向焦点移动；Tab 打开/关闭；Esc 关闭且不叠加 PauseMenu |
| Stage 2 Inventory 编解码门 | run `20260830T110036438Z-p30380-32bf4644` | 0 | 268/268；Inventory/Hotbar/Storage round-trip、未来字段、损坏/未知 ID 原子拒绝；Windows 构建通过 |
| Stage 2 Save v1 文件门 | run `20260830T110719283Z-p21928-c97a43e5` | 0 | 287/287；temp/backup/corruption/default/future/v0 migration；Windows 构建通过；零诊断 |
| Stage 2 运行时恢复门 | run `20260830T111134799Z-p25884-5c12775f` | 0 | 297/297；Inventory/Hotbar/Storage/位置/朝向/UI 重绑；跨区预先拒绝；Windows 构建通过 |
| Stage 2 跨区域恢复门 | run `20260830T111616904Z-p15200-9600c94a` | 0 | 299/299；snapshot 持久化 zone/spawn；无变更预检后跨区恢复精确位置、朝向和全部库存；未知区域失败原子；Windows 导出并启动；零诊断 |
| Stage 2 Settings 数据门 | run `20260830T112112439Z-p18040-38dec961` | 0 | 318/318；版本化 profile、键盘/手柄事件编解码、独立 `settings.cfg` temp 校验/原子替换、损坏读取不污染当前设置；Windows 导出并启动；零诊断 |
| Stage 2 Settings 运行时/UI 门 | run `20260903T022655587Z-p2808-c80cfa2f` | 0 | 331/331；音量、语言、UI 缩放、输入映射与镜头平滑运行时应用；暂停菜单焦点链；Windows 导出并启动；零诊断 |
| Stage 2 Settings 窗口复核 | `capybara_ci_smoke.exe` 真实窗口 | 不适用 | 856×511 窗口中中英设置页均完整；纯键盘完成暂停→设置、语言切换、反向焦点、应用和 Esc 返回；测试后恢复简体中文 |
| Stage 2 输入重映射门 | run `20260903T023218306Z-p12316-53efd5d1` | 0 | 341/341；7 动作键盘/手柄双槽、捕获保留另一设备、恢复默认、draft/焦点链；Windows 导出并启动；零诊断 |
| Stage 2 输入重映射窗口复核 | `capybara_ci_smoke.exe` 真实窗口 | 不适用 | 856×511 全部 7 行和双设备绑定完整可见；纯键盘进入；实测发现硬件扫描码被误显示为 Pause，修复为优先逻辑 keycode，并增加回归 |
| Stage 2 本地化完整性门 | run `20260903T023423198Z-p22324-4e5d7a76` | 0 | 84 个 `en/zh_CN` 双语键唯一且非空；64 个正式代码/场景/资源引用全部解析；统一门含此步骤；341/341 与 Windows 构建通过 |
| Stage 2 设置跨进程门 | run `20260903T023741317Z-p19344-18fe639c` | 0 | 独立 write/read/cleanup Godot 进程验证语言、125% UI、0.37 音量、镜头平滑与键盘+手柄绑定；fixture 清理；341/341 与 Windows 构建通过 |
| Stage 2 Storage UI 门 | run `20260903T024619892Z-p31572-eb73462d` | 0 | 356/356；24×32 双栏、typed storage payload、双向整组转移、焦点/关闭、完整源堆叠 ID 修复；88 个双语键；Windows 构建通过 |
| Stage 2 Storage 窗口复核 | `storage_visual_fixture.gd` 真实窗口 | 不适用 | 856×511 双栏完整；Enter 将树枝 ×7 转入箱内，点击箱内格转回玩家；Esc 关闭并恢复世界；无持久化 fixture |
| Stage 2 游戏存档跨进程门 | run `20260903T024852583Z-p14928-fea33ee2` | 0 | 独立 write/read/cleanup 进程；读进程先切林地，再恢复住宅地 spawn、位置、up_left、9 树枝、Hotbar 5、Storage 6 纤维；356/356、Windows 构建通过 |
| Stage 2 clean 审查前门 | run `20260903T025022184Z-p18168-6cf47098` | 0 | clean HEAD `565847f`；356/356；全部统一步骤与 Windows debug/headless smoke 通过 |
| Stage 2 首批审查修复门 | run `20260903T025835113Z-p1316-b0991dca` | 0 | 368/368；Settings backup、GUI 输入捕获、paused restore、stale travel、双库存原子通知、finite 坐标与固定 8 格 Hotbar；零诊断 |
| Stage 2 背包/工具上下文门 | run `20260903T030932301Z-p5084-d45275cf` | 0 | 386/386；拆分/二次丢弃/任务拒绝/排序/快捷栏分配，Q/R+肩键，芦苇铲拾取/装备/资源上下文与跨进程恢复；Windows 构建通过 |
| Stage 2 背包操作窗口复核 | `inventory_visual_fixture.gd` 真实窗口 | 不适用 | 856×511 全部控件可见；树枝 7→4+3，芦苇铲分配快捷栏，丢弃二次确认 4→3，整理合并为树枝 6；fixture 未写盘 |
| Stage 2 Save UI 门 | run `20260903T031920338Z-p34024-ca1816b8` | 0 | 397/397；暂停菜单正式保存/读取、语义不可应用 main 回退 backup、双损坏保持内存；107 个双语键；Windows 构建通过 |
| Stage 2 Save UI 窗口复核 | `save_ui_visual_fixture.gd` 真实窗口 | 不适用 | 856×511 保存/读取按钮与状态完整；纯键盘焦点、隔离保存和读取反馈通过；退出后 fixture 文件清理 |
| Stage 2 辅助功能与显示矩阵 | run `20260903T033158363Z-p24604-3aa153e0` | 0 | 526/526；减少动态/震动/高对比均有生产消费者；4 分辨率×3 缩放×5 modal 有界且内容可达；Windows 构建通过 |
| Stage 2 150% 窗口复核 | `display_matrix_visual_fixture.gd` 真实窗口 | 不适用 | 1280×720 / 150% 设置页上下滚动、储物页左右滚动均可达；高对比提示与当前目标明显可观察 |
| Stage 2 `f0fed01` 独立复审 | 两个只读复核任务 | 不适用 | 代码审查发现 3 High，QA 发现 5 High；禁止 merge/tag；全部转为 `ST2-011`–`ST2-015` 回归驱动修复 |
| Stage 2 复审修复专项 | `run_all.gd` + 两个跨进程脚本 | 0 | 608/608；9 动作精确重映射/含 modifier 动态提示、末端焦点矩阵、正式显示 dispatcher、世界差量、资源奖励、Storage 重绑和 fixture 隔离通过 |
| Stage 2 正式显示窗口复核 | `display_matrix_visual_fixture.gd` 真实窗口 | 不适用 | 通过正式 SettingsScreen/SettingsService 与隔离设置文件完成 1280×720 窗口→全屏→窗口→1280×800；各状态布局完整，fixture 清理 |
| Stage 2 复审修复提交前门 | run `20260903T040026703Z-p32308-41e56f12` | 0 | dirty worktree on `f0fed01`；608/608；112/87 本地化；GUID 设置/存档三进程；Windows debug 导出与启动；零诊断；`required_checks_satisfied=true` |
| Stage 2 `fc2b6c5` 代码终审 | 独立只读代码复核 | 不适用 | QA 判 0 High，但代码审查复现 2 High：缺失世界项非替换语义、multi-yield partial 奖励丢失；禁止 merge/tag 并继续修复 |
| Stage 2 完整状态替换专项 | `run_all.gd` | 0 | 616/616；Home 保存后修改 Grove 再加载会恢复 Grove 默认；缺失 interaction 恢复 fresh 默认；精确断言 yield=5/available=1 零变更、完整容量 +5/扣 1 use |
| Stage 2 终审边界提交前门 | run `20260903T040937825Z-p34152-f3581995` | 0 | dirty worktree on `fc2b6c5`；616/616；两组跨进程、Windows debug 导出/启动、零诊断；`required_checks_satisfied=true` |
| Stage 2 最终 exact clean 门 | run `20260903T041100794Z-p23616-cf38b6eb` | 0 | commit/HEAD 均为 `c7f91fe5e93a5771ad0fdec1059cc6aa1890a795`；616/616；全部 12 步、Windows debug/headless smoke、零诊断通过 |
| Stage 2 最终独立代码/QA 审查 | 两个只读终审任务 | 不适用 | `c7f91fe`：代码审查与 QA 均为 Blocker 0、Critical 0、High 0；共同批准 merge/tag；开放 Medium 级别准确 |
| Stage 3 旧 C1/D1 技术初筛 | ImageGen + RGBA 像素检查 + 144 px 预览 | 0 | 历史技术检查通过，但随后权利审查发现未核验输入污染；整条派生链已隔离，本证据不得用于晋级 |
| Stage 3 旧候选统一门 | run `20260903T044306816Z-p18352-6f654b12` | 0 | 历史运行本身通过 616/616，但发生在权利链问题发现前；不再证明任何活动候选有效 |
| Stage 3 美术流水线基础门 | run `20260903T045229459Z-p7908-335a47ca` | 0 | 13 步、616/616、Windows 构建通过；之后独立 QA 发现宽目录 manifest/联系表绑定假绿，现已在工作树修复，等待新统一门取代 |
| Stage 3 清洁链视觉审查 | 两个独立只读审查任务 | 不适用 | 权利 Blocker 已关闭；U/V/W/Z/AA/AD 六图逐文件 provenance 完整；视觉审查 Blocker/Critical/High 0/0/0，推荐 U1/AA1/V1 进入透明重做；仍无 PLAYER_MASTER |
| Stage 3 清洁链完整统一门 | run `20260903T064236154Z-p27784-aed4a2eb` | 0 | 最新清洁链、隔离、逐文件 manifest、联系表 input/output SHA-256、13 个统一步骤、616/616 与 Windows debug 导出/启动全部通过；零诊断；`required_checks_satisfied=true` |
| Stage 3 清洁链最终提交前门 | run `20260903T065348037Z-p5912-9baad987` | 0 | 增加隔离 SHA-256 防复用后，13/13 步、616/616、正式联系表绑定、Windows debug 导出/启动与 Git 空白检查全部通过；零诊断；`required_checks_satisfied=true` |
| Stage 3 SVG cutout 统一门 | run `20260903T080402869Z-p17488-1c09b8a5` | 0 | 新增 `svg_cutout_render` 后 14/14 步通过；Godot 重建 1024×768 RGBA SVG 预览并通过 PNG/Alpha 门；616/616、Windows debug 导出/启动、零诊断；`required_checks_satisfied=true` |
| Stage 3 SVG/Alpha 最终提交前门 | run `20260903T094743598Z-p10576-dc83277c` | 0 | 15/15 步；616/616；Godot `4.7.2.stable.official.ed1daf0bf`；SVG 渲染、四底/144 px、Windows debug 导出/启动、工作树/暂存差异检查全部通过；零诊断；`required_checks_satisfied=true` |
| Stage 3 AG1/AH1 独立视觉/政策审查 | 两个独立只读审查任务 | 不适用 | 来源/政策 B/C/H 0/0/0；视觉 B/C 0/0、AH1 独有 High 1；最终采用严格结论：AG1 可作 visual-concept 解剖锚点，AH1 rejected_visual，二者均不得冒充透明候选/母图/游戏资产 |
| Stage 3 AG1 方向锁定 | commit `a8f9890`；DEC-025 | 0 | 用户确认当前版本已经好看；AG1 作为主角视觉/解剖方向继续，后续不再以常规审美差异反复生图，只做必要技术适配 |
| Stage 3 家园 A1 视觉/政策审查 | 两个独立只读审查任务 | 不适用 | 两条审查均为 Blocker/Critical/High 0/0/0；1536×1024 RGB 只作为色彩、构图、水系骨架和模块清单参考；禁止冒充地图、game-ready 或商店截图 |
| Stage 3 家园 A1 完整统一门 | run `20260903T102526660Z-p28092-28e32666` | 0 | 15/15 步；新增家园概念逐文件 provenance/brief/prompt/审查门；616/616、Godot 4.7.2、Windows debug 导出/启动、工作树/暂存差异检查均通过；零诊断；`required_checks_satisfied=true` |
| Stage 3 家园功能 blockout 统一门 | run `20260903T104632803Z-p32712-2689b89b` | 0 | 网格绘制原点修正后的最终 16/16 步；650/650；独立 blockout 烟测、普通河面阻挡、192px 桥面通行、九个 64px 网格站位、约 144px 玩家比例、Windows debug 导出/启动全部通过；零诊断；`required_checks_satisfied=true` |
| Stage 3 世界坐标绘本水面统一门 | run `20260903T105619634Z-p12792-6decb0d1` | 0 | 16/16 步；655/655；动态水 shader、减少动态冻结、高对比分离、独立 blockout 烟测和 Windows debug 导出/启动全部通过；Compatibility GPU 三帧捕获另行实测退出码 0、零 diagnostics；`required_checks_satisfied=true` |
| Stage 3 家园样式/遮挡统一门 | run `20260903T110916784Z-p9400-dbb36a8f` | 0 | 16/16 步；665/665；StyleProfile 不变量、真实玩家树冠进入/离开、减少动态即时淡化、下右接触阴影、独立场景烟测与 Windows debug 导出/启动全部通过；Compatibility GPU 捕获退出码 0、零 diagnostics；`required_checks_satisfied=true` |
| Stage 3 地表/岸线/微粒统一门 | run `20260903T111911620Z-p10548-612f3e01` | 0 | 16/16 步；672/672；世界坐标水粉地表、18/8px 岸线、确定性微粒与减少动态冻结、独立 blockout 烟测、Windows debug 导出/启动全部通过；Compatibility GPU 捕获退出码 0、零 diagnostics；`required_checks_satisfied=true` |
| Stage 3 主屋视觉概念/透明拒绝门 | run `20260903T113529947Z-p23596-4b92865b` | 0 | 16/16 步；672/672；主屋 A1、内部 A1 参考哈希、完整 prompts、RGB 假透明与背景提取拒绝记录均通过；`game_path` 为空，Windows debug 导出/启动和零 diagnostics 通过；`required_checks_satisfied=true` |

## 当前可玩内容

- 1920×1200 灰盒世界与四边碰撞。
- Godot 几何占位玩家。
- WASD、方向键、左摇杆和十字键移动映射。
- 斜向速度归一化与最后非零方向。
- Camera2D 平滑跟随。
- Escape / 手柄 Start 暂停与恢复。
- 键盘可见焦点导航、继续和退出到桌面。
- `en` / `zh_CN` 最小本地化。
- Idle / Move / Interact / Disabled 显式状态机与合法转换。
- 8 方向 facing 稳定值、向量和 ID；真实玩家移动驱动状态与 facing。
- Typed InteractionContext / InteractionResult / InteractableComponent 协议基础。
- 确定性交互选择器：任务匹配、类型优先级、朝向、距离、稳定 ID。
- 玩家 InteractionSensor：Area2D 候选生命周期、当前目标信号、prompt 与 typed interact 入口。
- 拾取物与资源点灰盒：公共协议、工具要求、两阶段背包提交和耗尽状态；零转入不消耗资源。
- 床、箱子和门灰盒：休息/储物/转场请求与最小状态；无时间、库存或场景服务依赖。
- NPC 灰盒：稳定 NPC/对话 ID 请求；无关系、日程、任务或对话树依赖。
- InputDeviceService 和动态本地化提示：键鼠/手柄变化、摇杆死区、活动手柄回退；F/X 等重映射即时更新提示；实体手柄仍见 `QA-001`。
- SceneFlowService、WorldZone 和 WorldSpawnPoint：稳定 ID、失败保持当前区域、同区重定位和重复玩家场景拒绝。
- 住宅地与林地灰盒区域：门请求双向往返，主场景持久保留唯一玩家、相机与 UI。
- F3 调试覆盖层：实时显示区域、状态、朝向、交互目标、输入设备、Player 和活动区域数量。
- 同会话区域状态保持：拾取、资源次数、箱子开关在住宅地/林地 2095 次往返后保持。
- 完整世界交互状态：保存覆盖全部注册区域；加载以 fresh 场景默认补全缺失区域/交互后按 `zone_id + interaction_id` 恢复，重开和同进程旧档回滚都不残留后续 mutation。
- 单槽暂停安全转场队列：暂停期间不切区，恢复后只执行一次。
- 区域内容验证：拒绝空/错误场景、重复/空 spawn 与 interaction ID、重复 bootstrap。
- 版本化独立设置：原子 `settings.cfg`、音量/显示/UI 缩放/语言/镜头与辅助选项、输入事件编解码。
- 暂停菜单设置页：中英切换、滑条/开关、键盘焦点闭环和 1280×800 高度约束。
- 响应式核心 modal：暂停、设置、按键、背包和真实 24×32 储物在 100/125/150% 与四种目标分辨率下有界，末端焦点自动滚入可见区。
- 辅助功能消费者：减少动态禁用相机平滑；高对比强化交互提示与当前目标；成功交互按设置请求活动手柄震动。
- 芦苇铲资源采集先模拟整批产出；只有全部可接收才写入背包并消耗一次，部分或零容量时双方均不变。
- 暂停菜单正式保存/读取：本地化状态、主存档语义不可应用时 backup 恢复、双损坏不改运行时。
- 储物箱双栏 UI：24 格背包、32 格容器、键鼠/手柄焦点、双向事务转移和稳定 Storage ID。
- 独立 Stage 3 家园功能 blockout：房屋、菜地、水车、码头和路径围绕上下游水道布局；普通河面真实阻挡，约 144px 角色可从 192px 桥面跨河；九个关键站位对齐 64px 网格。
- 家园上下游独立绘本水面层：世界坐标缓慢流动，视觉层不改变碰撞；减少动态冻结、高对比分离已接入现有设置服务。
- 家园 StyleProfile 与前景遮挡：35° 俯角、左上光、下右阴影和色板集中定义；主路树冠在真实玩家进入/离开时淡化/恢复，减少动态设置可即时切换。
- 家园世界坐标水粉地表、双层浅水岸线与 12 个低密度环境微粒：镜头移动不贴屏，微粒轨迹可复现并可由减少动态冻结。

## 未解决问题

- `GIT-001`：仅gh CLI登录失效；Git凭据和GitHub集成已在2026-09-16验证可用。`GIT-002`：旧开发历史包含隔离图像，禁止直接公开原开发分支；本次使用独立当前tree快照供审阅。
- `QA-001`：实体手柄硬件尚未完成 Stage 0–2 全流程人工回归；合成事件覆盖移动、modal、重映射、肩键、断连回退和震动分发。
- `ST2-016 / Medium`：屏幕震动强度与文字显示字段等待 Stage 8/10 对应系统后接入，不在当前 UI 暴露无效控件。
- `ST2-017 / Medium`：精确位置已要求 finite；区域可达/碰撞安全恢复需 Stage 4 chunk/WorldZone 边界接口。
- `ART3-003 / Medium`：清洁链仍只有不透明视觉概念；AG1 仅是解剖锚点，透明 AG2 因光晕/长腿失败。必须完成可控 down-right 重绘、真实 Alpha、四底彩边和角色本体 144 px 证据后才能考虑母图。
- `ART3-004 / Medium`：本机没有 Blender；官方 4.5.13 LTS 便携包下载被安全层拒绝，继续 2D cutout，等待明确安装授权或工具出现后完成预渲染对比。
- `ART3-005 / Medium`：主屋 A1 两次 ImageGen 输出均为烘焙棋盘 RGB；只保留视觉概念，改走分层透明重建，不得直接进游戏。

详细级别、证据和退出条件见 `docs/KNOWN_ISSUES.md`。

## 待同步 Git 范围

- 2026-09-16：GitHub集成确认 `T1doo/Capybara` 是public且当前身份有push权限，隔离外Git凭据可读远程；失效的是gh CLI登录。发现本地旧历史包含已隔离C1/D1二进制，因此禁止直接推送原开发历史或其标签。用户要求审阅当前进度，改以当前干净tree、现有远程main为唯一父提交建立 `codex/review-progress-20260916`；保留本地完整历史，不改main，不force push。快照准备与审阅边界见 `docs/REVIEW_HANDOFF.md`。

- 原开发历史及Stage标签仍仅本地保留，不以认证已恢复为由直接整体推送；先解决GIT-002的历史可达性与公开资产审计。本次快照只同步当前源码和已清理资产，不上传旧C1/D1对象。
- 本地标签：`capybara-stage-00`、`capybara-stage-00.5`；Stage 1 合并后创建 `capybara-stage-01`。
- 开发分支：`codex/autonomous-v1`。
- 在远程身份、仓库归属和可见性安全确认前，不执行 push。

## 下一任务

1. 主屋材质映射已有可见改善；继续统一两坡瓦片物理尺度、烟囱/花箱与结构边线的细节密度，保留已验证的透明、碰撞、门位和遮挡。
2. 木桥、水车和码头已有可验证模块；继续菜地和植物的材质与结构制作，收敛ENV3-001；角色 AG1 只做必要透明 cutout/最小 idle 适配。

## 恢复执行命令

```powershell
Set-Location -LiteralPath 'E:\Capybara'
git status --short --branch
git log -20 --oneline --decorate
Get-Content -LiteralPath 'CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md' -Raw
Get-Content -LiteralPath 'AGENTS.md' -Raw
Get-Content -LiteralPath 'PLANS.md' -Raw
Get-Content -LiteralPath 'docs\AUTONOMOUS_STATUS.md' -Raw
pwsh -NoProfile -File .\tools\check_project.ps1
```

若检查失败，先修复当前分支，不删除测试、不降低质量门、不使用 `git reset --hard`。
