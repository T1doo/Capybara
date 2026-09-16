# Capybara 完整开发方案（供 Codex 使用）

> [!WARNING]
> **历史启动快照 / 已停用。** 这是原 v1.1 启动包的合并存档，不是当前执行契约。Stage 0 之后必须读取 `CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md`、`AGENTS.md`、`PLANS.md` 和 `docs/AUTONOMOUS_STATUS.md`；文件内部旧的工具路径、范围上限、逐 Stage 停止和 Git 禁令均由目标契约 v2 取代。

版本：1.1（`E:\Capybara` 定制版）  
日期：2026-08-30

> 本文件是模块化启动包的合并版。项目固定根目录为 `E:\Capybara`。Codex 最佳用法仍是直接读取整个项目文件夹；只有无法访问模块化文件时才使用本单文件。


---

# 从这里开始：E:\Capybara 定制版

版本：1.1（E 盘定制版）  
日期：2026-08-30

本启动包已经按照以下固定项目根目录重新整理：

```text
E:\Capybara
```

## 1. 解压位置

请先备份你当前的 `E:\Capybara`，然后把压缩包里的**全部内容直接解压到**：

```text
E:\Capybara
```

解压完成后的正确结构应当是：

```text
E:\Capybara\AGENTS.md
E:\Capybara\MASTER_PROMPT_FOR_CODEX.md
E:\Capybara\SEND_TO_CODEX_FIRST_MESSAGE.txt
E:\Capybara\SEND_TO_CODEX_AFTER_PLAN.txt
E:\Capybara\docs\01_GAME_DESIGN.md
```

不要出现下面这种多套一层的结构：

```text
E:\Capybara\Capybara_E_Drive_Codex_Pack\AGENTS.md
```

本版本已经包含可直接使用的 `.gitignore`，不需要再重命名 `.gitignore.template`。旧目录中若还留有 `.gitignore.template`，可以删除。

## 2. 用 PowerShell 检查文件是否放对

打开 PowerShell，依次运行：

```powershell
Set-Location 'E:\Capybara'
Test-Path '.\AGENTS.md'
Test-Path '.\MASTER_PROMPT_FOR_CODEX.md'
Test-Path '.\docs\01_GAME_DESIGN.md'
```

三个结果都应当是：

```text
True
```

## 3. 配置 Godot 路径

本包不包含 Godot 本体。请安装 Godot 4.7.2 Standard，并把它的 EXE 完整路径设置到用户环境变量 `GODOT_BIN`。

下面只是示例，请把 EXE 路径替换成你电脑上的实际位置：

```powershell
[Environment]::SetEnvironmentVariable(
    'GODOT_BIN',
    'E:\Tools\Godot\Godot_v4.7.2-stable_win64.exe',
    'User'
)
```

设置后请完全关闭并重新打开 Codex。然后在新 PowerShell 窗口验证：

```powershell
& $env:GODOT_BIN --version
```

若 Godot 安装在 C 盘、D 盘或其他目录也没有问题；只有项目根目录固定为 `E:\Capybara`。

## 4. 在 Codex 中打开正确文件夹

在 Codex 桌面端选择或打开：

```text
E:\Capybara
```

不要只打开 `E:\Capybara\game`，也不要让 Codex在其他目录新建第二个 Capybara 项目。

## 5. 给 Codex 发两条消息

推荐分两步执行，避免 Codex 一次改动过多。

第一步：把 `SEND_TO_CODEX_FIRST_MESSAGE.txt` 的全文发送给 Codex。它应该只读取文件、检查环境并给出阶段 0 计划，然后停止。

第二步：你看过计划并确认没有明显问题后，把 `SEND_TO_CODEX_AFTER_PLAN.txt` 的全文发送给 Codex。此时它才开始创建 Godot 灰盒项目。

## 6. 阶段 0 结束后你要亲自检查

- Godot 能打开 `E:\Capybara\game\project.godot`。
- 按 F6/F5 后灰盒场景可以运行。
- 占位水豚可以使用 WASD 和方向键移动。
- 斜向移动不会更快。
- 玩家不能穿过边界。
- Esc 暂停、继续和退出有效。
- Codex 实际运行了检查命令，没有只说“应该可以”。
- Codex 已停止，没有擅自进入阶段 1。
- Git 中没有 API 密钥、缓存、构建文件或未经授权素材。

## 7. 发生问题时

若 Codex 说找不到文件，先确认它当前打开的根目录就是 `E:\Capybara`。若它找不到 Godot，请不要让它从未知网站下载程序；你只需修正 `GODOT_BIN` 后重新打开 Codex，再让它继续验证。

---

# Capybara 项目：先读这里

版本：1.1（E 盘定制版）  
日期：2026-08-30  
固定项目根目录：`E:\Capybara`

这是一套可以直接交给 Codex 的项目启动包，目标是在 Windows 上从零开发一款原创 2D 温馨家园游戏，并最终发布到 Steam。

本包不是“让 Codex 一次性生成整款游戏”的提示词。它把项目拆成可验证、可回退的阶段，避免一次改动过大、代码无法运行、素材失控或存档系统返工。

## 一、默认技术路线

- 开发环境：Windows 10/11，64 位。
- 项目根目录：`E:\Capybara`。
- AI 开发协作：Codex 桌面端或 Codex CLI。
- 游戏引擎：Godot 4.7.2 Standard，不使用 .NET 版。
- 语言：GDScript，启用静态类型。
- 渲染：Compatibility，优先兼容普通 Windows 电脑和 Steam Deck。
- 版本管理：Git + GitHub Desktop，私人仓库。
- 绘画与修图：Krita。
- 可选动画工具：Blender；首版也可使用 Godot 2D 骨骼与有限逐帧动画。
- 音效处理：Audacity。
- 发布平台：Steam，第一版只发布 Windows；后续再评估 macOS/Linux。
- AI 使用方式：开发期间生成预制素材；游戏运行时不调用 AI。

## 二、开始前要做的事

1. 先备份现有的 `E:\Capybara`。
2. 把压缩包中的全部内容直接解压到 `E:\Capybara`，不要多套一层文件夹。
3. 安装并准备 Godot 4.7.2 Standard、Git/GitHub Desktop、Git LFS、Krita 和 Codex。Blender 与 Audacity 可以稍后安装。
4. 本包已经包含 `.gitignore`，不需要再重命名文件。
5. 设置 Windows 用户环境变量 `GODOT_BIN`，值为 Godot EXE 的完整路径。
6. 用 Codex 打开 `E:\Capybara`，而不是只打开 `game` 子目录。
7. 先发送 `SEND_TO_CODEX_FIRST_MESSAGE.txt`；Codex 给出计划并停止后，再发送 `SEND_TO_CODEX_AFTER_PLAN.txt`。
8. 第一次只允许 Codex 执行“阶段 0”。阶段 0 结束后，你亲自打开 Godot 验收，再决定是否继续阶段 1。

更细的安装与检查步骤见 `00_START_HERE_E_DRIVE.md`。

## 三、非常重要的素材规则

- 本项目使用原创水豚角色，不使用“水豚噜噜”的名称、图片、造型、标志性搭配、剧情或宣传材料。
- 没有明确权利的图片不得作为生图参考图、描摹底图或游戏素材。
- 不在提示词里写“模仿某个现有 IP”或“模仿某位在世艺术家”。
- AI 刚生成的图片只能进入 `art/generated_raw`，不能直接进入游戏。
- 只有经过人工挑选、修整、尺寸检查、透明边缘检查并登记的素材，才可进入 `art/approved` 和 `game/assets`。
- 所有玩家可见文字都由 Godot 字体系统渲染，不能烘焙在 AI 图片里。

## 四、正确使用 Codex 的节奏

每个功能都按以下顺序进行：

1. 阅读 `AGENTS.md` 和相关设计文档。
2. Codex 先列出不超过 8 条的实施计划。
3. 你确认计划。
4. 一次只实现一个可独立验收的功能。
5. Codex 实际运行检查并报告结果。
6. 你亲自试玩。
7. 通过后再提交 Git；未通过就小范围修复或回退，不叠加新功能。

不要发送“把整款游戏全部完成”“一次生成全部素材”“自动上架 Steam”之类的任务。

## 五、你需要亲自做的决定

Codex 可以给出候选方案，但以下决定必须由你批准：

- 主人公最终造型。
- 游戏正式名称。
- 核心玩法是否好玩。
- 每个里程碑是否通过。
- AI 图片是否足够原创且风格统一。
- Steam 商店描述、定价和发布时间。
- 最终发布构建。

## 六、本包中的核心文件

- `00_START_HERE_E_DRIVE.md`：针对 `E:\Capybara` 的安装与操作步骤。
- `SEND_TO_CODEX_FIRST_MESSAGE.txt`：第一次复制给 Codex 的消息。
- `SEND_TO_CODEX_AFTER_PLAN.txt`：确认计划后复制给 Codex 的消息。
- `MASTER_PROMPT_FOR_CODEX.md`：Codex 必须遵守的阶段 0 完整指令。
- `AGENTS.md`：Codex 在仓库内长期遵守的工程规则。
- `CAPYBARA_COMPLETE_PLAN_FOR_CODEX.md`：完整开发方案合并版。
- `docs/01_GAME_DESIGN.md`：完整游戏设计。
- `docs/02_TECHNICAL_DESIGN.md`：Godot 技术架构。
- `docs/03_ART_BIBLE.md`：原创美术规范。
- `docs/04_AI_ASSET_PIPELINE.md`：AI 素材生产与审核流程。
- `docs/05_ROADMAP.md`：开发阶段和里程碑。
- `docs/06_QA_PLAN.md`：测试、验收和错误分级。
- `docs/07_STEAM_RELEASE_CHECKLIST.md`：Steam 发布清单。
- `docs/08_PRODUCT_MARKETING.md`：产品定位和商店素材规划。
- `docs/09_LEGAL_AND_AI_POLICY.md`：权利与 AI 内容记录规则。
- `docs/11_IMAGE_PROMPT_LIBRARY.md`：可复用生图提示词模板。
- `docs/BACKLOG.csv`：任务清单。
- `docs/ASSET_MANIFEST.csv`：素材登记模板。

## 七、第一天的完成标准

第一天不要追求漂亮画面。只要完成以下事项就算成功：

- Git 仓库可用。
- Godot 项目可以打开。
- 主场景能运行。
- 一个占位水豚可以四方向移动。
- 碰撞有效。
- 可以暂停和退出。
- Codex 能用 headless 命令检查项目。
- 所有改动都能在 GitHub Desktop 中清楚看到。

---

# 给 Codex 的两条消息

项目根目录固定为 `E:\Capybara`。

## 第一条：只读取并制定计划

复制 `SEND_TO_CODEX_FIRST_MESSAGE.txt` 的全文。Codex 输出阶段 0 计划后应当停止，不应修改文件。

## 第二条：确认后开始执行

检查 Codex 的计划没有超出阶段 0 后，复制 `SEND_TO_CODEX_AFTER_PLAN.txt` 的全文。

## 计划不合格时不要发送第二条

出现以下情况时，先要求 Codex 修改计划：

- 它准备一次完成整款游戏。
- 它准备开始正式生图。
- 它准备接入 Steamworks。
- 它准备加入第三方插件。
- 它准备自动下载 Godot 或其他二进制程序。
- 它没有计划实际运行 headless 检查。
- 它打开的目录不是 `E:\Capybara`。
- 它准备自动提交或推送 Git。

---

# 发送给 Codex 的主提示词

版本：1.1（`E:\Capybara` 定制版）  
日期：2026-08-30

你现在是本项目的首席 Godot 工程师、技术策划、构建工程师、测试工程师和文档维护者。项目负责人没有游戏开发经验，因此你的工作必须可解释、可验证、可回退，不能用“大量一次性生成”代替工程质量。

## 0. 固定工作区与执行方式

- 项目根目录固定为 `E:\Capybara`。
- 在进行任何操作前，确认当前工作区根目录包含 `AGENTS.md`、`MASTER_PROMPT_FOR_CODEX.md` 和 `docs/01_GAME_DESIGN.md`。
- 不得在其他磁盘、用户目录或 `E:\Capybara` 的子目录中另建第二份项目。
- 所有仓库内路径使用相对路径；不得把 `E:\Capybara` 这样的绝对路径写进 Godot 资源、脚本或可发布构建。
- 第一次收到任务时只阅读、检查环境并提交计划，输出计划后必须停止。只有项目负责人明确发送“开始执行阶段 0”后，才可以修改文件。
- 若当前工作区不是 `E:\Capybara`，先停止并报告，不要自行猜测或迁移文件。

## 1. 项目目标

在 Windows 环境中，使用 Godot 4.7.2 Standard 与静态类型 GDScript，开发一款原创的 2D 温馨家园生活游戏。内部项目代号为 `Capybara`，正式商店名称暂未确定。

玩家扮演一只原创水豚，在一片逐渐干涸的湿地周围：

