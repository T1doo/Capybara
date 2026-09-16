# 02 技术设计文档

版本：2.0
日期：2026-08-30  
目标引擎：Godot 4.7.2 Standard

> Stage 0 之后以 `CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md` 为最高优先级。本文件保留早期系统细节，并新增大型世界流送、自治质量证据和恢复要求。

## 1. 技术目标

- 用可验证小批次、实际运行证据和恢复点控制风险。
- 保持系统数据驱动，避免每增加一种作物或鱼都改代码。
- 存档可迁移、可备份、可诊断。
- 键鼠与手柄从第一天共同支持。
- 支持 1280×720、1920×1080、2560×1440 和 1280×800。
- 以 60 FPS 为目标，避免昂贵后处理和大量实时光源。
- 不依赖大量第三方插件。

## 2. 固定技术栈

- Godot 4.7.2 Standard。
- GDScript，静态类型。
- Compatibility renderer。
- Git + Git LFS。
- Windows PowerShell 自动化。
- JSON 版本化存档。
- Godot 自定义 `Resource` 存储游戏定义数据。
- v1.0 不包含运行时网络服务。

## 3. 项目目录

```text
game/
  project.godot
  autoload/
    app.gd
    save_manager.gd
    settings_manager.gd
    audio_manager.gd
    event_bus.gd
  core/
    ids.gd
    result.gd
    grid_math.gd
    version.gd
  data/
    definitions/
      items/
      crops/
      fish/
      buildables/
      npcs/
      quests/
      recipes/
  assets/
    characters/
    environment/
    buildings/
    items/
    ui/
    audio/
  localization/
    translations.csv
  scenes/
    bootstrap/
    player/
    world/
    npc/
    interactables/
    ui/
    minigames/
  systems/
    inventory/
    interaction/
    world_grid/
    building/
    farming/
    water/
    fishing/
    npc/
    quest/
    time/
  tests/
    run_all.gd
    unit/
    integration/
  tools/
```

目录可在开发中细化，但不应随意移动大量资源路径。

## 4. 项目设置

### 4.1 显示

- 基础逻辑分辨率：1280×720。
- 窗口可调整大小。
- Stretch mode：适合 2D Canvas 的方式。
- Aspect：`expand`，让 16:10 显示额外视野，而不是拉伸。
- UI 全部使用 anchors/containers。
- 1280×800 下最小常规正文字号建议 18 px，关键按钮 20–24 px。
- 提供 100%、125%、150% UI 缩放选项。

### 4.2 渲染

- Compatibility renderer。
- 以 2D Sprite、TileMapLayer 和轻量 Shader 为主。
- 阴影主要使用预制半透明 Sprite，不依赖大量实时灯光。
- 后处理默认关闭或极轻。
- 不把画面品质依赖于单一高级 GPU 特性。

### 4.3 物理与网格

- 逻辑格尺寸：64×64 像素。
- 玩家可自由平滑移动，建造、农田和水体按网格对齐。
- 固定物理 tick 使用 Godot 默认值，除非性能测试证明需要调整。
- 碰撞层和遮罩必须命名。

建议初始物理层：

1. Player
2. WorldSolid
3. Interactable
4. NPC
5. ResourceNode
6. Water
7. PlacementBlocker
8. Trigger

## 5. 启动与场景结构

`main.tscn` 负责启动，不承载全部游戏逻辑：

```text
Main
  CurrentWorldContainer
  PersistentUI
  TransitionLayer
  DebugOverlay（仅调试构建）
```

以下是职责划分示例，并非已实现 Autoload 名称或必须创建的清单；实际服务以 project.godot 为准：

- `App`：应用状态、版本、当前存档槽和高层流程。
- `SaveManager`：保存、读取、备份和迁移。
- `SettingsManager`：音量、画面、输入和辅助功能。
- `AudioManager`：音乐与音效总线。
- `EventBus`：少量跨系统信号。

