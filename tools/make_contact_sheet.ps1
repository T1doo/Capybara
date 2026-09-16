[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]]$InputPath,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath,

    [string[]]$Label = @(),

    [ValidateRange(1, 6)]
    [int]$Columns = 3,

    [ValidateRange(64, 1024)]
    [int]$ThumbnailHeight = 360,

    [ValidateRange(8, 128)]
    [int]$Padding = 28,

    [string]$Title = 'Capybara Character Candidates',

    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$candidateRoot = [IO.Path]::GetFullPath((Join-Path $repositoryRoot 'art\candidates'))
$buildRoot = [IO.Path]::GetFullPath((Join-Path $repositoryRoot 'build'))

function Test-PathInside {
    param(
        [Parameter(Mandatory = $true)][string]$Child,
        [Parameter(Mandatory = $true)][string]$Parent
    )

    $normalizedChild = [IO.Path]::GetFullPath($Child)
    $normalizedParent = [IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    return $normalizedChild.StartsWith($normalizedParent, [StringComparison]::OrdinalIgnoreCase)
}

$outputFullPath = [IO.Path]::GetFullPath($OutputPath)
$outputRelativePath = [IO.Path]::GetRelativePath($repositoryRoot, $outputFullPath).Replace('\', '/')
if ($outputRelativePath.StartsWith('../') -or [IO.Path]::IsPathRooted($outputRelativePath)) {
    throw 'Contact sheet output must stay inside the repository.'
}
if (-not (Test-PathInside -Child $outputFullPath -Parent $candidateRoot) -and
    -not (Test-PathInside -Child $outputFullPath -Parent $buildRoot)) {
    throw 'Contact sheets may only be written below art/candidates or build.'
}
if ((Test-Path -LiteralPath $outputFullPath) -and -not $Force) {
    throw "Output already exists; pass -Force to replace it: $outputRelativePath"
}
if ($Label.Count -gt 0 -and $Label.Count -ne $InputPath.Count) {
    throw 'Label count must be zero or match InputPath count.'
}

$resolvedInputs = [System.Collections.Generic.List[string]]::new()
foreach ($path in $InputPath) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Input image is missing: $path"
    }
    $resolvedInput = (Resolve-Path -LiteralPath $path).ProviderPath
    if (-not (Test-PathInside -Child $resolvedInput -Parent $candidateRoot)) {
        throw "Contact-sheet input must stay below art/candidates: $resolvedInput"
    }
    $inputRelative = [IO.Path]::GetRelativePath($repositoryRoot, $resolvedInput).Replace('\', '/')
    if ($inputRelative.StartsWith('art/candidates/_quarantine/', [StringComparison]::OrdinalIgnoreCase)) {
        throw "Quarantined images cannot enter a contact sheet: $inputRelative"
    }
    $resolvedInputs.Add($resolvedInput)
}
if ($resolvedInputs.Count -eq 0) {
    throw 'At least one input image is required.'
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
        throw 'Contact-sheet labels cannot be blank.'
    }
    if ($candidateLabel.Length -gt 48) {
        throw "Contact-sheet label exceeds 48 characters: $candidateLabel"
    }
}
if (@($labels | ForEach-Object { $_.ToLowerInvariant() } | Group-Object | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
    throw 'Contact-sheet labels must be unique (case-insensitive).'
}
$cellWidth = [int][Math]::Max(420, $ThumbnailHeight * 1.45)
$labelHeight = 58
$titleHeight = if ([string]::IsNullOrWhiteSpace($Title)) { $Padding } else { 74 }
$rows = [int][Math]::Ceiling($resolvedInputs.Count / [double]$Columns)
$sheetWidth = ($Columns * $cellWidth) + (($Columns + 1) * $Padding)
$sheetHeight = $titleHeight + ($rows * ($ThumbnailHeight + $labelHeight + $Padding)) + $Padding
$sheet = [Drawing.Bitmap]::new($sheetWidth, $sheetHeight, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
$graphics = [Drawing.Graphics]::FromImage($sheet)
$titleFont = [Drawing.Font]::new('Segoe UI', 24, [Drawing.FontStyle]::Bold, [Drawing.GraphicsUnit]::Pixel)
$labelFont = [Drawing.Font]::new('Segoe UI', 19, [Drawing.FontStyle]::Regular, [Drawing.GraphicsUnit]::Pixel)
$titleBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 61, 70, 55))
$labelBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 74, 80, 67))
$cellBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 245, 241, 225))
$cellPen = [Drawing.Pen]::new([Drawing.Color]::FromArgb(255, 190, 198, 170), 2)
$outputParent = [IO.Path]::GetDirectoryName($outputFullPath)
$mappingFullPath = [IO.Path]::ChangeExtension($outputFullPath, '.mapping.json')
$temporarySuffix = [Guid]::NewGuid().ToString('N')
$temporaryOutputPath = Join-Path $outputParent ".$([IO.Path]::GetFileName($outputFullPath)).$temporarySuffix.tmp"
$temporaryMappingPath = Join-Path $outputParent ".$([IO.Path]::GetFileName($mappingFullPath)).$temporarySuffix.tmp"
try {
    $graphics.Clear([Drawing.Color]::FromArgb(255, 226, 234, 213))
    $graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::HighQuality
    $graphics.PixelOffsetMode = [Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    if (-not [string]::IsNullOrWhiteSpace($Title)) {
        $graphics.DrawString($Title, $titleFont, $titleBrush, [float]$Padding, [float]18)
    }

    for ($index = 0; $index -lt $resolvedInputs.Count; $index += 1) {
        $column = $index % $Columns
        $row = [int][Math]::Floor($index / [double]$Columns)
        $cellX = $Padding + ($column * ($cellWidth + $Padding))
        $cellY = $titleHeight + ($row * ($ThumbnailHeight + $labelHeight + $Padding))
        $cellRectangle = [Drawing.Rectangle]::new($cellX, $cellY, $cellWidth, $ThumbnailHeight + $labelHeight)
        $graphics.FillRectangle($cellBrush, $cellRectangle)
        $graphics.DrawRectangle($cellPen, $cellRectangle)

        $image = [Drawing.Image]::FromFile($resolvedInputs[$index])
        try {
            $maximumWidth = $cellWidth - (2 * $Padding)
            $scale = [Math]::Min($maximumWidth / [double]$image.Width, $ThumbnailHeight / [double]$image.Height)
            $drawWidth = [int][Math]::Round($image.Width * $scale)
            $drawHeight = [int][Math]::Round($image.Height * $scale)
            $drawX = $cellX + [int](($cellWidth - $drawWidth) / 2)
            $drawY = $cellY + [int](($ThumbnailHeight - $drawHeight) / 2)
            $graphics.DrawImage($image, $drawX, $drawY, $drawWidth, $drawHeight)
        }
        finally {
            $image.Dispose()
        }

        $labelSize = $graphics.MeasureString($labels[$index], $labelFont)
        $labelX = $cellX + [float](($cellWidth - $labelSize.Width) / 2)
        $labelY = $cellY + $ThumbnailHeight + 14
        $graphics.DrawString($labels[$index], $labelFont, $labelBrush, $labelX, [float]$labelY)
    }

    New-Item -ItemType Directory -Path $outputParent -Force | Out-Null
    $sheet.Save($temporaryOutputPath, [Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $cellPen.Dispose()
    $cellBrush.Dispose()
    $labelBrush.Dispose()
    $titleBrush.Dispose()
    $labelFont.Dispose()
    $titleFont.Dispose()
    $graphics.Dispose()
    $sheet.Dispose()
}

try {
    $mappingItems = for ($index = 0; $index -lt $resolvedInputs.Count; $index += 1) {
        [ordered]@{
            index = $index
            label = $labels[$index]
            file_path = [IO.Path]::GetRelativePath($repositoryRoot, $resolvedInputs[$index]).Replace('\', '/')
            sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $resolvedInputs[$index]).Hash.ToLowerInvariant()
        }
    }
    $mapping = [ordered]@{
        schema_version = 1
        output_path = $outputRelativePath
        output_sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $temporaryOutputPath).Hash.ToLowerInvariant()
        width = $sheetWidth
        height = $sheetHeight
        columns = $Columns
        thumbnail_height = $ThumbnailHeight
        candidates = @($mappingItems)
    }
    $mapping | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $temporaryMappingPath -Encoding utf8
    Move-Item -LiteralPath $temporaryOutputPath -Destination $outputFullPath -Force
    Move-Item -LiteralPath $temporaryMappingPath -Destination $mappingFullPath -Force
}
catch {
    foreach ($temporaryPath in @($temporaryOutputPath, $temporaryMappingPath)) {
        if (Test-Path -LiteralPath $temporaryPath) {
            Remove-Item -LiteralPath $temporaryPath -Force
        }
    }
    throw
}

[Console]::WriteLine(
    "[contact-sheet] PASS: $outputRelativePath + mapping ($sheetWidth x $sheetHeight, $($resolvedInputs.Count) candidates)"
)
exit 0