- 探索和采集。
- 开垦土地和种植。
- 挖掘网格化池塘与水渠。
- 建造与布置家园。
- 摘果子、钓鱼。
- 与原创动物 NPC 互动。
- 通过改善水环境吸引更多邻居。

核心差异化不是“功能很多”，而是“水改变家园”：池塘、水渠、灌溉、水生植物、钓鱼和动物来访属于同一套核心循环。

## 2. 在修改任何文件前必须阅读

按顺序完整阅读：

1. `AGENTS.md`
2. `docs/01_GAME_DESIGN.md`
3. `docs/02_TECHNICAL_DESIGN.md`
4. `docs/03_ART_BIBLE.md`
5. `docs/04_AI_ASSET_PIPELINE.md`
6. `docs/05_ROADMAP.md`
7. `docs/06_QA_PLAN.md`
8. `docs/09_LEGAL_AND_AI_POLICY.md`
9. `docs/10_DECISION_LOG.md`
10. `docs/BACKLOG.csv`

阅读后先输出：

- 你理解的产品目标。
- 当前只做阶段 0 的边界，以及明确不做的内容。
- 发现的环境依赖与实际检测结果。
- 最多 8 条实施步骤。
- 准备实际执行的检查命令。
- 可能阻塞执行的问题和需要项目负责人决定的事项。

第一次回复只能包含上述审阅结果和计划。在该回复中不要修改、创建、删除或移动文件；输出后立即停止，等待项目负责人明确发送“开始执行阶段 0”。

## 3. 本次只执行阶段 0：工程初始化

不要实现完整游戏，不要生成正式美术，不要接入 Steamworks，不要建立复杂 NPC、钓鱼或建造系统。

阶段 0 的任务如下：

### 3.1 环境检查

- 确认当前操作系统为 Windows，工作区根目录为 `E:\Capybara`。
- 确认根目录直接包含本提示词和 `docs`，不存在误用 `E:\Capybara\Capybara...` 嵌套目录的情况。
- 检查 Git 仓库是否存在；不存在则初始化本地仓库，但不要推送远程。
- 检查 Git LFS 是否可用；不可用时报告安装步骤，不要伪造成功。
- 寻找 Godot 4.7.2 Standard 可执行文件。
- 优先读取环境变量 `GODOT_BIN`；若没有，再检查常见安装目录。
- 如果找不到 Godot，可继续创建文档和目录，但必须停止运行验证，并清楚报告阻塞项。
- 不安装未知来源软件，不擅自下载二进制文件。

### 3.2 创建目录

在不覆盖已有文件的前提下创建：

```text
art/
  generated_raw/
  candidates/
  approved/
  source_layers/
build/
  windows/
docs/
game/
  assets/
    characters/
    environment/
    buildings/
    items/
    ui/
    audio/
  autoload/
  core/
  data/
    definitions/
  localization/
  scenes/
    bootstrap/
    player/
    world/
    ui/
  systems/
  tests/
  tools/
tools/
```

### 3.3 初始化 Godot 项目

在 `game/` 中创建 Godot 4.7.2 项目，要求：

- Standard/GDScript。
- Compatibility 渲染器。
- 基础逻辑分辨率 1280×720。
- 伸缩模式适配 16:9 和 16:10，UI 使用锚点，不依赖固定坐标。
- 主场景为 `res://scenes/bootstrap/main.tscn`。
- 默认窗口可调整大小。
- 项目名称暂为 `Capybara`。
- 不使用第三方插件。

### 3.4 最小可运行场景

创建一个纯占位的灰盒场景：

- `Main` 根节点。
- 简单地面和边界碰撞。
- 一个由基础几何图形组成的占位玩家，不能使用任何第三方图片。
- `CharacterBody2D` 四方向移动。
- `Camera2D` 平滑跟随。
- 最后移动方向被保存。
- 输入动作同时覆盖 WASD、方向键，并预留手柄左摇杆与十字键。
- `Esc` 打开暂停界面。
- 暂停界面有“继续”和“退出到桌面”。
- 屏幕角落显示 `Prototype / Phase 0`，该文字由 Godot UI 渲染。

### 3.5 基础代码规范

- 所有 GDScript 使用静态类型。
- 公开方法和复杂逻辑写简短注释。
- 节点引用使用类型声明。
- 不创建巨型 `GameManager`。
- 不使用魔法字符串保存游戏数据。
- 不使用绝对本地路径写入项目文件。
- 暂时不实现存档，但创建空的接口和设计占位时必须保持最小化。

### 3.6 最小测试与工具

创建：

- `game/tests/run_all.gd`：零依赖的 headless 测试入口。
- 至少测试玩家移动向量归一化和输入方向转换的纯逻辑。
- `tools/check_project.ps1`：
  - 检查 `GODOT_BIN`。
  - 运行 Godot headless 导入/解析检查。
  - 运行测试入口。
  - 任何步骤失败时返回非零退出码。
- `tools/run_editor.ps1`：用 `GODOT_BIN` 打开项目。
- `tools/run_game.ps1`：运行主场景。

不要声称测试通过，除非实际执行并获得成功退出码。

### 3.7 文档更新

完成后更新：

- `docs/10_DECISION_LOG.md`
- `docs/CHANGELOG.md`
- `docs/BACKLOG.csv` 中阶段 0 对应状态

不要删除原始需求，不要擅自改动游戏核心定位。

## 4. 阶段 0 验收标准

只有全部满足才算完成：

1. Godot 能打开项目且无解析错误。
2. 主场景能运行。
3. 玩家能以相同速度进行横向、纵向和斜向移动。
4. 玩家不能穿过边界。
5. 暂停与继续有效。
6. headless 检查成功。
7. 自建测试入口成功。
8. Git 改动范围清晰，无二进制构建产物、密钥或缓存文件被纳入。
9. 没有使用任何未授权图片或音频。
10. 完成报告中明确列出实际执行过的命令与结果。

## 5. 完成后必须停止

阶段 0 结束后不要继续阶段 1。输出一份报告，格式必须为：

```text
完成摘要
修改文件
新增文件
执行命令与结果
手工试玩步骤
已知问题
需要项目负责人决定的事项
下一阶段建议（只列建议，不执行）
```

不要自动提交或推送 Git，除非项目负责人明确要求。

## 6. 长期工作规则

- 每次任务只处理一个功能或一个紧密相关的小批次。
- 先计划，再修改，再检查，再报告。
- 不能通过隐藏报错、删除测试或注释功能来让检查“变绿”。
- 发现文档冲突时停止并请求决定，同时记录冲突。
- 依赖或插件必须先说明用途、许可证、维护风险与替代方案，得到批准后才能加入。
- AI 图片首先进入 `art/generated_raw`；未经批准不得进入游戏。
- 没有明确权利的图像不得作为参考。
- 游戏运行时不连接生图 API。
- API 密钥只能从环境变量读取，绝不写入仓库、Godot 资源或导出构建。
- 固定 Godot 4.7.2；不得自动升级引擎或重写项目格式。

---

# AGENTS.md

本文件是 Codex 在本仓库中的长期工作规则。任何任务都必须遵守。

## 项目概述

- 项目代号：Capybara。
- 固定仓库根目录：`E:\Capybara`；不得在其他位置创建第二份工程。
- 类型：原创 2D 温馨家园、轻建造、种植、钓鱼、NPC 社交。
- 首发平台：Windows / Steam。
- 引擎：Godot 4.7.2 Standard。
- 脚本：静态类型 GDScript。
- 渲染：Compatibility。
- 地图：64×64 像素逻辑网格，区域式半开放世界。
- AI：仅开发期间生成预制资产，v1.0 不包含运行时 AI。

## 绝对规则

1. 不使用或模仿任何未授权角色、IP、Logo、宣传图、音乐、字体或素材。
2. 不使用上传的“水豚噜噜”图片作为生成参考，除非以后提供了明确书面授权。
3. 不在图像提示词中要求模仿具体 IP 或在世艺术家。
4. 不把 API 密钥、Steam 凭据、证书或个人信息写进仓库。
5. 不自动升级 Godot 版本。
6. 不未经批准添加第三方插件或服务。
7. 不一次实现多个大型系统。
8. 不在没有实际运行的情况下声称测试通过。
9. 不覆盖 `art/source_layers` 中的源文件。
10. 不把 `art/generated_raw` 中的图片直接复制到 `game/assets`。

## 开始任务前

- 确认当前工作区根目录为 `E:\Capybara`，并直接包含本文件与 `docs/`。
- 阅读与任务相关的 `docs/` 文件。
- 检查当前 Git 状态。
- 识别未提交修改，避免覆盖用户工作。
- 输出不超过 8 条的实施计划。
- 明确本任务的验收标准。

## 代码规范

- 所有函数参数、返回值、成员变量尽量使用明确类型。
- 使用 `snake_case`：文件、变量、函数。
- 使用 `PascalCase`：`class_name` 与资源类型。
- 使用 `SCREAMING_SNAKE_CASE`：常量。
- 使用稳定 ID，不用显示名称作为存档键。
- 玩家可见文本使用本地化键和 `tr()`，不得写死。
- 单个脚本原则上不超过 350 行；超过时优先拆分职责。
- 避免深层节点路径；优先使用导出节点引用、组件或明确接口。
- 避免全局单例膨胀；Autoload 只保留跨场景且确有必要的服务。
- 使用信号解耦 UI 与游戏逻辑。
- 纯数据优先使用自定义 `Resource`；存档使用版本化 JSON。
- 不直接序列化整个节点树。
- 公共接口和非显然算法写简短注释，避免逐行废话注释。

## 目录规则

```text
game/autoload/              跨场景服务
game/core/                  通用类型与纯逻辑
game/data/definitions/      Item、Crop、Fish、NPC 等 Resource 定义
game/scenes/                场景
game/systems/               独立游戏系统
game/tests/                 无第三方依赖的自动测试
game/assets/                已批准并处理完成的游戏资产
art/generated_raw/          原始 AI 输出，不直接进游戏
art/candidates/             候选与联系表
art/approved/               已批准视觉方案
art/source_layers/          Krita/Blender 等可编辑源文件
tools/                      Windows PowerShell 与资产处理脚本
build/                      导出构建，不提交 Git
```

## 默认运行命令

优先从 Windows 环境变量读取 Godot：

```powershell
$env:GODOT_BIN
```

项目检查：

```powershell
& $env:GODOT_BIN --headless --path game --import
```

运行测试：

```powershell
& $env:GODOT_BIN --headless --path game --script res://tests/run_all.gd
```

运行游戏：

```powershell
& $env:GODOT_BIN --path game
```

如果命令因当前 Godot 版本参数差异而失败，先查看本机 Godot 帮助，再以最小方式修正脚本，同时记录变更。

## 每个任务的完成标准

- 功能满足明确验收条件。
- 没有新增解析错误或明显警告。
- 自动检查实际执行。
- 涉及 UI 时测试键鼠和手柄导航。
- 涉及存档时测试保存、加载、缺失数据、旧版本迁移和损坏备份。
- 涉及地图时测试碰撞、遮挡、排序和边界。
- 更新受影响文档与变更记录。
- 报告所有改动文件和手工测试步骤。

## 素材工作流

状态只能按以下顺序前进：

```text
generated_raw -> candidates -> approved -> source_layers/game_ready -> game/assets
```

每项素材必须登记到 `docs/ASSET_MANIFEST.csv`。需要记录：来源方式、提示词版本、引用的原创母图、人工修改、许可证或权利依据、批准状态与游戏路径。

## 禁止的范围扩张

除非路线图明确进入对应阶段并得到批准，否则不做：

- 联机或多人。
- 战斗。
- 随机世界。
- 真正任意形状的连续地形雕刻。
- 四季和大型天气系统。
- 运行时 AI。
- 手机或主机移植。
- 大量付费插件。
- 复杂脚本语言式对话编辑器。

## 最终报告格式

```text
任务目标
实施摘要
修改文件
新增文件
删除文件
执行的检查与结果
手工测试步骤
风险与已知问题
文档更新
建议的下一项小任务
```

---

# 01 游戏设计文档

版本：1.0  
日期：2026-08-30  
状态：前期制作基线

## 1. 项目定义

- 内部项目代号：`Capybara`。
- 正式名称：待定，建议最终使用具有辨识度的副标题，而不是只使用通用动物名。
- 类型：俯视角 2D 温馨家园生活、轻建造、种植、采集、钓鱼和 NPC 社交。
- 模式：单人、离线、无战斗。
- 首发平台：Windows / Steam。
- 目标体验：轻松、可爱、低压力、持续看到环境被自己改善。

## 2. 一句话提案

玩家扮演一只原创水豚，在一片逐渐干涸的湿地中挖池塘、引水、种植、建造和结交动物朋友，把荒地建设成大家愿意来泡水、发呆和生活的水边家园。

## 3. 核心幻想

