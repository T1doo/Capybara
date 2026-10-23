[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$OutputDirectory)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$output = [IO.Path]::GetFullPath($OutputDirectory, $root)
$build = [IO.Path]::GetFullPath((Join-Path $root 'build')) + [IO.Path]::DirectorySeparatorChar
if (-not $output.StartsWith($build, [StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)) {
    throw 'Choose a new output directory strictly below repository build.'
}
if (-not $env:GODOT_BIN -or (& $env:GODOT_BIN --version) -notmatch '^4\.7\.2\.') {
    throw 'GODOT_BIN must point to the pinned Godot 4.7.2 Standard executable.'
}
$review = Join-Path $root 'docs/reviews/stage-03-v004'
$evidence = Get-Content -LiteralPath (Join-Path $review 'EVIDENCE.json') -Raw | ConvertFrom-Json
$needed = @('evidence/motion_record.json', 'evidence/motion_bank.json', 'cutout_layers/layer_manifest.json')
$layers = Get-Content -LiteralPath (Join-Path $review 'cutout_layers/layer_manifest.json') -Raw | ConvertFrom-Json
foreach ($layer in $layers.layers) {
    if ([IO.Path]::GetFileName($layer.path) -ne $layer.path) { throw 'Invalid layer filename.' }
    $needed += 'cutout_layers/' + $layer.path
}
foreach ($relative in $needed) {
    $entry = @($evidence.files | Where-Object { $_.file -eq $relative })
    $path = Join-Path $review $relative
    if ($entry.Count -ne 1 -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry[0].sha256) {
        throw "Review payload changed or LFS content missing: $relative"
    }
}
New-Item -ItemType Directory -Path $output | Out-Null
$plateDirectory = Join-Path $output 'layers'
New-Item -ItemType Directory -Path $plateDirectory | Out-Null
Copy-Item -LiteralPath (Join-Path $review 'evidence/motion_record.json') -Destination (Join-Path $output 'motion.json')
Copy-Item -LiteralPath (Join-Path $review 'evidence/motion_bank.json') -Destination (Join-Path $output 'bank.json')
foreach ($relative in $needed | Where-Object { $_.StartsWith('cutout_layers/') }) {
    Copy-Item -LiteralPath (Join-Path $review $relative) -Destination (Join-Path $plateDirectory ([IO.Path]::GetFileName($relative)))
}
Set-Location -LiteralPath $root
foreach ($step in @('import', 'replay')) {
    $arguments = if ($step -eq 'import') { @('--headless', '--path', 'game', '--import') } else {
        @('--path', 'game', '--fixed-fps', '60', '--write-movie', (Join-Path $output 'capture.avi'),
            '--script', 'res://../tools/art/probe_player_cutout_v004.gd', '--',
            (Join-Path $output 'bank.json'), (Join-Path $output 'motion.json'),
            (Join-Path $output 'playback'), (Join-Path $plateDirectory 'layer_manifest.json'))
    }
    $log = Join-Path $output ($step + '.log')
    & $env:GODOT_BIN @arguments *> $log
    $code = $LASTEXITCODE
    if ($code -ne 0 -or (Get-Content -LiteralPath $log -Raw) -match '(?m)^SCRIPT ERROR:|^ERROR:|^WARNING:') {
        throw "Review replay failed: $step, exit $code; see $log"
    }
}
[Console]::WriteLine('[cutout-review] 330 real Player ticks replayed; no Blender or private build required. Visual approval remains separate.')
