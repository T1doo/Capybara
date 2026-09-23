[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-p' + $PID
$fixtureRoot = Join-Path $repositoryRoot "build/governance-fixtures/$runId"
$checker = Join-Path $PSScriptRoot 'check_governance.ps1'
$results = [System.Collections.Generic.List[object]]::new()
$stageDirectories = @('stage-00', 'stage-00-5') + @(1..12 | ForEach-Object { 'stage-{0:D2}' -f $_ })
$stageIds = @('0', '0.5') + @(1..12 | ForEach-Object { [string]$_ })

function Write-FixtureFile {
    param([string]$Root, [string]$RelativePath, [string]$Text)
    $path = Join-Path $Root $RelativePath
    $null = New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force
    [IO.File]::WriteAllText($path, $Text.Replace("`r`n", "`n"), [Text.UTF8Encoding]::new($false))
}

function New-Fixture {
    param([string]$Name)
    $root = Join-Path $fixtureRoot $Name
    # Only minimal documents/config stubs are built; no game tree, assets, or Git history is copied.
    $files = @(
        'README.md', 'AGENTS.md', 'CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md',
        'docs/ISSUES.md', 'docs/QUALITY_GATES.md', 'docs/RELEASE_READINESS.md',
        'docs/design/GAME_DESIGN.md', 'docs/design/TECHNICAL_DESIGN.md', 'docs/design/ART_BIBLE.md',
        'docs/design/CONTENT_CATALOG.csv', 'docs/production/ASSET_PIPELINE.md',
        'docs/production/RIGHTS_AND_AI_POLICY.md', 'docs/production/DEPENDENCIES.md',
        'docs/production/ASSET_MANIFEST.csv', '.github/workflows/ci.yml', 'game/export_presets.cfg',
        'tools/build_smoke.ps1', 'tools/check_governance.ps1', 'tools/test_governance.ps1',
        'tools/check_project.ps1', 'tools/check_format.ps1', 'tools/check_art_assets.ps1',
        'tools/validate_png_assets.ps1', 'tools/make_contact_sheet.ps1', 'tools/make_alpha_review_sheet.ps1',
        'tools/render_svg_preview.ps1', 'tools/check_svg_cutout_alpha.ps1', 'tools/check_localization.ps1',
        'tools/check_settings_restart.ps1', 'tools/check_save_restart.ps1'
    )
    foreach ($file in $files) { Write-FixtureFile $root $file "# Minimal governance fixture`n" }
    Write-FixtureFile $root 'AGENTS.md' 'Read CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md and the current stage plan.'
    Write-FixtureFile $root 'docs/RELEASE_READINESS.md' 'capybara-rc1 remains unverified.'
    Write-FixtureFile $root 'docs/production/DEPENDENCIES.md' 'Godot 4.7.2-stable remains pinned.'
    Write-FixtureFile $root 'docs/STATUS.md' @'
# Fixture status
- safe_branch: codex/production-clean-20260916
- review_baseline: 79092c078c63c1e1d5a6d056ebcedf8401a9ac59
禁止 force push。旧 codex/autonomous-v1 仅本地审计，不能 merge 回安全线。
'@
    $indexLines = @('# Stage index')
    for ($index = 0; $index -lt $stageDirectories.Count; $index++) {
        $directory = $stageDirectories[$index]
        $id = $stageIds[$index]
        $taskId = 'FIX-{0:D2}' -f $index
        $dependency = if ($index -gt 0) { 'FIX-{0:D2}' -f ($index - 1) } else { '-' }
        $stageStatus = if ($index -eq 0) { 'historical_passed' } else { 'not_started' }
        $taskStatus = if ($index -eq 0) { 'done' } else { 'todo' }
        $evidence = if ($index -eq 0) { 'historical_report: [历史日志](LOG.md#historical-records)' } else { '-' }
        $plan = @"
# Stage $id

- stage_id: "$id"
- status: $stageStatus
- evidence: $evidence

| ID | 交付任务 | 优先级 | 依赖 ID | 验收与证据要求 | 状态 | 证据 |
|---|---|---|---|---|---|---|
| $taskId | Observable stage capability | P1 | $dependency | Verify delivered capability and persisted result | $taskStatus | $evidence |
"@
        Write-FixtureFile $root "docs/stages/$directory/PLAN.md" $plan
        Write-FixtureFile $root "docs/stages/$directory/LOG.md" @'
# Stage log

## historical-records

Historical report / 历史范围: source commit 79092c078c63c1e1d5a6d056ebcedf8401a9ac59.
This minimal fixture models a recorded verification result, not a real project run.
'@
        $indexLines += "[Stage $id](docs/stages/$directory/PLAN.md)"
    }
    Write-FixtureFile $root 'PLANS.md' ($indexLines -join "`n")
    Write-FixtureFile $root 'docs/README.md' (($indexLines -join "`n").Replace('(docs/stages/', '(stages/'))
    return $root
}

function Edit-FixtureFile {
    param([string]$Root, [string]$RelativePath, [string]$Old, [string]$New)
    $path = Join-Path $Root $RelativePath
    $text = Get-Content -LiteralPath $path -Raw
    if (-not $text.Contains($Old)) { throw "Fixture setup did not find expected text in $RelativePath" }
    Write-FixtureFile $Root $RelativePath ($text.Replace($Old, $New))
}

function Invoke-Fixture {
    param([string]$Name, [scriptblock]$Mutation, [string]$ExpectedFailure = '')
    $root = New-Fixture $Name
    if ($Mutation) { & $Mutation $root }
    $start = [Diagnostics.ProcessStartInfo]::new()
    $start.FileName = (Get-Process -Id $PID).Path
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    foreach ($argument in @('-NoProfile', '-File', $checker, '-RepositoryRoot', $root, '-DocumentFixture')) { $start.ArgumentList.Add($argument) }
    $process = [Diagnostics.Process]::Start($start)
    $outputTask = $process.StandardOutput.ReadToEndAsync()
    $errorTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(30000)) { $process.Kill($true); throw "Governance fixture timed out: $Name" }
    $output = $outputTask.GetAwaiter().GetResult() + $errorTask.GetAwaiter().GetResult()
    $exitCode = $process.ExitCode
    $process.Dispose()
    $passed = if ($ExpectedFailure) { $exitCode -eq 10 -and $output.Contains($ExpectedFailure) } else { $exitCode -eq 0 }
    $results.Add([pscustomobject]@{ name = $Name; passed = $passed; exit_code = $exitCode; expected_failure = $ExpectedFailure; output = $output })
    if (-not $passed) { [Console]::Error.WriteLine("[governance-fixture] FAIL $Name exit=$exitCode`n$output") }
}

