# 自治质量门

本文件把目标契约的 Stage 退出条件转换为可审计证据。目标契约仍是最终权威来源；本文件不得降低其要求。

## 1. 证据规则

- “实现了”不等于“通过了”；必须有当前文件、退出码、日志、截图、性能记录或人工复核证据。
- 无法验证的要求记为 `Not Verified`，不得记为通过。
- Blocker、Critical 和 High 问题必须在 Stage 合并到 `main` 前关闭。
- 自动测试不能替代手感、视觉、音频和实体硬件检查。
- 视觉 Stage 必须保留固定场景截图并完成构图、风格和技术三轮审查。
- 每个 Stage 通过后才允许合并、创建 Stage tag 和更新稳定状态。

## 2. 每个提交的共同质量门

- [ ] 改动范围单一且可解释，没有未知用户文件被覆盖。
- [ ] Godot 版本仍为 `4.7.2.stable.official.ed1daf0bf`。
- [ ] `tools/check_project.ps1` 退出码为 `0`。
- [ ] 相关新增测试实际执行并通过。
- [ ] 全仓库格式/lint、`git diff --check` 和 `git diff --cached --check` 全部通过。
- [ ] 缓存、构建、密钥、个人路径和未筛选原始 AI 输出未进入提交。
- [ ] 玩家可见文本使用稳定本地化 key。
- [ ] 受影响的计划、状态、backlog、决策和问题文档已更新。

## 3. Stage 质量门

### Stage 0 — 工程基线

- [x] Godot 项目可导入和启动。
- [x] 移动、归一化、最后方向、碰撞、相机和暂停存在。
- [x] 键盘和手柄输入路径有自动测试。
- [x] 自动测试 `17/17` 通过。
- [x] 主场景烟雾退出码 `0`。
- [x] 检查脚本正确传播退出码。
- [x] 稳定 commit `803b90d` 与标签 `capybara-stage-00` 已建立。

### Stage 0.5 — 自治治理

- [x] 目标契约被 `AGENTS.md` 引用为 Stage 0 后最高优先级。
- [x] `PLANS.md`、自治状态、质量门、问题表、发布准备、依赖和恢复说明齐全。
- [x] 旧启动入口、路线图、技术、美术、AI 流水线、QA、backlog 与目标契约一致。
- [x] 统一检查生成唯一 run 文本日志和 JSON 摘要，并可靠记录失败 step、超时、宿主、branch 和 commit。
- [x] 治理自检验证必需文件、旧入口停用标记、绝对路径规则和 backlog 依赖图。
- [x] Windows CI 固定 `windows-2022`、官方 Godot 4.7.2 和 GitHub 官方 action commit；YAML 静态解析通过。
- [x] CI 校验编辑器/模板 SHA256；本机已实际完成 Windows debug 导出和 EXE 启动烟雾。
- [x] 全仓库格式/lint、Godot ERROR/WARNING 假绿、并行日志和 staged/untracked 覆盖有回归证据。
- [x] 回退流程不依赖破坏性 reset，稳定点可由 commit/tag 恢复。
- [x] 新会话只读仓库即可确定当前 Stage、测试、问题和下一任务。
- [x] 独立代码/文档审查与 QA 审查完成，未剩余未登记 High 以上问题。

GitHub 远程认证当前失效，首次远程 CI 运行和 push 按契约条件项登记在 `GIT-001`；本地同构强制构建门已通过，不盲目伪造远程证据。

### Stage 1 — 玩家状态、交互和场景基础

- [x] Idle、Move、Interact、Disabled 状态互斥且可测试。
- [x] 8 方向 facing 数据稳定；移动/表现解耦。
- [x] typed Interactable 协议、上下文和结果类型完成。
- [x] 交互候选按任务、类型、朝向、距离和稳定 ID 确定性排序。
- [x] 拾取物、资源点、床、箱子、门和 NPC 使用统一协议。
- [x] 输入设备识别和提示切换有自动测试，键盘提示完成真实窗口复核。
- [x] F3 调试覆盖层显示区域、状态、朝向、目标、设备与实例计数；129 项回归和真实窗口复核通过。
- [ ] 键鼠和实体手柄完整导航回归通过；实体设备证据见 `QA-001`。
- [x] 区域转场和出生点不复制玩家、不丢状态；住宅地/林地往返集成测试通过。
- [x] 20 分钟灰盒 soak 无卡死、暂停穿透、目标误选或转场状态丢失；最终 `a9eb836` 正式 run 通过。

### Stage 2 — 数据、背包、设置、本地化和可靠存档

