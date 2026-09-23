[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$candidateDirectory = Join-Path $root 'art/candidates/npc_river_residents_v001'
$candidateManifest = Join-Path $candidateDirectory 'CANDIDATE_MANIFEST.csv'
$globalManifest = Join-Path $root 'docs/production/ASSET_MANIFEST.csv'
$prompts = Join-Path $candidateDirectory 'PROMPTS.md'
$review = Join-Path $candidateDirectory 'REVIEW.md'
$pngValidator = Join-Path $PSScriptRoot 'validate_png_assets.ps1'
$quarantineManifest = Join-Path $root 'art/candidates/_quarantine/player_capybara_v1_unverified_reference/QUARANTINE_MANIFEST.csv'
$prefix = 'art/candidates/npc_river_residents_v001/'

try {
    foreach ($required in @($candidateManifest, $globalManifest, $prompts, $review, $pngValidator, $quarantineManifest)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing NPC provenance input: $required" }
    }
    $globalRows = @(Import-Csv -LiteralPath $globalManifest | Where-Object { $_.asset_id -eq 'river_npc_first_round_v001' })
    if ($globalRows.Count -ne 1) { throw 'NPC family must have exactly one global asset registration.' }
    $global = $globalRows[0]
    if ($global.category -ne 'character' -or $global.status -ne 'visual_concept' -or
        $global.source_method -ne 'ai_assisted' -or $global.reference_asset_ids -ne 'NONE_TEXT_ONLY' -or
        $global.source_path -ne ($prefix + 'CANDIDATE_MANIFEST.csv') -or $global.game_path -or
        $global.alpha_required -ne 'yes' -or $global.license_or_rights -notmatch 'text.only') {
        throw 'Global NPC family registration violates unapproved text-only scope.'
    }
    $rows = @(Import-Csv -LiteralPath $candidateManifest)
    if ($rows.Count -lt 4 -or $rows.Count -gt 12) { throw "NPC concept family requires 4-12 candidates; found $($rows.Count)." }
    foreach ($field in @('reference_asset_ids', 'reference_path', 'reference_sha256', 'rights_status', 'visual_review_status')) {
        if ($field -notin $rows[0].PSObject.Properties.Name) { throw "NPC manifest missing provenance column: $field" }
    }
    $existing = @(Get-ChildItem -LiteralPath $candidateDirectory -File -Filter '*.png' | ForEach-Object { $_.Name })
    if ($existing.Count -ne $rows.Count) { throw 'Every NPC candidate PNG must have exactly one manifest row.' }
    $quarantineHashes = @((Import-Csv -LiteralPath $quarantineManifest) | ForEach-Object { ([string]$_.sha256).ToLowerInvariant() })
    $promptText = Get-Content -LiteralPath $prompts -Raw
    $seenIds = @{}
    $seenPaths = @{}
    $checkedPaths = [Collections.Generic.List[string]]::new()
    foreach ($row in $rows) {
        $id = [string]$row.candidate_id
        if ($id -notmatch '^NPC-[A-Z0-9]+$' -or $seenIds.ContainsKey($id)) { throw "Duplicate or malformed NPC candidate ID: $id" }
        $seenIds[$id] = $true
        $path = ([string]$row.file_path).Replace('\', '/')
        if (-not $path.StartsWith($prefix, [StringComparison]::Ordinal) -or
            $path.Substring($prefix.Length) -notmatch '^npc_[a-z0-9_]+_v[0-9]{3}\.png$' -or
            $seenPaths.ContainsKey($path)) { throw "Unsafe or duplicate NPC file_path: $path" }
        $seenPaths[$path] = $true
        $file = Join-Path $root $path
        if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "Missing NPC candidate: $path" }
        if ($row.raw_path -notmatch '^art/generated_raw/npc/[a-z0-9_/]+\.png$' -or
            $row.prompt_record_path -ne ($prefix + 'PROMPTS.md') -or
            $row.review_record_path -ne ($prefix + 'REVIEW.md') -or
            $row.status -ne 'visual_concept' -or
            $row.alpha_required -ne 'yes' -or $row.game_path) {
            throw "NPC provenance or lifecycle violation: $id"
        }
        if ($row.reference_asset_ids -eq 'NONE_TEXT_ONLY') {
            if ($row.source_method -ne 'ai_assisted' -or $row.rights_status -ne 'original_project_text_only' -or
                $row.reference_path -or $row.reference_sha256) { throw "NPC text-only provenance mismatch: $id" }
        }
        else {
            $parentId = [string]$row.reference_asset_ids
            $parents = @($rows | Where-Object { $_.candidate_id -eq $parentId })
            if ($parentId -eq $id -or -not $seenIds.ContainsKey($parentId) -or $parents.Count -ne 1 -or
                $row.source_method -ne 'ai_assisted_edit' -or $row.rights_status -ne 'original_project_clean_lineage' -or
                $row.reference_path -ne $parents[0].file_path -or $row.reference_sha256 -ne $parents[0].sha256 -or
                $parents[0].status -ne 'visual_concept') {
                throw "NPC edited candidate lacks an earlier exact clean parent: $id"
            }
        }
        if ($row.visual_review_status -notin @('primary_shortlist_unapproved', 'backup_shortlist_unapproved', 'hold_unapproved', 'second_round_unapproved')) {
            throw "NPC concept has unsupported visual state: $id"
        }
        if ($row.prompt_id -ne $id -or $promptText -notmatch ('(?m)^## ' + [regex]::Escape($id) + '\s*$')) {
            throw "Missing exact prompt section for $id"
        }
        $stamp = [DateTimeOffset]::MinValue
        if (-not [DateTimeOffset]::TryParse([string]$row.recorded_at_utc, [ref]$stamp)) { throw "NPC recorded_at_utc invalid: $id" }
        if ($row.sha256 -notmatch '^[a-f0-9]{64}$' -or $row.sha256 -in $quarantineHashes -or
            (Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash.ToLowerInvariant() -ne $row.sha256) {
            throw "NPC candidate hash or rights quarantine mismatch: $id"
        }
        $width = 0
        $height = 0
        if (-not [int]::TryParse([string]$row.width, [ref]$width) -or
            -not [int]::TryParse([string]$row.height, [ref]$height) -or
            $width -lt 1000 -or $height -lt 1000 -or $row.pixel_format -ne 'Format32bppArgb') {
            throw "NPC dimensions or pixel format declaration invalid: $id"
        }
        $checkedPaths.Add($file)
    }
    foreach ($filename in $existing) {
        if (-not $seenPaths.ContainsKey($prefix + $filename)) { throw "Unregistered NPC PNG: $filename" }
    }
    & $pngValidator -Path @($checkedPaths.ToArray()) -MinimumWidth 1000 -MinimumHeight 1000 `
        -RequireAlpha -MinimumTransparentPadding 1 -MaximumAllowedBorderAlpha 1 -ManifestPath $candidateManifest
    if ($LASTEXITCODE -ne 0) { throw 'NPC PNG Alpha/dimension check failed.' }
    foreach ($row in $rows) {
        $file = Join-Path $root $row.file_path
        $inspection = [Capybara.Art.PngInspector]::Inspect($file)
        if ($inspection.Width -ne [int]$row.width -or $inspection.Height -ne [int]$row.height -or
            $inspection.PixelFormat -ne $row.pixel_format) { throw "NPC exact dimensions/pixel format mismatch: $($row.candidate_id)" }
    }
    [Console]::WriteLine("[npc-concepts] PASS: $($rows.Count) unapproved clean text-only/edited concepts; exact hashes, RGBA, parent chain, prompts, rights and no game paths verified.")
    exit 0
}
catch {
    [Console]::Error.WriteLine("[npc-concepts] FAIL: $($_.Exception.Message)")
    exit 22
}
