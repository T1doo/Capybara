[CmdletBinding()]
param(
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    [Console]::Error.WriteLine('[build-smoke] PowerShell 7 or newer is required.')
    exit 13
}

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$gameRoot = Join-Path $repositoryRoot 'game'
$godotBin = $env:GODOT_BIN
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repositoryRoot 'build\windows\capybara_ci_smoke.exe'
}

if ([string]::IsNullOrWhiteSpace($godotBin)) {
    [Console]::Error.WriteLine('[build-smoke] GODOT_BIN is not set.')
    exit 2
}
if (-not (Test-Path -LiteralPath $godotBin -PathType Leaf)) {
    [Console]::Error.WriteLine('[build-smoke] GODOT_BIN does not point to an existing file.')
    exit 3
}

$templateRoot = Join-Path $env:APPDATA 'Godot\export_templates\4.7.2.stable'
$debugTemplate = Join-Path $templateRoot 'windows_debug_x86_64.exe'
if (-not (Test-Path -LiteralPath $debugTemplate -PathType Leaf)) {
    [Console]::Error.WriteLine('[build-smoke] Godot 4.7.2 Windows debug export template is not installed.')
    exit 4
}

$outputDirectory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null

& $godotBin --headless --path $gameRoot --export-debug 'Windows Desktop' $OutputPath
if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine("[build-smoke] Godot export failed with exit code $LASTEXITCODE.")
    exit $LASTEXITCODE
}
if (-not (Test-Path -LiteralPath $OutputPath -PathType Leaf)) {
    [Console]::Error.WriteLine('[build-smoke] Export command succeeded but the Windows executable is missing.')
    exit 5
}

$startInfo = [Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $OutputPath
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
$startInfo.ArgumentList.Add('--headless')
$startInfo.ArgumentList.Add('--quit-after')
$startInfo.ArgumentList.Add('10')
$process = [Diagnostics.Process]::new()
$process.StartInfo = $startInfo
try {
    if (-not $process.Start()) {
        [Console]::Error.WriteLine('[build-smoke] Failed to start the exported executable.')
        exit 6
    }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit(30000)) {
        try { $process.Kill($true) } catch { $process.Kill() }
        $process.WaitForExit()
        [Console]::Error.WriteLine('[build-smoke] Exported executable timed out.')
        exit 7
    }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    if (-not [string]::IsNullOrWhiteSpace($stdout)) { [Console]::Write($stdout) }
    if (-not [string]::IsNullOrWhiteSpace($stderr)) { [Console]::Error.Write($stderr) }
    if ($process.ExitCode -ne 0) {
        [Console]::Error.WriteLine("[build-smoke] Exported executable failed with exit code $($process.ExitCode).")
        exit $process.ExitCode
    }
    if (($stdout + $stderr) -match '(?im)^\s*(SCRIPT ERROR|ERROR|WARNING):') {
        [Console]::Error.WriteLine('[build-smoke] Exported executable emitted an error or warning diagnostic.')
        exit 8
    }
}
finally {
    $process.Dispose()
}

[Console]::WriteLine("[build-smoke] PASS: exported and launched $([IO.Path]::GetFileName($OutputPath))")
exit 0