禁止把所有玩法塞入一个 `GameManager`。

## 6. 数据驱动定义

每种内容使用稳定 ID 与自定义 Resource。

### 6.1 ItemDefinition

建议字段：

- `id: StringName`
- `name_key: StringName`
- `description_key: StringName`
- `icon: Texture2D`
- `category: ItemCategory`
- `max_stack: int`
- `sell_price: int`
- `tags: Array[StringName]`
- `world_scene: PackedScene`

### 6.2 CropDefinition

- `id`
- `seed_item_id`
- `harvest_item_id`
- `growth_days`
- `stage_sprites`
- `requires_water`
- `regrow_days`
- `season_rules` 在早期 Stage 可暂不激活，但 RC1 必须支持目标契约规定的季节状态、内容条件和存档迁移。

### 6.3 FishDefinition

- `id`
- `name_key`
- `icon`
- `difficulty`
- `valid_zones`
- `time_windows`
- `water_requirements`
- `sell_price`

### 6.4 BuildableDefinition

- `id`
- `name_key`
- `preview_texture`
- `scene`
- `footprint: Array[Vector2i]`
- `allowed_surfaces`
- `rotation_variants`
- `cost`
- `comfort_tags`
- `blocks_navigation`

### 6.5 NpcDefinition

- `id`
- `name_key`
- `portrait_set`
- `world_scene`
- `schedule_id`
- `likes_tags`
- `relationship_thresholds`

定义数据是只读模板；运行状态保存到独立状态对象中。

## 7. 稳定 ID 规则

- 使用英文小写 `snake_case`。
- 一旦进入发布存档，不随显示名称更改。
- 示例：`item_reed_bundle`、`crop_water_spinach`、`npc_otter_builder`。
- 删除内容时保留迁移表，不复用旧 ID。
- 所有外键在项目检查中验证存在。

## 8. 玩家系统

### 8.1 节点结构

```text
Player (CharacterBody2D)
  VisualRoot
  AnimationPlayer/AnimatedSprite2D
  CollisionShape2D
  InteractionArea
  ToolOrigin
  Camera2D
  StateMachine
```

### 8.2 移动

- 输入向量归一化，斜向速度不得更快。
- 移动与视觉动画分离。
- 保存最后非零朝向。
- 允许在设置中开启/关闭镜头平滑。
- 所有移动速度由配置定义，不散落在代码中。

### 8.3 状态

初始状态：

- Idle
- Move
- Interact
- ToolUse
- Fishing
- BuildMode
- Disabled/Cutscene

状态切换必须防止同时移动与执行互斥动作。

## 9. 交互系统

定义通用接口或组件：

```gdscript
func can_interact(context: InteractionContext) -> bool
func get_interaction_prompt(context: InteractionContext) -> StringName
func interact(context: InteractionContext) -> InteractionResult
```

要求：

- 交互候选按距离、朝向和优先级排序。
- UI 只显示当前最高优先对象。
- 交互失败返回可本地化原因，不静默失败。
- NPC、储物箱、资源点、床和门使用同一高层协议。

## 10. 世界与 TileMapLayer

每个区域场景建议使用多个 `TileMapLayer`：

```text
GroundBase
GroundDetail
Soil
Water
Paths
LowDecor
ObjectsBack
ObjectsFront
RoofForeground
```

- 不使用已弃用的旧 `TileMap` 作为新系统基础。
- 水岸、道路和地面过渡使用 TileSet terrain 规则。
- 所有可修改格状态由 `WorldGridState` 管理，TileMap 只负责表现。
- 运行时修改后，存档记录区域 ID、格坐标、层和状态。
- 地图边界、不可挖区和建造区使用数据遮罩。

## 11. 建造系统

### 11.1 流程

