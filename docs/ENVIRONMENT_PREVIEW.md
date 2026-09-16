# 家园环境预览

这是 Stage 3 独立技术预览，包含当前主屋、木桥、水车和环境效果；玩家、植物、菜地和码头仍有占位表现，不代表正式美术验收。

## 启动与试玩

在项目根目录运行：

```powershell
pwsh -NoProfile -File .\tools\run_game.ps1 -VisualPreview
```

脚本只从 `GODOT_BIN` 调用引擎，不创建第二份工程。不传开关仍打开生产灰盒主场景。

1. 用 WASD、方向键或左摇杆走动，经过木桥到达水车旁。
2. Esc / Start 暂停：玩家和水车应同时停止，焦点落在“继续”。
3. 方向键或十字键选择“设置”，Enter / A 进入；可继续进入按键设置，Esc 逐层返回，不直接解除暂停。
4. 开启“减少动态效果”并应用；状态提示“仅本次运行生效”。返回场景后玩家可走动，水车、水纹与微粒维持减少动态效果。
5. 选择“继续”或按 Esc / Start 恢复；鼠标也能操作按钮。退出后重开应使用原持久设置。

预览不显示保存和加载，而且两个处理函数在访问正式存档服务前直接返回。设置仍走正式 SettingsService 消费链，但跳过持久化；不会覆盖生产设置和存档。

## 检查证据

- 自动回归：`home_visual_preview_test_cases.gd` 从 `run_all.gd` 的环境测试链调用；真实注入键鼠/手柄事件，跨物理帧检查冻结与恢复，并比较正式设置及主存档文件哈希。
- 首轮回归真实失败：8/728，独立复现确定 `ui_accept` 无手柄事件；补齐公共 UI 映射后保留原断言重新验证。
- 独立复审提出设备编号风险，设备 1 实际复现不响应；默认手柄事件改为 `device=-1` 后设备 1 流程通过。鼠标补测曾失败，统一门 `20260912T055643928Z-p31912-88350230` 为 1/730；原因是测试把视口坐标传入窗口坐标接口，改为明确视口坐标的真实 GUI 事件注入后通过，没有跳过按钮路由。
- `visual_preview_ui_fixture.gd`：真实 Compatibility/NVIDIA 窗口验证相同事件链并保存五张截图至 `build/art-pipeline/preview_ui_review/`。中文全页可读，英文 1280×800 / 150% 时焦点把末端按钮滚入可见区。
- 独立代码审查：共享组件默认开关、调用边界、场景依赖和烟测未发现新增 High/Medium。最终统一检查编号与计数见 `AUTONOMOUS_STATUS.md`。
- 这里的手柄事件为合成输入，不是实体硬件测试；QA-001 保持开放。

GPU 复核命令：

```powershell
& $env:GODOT_BIN --path game --rendering-method gl_compatibility --resolution 1280x720 --script res://tests/visual_preview_ui_fixture.gd
```