- [x] ItemDefinition 使用 typed Resource 和稳定 ID；内置内容启动验证。
- [x] ContentRegistry 事务加载并拒绝 null、非法数值、重复 ID/标签；查询顺序稳定。
- [x] 24 格背包的容量、堆叠、溢出、拆分、排序和任务物品规则通过 200 次确定性随机回归。
- [x] 本地化 24 格背包/8 格快捷栏 UI 通过 Tab/Back、方向焦点、Esc modal 和 720p 自动/真实窗口复核。
- [x] Inventory/Hotbar/Storage 纯数据编解码严格验证 schema、稳定 ID、容量和堆叠，失败不改变内存状态。
- [x] 背包拆分/丢弃确认/任务拒绝/排序、快捷栏分配与世界选择、Storage 和芦苇铲 typed 上下文消费链通过键鼠/手柄路径。
- [x] 版本化 SettingsProfile 与键盘/手柄事件编解码通过；独立 `settings.cfg` 原子写入、重读校验和损坏拒绝不污染当前设置。
- [x] 设置运行时应用覆盖音量、语言、输入、缩放、镜头与全部可见辅助选项；真实填充内容的 4×3×5 响应式显示/末端焦点矩阵通过。
- [x] 9 个动作支持键盘/手柄分别重映射；半推摇杆规范化、modifier round-trip、恢复默认预览和 F/X 世界提示同步通过。
- [x] 设置、显示、UI 缩放、输入重映射和辅助功能基础可持久化；独立 write/read/cleanup Godot 进程恢复回归通过。
- [x] `zh_CN` / `en` 切换与缺失 key 检查通过；112 个双语键唯一且非空，87 个正式引用全部解析。
- [x] Save v1 的 temp/backup/损坏/迁移、暂停菜单正式入口、恢复提示和语义不可应用 main 的 backup 回退均通过。
- [x] 跨区域 snapshot 先预检 zone/spawn/world delta，再恢复 Inventory/Hotbar/Storage、精确位置/朝向、拾取/资源状态和 UI 绑定；未知目标失败不改变内存。
- [x] 200 次随机物品事务不丢失；独立进程走真实拾取/采集后，区域、位置、Inventory、Hotbar、Storage 与 `zone_id + interaction_id` 差量一致且不可重复获取。
- [x] 最终 exact clean run `20260903T041100794Z-p23616-cf38b6eb` 对应 `c7f91fe`，616/616、全部统一步骤和零诊断通过；独立代码/QA 终审均为 0/0/0。

### Stage 3–12

各 Stage 必须逐项满足目标契约第 13 节的交付与退出标准；RC1 还必须满足第 14 节全部 Definition of Done。实施到相应 Stage 时，在本文件增加可执行命令、样本量、性能阈值、截图列表和证据链接，不得只复制抽象描述。

### Stage 3 当前执行门

- [x] 主角清洁 visual-concept、逐文件 provenance、联系表和独立视觉/政策审查已建立；AG1 视觉方向已锁定，但尚不是透明母图。
- [x] 家园 A1 visual-concept 通过两条独立审查；只允许作为色彩、构图、水系骨架和模块清单参考。
- [ ] 家园地标模块达到透明、分层、统一投影和游戏尺寸门。
  - [x] 主屋 A1 视觉概念完成来源、提示词与哈希登记；建筑结构与绘本材质可作分层重建参考。
  - [x] 主屋改用三层SVG并接入绘本材质，真实Alpha、四底、门位/碰撞与屋顶淡化通过；此为技术与原型材质集成，不代表整屋正式美术批准。
  - [x] 独立木桥模块702项整套回归及五视角检查通过，前后栏杆排序和独立碰撞有实际证据。
- [x] 独立家园功能 blockout 使用 64px 网格与约 144px 玩家；九个稳定站位、上下游阻挡多边形和桥面通行由自动测试覆盖。
- [ ] 主角透明技术适配、四方向母图与 cutout/Blender 方案对比完成。
- [ ] 地面、水岸、水面、植物、房屋、家具、NPC 和 UI 的高品质模块样板在真实场景通过。
- [ ] 动态水、光照、阴影、遮挡、环境粒子与减少动态兼容通过。
  - [x] 世界坐标动态水完成 Compatibility GPU 三帧捕获；减少动态 `motion_strength=0`、普通动态 `=1`、高对比分离均由自动测试验证。
  - [x] 家园 StyleProfile 固定 35° 俯角、左上光、下右接触阴影、64px/144px 尺度和色板；树冠真实进入/离开淡化与减少动态即时切换通过。
  - [x] 世界坐标水粉地表、18/8px 双层岸线和 12 个确定性微粒通过 Compatibility GPU 捕获；减少动态冻结微粒时间。
  - [ ] 局部岸边泡沫、更细致模块阴影与四种时段/天气参数仍待完成。
- [ ] 上午、黄昏、雨天、夜晚四套真实游戏截图完成三轮审查，且无 Blocker/Critical/High。

## 4. 严重级别

| 级别 | 定义 | Stage 行为 |
|---|---|---|
| Blocker | 无法启动、数据破坏、主流程完全阻断、安全或侵权风险 | 立即修复，停止合并与新功能 |
| Critical | 高频崩溃、存档丢失、关键流程不可完成 | 立即修复，不得合并到 `main` |
| High | 质量门缺失、可靠复现的严重交互/视觉/性能问题 | 当前 Stage 合并前修复 |
| Medium | 有绕过方法、不阻断当前 Stage 核心门 | 进入明确近期任务与负责人 |
| Low | 轻微文本、视觉或体验瑕疵 | 进入 polish backlog |

## 5. 统一检查命令

```powershell
pwsh -NoProfile -File .\tools\check_project.ps1
```

期望产物：

```text
build/logs/check_project-<run-id>.log
build/logs/check_project-<run-id>.json
build/logs/check_project-latest.log
build/logs/check_project-latest.json
```

每次运行先写唯一 run ID 文件，完成后通过互斥锁更新同一 run 的 latest 副本，避免并行检查交织。Godot 输出包含 `ERROR:`、`SCRIPT ERROR:` 或 `WARNING:` 时，即使原生进程码为 `0`，检查也必须失败。统一入口对所有 Git-visible 文本执行格式/lint，并同时检查工作树与 cached diff。脚本退出码非 `0` 时自动失败；JSON 的 `required_checks_satisfied=false` 表示本地可执行检查通过但 Windows 导出门被明确跳过，不能作为完整 Stage/CI 通过证据。