玩家不是在管理一座高效率工厂，而是在亲手照料一块土地。每一次挖水、种树、搭桥或摆放座椅，都能让环境变得更有生机，并改变动物朋友的行为。

## 4. 四个设计支柱

### 4.1 水改变世界

水不是纯装饰。玩家挖出的池塘和水渠会影响：

- 哪些土地可灌溉。
- 哪些水生植物可以生长。
- 哪些鱼类能够出现。
- 哪些 NPC 愿意来访。
- 家园的生态与舒适评分。
- 新区域的解锁。

### 4.2 家园属于大家

NPC 不只是站在原地发任务。关系提升后，他们会：

- 来家园泡水或发呆。
- 对家具、植物和头饰作出反应。
- 帮助建桥、制作家具或带来种子。
- 参与小型共同活动。

### 4.3 没有失败压力，但有清晰进步

- 不设置战斗和死亡惩罚。
- 不使用会让玩家焦虑的硬性倒计时任务。
- 不用强制体力条阻止探索。
- 每次短时间游玩也能获得可见进展。
- 重要操作可以撤销或预览。

### 4.4 角色有可收集的生活身份

通过故事、钓鱼、采集和朋友关系获得：

- 围巾、包、帽子和小型头饰。
- 家具与植物。
- 拍照姿势和表情。
- 家园主题装饰。

这些收集以外观和情感反馈为主，避免复杂数值膨胀。

## 5. 核心循环

```text
探索区域
  -> 采集木材、石料、果实和水生材料
  -> 完成动物朋友的请求
  -> 解锁工具、种子、家具或水利能力
  -> 挖池塘、铺路、种植和建造
  -> 改善家园生态与舒适度
  -> 吸引新 NPC 和鱼类
  -> 解锁下一片区域或故事
  -> 继续个性化家园
```

单次 15 分钟游玩应至少完成一个小目标，例如收获一批作物、完成一个请求、放置一件家具或扩建一小块池塘。

## 6. 地图结构

不制作一张巨大无缝开放世界。采用“区域式半开放世界”：每个区域独立加载，区域内部自由探索，转场短而清楚。

### 6.1 家园湿地

- 玩家住宅与主要建造区域。
- 农田、池塘、水渠和家具布置。
- NPC 来访与大部分社交活动。
- 作为所有系统的中心。

### 6.2 果树林

- 果实、木材、花和蜂蜜。
- 简单地形障碍与可修复小径。
- 兔子或松鼠类园艺 NPC 的故事。

### 6.3 芦苇湿地

- 钓鱼和水生植物。
- 水位恢复后开放更多路线。
- 水獭、鸭子等 NPC。

### 6.4 温泉山脚

- 后期区域。
- 水温、石材和更稀有鱼类。
- 主线故事阶段性结尾。

垂直切片只制作“家园湿地 + 果树林入口的一小段”。

## 7. 主角原创设定方向

最终设定必须经过独立概念探索，以下为默认方向而非不可修改的成品：

- 一只温暖灰棕色的年轻水豚。
- 身体比例接近真实水豚但更柔和可爱，不采用超大头婴儿比例。
- 左耳略微向外折，作为稳定剪影特征。
- 佩戴湖水青色防水围巾。
- 背一个小型睡莲叶形斜挎包。
- 标志工具为木制测水杆或小水瓢。
- 不头顶橘子，不穿与既有角色相似的固定裤装，不复用现有 IP 面部结构。
- 性格安静、耐心、喜欢水，对修复湿地非常认真。

## 8. 基础操作

### 8.1 键盘与手柄

- 移动：WASD / 方向键 / 左摇杆。
- 交互：E / 手柄南键。
- 使用当前工具：鼠标左键或键盘快捷键 / 手柄西键。
- 取消：Esc / 手柄东键。
- 背包：Tab / 手柄菜单键。
- 建造模式：B / 手柄肩键组合。
- 快捷栏：数字键或手柄肩键切换。

最终按键允许重映射。

### 8.2 交互优先级

当多个对象重叠时，按照以下优先级：

1. 当前任务目标。
2. NPC。
3. 可拾取或可采集物。
4. 家具与建造物。
5. 地面工具操作。

界面必须清楚显示当前会触发的动作。

## 9. 核心系统设计

### 9.1 采集

- 木材、石头、枝条、果实、花、水草和黏土。
- 资源节点以若干游戏日恢复，避免强制刷取。
- 采集前有简短动作和清楚音效。
- 地面掉落物可自动吸附到玩家附近，减少拾取负担。

### 9.2 背包和物品

- 物品按资源、种子、作物、鱼、家具、工具、任务物品分类。
- 同类物品堆叠。
- 任务物品不可误卖或丢弃。
- 垂直切片先使用 24 格背包，可通过家中储物箱扩展。
- 物品显示名与说明全部使用本地化键。

### 9.3 种植

流程：

```text
清理地块 -> 翻土 -> 播种 -> 浇水/靠近水渠 -> 跨日成长 -> 收获
```

设计原则：

- 水渠或池塘附近的农田可自动保持湿润，强化“水改变家园”。
- 手动浇水仍然可用，但不应成为高频体力劳动。
- 作物枯萎只在长期忽视后发生，且可以恢复，不做永久惩罚。
- 垂直切片包含 3 种作物：快速叶菜、果实作物、水生作物。

### 9.4 建造与家具

- 基于 64×64 逻辑网格放置。
- 放置前显示占地、碰撞和有效/无效预览。
- 可移动与收回家具，不造成资源损失。
- 部分对象支持方向变体；没有对应美术时不开放旋转。
- 住宅采用固定升级阶段，不做完全自由房屋结构编辑。
- 家具可贡献舒适、自然、社交或实用标签。

### 9.5 池塘与水渠

第一版不做连续自由地形雕刻，而做安全、可保存的网格化水体编辑：

- 仅可在标记为可挖掘的地面格操作。
- 挖掘后格子转为浅水或水渠。
- 岸边通过 TileSet terrain/autotile 规则更新。
- 建筑、资源点和任务物体占用的格子不能挖。
- 填土可撤销水格，重要情况下弹出确认。
- 连通水体记录尺寸、植物数量和装饰数量。
- 水体至少达到指定尺寸后可放鱼苗或成为钓鱼点。

垂直切片只计算：

- 水体连通尺寸。
- 水生植物数量。
- 周围座椅/灯笼数量。

据此计算简单的 `pond_comfort_score`，吸引一个 NPC 来泡水。

完整版可扩展：清洁度、水温、遮阴、鱼类多样性和水流。

### 9.6 钓鱼

采用轻量单键玩法：

1. 选择钓点并抛竿。
2. 等待明显的视觉和音效提示。
3. 在时间窗口内按键咬钩。
4. 通过一段短的节奏或保持指针区域完成收线。

原则：

- 普通鱼容易获得。
- 失败不消耗稀有诱饵。
- 稀有鱼由区域、水体条件和时段影响。
- 垂直切片包含 3 种鱼和一套简化钓鱼小游戏。

### 9.7 NPC 与关系

每个主要 NPC 需要：

- 独特剪影与动作节奏。
- 家园功能或专长。
- 简单日程。
- 3 个关系阶段。
- 至少一个不依赖送礼的互动。
- 一条 15–25 分钟的小故事。

关系增长来源：

- 完成请求。
- 一起泡水、坐下或分享果实。
- 建造 NPC 喜欢的环境。
- 关键对话选择。

垂直切片 NPC：

- `npc_otter_builder`：水獭木匠，帮助修复小桥。
- `npc_rabbit_gardener`：兔子园艺师，作为环境角色或短请求角色。

最终名称以后统一创作，不在代码中使用中文显示名作为 ID。

### 9.8 请求与故事

- 请求没有失败计时。
- 主线用于解锁区域和工具。
- 好友故事用于展示性格和共同活动。
- 日常请求只提供轻量资源，不是强制任务列表。
- 对话保持短句、可跳过、可查看历史。

### 9.9 时间与休息

- 游戏日用于作物和资源恢复。
- 玩家可以在床上结束当天。
- 不设置必须在午夜前回家造成损失的惩罚。
- 夜晚可以继续活动，也可以通过设置简化昼夜变化。
- 垂直切片可先使用手动睡眠推进一天，不做完整昼夜光照系统。

### 9.10 经济与进度

三类进度：

- 资源：建造与制作所需材料。
- 硬币：出售多余物品和完成请求获得，用于购买种子和家具。
- 栖息地等级：由水体、植物、设施和故事进度提升，解锁新区域和来访者。

避免：

- 多种高级货币。
- 抽卡。
- 强制每日签到。
- 高压债务。
- 需要大量重复劳动的价格曲线。

## 10. 垂直切片定义

目标游玩时长：30–45 分钟。  
目标：证明移动、建造、种植、水体、钓鱼和 NPC 能形成一个完整而有情绪回报的循环。

包含：

- 1 个主家园区域。
- 1 个很小的外部采集区域。
- 1 个完整 NPC 小故事，另有 1 个轻量 NPC。
- 3 种资源节点。
- 3 种作物。
- 3 种鱼。
- 12 件家具或建造物。
- 1 次小桥修复。
- 1 套可编辑池塘。
- 1 次 NPC 来家园泡水事件。
- 背包、快捷栏、设置、保存和读取。
- 简体中文与英文界面框架。
- 键鼠与完整手柄操作。

垂直切片完成画面：玩家挖出并装饰一座小池塘，完成水獭木匠的请求；傍晚，两个动物坐在池边，栖息地等级提升并打开果树林入口。

## 11. 1.0 建议内容上限

为了让首作可完成，1.0 目标上限为：

- 4 个区域。
- 6–8 个主要 NPC。
- 12 种作物。
- 18–24 种鱼。
- 60–80 件家具与建造物。
- 20–30 个主要/好友请求。
- 3 个住宅升级阶段。
- 25–40 个装扮物。
- 8–12 小时主线与自然探索内容。

这些是上限，不是必须填满的最低数量。质量和完成度优先。

## 12. 首版明确不做

- 联机、多人共建。
- 战斗、敌人和生命值。
- 随机生成世界。
- 完全自由的连续地形雕刻。
- 四季系统。
- 大型天气模拟。
- 上百名 NPC。
- 坐骑与繁殖。
- 手机、主机同时发行。
- 玩家运行游戏时调用生成式 AI。
- 用户生成内容平台。

## 13. 新手引导

前 20 分钟按“边做边学”展开：

1. 移动到旧水泵旁。
2. 拾取枝条，清理一条小路。
3. 与水獭木匠交谈。
4. 种下一株快速作物。
5. 用铲子挖出 3×3 小池塘。
6. 放置一株芦苇和一张木凳。
7. 钓到第一条鱼。
8. 修复小桥。
9. 触发朋友来泡水的场景。

避免一次弹出大段教程文字。每个步骤只显示当前需要的按键与一句说明。

## 14. 成功指标

垂直切片试玩后，希望多数玩家能够回答“是”：

- 我理解为什么要改善水环境。
- 挖池塘和布置家园有明显反馈。
- 我喜欢主角和至少一个 NPC。
- 我愿意继续解锁下一个区域。
- 操作没有让我感到疲劳或困惑。
- 我能在 30 分钟后记住这款游戏与“水边家园”的关联。

---

# 02 技术设计文档

版本：1.0  
日期：2026-08-30  
目标引擎：Godot 4.7.2 Standard

## 1. 技术目标

- 让没有开发经验的项目负责人可以通过小步验收控制风险。
- 保持系统数据驱动，避免每增加一种作物或鱼都改代码。
- 存档可迁移、可备份、可诊断。
- 键鼠与手柄从第一天共同支持。
- 支持 1280×720、1920×1080 和 1280×800。
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

Autoload 只允许：

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
- `season_rules` 预留但 v1 不启用季节。

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

先保证正确，再优化。垂直切片地图较小，不做过早复杂优化。

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

---

# 03 美术规范 ART BIBLE

版本：1.0  
日期：2026-08-30  
状态：待角色概念验证

## 1. 美术目标

创建一套可长期扩展、可动画、在小尺寸下清楚、与任何现有卡通 IP 明显区分的原创视觉体系。

关键词：

- 温暖湿地。
- 柔和绘本。
- 手工贴纸感。
- 清晰剪影。
- 低压力、自然、安静幽默。
- 非像素 2D。

## 2. 禁止项

- 不使用“水豚噜噜”图片作为参考图。
- 不保留头顶橘子、相同大头比例、相似服装与面部组合。
- 不要求“像某个现有角色”。
- 不写具体在世艺术家风格。
- 不生成带 Logo、水印、签名或可读文字的游戏资产。
- 不把风格不一致的单张图直接塞进游戏。
- 不独立生图制作逐帧走路动画。

## 3. 总体画面方向

### 3.1 风格

- 柔和水粉/厚涂绘本质感。
- 轮廓以深棕柔边或局部边缘对比为主，不使用纯黑粗描边。
- 形状简洁，细节在缩小后仍然可读。
- 纹理适度，避免照片级材质和过多噪点。
- 色彩明亮但不过饱和。

