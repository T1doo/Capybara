# 问题登记簿

问题必须有稳定 ID、严重级别、证据、缓解措施和关闭条件。关闭问题时保留记录并标记 `Closed`，不要删除历史。

## 当前开放问题

| ID | 级别 | Stage | 状态 | 问题 | 当前证据 | 缓解措施 | 关闭条件 |
|---|---|---:|---|---|---|---|---|
| GIT-001 | Low | 0.5 | Open | 历史 gh CLI 认证异常不代表当前 Git 凭据失效 | 2026-09-16接管沙箱外已核验public/ADMIN和远程refs；沙箱内凭据失败属于环境边界，当前gh CLI未单独重验 | 使用已验证的Git凭据与GitHub集成，不输出或复制token；公开同步遵守GIT-002 | 仅在实际需要gh CLI且重新验证仍失败时处理对应登录；不阻止已授权Git同步和本地工作 |
| QA-001 | Medium | 0–2 | Open | 实体手柄尚未在当前机器完成全流程人工回归 | 合成事件覆盖摇杆、十字键、Start、A、Back、肩键、重映射、断连回退与震动分发；键盘窗口复核通过 | 保持手柄输入为一等路径；获得实体设备时执行移动、modal、Storage、Save、重映射、焦点滚动和震动矩阵 | 实体通用/Xbox 布局手柄完成 Stage 0–2 全流程回归并记录结果 |
| ST2-016 | Medium | 2 | Open | `screen_shake_intensity`、`text_speed`、`instant_text` 已持久化但当前 Stage 尚无对应生产效果 | 当前尚无屏幕震动或正式对话逐字系统可消费这些字段 | 保留版本化字段；在 Stage 8 对话和 Stage 10 VFX 接入时同时增加 UI、消费者与回归，不提前显示无效控件 | 对应系统落地后设置可见、可观察、可持久化且有自动/窗口证据 |
| ST2-017 | Medium | 2–4 | In Progress | 当前地图安全落点及正式加载事务已加固；完整流送chunk和多层恢复须随Stage4/5扩展 | 61项实际碰撞/连通/备用出生点/全状态回滚；run20260916T080216355Z-p8148-b860280a通过 | 单层地图未知chunk/layer回命名安全点，正式SaveManager外层事务保护；裸flow方法不独自承担整体回滚 | Stage4真实chunk生命周期与Stage5多层行走接入后延伸位置回归；当前Stage2范围已通过 |
| ART3-003 | Medium | 3 | Open | 当前清洁链有 7 张不透明视觉概念，尚无可锁定的真实透明技术候选和四底 Alpha 彩边证据 | AG1 在独立 144 px 审查中以水豚身份 9.0/10 成为解剖锚点；AH1 因物种漂移拒绝；U2/AA2/V2/AG2 等透明尝试因长腿、光晕、宠物眼或假透明拒绝 | 不再盲抽同类透明图；从 AG1 的文字化长低体态、宽钝口鼻、小眼规则重绘可控 down-right cutout，统一耳朵、围巾、叶包、俯角与光向 | 至少一张技术候选通过真实 RGBA、无阴影/彩边、实际尺寸与独立复审，并可进入 `approved_concept` |
| ART3-004 | Medium | 3 | In Progress | Blender工具前置已解除，要求的正交预渲染对比仍未完成 | 2026-09-16现场核验官方ZIP SHA256，便携4.5.13 LTS安装及背景版本启动退出0；历史拒绝保留Stage3 LOG | 使用已安装官方工具完成统一尺寸/相机/动作的最小A/B，不扩建两条全量产线 | ART3-100具有实际样板、渲染、观感/成本/一致性对比与路线决定 |
| ART3-005 | Medium | 3 | Open | 主屋 ImageGen 视觉概念无法直接成为透明模块 | 初始 1402×1122 与一次背景提取 1403×1121 均为 `Format24bppRgb`、四角 Alpha 255，棋盘格烘焙；精确 SHA-256 与 prompt 已登记 | 停止重复背景提取；只把造型/材质当内部参考，改用可控分层透明重建并走四底/游戏尺寸/独立屋顶检查 | 分层主屋具有真实 Alpha、无彩边、屋顶/墙体/门窗/烟囱/台阶可独立控制，Godot 实景比例与遮挡通过 |

### GIT-002 — 公开推送须排除隔离图像旧历史

级别：High。Stage：3。状态：Open。

2026-09-16确认仓库public，GitHub集成与Git凭据可用；但本地5f28b3a曾纳入C1/D1 PNG，2141fda只从当前tree移除，旧对象仍可达。禁止直接推送原开发分支及其历史标签。当前进度通过独立干净快照审阅分支同步，保留本地历史；后续需设计并验证安全的长期同步历史，不得force push或在未核实的情况下把原祖先接回公开分支。

