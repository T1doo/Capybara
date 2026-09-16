# 给 Codex 的两条消息

> [!WARNING]
> **历史启动快照 / 已停用。** 这两条消息只用于最初 Stage 0 启动，当前不得再次发送。Stage 0 之后从 `CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md`、`AGENTS.md`、`PLANS.md` 和 `docs/AUTONOMOUS_STATUS.md` 恢复持续自治工作。

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
