[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$candidateDirectory = Join-Path $repositoryRoot 'art\candidates\player_capybara_v1'
$visualConceptDirectory = Join-Path $candidateDirectory 'visual_concepts'
$homeCandidateDirectory = Join-Path $repositoryRoot 'art\candidates\environment\home_visual_v1'
$homeCandidateManifestPath = Join-Path $homeCandidateDirectory 'CANDIDATE_MANIFEST.csv'
$homeVisualConceptPath = Join-Path $homeCandidateDirectory 'visual_concepts\env_home_visual_concept_a1_v001.png'
$homeBriefPath = Join-Path $homeCandidateDirectory 'BRIEF.md'
$homePromptPath = Join-Path $homeCandidateDirectory 'PROMPTS.md'
$homeReviewPath = Join-Path $homeCandidateDirectory 'REVIEW.md'
$cottageCandidateDirectory = Join-Path $repositoryRoot 'art\candidates\environment\home_cottage_v1'
$cottageCandidateManifestPath = Join-Path $cottageCandidateDirectory 'CANDIDATE_MANIFEST.csv'
$cottageRejectedManifestPath = Join-Path $cottageCandidateDirectory 'REJECTED_TECHNICAL_MANIFEST.csv'
$cottageVisualConceptPath = Join-Path $cottageCandidateDirectory 'visual_concepts\bld_home_cottage_a1_v001.png'
$cottageBriefPath = Join-Path $cottageCandidateDirectory 'BRIEF.md'
$cottagePromptPath = Join-Path $cottageCandidateDirectory 'PROMPTS.md'
$cottageReviewPath = Join-Path $cottageCandidateDirectory 'REVIEW.md'
$manifestPath = Join-Path $repositoryRoot 'docs\production\ASSET_MANIFEST.csv'
$candidateManifestPath = Join-Path $candidateDirectory 'CANDIDATE_MANIFEST.csv'
$prototypeManifestPath = Join-Path $candidateDirectory 'PROTOTYPE_MANIFEST.csv'
$rejectedVisualManifestPath = Join-Path $candidateDirectory 'REJECTED_VISUAL_MANIFEST.csv'
$rejectedTechnicalManifestPath = Join-Path $candidateDirectory 'REJECTED_TECHNICAL_MANIFEST.csv'
$validatorPath = Join-Path $PSScriptRoot 'validate_png_assets.ps1'
$contactSheetPath = Join-Path $PSScriptRoot 'make_contact_sheet.ps1'
$alphaReviewPath = Join-Path $PSScriptRoot 'make_alpha_review_sheet.ps1'
$renderSvgPath = Join-Path $PSScriptRoot 'render_svg_preview.ps1'
$hashValidatorPath = Join-Path $PSScriptRoot 'validate_asset_hash.ps1'
$svgCheckoutTestPath = Join-Path $PSScriptRoot 'test_svg_checkout_hash.ps1'
$referencePath = Join-Path $candidateDirectory 'references\capybara_anatomy_cc0_fernando_sessegolo.jpg'
$formalContactSheet = Join-Path $candidateDirectory 'clean_contact_sheet_v002.png'
$formalContactMapping = Join-Path $candidateDirectory 'clean_contact_sheet_v002.mapping.json'
$vectorPrototypePath = Join-Path $candidateDirectory 'vector_prototypes\chr_player_cutout_down_right_v001.svg'
$quarantineManifestPath = Join-Path $repositoryRoot 'art\candidates\_quarantine\player_capybara_v1_unverified_reference\QUARANTINE_MANIFEST.csv'
$smokeOutput = Join-Path $repositoryRoot 'build\art-pipeline\contact_sheet_smoke.png'
$fixtureDirectory = Join-Path $repositoryRoot 'build\art-pipeline\fixtures'
$fixtureManifestPath = Join-Path $fixtureDirectory 'manifest.csv'
$opaqueFixturePath = Join-Path $fixtureDirectory 'opaque_fixture_v001.png'
$alphaFixturePath = Join-Path $fixtureDirectory 'alpha_fixture_v001.png'
$wideAlphaFixturePath = Join-Path $fixtureDirectory 'wide_alpha_fixture_v001.png'
$alphaReviewSmokeDirectory = Join-Path $repositoryRoot 'build\art-pipeline\alpha-review-smoke'
$forbiddenOutput = Join-Path $repositoryRoot 'game\assets\art_pipeline_forbidden_contact_sheet.png'

foreach ($requiredPath in @(
    $validatorPath,
    $contactSheetPath,
    $alphaReviewPath,
    $renderSvgPath,
    $hashValidatorPath,
    $svgCheckoutTestPath,
    $manifestPath,
    $candidateManifestPath,
    $homeCandidateManifestPath,
    $homeVisualConceptPath,
    $homeBriefPath,
    $homePromptPath,
    $homeReviewPath,
    $cottageCandidateManifestPath,
    $cottageRejectedManifestPath,
    $cottageVisualConceptPath,
    $cottageBriefPath,
    $cottagePromptPath,
    $cottageReviewPath,
    $prototypeManifestPath,
    $rejectedVisualManifestPath,
    $rejectedTechnicalManifestPath,
    $referencePath,
    $quarantineManifestPath,
    $formalContactSheet,
    $formalContactMapping
    $vectorPrototypePath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        [Console]::Error.WriteLine("[art] FAIL: Required file is missing: $requiredPath")
        exit 22
    }
}

Add-Type -AssemblyName System.Drawing

function Test-MarkdownPromptSection {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$PromptId,
        [switch]$RequireFencedText
    )

    $headingPattern = '(?m)^##[ \t]+' + [regex]::Escape($PromptId) + '[ \t]*\r?$'
    $headingMatch = [regex]::Match($Content, $headingPattern)
    if (-not $headingMatch.Success) {
        return $false
    }
    if (-not $RequireFencedText) {
        return $true
    }
    $sectionStart = $headingMatch.Index + $headingMatch.Length
    $tail = $Content.Substring($sectionStart)
    $nextHeading = [regex]::Match($tail, '(?m)^##[ \t]+')
    $section = if ($nextHeading.Success) { $tail.Substring(0, $nextHeading.Index) } else { $tail }
    return [regex]::IsMatch($section, '(?ms)```text[ \t]*\r?\n.+?\r?\n```')
}

$technicalCandidatePaths = @(
    Get-ChildItem -LiteralPath $candidateDirectory -File -Filter 'chr_player_clean_candidate_*_v*.png' |
        Sort-Object Name |
        ForEach-Object { $_.FullName }
)
$visualConceptPaths = @(
    Get-ChildItem -LiteralPath $visualConceptDirectory -File -Filter 'chr_player_clean_concept_*_v*.png' |
        Sort-Object Name |
        ForEach-Object { $_.FullName }
)
$allConceptPaths = @($technicalCandidatePaths) + @($visualConceptPaths)
if ($allConceptPaths.Count -lt 6 -or $allConceptPaths.Count -gt 12) {
    [Console]::Error.WriteLine("[art] FAIL: Expected 6-12 visual concepts, found $($allConceptPaths.Count).")
    exit 22
}

