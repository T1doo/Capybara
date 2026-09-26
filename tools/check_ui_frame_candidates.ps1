[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$candidateDirectory = Join-Path $root 'art/candidates/ui_storybook_frame_v001'
$manifestPath = Join-Path $candidateDirectory 'CANDIDATE_MANIFEST.csv'
$reviewPath = Join-Path $candidateDirectory 'REVIEW.md'
$globalPath = Join-Path $root 'docs/production/ASSET_MANIFEST.csv'
$renderer = Join-Path $PSScriptRoot 'render_svg_preview.ps1'
$prefix = 'art/candidates/ui_storybook_frame_v001/'

try {
    foreach ($required in @($manifestPath, $reviewPath, $globalPath, $renderer)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing original UI frame provenance input: $required" }
    }
    $globalRows = @(Import-Csv -LiteralPath $globalPath | Where-Object { $_.asset_id -eq 'ui_riverstone_frame_v001' })
    if ($globalRows.Count -ne 1) { throw 'UI frame must have exactly one global asset registration.' }
    $global = $globalRows[0]
    if ($global.category -ne 'ui' -or $global.status -ne 'technical_candidate' -or
        $global.source_method -ne 'manual_svg' -or $global.source_path -ne ($prefix + 'CANDIDATE_MANIFEST.csv') -or
        $global.alpha_required -ne 'yes' -or $global.game_path -or
        $global.license_or_rights -notmatch 'original_project_asset') {
        throw 'Global UI frame registration violates original unapproved scope.'
    }
    $rows = @(Import-Csv -LiteralPath $manifestPath)
    if ($rows.Count -ne 2 -or $rows[0].candidate_id -ne 'UI-FRAME-A' -or $rows[1].candidate_id -ne 'UI-FRAME-B') {
        throw 'This two-round UI panel review requires ordered A and B candidates.'
    }
    $svgFiles = @(Get-ChildItem -LiteralPath $candidateDirectory -File -Filter '*.svg')
    if ($svgFiles.Count -ne $rows.Count) { throw 'Every UI frame SVG must have one manifest row.' }
    $runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-p' + $PID
    $buildOutput = Join-Path $root "build/art-pipeline/ui-frame-check/$runId"
    foreach ($row in $rows) {
        $path = ([string]$row.file_path).Replace('\', '/')
        if (-not $path.StartsWith($prefix, [StringComparison]::Ordinal) -or
            $path.Substring($prefix.Length) -notmatch '^panel_riverstone_[ab]_v001\.svg$' -or
            $row.status -ne 'technical_candidate' -or $row.game_path -or
            $row.review_record_path -ne ($prefix + 'REVIEW.md') -or
            $row.width -ne '512' -or $row.height -ne '512' -or $row.alpha_required -ne 'yes' -or
            $row.sha256 -notmatch '^[a-f0-9]{64}$' -or $row.expected_raster_sha256 -notmatch '^[a-f0-9]{64}$') {
            throw "Malformed or promoted UI frame candidate: $($row.candidate_id)"
        }
        $source = Join-Path $root $path
        if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or
            (Get-FileHash -Algorithm SHA256 -LiteralPath $source).Hash.ToLowerInvariant() -ne $row.sha256) {
            throw "UI frame source hash mismatch: $($row.candidate_id)"
        }
        $xmlText = Get-Content -LiteralPath $source -Raw
        if ($xmlText -match '(?i)<\s*(script|image|foreignObject)\b|\b(xlink:)?href\s*=|@import|url\(https?://') {
            throw "UI frame embeds an external or executable resource: $($row.candidate_id)"
        }
        $document = [xml]$xmlText
        if ($document.DocumentElement.LocalName -ne 'svg' -or
            $document.DocumentElement.width -ne '512' -or $document.DocumentElement.height -ne '512') {
            throw "UI frame SVG canvas is not an editable 512x512 source: $($row.candidate_id)"
        }
        if ($row.candidate_id -eq 'UI-FRAME-A') {
            if ($row.source_method -ne 'manual_svg' -or $row.reference_path -or $row.reference_sha256 -or
                $row.rights_status -ne 'original_project_asset' -or $row.visual_review_status -ne 'changes_required') {
                throw 'First UI frame must be original and unapproved.'
            }
        }
        else {
            if ($row.source_method -ne 'manual_svg_revision' -or
                $row.reference_path -ne $rows[0].file_path -or $row.reference_sha256 -ne $rows[0].sha256 -or
                $row.rights_status -ne 'original_project_clean_lineage' -or $row.visual_review_status -ne 'shortlist_unapproved') {
                throw 'Second UI frame must cite exact original A and remain unapproved.'
            }
        }
        $raster = Join-Path $buildOutput ([IO.Path]::GetFileNameWithoutExtension($source) + '.png')
        & $renderer -InputPath $source -OutputPath $raster
        if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $raster -PathType Leaf) -or
            (Get-FileHash -Algorithm SHA256 -LiteralPath $raster).Hash.ToLowerInvariant() -ne $row.expected_raster_sha256) {
            throw "UI frame render or transparent raster hash mismatch: $($row.candidate_id)"
        }
    }
    [Console]::WriteLine('[ui-frame] PASS: 2 original editable SVG rounds; exact source/render hashes, clean parent, RGBA and no game path verified.')
    exit 0
}
catch {
    [Console]::Error.WriteLine("[ui-frame] FAIL: $($_.Exception.Message)")
    exit 22
}
