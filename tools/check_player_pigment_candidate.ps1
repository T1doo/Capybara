[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$prefix = 'art/candidates/player_fur_gouache_v001/'

try {
    $record = Get-Content -LiteralPath (Join-Path $root ($prefix + 'MANIFEST.json')) -Raw | ConvertFrom-Json
    if ($record.asset_id -ne 'player_fur_gouache_a_v001' -or $record.status -ne 'technical_unapproved' -or
        $record.release_approved -ne $false -or $record.game_path -or $record.alpha_required -ne $false -or
        $record.source_method -ne 'ai_generated_text_only' -or $record.rights_status -ne 'clean_text_only' -or
        $record.reference_asset_ids.Count -ne 0 -or $record.reference_image_paths.Count -ne 0) {
        throw 'Pigment source must remain an unapproved text-only material with no game path.'
    }
    if ($record.candidate_path -ne ($prefix + 'fur_gouache_a_v001.png') -or
        $record.prompt_record -ne ($prefix + 'PROMPTS.md') -or $record.sha256 -notmatch '^[a-f0-9]{64}$') {
        throw 'Invalid registered material source path/hash.'
    }
    $path = Join-Path $root $record.candidate_path
    $actual = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $record.sha256) { throw 'Material bytes differ from the recorded original.' }
    $quarantine = @(Import-Csv -LiteralPath (Join-Path $root 'art/candidates/_quarantine/player_capybara_v1_unverified_reference/QUARANTINE_MANIFEST.csv'))
    if ($actual -in $quarantine.sha256) { throw 'Quarantined image hash rejected.' }
    $prompt = Get-Content -LiteralPath (Join-Path $root $record.prompt_record) -Raw
    if (-not $prompt.Contains($record.prompt_id) -or -not $prompt.Contains($actual)) { throw 'Prompt provenance missing.' }
    Add-Type -AssemblyName System.Drawing
    $bitmap = [Drawing.Bitmap]::new($path)
    try {
        if ($bitmap.Width -ne 1254 -or $bitmap.Height -ne 1254 -or
            $record.width -ne $bitmap.Width -or $record.height -ne $bitmap.Height -or
            $bitmap.PixelFormat -ne [Drawing.Imaging.PixelFormat]::Format24bppRgb) {
            throw 'Expected original opaque 1254 square RGB material.'
        }
    } finally { $bitmap.Dispose() }
    $global = @(Import-Csv -LiteralPath (Join-Path $root 'docs/production/ASSET_MANIFEST.csv') |
        Where-Object { $_.asset_id -eq $record.asset_id })
    if ($global.Count -ne 1 -or $global[0].source_path -ne $record.candidate_path -or
        $global[0].game_path -or $global[0].status -ne $record.status -or
        $global[0].source_method -ne $record.source_method -or $global[0].alpha_required -ne 'no') {
        throw 'Global registration differs from the held candidate.'
    }
    [Console]::WriteLine('[player-pigment] PASS: original RGB hash/dimensions/text-only provenance; unapproved; no game path.')
    exit 0
} catch {
    [Console]::Error.WriteLine('[player-pigment] FAIL: ' + $_.Exception.Message)
    exit 22
}