& $validatorPath `
    -Path $allConceptPaths `
    -MinimumWidth 1000 `
    -MinimumHeight 1000 `
    -ManifestPath $candidateManifestPath
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
if ($technicalCandidatePaths.Count -gt 0) {
    & $validatorPath `
        -Path $technicalCandidatePaths `
        -MinimumWidth 1024 `
        -MinimumHeight 1024 `
        -RequireAlpha `
        -MinimumTransparentPadding 1 `
        -ManifestPath $candidateManifestPath
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

$referenceSha1 = (Get-FileHash -Algorithm SHA1 -LiteralPath $referencePath).Hash.ToLowerInvariant()
$expectedReferenceSha1 = '9425282a7e3ccdd74feee6fa227eff4c0cfa0895'
$referenceSha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $referencePath).Hash.ToLowerInvariant()
$expectedReferenceSha256 = 'ce7f277fd0d0b219dffa81bfa2fe78e8e26a26cf905758404b73887d56e21145'
if ($referenceSha1 -ne $expectedReferenceSha1 -or $referenceSha256 -ne $expectedReferenceSha256) {
    [Console]::Error.WriteLine('[art] FAIL: CC0 anatomy reference SHA-1/SHA-256 mismatch.')
    exit 22
}

$manifestRows = @(Import-Csv -LiteralPath $manifestPath)
$playerRow = @($manifestRows | Where-Object { $_.asset_id -eq 'player_capybara_v1' })
if ($playerRow.Count -ne 1) {
    [Console]::Error.WriteLine("[art] FAIL: Expected one player_capybara_v1 manifest row, found $($playerRow.Count).")
    exit 22
}
foreach ($field in @(
    'status', 'source_method', 'model_or_tool', 'prompt_id', 'reference_asset_ids',
    'raw_path', 'source_path', 'width', 'height', 'alpha_required', 'license_or_rights',
    'human_edits', 'reviewer', 'ai_disclosure_required', 'notes'
)) {
    if ([string]::IsNullOrWhiteSpace([string]$playerRow[0].$field)) {
        [Console]::Error.WriteLine("[art] FAIL: player_capybara_v1 manifest field is blank: $field")
        exit 22
    }
}
if ($playerRow[0].status -ne 'visual_concept') {
    [Console]::Error.WriteLine("[art] FAIL: player_capybara_v1 must remain visual_concept during clean-lineage exploration.")
    exit 22
}
if ($playerRow[0].width -ne 'varies' -or
    $playerRow[0].height -ne 'varies' -or
    $playerRow[0].alpha_required -ne 'no') {
    [Console]::Error.WriteLine('[art] FAIL: Visual-concept family dimensions/alpha semantics are invalid.')
    exit 22
}

$candidateRows = @(Import-Csv -LiteralPath $candidateManifestPath)
if ($candidateRows.Count -ne $allConceptPaths.Count) {
    [Console]::Error.WriteLine(
        "[art] FAIL: Candidate manifest rows ($($candidateRows.Count)) do not match active files ($($allConceptPaths.Count))."
    )
    exit 22
}
$duplicateCandidateIds = @($candidateRows | Group-Object candidate_id | Where-Object { $_.Count -gt 1 })
$duplicateCandidatePaths = @($candidateRows | Group-Object file_path | Where-Object { $_.Count -gt 1 })
$duplicatePromptIds = @($candidateRows | Group-Object prompt_id | Where-Object { $_.Count -gt 1 })
if ($duplicateCandidateIds.Count -gt 0 -or
    $duplicateCandidatePaths.Count -gt 0 -or
    $duplicatePromptIds.Count -gt 0) {
    [Console]::Error.WriteLine('[art] FAIL: Candidate IDs, file paths, and prompt IDs must each be unique.')
    exit 22
}
$allowedReferences = @('REF-CAPYBARA-ANATOMY-CC0-001', 'NONE_TEXT_ONLY')
$allowedVisualReviewStatuses = @(
    'pending_independent',
    'advance_to_technical_redesign',
    'hold_as_backup',
    'do_not_advance_player'
)
$allowedTechnicalReviewStatuses = @('pending_alpha_review', 'technical_pass', 'technical_fail')
$allowedRightsStatuses = @('clean_cc0_only', 'clean_text_only')
$quarantineRows = @(Import-Csv -LiteralPath $quarantineManifestPath)
$quarantineHashes = @($quarantineRows | ForEach-Object { $_.sha256.ToLowerInvariant() })
if ($quarantineRows.Count -eq 0 -or
    @($quarantineRows | Where-Object { $_.status -ne 'do_not_use' }).Count -gt 0) {
    [Console]::Error.WriteLine('[art] FAIL: Quarantine manifest is empty or contains a reusable status.')
    exit 22
}
foreach ($row in $candidateRows) {
    foreach ($field in @(
        'candidate_id', 'file_path', 'state', 'source_method', 'tool', 'prompt_id',
        'reference_asset_ids', 'prompt_record_path', 'review_record_path', 'generated_at_utc', 'width',
        'height', 'pixel_format', 'alpha_required', 'sha256', 'visual_review_status',
        'technical_review_status', 'rights_status', 'notes'
    )) {
        if ([string]::IsNullOrWhiteSpace([string]$row.$field)) {
            [Console]::Error.WriteLine("[art] FAIL: Candidate '$($row.candidate_id)' field is blank: $field")
            exit 22
        }
    }
    if ($row.state -notin @('visual_concept', 'technical_candidate')) {
        [Console]::Error.WriteLine("[art] FAIL: Candidate '$($row.candidate_id)' has invalid state '$($row.state)'.")
        exit 22
    }
    if ($row.reference_asset_ids -notin $allowedReferences) {
        [Console]::Error.WriteLine(
            "[art] FAIL: Candidate '$($row.candidate_id)' has a non-clean reference chain: $($row.reference_asset_ids)"
        )
        exit 22
    }
    if ($row.rights_status -notin $allowedRightsStatuses) {
        [Console]::Error.WriteLine("[art] FAIL: Candidate '$($row.candidate_id)' has invalid rights status.")
        exit 22
    }
    if ($row.file_path -match '(?i)quarantine|USER-SESSION|player_capybara_v1_c1|player_capybara_v1_d1') {
        [Console]::Error.WriteLine("[art] FAIL: Candidate '$($row.candidate_id)' references quarantined lineage.")
        exit 22
    }
    $candidateFullPath = Join-Path $repositoryRoot $row.file_path
    if (-not (Test-Path -LiteralPath $candidateFullPath -PathType Leaf)) {
        [Console]::Error.WriteLine("[art] FAIL: Candidate file is missing: $($row.file_path)")
        exit 22
    }
    $actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $candidateFullPath).Hash.ToLowerInvariant()
    if ($actualHash -ne $row.sha256.ToLowerInvariant()) {
        [Console]::Error.WriteLine("[art] FAIL: Candidate hash mismatch: $($row.candidate_id)")
        exit 22
    }
    if ($actualHash -in $quarantineHashes) {
        [Console]::Error.WriteLine("[art] FAIL: Active candidate reuses quarantined binary content: $($row.candidate_id)")
        exit 22
    }
    $promptRecordFullPath = Join-Path $repositoryRoot $row.prompt_record_path
    if (-not (Test-Path -LiteralPath $promptRecordFullPath -PathType Leaf)) {
        [Console]::Error.WriteLine("[art] FAIL: Prompt record is missing: $($row.prompt_record_path)")
        exit 22
    }
    $promptRecord = Get-Content -Raw -LiteralPath $promptRecordFullPath
    if (-not (Test-MarkdownPromptSection -Content $promptRecord -PromptId $row.prompt_id -RequireFencedText)) {
        [Console]::Error.WriteLine("[art] FAIL: Prompt ID '$($row.prompt_id)' is missing from its record.")
        exit 22
    }
    $reviewRecordFullPath = Join-Path $repositoryRoot $row.review_record_path
    if (-not (Test-Path -LiteralPath $reviewRecordFullPath -PathType Leaf)) {
        [Console]::Error.WriteLine("[art] FAIL: Review record is missing: $($row.review_record_path)")
        exit 22
    }
    $reviewRecord = Get-Content -Raw -LiteralPath $reviewRecordFullPath
    if (-not $reviewRecord.Contains($row.candidate_id.Replace('player_clean_', '').ToUpperInvariant())) {
        [Console]::Error.WriteLine("[art] FAIL: Candidate '$($row.candidate_id)' is missing from its review record.")
        exit 22
    }
    $candidateImage = [Drawing.Bitmap]::FromFile($candidateFullPath)
    try {
        if ($candidateImage.Width -ne [int]$row.width -or $candidateImage.Height -ne [int]$row.height) {
            [Console]::Error.WriteLine("[art] FAIL: Candidate dimensions do not match manifest: $($row.candidate_id)")
            exit 22
        }
        if ($candidateImage.PixelFormat.ToString() -ne $row.pixel_format) {
            [Console]::Error.WriteLine("[art] FAIL: Candidate pixel format does not match manifest: $($row.candidate_id)")
            exit 22
        }
    }
    finally {
        $candidateImage.Dispose()
    }
    if (($row.state -eq 'technical_candidate') -ne ($row.alpha_required -eq 'yes')) {
        [Console]::Error.WriteLine("[art] FAIL: Candidate state and alpha requirement disagree: $($row.candidate_id)")
        exit 22
    }
    if ($row.state -eq 'visual_concept') {
        if ($row.visual_review_status -notin $allowedVisualReviewStatuses -or
            $row.technical_review_status -ne 'visual_only_opaque') {
            [Console]::Error.WriteLine("[art] FAIL: Visual-concept review states are invalid: $($row.candidate_id)")
            exit 22
        }
    }
    elseif ($row.visual_review_status -notin @('pending_independent', 'advance_to_master_review', 'hold_as_backup') -or
        $row.technical_review_status -notin $allowedTechnicalReviewStatuses) {
        [Console]::Error.WriteLine("[art] FAIL: Technical-candidate review states are invalid: $($row.candidate_id)")
        exit 22
    }
}

