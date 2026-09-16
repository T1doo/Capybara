# 从这里开始：E:\Capybara 定制版

> [!WARNING]
> **历史启动快照 / 已停用。** 本文件只描述 2026-08-30 的原始解压启动流程，不再是当前执行入口。Stage 0 之后必须从 `CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md`、`AGENTS.md`、`PLANS.md` 和 `docs/AUTONOMOUS_STATUS.md` 恢复；旧的逐 Stage 人工批准、禁止自治 Git 和 `E:\Tools\Godot` 示例全部作废。

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
