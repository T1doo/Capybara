[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string[]]$ManifestPath,
    [Parameter(Mandatory = $true)][string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$buildRoot = Join-Path $repositoryRoot 'build'
$output = [IO.Path]::GetFullPath($OutputDirectory)
if (-not $output.StartsWith($buildRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Review output must remain in the ignored build directory.'
}
if (Test-Path -LiteralPath $output) { throw 'Use a new review directory; existing evidence is not overwritten.' }
New-Item -ItemType Directory -Path $output | Out-Null

$drawingReferences = @([AppContext]::GetData('TRUSTED_PLATFORM_ASSEMBLIES') -split [IO.Path]::PathSeparator)
Add-Type -ReferencedAssemblies $drawingReferences -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
public static class CharacterAlphaInspection {
    public static int[] Measure(Bitmap source) {
        { var bmp = source;
            var rect = new Rectangle(0, 0, bmp.Width, bmp.Height);
            var data = bmp.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            try {
                int minX=bmp.Width, minY=bmp.Height, maxX=-1, maxY=-1, count=0, border=0, translucent=0;
                byte[] row=new byte[Math.Abs(data.Stride)];
                for (int y=0; y<bmp.Height; y++) {
                    Marshal.Copy(IntPtr.Add(data.Scan0,y*data.Stride),row,0,row.Length);
                    for(int x=0;x<bmp.Width;x++) {
                        int a=row[x*4+3];
                        if(a>0 && (x==0 || y==0 || x==bmp.Width-1 || y==bmp.Height-1)) border++;
                        if(a>0 && a<255) translucent++;
                        if(a<=8) continue;
                        minX=Math.Min(minX,x); minY=Math.Min(minY,y);
                        maxX=Math.Max(maxX,x); maxY=Math.Max(maxY,y); count++;
                    }
                }
                return new int[]{minX,minY,maxX,maxY,count,border,translucent};
            } finally { bmp.UnlockBits(data); }
        }
    }
}
'@

$frames = [Collections.Generic.List[object]]::new()
$alphaFailures = [Collections.Generic.List[string]]::new()
$referenceCanvas = $null
$referencePivot = $null
foreach ($manifest in $ManifestPath) {
    $manifestFile = (Resolve-Path -LiteralPath $manifest).ProviderPath
    $data = Get-Content -LiteralPath $manifestFile -Raw | ConvertFrom-Json
    if (@($data.canvas).Count -ne 2 -or @($data.pivot).Count -ne 2 -or @($data.frames).Count -eq 0) {
        throw "Invalid character manifest: $manifest"
    }
    $canvasKey = $data.canvas -join ','
    $pivotKey = $data.pivot -join ','
    if ($canvasKey -ne '512,512') { throw 'This fixed-scale board requires a 512 square source canvas.' }
    if ($null -eq $referenceCanvas) { $referenceCanvas=$canvasKey; $referencePivot=$pivotKey }
    if ($referenceCanvas -ne $canvasKey -or $referencePivot -ne $pivotKey -or $data.camera_pitch_degrees -ne 35) {
        throw 'A/B inputs must share canvas, ground pivot and 35 degree camera.'
    }
    foreach ($frame in $data.frames) {
        $path = [IO.Path]::GetFullPath((Join-Path (Split-Path $manifestFile -Parent) $frame.path))
        if (-not $path.StartsWith($buildRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
            throw 'Review only the generated build frames; production and quarantined images are not inputs.'
        }
        $bitmap = [Drawing.Bitmap]::new($path)
        try {
            if ($bitmap.Width -ne $data.canvas[0] -or $bitmap.Height -ne $data.canvas[1]) { throw "Canvas mismatch: $path" }
            $bounds = [CharacterAlphaInspection]::Measure($bitmap)
            if ($bounds[4] -eq 0 -or $bounds[5] -ne 0) { $alphaFailures.Add("Empty or edge-clipped alpha: $path") }
            $frames.Add([pscustomobject]@{
                route=$data.route; direction=$frame.direction; pose=$frame.pose
                file=[IO.Path]::GetRelativePath($repositoryRoot,$path).Replace('\','/')
                sha256=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
                bbox=@($bounds[0],$bounds[1],$bounds[2],$bounds[3]); alpha_pixels=$bounds[4]
                border_alpha_pixels=$bounds[5]; translucent_pixels=$bounds[6]
                body_height_px=$bounds[3]-$bounds[1]+1; ground_pivot=$data.pivot
            })
        } finally { $bitmap.Dispose() }
    }
}

$cellWidth=320; $cellHeight=318; $columns=4
$rows=[int][Math]::Ceiling($frames.Count/[double]$columns)
$sheet=[Drawing.Bitmap]::new($columns*$cellWidth,$rows*$cellHeight)
$graphics=[Drawing.Graphics]::FromImage($sheet)
$font=[Drawing.Font]::new('Segoe UI',10)
$brush=[Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(38,49,45))
$backgrounds=@('#f6f1e5','#202c29','#6a8155','#447c86')
try {
    $graphics.Clear([Drawing.Color]::FromArgb(242,239,230))
    $graphics.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    for($index=0;$index -lt $frames.Count;$index++) {
        $frame=$frames[$index]; $x=($index%$columns)*$cellWidth; $y=[int][Math]::Floor($index/$columns)*$cellHeight
        $background=[Drawing.SolidBrush]::new([Drawing.ColorTranslator]::FromHtml($backgrounds[[int][Math]::Floor($index/$columns)%4]))
        $bitmap=[Drawing.Bitmap]::new((Join-Path $repositoryRoot $frame.file))
        try {
            $graphics.FillRectangle($background,$x+32,$y+6,256,256)
            # Every image has the same fixed 0.5 scale. Never normalize each pose's alpha bounds.
            $graphics.DrawImage($bitmap,[Drawing.Rectangle]::new($x+32,$y+6,256,256))
            $label="$($frame.route) / $($frame.direction) / $($frame.pose)"
            $graphics.DrawString($label,$font,$brush,[float]($x+8),[float]($y+268))
            $graphics.DrawString("body=$($frame.body_height_px)px; scale=0.5; unapproved",$font,$brush,[float]($x+8),[float]($y+287))
        } finally { $bitmap.Dispose(); $background.Dispose() }
    }
    $sheet.Save((Join-Path $output 'fixed_scale_contact_sheet.png'),[Drawing.Imaging.ImageFormat]::Png)
} finally { $graphics.Dispose(); $sheet.Dispose(); $font.Dispose(); $brush.Dispose() }
[ordered]@{
    evidence_kind='technical_comparison_board_not_gameplay'; status='unapproved'
    created_at_utc=[DateTime]::UtcNow.ToString('o'); frame_scale=0.5
    comparison_note='No per-frame crop or normalization. Alpha checks cannot approve visual quality or animation.'
    alpha_failures=@($alphaFailures)
    frames=@($frames)
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $output 'alpha_report.json') -Encoding utf8
if ($alphaFailures.Count -gt 0) { throw "Alpha gate failed ($($alphaFailures.Count) frames); rejected evidence preserved in $output" }
[Console]::WriteLine("[character-review] PASS: $($frames.Count) transparent fixed-canvas frames; visual approval remains manual. Output=$output")