Invoke-Fixture 'valid-historical-completion' $null
Invoke-Fixture 'valid-stage-promotion' {
    param($root)
    Edit-FixtureFile $root 'docs/stages/stage-00/PLAN.md' 'historical_passed' 'passed'
    Edit-FixtureFile $root 'docs/stages/stage-00/PLAN.md' 'historical_report: ' ''
}
Invoke-Fixture 'valid-retired-historical-reference' {
    param($root)
    Write-FixtureFile $root 'docs/design/GAME_DESIGN.md' '历史引用 docs/old-design.md at 79092c078c63c1e1d5a6d056ebcedf8401a9ac59; this is not an active recovery path.'
}
Invoke-Fixture 'missing-plan' {
    param($root)
    Remove-Item -LiteralPath (Join-Path $root 'docs/stages/stage-03/PLAN.md')
} 'Missing required file: docs/stages/stage-03/PLAN.md'
Invoke-Fixture 'missing-log' {
    param($root)
    Remove-Item -LiteralPath (Join-Path $root 'docs/stages/stage-03/LOG.md')
} 'Missing required file: docs/stages/stage-03/LOG.md'
Invoke-Fixture 'duplicate-task' {
    param($root)
    Edit-FixtureFile $root 'docs/stages/stage-03/PLAN.md' '| FIX-04 |' '| FIX-00 |'
} 'Duplicate task ID: FIX-00'
Invoke-Fixture 'missing-dependency' {
    param($root)
    Edit-FixtureFile $root 'docs/stages/stage-03/PLAN.md' '| FIX-03 |' '| FIX-999 |'
} 'Missing dependency FIX-999'
Invoke-Fixture 'dependency-cycle' {
    param($root)
    Edit-FixtureFile $root 'docs/stages/stage-00/PLAN.md' '| P1 | - |' '| P1 | FIX-01 |'
} 'dependency graph contains a cycle'
Invoke-Fixture 'forged-evidence' {
    param($root)
    Edit-FixtureFile $root 'docs/stages/stage-00/PLAN.md' '(LOG.md#historical-records)' '(missing-proof.json)'
} 'Missing evidence path'
Invoke-Fixture 'historical-without-source' {
    param($root)
    Write-FixtureFile $root 'docs/stages/stage-00/LOG.md' '# A historical claim with no source commit'
} 'Historical evidence lacks a source commit'
Invoke-Fixture 'empty-acceptance' {
    param($root)
    Edit-FixtureFile $root 'docs/stages/stage-03/PLAN.md' 'Verify delivered capability and persisted result' '-'
} 'Empty Acceptance'
Invoke-Fixture 'wrong-stage-0-5' {
    param($root)
    Edit-FixtureFile $root 'docs/stages/stage-00-5/PLAN.md' 'stage_id: "0.5"' 'stage_id: "5"'
} 'Invalid semantic stage_id'
Invoke-Fixture 'stage-promotion-with-open-task' {
    param($root)
    Edit-FixtureFile $root 'docs/stages/stage-00/PLAN.md' 'historical_passed' 'passed'
    Edit-FixtureFile $root 'docs/stages/stage-00/PLAN.md' '| done |' '| todo |'
} 'contains unfinished task'
Invoke-Fixture 'stage-promotion-with-historical-only-evidence' {
    param($root)
    Edit-FixtureFile $root 'docs/stages/stage-00/PLAN.md' 'historical_passed' 'passed'
} 'Passed stage needs current verification'
Invoke-Fixture 'broken-active-link' {
    param($root)
    Write-FixtureFile $root 'docs/design/TECHNICAL_DESIGN.md' '[Recovery](../missing-recovery.md)'
} 'Broken active document link'
Invoke-Fixture 'stale-active-prose-reference' {
    param($root)
    Write-FixtureFile $root 'docs/design/TECHNICAL_DESIGN.md' 'Active recovery uses docs/old-recovery.md.'
} 'Stale active document reference'
Invoke-Fixture 'stale-runtime-reference' {
    param($root)
    Write-FixtureFile $root 'tools/example.ps1' "# Consumer of docs/old-document.md`n"
} 'Stale executable document reference'
Invoke-Fixture 'runtime-absolute-path' {
    param($root)
    Write-FixtureFile $root 'game/example.gd' ('const WRONG_PATH = "' + 'E:' + '\Capybara\game"')
} 'Absolute local path'
Invoke-Fixture 'runtime-unc-path' {
    param($root)
    Write-FixtureFile $root 'tools/example.ps1' 'Set-Location "\\server\share\folder"'
} 'Absolute local path'
Invoke-Fixture 'unsafe-status-branch' {
    param($root)
    Edit-FixtureFile $root 'docs/STATUS.md' 'safe_branch: codex/production-clean-20260916' 'safe_branch: codex/autonomous-v1'
} 'STATUS needs an explicit safe development branch'
Invoke-Fixture 'second-backlog' {
    param($root)
    Write-FixtureFile $root 'docs/BACKLOG.csv' 'id,status'
} 'A second editable task source remains'

$reportPath = Join-Path $fixtureRoot 'results.json'
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $reportPath -Encoding utf8
$logDirectory = Join-Path $repositoryRoot 'build/logs'
$null = New-Item -ItemType Directory -Path $logDirectory -Force
Copy-Item -LiteralPath $reportPath -Destination (Join-Path $logDirectory "governance-fixtures-$runId.json")
$failed = @($results | Where-Object { -not $_.passed })
if ($failed.Count -gt 0) { [Console]::Error.WriteLine("[governance-fixture] $($failed.Count)/$($results.Count) failed; $reportPath"); exit 10 }
[Console]::WriteLine("[governance-fixture] PASS: $($results.Count)/$($results.Count); $reportPath")
exit 0
