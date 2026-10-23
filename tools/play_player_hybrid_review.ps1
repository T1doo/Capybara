[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$OutputDirectory,
    [switch]$Autoplay,
    [switch]$Smoke
)

$ErrorActionPreference = 'Stop'
if ($Smoke -and -not $Autoplay) { throw 'Smoke is an automated sequence; also pass -Autoplay.' }
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$output = [IO.Path]::GetFullPath($OutputDirectory, $root)
$build = [IO.Path]::GetFullPath((Join-Path $root 'build')) + [IO.Path]::DirectorySeparatorChar
if (-not $output.StartsWith($build, [StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)) {
    throw 'Use a NEW output directory strictly below repository build.'
}
if (-not $env:GODOT_BIN -or (& $env:GODOT_BIN --version) -notmatch '^4\.7\.2\.') {
    throw 'Set GODOT_BIN to the pinned Godot 4.7.2 Standard executable.'
}
$review = Join-Path $root 'docs/reviews/stage-03-v005'
$evidence = Get-Content -LiteralPath (Join-Path $review 'EVIDENCE.json') -Raw | ConvertFrom-Json
$manifest = Get-Content -LiteralPath (Join-Path $review 'assets/hybrid_manifest.json') -Raw | ConvertFrom-Json
$needed = @('assets/hybrid_manifest.json')
foreach ($heading in $manifest.headings) {
    $images = @($heading.upper) + @($heading.feet | ForEach-Object { $_.image })
    foreach ($image in $images) {
        if ([IO.Path]::GetFileName($image.path) -ne $image.path) { throw 'Invalid native plate filename.' }
        $needed += 'assets/' + $image.path
    }
}
foreach ($relative in $needed) {
    $entry = @($evidence.files | Where-Object { $_.file -eq $relative })
    if ($entry.Count -ne 1 -or (Get-FileHash -LiteralPath (Join-Path $review $relative) -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry[0].sha256) {
        throw "Missing/changed review payload or LFS content: $relative"
    }
}
New-Item -ItemType Directory -Path $output | Out-Null
$assetDirectory = Join-Path $output 'assets'
New-Item -ItemType Directory -Path $assetDirectory | Out-Null
foreach ($relative in $needed) {
    Copy-Item -LiteralPath (Join-Path $review $relative) -Destination (Join-Path $assetDirectory ([IO.Path]::GetFileName($relative)))
}
Set-Location -LiteralPath $root
foreach ($step in @('import', 'play')) {
    $arguments = @('--headless', '--path', 'game', '--import')
    if ($step -eq 'play') {
        $arguments = @('--path', 'game')
        if ($Autoplay) { $arguments += @('--fixed-fps', '60', '--write-movie', (Join-Path $output 'capture.avi')) }
        $arguments += @('--script', 'res://../tools/art/probe_player_hybrid_v005.gd', '--',
            (Join-Path $assetDirectory 'hybrid_manifest.json'), (Join-Path $output 'live'))
        if (-not $Autoplay) { $arguments += '--interactive' }
        elseif ($Smoke) { $arguments += '--smoke' }
    }
    $log = Join-Path $output ($step + '.log')
    & $env:GODOT_BIN @arguments *> $log
    $code = $LASTEXITCODE
    if ($code -ne 0 -or (Get-Content -LiteralPath $log -Raw) -match '(?m)^SCRIPT ERROR:|^ERROR:|^WARNING:') {
        throw "Hybrid review failed: $step, exit $code; see $log"
    }
}
[Console]::WriteLine('[hybrid-review] Candidate session finished. Default is free input; automated evidence requires -Autoplay. No mother/Stage3 approval implied.')
