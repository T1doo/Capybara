[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]]$InputPath,

    [string]$OutputDirectory,

    [string[]]$Label = @(),

    [string]$ManifestPath,

    [ValidateRange(64, 512)]
    [int]$ActualCharacterHeight = 144,

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$candidateRoot = [IO.Path]::GetFullPath((Join-Path $repositoryRoot 'art\candidates'))
$buildRoot = [IO.Path]::GetFullPath((Join-Path $repositoryRoot 'build'))
$validatorPath = Join-Path $PSScriptRoot 'validate_png_assets.ps1'

function Test-PathInside {
    param(
        [Parameter(Mandatory = $true)][string]$Child,
        [Parameter(Mandatory = $true)][string]$Parent
    )

    $normalizedChild = [IO.Path]::GetFullPath($Child)
    $normalizedParent = [IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    return $normalizedChild.StartsWith($normalizedParent, [StringComparison]::OrdinalIgnoreCase)
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $buildRoot 'art-pipeline\alpha-review'
}
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $repositoryRoot 'art\candidates\player_capybara_v1\CANDIDATE_MANIFEST.csv'
}
$outputFullDirectory = [IO.Path]::GetFullPath($OutputDirectory)
if (-not (Test-PathInside -Child $outputFullDirectory -Parent $candidateRoot) -and
    -not (Test-PathInside -Child $outputFullDirectory -Parent $buildRoot)) {
    throw 'Alpha review output must stay below art/candidates or build.'
}

