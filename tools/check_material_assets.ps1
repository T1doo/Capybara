[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$materialRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
Add-Type -AssemblyName System.Drawing

try {
    $assetRows = @(Import-Csv -LiteralPath (Join-Path $materialRoot 'docs/production/ASSET_MANIFEST.csv'))
    foreach ($materialName in @('cottage_materials_v1', 'foliage_material_v1')) {
        $recordPath = Join-Path $materialRoot "art/candidates/environment/$materialName/MANIFEST.json"
        $record = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
        if ($record.status -ne 'prototype_integrated' -or $record.release_approved -ne $false -or
            $record.alpha_required -ne $false -or $record.reference_asset_ids.Count -ne 0 -or
            $record.sha256 -notmatch '^[a-f0-9]{64}$') {
            throw "Invalid material provenance or prototype status: $materialName"
        }
        foreach ($field in @('prompt_record', 'review_record', 'candidate_path', 'approved_path', 'source_path', 'runtime_path')) {
            $relativePath = [string]$record.$field
            $absolutePath = [IO.Path]::GetFullPath((Join-Path $materialRoot $relativePath))
            if ([string]::IsNullOrWhiteSpace($relativePath) -or
                -not $absolutePath.StartsWith($materialRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase) -or
                -not (Test-Path -LiteralPath $absolutePath -PathType Leaf)) {
                throw "Missing or out-of-repository material field: $materialName/$field"
            }
            if ($field -in @('prompt_record', 'review_record')) { continue }
            if ((Get-FileHash -LiteralPath $absolutePath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $record.sha256) {
                throw "Material copy hash differs: $relativePath"
            }
            $materialImage = [Drawing.Image]::FromFile($absolutePath)
            try {
                if ($materialImage.Width -ne $record.width -or $materialImage.Height -ne $record.height -or
                    $materialImage.PixelFormat.ToString() -ne $record.format) {
                    throw "Material dimensions or pixel format differ: $relativePath"
                }
            }
            finally { $materialImage.Dispose() }
        }
        $registered = @($assetRows | Where-Object asset_id -eq $record.asset_id)
        if ($registered.Count -ne 1 -or $registered[0].game_path -ne $record.runtime_path -or
            $registered[0].source_path -ne $record.source_path -or $registered[0].status -ne $record.status -or
            $registered[0].prompt_id -ne $record.prompt_id -or $registered[0].license_or_rights -ne 'original_project_asset') {
            throw "Top-level asset registration differs: $materialName"
        }
        Write-Output "[materials] PASS: $($record.asset_id), 4 identical copies, dimensions, provenance and prototype scope."
    }
    exit 0
}
catch {
    [Console]::Error.WriteLine("[materials] FAIL: $($_.Exception.Message)")
    exit 1
}
