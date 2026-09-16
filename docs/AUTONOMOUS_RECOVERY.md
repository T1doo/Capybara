# 自治恢复、备份与回退

目标：任何上下文压缩、应用重启、机器重启、方案失败或远程不可用后，都能从可验证 Git 状态恢复，而不破坏用户数据。

## 1. 恢复顺序

```powershell
Set-Location -LiteralPath 'E:\Capybara'
Get-Content -LiteralPath 'CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md' -Raw
Get-Content -LiteralPath 'AGENTS.md' -Raw
Get-Content -LiteralPath 'PLANS.md' -Raw
Get-Content -LiteralPath 'docs\AUTONOMOUS_STATUS.md' -Raw
git log -20 --oneline --decorate
git status --short --branch
pwsh -NoProfile -File .\tools\check_project.ps1
```

如果统一检查失败，当前分支视为未恢复完成；先修复或切到已知稳定 commit/tag 的新分支进行诊断。

## 2. 稳定点策略

- 每个可验证小批次创建原子 commit。
- 每个 Stage 通过后合并到 `main` 并创建注释标签。
- 当前稳定点：`803b90d` / `capybara-stage-00`。
- 大型或高风险改动开始前，先确保前一批次已 commit。
- 未提交的用户独有文件不得删除、覆盖或用 `git reset --hard` 丢弃。

## 3. 安全回退

### 放弃错误方向但保留历史

优先使用：

```powershell
git revert <bad-commit>
```

或从稳定标签创建诊断分支：

```powershell
git switch -c codex/recovery-<topic> capybara-stage-00
```

不得使用：

```text
git reset --hard
git push --force
git push --force-with-lease
```

### 恢复单个已跟踪文件

只有目标明确且确认不会覆盖用户独有修改时使用：

```powershell
git restore --source=<known-good-commit> --worktree -- <exact-path>
```

恢复前后都运行 `git status --short --branch` 和相关测试。

## 4. 远程不可用

- 继续在本地 `codex/autonomous-v1` 原子 commit。
- 在 `docs/AUTONOMOUS_STATUS.md` 记录未同步 commit、tags 和分支。
- 每个 Stage 最多进行一次安全同步尝试，避免反复触发认证失败。
- 认证恢复后先确认 `git remote -v`、仓库归属、可见性和非强制推送目标。

## 5. 构建与运行产物

- `build/`、`game/.godot/`、日志、缓存和导出文件不作为源码备份。
- 可复现来源是 commit、Stage tag、资产 manifest 和构建脚本。
- 当前 `.gitattributes` 尚未配置 Git LFS pattern；首次大型正式资产入库前，必须按实际格式最小追加规则并用 `git check-attr` 验证，不能假装已经受 LFS 保护。
- 未筛选 AI 原始候选保持忽略，manifest 记录生成批次和选择结果。

## 6. 故障记录

每次恢复或回退后更新：

- `docs/AUTONOMOUS_STATUS.md`：当前稳定点和下一任务。
- `docs/KNOWN_ISSUES.md`：原因、影响、修复和关闭证据。
- `docs/CHANGELOG.md`：玩家或开发流程可见的修复。
- 必要时更新 `docs/10_DECISION_LOG.md`，避免重复采用失败方案。
