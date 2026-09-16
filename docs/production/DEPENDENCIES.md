# 依赖与供应链记录

本文件记录运行时、开发期和 CI 依赖。新增依赖前必须说明用途、许可证、固定版本、安全/维护风险和零依赖替代方案。

## 当前结论

- 游戏运行时第三方插件：无。
- Godot 插件：无。
- 外部 SDK：无。
- 付费依赖：无。
- 开发引擎：Godot 4.7.2 Standard，MIT License，通过 `GODOT_BIN` 调用，不进入仓库。
- 自动化宿主：PowerShell 7 或更高版本；统一检查为避免 Windows PowerShell 5.1 原生 stderr 语义差异而明确拒绝旧宿主。
- 美术技术处理：使用 PowerShell 7 运行时已提供的 Windows/.NET `System.Drawing` 读取 PNG 像素与生成联系表；不增加 Python/Pillow、插件或项目运行时依赖。
- Blender：2026-09-16已按本次授权安全安装官方4.5.13 LTS便携版（build daeeeca98fb0）到D:\GameDev\Blender；ZIP 398648740字节，SHA-256 `b5fdf800ce65fa2f209e8f68d02667e4d720fa1c42f247c72d1882ab04decba6`与现场读取的官方文件一致。包内copyright.txt及license/列出GPL及第三方许可；仅开发期，不随游戏分发。背景版本启动退出0，动画A/B仍未完成。历史下载拒绝保留在Stage3 LOG。

## CI 依赖

| 依赖 | 固定版本 | 来源 | 用途 | 许可证/归属 | 风险控制 |
|---|---|---|---|---|---|
| Godot Standard Windows | `4.7.2-stable` | `godotengine/godot-builds` 官方 release | 导入、测试、主场景烟雾 | Godot Engine，MIT | 固定 release tag；运行时再次验证 `4.7.2.stable.official.*`；不缓存到仓库 |
| Godot Export Templates | `4.7.2-stable` | `godotengine/godot-builds` 官方 release | Windows debug 导出烟雾 | Godot Engine，MIT | 固定 release tag 和 SHA256；仅安装到 CI runner 用户目录 |
| `actions/checkout` | `11bd71901bbe5b1630ceea73d27597364c9af683`（v4.2.2） | GitHub 官方 action | 检出仓库 | GitHub，MIT | 固定 commit SHA；`contents: read` 最小权限 |
| `actions/upload-artifact` | `ea165f8d65b6e75b540449e92b4886f43607fa02`（v4.6.2） | GitHub 官方 action | 保存忽略的检查日志 | GitHub，MIT | 固定 commit SHA；仅上传 `build/logs/` |

CI runner 固定为 `windows-2022`，避免 `windows-latest` 切换宿主世代造成 PowerShell、Git 或系统组件漂移。

## 待恢复开发工具

| 工具 | 候选版本 | 官方来源 | 用途 | 当前状态 |
|---|---|---|---|---|
| Blender Portable | 4.5.13 LTS | `https://download.blender.org/release/Blender4.5/blender-4.5.13-windows-x64.zip` | Stage 3 正交预渲染与 cutout 对比 | 已安装且背景版本验证通过；详细证据见Stage3 LOG的STAGE3-TOOLS-01，角色方案尚未比较 |

Godot CI 下载地址：

```text
https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_win64.exe.zip
```

2026-08-30 已用只读 HTTP HEAD 验证该地址返回最终 `200 OK`，内容类型为 `application/octet-stream`，文件名与锁定版本一致。

官方 GitHub release API 返回并用于 CI 的 SHA256：

```text
Godot_v4.7.2-stable_win64.exe.zip
731980f9608d61333e5baf54a2ef17210acc7a538446c0cb9969f002aca1e953

Godot_v4.7.2-stable_export_templates.tpz
f298490b8d44d934be425a5a65a51bf15f422428b229a06a6e11d9ffea248011
```

## 新依赖审查模板

```text
名称：
用途：
候选版本/commit：
来源与维护者：
许可证：
运行时或开发期：
安全风险：
维护/弃用风险：
体积和性能影响：
零依赖替代方案：
回退方式：
决定与批准证据：
```

## PowerShell 运行要求

统一检查使用：

```powershell
pwsh -NoProfile -File .\tools\check_project.ps1
```

若 `pwsh` 不存在，当前机器缺少 Stage 0.5 自动化宿主；不要改用 Windows PowerShell 5.1 制造不一致结果。应从 Microsoft 官方渠道安装 PowerShell 7 到 `D:\GameDev` 或系统已批准位置，或在已有 Codex PowerShell 7 环境中执行；不得从未知来源下载。