### ENV3-001 — 环境木纹与结构细节统一

级别：Medium。Stage：3。状态：Open。

主屋、桥、水车和码头的现有材质/结构仍是原型样板；码头近景有较强木纹对比和首尾重复木结，绳索/几何柱体层次不足。独立审查允许功能原型集成，不批准正式美术。后续在统一场景尺寸下调整木纹密度、对比和结构细节，检查左上光及各模块的一致性；通过家园整体截图审查后关闭，不能以自动测试通过替代。

### ENV3-002 — 正式树冠枝叶层次与树干统一

级别：Medium。Stage：3。状态：Open。

阔叶树原型改善了原圆形占位，但近景仍偏整块纹理剪影，轮廓会截断部分叶片，树干比叶片更平面。foliage_review两轮允许原型集成，没有批准正式树木。后续使用可编辑独立枝叶簇形成空隙和轮廓层次，统一树干比例、材质及接触关系；在实景远近尺寸通过审查后关闭，不为此反复重新生成整套概念。

## 已关闭问题


- `UI3-002 / High / Stage 3 / Closed`：默认手柄事件未设置全设备匹配，设备 1 无法操作界面；独立审查提示后实际复现，两个默认手柄事件构造器设置 `device=-1`，设备 1 的真实注入流程通过。鼠标测试坐标误用也保留在预览检查记录，未绕过 GUI 验收。

- `UI3-001 / High / Stage 3 / Closed`：真实预览事件测试发现本机 `ui_accept` 只有键盘映射，合成 A 键无法确认。公共 InputSetup 已最小追加 A/B、十字键与左摇杆 UI 映射，独立 headless 和 Compatibility 窗口事件验证通过；实体硬件回归仍见 QA-001。首次全套失败 8/728 保留在检查记录，不以直接调用按钮回调替代输入验收。