### 3.2 视角

- 3/4 俯视角。
- 场景尽量使用平行/弱透视感。
- 所有建筑、家具、树木和角色保持相同相机俯角。
- 角色提供上、下、左、右四个方向。

### 3.3 光照

- 固定柔和主光从左上方照射。
- 阴影向右下方。
- 角色和可移动物体的地面阴影单独导出。
- 避免强烈高光和复杂环境反射，以减少素材不一致。

## 4. 原创主角基线

内部资产 ID：`player_capybara_v1`。

不可轻易变化的识别特征：

- 温暖灰棕色毛发。
- 中等大小头部与稍长口鼻，避免超大圆头。
- 左耳轻微向外折。
- 湖水青色防水围巾。
- 睡莲叶形小斜挎包。
- 深棕椭圆眼睛，小而清楚的高光。
- 脚掌和鼻口使用更深的暖棕色。
- 不戴头顶水果。
- 不穿红色短裤或与现有形象近似的固定服装组合。

性格通过姿势表达：

- 身体略微前倾，动作认真但不急躁。
- 待机时会眨眼、抖耳、看水面。
- 开心不是夸张跳跃，而是轻轻抬头和摇晃围巾。

## 5. 角色设定图要求

主设定图 `PLAYER_MASTER_V1` 至少包括：

- 正面。
- 背面。
- 左侧。
- 右侧。
- 游戏实际 3/4 俯视四方向。
- 固定色板。
- 角色高度比例线。
- 围巾与包单独展示。
- 开心、平静、困倦、惊讶、担心五种表情。
- 缩小到游戏尺寸后的预览。
- 明确写出不能改变的特征，但文字应放在设计文档，不进入游戏图片。

批准后，后续姿势优先使用图像编辑与母图参考，不从纯文字重新生成。

## 6. NPC 设计原则

每个 NPC 必须在全黑剪影下仍可区分。

差异来自：

- 身高和宽度。
- 耳朵、尾巴、喙或头部轮廓。
- 站姿与动作节奏。
- 职业工具。
- 主色与材质。

不采用“同一张脸换动物耳朵”的方式。

初始 NPC 方向：

- 水獭木匠：细长身体、宽工具腰带、木色与河石蓝。
- 兔子园艺师：高耳朵、泥土围裙、叶绿与奶油色。
- 鸭子邮差：低矮宽体、斜挎邮包、芥末黄与湖蓝。

所有名称和造型都需要后续原创审查。

## 7. 环境设计

### 7.1 地面

- 每种地面提供至少 4 个随机细节变体。
- 主要地面：草、泥土、湿泥、浅水、道路、石地。
- 细节不能过密，给可交互物留视觉空间。

### 7.2 水体

- 水面颜色以蓝绿为主，边缘偏浅。
- 轻微循环波纹，不使用高频闪烁。
- 岸边提供直边、内角、外角、孤立小格和过渡变体。
- 水生植物放在独立层，不画死在水面底图。

### 7.3 植物

- 树木、灌木、芦苇、花和作物使用清楚的外轮廓。
- 可采集状态与普通装饰状态有可见差异。
- 前景树冠可半透明或淡化，避免遮挡角色。

### 7.4 建筑

- 房屋采用模块化外观，但首版为固定升级阶段。
- 门宽、碰撞和角色比例必须统一。
- 屋顶可在角色进入内部或被遮挡时淡出。
- 建筑不要包含 AI 生成的文字招牌；标识使用图形符号或 Godot 文本。

## 8. UI 设计

- 圆角木牌、叶片、水滴和河石作为形状语言。
- 背景具有足够不透明度，不让复杂场景影响阅读。
- 图标采用单一物件、居中、清楚剪影。
- 不把中文或英文烘焙在按钮图里。
- 选中、不可用和危险状态不只依赖颜色，也使用形状、亮度或图标变化。
- 手柄焦点必须明显。

## 9. 色板基线

建议色彩角色：

- 主角毛色：暖灰棕。
- 品牌强调：湖水青。
- 自然主色：芦苇绿、嫩芽绿。
- 温暖点缀：蜂蜜黄、陶土橙。
- UI 中性：奶油白、深树皮棕。
- 警示：低饱和珊瑚红，仅少量使用。

最终色值由批准的主设定图提取，并记录为项目色板文件。

## 10. 尺寸与导出规范

| 类型 | 原始工作尺寸 | 游戏显示建议 | 格式 |
|---|---:|---:|---|
| 主角单方向画布 | 1024×1024 或更高 | 高约 128–160 px | PNG 透明 |
| NPC 单方向画布 | 1024×1024 | 高约 112–176 px | PNG 透明 |
| 小物品图标 | 512×512 | 32–64 px | PNG 透明 |
| 单格地块 | 256×256 源图 | 64×64 px | PNG |
| 小家具 | 512–1024 | 1–3 格 | PNG 透明 |
| 建筑 | 2048 或分模块 | 4–10 格 | PNG 透明 |
| 头像 | 1024×1024 | 192–256 px | PNG 透明/固定背景 |

- 保留高分辨率源图。
- 游戏资产使用无多余透明边距的裁切版本。
- 透明边缘不得有白边、黑边或零散像素。
- 角色 pivot 统一在双脚/身体接地点。
- 阴影独立命名为 `_shadow`。

## 11. 动画策略

首选：有限 2D Cutout + 少量手绘替换帧。

基础动作：

- idle
- walk
- pickup
- tool_use
- fish_cast
- fish_reel
- sit
- soak
- emote_happy

原则：

- 不逐帧独立调用生图。
- 先锁定主设定，再拆分头、耳、身体、四肢、围巾、包和工具。
- 动画幅度小而有性格。
- 四方向复用动作节奏，但每个方向必须检查遮挡关系。
- 复杂动作可在 Blender 中用正交相机预渲染，再作为 2D Sprite 使用。

## 12. 素材命名

```text
chr_player_idle_down_v001.png
chr_otter_builder_portrait_happy_v002.png
env_reed_cluster_a_v001.png
tile_water_edge_outer_ne_v001.png
bld_wood_bench_front_v001.png
ui_icon_fishing_rod_v001.png
```

命名包含：类别、对象、状态/方向、变体和版本。

## 13. 美术验收清单

一项素材进入 `game/assets` 前必须满足：

- 与批准的视角一致。
- 与固定左上光一致。
- 缩小到实际尺寸仍可读。
- 无额外肢体、错误结构或变形。
- 无文字、Logo、水印或签名。
- 透明边缘干净。
- 无明显类似既有 IP 的标志性组合。
- 已登记提示词、来源、人工修改和批准状态。
- 在 Godot 场景中与邻近素材实测过，而不是只看大图。

---

# 04 AI 素材生产流程

版本：1.0  
日期：2026-08-30

## 1. 基本原则

AI 是概念探索和素材生产工具，不是自动美术总监。所有最终视觉资产必须经过人工选择、编辑、测试和登记。

v1.0 的游戏运行期间不调用图像、文本或语音生成 API。所有 AI 输出都在开发期预先生成并作为普通文件打包。

## 2. 资产状态机

```text
BRIEF
  -> GENERATED_RAW
  -> CANDIDATE
  -> APPROVED_CONCEPT
  -> HUMAN_EDITED_SOURCE
  -> GAME_READY
  -> INTEGRATED
  -> RELEASE_APPROVED
```

目录映射：

```text
art/generated_raw/    原始输出，默认不提交 Git
art/candidates/       候选联系表和选择记录
art/approved/         已批准概念与母图
art/source_layers/    Krita、Blender 等可编辑源文件
game/assets/          处理完成并实际使用的资产
```

禁止跳过状态。

## 3. 每项素材的标准流程

### 3.1 创建资产 brief

写清楚：

- `asset_id`。
- 游戏用途。
- 游戏内尺寸。
- 视角和方向。
- 光照。
- 色板。
- 必须保持的特征。
- 禁止出现的内容。
- 是否需要透明背景。
- 是否需要方向或状态变体。
- 验收方法。

### 3.2 生成少量候选

- 角色概念：首轮 6–12 张。
- 普通道具：首轮 4 张。
- Tile 或 UI 图标：首轮 4–8 张。
- 不为“碰碰运气”一次生成数百张。
- 原始文件自动命名并保留元数据。

### 3.3 创建联系表

Codex 或工具脚本将候选缩略图放入带编号的联系表。项目负责人只批准编号，不直接修改原图。

### 3.4 锁定母图

角色、建筑套系和 UI 组件需要批准的母图：

- `PLAYER_MASTER_V1`
- `NPC_OTTER_MASTER_V1`
- `HOUSE_SET_MASTER_V1`
- `UI_MASTER_V1`

后续变体优先使用编辑模式和母图作为参考，不重新从零生成。

### 3.5 人工编辑

至少检查和修正：

- 结构错误。
- 额外肢体。
- 不一致的服装细节。
- 透视和光向。
- 透明边缘。
- 色板。
- 尺寸和 pivot。
- 与其他素材的风格差异。

保留 `.kra`、`.blend` 或其他可编辑源文件。

### 3.6 技术处理

- 裁切透明边距。
- 检查 alpha。
- 按正确尺寸缩放。
- 导出 PNG/WebP；透明角色默认 PNG。
- 生成缩略图。
- 必要时拆分动画部件。
- 导入 Godot 并检查纹理过滤、mipmap 与压缩设置。

### 3.7 游戏内审核

必须在真实场景中检查：

- 与 64px 网格比例是否正确。
- 是否遮挡玩家。
- 颜色是否过亮或过暗。
- 交互状态是否清楚。
- 手柄焦点和 UI 图标是否易读。
- 动画时是否漂移。

### 3.8 登记

更新 `docs/ASSET_MANIFEST.csv`，记录：

- 生成工具或模型。
- 提示词 ID。
- 使用的原创参考资产 ID。
- 原始、源文件和游戏路径。
- 人工修改说明。
- 权利/许可证。
- 审核人和日期。
- 是否需要在 Steam AI 内容说明中披露。

## 4. Codex 生图规则

当 Codex 有图像生成技能时：

1. 先读取 `03_ART_BIBLE.md` 与 `11_IMAGE_PROMPT_LIBRARY.md`。
2. 先生成 brief 和文件命名计划。
3. 每次只生成一个资产组。
4. 输出进入 `art/generated_raw/<category>/<asset_id>/`。
5. 自动创建 `metadata.json`，保存提示词、尺寸、生成时间和参考资产 ID。
6. 创建联系表。
7. 更新 manifest 状态为 `generated_raw` 或 `candidate`。
8. 停止，等待项目负责人选择。

如果工具不可用：

- 创建待执行提示词和目录。
- 使用明显的几何占位图继续程序开发。
- 不声称已经生成图片。
- 不从网络随意下载替代素材。

## 5. 批量 Images API 规则

只有在视觉风格已锁定、单项流程已验证后才使用批量 API。

- 密钥从 `OPENAI_API_KEY` 环境变量读取。
- `.env` 必须被 Git 忽略。
- 脚本不得输出完整密钥到日志。
- 设置每次任务最大生成数量和预算保护。
- 失败时保留请求 ID 与错误，不无限重试。
- 脚本生成的文件仍需人工批准。
- API 输出不得直接写入 `game/assets`。

建议工具：

```text
tools/generate_assets.py
tools/make_contact_sheet.py
tools/validate_png_assets.py
tools/update_asset_manifest.py
```

## 6. 一致性策略

### 6.1 角色

- 使用批准母图作为唯一主要视觉参考。
- 固定不可变特征和色板。
- 一次编辑一个姿势或表情。
- 与母图叠加对比轮廓。
- 需要动画时先拆分或绑定，不独立生成每一帧。

### 6.2 场景

AI 可以生成氛围概念图，但可探索地图必须拆为：

- 地面 Tile。
- 水岸 Tile。
- 道路 Tile。
- 植物和石头。
- 房屋和桥梁。
- 前景遮挡。
- 独立碰撞和交互区域。

完整场景插画只用于加载画面、宣传或不可交互背景。

### 6.3 UI

- 图形与框体可生成。
- 文字、数字、按键名称和本地化内容由 Godot 渲染。
- 同一 UI 套系先批准一张组件板，再批量扩展。

## 7. 质量检查脚本建议

`validate_png_assets.py` 至少检查：

- 文件可打开。
- 宽高符合约定。
- 模式包含 alpha（需要透明的资产）。
- 透明边界是否存在异常非透明像素。
- 文件名是否匹配命名规范。
- 是否有重复哈希。
- 是否在 manifest 中登记。

自动检查不能替代视觉审查。

## 8. 预算控制

每周设置生图额度：

- 概念阶段优先少量高差异候选。
- 风格未批准前不批量生产。
- 相似候选超过 3 次仍未通过时，先修改 brief，而不是继续盲抽。
- 对常用小物件优先制作模块化套系。
- 记录废弃原因，避免重复生成同样错误。

