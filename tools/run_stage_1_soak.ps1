param(
    [ValidateRange(1, 86400)]
    [int]$DurationSeconds = 1200,
    [switch]$ChildProcess,
    [string]$ChildLogPath,
    [string]$ChildGamePath,
    [string]$ChildGodotBin
)

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'PowerShell 7 or newer is required.'
}

if ($ChildProcess) {
    $env:CAPYBARA_STAGE_1_SOAK_SECONDS = [string]$DurationSeconds
    & $ChildGodotBin --headless --path $ChildGamePath --script res://tests/stage_1_soak.gd 2>&1 |
        Tee-Object -FilePath $ChildLogPath
    exit $LASTEXITCODE
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$gamePath = Join-Path $projectRoot 'game'
$logDirectory = Join-Path $projectRoot 'build\logs'
$runId = '{0}-p{1}-{2}' -f (
    [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'),
    $PID,
    [Guid]::NewGuid().ToString('N').Substring(0, 8)
)
$logPath = Join-Path $logDirectory "stage-1-soak-$runId.log"
$timeoutSeconds = $DurationSeconds + 60

if ([string]::IsNullOrWhiteSpace($env:GODOT_BIN)) {
    throw 'GODOT_BIN is not set.'
}
if (-not (Test-Path -LiteralPath $env:GODOT_BIN -PathType Leaf)) {
    throw "GODOT_BIN does not point to a file: $env:GODOT_BIN"
}

New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
$powerShellBin = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$startInfo = [Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $powerShellBin
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
foreach ($argument in @(
    '-NoProfile',
    '-ExecutionPolicy',
    'Bypass',
    '-File',
    $PSCommandPath,
    '-DurationSeconds',
    [string]$DurationSeconds,
    '-ChildProcess',
    '-ChildLogPath',
    $logPath,
    '-ChildGamePath',
    $gamePath,
    '-ChildGodotBin',
    $env:GODOT_BIN
)) {
    $startInfo.ArgumentList.Add($argument)
}

$process = [Diagnostics.Process]::new()
$process.StartInfo = $startInfo
$timedOut = $false
try {
    if (-not $process.Start()) {
        throw 'Failed to start the Stage 1 soak child process.'
    }
    if (-not $process.WaitForExit($timeoutSeconds * 1000)) {
        $timedOut = $true
        try {
            $process.Kill($true)
        }
        catch {
            $process.Kill()
        }
        $process.WaitForExit()
    }
    $nativeExitCode = if ($timedOut) { 124 } else { $process.ExitCode }
}
finally {
    $process.Dispose()
}

$outputText = if (Test-Path -LiteralPath $logPath -PathType Leaf) {
    Get-Content -LiteralPath $logPath -Raw
}
else {
    ''
}
if ($timedOut) {
    throw "Stage 1 soak timed out after $timeoutSeconds seconds. Log: $logPath"
}
if ($nativeExitCode -ne 0) {
    throw "Stage 1 soak exited with code $nativeExitCode. Log: $logPath"
}
if ($outputText -match '(?m)^\s*(SCRIPT ERROR|ERROR|WARNING):') {
    throw "Stage 1 soak emitted a diagnostic. Log: $logPath"
}

$markerPattern = (
    'CAPYBARA STAGE 1 SOAK PASSED: duration=(\d+)s cycles=(\d+) transitions=(\d+) ' +
    'inputs=(\d+) selections=(\d+) state_checks=(\d+)'
)
$markerMatch = [regex]::Match($outputText, $markerPattern)
if (-not $markerMatch.Success) {
    throw "Stage 1 soak pass marker was not found. Log: $logPath"
}
$metrics = [pscustomobject]@{
    duration_seconds = [int]$markerMatch.Groups[1].Value
    cycles = [int]$markerMatch.Groups[2].Value
    transitions = [int]$markerMatch.Groups[3].Value
    inputs = [int]$markerMatch.Groups[4].Value
    selections = [int]$markerMatch.Groups[5].Value
    state_checks = [int]$markerMatch.Groups[6].Value
}
$heartbeatCount = ([regex]::Matches($outputText, 'STAGE 1 SOAK HEARTBEAT:')).Count
$minimumHeartbeats = [Math]::Floor($DurationSeconds / 60)
if (
    $metrics.duration_seconds -lt $DurationSeconds -or
    $metrics.cycles -le 0 -or
    $metrics.transitions -le 0 -or
    $metrics.inputs -ne $metrics.transitions -or
    $metrics.selections -le 0 -or
    $metrics.state_checks -le 0 -or
    $heartbeatCount -lt $minimumHeartbeats
) {
    throw "Stage 1 soak metrics did not satisfy the requested workload. Log: $logPath"
}

Write-Host ((
    '[stage-1-soak] PASS duration_seconds={0} cycles={1} transitions={2} inputs={3} ' +
    'selections={4} state_checks={5} heartbeats={6} log={7}'
) -f
    $metrics.duration_seconds,
    $metrics.cycles,
    $metrics.transitions,
    $metrics.inputs,
    $metrics.selections,
    $metrics.state_checks,
    $heartbeatCount,
    $logPath)
