[CmdletBinding()]
param(
    [ValidateRange(10, 1800)]
    [int]$DefaultTimeoutSeconds = 180
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Console]::Error.WriteLine('[check] PowerShell 7 or newer is required for deterministic native-process capture.')
    exit 13
}

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$gameRoot = Join-Path $repositoryRoot 'game'
$projectFile = Join-Path $gameRoot 'project.godot'
$governanceScript = Join-Path $PSScriptRoot 'check_governance.ps1'
$formatScript = Join-Path $PSScriptRoot 'check_format.ps1'
$artAssetsScript = Join-Path $PSScriptRoot 'check_art_assets.ps1'
$materialAssetsScript = Join-Path $PSScriptRoot 'check_material_assets.ps1'
$svgRenderScript = Join-Path $PSScriptRoot 'render_svg_preview.ps1'
$svgAlphaReviewScript = Join-Path $PSScriptRoot 'check_svg_cutout_alpha.ps1'
$localizationScript = Join-Path $PSScriptRoot 'check_localization.ps1'
$settingsRestartScript = Join-Path $PSScriptRoot 'check_settings_restart.ps1'
$saveRestartScript = Join-Path $PSScriptRoot 'check_save_restart.ps1'
$buildSmokeScript = Join-Path $PSScriptRoot 'build_smoke.ps1'
$godotBin = $env:GODOT_BIN
$logDirectory = Join-Path $repositoryRoot 'build\logs'
$runId = '{0}-p{1}-{2}' -f (
    [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'),
    $PID,
    [Guid]::NewGuid().ToString('N').Substring(0, 8)
)
$textLogPath = Join-Path $logDirectory "check_project-$runId.log"
$jsonLogPath = Join-Path $logDirectory "check_project-$runId.json"
$latestTextLogPath = Join-Path $logDirectory 'check_project-latest.log'
$latestJsonLogPath = Join-Path $logDirectory 'check_project-latest.json'
$latestRunPath = Join-Path $logDirectory 'check_project-latest-run.txt'
$steps = [System.Collections.Generic.List[object]]::new()
$startedAtUtc = [DateTime]::UtcNow
$overallExitCode = 0
$requiredChecksSatisfied = $true
$currentStep = $null
$failure = $null
$lastStandardOutput = ''
$sourceBefore = $null
$sourceAfter = $null

New-Item -ItemType Directory -Force -Path $logDirectory | Out-Null
Set-Content -LiteralPath $textLogPath -Value "[check] RUN $runId" -Encoding utf8

function Get-SourceEvidence {
    $sourceCommit = (& git -C $repositoryRoot rev-parse HEAD 2>$null).Trim()
    if ($LASTEXITCODE -ne 0) { throw 'Unable to capture source commit.' }
    $sourceDiff = (& git -C $repositoryRoot diff HEAD --no-ext-diff --binary 2>$null) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to capture source diff.' }
    $untrackedRaw = (& git -C $repositoryRoot ls-files -z --others --exclude-standard) -join "`n"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to capture untracked source paths.' }
    $untrackedPaths = @($untrackedRaw -split "`0" | Where-Object { $_.Length -gt 0 })
    $untrackedHashes = @($untrackedPaths | Sort-Object | ForEach-Object {
        $hash = (Get-FileHash -LiteralPath (Join-Path $repositoryRoot $_) -Algorithm SHA256).Hash
        "$_ $hash"
    })
    $bytes = [Text.Encoding]::UTF8.GetBytes($sourceCommit + "`n" + $sourceDiff + "`n" + ($untrackedHashes -join "`n"))
    return [ordered]@{
        commit = $sourceCommit
        dirty = ($sourceDiff.Length -gt 0 -or $untrackedPaths.Count -gt 0)
        fingerprint_sha256 = [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($bytes)).ToLowerInvariant()
        untracked_count = $untrackedPaths.Count
    }
}

function Write-CheckLine {
    param([Parameter(Mandatory = $true)][string]$Message)

    [Console]::WriteLine($Message)
    Add-Content -LiteralPath $textLogPath -Value $Message -Encoding utf8
}

function Invoke-RecordedCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [int]$TimeoutSeconds = $DefaultTimeoutSeconds,
        [switch]$FailOnDiagnostics
    )

    $script:currentStep = $Name
    $step = [pscustomobject]@{
        name = $Name
        status = 'running'
        exit_code = $null
        native_exit_code = $null
        diagnostic_count = 0
        timed_out = $false
        timeout_seconds = $TimeoutSeconds
        duration_ms = 0
        failure_message = $null
    }
    $steps.Add($step)
    Write-CheckLine "[check] START $Name timeout_seconds=$TimeoutSeconds"
    $stepStartedAtUtc = [DateTime]::UtcNow

    $startInfo = [Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $FilePath
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $Arguments) {
        $startInfo.ArgumentList.Add($argument)
    }

    $process = [Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    try {
        if (-not $process.Start()) {
            throw "Failed to start process for step '$Name'."
        }
        $standardOutputTask = $process.StandardOutput.ReadToEndAsync()
        $standardErrorTask = $process.StandardError.ReadToEndAsync()
        $completed = $process.WaitForExit($TimeoutSeconds * 1000)
        if (-not $completed) {
            $step.timed_out = $true
            try {
                $process.Kill($true)
            }
            catch {
                $process.Kill()
            }
            $process.WaitForExit()
        }

        $standardOutput = $standardOutputTask.GetAwaiter().GetResult()
        $standardError = $standardErrorTask.GetAwaiter().GetResult()
        $script:lastStandardOutput = $standardOutput
        $standardOutputLines = @($standardOutput -split '\r?\n' | Where-Object { $_.Length -gt 0 })
        $standardErrorLines = @($standardError -split '\r?\n' | Where-Object { $_.Length -gt 0 })
        foreach ($line in @($standardOutputLines + $standardErrorLines)) {
            Write-CheckLine $line
        }

        $nativeExitCode = if ($step.timed_out) { 124 } else { $process.ExitCode }
        $diagnostics = @()
        if ($FailOnDiagnostics) {
            $diagnostics = @($standardOutputLines + $standardErrorLines | Where-Object {
                $_ -match '(?i)^\s*(SCRIPT ERROR|ERROR|WARNING):'
            })
        }
        $effectiveExitCode = $nativeExitCode
        if ($effectiveExitCode -eq 0 -and $diagnostics.Count -gt 0) {
            $effectiveExitCode = 20
        }

        $step.native_exit_code = $nativeExitCode
        $step.exit_code = $effectiveExitCode
        $step.diagnostic_count = $diagnostics.Count
        $step.duration_ms = [int]([DateTime]::UtcNow - $stepStartedAtUtc).TotalMilliseconds
        $step.status = if ($effectiveExitCode -eq 0) { 'passed' } else { 'failed' }
        if ($effectiveExitCode -ne 0) {
            $step.failure_message = "native=$nativeExitCode diagnostics=$($diagnostics.Count) timed_out=$($step.timed_out)"
        }
        Write-CheckLine "[check] END $Name status=$($step.status) exit=$effectiveExitCode native_exit=$nativeExitCode diagnostics=$($diagnostics.Count) timed_out=$($step.timed_out) duration_ms=$($step.duration_ms)"

        if ($effectiveExitCode -ne 0) {
            throw "Step '$Name' failed with exit code $effectiveExitCode."
        }
    }
    catch {
        $step.status = 'failed'
        if ($null -eq $step.exit_code) {
            $step.exit_code = 1
        }
        if ($null -eq $step.native_exit_code) {
            $step.native_exit_code = 1
        }
        $step.duration_ms = [int]([DateTime]::UtcNow - $stepStartedAtUtc).TotalMilliseconds
        if ([string]::IsNullOrWhiteSpace($step.failure_message)) {
            $step.failure_message = $_.Exception.Message
        }
        throw
    }
    finally {
        $process.Dispose()
    }
}

