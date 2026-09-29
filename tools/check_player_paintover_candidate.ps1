[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$prefix = 'art/candidates/player_v003_paintover_v001/'

try {
    $record = Get-Content -LiteralPath (Join-Path $root ($prefix + 'MANIFEST.json')) -Raw | ConvertFrom-Json
    if ($record.status -ne 'technical_unapproved' -or $record.game_path -or
        $record.rights_status -ne 'original_project_clean_lineage' -or $record.source_method -ne 'ai_assisted_edit') {
        throw 'Paintover must remain an unapproved clean project edit with no game path.'
    }
    $expected = @(($prefix + 'native_target_v003.png'), ($prefix + 'paintover_a_v001.png'),
        'art/candidates/player_ag4_v001/chr_player_ag4_down_right_v001.png')
    $inputs = @($record.native_target, $record.paintover, $record.style_reference)
    $quarantine = @(Import-Csv -LiteralPath (Join-Path $root 'art/candidates/_quarantine/player_capybara_v1_unverified_reference/QUARANTINE_MANIFEST.csv'))
    for ($i = 0; $i -lt $inputs.Count; $i++) {
        $entry = $inputs[$i]
        if ($entry.path -ne $expected[$i] -or $entry.sha256 -notmatch '^[a-f0-9]{64}$') { throw 'Unexpected paintover source path/hash.' }
        $hash = (Get-FileHash -LiteralPath (Join-Path $root $entry.path) -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($hash -ne $entry.sha256 -or $hash -in $quarantine.sha256) { throw 'Source changed or quarantined.' }
    }
    if ($record.native_source_script -ne 'tools/art/probe_player_shape_v003.py') { throw 'Unexpected native generator.' }
    $sourceHash = (Get-FileHash -LiteralPath (Join-Path $root $record.native_source_script) -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($sourceHash -ne $record.native_source_script_sha256) { throw 'Frozen native generator hash changed.' }
    $validationDirectory = Join-Path $root ('build/art-pipeline/paintover-check/' + [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-p' + $PID)
    New-Item -ItemType Directory -Path $validationDirectory | Out-Null
    $validationManifest = Join-Path $validationDirectory 'derived_png_paths.csv'
    @($record.native_target, $record.paintover) | ForEach-Object {
        [pscustomobject]@{ file_path = $_.path }
    } | Export-Csv -LiteralPath $validationManifest -NoTypeInformation -Encoding utf8
    & (Join-Path $PSScriptRoot 'validate_png_assets.ps1') -Path (Join-Path $root $record.native_target.path) -ExpectedWidth 512 -ExpectedHeight 512 -RequireAlpha -ManifestPath $validationManifest
    if ($LASTEXITCODE -ne 0) { throw 'Native target PNG failed.' }
    & (Join-Path $PSScriptRoot 'validate_png_assets.ps1') -Path (Join-Path $root $record.paintover.path) -ExpectedWidth 1254 -ExpectedHeight 1254 -RequireAlpha -ManifestPath $validationManifest
    if ($LASTEXITCODE -ne 0) { throw 'Paintover PNG failed.' }
    if ($record.prompt_record -ne ($prefix + 'PROMPTS.md') -or $record.review_record -ne ($prefix + 'REVIEW.md')) { throw 'Unexpected provenance documents.' }
    $prompt = Get-Content -LiteralPath (Join-Path $root $record.prompt_record) -Raw
    if (-not $prompt.Contains($record.prompt_id)) { throw 'Exact prompt record missing.' }
    foreach ($entry in $inputs) {
        if (-not $prompt.Contains($entry.sha256)) { throw 'Prompt source hash missing.' }
    }
    if (-not (Test-Path -LiteralPath (Join-Path $root $record.review_record))) { throw 'Review missing.' }
    $global = @(Import-Csv -LiteralPath (Join-Path $root 'docs/production/ASSET_MANIFEST.csv') |
        Where-Object { $_.asset_id -eq $record.asset_id })
    if ($global.Count -ne 1 -or $global[0].source_path -ne ($prefix + 'MANIFEST.json') -or
        $global[0].game_path -or $global[0].status -ne $record.status) { throw 'Global scope mismatch.' }
    [Console]::WriteLine('[paintover] PASS: exact native/paint/style hashes, frozen generator, RGBA and unapproved scope; no geometry/quality approval.')
    exit 0
} catch {
    [Console]::Error.WriteLine('[paintover] FAIL: ' + $_.Exception.Message)
    exit 22
}