## 9. Steam AI 内容记录

所有随游戏发布、由 AI 辅助生成的角色、场景、图标、音频或文本都标记为预生成 AI 内容候选，并保留实际工作流记录。

建议发布说明草稿，只有在与实际情况一致时使用：

> 开发过程中使用生成式 AI 辅助早期概念探索和部分 2D 视觉资产制作。所有随游戏发布的素材均经过人工选择、编辑、质量审查与项目内整合。游戏运行期间不会生成 AI 内容。

最终提交 Steam 前必须根据实际资产重新核对，不可照抄错误说明。

## 10. 失败处理

出现以下情况立即停止该资产组：

- 与现有 IP 高度近似。
- 多轮生成仍无法保持角色结构。
- 无法确认输入图片权利。
- 输出含水印、Logo 或可识别品牌。
- 透明背景和轮廓无法稳定修复。
- 实际尺寸下不可读。

停止后回到 brief，重新设计形状语言或改用人工绘制/3D 预渲染。

---

# 11 图像生成提示词库

版本：1.0  
日期：2026-08-30

这些模板用于 Codex 的图像生成技能或经批准的 Images API 流程。所有输出仍须遵守 `03_ART_BIBLE.md` 和 `04_AI_ASSET_PIPELINE.md`。

提示词建议使用英文主体以便固定术语，Codex 负责在 metadata 中同时记录中文 brief。

## 1. 通用风格前缀

```text
Original 2D game asset for a cozy wetland home-building game, soft hand-painted gouache storybook style, clean readable silhouette, gentle natural colors, subtle paper texture, consistent three-quarter top-down view, weak perspective, soft light from upper left, shadow direction toward lower right, production-ready shape design, no photorealism.
```

## 2. 通用透明素材后缀

```text
Full object visible, centered, isolated on a transparent background, no environment, no text, no letters, no numbers, no logo, no signature, no watermark, clean alpha edges, generous but not excessive padding.
```

## 3. 通用禁止约束

```text
Do not reference or imitate any existing character, entertainment IP, mascot, brand, or living artist. No fruit balanced on the head. No red shorts. No oversized baby-like head. No extra limbs, no duplicated features, no malformed paws, no inconsistent accessories, no baked-in ground shadow unless explicitly requested.
```

## 4. 主角首轮概念

```text
Create one of six clearly different original protagonist concepts for a cozy 2D wetland restoration game.

Species: capybara.
Personality: calm, observant, quietly enthusiastic about repairing waterways and building a home.
Required identity features: warm gray-brown fur, medium head-to-body ratio, slightly elongated muzzle, one subtly folded left ear, lake-teal waterproof scarf, a small water-lily-leaf-shaped crossbody satchel, dark oval eyes with tiny highlights.
Body language: patient and practical, standing with a slight forward lean.
Camera: three-quarter top-down game view.
Output: one full-body character only, transparent background.

Make this concept distinct in body shape, scarf tying method, satchel construction, and facial proportions while preserving all required identity features.

[APPEND COMMON STYLE PREFIX, TRANSPARENT SUFFIX, AND PROHIBITED CONSTRAINTS]
```

Codex 每次替换“concept 1/6”并写明差异，不允许只生成几乎相同的颜色变化。

## 5. 主角四方向母图

```text
Using the approved original character master reference, create a clean four-direction turnaround sheet for a 2D game: facing down, facing left, facing right, and facing up. Preserve exact body proportions, folded left ear, lake-teal scarf, water-lily satchel, muzzle shape, eye placement, and palette.

All four views must use the same three-quarter top-down camera angle and upper-left light. Neutral standing pose, full body visible, consistent scale. Separate each direction with clear spacing. Transparent background. No labels or text inside the image.
```

联系表文字由外部脚本添加，不能让模型生成方向标签。

## 6. 表情头像

```text
Using the approved original character master reference, create a single bust portrait with the expression: {expression}. Preserve exact proportions, fur colors, folded left ear, scarf and satchel strap. Soft hand-painted gouache storybook style, upper-left light, transparent background, no text.
```

一次只做一个表情，避免一张图中角色细节漂移。

## 7. NPC 概念

```text
Create an original {species} NPC for a cozy wetland home-building game.
Role: {role}.
Personality: {personality}.
Silhouette goal: {silhouette_goal}.
Required tools/clothing: {required_features}.
Palette: {palette}.
The character must be immediately distinguishable from the capybara protagonist in height, width, head shape, posture, and movement potential.
Three-quarter top-down game view, full body, transparent background.

Do not reuse the protagonist's face, scarf, satchel, or body proportions.
[APPEND COMMON STYLE PREFIX AND PROHIBITED CONSTRAINTS]
```

## 8. 单件家具

```text
Create one original placeable game prop: {object_name}.
Function: {function}.
Footprint: {width_cells} by {height_cells} cells on a 64-pixel logical grid.
Material: {material}.
Palette: {palette}.
Three-quarter top-down view with weak perspective, soft upper-left light. The base and contact points must be clear for grid placement. Full object visible, transparent background, no character, no text, no built-in UI badge.
```

## 9. 建筑

```text
Create an original small wetland cottage exterior for a cozy 2D game. It must fit a {width_cells} by {height_cells} logical grid footprint. Include a clearly readable front door sized for the established character scale, modular roof, simple windows, and construction materials from wood, reeds, clay, and river stone. Three-quarter top-down weak perspective, upper-left light, clean silhouette, transparent background, no sign text, no logo.
```

先生成整体概念，批准后再按门、屋顶、墙体和装饰模块拆分，不直接把完整概念图作为可交互建筑。

## 10. 植物或资源节点

```text
Create a small set of four consistent variants of {plant_or_resource}, designed as harvestable nodes for a cozy 2D game. Same species and palette, subtle differences in leaf or branch arrangement. Three-quarter top-down view, upper-left light, each variant separated with spacing, transparent background, no text. Keep all variants readable at approximately {display_size}px in game.
```

生成后拆分为独立文件并检查每个 alpha 边缘。

## 11. UI 图标

```text
Create a single original UI inventory icon for {item_name}. Soft painted storybook icon style, simplified shape, centered composition, high readability at 48 pixels, transparent background, no frame, no text, no number, no shadow outside the icon bounds.
```

UI 框和物品图标分开生成。

## 12. Tile 概念

AI 不应直接一次生成整套可用 autotile。先生成材质概念：

```text
Create a top-down material concept for {terrain_type}, designed for a cozy hand-painted 2D game. Even lighting, minimal directional objects, no large unique landmarks, no text. The texture should suggest repeatable coverage, but this is a concept source that will be manually edited into seamless 64x64 tiles.
```

随后由人工或脚本制作真正无缝 Tile、边缘和角落。

## 13. 加载画面/宣传插画

```text
Create an original key art illustration for a cozy wetland home-building game. Show the approved capybara protagonist beside a player-built pond with reeds, a wooden bench, a small cottage, and two original animal friends relaxing nearby. Emphasize the transformation from dry land to a lively waterside home. Soft hand-painted gouache storybook style, warm evening light, no text, no logo, no imitation of existing IP.
```

只有角色和环境母图稳定后才生成宣传插画。

## 14. 编辑提示词：修复一致性

```text
Edit the supplied approved original game asset. Preserve all approved shapes, proportions, palette, camera angle, lighting direction, and accessories. Change only: {single_requested_change}. Do not redesign any other feature. Keep transparent background and clean alpha edges.
```

每次只改一个问题。

## 15. 编辑提示词：透明边缘与阴影分离

```text
Preserve the object exactly. Remove the baked ground shadow and any background color. Reconstruct clean natural edges and output the object alone on a transparent background. Do not alter color, shape, texture, perspective, or proportions.
```

阴影需要时另生成：

```text
Create only a soft semi-transparent oval contact shadow matching the supplied object's footprint and upper-left lighting. No object, no background, transparent canvas.
```

## 16. 生图任务报告模板

```text
资产组：
读取的母图 ID：
使用的提示词 ID：
生成数量：
输出目录：
联系表：
manifest 更新：
主要差异：
已知问题：
等待批准的编号：
```

---

# 05 开发路线图

版本：1.0  
日期：2026-08-30

## 1. 时间假设

按项目负责人每周投入 15–20 小时、首次开发游戏、Codex 辅助编程计算：

- 垂直切片：约 4–6 个月。
- 可发布 1.0：约 12–18 个月。
- 如果每周少于 10 小时、美术全部单人制作或频繁增加功能，时间会明显延长。

时间是规划范围，不是交付承诺。每个阶段以验收门槛而不是日期为准。

## 2. 里程碑总览

| 阶段 | 名称 | 建议时长 | 结果 |
|---|---|---:|---|
| 0 | 工程初始化 | 1 周 | 可运行的灰盒项目与自动检查 |
| 1 | 移动与交互原型 | 2 周 | 10 分钟可探索灰盒 |
| 2 | 数据、背包与存档基础 | 3 周 | 稳定物品与保存框架 |
| 3 | 建造、农田与水体 | 5–7 周 | 核心“水边家园”循环 |
| 4 | 钓鱼、NPC 与任务 | 4–6 周 | 30–45 分钟完整体验 |
| 5 | 美术锁定与垂直切片 | 5–8 周 | 可公开展示的品质样片 |
| 6 | 内容生产 Alpha | 4–6 个月 | 全部主要系统与内容可玩 |
| 7 | Beta、Steam 与优化 | 2–3 个月 | 内容锁定、测试、发布候选 |
| 8 | 发布与维护 | 持续 | 首发、补丁和反馈处理 |

## 3. 阶段 0：工程初始化

目标：不依赖正式素材，建立可运行、可检查、可回退的工程。

交付：

- Godot 4.7.2 项目。
- 灰盒玩家移动。
- 边界碰撞。
- 暂停菜单。
- headless 检查。
- 最小测试入口。
- PowerShell 脚本。
- Git 忽略规则和文档更新。

通过门槛：`MASTER_PROMPT_FOR_CODEX.md` 中的 10 条验收全部满足。

## 4. 阶段 1：移动与交互原型

### 目标

证明基础操作舒适，建立可复用交互接口。

### 任务

- 玩家状态机。
- 四方向占位动画。
- 交互候选排序。
- 可拾取物。
- 可采集资源节点。
- 门、床、储物箱占位交互。
- 区域转场。
- 输入提示自动切换键盘/手柄。
- 调试覆盖层。

### 退出标准

- 玩家连续游玩 10 分钟无卡死。
- 键鼠和手柄均可完成全部操作。
- 交互对象不易误选。
- 转场无重复玩家或状态丢失。
- 至少 5 个纯逻辑测试和 2 个集成测试通过。

## 5. 阶段 2：数据、背包与存档

### 目标

建立所有后续内容依赖的数据基础。

### 任务

- ItemDefinition 与内容注册表。
- 24 格背包和堆叠。
- 快捷栏。
- 储物箱。
- 简单商店接口。
- SaveManager v1。
- 临时文件、备份、损坏回退。
- 设置系统。
- zh_CN / en 本地化框架。

### 退出标准

- 100 次随机物品增减测试不出现负数或丢失。
- 保存、退出、重开后位置和物品一致。
- 删除字段、添加字段时旧存档能用默认值读取。
- 损坏主存档时能恢复备份并提示。

## 6. 阶段 3：建造、农田与水体

### 目标

证明项目的核心差异化玩法。

### 子阶段 3A：网格与家具

- TileMapLayer 区域。
- 网格光标。
- 放置预览和占地检查。
- 5 件占位家具。
- 移动与收回。
- 动态导航阻挡。

### 子阶段 3B：种植

- 翻土、播种、湿润和跨日成长。
- 3 种作物。
- 水体自动灌溉范围。
- 收获与背包。

### 子阶段 3C：池塘

- 可挖掘遮罩。
- 地面转浅水。
- 岸边自动连接。
- 填土。
- 水体连通与面积。
- 水生植物放置。
- `pond_comfort_score`。

### 退出标准

- 玩家能从采集材料开始，建造木凳、种植作物、挖出池塘并触发舒适度变化。
- 保存读取后所有格状态与家具实例一致。
- 不可挖区、建筑下方和地图边界无法被破坏。
- 连续编辑 200 次后无明显性能下降或状态损坏。

## 7. 阶段 4：钓鱼、NPC 与任务

### 目标

把系统连接成完整 30–45 分钟流程。

### 任务

- 3 种鱼和鱼池表。
- 钓鱼小游戏。
- NPC 数据、路径和日程。
- 水獭木匠的完整小故事。
- 兔子园艺师的短请求。
- 关系阶段。
- 一起泡水/坐下活动。
- 请求日志。
- 小桥修复与果树林入口解锁。

### 退出标准

- 从新存档开始可完整完成故事。
- 关键剧情不依赖随机日程。
- NPC 在玩家建造家具和修改水体后仍能寻路。
- 故事完成状态可稳定保存。
- 钓鱼可用键盘、鼠标和手柄完成。