$resolvedInputs = [System.Collections.Generic.List[string]]::new()
foreach ($path in $InputPath) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Alpha review input is missing: $path"
    }
    $resolvedInput = (Resolve-Path -LiteralPath $path).ProviderPath
    if (-not (Test-PathInside -Child $resolvedInput -Parent $candidateRoot) -and
        -not (Test-PathInside -Child $resolvedInput -Parent $buildRoot)) {
        throw "Alpha review input must stay below art/candidates or build: $resolvedInput"
    }
    $relativeInput = [IO.Path]::GetRelativePath($repositoryRoot, $resolvedInput).Replace('\', '/')
    if ($relativeInput.StartsWith('art/candidates/_quarantine/', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Quarantined images cannot enter alpha review: $relativeInput"
    }
    $resolvedInputs.Add($resolvedInput)
}
if ($resolvedInputs.Count -eq 0) {
    throw 'At least one alpha review input is required.'
}
if ($Label.Count -gt 0 -and $Label.Count -ne $resolvedInputs.Count) {
    throw 'Label count must be zero or match InputPath count.'
}
$labels = @(
    if ($Label.Count -gt 0) {
        $Label
    }
    else {
        $resolvedInputs | ForEach-Object { [IO.Path]::GetFileNameWithoutExtension($_) }
    }
)
foreach ($candidateLabel in $labels) {
    if ([string]::IsNullOrWhiteSpace($candidateLabel)) {
        throw 'Alpha review labels cannot be blank.'
    }
    if ($candidateLabel.Length -gt 48) {
        throw "Alpha review label exceeds 48 characters: $candidateLabel"
    }
}
if (@($labels | ForEach-Object { $_.ToLowerInvariant() } | Group-Object | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
    throw 'Alpha review labels must be unique (case-insensitive).'
}

New-Item -ItemType Directory -Path $outputFullDirectory -Force | Out-Null
$inspectionPath = Join-Path $outputFullDirectory ".alpha_inspection.$([Guid]::NewGuid().ToString('N')).tmp.json"
$temporaryArtifacts = [System.Collections.Generic.List[string]]::new()
$temporaryArtifacts.Add($inspectionPath)
try {
& $validatorPath `
    -Path @($resolvedInputs) `
    -RequireAlpha `
    -MinimumTransparentPadding 1 `
    -ManifestPath $ManifestPath `
    -JsonOutputPath $inspectionPath
if ($LASTEXITCODE -ne 0) {
    if (Test-Path -LiteralPath $inspectionPath) {
        Remove-Item -LiteralPath $inspectionPath -Force
    }
    exit $LASTEXITCODE
}
$inspection = Get-Content -Raw -LiteralPath $inspectionPath | ConvertFrom-Json
$assetInspections = @($inspection.assets)
if ($assetInspections.Count -ne $resolvedInputs.Count) {
    throw 'Alpha inspection result count does not match inputs.'
}

$edgeOutput = Join-Path $outputFullDirectory 'alpha_edge_review_v001.png'
$actualOutput = Join-Path $outputFullDirectory 'actual_size_144px_v001.png'
$mappingOutput = Join-Path $outputFullDirectory 'alpha_review_v001.mapping.json'
foreach ($outputPath in @($edgeOutput, $actualOutput, $mappingOutput)) {
    if ((Test-Path -LiteralPath $outputPath) -and -not $Force) {
        throw "Alpha review output exists; pass -Force to replace it: $outputPath"
    }
}

$backgrounds = @(
    @{ name = 'white'; color = [Drawing.Color]::FromArgb(255, 250, 248, 241) },
    @{ name = 'black'; color = [Drawing.Color]::FromArgb(255, 22, 25, 25) },
    @{ name = 'grass'; color = [Drawing.Color]::FromArgb(255, 72, 103, 60) },
    @{ name = 'water'; color = [Drawing.Color]::FromArgb(255, 43, 111, 126) }
)
$panelWidth = 400
$rowHeight = 420
$edgeWidth = $panelWidth * $backgrounds.Count
$edgeHeight = $rowHeight * $resolvedInputs.Count
$actualColumns = [Math]::Min(3, $resolvedInputs.Count)
$maximumActualDrawWidth = 0
foreach ($asset in $assetInspections) {
    $contentWidth = [int]$asset.content_right_exclusive - [int]$asset.content_left
    $contentHeight = [int]$asset.content_bottom_exclusive - [int]$asset.content_top
    $expectedWidth = [int][Math]::Ceiling($contentWidth * $ActualCharacterHeight / [double]$contentHeight)
    $maximumActualDrawWidth = [Math]::Max($maximumActualDrawWidth, $expectedWidth)
}
$actualCellWidth = [int][Math]::Max(420, $maximumActualDrawWidth + 40)
$actualCellHeight = 250
$actualRows = [int][Math]::Ceiling($resolvedInputs.Count / [double]$actualColumns)
$actualWidth = $actualColumns * $actualCellWidth
$actualHeight = $actualRows * $actualCellHeight
$edgeSheet = [Drawing.Bitmap]::new($edgeWidth, $edgeHeight, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$actualSheet = [Drawing.Bitmap]::new($actualWidth, $actualHeight, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$edgeGraphics = [Drawing.Graphics]::FromImage($edgeSheet)
$actualGraphics = [Drawing.Graphics]::FromImage($actualSheet)
$labelFont = [Drawing.Font]::new('Segoe UI', 18, [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
$lightBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 245, 240, 224))
$darkBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 52, 58, 49))
$temporarySuffix = [Guid]::NewGuid().ToString('N')
$temporaryEdge = Join-Path $outputFullDirectory ".alpha_edge.$temporarySuffix.tmp"
$temporaryActual = Join-Path $outputFullDirectory ".actual_size.$temporarySuffix.tmp"
$temporaryMapping = Join-Path $outputFullDirectory ".mapping.$temporarySuffix.tmp"
$temporaryArtifacts.Add($temporaryEdge)
$temporaryArtifacts.Add($temporaryActual)
$temporaryArtifacts.Add($temporaryMapping)
try {
    $edgeGraphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $edgeGraphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
    $actualGraphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $actualGraphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
    $actualGraphics.Clear([Drawing.Color]::FromArgb(255, 232, 238, 220))

    for ($index = 0; $index -lt $resolvedInputs.Count; $index += 1) {
        $asset = $assetInspections[$index]
        $sourceRectangle = [Drawing.Rectangle]::new(
            [int]$asset.content_left,
            [int]$asset.content_top,
            [int]$asset.content_right_exclusive - [int]$asset.content_left,
            [int]$asset.content_bottom_exclusive - [int]$asset.content_top
        )
        $image = [Drawing.Image]::FromFile($resolvedInputs[$index])
        try {
            for ($backgroundIndex = 0; $backgroundIndex -lt $backgrounds.Count; $backgroundIndex += 1) {
                $panelX = $backgroundIndex * $panelWidth
                $panelY = $index * $rowHeight
                $backgroundBrush = [Drawing.SolidBrush]::new($backgrounds[$backgroundIndex].color)
                try {
                    $edgeGraphics.FillRectangle($backgroundBrush, $panelX, $panelY, $panelWidth, $rowHeight)
                }
                finally {
                    $backgroundBrush.Dispose()
                }
                $scale = [Math]::Min(360.0 / $sourceRectangle.Width, 350.0 / $sourceRectangle.Height)
                $drawWidth = [int][Math]::Round($sourceRectangle.Width * $scale)
                $drawHeight = [int][Math]::Round($sourceRectangle.Height * $scale)
                $drawX = $panelX + [int](($panelWidth - $drawWidth) / 2)
                $drawY = $panelY + 46 + [int]((350 - $drawHeight) / 2)
                $destination = [Drawing.Rectangle]::new($drawX, $drawY, $drawWidth, $drawHeight)
                $edgeGraphics.DrawImage($image, $destination, $sourceRectangle, [Drawing.GraphicsUnit]::Pixel)
                $textBrush = if ($backgroundIndex -eq 1) { $lightBrush } else { $darkBrush }
                $edgeGraphics.DrawString(
                    "$($labels[$index]) / $($backgrounds[$backgroundIndex].name)",
                    $labelFont,
                    $textBrush,
                    [float]($panelX + 14),
                    [float]($panelY + 12)
                )
            }

            $column = $index % $actualColumns
            $row = [int][Math]::Floor($index / [double]$actualColumns)
            $actualDrawWidth = [int][Math]::Round(
                $sourceRectangle.Width * $ActualCharacterHeight / [double]$sourceRectangle.Height
            )
            $actualX = ($column * $actualCellWidth) + [int](($actualCellWidth - $actualDrawWidth) / 2)
            $actualY = ($row * $actualCellHeight) + 52
            $actualGraphics.DrawImage(
                $image,
                [Drawing.Rectangle]::new($actualX, $actualY, $actualDrawWidth, $ActualCharacterHeight),
                $sourceRectangle,
                [Drawing.GraphicsUnit]::Pixel
            )
            $actualGraphics.DrawString(
                "$($labels[$index]) / ${ActualCharacterHeight}px",
                $labelFont,
                $darkBrush,
                [float](($column * $actualCellWidth) + 14),
                [float](($row * $actualCellHeight) + 14)
            )
        }
        finally {
            $image.Dispose()
        }
    }
    $edgeSheet.Save($temporaryEdge, [Drawing.Imaging.ImageFormat]::Png)
    $actualSheet.Save($temporaryActual, [Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $darkBrush.Dispose()
    $lightBrush.Dispose()
    $labelFont.Dispose()
    $actualGraphics.Dispose()
    $edgeGraphics.Dispose()
    $actualSheet.Dispose()
    $edgeSheet.Dispose()
}

try {
    $mappingItems = for ($index = 0; $index -lt $resolvedInputs.Count; $index += 1) {
        [ordered]@{
            index = $index
            label = $labels[$index]
            file_path = [IO.Path]::GetRelativePath($repositoryRoot, $resolvedInputs[$index]).Replace('\', '/')
            sha256 = $assetInspections[$index].sha256
            content_bounds = @(
                [int]$assetInspections[$index].content_left,
                [int]$assetInspections[$index].content_top,
                [int]$assetInspections[$index].content_right_exclusive,
                [int]$assetInspections[$index].content_bottom_exclusive
            )
        }
    }
    $mapping = [ordered]@{
        schema_version = 1
        actual_character_height = $ActualCharacterHeight
        edge_output = [ordered]@{
            path = [IO.Path]::GetRelativePath($repositoryRoot, $edgeOutput).Replace('\', '/')
            sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $temporaryEdge).Hash.ToLowerInvariant()
            width = $edgeWidth
            height = $edgeHeight
        }
        actual_size_output = [ordered]@{
            path = [IO.Path]::GetRelativePath($repositoryRoot, $actualOutput).Replace('\', '/')
            sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $temporaryActual).Hash.ToLowerInvariant()
            width = $actualWidth
            height = $actualHeight
        }
        candidates = @($mappingItems)
    }
    $mapping | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $temporaryMapping -Encoding utf8
    Move-Item -LiteralPath $temporaryEdge -Destination $edgeOutput -Force
    Move-Item -LiteralPath $temporaryActual -Destination $actualOutput -Force
    Move-Item -LiteralPath $temporaryMapping -Destination $mappingOutput -Force
}
catch {
    foreach ($temporaryPath in @($temporaryEdge, $temporaryActual, $temporaryMapping, $inspectionPath)) {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
    throw
}
if (Test-Path -LiteralPath $inspectionPath) {
    Remove-Item -LiteralPath $inspectionPath -Force
}

[Console]::WriteLine(
    "[alpha-review] PASS: $($resolvedInputs.Count) candidates; four backgrounds and ${ActualCharacterHeight}px preview generated."
)
}
finally {
    foreach ($temporaryPath in $temporaryArtifacts) {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
}
exit 0