| ID | 级别 | Stage | 状态 | 问题 | 修复证据 |
|---|---|---:|---|---|---|
| ST0-001 | High | 0 | Closed | Stage 0 文件未提交，旧报告无法作为稳定基线 | `803b90d`、`capybara-stage-00`、统一检查 `17/17`、主场景烟雾退出码 0 |
| ST0-002 | Medium | 0 | Closed | 暂停输入仅物理键时无法兼容部分合成/逻辑键事件 | 同时登记逻辑/物理键；当前窗口 Escape、焦点和退出复核通过 |
| GOV-001 | High | 0.5 | Closed | Stage 0.5 治理、CI 和恢复闭环缺少稳定 commit | `481a140` 建立自治恢复与 CI；强制本地门 `required_checks_satisfied=true`；状态已切到 Stage 1 |
| GOV-002 | High | 0.5 | Closed | Godot 输出错误时可能仍返回 0，旧检查只看退出码会假绿 | 统一入口扫描 Godot ERROR/WARNING 诊断并以退出码 20 失败；沙箱错误路径用于回归 |
| GOV-003 | High | 0.5 | Closed | 并行检查共写 latest 文件导致日志交织和 JSON 覆盖 | 每次运行写唯一 run ID 文件；互斥锁只在运行完成后更新 latest 副本 |
| GOV-004 | High | 0.5 | Closed | staged/untracked/CI clean checkout 不受单一 `git diff --check` 充分覆盖 | 新增全仓库 Git-visible 文本格式/lint，并同时执行工作树与 cached diff 检查 |
| GOV-005 | High | 0.5 | Closed | CI 未固定 Godot 内容摘要且缺 Windows 构建烟雾 | 官方 API SHA256 固定；官方模板安装；本机 debug 导出和 EXE 启动通过；CI 强制同一门 |
| GOV-006 | High | 0.5 | Closed | 旧启动/AI/QA 文档仍能诱导逐 Stage 停止等待人工批准 | 7 个旧入口首屏停用；AI/QA 活跃流程改为自治证据审查；治理自检强制横幅 |
| ART3-001 | Blocker | 3 | Closed | 旧 C1 生成使用权利未核验的用户临时照片，后续 D1/P1/Q1/R1/S1 继承该参考链 | 整条链与旧联系表/审查移动到 `_quarantine`；活动 U/V/W 仅用已核验 CC0，Z/AA/AD 文字-only；新旧 SHA-256 无重用；独立 QA 确认权利 Blocker 关闭 |
| ART3-002 | High | 3 | Closed | 目录级 manifest 前缀匹配和未绑定输出的联系表可让未登记或被替换图片假绿 | 精确逐文件 `CANDIDATE_MANIFEST.csv`；ID/path/prompt/hash/state 枚举；mapping active-set/index 唯一性和输入/输出 SHA-256；隔离输入与错误目录负向门禁 |
| ST1-001 | High | 1 | Closed | 区域重建会丢失拾取物、资源次数和箱子状态 | `2d42196` 缓存同会话区域；139 项回归和完整 Windows 门验证三类状态往返保持 |
| ST1-003 | High | 1 | Closed | 已排队的 deferred 门转场可能穿透同帧暂停 | 149 项回归验证请求→暂停→多个 paused frame→恢复后单次转场；重复请求不叠加 |
| ST1-004 | Medium | 1 | Closed | 玩家每帧刷新会清空 InteractionSensor.active_task_id | Player 持有 stable task ID；145 项回归验证真实玩家跨多个物理帧保持任务优先，清除后恢复类型优先 |
| ST1-005 | Medium | 1 | Closed | Stage 1 生命周期与内容验证仍有多个防御缺口 | 168 项回归覆盖错误/空场景根、双 Bootstrap、悬空 target、重复 ID、无效门和输入 release/断开；soak runner 有 watchdog |
| ST1-002 | High | 1 | Closed | 正式 soak 曾绕过 Player/InteractionSensor/输入链，不能证明无目标误选 | 最终 `a9eb836` run：1200 秒、2095 次真实 Player E/A 转场、524 次重叠候选、8378 次状态检查、零诊断；独立代码/QA 复核无 High |
| ST2-001 | Medium | 2 | Closed | 运行时加载曾只允许 snapshot 区域等于当前活动区域 | run `20260830T111616904Z-p15200-9600c94a`：299/299；SceneFlow 先无变更预检 zone/spawn，再跨区恢复精确位置、Inventory/Hotbar/Storage/朝向；未知区域失败保持内存 |
| ST2-002 | High | 2 | Closed | 完整搬空源槽时转移服务从已清空的 slot 引用读取空 item_id，触发事务回滚 | Storage UI 完整堆叠回归复现；变更前捕获稳定 item_id 后 356/356；真实窗口树枝 ×7 双向整组转移通过 |
| ST2-006 | High | 2 | Closed | Settings backup 被创建但 main 损坏/缺失时不读取，后续保存可能覆盖好备份 | main 损坏与缺失均回退 backup、双损坏失败；文件句柄显式关闭；368/368 |
| ST2-007 | High | 2 | Closed | 暂停菜单内应用存档必被 SceneFlow paused 防护拒绝，陈旧 pending travel 还会覆盖恢复 | 专用 saved transition 保留 pause、取消 pending；跨区 paused restore 回归通过 |
| ST2-008 | High | 2 | Closed | `_unhandled_input` 无法可靠捕获被 GUI 消费的常用键/手柄按钮 | 捕获移至 `_input` 并在 GUI 前 handled；现有键盘/手柄事件回归通过 |
| ST2-009 | High | 2 | Closed | 双 Inventory 转移在两个 changed 信号间暴露半事务状态 | 工作模型完成事务、双侧静默提交后再通知；监听器两次均观察最终一致状态 |
| ST2-010 | High | 2 | Closed | Save validator 接受非有限坐标和非 8 格 Hotbar | `is_finite` 与固定 8 格 schema；INF 和 1 格 Hotbar 负向回归；368/368 |
| ST2-003 | High | 2 | Closed | 背包操作、快捷栏装备和工具上下文消费链曾缺少玩家路径 | 386/386；真实窗口拆分/分配/二次丢弃/整理；Q/R+肩键；芦苇铲两阶段拾取、typed 资源上下文和跨进程装备恢复 |
| ST2-004 | High | 2 | Closed | Save v1 曾缺正式玩家入口、恢复提示和语义不可应用 main 的 backup 回退 | 397/397；暂停菜单真实保存/读取；完整 load+preflight+apply 主文件失败后尝试 backup；语义损坏/双损坏回归；856×511 真实窗口键盘复核 |
| ST2-005 | High | 2 | Closed | 显示矩阵曾未完整实测，三个可见辅助设置没有生产消费者 | 608/608 专项；填充后的 24×32 Storage 在内的 4×3×5 矩阵逐项验证末端焦点自动滚入视口；正式设置 UI 完成窗口→全屏→窗口及 1280×800 往返；三项消费者均可观察 |
| ST2-011 | High | 2 | Closed | 响应式 modal 曾未跟随键盘/手柄焦点，末端控件可在高缩放时移出视口 | `follow_focus=true`；4 分辨率×3 缩放×5 个真实填充 modal 将焦点从首控件送到末控件并验证其中心位于可见区；150% 设置/Storage 窗口复核 |
| ST2-012 | High | 2 | Closed | 高对比目标曾使用不传给可见子图形的 `self_modulate` | 改用父 CanvasItem `modulate`；测试验证实际目标父调制，真实窗口中提示与当前拾取目标均明显变黄 |
| ST2-013 | High | 2 | Closed | 世界交互提示曾在重映射后仍固定显示 E/南键 | 提示从当前 InputMap 按活动设备格式化；F/X 重映射生产提示回归通过；恢复默认立即显示 E/A |
| ST2-014 | High | 2 | Closed | 半推摇杆绑定可保存却无法重启读取，且快捷栏前后动作不可重映射 | 捕获轴值规范化为 ±1；支持事件集合/范围与 modifier 编解码对齐；Q/R 与左右肩键纳入 9 动作重映射；独立进程精确绑定恢复通过 |
| ST2-015 | High | 2 | Closed | Save v1 曾不保存拾取/资源差量，资源采集还会扣次数但不给背包收益 | `zone_id + interaction_id` 世界差量预检/应用；资源需芦苇铲并在背包提交后扣次数；三进程真实拾取/采集→保存→重开验证防重复与剩余次数 |
| ST2-018 | High | 2 | Closed | 世界差量曾只覆盖存档中出现的区域/交互，加载旧档会保留保存后的未列出 mutation | 保存捕获全部注册区域；加载从 fresh 场景默认补全缺失区域/交互后完整应用；回归覆盖 Home 保存后修改 Grove 及缺失 Pickup entry 均恢复默认 |
| ST2-019 | High | 2 | Closed | 多产出资源在背包仅能部分接收时会扣一次 use 并丢失 remainder | Bootstrap 先 simulate 全量产出，仅完整可接收时真实提交；断言 yield=5/available=1 零变更，腾出容量后精确 +5 且只扣一次；616/616 |

