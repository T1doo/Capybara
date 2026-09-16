[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$gameRoot = Join-Path $repositoryRoot 'game'
$godotBin = $env:GODOT_BIN
$fixtureRunId = [Guid]::NewGuid().ToString('N')
$fixturePath = "user://capybara_tests/settings_process/$fixtureRunId/settings.cfg"
if ([string]::IsNullOrWhiteSpace($godotBin) -or -not (Test-Path -LiteralPath $godotBin -PathType Leaf)) {
    [Console]::Error.WriteLine('[settings-restart] FAIL: GODOT_BIN is unavailable.')
    exit 2
}

function Invoke-SettingsFixture {
    param([Parameter(Mandatory = $true)][string]$Mode)

    $output = @(& $godotBin --headless --path $gameRoot `
        --script 'res://tests/settings_process_fixture.gd' -- $Mode $fixturePath 2>&1)
    $exitCode = $LASTEXITCODE
    foreach ($line in $output) {
        [Console]::WriteLine([string]$line)
    }
    if ($exitCode -ne 0) {
        throw "Fixture mode '$Mode' exited with $exitCode."
    }
    if (($output -join "`n") -match '(?im)^\s*(SCRIPT ERROR|ERROR|WARNING):') {
        throw "Fixture mode '$Mode' emitted a diagnostic."
    }
}

try {
    Invoke-SettingsFixture -Mode 'write'
    Invoke-SettingsFixture -Mode 'read'
}
catch {
    [Console]::Error.WriteLine("[settings-restart] FAIL: $($_.Exception.Message)")
    try { Invoke-SettingsFixture -Mode 'cleanup' } catch {}
    exit 15
}

Invoke-SettingsFixture -Mode 'cleanup'
[Console]::WriteLine('[settings-restart] PASS: independent write/read processes restored settings.')
exit 0
