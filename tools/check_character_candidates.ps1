[CmdletBinding()]
param(
    [string[]]$ManifestPath = @(),
    [string]$GlobalManifestPath,
    [string]$JsonOutputPath
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
if (-not $GlobalManifestPath) { $GlobalManifestPath = Join-Path $repositoryRoot 'docs/production/ASSET_MANIFEST.csv' }
$failures = [Collections.Generic.List[string]]::new()
$verified = [Collections.Generic.List[object]]::new()
$hashValidator = Join-Path $PSScriptRoot 'validate_asset_hash.ps1'
$pngValidator = Join-Path $PSScriptRoot 'validate_png_assets.ps1'
$quarantineManifest = Join-Path $repositoryRoot 'art/candidates/_quarantine/player_capybara_v1_unverified_reference/QUARANTINE_MANIFEST.csv'

function Resolve-AssetRecordPath {
    param([string]$Value, [string]$Label)
    if (-not $Value -or [IO.Path]::IsPathRooted($Value) -or $Value -match '(?i)(^|[/\\])_?quarantine([/\\]|$)|USER-SESSION' -or $Value -match '(^|[/\\])\.\.([/\\]|$)') {
        throw "Unsafe or empty $Label path: '$Value'"
    }
    $full = [IO.Path]::GetFullPath((Join-Path $repositoryRoot $Value))
    if (-not $full.StartsWith($repositoryRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw "Escaping $Label path: '$Value'" }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "Missing $Label file: $Value" }
    if ((Get-Item -LiteralPath $full).Length -eq 0) { throw "Empty $Label file: $Value" }
    return $full
}

function Get-RelativeAssetPath {
    param([string]$Path)
    return [IO.Path]::GetRelativePath($repositoryRoot, [IO.Path]::GetFullPath($Path)).Replace('\', '/')
}

function Get-UnregisteredCandidatePaths {
    param([string]$DirectoryPath, [string[]]$ExistingPaths, [string[]]$RegisteredPaths)
    # A manifest owns its immediate directory. Child folders and build QA have their own scope.
    $directory = $DirectoryPath.Replace('\', '/').TrimEnd('/')
    $registered = @{}
    foreach ($path in $RegisteredPaths) { $registered[$path.Replace('\', '/')] = $true }
    foreach ($path in $ExistingPaths) {
        $normalized = $path.Replace('\', '/')
        $separator = $normalized.LastIndexOf('/')
        if ($separator -lt 0 -or $normalized.Substring(0, $separator) -ne $directory -or $normalized -notmatch '\.png$') { continue }
        if (-not $registered.ContainsKey($normalized)) { $normalized }
    }
}

function Test-ExactHash {
    param([string]$Path, [string]$Expected, [string]$Label)
    if ($Expected -notmatch '^[a-fA-F0-9]{64}$') { throw "Invalid $Label SHA-256" }
    $output = @(& $hashValidator -Path $Path -ExpectedHash $Expected -QuarantineHashes $quarantineHashes 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "$Label exact hash rejected: $($output -join ' ')" }
}

function Test-Approval {
    param([object]$Row, [string]$ReviewPath)
    if ($Row.status -eq 'technical_candidate') { return }
    $recordPath = Resolve-AssetRecordPath ([string]$Row.approval_record_path) 'approval_record'
    if ([IO.Path]::GetExtension($recordPath) -ne '.json') { throw 'Approval record must be structured JSON.' }
    $record = Get-Content -LiteralPath $recordPath -Raw | ConvertFrom-Json
    foreach ($field in @('candidate_id', 'file_path', 'sha256', 'decision', 'visual_review_status', 'review_record_path', 'review_record_sha256', 'reviewer', 'reviewed_at', 'scope', 'blocking_findings')) {
        if ($field -notin $record.PSObject.Properties.Name) { throw "Approval record missing field: $field" }
    }
    if ($record.candidate_id -cne $Row.candidate_id -or $record.file_path -cne $Row.file_path -or $record.sha256 -ne $Row.sha256) { throw 'Approval record does not identify this exact candidate.' }
    if ($record.decision -ne 'approved_concept' -or $record.visual_review_status -ne 'passed' -or $record.scope -ne 'concept_only' -or (($record.blocking_findings -isnot [long]) -and ($record.blocking_findings -isnot [int])) -or $record.blocking_findings -ne 0) { throw 'Approval record lacks a passed concept-only visual decision with zero blocking findings.' }
    if ($record.review_record_path -cne $Row.review_record_path -or [string]::IsNullOrWhiteSpace([string]$record.reviewer)) { throw 'Approval record has no specific review and reviewer.' }
    $reviewedAt = [DateTimeOffset]::MinValue
    if (-not [DateTimeOffset]::TryParse([string]$record.reviewed_at, [ref]$reviewedAt)) { throw 'Approval review date is invalid.' }
    Test-ExactHash $ReviewPath $record.review_record_sha256 'approval review'
    if ((Get-Content -LiteralPath $ReviewPath -Raw) -notmatch '(?m)^- visual_review_status:\s*passed\s*$') { throw 'Visual review does not explicitly record visual_review_status: passed.' }
    if ($Row.visual_review_status -and $Row.visual_review_status -ne 'passed') { throw 'Candidate visual review status contradicts approval.' }
}

function Test-CleanReferenceChain {
    param([object]$Row)
    $visited = @{}
    $visited[([string]$Row.file_path).Replace('\', '/')] = $true
    $cursor = $Row
    while ($cursor.reference_path) {
        $referencePath = Resolve-AssetRecordPath $cursor.reference_path 'reference'
        $key = Get-RelativeAssetPath $referencePath
        if ($visited.ContainsKey($key)) { throw 'Candidate reference chain contains a cycle.' }
        $visited[$key] = $true
        if (-not $registeredReferences.ContainsKey($key) -or $registeredReferences[$key].Count -ne 1) { throw 'Reference must resolve uniquely to an existing clean candidate registry row.' }
        $parent = $registeredReferences[$key][0]
        if ($parent.sha256 -ne $cursor.reference_sha256 -or $parent.rights_status -notin @('clean_text_only', 'clean_cc0_anatomy_reference', 'original_project_clean_lineage', 'original_project_asset')) { throw 'Reference hash or clean registry provenance does not match.' }
        if ($parent.status -match '(?i)reject|quarantine' -or $parent.state -match '(?i)reject|quarantine' -or $parent.visual_review_status -match '(?i)^rejected') { throw 'Rejected reference cannot seed a controlled candidate.' }
        Test-ExactHash $referencePath $cursor.reference_sha256 'reference'
        $cursor = $parent
    }
}

try {
    foreach ($required in @($GlobalManifestPath, $quarantineManifest, $hashValidator, $pngValidator)) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) { throw "Required candidate checker input/tool is missing: $required" }
    }
    $globalRows = @(Import-Csv -LiteralPath $GlobalManifestPath)
    if ($globalRows.Count -eq 0) { throw 'Global asset manifest is empty.' }
    $quarantineRows = @(Import-Csv -LiteralPath $quarantineManifest)
    if ($quarantineRows.Count -eq 0 -or @($quarantineRows | Where-Object { $_.sha256 -notmatch '^[a-fA-F0-9]{64}$' -or $_.status -ne 'do_not_use' }).Count) { throw 'Quarantine hash registry is empty or invalid.' }
    $quarantineHashes = @($quarantineRows | ForEach-Object { $_.sha256.ToLowerInvariant() })
    $candidateRoot = Join-Path $repositoryRoot 'art/candidates'
    $registeredReferences = @{}
    $discoveredManifests = [Collections.Generic.List[string]]::new()
    foreach ($file in Get-ChildItem -LiteralPath $candidateRoot -Recurse -File -Filter 'CANDIDATE_MANIFEST.csv') {
        if ($file.FullName -match '(?i)[\\/]_quarantine[\\/]') { continue }
        $rows = @(Import-Csv -LiteralPath $file.FullName)
        if ($rows.Count -eq 0) { continue }
        if ('reference_path' -in $rows[0].PSObject.Properties.Name -and 'status' -in $rows[0].PSObject.Properties.Name) { $discoveredManifests.Add($file.FullName) }
        foreach ($row in $rows) {
            if ($row.file_path -and $row.sha256 -match '^[a-fA-F0-9]{64}$') {
                $key = ([string]$row.file_path).Replace('\', '/')
                if (-not $registeredReferences.ContainsKey($key)) { $registeredReferences[$key] = @() }
                $registeredReferences[$key] += $row
            }
        }
    }
    if ($ManifestPath.Count -eq 0) {
        foreach ($row in $globalRows) {
            if ($row.category -eq 'character' -and $row.source_method -eq 'ai_assisted_edit' -and $row.source_path -match 'CANDIDATE_MANIFEST\.csv$') {
                $discoveredManifests.Add((Join-Path $repositoryRoot $row.source_path))
            }
        }
        $ManifestPath = @($discoveredManifests | Sort-Object -Unique)
    }
    $seenIds = @{}
    $seenPaths = @{}
    foreach ($manifest in $ManifestPath) {
        try {
            $relativeManifest = Get-RelativeAssetPath $manifest
            $manifestFull = Resolve-AssetRecordPath $relativeManifest 'candidate manifest'
            $registrations = @($globalRows | Where-Object { ([string]$_.source_path).Replace('\', '/') -eq $relativeManifest })
            if ($registrations.Count -ne 1) { throw "Candidate manifest must have one global registration, found $($registrations.Count): $relativeManifest" }
            $rows = @(Import-Csv -LiteralPath $manifestFull)
            if ($rows.Count -eq 0) { throw "Candidate manifest is empty: $relativeManifest" }
            if (-not $relativeManifest.StartsWith('build/', [StringComparison]::OrdinalIgnoreCase)) {
                $directory = Split-Path $manifestFull -Parent
                $existingPngPaths = @(Get-ChildItem -LiteralPath $directory -File -Filter '*.png' | ForEach-Object { Get-RelativeAssetPath $_.FullName })
                $unregistered = @(Get-UnregisteredCandidatePaths -DirectoryPath (Get-RelativeAssetPath $directory) -ExistingPaths $existingPngPaths -RegisteredPaths @($rows.file_path))
                if ($unregistered.Count) { throw "Unregistered PNG in candidate manifest directory: $($unregistered -join ', ')" }
            }
            foreach ($row in $rows) {
                try {
                    foreach ($field in @('candidate_id', 'file_path', 'sha256', 'status', 'reference_path', 'reference_sha256', 'prompt_record_path', 'review_record_path', 'width', 'height', 'pixel_format', 'rights_status', 'game_path')) {
                        if ($field -notin $row.PSObject.Properties.Name -or ($field -ne 'game_path' -and [string]::IsNullOrWhiteSpace([string]$row.$field))) { throw "Candidate missing required field: $field" }
                    }
                    if ($row.status -notin @('technical_candidate', 'approved_concept')) { throw "Unsupported candidate lifecycle status '$($row.status)'; game-ready promotion needs an explicit validator extension." }
                    if ($row.game_path -or $registrations[0].game_path) { throw 'Candidate/concept cannot publish a game_path.' }
                    if ($registrations[0].status -ne $row.status) { throw 'Global and local candidate status disagree.' }
                    if ($row.rights_status -notin @('original_project_clean_lineage', 'clean_text_only', 'original_project_asset')) { throw 'Candidate rights_status does not establish clean project lineage.' }
                    if ($row.sha256 -in $quarantineHashes -or $row.reference_sha256 -in $quarantineHashes) { throw 'Candidate or reference declares a quarantined hash.' }
                    if ($seenIds.ContainsKey($row.candidate_id)) { throw "Duplicate candidate ID: $($row.candidate_id)" }
                    $seenIds[$row.candidate_id] = $relativeManifest
                    if (-not ([string]$row.file_path).Replace('\', '/').StartsWith('art/candidates/', [StringComparison]::OrdinalIgnoreCase)) { throw 'Candidate PNG must stay under art/candidates, never generated_raw or game assets.' }
                    $asset = Resolve-AssetRecordPath $row.file_path 'candidate'
                    $relativeAsset = Get-RelativeAssetPath $asset
                    if ($seenPaths.ContainsKey($relativeAsset)) { throw "Duplicate candidate file path: $relativeAsset" }
                    $seenPaths[$relativeAsset] = $row.candidate_id
                    $reference = Resolve-AssetRecordPath $row.reference_path 'reference'
                    $null = Resolve-AssetRecordPath $row.prompt_record_path 'prompt_record'
                    $review = Resolve-AssetRecordPath $row.review_record_path 'review_record'
                    if ($asset -eq $reference) { throw 'Candidate cannot reference itself.' }
                    $referenceKey = Get-RelativeAssetPath $reference
                    Test-CleanReferenceChain $row
                    $width = 0
                    $height = 0
                    if (-not [int]::TryParse($row.width, [ref]$width) -or -not [int]::TryParse($row.height, [ref]$height) -or $width -lt 1 -or $height -lt 1 -or $width -gt 16384 -or $height -gt 16384) { throw 'Candidate dimensions must be explicit positive pixel counts.' }
                    Test-Approval $row $review
                    Test-ExactHash $asset $row.sha256 'candidate'
                    $pngOutput = @(& $pngValidator -Path $asset -ExpectedWidth $width -ExpectedHeight $height -RequireAlpha -ManifestPath $manifestFull 2>&1)
                    if ($LASTEXITCODE -ne 0) { throw "Candidate PNG validation failed: $($pngOutput -join ' ')" }
                    $inspection = [Capybara.Art.PngInspector]::Inspect($asset)
                    if ($inspection.PixelFormat -ne $row.pixel_format) { throw "Candidate pixel_format mismatch: recorded $($row.pixel_format), actual $($inspection.PixelFormat)" }
                    $verified.Add([pscustomobject]@{ candidate_id = $row.candidate_id; manifest = $relativeManifest; file_path = $relativeAsset; status = $row.status; sha256 = $row.sha256; reference_path = $referenceKey })
                }
                catch { $failures.Add("$($row.candidate_id): $($_.Exception.Message)") }
            }
        }
        catch { $failures.Add($_.Exception.Message) }
    }
}
catch { $failures.Add($_.Exception.Message) }

$summary = [ordered]@{ success = ($failures.Count -eq 0); checked = $verified.Count; manifests = $ManifestPath.Count; candidates = @($verified); failures = @($failures) }
if ($JsonOutputPath) {
    $jsonPath = [IO.Path]::GetFullPath($JsonOutputPath)
    $buildRoot = [IO.Path]::GetFullPath((Join-Path $repositoryRoot 'build')) + [IO.Path]::DirectorySeparatorChar
    if (-not $jsonPath.StartsWith($buildRoot, [StringComparison]::OrdinalIgnoreCase) -or [IO.Path]::GetExtension($jsonPath) -ne '.json') { throw 'Candidate check JSON must be a file under build.' }
    $null = New-Item -ItemType Directory -Path (Split-Path $jsonPath -Parent) -Force
    $summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $jsonPath -Encoding utf8
}
if ($failures.Count) {
    foreach ($failure in $failures) { [Console]::Error.WriteLine("[character-candidate] FAIL: $failure") }
    exit 22
}
[Console]::WriteLine("[character-candidate] PASS: $($verified.Count) controlled candidates across $($ManifestPath.Count) manifests; hashes, clean references, provenance, RGBA and lifecycle verified.")
exit 0