1. 玩家选择配方或家具。
2. 创建半透明预览。
3. 将鼠标/手柄指针吸附到网格。
4. 检查占地、表面、边界、碰撞和任务保护区。
5. 有效时显示确认色与成本。
6. 确认后扣除材料并生成对象。
7. 给实例分配稳定实例 ID。
8. 更新导航阻挡与存档脏标记。

### 11.2 实例状态

保存：

- `instance_id`
- `definition_id`
- `zone_id`
- `grid_origin`
- `rotation`
- `variant`
- `custom_state`

### 11.3 撤回与移动

- 家具可进入移动模式。
- 普通家具收回返还全部物品。
- 任务建筑不允许误拆。
- 水体填平与大型建筑拆除需要确认。

## 12. 农田系统

每个农田格保存：

- 地块状态。
- 作物定义 ID。
- 当前阶段。
- 已生长天数。
- 今日是否湿润。
- 是否由附近水体自动灌溉。
- 肥料预留字段。

跨日时批量更新，不每帧计算作物成长。

自动灌溉：

- 根据水体格或水渠格的曼哈顿/配置半径判断。
- 缓存灌溉影响范围。
- 水体改变时只重算受影响区域。

## 13. 水体系统

### 13.1 数据模型

每个可修改格可处于：

- Ground
- DugSoil
- ShallowWater
- Channel
- Protected

水体编辑后：

- 更新 TileMapLayer 表现。
- 更新碰撞。
- 更新相邻岸边。
- 标记连通区域需要重算。
- 更新灌溉缓存。
- 更新 NPC 路径阻挡。

### 13.2 连通水体

使用洪泛或并查集在编辑后重建受影响的局部连通区域。每个水体得到：

- `water_body_id`
- 格子集合或边界摘要。
- 面积。
- 水生植物计数。
- 邻近家具标签。
- `comfort_score`
- 可钓鱼状态。

先保证正确，再用受影响区域增量重算。早期垂直切片可在单 chunk 内验证；大型世界必须维护 chunk 内连通摘要和跨 chunk 邻接图，编辑时只重算局部及相邻边界，不得洪泛整个世界。

### 13.3 视觉

- 水面可使用轻量动画 Tile 或简单 UV Shader。
- 岸边使用 terrain 自动连接。
- 玩家进入浅水时切换脚步声和局部遮罩。
- 泡水使用独立姿势与水面前景遮挡，不改变玩家碰撞体。

## 14. 背包与物品交易

- 背包状态是若干 `InventorySlot`，只保存物品 ID 和数量。
- 所有增减通过单一服务执行，返回明确结果。
- 支持模拟操作，用于建造前检查成本。
- UI 不直接修改数据。
- 任务物品带标签，禁止出售。
- 交易价格来自定义数据，不写在商店 UI。

## 15. 钓鱼系统

拆成三个部分：

- `FishingSpot`：是否可钓、使用哪个鱼池表。
- `FishingRoll`：根据区域、时间、水体条件和随机种子决定候选。
- `FishingMinigame`：纯玩法状态，不直接发放奖励。

完成后由服务验证并添加物品。保留调试种子，便于复现测试。

## 16. NPC、路径和日程

- 初期采用 `AStarGrid2D` 或自建网格路径，适合可建造的 64px 网格。
- 建筑和水体改变后只更新相关阻挡格。
- NPC 状态：Idle、Move、Activity、Talk、Scripted。
- 日程以数据定义：时间段、目标位置、活动类型和备用点。
- NPC 找不到路径时停在安全点并记录警告，不能穿墙或永久卡死。
- 重要剧情使用明确脚本节点，不依赖日程碰巧触发。

## 17. 对话与任务

第一版使用简单、可本地化的数据结构，不开发复杂可视化编辑器。

对话节点建议字段：

- `node_id`
- `speaker_id`
- `text_key`
- `portrait_expression`
- `choices`
- `conditions`
- `effects`
- `next_node_id`

任务状态：Locked、Available、Active、Completed、Failed（v1 大多不使用 Failed）。

