[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$gameRoot = Join-Path $repositoryRoot 'game'
$godotBin = $env:GODOT_BIN
$fixtureRunId = [Guid]::NewGuid().ToString('N')
$fixtureBasePath = "user://capybara_tests/save_process/$fixtureRunId/slot"
if ([string]::IsNullOrWhiteSpace($godotBin) -or -not (Test-Path -LiteralPath $godotBin -PathType Leaf)) {
    [Console]::Error.WriteLine('[save-restart] FAIL: GODOT_BIN is unavailable.')
    exit 2
}

function Invoke-SaveFixture {
    param(
        [Parameter(Mandatory = $true)][string]$Mode,
        [string]$Script = 'res://tests/save_process_fixture.gd'
    )

    $output = @(& $godotBin --headless --path $gameRoot `
        --script $Script -- $Mode $fixtureBasePath 2>&1)
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
    Invoke-SaveFixture -Mode 'write'
    Invoke-SaveFixture -Mode 'read'
    Invoke-SaveFixture -Mode 'cleanup'
    foreach ($mode in @('seed', 'recover', 'save', 'verify', 'cleanup',
        'seed', 'isolate_fail', 'save', 'verify', 'cleanup',
        'seed_capacity', 'isolate_fail', 'save', 'verify', 'faults', 'cleanup')) {
        Invoke-SaveFixture -Mode $mode -Script 'res://tests/save_recovery_process_fixture.gd'
    }
    foreach ($mode in @('write', 'read', 'cleanup')) {
        Invoke-SaveFixture -Mode $mode -Script 'res://tests/hotbar_process_fixture.gd'
    }
}
catch {
    [Console]::Error.WriteLine("[save-restart] FAIL: $($_.Exception.Message)")
    try { Invoke-SaveFixture -Mode 'cleanup' } catch {}
    try { Invoke-SaveFixture -Mode 'cleanup' -Script 'res://tests/save_recovery_process_fixture.gd' } catch {}
    exit 16
}

Invoke-SaveFixture -Mode 'cleanup'
[Console]::WriteLine('[save-restart] PASS: cross-zone state, recovery-save-restart, and write/rotation/commit failures verified.')
exit 0