$homeRows = @(Import-Csv -LiteralPath $homeCandidateManifestPath)
if ($homeRows.Count -ne 1) {
    [Console]::Error.WriteLine("[art] FAIL: Expected one home visual concept row, found $($homeRows.Count).")
    exit 22
}
$homeRow = $homeRows[0]
foreach ($field in @(
    'candidate_id', 'file_path', 'state', 'source_method', 'tool', 'prompt_id',
    'reference_asset_ids', 'prompt_record_path', 'review_record_path', 'generated_at_utc',
    'width', 'height', 'pixel_format', 'alpha_required', 'sha256', 'visual_review_status',
    'technical_review_status', 'rights_status', 'notes'
)) {
    if ([string]::IsNullOrWhiteSpace([string]$homeRow.$field)) {
        [Console]::Error.WriteLine("[art] FAIL: Home visual concept field is blank: $field")
        exit 22
    }
}
if ($homeRow.candidate_id -ne 'home_visual_a1' -or
    $homeRow.file_path -ne 'art/candidates/environment/home_visual_v1/visual_concepts/env_home_visual_concept_a1_v001.png' -or
    $homeRow.state -ne 'visual_concept' -or
    $homeRow.source_method -ne 'ai_assisted' -or
    $homeRow.tool -ne 'OpenAI ImageGen built-in' -or
    $homeRow.prompt_id -ne 'ENV-HOME-VISUAL-A1' -or
    $homeRow.reference_asset_ids -ne 'NONE_TEXT_ONLY' -or
    $homeRow.alpha_required -ne 'no' -or
    $homeRow.visual_review_status -ne 'direction_locked_for_modular_rebuild' -or
    $homeRow.technical_review_status -ne 'visual_only_opaque' -or
    $homeRow.rights_status -ne 'clean_text_only') {
    [Console]::Error.WriteLine('[art] FAIL: Home visual concept state/source/review semantics are invalid.')
    exit 22
}
& $validatorPath `
    -Path $homeVisualConceptPath `
    -MinimumWidth 1500 `
    -MinimumHeight 1000 `
    -ManifestPath $homeCandidateManifestPath
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
$homeHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $homeVisualConceptPath).Hash.ToLowerInvariant()
if ($homeHash -ne $homeRow.sha256.ToLowerInvariant() -or
    $homeHash -in @($candidateRows.sha256) -or
    $homeHash -in $quarantineHashes) {
    [Console]::Error.WriteLine('[art] FAIL: Home visual concept hash is stale or reuses player/quarantine content.')
    exit 22
}
$homeImage = [Drawing.Bitmap]::FromFile($homeVisualConceptPath)
try {
    if ($homeImage.Width -ne [int]$homeRow.width -or
        $homeImage.Height -ne [int]$homeRow.height -or
        $homeImage.PixelFormat.ToString() -ne $homeRow.pixel_format) {
        [Console]::Error.WriteLine('[art] FAIL: Home visual concept metadata does not match its manifest.')
        exit 22
    }
}
finally {
    $homeImage.Dispose()
}
if (-not (Test-MarkdownPromptSection `
        -Content (Get-Content -Raw -LiteralPath $homePromptPath) `
        -PromptId $homeRow.prompt_id `
        -RequireFencedText
    ) -or
    -not (Get-Content -Raw -LiteralPath $homeReviewPath).Contains('Blocker 0、Critical 0、High 0') -or
    -not (Get-Content -Raw -LiteralPath $homeBriefPath).Contains('不得把整张概念图放入游戏充当场景')) {
    [Console]::Error.WriteLine('[art] FAIL: Home visual concept brief, prompt, or review evidence is stale.')
    exit 22
}
$topLevelHomeRow = @($manifestRows | Where-Object { $_.asset_id -eq 'home_visual_v1' })
if ($topLevelHomeRow.Count -ne 1 -or
    $topLevelHomeRow[0].status -ne $homeRow.state -or
    $topLevelHomeRow[0].source_method -ne $homeRow.source_method -or
    $topLevelHomeRow[0].model_or_tool -ne $homeRow.tool -or
    $topLevelHomeRow[0].prompt_id -ne $homeRow.prompt_id -or
    $topLevelHomeRow[0].reference_asset_ids -ne $homeRow.reference_asset_ids -or
    $topLevelHomeRow[0].source_path -ne 'art/candidates/environment/home_visual_v1/CANDIDATE_MANIFEST.csv' -or
    $topLevelHomeRow[0].width -ne $homeRow.width -or
    $topLevelHomeRow[0].height -ne $homeRow.height -or
    $topLevelHomeRow[0].alpha_required -ne $homeRow.alpha_required) {
    [Console]::Error.WriteLine('[art] FAIL: Top-level asset manifest does not exactly register the home visual concept.')
    exit 22
}

$cottageRows = @(Import-Csv -LiteralPath $cottageCandidateManifestPath)
if ($cottageRows.Count -ne 1) {
    [Console]::Error.WriteLine("[art] FAIL: Expected one cottage visual concept row, found $($cottageRows.Count).")
    exit 22
}
$cottageRow = $cottageRows[0]
foreach ($field in @(
    'candidate_id', 'file_path', 'state', 'source_method', 'tool', 'prompt_id',
    'reference_asset_ids', 'reference_sha256', 'prompt_record_path', 'review_record_path',
    'generated_at_utc', 'width', 'height', 'pixel_format', 'alpha_required', 'sha256',
    'visual_review_status', 'technical_review_status', 'rights_status', 'notes'
)) {
    if ([string]::IsNullOrWhiteSpace([string]$cottageRow.$field)) {
        [Console]::Error.WriteLine("[art] FAIL: Cottage visual concept field is blank: $field")
        exit 22
    }
}
if ($cottageRow.candidate_id -ne 'home_cottage_a1' -or
    $cottageRow.file_path -ne 'art/candidates/environment/home_cottage_v1/visual_concepts/bld_home_cottage_a1_v001.png' -or
    $cottageRow.state -ne 'visual_concept' -or
    $cottageRow.source_method -ne 'ai_assisted' -or
    $cottageRow.tool -ne 'OpenAI ImageGen built-in' -or
    $cottageRow.prompt_id -ne 'ENV-HOME-COTTAGE-A1' -or
    $cottageRow.reference_asset_ids -ne 'home_visual_a1' -or
    $cottageRow.reference_sha256 -ne $homeHash -or
    $cottageRow.alpha_required -ne 'no' -or
    $cottageRow.visual_review_status -ne 'hold_for_layered_rebuild' -or
    $cottageRow.technical_review_status -ne 'opaque_fake_checkerboard' -or
    $cottageRow.rights_status -ne 'clean_internal_reference') {
    [Console]::Error.WriteLine('[art] FAIL: Cottage visual concept source/state/review semantics are invalid.')
    exit 22
}
& $validatorPath `
    -Path $cottageVisualConceptPath `
    -MinimumWidth 1000 `
    -MinimumHeight 1000 `
    -ManifestPath $cottageCandidateManifestPath
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
$cottageHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $cottageVisualConceptPath).Hash.ToLowerInvariant()
if ($cottageHash -ne $cottageRow.sha256.ToLowerInvariant() -or
    $cottageHash -in @($candidateRows.sha256) -or
    $cottageHash -in $quarantineHashes -or
    $cottageHash -eq $homeHash) {
    [Console]::Error.WriteLine('[art] FAIL: Cottage visual concept hash is stale or reuses another asset.')
    exit 22
}
if (-not (Test-MarkdownPromptSection `
        -Content (Get-Content -Raw -LiteralPath $cottagePromptPath) `
        -PromptId $cottageRow.prompt_id `
        -RequireFencedText
    ) -or
    -not (Get-Content -Raw -LiteralPath $cottageReviewPath).Contains('Format24bppRgb') -or
    -not (Get-Content -Raw -LiteralPath $cottageBriefPath).Contains('当前图片不得进入 `game/assets`')) {
    [Console]::Error.WriteLine('[art] FAIL: Cottage brief, prompt, or review evidence is stale.')
    exit 22
}
$topLevelCottageRow = @($manifestRows | Where-Object { $_.asset_id -eq 'home_cottage_v1' })
if ($topLevelCottageRow.Count -ne 1 -or
    $topLevelCottageRow[0].status -ne $cottageRow.state -or
    $topLevelCottageRow[0].source_method -ne $cottageRow.source_method -or
    $topLevelCottageRow[0].model_or_tool -ne $cottageRow.tool -or
    $topLevelCottageRow[0].prompt_id -ne $cottageRow.prompt_id -or
    $topLevelCottageRow[0].reference_asset_ids -ne $cottageRow.reference_asset_ids -or
    $topLevelCottageRow[0].source_path -ne 'art/candidates/environment/home_cottage_v1/CANDIDATE_MANIFEST.csv' -or
    $topLevelCottageRow[0].width -ne $cottageRow.width -or
    $topLevelCottageRow[0].height -ne $cottageRow.height -or
    $topLevelCottageRow[0].alpha_required -ne $cottageRow.alpha_required -or
    -not [string]::IsNullOrWhiteSpace([string]$topLevelCottageRow[0].game_path)) {
    [Console]::Error.WriteLine('[art] FAIL: Top-level asset manifest does not exactly register the cottage visual concept.')
    exit 22
}
$cottageRejectedRows = @(Import-Csv -LiteralPath $cottageRejectedManifestPath)
if ($cottageRejectedRows.Count -ne 1) {
    [Console]::Error.WriteLine("[art] FAIL: Expected one rejected cottage technical row, found $($cottageRejectedRows.Count).")
    exit 22
}
$cottageRejectedRow = $cottageRejectedRows[0]
if ($cottageRejectedRow.state -ne 'rejected_technical' -or
    $cottageRejectedRow.prompt_id -ne 'ENV-HOME-COTTAGE-A1-BG-EXTRACT' -or
    $cottageRejectedRow.reference_asset_ids -ne 'home_cottage_a1' -or
    $cottageRejectedRow.reference_sha256 -ne $cottageHash -or
    $cottageRejectedRow.pixel_format -ne 'Format24bppRgb' -or
    $cottageRejectedRow.rights_status -ne 'clean_internal_derived' -or
    $cottageRejectedRow.promotion_status -ne 'do_not_promote' -or
    $cottageRejectedRow.sha256 -eq $cottageHash -or
    $cottageRejectedRow.sha256 -in $quarantineHashes) {
    [Console]::Error.WriteLine('[art] FAIL: Rejected cottage technical semantics are invalid.')
    exit 22
}
if (-not (Test-MarkdownPromptSection `
        -Content (Get-Content -Raw -LiteralPath $cottagePromptPath) `
        -PromptId $cottageRejectedRow.prompt_id `
        -RequireFencedText
    )) {
    [Console]::Error.WriteLine('[art] FAIL: Rejected cottage technical prompt is missing or stale.')
    exit 22
}
$cottageRejectedFullPath = Join-Path $repositoryRoot $cottageRejectedRow.raw_path
if (Test-Path -LiteralPath $cottageRejectedFullPath -PathType Leaf) {
    $actualRejectedCottageHash = (
        Get-FileHash -Algorithm SHA256 -LiteralPath $cottageRejectedFullPath
    ).Hash.ToLowerInvariant()
    if ($actualRejectedCottageHash -ne $cottageRejectedRow.sha256.ToLowerInvariant()) {
        [Console]::Error.WriteLine('[art] FAIL: Local rejected cottage technical hash mismatch.')
        exit 22
    }
    $rejectedCottageImage = [Drawing.Bitmap]::FromFile($cottageRejectedFullPath)
    try {
        if ($rejectedCottageImage.Width -ne [int]$cottageRejectedRow.width -or
            $rejectedCottageImage.Height -ne [int]$cottageRejectedRow.height -or
            $rejectedCottageImage.PixelFormat.ToString() -ne $cottageRejectedRow.pixel_format) {
            [Console]::Error.WriteLine('[art] FAIL: Local rejected cottage technical metadata mismatch.')
            exit 22
        }
    }
    finally {
        $rejectedCottageImage.Dispose()
    }
}

$prototypeRows = @(Import-Csv -LiteralPath $prototypeManifestPath)
if ($prototypeRows.Count -ne 1) {
    [Console]::Error.WriteLine("[art] FAIL: Expected one vector prototype row, found $($prototypeRows.Count).")
    exit 22
}
$prototypeRow = $prototypeRows[0]
foreach ($field in @(
    'prototype_id', 'file_path', 'state', 'source_method', 'tool', 'prompt_id',
    'reference_asset_ids', 'review_record_path', 'width', 'height', 'alpha_required',
    'sha256', 'rights_status', 'notes'
)) {
    if ([string]::IsNullOrWhiteSpace([string]$prototypeRow.$field)) {
        [Console]::Error.WriteLine("[art] FAIL: Vector prototype field is blank: $field")
        exit 22
    }
}
if ($prototypeRow.state -ne 'vector_technical_prototype' -or
    $prototypeRow.reference_asset_ids -ne 'NONE_TEXT_ONLY' -or
    $prototypeRow.rights_status -ne 'clean_text_only' -or
    $prototypeRow.alpha_required -ne 'yes') {
    [Console]::Error.WriteLine('[art] FAIL: Vector prototype state or rights semantics are invalid.')
    exit 22
}
if ([int]$prototypeRow.width -ne 1024 -or [int]$prototypeRow.height -ne 768) {
    [Console]::Error.WriteLine('[art] FAIL: Vector prototype manifest dimensions must be 1024x768.')
    exit 22
}
$prototypeFullPath = Join-Path $repositoryRoot $prototypeRow.file_path
if ($prototypeFullPath -ne $vectorPrototypePath) {
    [Console]::Error.WriteLine('[art] FAIL: Vector prototype manifest path is not the active source.')
    exit 22
}
& $hashValidatorPath -Path $prototypeFullPath -ExpectedHash $prototypeRow.sha256 -QuarantineHashes $quarantineHashes
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
& $svgCheckoutTestPath
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
$svgText = Get-Content -Raw -LiteralPath $prototypeFullPath
if ($svgText -match '(?i)<!DOCTYPE|<!ENTITY') {
    [Console]::Error.WriteLine('[art] FAIL: SVG must not contain a DOCTYPE or entity declaration.')
    exit 22
}
try {
    [xml]$svgDocument = $svgText
}
catch {
    [Console]::Error.WriteLine("[art] FAIL: SVG is not valid XML: $($_.Exception.Message)")
    exit 22
}
$svgRoot = $svgDocument.DocumentElement
if ($svgRoot.LocalName -ne 'svg' -or
    $svgRoot.GetAttribute('viewBox') -ne '0 0 1024 768' -or
    $svgRoot.GetAttribute('width') -ne '1024' -or
    $svgRoot.GetAttribute('height') -ne '768') {
    [Console]::Error.WriteLine('[art] FAIL: SVG root dimensions/viewBox are invalid.')
    exit 22
}
$svgNodes = @($svgDocument.SelectNodes('//*'))
$forbiddenSvgNodes = @($svgNodes | Where-Object {
    $_.LocalName -in @('script', 'foreignObject', 'image')
})
if ($forbiddenSvgNodes.Count -gt 0) {
    [Console]::Error.WriteLine('[art] FAIL: SVG contains script, foreignObject, or embedded/external image content.')
    exit 22
}
$hrefAttributes = @($svgNodes | ForEach-Object {
    @($_.Attributes | Where-Object { $_.LocalName -eq 'href' -and -not [string]::IsNullOrWhiteSpace($_.Value) })
})
if ($hrefAttributes.Count -gt 0) {
    [Console]::Error.WriteLine('[art] FAIL: SVG must not contain href-based external or embedded references.')
    exit 22
}
$svgIds = @($svgNodes | ForEach-Object { $_.GetAttribute('id') } | Where-Object { $_ })
if (@($svgIds | Group-Object | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
    [Console]::Error.WriteLine('[art] FAIL: SVG contains duplicate IDs.')
    exit 22
}
$requiredSvgGroups = @(
    'rear-feet', 'body', 'bag-strap', 'satchel', 'front-feet',
    'head', 'ears', 'face', 'muzzle', 'scarf'
)
$actualSvgGroups = @($svgNodes | Where-Object { $_.LocalName -eq 'g' } | ForEach-Object { $_.GetAttribute('id') })
foreach ($requiredGroup in $requiredSvgGroups) {
    if ($requiredGroup -notin $actualSvgGroups) {
        [Console]::Error.WriteLine("[art] FAIL: SVG is missing required cutout group: $requiredGroup")
        exit 22
    }
}
$prototypeReviewPath = Join-Path $repositoryRoot $prototypeRow.review_record_path
if (-not (Test-Path -LiteralPath $prototypeReviewPath -PathType Leaf) -or
    -not (Test-MarkdownPromptSection `
        -Content (Get-Content -Raw -LiteralPath $prototypeReviewPath) `
        -PromptId $prototypeRow.prompt_id
    )) {
    [Console]::Error.WriteLine('[art] FAIL: Vector prototype review record is missing or stale.')
    exit 22
}
$topLevelPrototypeRow = @($manifestRows | Where-Object { $_.asset_id -eq 'player_capybara_cutout_proto_v001' })
if ($topLevelPrototypeRow.Count -ne 1 -or
    $topLevelPrototypeRow[0].source_path -ne $prototypeRow.file_path -or
    $topLevelPrototypeRow[0].status -ne $prototypeRow.state -or
    $topLevelPrototypeRow[0].source_method -ne $prototypeRow.source_method -or
    $topLevelPrototypeRow[0].model_or_tool -ne $prototypeRow.tool -or
    $topLevelPrototypeRow[0].prompt_id -ne $prototypeRow.prompt_id -or
    $topLevelPrototypeRow[0].reference_asset_ids -ne $prototypeRow.reference_asset_ids -or
    $topLevelPrototypeRow[0].width -ne $prototypeRow.width -or
    $topLevelPrototypeRow[0].height -ne $prototypeRow.height -or
    $topLevelPrototypeRow[0].alpha_required -ne $prototypeRow.alpha_required -or
    $topLevelPrototypeRow[0].license_or_rights -ne 'original_project_asset') {
    [Console]::Error.WriteLine('[art] FAIL: Top-level asset manifest does not exactly register the vector prototype.')
    exit 22
}

$rejectedVisualRows = @(Import-Csv -LiteralPath $rejectedVisualManifestPath)
if ($rejectedVisualRows.Count -ne 1) {
    [Console]::Error.WriteLine("[art] FAIL: Expected one rejected visual raw row, found $($rejectedVisualRows.Count).")
    exit 22
}
$rejectedVisualRow = $rejectedVisualRows[0]
foreach ($field in @(
    'rejected_id', 'raw_path', 'state', 'source_method', 'tool', 'prompt_id',
    'reference_asset_ids', 'prompt_record_path', 'review_record_path', 'generated_at_utc',
    'width', 'height', 'pixel_format', 'sha256', 'rights_status', 'promotion_status', 'rejection_reason'
)) {
    if ([string]::IsNullOrWhiteSpace([string]$rejectedVisualRow.$field)) {
        [Console]::Error.WriteLine("[art] FAIL: Rejected visual field is blank: $field")
        exit 22
    }
}
if ($rejectedVisualRow.state -ne 'rejected_visual' -or
    $rejectedVisualRow.source_method -ne 'ai_assisted' -or
    $rejectedVisualRow.tool -ne 'OpenAI ImageGen built-in' -or
    $rejectedVisualRow.reference_asset_ids -ne 'NONE_TEXT_ONLY' -or
    $rejectedVisualRow.rights_status -ne 'clean_text_only' -or
    $rejectedVisualRow.promotion_status -ne 'do_not_promote') {
    [Console]::Error.WriteLine('[art] FAIL: Rejected visual state/source/reference/rights semantics are invalid.')
    exit 22
}
if (-not $rejectedVisualRow.raw_path.StartsWith(
    'art/generated_raw/character/player_capybara_v1_clean_visual_round_02/',
    [StringComparison]::OrdinalIgnoreCase
)) {
    [Console]::Error.WriteLine('[art] FAIL: Rejected visual raw path is outside the expected ignored group.')
    exit 22
}
$activePrototypeHashes = @($candidateRows.sha256) + @($prototypeRow.sha256)
if ($rejectedVisualRow.sha256 -in $activePrototypeHashes -or
    $rejectedVisualRow.sha256 -in $quarantineHashes) {
    [Console]::Error.WriteLine('[art] FAIL: Rejected visual hash is reused by active/prototype/quarantine content.')
    exit 22
}
$rejectedVisualPromptPath = Join-Path $repositoryRoot $rejectedVisualRow.prompt_record_path
$rejectedVisualReviewPath = Join-Path $repositoryRoot $rejectedVisualRow.review_record_path
if (-not (Test-Path -LiteralPath $rejectedVisualPromptPath -PathType Leaf) -or
    -not (Test-MarkdownPromptSection `
        -Content (Get-Content -Raw -LiteralPath $rejectedVisualPromptPath) `
        -PromptId $rejectedVisualRow.prompt_id `
        -RequireFencedText
    ) -or
    -not (Test-Path -LiteralPath $rejectedVisualReviewPath -PathType Leaf) -or
    -not (Get-Content -Raw -LiteralPath $rejectedVisualReviewPath).Contains('## AH1')) {
    [Console]::Error.WriteLine('[art] FAIL: Rejected visual prompt or review record is missing or stale.')
    exit 22
}
$rejectedVisualFullPath = Join-Path $repositoryRoot $rejectedVisualRow.raw_path
if (Test-Path -LiteralPath $rejectedVisualFullPath -PathType Leaf) {
    $rejectedVisualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $rejectedVisualFullPath).Hash.ToLowerInvariant()
    if ($rejectedVisualHash -ne $rejectedVisualRow.sha256.ToLowerInvariant()) {
        [Console]::Error.WriteLine('[art] FAIL: Local rejected visual raw hash mismatch.')
        exit 22
    }
    $rejectedVisualImage = [Drawing.Bitmap]::FromFile($rejectedVisualFullPath)
    try {
        if ($rejectedVisualImage.Width -ne [int]$rejectedVisualRow.width -or
            $rejectedVisualImage.Height -ne [int]$rejectedVisualRow.height -or
            $rejectedVisualImage.PixelFormat.ToString() -ne $rejectedVisualRow.pixel_format) {
            [Console]::Error.WriteLine('[art] FAIL: Local rejected visual raw metadata mismatch.')
            exit 22
        }
    }
    finally {
        $rejectedVisualImage.Dispose()
    }
}

