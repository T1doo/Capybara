# Stage 0 — 开发日志

## 2026-09-16T15:35:34+08:00 · DOC-MIGRATE-stage-00 · 阶段记录迁移

- 来源类型：executed_now（仅文档迁移）；历史实现单独标为 historical_report。
- 受测基线：`79092c078c63c1e1d5a6d056ebcedf8401a9ac59` + 本次文档工作树改动；本条不声明游戏验证通过。
- 本轮交付：建立本阶段唯一 PLAN/LOG，保留原任务 ID、设计范围、证据和失败；[迁移映射](../stage-00-5/MIGRATION_MAP.csv)。
- 验证：本阶段原任务身份及依赖静态审查；统一检查与治理正负 fixture 由本批集成验证记录补充，不预写通过。
- Git：未提交的迁移工作树，最终 SHA 由后续检查点记录，避免自引用。
- 下一动作：见 [PLAN](PLAN.md#下一批执行顺序)。

## historical-records

来源类型：historical_report。来源基准 `79092c078c63c1e1d5a6d056ebcedf8401a9ac59`；旧本地实现 SHA 仅本地审计，不保证远程可达。历史原始日志/截图在被忽略的 build 中，本次未逐项验证可取性；原日期保留，旧条目未提供精确时刻/时区者记为未知。以下记录只描述当时覆盖范围，不作为新 HEAD、GPU/硬件或 RC1 通过证明。失败与修正均保留。

## 2026-08-30 — 阶段 0 工程初始化

Added
- 创建 Godot 4.7.2 Standard / GDScript / Compatibility 项目与 1280×720 可调整窗口配置。
- 创建灰盒主场景、基础地面、世界边界、纯 Godot 几何占位玩家和 Camera2D 跟随。
- 创建 WASD、方向键、手柄左摇杆/十字键移动，以及 Escape/手柄 Start 暂停输入。
- 创建暂停、继续、退出到桌面和 `Prototype / Phase 0` 界面，并加入最小中英文本地化资源。
- 创建零第三方依赖测试入口，覆盖移动数学、真实场景移动、最后方向、边界碰撞、暂停和默认焦点。
- 创建 `tools/check_project.ps1`、`tools/run_editor.ps1` 和 `tools/run_game.ps1`。

Changed
- 阶段 0 的输入动作由统一的 `InputSetup` 注册，同时登记物理键与逻辑键。

Fixed
- 暂停监听改为在 GUI 消费取消输入前处理，并兼容逻辑 Escape 与物理 Escape 事件。

Known Issues
- 实体手柄尚需项目负责人按 QA 步骤手工复核；自动测试已覆盖手柄事件注册所依赖的输入路径。

- 历史检查表：Godot 版本、导入、测试；`tools/check_project.ps1`；0；Godot `4.7.2.stable.official.ed1daf0bf`；Stage 1 最终 `168/168` 通过

- 历史检查表：主场景烟雾；`& $env:GODOT_BIN --headless --path game --quit-after 10`；0；无错误输出

- 历史检查表：Git 空白检查；`git diff --cached --check`；0；Stage 0 暂存内容通过

- 历史检查表：凭据模式扫描；Stage 0 文件范围 `rg` 扫描；0；无凭据赋值或私钥头命中

- 历史检查表：窗口视觉复核；当前 `Capybara (DEBUG)`；不适用；灰盒、阶段标识、暂停、焦点导航和退出通过

- 历史任务 `CAP-0001`：原状态 `done`，原阶段 `0`；已验证 4.7.2 stable official。

- 历史任务 `CAP-0002`：原状态 `done`，原阶段 `0`；沿用已批准基线；无需修改 ignore 或 LFS 规则。

- 历史任务 `CAP-0003`：原状态 `done`，原阶段 `0`；headless 导入与主场景冒烟通过。

- 历史任务 `CAP-0004`：原状态 `done`，原阶段 `0`；自动测试覆盖移动归一化、真实场景移动与边界。

- 历史任务 `CAP-0005`：原状态 `done`，原阶段 `0`；键盘窗口实测通过；实体手柄需手工复核。

- 历史任务 `CAP-0006`：原状态 `done`，原阶段 `0`；零依赖测试与检查脚本实际通过。

- 历史决定：DEC-002；2026-08-30；使用 Godot 4.7.2 Standard + GDScript；适合 2D、轻量、无引擎版税、便于 Codex 操作；固定版本，不自动升级；Accepted

- 历史决定：DEC-005；2026-08-30；v1.0 无战斗、无联机、无运行时 AI；控制首作范围和发布风险；不建立网络与敌人架构；Accepted

- 历史决定：DEC-007；2026-08-30；游戏运行时不调用生成式 AI；降低成本、审核、隐私和稳定性风险；AI 只做预生成内容；Accepted

- 历史决定：DEC-009；2026-08-30；阶段 0 通过统一的 `InputSetup` 注册物理键、逻辑键和基础手柄事件；同时支持真实键盘、不同键盘布局、自动化输入与后续重映射扩展；阶段 1/2 可在保留动作 ID 的前提下扩展输入提示与重映射；Accepted