效果必须走白名单命令，例如：

- give_item
- remove_item
- set_flag
- add_relationship
- unlock_recipe
- unlock_zone
- start_cutscene

不得执行任意脚本字符串。

## 18. 时间系统

- 时间服务使用游戏内分钟，但跨日成长由日事件处理。
- 暂停、菜单和对话是否暂停时间由统一策略决定。
- 垂直切片可先只实现“睡眠推进一天”。
- 以后加入昼夜时，旧存档默认映射到安全上午时间。

## 19. 保存系统

### 19.1 文件

```text
user://saves/slot_01.json
user://saves/slot_01.bak.json
user://saves/slot_01.meta.json
```

### 19.2 顶层结构

```json
{
  "schema_version": 1,
  "game_version": "0.1.0",
  "save_id": "...",
  "saved_at_utc": "...",
  "play_time_seconds": 0,
  "player": {},
  "inventories": {},
  "world": {},
  "world_state": {},
  "quests": {},
  "relationships": {},
  "settings_snapshot": {}
}
```

### 19.3 规则

- 保存前构建纯数据，不保存 Node 引用。
- 先写临时文件，验证可重新解析后再替换正式文件。
- 替换前保留上一个有效备份。
- 每次读取验证字段类型与默认值。
- Stage 2 世界交互状态以 `zone_id + interaction_id` 保存全部注册区域的拾取剩余数量和资源剩余次数；缺失项从 fresh 场景默认补全，不得沿用保存后的 cache mutation。
- 世界差量与区域/spawn 一起预检；未知区域、未知交互 ID 或类型不匹配时不提交运行时状态。
- 使用顺序迁移函数：v1 -> v2 -> v3。
- 损坏时尝试备份并向玩家显示清楚提示。
- 自动保存不能在切场景或写盘中重复触发。
- Steam Cloud 只同步稳定保存目录，不同步缓存和设置日志。

## 20. 设置与辅助功能

第一版包括：

- 主音量、音乐、音效。
- 全屏/窗口。
- 分辨率。
- UI 缩放。
- 镜头平滑。
- 屏幕震动强度或关闭。
- 文字速度与瞬间显示。
- 输入重映射。
- 手柄震动开关。
- 高对比交互轮廓。
- 减少动态背景选项。

设置独立于游戏存档，写入 `user://settings.cfg`。

## 21. 本地化

- 首期框架支持 `zh_CN` 和 `en`。
- 所有玩家可见文本使用稳定键。
- 不把文字绘制进图片。
- UI 预留中文、英文长度差异。
- 数量、日期和按键图标通过格式化函数生成。
- 资产名称和内部 ID 不翻译。

## 22. 音频

建议总线：

```text
Master
  Music
  Ambience
  SFX
  UI
```

- 脚步、工具、水声、拾取和 UI 均有独立类别。
- 同类短音效支持少量变体，降低重复感。
- 场景氛围按区域淡入淡出。
- 音频素材必须登记许可证和作者。

## 23. 测试策略

不依赖第三方测试插件的起步方案：

- `tests/run_all.gd` 汇总纯逻辑测试。
- 单元测试覆盖网格数学、库存增减、建造占地、水体连通、存档迁移和鱼池抽取。
- 集成测试场景覆盖玩家移动、交互、放置、跨日和保存读取。
- PowerShell 脚本执行 headless 导入和测试。
- 任何已修复严重 Bug 都增加回归测试或固定手工步骤。

## 24. 诊断与日志

- 使用统一日志前缀和严重级别。
- 发布版不显示调试覆盖层。
- 严重保存错误写入 `user://logs/`，不得包含隐私或密钥。
- 关键随机系统允许记录 seed 以复现。
- 开发版提供当前格坐标、区域 ID、FPS 和交互对象显示。

## 25. 导出与构建