try {
    $sourceBefore = Get-SourceEvidence
    if ([string]::IsNullOrWhiteSpace($godotBin)) {
        throw 'GODOT_BIN is not set.'
    }
    if (-not (Test-Path -LiteralPath $godotBin -PathType Leaf)) {
        throw 'GODOT_BIN does not point to an existing file.'
    }
    if (-not (Test-Path -LiteralPath $projectFile -PathType Leaf)) {
        throw 'game/project.godot is missing.'
    }
    foreach ($requiredScript in @(
        $governanceScript,
        $formatScript,
        $artAssetsScript,
        $svgRenderScript,
        $svgAlphaReviewScript,
        $localizationScript,
        $settingsRestartScript,
        $saveRestartScript,
        $buildSmokeScript
    )) {
        if (-not (Test-Path -LiteralPath $requiredScript -PathType Leaf)) {
            throw "Required check script is missing: $([IO.Path]::GetFileName($requiredScript))"
        }
    }

    $powerShellBin = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    Invoke-RecordedCommand 'governance' $powerShellBin @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $governanceScript
    ) -TimeoutSeconds 30
    Invoke-RecordedCommand 'repository_format' $powerShellBin @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $formatScript
    ) -TimeoutSeconds 30
    Invoke-RecordedCommand 'art_asset_pipeline' $powerShellBin @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $artAssetsScript
    ) -TimeoutSeconds 60
    Invoke-RecordedCommand 'godot_version' $godotBin @('--version') -TimeoutSeconds 30
    $versionOutput = ($lastStandardOutput -split '\r?\n' | Where-Object { $_.Length -gt 0 } | Select-Object -First 1).Trim()
    $expectedVersion = '4.7.2.stable.official.ed1daf0bf'
    if ($versionOutput -ne $expectedVersion) {
        throw "Expected Godot '$expectedVersion', got '$versionOutput'."
    }
    ($steps | Where-Object { $_.name -eq 'godot_version' } | Select-Object -Last 1) |
        Add-Member -NotePropertyName version -NotePropertyValue $versionOutput

    Invoke-RecordedCommand 'godot_import' $godotBin @(
        '--headless', '--path', $gameRoot, '--import'
    ) -TimeoutSeconds 180 -FailOnDiagnostics
    Invoke-RecordedCommand 'svg_cutout_render' $powerShellBin @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $svgRenderScript
    ) -TimeoutSeconds 60 -FailOnDiagnostics
    Invoke-RecordedCommand 'painted_material_assets' $powerShellBin @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $materialAssetsScript
    ) -TimeoutSeconds 60
    Invoke-RecordedCommand 'svg_cutout_alpha_review' $powerShellBin @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $svgAlphaReviewScript
    ) -TimeoutSeconds 60
    Invoke-RecordedCommand 'localization_integrity' $powerShellBin @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $localizationScript
    ) -TimeoutSeconds 30
    Invoke-RecordedCommand 'settings_process_restart' $powerShellBin @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $settingsRestartScript
    ) -TimeoutSeconds 60 -FailOnDiagnostics
    Invoke-RecordedCommand 'save_process_restart' $powerShellBin @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $saveRestartScript
    ) -TimeoutSeconds 60 -FailOnDiagnostics
    Invoke-RecordedCommand 'automated_tests' $godotBin @(
        '--headless', '--path', $gameRoot, '--script', 'res://tests/run_all.gd'
    ) -TimeoutSeconds 120 -FailOnDiagnostics
    if ($lastStandardOutput -notmatch 'CAPYBARA TESTS PASSED: [1-9][0-9]*/[1-9][0-9]*') {
        throw 'Automated tests exited successfully without the required non-zero test pass marker.'
    }
    Invoke-RecordedCommand 'save_runtime_transaction' $godotBin @(
        '--headless', '--path', $gameRoot, '--script', 'res://tests/save_transaction_fixture.gd'
    ) -TimeoutSeconds 120 -FailOnDiagnostics
    Invoke-RecordedCommand 'main_scene_smoke' $godotBin @(
        '--headless', '--path', $gameRoot, '--quit-after', '10'
    ) -TimeoutSeconds 60 -FailOnDiagnostics
    Invoke-RecordedCommand 'home_visual_blockout_smoke' $godotBin @(
        '--headless', '--path', $gameRoot, '--quit-after', '10',
        'res://scenes/visual_prototypes/home_visual_blockout.tscn'
    ) -TimeoutSeconds 60 -FailOnDiagnostics

    Invoke-RecordedCommand 'home_visual_preview_smoke' $godotBin @(
        '--headless', '--path', $gameRoot, '--quit-after', '10',
        'res://scenes/visual_prototypes/home_visual_preview.tscn'
    ) -TimeoutSeconds 60 -FailOnDiagnostics

    $debugExportTemplate = Join-Path $env:APPDATA 'Godot\export_templates\4.7.2.stable\windows_debug_x86_64.exe'
    if (Test-Path -LiteralPath $debugExportTemplate -PathType Leaf) {
        Invoke-RecordedCommand 'windows_build_smoke' $powerShellBin @(
            '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $buildSmokeScript
        ) -TimeoutSeconds 300 -FailOnDiagnostics
    }
    else {
        $currentStep = 'windows_build_smoke'
        if ($env:REQUIRE_WINDOWS_BUILD_SMOKE -eq '1') {
            throw 'Windows build smoke is required, but Godot 4.7.2 export templates are missing.'
        }
        $requiredChecksSatisfied = $false
        $steps.Add([pscustomobject]@{
            name = 'windows_build_smoke'
            status = 'skipped'
            exit_code = 0
            native_exit_code = $null
            diagnostic_count = 0
            timed_out = $false
            timeout_seconds = 300
            duration_ms = 0
            failure_message = $null
            reason = 'Godot 4.7.2 Windows export templates are not installed on this machine.'
        })
        Write-CheckLine '[check] SKIP windows_build_smoke: Godot 4.7.2 Windows export templates are not installed.'
    }

    Invoke-RecordedCommand 'git_worktree_diff_check' 'git' @(
        '-C', $repositoryRoot, 'diff', '--check'
    ) -TimeoutSeconds 30
    Invoke-RecordedCommand 'git_cached_diff_check' 'git' @(
        '-C', $repositoryRoot, 'diff', '--cached', '--check'
    ) -TimeoutSeconds 30
    $sourceAfter = Get-SourceEvidence
    if ($sourceBefore.fingerprint_sha256 -ne $sourceAfter.fingerprint_sha256) {
        $currentStep = 'source_stability'
        throw 'Source changed during checks; rerun after the batch is stable.'
    }
    if ($requiredChecksSatisfied) {
        Write-CheckLine '[check] PASS required_checks_satisfied=true'
    }
    else {
        Write-CheckLine '[check] PASS required_checks_satisfied=false (Windows build smoke skipped)'
    }
}
catch {
    $overallExitCode = 1
    $failure = [ordered]@{
        step = $currentStep
        exception_type = $_.Exception.GetType().FullName
        message = $_.Exception.Message
    }
    $failureMessage = "[check] FAIL: $($_.Exception.Message)"
    [Console]::Error.WriteLine($failureMessage)
    Add-Content -LiteralPath $textLogPath -Value $failureMessage -Encoding utf8
}
finally {
    $finishedAtUtc = [DateTime]::UtcNow
    $branch = (& git -C $repositoryRoot branch --show-current 2>$null).Trim()
    $commit = (& git -C $repositoryRoot rev-parse HEAD 2>$null).Trim()
    $gitVersion = (& git --version 2>$null).Trim()
    $summary = [ordered]@{
        schema_version = 3
        run_id = $runId
        success = ($overallExitCode -eq 0)
        required_checks_satisfied = ($overallExitCode -eq 0 -and $requiredChecksSatisfied)
        exit_code = $overallExitCode
        started_at_utc = $startedAtUtc.ToString('o')
        finished_at_utc = $finishedAtUtc.ToString('o')
        duration_ms = [int]($finishedAtUtc - $startedAtUtc).TotalMilliseconds
        branch = $branch
        commit = $commit
        source_commit = if ($null -ne $sourceBefore) { $sourceBefore.commit } else { $null }
        source_before = $sourceBefore
        source_after = $sourceAfter
        execution_mode = 'headless'
        build_configuration = 'Debug'
        host = [ordered]@{
            os = [Runtime.InteropServices.RuntimeInformation]::OSDescription
            powershell_version = $PSVersionTable.PSVersion.ToString()
            powershell_edition = $PSVersionTable.PSEdition
            git_version = $gitVersion
        }
        godot_executable = if ([string]::IsNullOrWhiteSpace($godotBin)) { $null } else { [IO.Path]::GetFileName($godotBin) }
        failure = $failure
        steps = @($steps)
    }
    $temporaryJsonPath = "$jsonLogPath.tmp"
    $summary | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath $temporaryJsonPath -Encoding utf8
    Move-Item -LiteralPath $temporaryJsonPath -Destination $jsonLogPath -Force
    Write-CheckLine "[check] Results: build/logs/$([IO.Path]::GetFileName($textLogPath)), build/logs/$([IO.Path]::GetFileName($jsonLogPath))"

    $latestMutex = [Threading.Mutex]::new($false, 'Local\CapybaraCheckProjectLatest')
    try {
        if ($latestMutex.WaitOne([TimeSpan]::FromSeconds(30))) {
            Copy-Item -LiteralPath $textLogPath -Destination $latestTextLogPath -Force
            Copy-Item -LiteralPath $jsonLogPath -Destination $latestJsonLogPath -Force
            Set-Content -LiteralPath $latestRunPath -Value $runId -Encoding utf8
            $latestMutex.ReleaseMutex()
        }
        else {
            Write-CheckLine '[check] NOTE: unique run files are complete; latest pointer update timed out.'
        }
    }
    finally {
        $latestMutex.Dispose()
    }
}

exit $overallExitCode
