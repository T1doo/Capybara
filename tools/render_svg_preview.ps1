[CmdletBinding()]
param(
    [string]$InputPath,
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
if ([string]::IsNullOrWhiteSpace($InputPath)) {
    $InputPath = Join-Path $repositoryRoot 'art\candidates\player_capybara_v1\vector_prototypes\chr_player_cutout_down_right_v001.svg'
}
if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $repositoryRoot 'build\art-pipeline\chr_player_cutout_down_right_v001.png'
}
$inputFullPath = [IO.Path]::GetFullPath($InputPath)
$outputFullPath = [IO.Path]::GetFullPath($OutputPath)
$candidateRoot = [IO.Path]::GetFullPath((Join-Path $repositoryRoot 'art\candidates')).TrimEnd('\') + '\'
$buildRoot = [IO.Path]::GetFullPath((Join-Path $repositoryRoot 'build')).TrimEnd('\') + '\'
if (-not $inputFullPath.StartsWith($candidateRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'SVG preview input must stay below art/candidates.'
}
$relativeInput = [IO.Path]::GetRelativePath($repositoryRoot, $inputFullPath).Replace('\', '/')
if ($relativeInput.StartsWith('art/candidates/_quarantine/', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Quarantined SVG files cannot be rendered as active prototypes.'
}
if (-not $outputFullPath.StartsWith($buildRoot, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'SVG preview output must stay below build.'
}
if (-not [IO.Path]::GetExtension($inputFullPath).Equals('.svg', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'SVG preview input must use the .svg extension.'
}
if (-not [IO.Path]::GetExtension($outputFullPath).Equals('.png', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'SVG preview output must use the .png extension.'
}
if ([IO.Path]::GetFileName($outputFullPath) -notmatch '^[a-z0-9_]+_v[0-9]{3}\.png$') {
    throw 'SVG preview output filename must match the versioned asset naming convention.'
}
if (-not (Test-Path -LiteralPath $inputFullPath -PathType Leaf)) {
    throw "SVG preview input is missing: $inputFullPath"
}
$godotBin = $env:GODOT_BIN
if ([string]::IsNullOrWhiteSpace($godotBin) -or -not (Test-Path -LiteralPath $godotBin -PathType Leaf)) {
    throw 'GODOT_BIN is missing or invalid.'
}
$outputParent = [IO.Path]::GetDirectoryName($outputFullPath)
New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
$stagingSuffix = [Guid]::NewGuid().ToString('N')
$stagingOutputPath = Join-Path $outputParent ".$([IO.Path]::GetFileName($outputFullPath)).$stagingSuffix.tmp.png"
$stagingManifestPath = Join-Path $outputParent ".vector_preview.$stagingSuffix.tmp.csv"
$startInfo = [Diagnostics.ProcessStartInfo]::new()
$startInfo.FileName = $godotBin
$startInfo.UseShellExecute = $false
$startInfo.CreateNoWindow = $true
$startInfo.RedirectStandardOutput = $true
$startInfo.RedirectStandardError = $true
foreach ($argument in @(
    '--headless',
    '--path', (Join-Path $repositoryRoot 'game'),
    '--script', 'res://tests/art/render_svg_preview.gd',
    '--', $inputFullPath, $stagingOutputPath
)) {
    $startInfo.ArgumentList.Add($argument)
}
$process = [Diagnostics.Process]::new()
$process.StartInfo = $startInfo
try {
    if (-not $process.Start()) {
        throw 'Failed to start Godot SVG renderer.'
    }
    $standardOutputTask = $process.StandardOutput.ReadToEndAsync()
    $standardErrorTask = $process.StandardError.ReadToEndAsync()
    $completed = $process.WaitForExit(60000)
    if (-not $completed) {
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
    $outputLines = @(
        @($standardOutput -split '\r?\n') + @($standardError -split '\r?\n') |
            Where-Object { $_.Length -gt 0 }
    )
    foreach ($line in $outputLines) {
        [Console]::WriteLine($line)
    }
    $renderExit = if ($completed) { $process.ExitCode } else { 124 }
    $diagnostics = @($outputLines | Where-Object {
        $_ -match '(?i)^\s*(SCRIPT ERROR|ERROR|WARNING):'
    })
}
finally {
    $process.Dispose()
}
if ($renderExit -ne 0) {
    if (Test-Path -LiteralPath $stagingOutputPath) {
        Remove-Item -LiteralPath $stagingOutputPath -Force
    }
    exit $renderExit
}
if ($diagnostics.Count -gt 0) {
    [Console]::Error.WriteLine("SVG PREVIEW FAILED: Godot emitted $($diagnostics.Count) diagnostics.")
    if (Test-Path -LiteralPath $stagingOutputPath) {
        Remove-Item -LiteralPath $stagingOutputPath -Force
    }
    exit 20
}
$relativeStagingOutput = [IO.Path]::GetRelativePath($repositoryRoot, $stagingOutputPath).Replace('\', '/')
@(
    'file_path,raw_path,source_path,game_path',
    "$relativeStagingOutput,,,"
) | Set-Content -LiteralPath $stagingManifestPath -Encoding utf8
& (Join-Path $PSScriptRoot 'validate_png_assets.ps1') `
    -Path $stagingOutputPath `
    -MinimumWidth 512 `
    -MinimumHeight 512 `
    -RequireAlpha `
    -MinimumTransparentPadding 1 `
    -ManifestPath $stagingManifestPath `
    -SkipNameCheck
$stagingValidationExit = $LASTEXITCODE
if ($stagingValidationExit -ne 0) {
    foreach ($stagingPath in @($stagingOutputPath, $stagingManifestPath)) {
        if (Test-Path -LiteralPath $stagingPath) {
            Remove-Item -LiteralPath $stagingPath -Force
        }
    }
    exit $stagingValidationExit
}
Move-Item -LiteralPath $stagingOutputPath -Destination $outputFullPath -Force
Remove-Item -LiteralPath $stagingManifestPath -Force
$relativeOutput = [IO.Path]::GetRelativePath($repositoryRoot, $outputFullPath).Replace('\', '/')
$manifestPath = Join-Path $outputParent 'vector_preview_manifest.csv'
$temporaryManifestPath = Join-Path $outputParent ".vector_preview_manifest.$stagingSuffix.tmp"
@(
    'file_path,raw_path,source_path,game_path',
    "$relativeOutput,,,"
) | Set-Content -LiteralPath $temporaryManifestPath -Encoding utf8
Move-Item -LiteralPath $temporaryManifestPath -Destination $manifestPath -Force
& (Join-Path $PSScriptRoot 'validate_png_assets.ps1') `
    -Path $outputFullPath `
    -MinimumWidth 512 `
    -MinimumHeight 512 `
    -RequireAlpha `
    -MinimumTransparentPadding 1 `
    -ManifestPath $manifestPath
exit $LASTEXITCODE