## 8. 阶段 5：美术锁定与垂直切片

### 目标

替换主要占位图，达到可向陌生玩家展示的质量。

### 任务

- 原创主角概念 6–12 个，批准 1 个。
- PLAYER_MASTER_V1。
- 主角四方向基础动画。
- 水獭和兔子母图。
- 一套地面、水岸、植物、家具和房屋美术。
- UI 主组件板。
- 环境音、基础音乐和关键音效。
- 镜头、过场和最终泡水场景。
- 外部试玩 10–20 人。

### 退出标准

- 未看过说明的玩家能理解主要操作。
- 80% 以上测试者能完成垂直切片。
- 多数测试者能描述“用水改善家园”的核心特色。
- 没有严重保存、卡死或阻断 Bug。
- 所有最终资产已登记来源和 AI 使用情况。

## 9. 阶段 6：内容生产 Alpha

内容目标遵循 `01_GAME_DESIGN.md` 的上限，不因进度良好自动扩大。

重点：

- 完成 4 个区域。
- 完成 6–8 个主要 NPC。
- 补齐作物、鱼、家具和故事。
- 住宅升级。
- 栖息地等级与区域解锁。
- 完整音频与本地化初稿。
- Steamworks 基础接口封装，但非 Steam 构建仍能运行。

Alpha 定义：所有计划系统和主要内容从头到尾可玩，但仍有占位、Bug 和平衡问题。

## 10. 阶段 7：Beta 与发布候选

- 内容冻结。
- 只修 Bug、性能、可访问性和文本。
- Steam Cloud。
- Steam Input/手柄图标。
- 基础成就。
- 商店页与真实截图。
- Playtest 或 Demo。
- Steam Deck 1280×800 测试。
- Windows 10/11 测试。
- AI 内容调查与权利清单复核。
- 存档迁移演练。

Beta 退出标准：

- 无阻断 Bug。
- 高优先级 Bug 已有解决方案。
- 新用户从安装到完成主线无开发者干预。
- 发布构建可在干净机器安装和卸载。
- Steam 审核所需素材和说明完整。

## 11. 每周工作节奏

### 周初

- 从 backlog 选择 1 个主要任务和最多 2 个小任务。
- 写明确验收标准。
- Git 创建分支或记录恢复点。

### 周中

- Codex 小步实现。
- 每项任务后运行检查。
- 每天至少一次亲自试玩。

### 周末

- 完成一次从新存档开始的回归。
- 更新变更日志和决策日志。
- 录制 1–3 分钟开发视频，用于观察而不一定公开。
- 未完成任务拆小，不把整周未验证改动继续堆积。

## 12. 范围变更规则

任何新功能先进入 `Parking Lot`，回答：

- 它是否强化“水边家园”核心？
- 能否复用现有系统？
- 会增加多少美术、动画、UI、存档和测试成本？
- 可以删除哪项同等工作量的旧功能？
- 垂直切片是否真的需要？

没有明确删除项的新功能，默认不进入当前里程碑。

## 13. 立即停止并回退的信号

- 项目连续两天无法运行。
- 存档在常规操作中丢失。
- Codex 一次改动超过 30 个无关文件。
- 同一功能同时出现两套竞争架构。
- 正式美术未锁定就批量生成数百项资产。
- 为解决小问题加入大型插件或重写系统。
- 试玩者普遍不理解核心循环。

---

# 06 QA、测试与验收计划

版本：1.0  
日期：2026-08-30

## 1. 测试目标

- 让每次 Codex 修改都能被验证，而不是“看起来应该可以”。
- 尽早保护存档、物品、建造和水体等高风险状态。
- 保证键鼠、手柄、不同分辨率和 Steam Deck 方向从早期就不掉队。
- 所有已修复严重问题都有回归办法。

## 2. Definition of Done

功能只有同时满足以下条件才算完成：

- 验收标准通过。
- 代码可解析、项目可运行。
- 自动测试实际执行成功。
- 有手工试玩步骤。
- 无明显回归。
- 必要文档已更新。
- 新数据使用稳定 ID。
- 玩家文字已本地化。
- 涉及素材时 manifest 已更新。
- 涉及存档时已有迁移或默认值策略。

## 3. 测试层级

### 3.1 纯逻辑单元测试

优先测试：

- 网格坐标转换。
- 输入向量归一化。
- 背包堆叠和容量。
- 建造占地判断。
- 水体连通算法。
- 灌溉范围。
- 鱼池权重选择。
- 关系阈值。
- 存档迁移和字段校验。

这些测试不依赖场景渲染，适合 headless 快速运行。

### 3.2 集成测试场景

覆盖：

- 玩家移动与碰撞。
- 交互候选排序。
- 家具放置/移动/收回。
- 翻土、种植和跨日。
- 挖水、填土和岸边更新。
- NPC 路径更新。
- 保存、重载同一场景。
- 区域转场。

### 3.3 手工体验测试

自动测试无法判断：

- 操作手感。
- UI 是否清楚。
- 角色是否可爱且一致。
- 钓鱼节奏是否舒服。
- 玩家是否理解下一步。
- 动画和音效是否有情绪反馈。

每个里程碑必须由项目负责人亲自从新存档试玩。

## 4. 必测平台矩阵

### 开发期最低矩阵

- Windows 11，1920×1080，键鼠。
- Windows 11，1280×720，手柄。
- 1280×800 窗口，模拟 Steam Deck UI。
- 集成显卡或性能较低机器至少一台。

### Beta 增加

- Windows 10 64 位。
- 常见 Xbox 布局手柄。
- PlayStation 布局手柄经 Steam Input。
- Steam Deck 实机或正式兼容性测试环境。
- 多显示器、窗口/全屏切换。
- 非管理员用户目录。

## 5. 每次提交前冒烟测试

1. 启动到主菜单。
2. 新建游戏。
3. 移动、碰撞、交互。
4. 打开与关闭背包。
5. 放置和收回一个家具。
6. 改变一格农田和一格水体。
7. 保存。
8. 返回主菜单。
9. 读取。
10. 确认位置、背包、家具、农田和水体一致。
11. 暂停与退出。
12. 运行 headless 检查。

未实现的步骤在早期标记为 N/A，不假装通过。

## 6. 存档专项测试

- 空存档。
- 正常存档。
- 保存时退出模拟。
- 主文件损坏、备份有效。
- 主文件和备份都损坏。
- 缺少可选字段。
- 未知新字段。
- 旧 schema 迁移。
- 内容定义 ID 已删除。
- 家具位于后来变为禁区的格子。
- 背包数量接近上限。
- 非 ASCII 玩家名称或系统用户名。
- 磁盘空间不足或写入失败。

保存错误不能导致正在运行的内存状态被清空。

## 7. 建造与水体专项测试

- 地图四个边界。
- 建筑相邻放置。
- 重叠占地。
- 旋转变体缺失。
- NPC 正站在目标格。
- 水体旁放置家具。
- 建筑下尝试挖水。
- 连续挖/填相同格。
- 分割一片连通水体。
- 合并两片水体。
- 读取后自动岸边是否一致。
- 200 次随机编辑后状态是否一致。

## 8. 输入与 UI 专项测试

- 只用键盘完成所有菜单。
- 只用手柄完成所有菜单。
- 鼠标与手柄来回切换提示。
- 断开手柄时不丢失控制。
- UI 缩放 100/125/150%。
- 简体中文与英文切换。
- 长文本、超长物品名。
- 1280×800 无按钮出屏。
- 暂停时游戏逻辑是否真的停止。
- 弹窗焦点不会跑到背景按钮。

## 9. 性能目标

垂直切片阶段：

- 常规区域目标 60 FPS。
- 低性能设备允许稳定 30 FPS 作为保底，但输入和 UI 不应卡顿。
- 区域进入后无明显持续卡顿。
- 保存通常在 200 ms 内完成；超时时显示非阻塞提示。
- 不在每帧重算全地图水体、灌溉或 NPC 路径。
- 开发版记录帧时间峰值。

## 10. Bug 严重级别

### S0 阻断

- 无法启动。
- 存档永久丢失。
- 主线不可继续且无绕过。
- 导出构建崩溃。

立即停止新功能。

### S1 严重

- 高频崩溃。
- 物品复制/丢失。
- NPC 永久卡死导致任务失败。
- 手柄无法完成关键操作。

当前里程碑必须修复。

### S2 中等

- UI 错位。
- 动画或音效明显错误。
- 可绕过的任务问题。
- 性能局部下降。

进入近期 backlog。

### S3 轻微

- 文本、像素边缘、轻微视觉瑕疵。
- 不影响完成流程。

集中修整。

## 11. Bug 报告模板

```text
标题：
构建版本：
平台/分辨率/输入：
存档槽：
前置条件：
复现步骤：
实际结果：
预期结果：
复现概率：
截图/视频/日志：
最后已知正常版本：
严重级别：
```

## 12. Codex 测试报告要求

Codex 每次完成任务必须写明：

- 实际执行的命令。
- 每个命令的退出码。
- 自动测试数量和结果。
- 没有执行的检查及原因。
- 手工测试步骤。
- 未解决警告。

“理论上可以”“看代码应该没问题”不算测试结果。

## 13. 里程碑外部试玩

垂直切片至少安排：

- 3 名从不玩模拟游戏的玩家。
- 5 名喜欢温馨/种田游戏的玩家。
- 2 名主要使用手柄的玩家。

观察而不立即提示，记录：

- 第一次卡住的位置。
- 第一次主动装饰的位置。
- 是否理解水体用途。
- 完成时间。
- 最喜欢和最不喜欢的动作。
- 是否愿意继续玩。

不要只收集“好不好玩”的口头评价，要记录行为。

---

# 07 Steam 发布清单

版本：1.0  
日期：2026-08-30

Steam 的规则和页面要求可能更新。真正提交前必须再次核对官方 Steamworks 文档，本文件用于项目规划，不替代当时的正式要求。

## 1. 入驻准备

- 确定发布主体：个人或公司。
- 准备身份、银行与税务信息。
- 签署 Steamworks 协议。
- 为应用支付 Steam Direct 费用。
- 预留首次应用从缴费到可发布的等待时间。
- 公开“即将推出”页面保持至少要求的时间。
- 不在名称和胶囊图中使用无权 IP。

## 2. 何时创建 Steam 应用

建议在以下条件满足后进行：

- 原创主角已锁定。
- 游戏正式或接近正式名称已确定。
- 垂直切片稳定可玩。
- 有真实实机截图。
- 能制作 30–60 秒实机视频。
- 核心玩法不会完全推翻。

不要只凭概念图创建商店页并承诺尚未验证的功能。

## 3. 商店页面

### 文案

- 一句话卖点突出“用水修复湿地并建设动物家园”。
- 描述实际已有或确定会完成的功能。
- 不写“无限开放世界”“上百 NPC”等夸张承诺。
- 清楚说明单人、休闲、无战斗。
- 简体中文和英文分别人工审校。

### 图片

- 只使用真实游戏画面或明确标注的宣传插画。
- 胶囊图需要高对比主角和水边家园识别点。
- 截图至少覆盖：挖池塘、布置家园、种植、钓鱼、NPC 泡水、区域探索。
- UI 不应在每张图中遮挡主要内容。

### 预告片

前 10 秒直接展示：

1. 荒地。
2. 玩家挖出水体。
3. 植物生长和动物来访。

其后展示建造、钓鱼、关系和家园前后对比。尽量使用实机镜头，不以概念动画代替游戏。

## 4. AI 内容调查

本项目预计包含开发期间生成的预制 AI 视觉资产，因此需要：

- 记录哪些发布资产由 AI 辅助生成。
- 说明所有最终资产经过人工选择、编辑和审查。
- 确认不存在非法或侵权内容。
- 说明游戏运行时不生成 AI 内容，前提是最终版本确实如此。
- 商店描述、内容调查与实际构建保持一致。

提交前由人工逐项核对 `ASSET_MANIFEST.csv`，不能只依靠 Codex 自动判断。

## 5. 构建与 Depot

- Windows x86_64 Release 构建。
- 独立 Debug/Playtest/Release 渠道。
- 构建号与 Git commit 可追踪。
- 干净机器安装测试。
- 不包含源文件、API 密钥、原始生图、调试菜单或测试存档。
- Steamworks redistributables 与 SDK 按官方要求配置。
- 上传脚本不在日志显示敏感凭据。

## 6. Steamworks 功能优先级

### 首发建议

- Steam Cloud。
- Steam Input / 完整手柄支持。
- 10–20 个基础成就。
- Overlay 兼容。
- Playtime 与语言正常。

### 可后置

- 排行榜。
- Workshop。
- Remote Play 特殊功能。
- 复杂统计系统。
- 联机功能。

## 7. Steam Cloud