$rejectedRows = @(Import-Csv -LiteralPath $rejectedTechnicalManifestPath)
if ($rejectedRows.Count -ne 7) {
    [Console]::Error.WriteLine("[art] FAIL: Expected seven rejected technical raw rows, found $($rejectedRows.Count).")
    exit 22
}
foreach ($groupField in @('rejected_id', 'raw_path', 'prompt_id', 'sha256')) {
    if (@($rejectedRows | Group-Object $groupField | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
        [Console]::Error.WriteLine("[art] FAIL: Rejected technical field must be unique: $groupField")
        exit 22
    }
}
$allowedRejectedReferences = @(
    'NONE_TEXT_ONLY',
    'REF-CAPYBARA-ANATOMY-CC0-001',
    'rejected_aa2'
)
$allowedRejectedRightsStatuses = @('clean_text_only', 'clean_cc0_only', 'clean_internal_derived')
$activeAndPrototypeHashes = @($candidateRows.sha256) + @($prototypeRow.sha256) + @($rejectedVisualRow.sha256)
foreach ($row in $rejectedRows) {
    foreach ($field in @(
        'rejected_id', 'raw_path', 'state', 'tool', 'prompt_id', 'reference_asset_ids',
        'reference_sha256', 'prompt_record_path', 'generated_at_utc', 'width', 'height', 'pixel_format',
        'sha256', 'rights_status', 'promotion_status', 'rejection_reason'
    )) {
        if ([string]::IsNullOrWhiteSpace([string]$row.$field)) {
            [Console]::Error.WriteLine("[art] FAIL: Rejected raw '$($row.rejected_id)' field is blank: $field")
            exit 22
        }
    }
    if ($row.state -ne 'rejected_raw' -or
        $row.promotion_status -ne 'do_not_promote' -or
        $row.reference_asset_ids -notin $allowedRejectedReferences -or
        $row.rights_status -notin $allowedRejectedRightsStatuses) {
        [Console]::Error.WriteLine("[art] FAIL: Rejected raw state/reference/rights are invalid: $($row.rejected_id)")
        exit 22
    }
    if (-not ($row.raw_path.StartsWith(
            'art/generated_raw/character/player_capybara_v1_clean_technical_round_01/',
            [StringComparison]::OrdinalIgnoreCase
        ) -or $row.raw_path.StartsWith(
            'art/generated_raw/character/player_capybara_v1_clean_technical_round_02/',
            [StringComparison]::OrdinalIgnoreCase
        ))) {
        [Console]::Error.WriteLine("[art] FAIL: Rejected raw path is outside the expected ignored group.")
        exit 22
    }
    if ($row.sha256 -in $activeAndPrototypeHashes -or $row.sha256 -in $quarantineHashes) {
        [Console]::Error.WriteLine("[art] FAIL: Rejected raw hash is reused by active/prototype/quarantine content.")
        exit 22
    }
    $rejectedPromptPath = Join-Path $repositoryRoot $row.prompt_record_path
    if (-not (Test-Path -LiteralPath $rejectedPromptPath -PathType Leaf) -or
        -not (Test-MarkdownPromptSection `
            -Content (Get-Content -Raw -LiteralPath $rejectedPromptPath) `
            -PromptId $row.prompt_id `
            -RequireFencedText
        )) {
        [Console]::Error.WriteLine("[art] FAIL: Rejected raw prompt record is missing or stale: $($row.rejected_id)")
        exit 22
    }
    if ($row.reference_asset_ids -eq 'NONE_TEXT_ONLY') {
        if ($row.reference_sha256 -ne 'none') {
            [Console]::Error.WriteLine('[art] FAIL: Text-only rejected raw has an image reference hash.')
            exit 22
        }
    }
    elseif ($row.reference_asset_ids -eq 'REF-CAPYBARA-ANATOMY-CC0-001') {
        if ($row.reference_sha256 -ne $expectedReferenceSha256) {
            [Console]::Error.WriteLine('[art] FAIL: CC0 rejected raw reference hash is stale.')
            exit 22
        }
    }
    else {
        $referencedRows = @($rejectedRows | Where-Object { $_.rejected_id -eq $row.reference_asset_ids })
        if ($referencedRows.Count -ne 1 -or
            $referencedRows[0].state -ne 'rejected_raw' -or
            $referencedRows[0].rights_status -ne 'clean_text_only' -or
            $row.reference_sha256 -ne $referencedRows[0].sha256) {
            [Console]::Error.WriteLine('[art] FAIL: Internal rejected raw reference does not resolve exactly.')
            exit 22
        }
    }
    $rejectedFullPath = Join-Path $repositoryRoot $row.raw_path
    if (Test-Path -LiteralPath $rejectedFullPath -PathType Leaf) {
        $rejectedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $rejectedFullPath).Hash.ToLowerInvariant()
        if ($rejectedHash -ne $row.sha256.ToLowerInvariant()) {
            [Console]::Error.WriteLine("[art] FAIL: Local rejected raw hash mismatch: $($row.rejected_id)")
            exit 22
        }
        $rejectedImage = [Drawing.Bitmap]::FromFile($rejectedFullPath)
        try {
            if ($rejectedImage.Width -ne [int]$row.width -or
                $rejectedImage.Height -ne [int]$row.height -or
                $rejectedImage.PixelFormat.ToString() -ne $row.pixel_format) {
                [Console]::Error.WriteLine("[art] FAIL: Local rejected raw metadata mismatch: $($row.rejected_id)")
                exit 22
            }
        }
        finally {
            $rejectedImage.Dispose()
        }
    }
}

try {
    $contactMapping = Get-Content -Raw -LiteralPath $formalContactMapping | ConvertFrom-Json
}
catch {
    [Console]::Error.WriteLine("[art] FAIL: Contact-sheet mapping is invalid JSON: $($_.Exception.Message)")
    exit 22
}
if ($contactMapping.schema_version -ne 1 -or
    $contactMapping.output_path -ne 'art/candidates/player_capybara_v1/clean_contact_sheet_v002.png') {
    [Console]::Error.WriteLine('[art] FAIL: Contact-sheet mapping identity is invalid.')
    exit 22
}
$mappedCandidates = @($contactMapping.candidates)
if ($mappedCandidates.Count -ne $allConceptPaths.Count) {
    [Console]::Error.WriteLine('[art] FAIL: Contact-sheet mapping candidate count is stale.')
    exit 22
}
$mappedLabels = @($mappedCandidates | ForEach-Object { $_.label })
if (@($mappedLabels | Group-Object | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
    [Console]::Error.WriteLine('[art] FAIL: Contact-sheet mapping contains duplicate labels.')
    exit 22
}
if (@($mappedCandidates | Group-Object file_path | Where-Object { $_.Count -gt 1 }).Count -gt 0) {
    [Console]::Error.WriteLine('[art] FAIL: Contact-sheet mapping contains duplicate file paths.')
    exit 22
}
$activeRelativePaths = @($allConceptPaths | ForEach-Object {
    [IO.Path]::GetRelativePath($repositoryRoot, $_).Replace('\', '/')
})
$mappedRelativePaths = @($mappedCandidates | ForEach-Object { [string]$_.file_path })
$setDifference = @(Compare-Object -ReferenceObject $activeRelativePaths -DifferenceObject $mappedRelativePaths)
if ($setDifference.Count -gt 0) {
    [Console]::Error.WriteLine('[art] FAIL: Contact-sheet mapping does not exactly match the active candidate set.')
    exit 22
}
for ($index = 0; $index -lt $mappedCandidates.Count; $index += 1) {
    if ([int]$mappedCandidates[$index].index -ne $index) {
        [Console]::Error.WriteLine('[art] FAIL: Contact-sheet mapping indices are not contiguous and ordered.')
        exit 22
    }
}
foreach ($mappedCandidate in $mappedCandidates) {
    $matchingRow = @($candidateRows | Where-Object { $_.file_path -eq $mappedCandidate.file_path })
    if ($matchingRow.Count -ne 1) {
        [Console]::Error.WriteLine("[art] FAIL: Contact sheet maps an unregistered file: $($mappedCandidate.file_path)")
        exit 22
    }
    if ($matchingRow[0].sha256 -ne $mappedCandidate.sha256) {
        [Console]::Error.WriteLine("[art] FAIL: Contact-sheet hash is stale: $($mappedCandidate.file_path)")
        exit 22
    }
}
$formalSheetImage = [Drawing.Image]::FromFile($formalContactSheet)
try {
    if ($formalSheetImage.Width -ne [int]$contactMapping.width -or
        $formalSheetImage.Height -ne [int]$contactMapping.height) {
        [Console]::Error.WriteLine('[art] FAIL: Contact-sheet dimensions do not match its mapping.')
        exit 22
    }
}
finally {
    $formalSheetImage.Dispose()
}
$formalSheetHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $formalContactSheet).Hash.ToLowerInvariant()
if ($formalSheetHash -ne [string]$contactMapping.output_sha256) {
    [Console]::Error.WriteLine('[art] FAIL: Contact-sheet PNG hash does not match its mapping.')
    exit 22
}

New-Item -ItemType Directory -Path $fixtureDirectory -Force | Out-Null
$opaqueFixture = [Drawing.Bitmap]::new(64, 64, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
try {
    $fixtureGraphics = [Drawing.Graphics]::FromImage($opaqueFixture)
    try {
        $fixtureGraphics.Clear([Drawing.Color]::FromArgb(255, 220, 210, 190))
    }
    finally {
        $fixtureGraphics.Dispose()
    }
    $opaqueFixture.Save($opaqueFixturePath, [Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $opaqueFixture.Dispose()
}
$alphaFixture = [Drawing.Bitmap]::new(128, 96, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
    $alphaGraphics = [Drawing.Graphics]::FromImage($alphaFixture)
    $alphaBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 145, 112, 86))
    try {
        $alphaGraphics.Clear([Drawing.Color]::Transparent)
        $alphaGraphics.FillEllipse($alphaBrush, 18, 20, 92, 58)
    }
    finally {
        $alphaBrush.Dispose()
        $alphaGraphics.Dispose()
    }
    $alphaFixture.Save($alphaFixturePath, [Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $alphaFixture.Dispose()
}
$wideAlphaFixture = [Drawing.Bitmap]::new(480, 96, [Drawing.Imaging.PixelFormat]::Format32bppArgb)
try {
    $wideAlphaGraphics = [Drawing.Graphics]::FromImage($wideAlphaFixture)
    $wideAlphaBrush = [Drawing.SolidBrush]::new([Drawing.Color]::FromArgb(255, 123, 92, 72))
    try {
        $wideAlphaGraphics.Clear([Drawing.Color]::Transparent)
        $wideAlphaGraphics.FillEllipse($wideAlphaBrush, 10, 28, 460, 40)
    }
    finally {
        $wideAlphaBrush.Dispose()
        $wideAlphaGraphics.Dispose()
    }
    $wideAlphaFixture.Save($wideAlphaFixturePath, [Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $wideAlphaFixture.Dispose()
}
@(
    'file_path,raw_path,source_path,game_path',
    'build/art-pipeline/fixtures/opaque_fixture_v001.png,,,',
    'build/art-pipeline/fixtures/alpha_fixture_v001.png,,,',
    'build/art-pipeline/fixtures/wide_alpha_fixture_v001.png,,,'
) | Set-Content -LiteralPath $fixtureManifestPath -Encoding utf8

$powerShellBin = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$opaqueFailureOutput = & $powerShellBin `
    -NoProfile -ExecutionPolicy Bypass -File $validatorPath `
    -Path $opaqueFixturePath -RequireAlpha -ManifestPath $fixtureManifestPath 2>&1
$opaqueFailureExit = $LASTEXITCODE
if ($opaqueFailureExit -ne 21) {
    [Console]::Error.WriteLine("[art] FAIL: Opaque PNG fixture should exit 21, got $opaqueFailureExit.")
    [Console]::Error.WriteLine(($opaqueFailureOutput -join [Environment]::NewLine))
    exit 22
}

$duplicateFailureOutput = & $powerShellBin `
    -NoProfile -ExecutionPolicy Bypass -File $validatorPath `
    -Path $allConceptPaths[0] $allConceptPaths[0] -ManifestPath $candidateManifestPath 2>&1
$duplicateFailureExit = $LASTEXITCODE
if ($duplicateFailureExit -ne 21) {
    [Console]::Error.WriteLine("[art] FAIL: Duplicate PNG fixture should exit 21, got $duplicateFailureExit.")
    [Console]::Error.WriteLine(($duplicateFailureOutput -join [Environment]::NewLine))
    exit 22
}

if (Test-Path -LiteralPath $forbiddenOutput) {
    [Console]::Error.WriteLine("[art] FAIL: Forbidden contact-sheet path already exists: $forbiddenOutput")
    exit 22
}
$forbiddenFailureOutput = & $powerShellBin `
    -NoProfile -ExecutionPolicy Bypass -File $contactSheetPath `
    -InputPath $allConceptPaths[0] -OutputPath $forbiddenOutput -Force 2>&1
$forbiddenFailureExit = $LASTEXITCODE
if ($forbiddenFailureExit -eq 0 -or (Test-Path -LiteralPath $forbiddenOutput)) {
    [Console]::Error.WriteLine('[art] FAIL: Contact-sheet writer did not reject game/assets output.')
    [Console]::Error.WriteLine(($forbiddenFailureOutput -join [Environment]::NewLine))
    exit 22
}

& $alphaReviewPath `
    -InputPath @($alphaFixturePath, $wideAlphaFixturePath) `
    -OutputDirectory $alphaReviewSmokeDirectory `
    -Label @('Fixture', 'Wide Fixture') `
    -ManifestPath $fixtureManifestPath `
    -Force
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
$alphaReviewMappingPath = Join-Path $alphaReviewSmokeDirectory 'alpha_review_v001.mapping.json'
$alphaReviewMapping = Get-Content -Raw -LiteralPath $alphaReviewMappingPath | ConvertFrom-Json
if ($alphaReviewMapping.candidates.Count -ne 2 -or
    $alphaReviewMapping.candidates[0].label -ne 'Fixture' -or
    $alphaReviewMapping.candidates[1].label -ne 'Wide Fixture' -or
    [int]$alphaReviewMapping.actual_size_output.width -le 840) {
    [Console]::Error.WriteLine('[art] FAIL: Alpha review mapping or wide-aspect layout is invalid.')
    exit 22
}
foreach ($outputRecord in @($alphaReviewMapping.edge_output, $alphaReviewMapping.actual_size_output)) {
    $outputFullPath = Join-Path $repositoryRoot $outputRecord.path
    if (-not (Test-Path -LiteralPath $outputFullPath -PathType Leaf) -or
        (Get-FileHash -Algorithm SHA256 -LiteralPath $outputFullPath).Hash.ToLowerInvariant() -ne $outputRecord.sha256) {
        [Console]::Error.WriteLine('[art] FAIL: Alpha review smoke output hash mismatch.')
        exit 22
    }
}

$labels = @($allConceptPaths | ForEach-Object {
    [IO.Path]::GetFileNameWithoutExtension($_).Replace('chr_player_concept_', '').Replace('_v001', '').ToUpperInvariant()
})
& $contactSheetPath `
    -InputPath $allConceptPaths `
    -OutputPath $smokeOutput `
    -Label $labels `
    -Columns ([Math]::Min(3, $allConceptPaths.Count)) `
    -ThumbnailHeight 180 `
    -Title 'Capybara Art Pipeline Smoke' `
    -Force
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$smokeImage = [Drawing.Image]::FromFile($smokeOutput)
try {
    if ($smokeImage.Width -le 0 -or $smokeImage.Height -le 0) {
        [Console]::Error.WriteLine('[art] FAIL: Contact sheet smoke output has invalid dimensions.')
        exit 22
    }
}
finally {
    $smokeImage.Dispose()
}

foreach ($candidateCheck in @('check_character_candidates.ps1', 'test_character_candidates.ps1', 'check_npc_concepts.ps1')) {
    & (Join-Path $PSScriptRoot $candidateCheck)
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
[Console]::WriteLine(
    "[art] PASS: $($allConceptPaths.Count) clean-lineage concepts, registered controlled adaptations, environment provenance, alpha and rejection paths verified."
)
exit 0
