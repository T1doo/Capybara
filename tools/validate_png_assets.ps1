[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Path,

    [ValidateRange(0, 16384)]
    [int]$ExpectedWidth = 0,

    [ValidateRange(0, 16384)]
    [int]$ExpectedHeight = 0,

    [ValidateRange(0, 16384)]
    [int]$MinimumWidth = 0,

    [ValidateRange(0, 16384)]
    [int]$MinimumHeight = 0,

    [switch]$RequireAlpha,

    [ValidateRange(0, 1024)]
    [int]$MinimumTransparentPadding = 1,

    [ValidateRange(0, 255)]
    [int]$MaximumAllowedBorderAlpha = 1,

    [string]$ManifestPath,

    [string]$JsonOutputPath,

    [switch]$SkipNameCheck,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$AdditionalPath = @()
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$Path = @($Path) + @($AdditionalPath)
if ([string]::IsNullOrWhiteSpace($ManifestPath)) {
    $ManifestPath = Join-Path $repositoryRoot 'docs\production\ASSET_MANIFEST.csv'
}

if (-not ('Capybara.Art.PngInspector' -as [type])) {
    Add-Type -AssemblyName System.Drawing
    $drawingAssemblyPath = [Drawing.Bitmap].Assembly.Location
    $drawingPrimitiveAssemblyPath = [Drawing.Color].Assembly.Location
    $gdiPlusAssemblyPath = Join-Path $PSHOME 'System.Private.Windows.GdiPlus.dll'
    $windowsCoreAssemblyPath = Join-Path $PSHOME 'System.Private.Windows.Core.dll'
    Add-Type -ReferencedAssemblies @(
        $drawingAssemblyPath,
        $drawingPrimitiveAssemblyPath,
        $gdiPlusAssemblyPath,
        $windowsCoreAssemblyPath
    ) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;

namespace Capybara.Art {
    public sealed class PngInspection {
        public int Width { get; set; }
        public int Height { get; set; }
        public string PixelFormat { get; set; }
        public bool IsPng { get; set; }
        public bool HasAlphaPixelFormat { get; set; }
        public int MinimumAlpha { get; set; }
        public int MaximumAlpha { get; set; }
        public int MaximumBorderAlpha { get; set; }
        public long TransparentPixelCount { get; set; }
        public long ContentPixelCount { get; set; }
        public long VisibleContentPixelCount { get; set; }
        public long OpaquePixelCount { get; set; }
        public int ContentLeft { get; set; }
        public int ContentTop { get; set; }
        public int ContentRightExclusive { get; set; }
        public int ContentBottomExclusive { get; set; }
    }

    public static class PngInspector {
        public static PngInspection Inspect(string path) {
            using (var source = new Bitmap(path)) {
                var result = new PngInspection {
                    Width = source.Width,
                    Height = source.Height,
                    PixelFormat = source.PixelFormat.ToString(),
                    IsPng = source.RawFormat.Guid == ImageFormat.Png.Guid,
                    HasAlphaPixelFormat = Image.IsAlphaPixelFormat(source.PixelFormat),
                    MinimumAlpha = 255,
                    MaximumAlpha = 0,
                    MaximumBorderAlpha = 0,
                    ContentLeft = source.Width,
                    ContentTop = source.Height,
                    ContentRightExclusive = 0,
                    ContentBottomExclusive = 0
                };

                using (var normalized = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb)) {
                    using (var graphics = Graphics.FromImage(normalized)) {
                        graphics.Clear(Color.Transparent);
                        graphics.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceCopy;
                        graphics.DrawImageUnscaled(source, 0, 0);
                    }

                    var rectangle = new Rectangle(0, 0, normalized.Width, normalized.Height);
                    var data = normalized.LockBits(rectangle, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
                    try {
                        int absoluteStride = Math.Abs(data.Stride);
                        var bytes = new byte[absoluteStride * normalized.Height];
                        Marshal.Copy(data.Scan0, bytes, 0, bytes.Length);
                        for (int y = 0; y < normalized.Height; y++) {
                            int row = data.Stride >= 0 ? y * absoluteStride : (normalized.Height - 1 - y) * absoluteStride;
                            for (int x = 0; x < normalized.Width; x++) {
                                int alpha = bytes[row + (x * 4) + 3];
                                if (alpha < result.MinimumAlpha) result.MinimumAlpha = alpha;
                                if (alpha > result.MaximumAlpha) result.MaximumAlpha = alpha;
                                if (x == 0 || y == 0 || x == normalized.Width - 1 || y == normalized.Height - 1) {
                                    if (alpha > result.MaximumBorderAlpha) result.MaximumBorderAlpha = alpha;
                                }
                                if (alpha == 0) {
                                    result.TransparentPixelCount++;
                                } else {
                                    result.ContentPixelCount++;
                                }
                                if (alpha > 1) {
                                    result.VisibleContentPixelCount++;
                                    if (x < result.ContentLeft) result.ContentLeft = x;
                                    if (y < result.ContentTop) result.ContentTop = y;
                                    if (x + 1 > result.ContentRightExclusive) result.ContentRightExclusive = x + 1;
                                    if (y + 1 > result.ContentBottomExclusive) result.ContentBottomExclusive = y + 1;
                                }
                                if (alpha >= 250) result.OpaquePixelCount++;
                            }
                        }
                    } finally {
                        normalized.UnlockBits(data);
                    }
                }
                return result;
            }
        }
    }
}
'@
}

function Convert-ToRepositoryPath {
    param([Parameter(Mandatory = $true)][string]$FullPath)

    return [IO.Path]::GetRelativePath($repositoryRoot, $FullPath).Replace('\', '/')
}

function Test-PathInside {
    param(
        [Parameter(Mandatory = $true)][string]$Child,
        [Parameter(Mandatory = $true)][string]$Parent
    )

    $normalizedChild = [IO.Path]::GetFullPath($Child)
    $normalizedParent = [IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    return $normalizedChild.StartsWith($normalizedParent, [StringComparison]::OrdinalIgnoreCase)
}

function Test-ManifestRegistration {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][object[]]$Rows
    )

    foreach ($row in $Rows) {
        foreach ($fieldName in @('file_path', 'raw_path', 'source_path', 'game_path')) {
            $registeredPath = [string]$row.$fieldName
            if ([string]::IsNullOrWhiteSpace($registeredPath)) {
                continue
            }
            $registeredPath = $registeredPath.Replace('\', '/')
            if ($RelativePath.Equals($registeredPath, [StringComparison]::OrdinalIgnoreCase)) {
                return $true
            }
        }
    }
    return $false
}

$failures = [System.Collections.Generic.List[string]]::new()
$results = [System.Collections.Generic.List[object]]::new()
$seenHashes = @{}
$manifestRows = @()
if (-not (Test-Path -LiteralPath $ManifestPath -PathType Leaf)) {
    $failures.Add("Manifest is missing: $ManifestPath")
}
else {
    $manifestRows = @(Import-Csv -LiteralPath $ManifestPath)
    if ($manifestRows.Count -eq 0) {
        $failures.Add("Manifest contains no asset rows: $ManifestPath")
    }
}

foreach ($inputPath in $Path) {
    if (-not (Test-Path -LiteralPath $inputPath -PathType Leaf)) {
        $failures.Add("File is missing: $inputPath")
        continue
    }
    $fullPath = (Resolve-Path -LiteralPath $inputPath).ProviderPath
    $relativePath = Convert-ToRepositoryPath -FullPath $fullPath
    if ($relativePath.StartsWith('../') -or [IO.Path]::IsPathRooted($relativePath)) {
        $failures.Add("PNG must stay inside the repository: $fullPath")
    }
    if (-not [IO.Path]::GetExtension($fullPath).Equals('.png', [StringComparison]::OrdinalIgnoreCase)) {
        $failures.Add("Not a .png file: $relativePath")
        continue
    }
    if (-not $SkipNameCheck -and
        [IO.Path]::GetFileName($fullPath) -notmatch '^[a-z0-9_]+_v[0-9]{3}\.png$') {
        $failures.Add("Filename does not match the asset naming convention: $relativePath")
    }

    try {
        $inspection = [Capybara.Art.PngInspector]::Inspect($fullPath)
    }
    catch {
        $failures.Add("PNG cannot be opened: ${relativePath}: $($_.Exception.Message)")
        continue
    }
    if (-not $inspection.IsPng) {
        $failures.Add("File extension is PNG but encoded format is different: $relativePath")
    }
    if ($ExpectedWidth -gt 0 -and $inspection.Width -ne $ExpectedWidth) {
        $failures.Add("Unexpected width for ${relativePath}: $($inspection.Width), expected $ExpectedWidth")
    }
    if ($ExpectedHeight -gt 0 -and $inspection.Height -ne $ExpectedHeight) {
        $failures.Add("Unexpected height for ${relativePath}: $($inspection.Height), expected $ExpectedHeight")
    }
    if ($MinimumWidth -gt 0 -and $inspection.Width -lt $MinimumWidth) {
        $failures.Add("Image is too narrow: ${relativePath} ($($inspection.Width), minimum $MinimumWidth)")
    }
    if ($MinimumHeight -gt 0 -and $inspection.Height -lt $MinimumHeight) {
        $failures.Add("Image is too short: ${relativePath} ($($inspection.Height), minimum $MinimumHeight)")
    }
    if ($inspection.VisibleContentPixelCount -eq 0) {
        $failures.Add("Image has no visible content: $relativePath")
    }
    if ($inspection.OpaquePixelCount -eq 0) {
        $failures.Add("Image has no substantially opaque pixels: $relativePath")
    }
    if ($RequireAlpha) {
        if (-not $inspection.HasAlphaPixelFormat) {
            $failures.Add("Image does not use an alpha pixel format: ${relativePath} ($($inspection.PixelFormat))")
        }
        if ($inspection.TransparentPixelCount -eq 0) {
            $failures.Add("Image has no fully transparent pixels: $relativePath")
        }
        if ($inspection.MaximumBorderAlpha -gt $MaximumAllowedBorderAlpha) {
            $failures.Add("Image border exceeds allowed alpha: ${relativePath} (max $($inspection.MaximumBorderAlpha), allowed $MaximumAllowedBorderAlpha)")
        }
        if ($inspection.VisibleContentPixelCount -gt 0 -and $MinimumTransparentPadding -gt 0) {
            $rightPadding = $inspection.Width - $inspection.ContentRightExclusive
            $bottomPadding = $inspection.Height - $inspection.ContentBottomExclusive
            if ($inspection.ContentLeft -lt $MinimumTransparentPadding -or
                $inspection.ContentTop -lt $MinimumTransparentPadding -or
                $rightPadding -lt $MinimumTransparentPadding -or
                $bottomPadding -lt $MinimumTransparentPadding) {
                $failures.Add("Image content lacks $MinimumTransparentPadding px transparent padding: $relativePath")
            }
        }
    }

    $sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $fullPath).Hash.ToLowerInvariant()
    if ($seenHashes.ContainsKey($sha256)) {
        $failures.Add("Duplicate PNG content: $relativePath and $($seenHashes[$sha256])")
    }
    else {
        $seenHashes[$sha256] = $relativePath
    }
    if ($manifestRows.Count -gt 0 -and -not (Test-ManifestRegistration -RelativePath $relativePath -Rows $manifestRows)) {
        $failures.Add("PNG is not registered in the asset manifest: $relativePath")
    }

    $result = [ordered]@{
        path = $relativePath
        width = $inspection.Width
        height = $inspection.Height
        pixel_format = $inspection.PixelFormat
        has_alpha_pixel_format = $inspection.HasAlphaPixelFormat
        minimum_alpha = $inspection.MinimumAlpha
        maximum_alpha = $inspection.MaximumAlpha
        maximum_border_alpha = $inspection.MaximumBorderAlpha
        transparent_pixels = $inspection.TransparentPixelCount
        content_pixels = $inspection.ContentPixelCount
        visible_content_pixels = $inspection.VisibleContentPixelCount
        opaque_pixels = $inspection.OpaquePixelCount
        content_left = $inspection.ContentLeft
        content_top = $inspection.ContentTop
        content_right_exclusive = $inspection.ContentRightExclusive
        content_bottom_exclusive = $inspection.ContentBottomExclusive
        sha256 = $sha256
    }
    $results.Add([pscustomobject]$result)
    $resultLine = '[png] {0} {1}x{2} {3} border_alpha={4} sha256={5}' -f @(
        $relativePath,
        $inspection.Width,
        $inspection.Height,
        $inspection.PixelFormat,
        $inspection.MaximumBorderAlpha,
        $sha256.Substring(0, 12)
    )
    [Console]::WriteLine($resultLine)
}

$summary = [ordered]@{
    success = ($failures.Count -eq 0)
    checked = $results.Count
    failures = @($failures)
    assets = @($results)
}
if (-not [string]::IsNullOrWhiteSpace($JsonOutputPath)) {
    $jsonFullPath = [IO.Path]::GetFullPath($JsonOutputPath)
    $buildRoot = Join-Path $repositoryRoot 'build'
    $candidateRoot = Join-Path $repositoryRoot 'art\candidates'
    if (-not (Test-PathInside -Child $jsonFullPath -Parent $buildRoot) -and
        -not (Test-PathInside -Child $jsonFullPath -Parent $candidateRoot)) {
        throw 'PNG validation JSON output must stay below build or art/candidates.'
    }
    if (-not [IO.Path]::GetExtension($jsonFullPath).Equals('.json', [StringComparison]::OrdinalIgnoreCase)) {
        throw 'PNG validation JSON output must use the .json extension.'
    }
    $jsonParent = [IO.Path]::GetDirectoryName($jsonFullPath)
    New-Item -ItemType Directory -Path $jsonParent -Force | Out-Null
    $summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $jsonFullPath -Encoding utf8
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        [Console]::Error.WriteLine("[png] FAIL: $failure")
    }
    exit 21
}

[Console]::WriteLine("[png] PASS: $($results.Count) PNG assets verified.")
exit 0
