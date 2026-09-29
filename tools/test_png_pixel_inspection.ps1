[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$run = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-p' + $PID
$output = Join-Path $root ('build/art-pipeline/png-pixel-fixtures/' + $run)
New-Item -ItemType Directory -Path $output | Out-Null
$results = [Collections.Generic.List[object]]::new()

try {
    if (-not ('Capybara.Art.PngInspector' -as [type])) {
        & (Join-Path $PSScriptRoot 'check_player_paintover_candidate.ps1')
        if ($LASTEXITCODE -ne 0) { throw 'Could not initialize source-pixel inspector.' }
    }
    foreach ($dpi in @(72, 96, 300)) {
        $path = Join-Path $output ('dpi_' + $dpi + '_v001.png')
        $bitmap = [Drawing.Bitmap]::new(128, 128, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $bitmap.SetResolution($dpi, $dpi)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.PageUnit = [Drawing.GraphicsUnit]::Pixel
            $graphics.Clear([Drawing.Color]::Transparent)
            $graphics.FillRectangle([Drawing.Brushes]::CornflowerBlue, 40, 40, 60, 60)
            $bitmap.Save($path, [Drawing.Imaging.ImageFormat]::Png)
        } finally { $graphics.Dispose(); $bitmap.Dispose() }
        $actual = [Capybara.Art.PngInspector]::Inspect($path)
        if ($actual.MaximumBorderAlpha -ne 0 -or $actual.ContentLeft -ne 40 -or
            $actual.ContentTop -ne 40 -or $actual.ContentRightExclusive -ne 100 -or
            $actual.ContentBottomExclusive -ne 100 -or $actual.OpaquePixelCount -ne 3600 -or
            $actual.TransparentPixelCount -ne 12784) { throw "DPI $dpi changed source pixels." }
        $results.Add([pscustomobject]@{ case_id = "dpi_$dpi"; passed = $true; observed = $actual })
    }
    $real = [Capybara.Art.PngInspector]::Inspect((Join-Path $root 'art/candidates/player_v003_paintover_v001/native_target_v003.png'))
    if ($real.Width -ne 512 -or $real.Height -ne 512 -or $real.MaximumBorderAlpha -ne 0 -or
        $real.TransparentPixelCount -le 0 -or -not $real.HasAlphaPixelFormat) { throw 'Real Blender Alpha regression.' }
    $results.Add([pscustomobject]@{ case_id = 'real_blender_72dpi'; passed = $true; observed = $real })
    foreach ($kind in @('opaque_rgb', 'touched_border', 'empty_rgba')) {
        $path = Join-Path $output ($kind + '_v001.png')
        $format = if ($kind -eq 'opaque_rgb') { [Drawing.Imaging.PixelFormat]::Format24bppRgb } else { [Drawing.Imaging.PixelFormat]::Format32bppArgb }
        $bitmap = [Drawing.Bitmap]::new(128, 128, $format)
        $graphics = [Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.Clear([Drawing.Color]::Transparent)
            if ($kind -eq 'opaque_rgb') { $graphics.Clear([Drawing.Color]::CornflowerBlue) }
            if ($kind -eq 'touched_border') { $bitmap.SetPixel(0, 0, [Drawing.Color]::CornflowerBlue) }
            $bitmap.Save($path, [Drawing.Imaging.ImageFormat]::Png)
        } finally { $graphics.Dispose(); $bitmap.Dispose() }
        $actual = [Capybara.Art.PngInspector]::Inspect($path)
        if ($kind -eq 'opaque_rgb' -and ($actual.HasAlphaPixelFormat -or $actual.MinimumAlpha -ne 255 -or $actual.OpaquePixelCount -ne 16384)) {
            throw 'Opaque RGB must not acquire false transparency.'
        }
        if ($kind -eq 'touched_border' -and ($actual.MaximumBorderAlpha -ne 255 -or $actual.ContentLeft -ne 0 -or $actual.ContentTop -ne 0)) {
            throw 'A real occupied border must remain detectable.'
        }
        if ($kind -eq 'empty_rgba' -and ($actual.VisibleContentPixelCount -ne 0 -or $actual.OpaquePixelCount -ne 0 -or $actual.TransparentPixelCount -ne 16384)) {
            throw 'An empty sprite must remain detectable.'
        }
        $results.Add([pscustomobject]@{ case_id = $kind; passed = $true; observed = $actual })
    }
    $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $output 'results.json') -Encoding utf8
    [Console]::WriteLine("[png-pixel-fixture] PASS: 7/7; source Alpha independent of DPI; opaque/occupied/empty cases retained; $output")
    exit 0
} catch {
    [Console]::Error.WriteLine('[png-pixel-fixture] FAIL: ' + $_.Exception.Message)
    exit 22
}