## 新问题模板

```text
ID：AREA-NNN
级别：Blocker / Critical / High / Medium / Low
Stage：
状态：Open / In Progress / Closed
问题：
复现或证据：
影响：
缓解措施：
关闭条件：
关联 commit/test/screenshot：
```

## 2026-09-16 接管审阅登记

基准 `79092c078c63c1e1d5a6d056ebcedf8401a9ac59`；来源 imported_review / static_analysis，运行复现结果在所属阶段LOG另记。下表关闭前不得把推断写成已复现，也不得因历史通过而忽略组合序列。

| ID | 级别 | Stage | 状态 | 证据与影响 | 关联任务 / 关闭条件 |
|---|---|---|---|---|---|
| R-CI-01 | High | 0.5 | In Progress | 历史CI 35062299753资产exit22；本轮run 20260916T073251372Z-p43016-602f2eaa实际同样失败；SVG LF/CRLF字节hash差异 | AUT-0059；新Windows检出/autocrlf正反、篡改/隔离拒绝和exact SHA完整CI |
| R-SAVE-01 | High | 2 | Closed | 已复现原备份污染；保存前真实库存/区域/world适用性检查、持久隔离及IO失败拒绝；隔离失败/容量不适用/跨进程再保存再损坏回归均通过 | ST2-R001；Stage2 LOG reliability-integration，run20260916T080216355Z-p8148-b860280a，19/19与61事务检查 |
| R-HOTBAR-01 | High | 2 | Closed | 原16/27失败；整理/移动/合并映射全部绑定，耗尽/整堆箱转清空；旧schema1及跨进程装备/UI一致 | ST2-R002；35项专项、独立审阅及run20260916T080216355Z-p8148-b860280a |
| R-INTERACT-01 | High | 2 | Closed | 原满包成功反馈已复现；请求与提交分离，最终数量/事件/震动在实际提交后，replay及读档旧pending拒绝 | ST2-R003；63项专项、独立审阅及run20260916T080216355Z-p8148-b860280a |
| R-DOC-01 | High | 0.5 | In Progress | 旧恢复线、双backlog、旧启动入口硬锁与RC状态失真 | AUT-0060/0061；14阶段唯一任务源、路径/依赖/证据正负检查及全门通过 |
| R-CI-02 | High | 0.5 | In Progress | 实际远程02ac9b37ed6eed7d8b12261c0d9772a30704d8f7 / run35069530550 / artifact10435003811：svg_cutout_render exit20及166 class_name解析诊断；SVG资产与10检出回归已过，导入前脚本依赖不存在的全局类缓存 | AUT-0062；版本/导入前置所有Godot脚本，干净缓存回归和exact SHA全CI成功 |

R-POS-01 是 ST2-017 的审阅别名，不另维护状态；任务 ST2-R004 前置到正式家园替换前。R-GIT-01 是 GIT-002 的审阅别名。GIT-002当前安全线已从审阅SHA建立为 `codex/production-clean-20260916`；旧开发/main/tag仍本地保留且禁推，首次新线push还须审计全部待推祖先与LFS对象。

GOV-006 的历史“保留七入口横幅”关闭依据仅描述旧治理；本次R-DOC-01用实际删除重复入口和新结构检查取代该方法，保留失败历史不等于保留失效规则。
