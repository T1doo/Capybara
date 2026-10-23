[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$OutputDirectory)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$output = [IO.Path]::GetFullPath($OutputDirectory, $root)
$build = [IO.Path]::GetFullPath((Join-Path $root 'build')) + [IO.Path]::DirectorySeparatorChar
if (-not $output.StartsWith($build, [StringComparison]::OrdinalIgnoreCase) -or (Test-Path -LiteralPath $output)) {
    throw 'Use a new output directory strictly below this repository build.'
}
$blender = $env:BLENDER_BIN
$godot = $env:GODOT_BIN
if (-not $blender -or -not $godot) { throw 'Set BLENDER_BIN (4.5.13 LTS) and GODOT_BIN (4.7.2 Standard).' }
if ((& $blender --version | Select-Object -First 1) -notmatch '^Blender 4\.5\.13') { throw 'Pinned Blender version required.' }
if ((& $godot --version) -notmatch '^4\.7\.2\.') { throw 'Pinned Godot version required.' }
New-Item -ItemType Directory -Path $output | Out-Null
Set-Location -LiteralPath $root

function Invoke-SampleStep([string]$Name, [string]$Executable, [string[]]$Arguments) {
    $log = Join-Path $output ($Name + '.log')
    & $Executable @Arguments *> $log
    $code = $LASTEXITCODE
    $text = Get-Content -LiteralPath $log -Raw
    if ($code -ne 0 -or $text -match '(?m)^SCRIPT ERROR:|^ERROR:|^Traceback') {
        throw "Sample step failed: $Name (exit $code). Evidence retained at $log"
    }
    [Console]::WriteLine('[motion-build] PASS: ' + $Name)
}

function Invoke-BlenderStep([string]$Name, [string]$Script, [string[]]$Arguments) {
    Invoke-SampleStep $Name $blender (@('--background', '--factory-startup', '--python-exit-code', '1', '--python', $Script, '--') + $Arguments)
}

Invoke-SampleStep 'import' $godot @('--headless', '--path', 'game', '--import')
$native = Join-Path $output 'native'
Invoke-BlenderStep 'native' 'tools/art/build_player_mesh_v002.py' @('--output-dir', $native, '--samples', '32', '--threads', '8')
$shape = Join-Path $output 'shape'
Invoke-BlenderStep 'shape' 'tools/art/probe_player_shape_v003.py' @('--model-manifest', (Join-Path $native 'render_manifest.json'), '--output-dir', $shape)
$paint = Join-Path $output 'paint'
Invoke-BlenderStep 'paint' 'tools/art/probe_player_paint_projection.py' @('--model-manifest', (Join-Path $shape 'render_manifest.json'),
    '--paintover', 'art/candidates/player_v003_paintover_v001/paintover_a_v001.png', '--paintover-sha256', '06781018de02905d017667e0bb03c3a3fde82a2c164ba8153dfa281ab3a4201a',
    '--rear-paintover', 'art/candidates/player_v003_rear_paintover_v001/rear_paintover_a_v001.png', '--rear-sha256', 'c7c384daf098b66950df8d42c124708a40304989b717193174449affa14b2d1b',
    '--rear-uv-offset', '0.00318979266347687', '0.023125996810207337', '--view-transform', 'Standard', '--output-dir', $paint)
$record = Join-Path $output 'record'
Invoke-SampleStep 'record' $godot @('--headless', '--path', 'game', '--fixed-fps', '60', '--script', 'res://../tools/art/record_player_motion.gd', '--', $record)
$bank = Join-Path $output 'bank'
Invoke-BlenderStep 'bank' 'tools/art/render_player_motion.py' @('--model-dir', $paint, '--motion', (Join-Path $record 'motion.json'), '--output-dir', $bank)
$movie = Join-Path $output 'capture.avi'
$playback = Join-Path $output 'playback'
Invoke-SampleStep 'gpu_movie' $godot @('--path', 'game', '--fixed-fps', '60', '--write-movie', $movie, '--script', 'res://../tools/art/play_player_motion.gd', '--', (Join-Path $bank 'motion_manifest.json'), (Join-Path $record 'motion.json'), $playback)
Invoke-BlenderStep 'mp4' 'tools/art/encode_player_motion.py' @('--input', $movie, '--output', (Join-Path $output 'review.mp4'))
[Console]::WriteLine('[motion-build] Candidate generated; visual/route/Stage3 approval remains separate. ' + $output)