- 只同步 `user://saves/` 下的正式存档。
- 设置文件是否同步需谨慎，避免不同设备分辨率冲突。
- 不同步缓存、日志、临时文件和原始截图。
- 测试两台设备先后修改存档的冲突情况。
- 版本升级前确认旧云存档可迁移。

## 8. Steam Deck 与手柄

- 支持 1280×800。
- 文字在掌机距离可读。
- 不需要鼠标完成任何核心操作。
- 显示正确的控制器提示。
- 可唤出屏幕键盘的地方尽量少。
- 休眠恢复后声音、输入和保存正常。
- 性能与功耗稳定。
- 启动器不可要求触摸小按钮。

## 9. Playtest / Demo

建议先使用 Steam Playtest 或小规模外部测试：

- 与正式游戏分离管理测试权限。
- 收集崩溃、卡点和完成率。
- 测试新用户引导和手柄。
- 不把未打磨的大量内容交给玩家，只给一段完整体验。

Demo 建议内容：

- 30–45 分钟垂直切片。
- 可保存，但与正式版存档兼容策略要明确。
- 结束时展示下一片区域和愿望单提示。
- 不需要包含所有系统。

## 10. 发布前 30 天

- 内容冻结。
- 完成商店页最终检查。
- 完成 AI 与权利清单。
- 运行全平台回归。
- 准备首日补丁分支。
- 提交 Steam 审核并预留返工时间。
- 给测试者验证候选构建。
- 备份上传脚本、构建与符号信息。

## 11. 发布前 7 天

- 只接受 S0/S1 修复。
- 所有修复经过完整冒烟测试。
- 验证商店描述、语言、价格和发布时间。
- 验证成就不会提前或无法触发。
- 验证新存档和旧测试存档。
- 准备已知问题说明和支持邮箱。

## 12. 发布日

- 确认正确分支与 Depot live。
- 从普通用户账号安装并启动。
- 监控论坛、评论、崩溃和存档问题。
- 不因轻微问题立即推送未经验证的热修复。
- 优先处理启动、控制器、存档和主线阻断。

## 13. 发布后

- 第 1–3 天：紧急稳定性补丁。
- 第 1–2 周：体验与平衡补丁。
- 第 1 个月：汇总反馈，决定小型内容更新。
- 不承诺无法按时完成的大型路线图。
- 保存格式更新始终提供迁移。

---

# 08 产品定位与营销方案

版本：1.0  
日期：2026-08-30

## 1. 推荐定位

不是“什么都有的开放世界农场游戏”，而是：

> 一款围绕水体改造和动物陪伴展开的温馨家园游戏。玩家把干涸湿地变成朋友们愿意来泡水、钓鱼和生活的社区。

## 2. 目标玩家

- 喜欢温馨、放松、建造和生活模拟的玩家。
- 喜欢动物角色和家园装饰的玩家。
- 不喜欢战斗、惩罚和高强度资源压力的玩家。
- 希望短时间也能获得进展的玩家。
- Steam Deck 和手柄玩家。

## 3. 核心卖点顺序

1. 自己挖出并设计池塘和水渠。
2. 水环境会影响种植、鱼类和动物来访。
3. 与动物朋友一起泡水、坐下和建设社区。
4. 自由布置温暖的水边家园。
5. 无战斗、无失败倒计时的轻松体验。

## 4. 名称策略

`Capybara` 可作为内部代号，但正式商店名建议包含独特副标题，提升搜索辨识度并降低同名风险。

命名标准：

- 中英文都易读。
- 不依赖第三方 IP。
- 能联想到水、家园、湿地或朋友。
- Steam 搜索中易区分。
- 可注册社交账号和域名。
- 经过商标与同名作品初步检索。

候选方向仅供后续创意，不代表已完成检索：

- Capybara: Waterside Home
- Capybara Haven
- Little Wetland Home
- 水豚的水边小家
- 水岸慢生活

## 5. Steam 标签方向

根据实际成品选择，不滥用：

- Cozy
- Relaxing
- Casual
- Life Sim
- Building
- Farming Sim
- Fishing
- Nature
- Cute
- Singleplayer
- Exploration
- Character Customization

## 6. 商店短描述草稿

> 挖池塘、引水、种植和布置家园，把一片干涸湿地变成动物朋友们愿意来泡水、钓鱼和生活的温暖社区。这是一款无战斗、低压力的 2D 水边家园生活游戏。

该文案必须在功能完成后按实际内容调整。

## 7. 截图计划

至少准备以下真实画面：

1. 荒地与修复后的家园对比。
2. 玩家正在挖池塘，显示岸边自动连接。
3. 池塘旁的家具与水生植物。
4. 三种作物和自动灌溉。
5. 钓鱼小游戏。
6. 水獭木匠修桥。
7. 两只动物一起泡水。
8. 果树林探索。
9. 背包或建造 UI，但不超过 2 张 UI-heavy 截图。
10. 傍晚完整家园全景。

## 8. 预告片节奏

### 0–10 秒

- 干涸湿地。
- 一铲挖开水面。
- 快速前后对比。
- 标题和一句核心卖点。

### 10–35 秒

- 种植、建造、池塘装饰。
- 钓鱼。
- NPC 互动。
- 家园逐步热闹。

### 35–55 秒

- 四个区域的短镜头。
- 主角装扮。
- 傍晚泡水场景。
- 愿望单行动号召。

只使用实际游戏可实现的画面。

## 9. Demo 作为营销核心

Demo 不是零散功能集合，而是一段完整情绪弧线：

```text
荒地 -> 第一次挖水 -> 种植和钓鱼 -> 帮助朋友 -> 装饰池塘 -> 朋友来访 -> 新区域出现
```

结束时玩家应看到“这是我改变的地方”。

## 10. 开发日志内容

每两到四周发布一次高质量更新即可：

- 池塘系统前后对比。
- 一位 NPC 的动作设计。
- AI 概念如何经过人工修整成为游戏素材。
- 同一资产从大图到实际 128px 的过程。
- 手柄和 Steam Deck UI 优化。
- 玩家反馈如何改变设计。

不要每天发布大量未定稿 AI 图片，以免品牌形象混乱。

## 11. 商业模式建议

- 首版采用一次性买断。
- 不做抽卡、体力付费或广告。
- 后续内容更新先修复与扩展基础游戏。
- 是否制作付费 DLC，在 1.0 稳定并获得真实玩家反馈后决定。
- 定价在垂直切片完成后结合内容时长、品质和同类市场重新研究，不在前期锁死。

## 12. 品牌识别

最终宣传图中反复出现三个视觉锚点：

- 原创水豚的湖水青围巾与睡莲包。
- 可自由设计的蓝绿色池塘。
- 动物朋友围着水体休息的场景。

这样即使玩家快速浏览，也能理解游戏不是普通种田换皮。

---

# 09 权利、原创性与 AI 使用政策

版本：1.0  
日期：2026-08-30

本文件是项目内部风险控制规则，不构成针对具体司法辖区的法律意见。签约、商标、重大授权或争议应咨询专业人士。

## 1. 原创项目基线

- 项目不以“水豚噜噜”或其他第三方角色为基础。
- 未获得明确权利前，不使用其名称、图片、模型、动作、服装、故事、Logo 或宣传素材。
- 上传过的参考图片也不能自动视为可商用素材。
- “水豚”作为动物题材可以创作，但具体角色表达必须独立设计。

## 2. 生图输入规则

允许：

- 自己编写的原创文字设定。
- 本项目已经批准且权利清楚的原创母图。
- 自己拍摄或明确拥有商业使用权的材质参考。
- 明确允许相应用途的公共领域/许可素材，并记录许可证。

不允许：

- 未授权角色图。
- 从社交媒体下载的插画。
- “做得像某某 IP”。
- “模仿某位在世艺术家”。
- 含有品牌 Logo、签名或水印的图片。
- 来源不明的字体、音乐和音效。

## 3. 相似性审查

主角和主要 NPC 批准前，应对以下组合进行人工比较：

- 头身比例。
- 脸型和眼睛布局。
- 标志性头饰。
- 服装配色。
- 剪影。
- 固定动作和道具。
- 名称和口头禅。

任何单一元素可能常见，但多个标志元素组合近似时应重新设计。

## 4. 资产证据链

每个发布素材保留：

- brief。
- 提示词版本。
- 原始生成文件。
- 选择记录。
- 人工修改源文件。
- 导出文件。
- 使用的参考资产 ID。
- 工具/模型名称与日期。
- 许可证、购买凭证或创作者合同。
- 最终批准记录。

这套记录既服务 Steam 内容调查，也方便未来替换和维护。

## 5. AI 输出的项目政策

- 不假设 AI 输出具有绝对唯一性。
- 不因工具条款允许使用输出，就忽略第三方权利和相似性风险。
- 重要角色必须有明显的人类选择、编排、编辑和设计贡献。
- 保留可编辑源文件，而不只保存最终扁平 PNG。
- 不把未经人工检查的输出直接发布。

## 6. Steam 披露

随游戏发布、由 AI 工具帮助创作且玩家会看到或听到的内容，纳入预生成 AI 内容清单。

发布前核对：

- 角色和 NPC。
- 环境与建筑。
- UI 图标与插画。
- 音乐、音效、语音。
- 对话、剧情和本地化。
- 商店宣传素材。

游戏当前计划不使用运行时 AI。如果未来改变，必须重新评估内容过滤、成本、隐私、联网和 Steam 披露，不能直接加入。

## 7. 字体、音频与插件

- 字体必须允许嵌入商业游戏和多语言发布。
- 音乐和音效记录作者、平台、许可证与购买日期。
- 外包合同写明游戏、商店页、预告片、更新和全球平台使用权。
- Godot 插件记录许可证、版本、来源和是否仍维护。
- 不把仅限个人使用或禁止再分发的素材打包。

## 8. 商标与名称

正式名称确定前进行：

- Steam 同名搜索。
- 常见搜索引擎与应用商店搜索。
- 目标市场商标初步检索。
- 域名和社交账号检查。
- 中文、英文和近似读音检查。

`Capybara` 是通用英文动物名，建议增加独特副标题。

## 9. 隐私与网络

v1.0 计划离线运行，不收集账号、聊天、位置或行为分析数据。

如果后来加入崩溃报告或分析：

- 明确收集字段。
- 最小化数据。
- 提供隐私说明和退出选项。
- 不上传存档内容或个人路径。
- 不把 API 密钥放在客户端。

## 10. 外包与协作者

每位协作者需要：

- 明确交付物。
- 原创和权利保证。
- 是否允许使用生成式 AI。
- 源文件交付。
- 修改与商业发行权。
- 署名方式。
- 保密与未公开内容规则。

## 11. 发布前权利清单

- 主角和 NPC 通过相似性审查。
- 游戏名称完成检索。
- 所有字体许可证已保存。
- 所有音乐/音效许可证已保存。
- 所有插件许可证已保存。
- AI 资产 manifest 无空白关键字段。
- 商店图与实际构建一致。
- 无测试用下载图片残留。
- 导出包无源文件和密钥。
- Steam AI 内容回答与实际使用一致。

---

# 10 决策日志

版本：1.0  
创建日期：2026-08-30

重要技术和产品决定必须记录，避免几周后重复讨论或让 Codex自行改变方向。

## 已确定决定

| ID | 日期 | 决定 | 原因 | 影响 | 状态 |
|---|---|---|---|---|---|
| DEC-001 | 2026-08-30 | 使用原创水豚角色，不使用水豚噜噜 IP | 避免授权不确定性，建立独立品牌 | 需要完整原创角色设计与相似性审查 | Accepted |
| DEC-002 | 2026-08-30 | 使用 Godot 4.7.2 Standard + GDScript | 适合 2D、轻量、无引擎版税、便于 Codex 操作 | 固定版本，不自动升级 | Accepted |
| DEC-003 | 2026-08-30 | 使用区域式半开放地图 | 降低无缝大世界和加载复杂度 | 每个区域独立场景和状态 | Accepted |
| DEC-004 | 2026-08-30 | 核心差异化是水体改造和湿地恢复 | 将建造、种植、钓鱼和 NPC 统一 | 水体系统优先级高 | Accepted |
| DEC-005 | 2026-08-30 | v1.0 无战斗、无联机、无运行时 AI | 控制首作范围和发布风险 | 不建立网络与敌人架构 | Accepted |
| DEC-006 | 2026-08-30 | 美术采用 3/4 俯视、非像素、柔和绘本风 | 与温馨题材匹配并适合 AI 概念生产 | 需要严格视角和母图流程 | Accepted |
| DEC-007 | 2026-08-30 | 游戏运行时不调用生成式 AI | 降低成本、审核、隐私和稳定性风险 | AI 只做预生成内容 | Accepted |
| DEC-008 | 2026-08-30 | 64×64 逻辑建造网格 | 平衡视觉细节和系统实现 | Tile、家具和水体按格设计 | Accepted |

## 待决定

