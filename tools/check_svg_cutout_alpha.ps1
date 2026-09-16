[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$renderedPath = Join-Path $repositoryRoot 'build\art-pipeline\chr_player_cutout_down_right_v001.png'
$renderManifestPath = Join-Path $repositoryRoot 'build\art-pipeline\vector_preview_manifest.csv'
$reviewDirectory = Join-Path $repositoryRoot 'build\art-pipeline\cutout-review'
$reviewToolPath = Join-Path $PSScriptRoot 'make_alpha_review_sheet.ps1'

foreach ($requiredPath in @($renderedPath, $renderManifestPath, $reviewToolPath)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        [Console]::Error.WriteLine("[cutout-alpha] FAIL: Required input is missing: $requiredPath")
        exit 24
    }
}

& $reviewToolPath `
    -InputPath $renderedPath `
    -OutputDirectory $reviewDirectory `
    -Label 'Cutout V1' `
    -ManifestPath $renderManifestPath `
    -ActualCharacterHeight 144 `
    -Force
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$mappingPath = Join-Path $reviewDirectory 'alpha_review_v001.mapping.json'
try {
    $mapping = Get-Content -Raw -LiteralPath $mappingPath | ConvertFrom-Json
}
catch {
    [Console]::Error.WriteLine("[cutout-alpha] FAIL: Mapping is invalid: $($_.Exception.Message)")
    exit 24
}
$candidates = @($mapping.candidates)
if ($mapping.schema_version -ne 1 -or
    $mapping.actual_character_height -ne 144 -or
    $candidates.Count -ne 1 -or
    $candidates[0].index -ne 0 -or
    $candidates[0].label -ne 'Cutout V1') {
    [Console]::Error.WriteLine('[cutout-alpha] FAIL: Mapping identity or 144px contract is invalid.')
    exit 24
}
$renderedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $renderedPath).Hash.ToLowerInvariant()
if ($candidates[0].sha256 -ne $renderedHash) {
    [Console]::Error.WriteLine('[cutout-alpha] FAIL: Mapping does not reference the latest rendered PNG.')
    exit 24
}
$bounds = @($candidates[0].content_bounds)
if ($bounds.Count -ne 4 -or
    [int]$bounds[2] -le [int]$bounds[0] -or
    [int]$bounds[3] -le [int]$bounds[1]) {
    [Console]::Error.WriteLine('[cutout-alpha] FAIL: Character content bounds are invalid.')
    exit 24
}
$contentWidth = [int]$bounds[2] - [int]$bounds[0]
$contentHeight = [int]$bounds[3] - [int]$bounds[1]
$expectedActualWidth = [int][Math]::Ceiling($contentWidth * 144.0 / $contentHeight)
if ([int]$mapping.actual_size_output.width -lt $expectedActualWidth + 40) {
    [Console]::Error.WriteLine('[cutout-alpha] FAIL: 144px preview canvas can crop the character horizontally.')
    exit 24
}

Add-Type -AssemblyName System.Drawing
foreach ($outputRecord in @($mapping.edge_output, $mapping.actual_size_output)) {
    $outputFullPath = Join-Path $repositoryRoot $outputRecord.path
    if (-not (Test-Path -LiteralPath $outputFullPath -PathType Leaf)) {
        [Console]::Error.WriteLine("[cutout-alpha] FAIL: Review output is missing: $($outputRecord.path)")
        exit 24
    }
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $outputFullPath).Hash.ToLowerInvariant()
    if ($actualHash -ne $outputRecord.sha256) {
        [Console]::Error.WriteLine("[cutout-alpha] FAIL: Review output hash mismatch: $($outputRecord.path)")
        exit 24
    }
    $outputImage = [Drawing.Image]::FromFile($outputFullPath)
    try {
        if ($outputImage.Width -ne [int]$outputRecord.width -or
            $outputImage.Height -ne [int]$outputRecord.height) {
            [Console]::Error.WriteLine("[cutout-alpha] FAIL: Review output dimensions are stale: $($outputRecord.path)")
            exit 24
        }
    }
    finally {
        $outputImage.Dispose()
    }
}

[Console]::WriteLine(
    "[cutout-alpha] PASS: latest render hash, four backgrounds, bounds, output hashes, and 144px no-crop contract verified."
)
exit 0