- 先只建立 Windows x86_64 导出预设。
- 构建输出到 `build/windows/`。
- 构建前运行项目检查与测试。
- 构建文件名包含版本和渠道，例如：

  `capybara_0.1.0_playtest_win64.exe`

- 不把 Steamworks SDK 复制进仓库公共目录。
- Steam 集成在垂直切片稳定后进行。

## 26. 版本与升级政策

- 项目锁定 Godot 4.7.2。
- 任何升级先创建独立分支并备份。
- 阅读迁移说明，运行完整回归。
- 只有解决明确问题或获得重要收益时升级。
- 不因 Codex 本地安装了更高版本就自动转换项目。

## 27. 大型世界与分块流送基线

- 最终世界由高密度手工核心地区、独立内部场景、确定性程序化外围和分块流送共同组成。
- 永久世界 ID 使用 chunk 坐标、局部格坐标、生成器版本和稳定实例 ID，不使用显示名或大范围像素浮点坐标。
- 初始候选 chunk 尺寸为 32×32 或 48×48 个 64px 逻辑格，由 Stage 4 性能、生成和可达性测试决定。
- 活跃环从 3×3 chunks 起步，支持移动方向预加载、休眠、卸载和对象池；不得每帧重算整个世界。
- 同一 seed、生成器版本和 chunk 坐标必须产生相同基础内容。
- 只保存已探索 chunk 的版本和玩家差量；生成器升级不得无声改变已探索区域。
- 手工地区可使用 chunk 化场景或数据模板，但地标、路径、剧情保护区和视觉构图必须人工审查。
- Stage 4 必须覆盖确定性、可达性、重复率、资源密度、重载一致性、60 分钟探索和内存证据。

## 28. 自治检查、CI 与恢复

- `tools/check_project.ps1` 是统一检查入口；每次运行生成唯一 run ID 的文本日志和 JSON 摘要，并通过互斥锁更新同一 run 的 latest 副本。
- Godot 输出中的 `ERROR:`、`SCRIPT ERROR:` 和 `WARNING:` 视为失败证据，不能只信任原生退出码。
- 检查入口覆盖治理文件、Godot 精确版本、导入/解析、自动测试、主场景烟雾和 Git 空白错误。
- GitHub CI 使用 Windows runner、官方 Godot 4.7.2 Standard 包和锁定 commit 的 GitHub 官方 actions。
- 当前 Stage、稳定 commit/tag、测试退出码、问题和下一任务记录在 `docs/STATUS.md`。
- 回退优先使用原子 commit、Stage tag、`git revert` 和恢复分支；禁止破坏性 reset 和 force push。
- 每个 Stage 扩展统一测试入口，而不是建立互相竞争的检查脚本。

## 29. 当前架构边界与后续消费者

DEC-014 的两区域节点缓存仅适用于当前灰盒；Stage4必须分离WorldData/ChunkData与节点并限制活跃集、真正卸载，不把缓存改名chunk。稳定ID使用整数chunk/局部坐标与generator版本，跨块河流/道路/高度/可达性须一致。

Stage5前置最小GameClock/环境条件、轻量目标消费者、NPC设施导航/使用及基础音效；Stage6农业跨日离块一致，Stage7钓鱼、Stage8日程复用同一条件源。完整天气/季节视听在Stage10扩展，数据前置不代表后续阶段完成。

DEC-016/017：库存模拟后事务提交，存档完整验证纯数据后应用。DEC-018/019/021保留有效备份与完整世界替换意图；R-SAVE-01需进一步证明运行时不可应用主档不能轮换污染好备份，ST2-017需碰撞安全落点和整体失败回滚。DEC-020/022：响应式modal焦点跟随、真实辅助消费者、9动作重映射和实际InputMap提示。正式交互成功信号必须在库存/资源提交后发出。

默认all_resources导出仍为Debug开发烟雾，Stage12须独立Release排除测试/调试/未批准资产并审计包内清单，不能以重命名Debug构建验收RC。