| ID | 问题 | 建议决定时间 | 候选 | 状态 |
|---|---|---|---|---|
| OPEN-001 | 正式中英文名称 | 主角母图批准后 | 带水边/湿地/家园副标题 | Open |
| OPEN-002 | 主角最终色板与配饰 | 美术阶段首轮 | 围巾+睡莲包基线或替代方案 | Open |
| OPEN-003 | 动画主要方式 | PLAYER_MASTER_V1 后 | Godot Cutout / Blender 预渲染 / 混合 | Open |
| OPEN-004 | 是否首发同步英文 | 垂直切片后 | 同步中英 / 中文先行但保留框架 | Open |
| OPEN-005 | 定价 | 商店页前 | 根据内容和市场研究 | Open |

## 新决策模板

```text
ID：DEC-XXX
日期：YYYY-MM-DD
问题：
决定：
背景：
考虑过的替代方案：
原因：
影响：
可逆性：容易 / 中等 / 困难
批准人：
状态：Proposed / Accepted / Superseded
```

---

# 项目变更记录

## 2026-08-30 — 规划包 v1.0

- 建立游戏设计、技术设计、美术规范、AI 素材流程、路线图、QA、Steam、营销和权利政策。
- 固定初始技术路线为 Godot 4.7.2 Standard + 静态类型 GDScript。
- 固定首版范围：单人、Windows/Steam、无战斗、无联机、无运行时 AI。
- 将水体改造确定为核心差异化系统。

## 后续条目模板

```text
## YYYY-MM-DD — 版本/里程碑

Added
-

Changed
-

Fixed
-

Known Issues
-
```

---

# 附录 A：第一次发送给 Codex 的消息

```text
当前项目根目录固定为：

E:\Capybara

请先确认你当前打开的工作区根目录就是 E:\Capybara，不要在其他位置新建第二个项目，也不要只打开 game 子目录。

本轮先不要修改、创建、删除或移动任何文件。请按顺序完整阅读：

1. E:\Capybara\00_START_HERE_E_DRIVE.md
2. E:\Capybara\README_FIRST.md
3. E:\Capybara\AGENTS.md
4. E:\Capybara\MASTER_PROMPT_FOR_CODEX.md
5. MASTER_PROMPT_FOR_CODEX.md 指定的 docs 文件

阅读后，请只回复以下内容：

1. 你理解的产品目标。
2. 阶段 0 的明确边界，以及本轮绝对不做的内容。
3. 你检测到的环境情况：Windows、Git、Git LFS、GODOT_BIN、Godot 版本及项目目录。
4. 最多 8 条的阶段 0 实施计划。
5. 当前阻塞项、风险和需要我决定的事项。
6. 你准备实际执行的检查命令。

请勿在这条回复中开始写代码或改文件。输出计划后立即停止，等待我发送“开始执行阶段 0”。不要进入阶段 1，不要生成正式美术，不要接入 Steamworks，不要自动提交或推送 Git。
```

---

# 附录 B：确认计划后发送给 Codex 的消息

```text
我已经看过你的阶段 0 计划。现在开始执行阶段 0。

请严格遵守：

- 项目根目录是 E:\Capybara。
- 完整执行 E:\Capybara\MASTER_PROMPT_FOR_CODEX.md。
- 本轮只做阶段 0，不得提前进入阶段 1。
- 不使用任何第三方或未经授权的图片、音频、字体或插件。
- 只使用基础几何图形制作灰盒占位角色和场景。
- 不擅自下载二进制软件，不自动升级 Godot。
- 每项检查都必须实际运行；失败就如实报告，不得声称“应该通过”。
- 不通过删除测试、屏蔽错误或注释功能来让检查变绿。
- 不自动提交或推送 Git。

完成后请严格按以下结构报告，并停止：

完成摘要
修改文件
新增文件
执行命令与实际结果
手工试玩步骤
未通过的检查
已知问题
需要我决定的事项
下一阶段建议（只列建议，不执行）
```

---

# 附录 C：BACKLOG.csv

```csv
﻿id,phase,epic,task,priority,dependencies,acceptance_criteria,status,owner_notes
CAP-0001,0,Setup,确认 Godot 4.7.2 可执行路径,P0,,GODOT_BIN 可用于 headless 与 editor；失败时有明确说明,todo,
CAP-0002,0,Setup,初始化 Git 与 .gitignore,P0,CAP-0001,缓存、构建、密钥与 raw AI 输出不进入 Git,todo,
CAP-0003,0,Project,创建 Godot Compatibility 项目,P0,CAP-0001,项目可打开，无解析错误，主场景路径正确,todo,
CAP-0004,0,Player,创建灰盒四方向移动,P0,CAP-0003,斜向归一化，碰撞有效，最后朝向保存,todo,
CAP-0005,0,UI,创建暂停菜单,P0,CAP-0003,继续与退出有效，手柄可聚焦,todo,
CAP-0006,0,Testing,创建 headless 检查与测试入口,P0,CAP-0003,PowerShell 返回正确退出码并实际运行,todo,
CAP-0101,1,Player,玩家状态机,P0,CAP-0004,Idle/Move/Interact 互斥且可测试,todo,
CAP-0102,1,Interaction,通用交互接口,P0,CAP-0101,可拾取物、资源点和 NPC 使用统一协议,todo,
CAP-0103,1,Input,键盘/手柄提示切换,P1,CAP-0005,最后输入设备变化时提示正确,todo,
CAP-0104,1,World,区域切换与玩家出生点,P0,CAP-0101,往返区域位置与状态正确,todo,
CAP-0201,2,Data,ItemDefinition 与内容注册表,P0,CAP-0102,稳定 ID 可加载且重复/缺失会报错,todo,
CAP-0202,2,Inventory,背包与堆叠,P0,CAP-0201,容量、堆叠、溢出和任务物品规则通过测试,todo,
CAP-0203,2,Inventory,快捷栏与储物箱,P1,CAP-0202,键鼠手柄可操作，状态可保存,todo,
CAP-0204,2,Save,SaveManager v1,P0,"CAP-0202,CAP-0104",原子写入、备份、读取与错误提示通过,todo,
CAP-0205,2,Localization,zh_CN/en 本地化框架,P1,CAP-0005,玩家可见文字不写死，切换语言后 UI 正常,todo,
CAP-0206,2,Settings,音量、窗口、UI 缩放与输入设置,P1,CAP-0005,重启后设置保留，1280x800 无出屏,todo,
CAP-0301,3,WorldGrid,64px 网格状态服务,P0,CAP-0104,世界数据与 TileMap 表现分离,todo,
CAP-0302,3,Building,放置预览与占地验证,P0,"CAP-0301,CAP-0202",有效/无效反馈清楚，不重叠、不越界,todo,
CAP-0303,3,Building,家具实例移动和收回,P1,"CAP-0302,CAP-0204",实例 ID 稳定，保存后位置一致,todo,
CAP-0310,3,Farming,翻土、播种与跨日成长,P0,"CAP-0301,CAP-0201",3 种作物可完整种收并保存,todo,
CAP-0311,3,Farming,水体自动灌溉,P0,"CAP-0310,CAP-0320",水体改变后受影响农田正确更新,todo,
CAP-0320,3,Water,挖水/填土与可挖遮罩,P0,CAP-0301,边界、建筑和保护区不可破坏,todo,
CAP-0321,3,Water,岸边 terrain 更新,P0,CAP-0320,直边、内外角和孤立格表现正确,todo,
CAP-0322,3,Water,连通水体和舒适度,P0,CAP-0320,合并/分割后面积与评分正确,todo,
CAP-0401,4,Fishing,鱼定义和鱼池表,P1,"CAP-0201,CAP-0322",3 种鱼按条件可复现抽取,todo,
CAP-0402,4,Fishing,单键钓鱼小游戏,P0,CAP-0401,键鼠和手柄可完成，失败反馈清楚,todo,
CAP-0410,4,NPC,NPC 状态和网格路径,P0,CAP-0303,动态建筑/水体后仍可寻路或安全失败,todo,
CAP-0411,4,NPC,日程与活动点,P1,CAP-0410,跨日和区域加载后日程稳定,todo,
CAP-0420,4,Dialogue,可本地化对话数据,P0,CAP-0205,分支、条件和白名单效果可测试,todo,
CAP-0421,4,Quest,水獭木匠故事线,P0,"CAP-0420,CAP-0410,CAP-0322",从新存档可完成并解锁小桥,todo,
CAP-0422,4,Relationship,一起泡水事件,P0,CAP-0421,池塘达标后可靠触发，状态可保存,todo,
CAP-0501,5,Art,生成主角原创概念候选,P0,,6–12 个高差异候选，联系表和 manifest 完整,todo,等待程序灰盒稳定后
CAP-0502,5,Art,批准 PLAYER_MASTER_V1,P0,CAP-0501,四方向、色板、表情和不可变特征通过审查,todo,必须人工批准
CAP-0503,5,Animation,主角基础动画,P0,CAP-0502,四方向 idle/walk/interact 无形变漂移,todo,
CAP-0510,5,Art,环境与水岸套系,P0,CAP-0321,实际场景中比例、光向、透明边缘一致,todo,
CAP-0520,5,UI,UI 主组件板,P1,CAP-0206,中文英文和手柄焦点清楚,todo,
CAP-0530,5,Audio,垂直切片音频,P1,CAP-0422,核心动作均有反馈，许可证登记完整,todo,
CAP-0540,5,Playtest,外部试玩 10–20 人,P0,"CAP-0503,CAP-0510,CAP-0520,CAP-0530",80% 可完成并理解水体核心,todo,
CAP-0601,6,Content,完成家园区内容,P0,CAP-0540,区域内容无占位且主线可玩,todo,
CAP-0602,6,Content,完成果树林,P1,CAP-0601,区域有独特资源、NPC 与解锁作用,todo,
CAP-0603,6,Content,完成芦苇湿地,P1,CAP-0601,钓鱼与水生生态扩展有效,todo,
CAP-0604,6,Content,完成温泉山脚,P1,"CAP-0602,CAP-0603",主线阶段性结尾可完成,todo,
CAP-0610,6,Steam,Steamworks 抽象层,P1,CAP-0540,无 Steam 环境仍能运行，平台调用可禁用,todo,
CAP-0701,7,Steam,Steam Cloud,P0,"CAP-0610,CAP-0204",双设备冲突和旧存档迁移测试通过,todo,
CAP-0702,7,Steam,Steam Input 与手柄验证,P0,CAP-0610,核心流程无需鼠标,todo,
CAP-0703,7,Release,商店页与真实截图,P0,CAP-0540,文案与构建一致，无概念冒充实机,todo,
CAP-0704,7,Release,AI 内容与权利复核,P0,CAP-0703,manifest 完整，Steam 回答与实际一致,todo,
CAP-0705,7,Release,发布候选回归,P0,"CAP-0701,CAP-0702,CAP-0704",无 S0/S1，干净机器安装通过,todo,
```

---

# 附录 D：ASSET_MANIFEST.csv

```csv
﻿asset_id,display_name,category,sub_category,status,source_method,model_or_tool,prompt_id,reference_asset_ids,raw_path,source_path,game_path,width,height,alpha_required,license_or_rights,human_edits,reviewer,approved_date,ai_disclosure_required,notes
player_capybara_v1,原创水豚主角,character,player,brief,ai_assisted,,CHAR-CONCEPT-001,,,,,1024,1024,yes,original_project_asset,,,,yes,禁止使用未授权角色图作为参考
npc_otter_builder_v1,水獭木匠,character,npc,brief,ai_assisted,,NPC-CONCEPT-001,,,,,1024,1024,yes,original_project_asset,,,,yes,垂直切片主要 NPC
tile_water_set_v1,浅水与岸边地块,environment,tileset,brief,hybrid_ai_human,,TILE-WATER-001,,,,,64,64,varies,original_project_asset,,,,yes,需要人工制作 terrain 连接
```

---

# 附录 E：CONTENT_CATALOG.csv

```csv
﻿content_id,content_type,display_name_zh,display_name_en,name_key,description_key,unlock_condition,source_definition_path,status,notes
item_branch,item,树枝,Branch,ITEM_BRANCH_NAME,ITEM_BRANCH_DESC,start,,planned,基础资源
crop_leafy_green,crop,嫩叶菜,Tender Greens,CROP_LEAFY_NAME,CROP_LEAFY_DESC,tutorial_seed,,planned,垂直切片快速作物
fish_pond_minnow,fish,池塘小鱼,Pond Minnow,FISH_MINNOW_NAME,FISH_MINNOW_DESC,first_fishing,,planned,垂直切片普通鱼
npc_otter_builder,npc,待定,TBD,NPC_OTTER_NAME,NPC_OTTER_DESC,start_story,,planned,水獭木匠，正式名待定
build_wood_bench,buildable,木长凳,Wooden Bench,BUILD_BENCH_NAME,BUILD_BENCH_DESC,builder_request,,planned,贡献社交舒适标签
```
