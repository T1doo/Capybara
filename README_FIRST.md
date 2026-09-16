# Capybara 项目：先读这里

> [!WARNING]
> **历史启动快照 / 已停用。** 当前恢复入口是 `CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md`、`AGENTS.md`、`PLANS.md` 和 `docs/AUTONOMOUS_STATUS.md`。本文件以下“阶段完成后停下等待批准”等说明仅用于原始启动包历史，不再约束 Stage 0 后自治执行。

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
