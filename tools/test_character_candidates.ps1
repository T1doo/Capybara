[CmdletBinding()]
param([string]$SourceManifestPath)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$checker = Join-Path $PSScriptRoot 'check_character_candidates.ps1'
$globalRows = @(Import-Csv -LiteralPath (Join-Path $repositoryRoot 'docs/production/ASSET_MANIFEST.csv'))
if (-not $SourceManifestPath) {
    $source = $globalRows | Where-Object { $_.category -eq 'character' -and $_.source_method -eq 'ai_assisted_edit' -and $_.source_path -match 'CANDIDATE_MANIFEST\.csv$' } | Select-Object -First 1
    if (-not $source) { throw 'Fixture needs an existing clean controlled candidate; no production candidate count is required by the checker.' }
    $SourceManifestPath = Join-Path $repositoryRoot $source.source_path
}
$sourceRow = @(Import-Csv -LiteralPath $SourceManifestPath)[0]
$sourceRelative = [IO.Path]::GetRelativePath($repositoryRoot, [IO.Path]::GetFullPath($SourceManifestPath)).Replace('\', '/')
$sourceGlobal = $globalRows | Where-Object { $_.source_path -eq $sourceRelative } | Select-Object -First 1
if (-not $sourceGlobal) { throw 'Fixture source manifest needs its production global registration.' }
$runId = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-p' + $PID
$fixtureRoot = Join-Path $repositoryRoot "build/art-pipeline/character-candidate-fixtures/$runId"
$null = New-Item -ItemType Directory -Path $fixtureRoot -Force
$results = [Collections.Generic.List[object]]::new()

function Relative-Path {
    param([string]$FullPath)
    return [IO.Path]::GetRelativePath($repositoryRoot, $FullPath).Replace('\', '/')
}

function Set-Field {
    param([object]$Row, [string]$Name, [object]$Value)
    $Row | Add-Member -NotePropertyName $Name -NotePropertyValue $Value -Force
}

function Add-SyntheticApproval {
    param([object]$Case)
    $reviewPath = Join-Path $Case.root 'SYNTHETIC_REVIEW.md'
    @'
# Synthetic fixture only: no real asset is approved by this record
- visual_review_status: passed
This generated record tests validation behavior and has no production approval effect.
'@ | Set-Content -LiteralPath $reviewPath -Encoding utf8
    $approvalPath = Join-Path $Case.root 'SYNTHETIC_APPROVAL.json'
    Set-Field $Case.row 'status' 'approved_concept'
    Set-Field $Case.row 'visual_review_status' 'passed'
    Set-Field $Case.row 'review_record_path' (Relative-Path $reviewPath)
    Set-Field $Case.row 'approval_record_path' (Relative-Path $approvalPath)
    $Case.global.status = 'approved_concept'
    $record = [ordered]@{
        candidate_id = $Case.row.candidate_id; file_path = $Case.row.file_path; sha256 = $Case.row.sha256
        decision = 'approved_concept'; visual_review_status = 'passed'; scope = 'concept_only'
        review_record_path = $Case.row.review_record_path
        review_record_sha256 = (Get-FileHash -LiteralPath $reviewPath -Algorithm SHA256).Hash.ToLowerInvariant()
        reviewer = 'Synthetic validation fixture, not a production reviewer'
        reviewed_at = [DateTime]::UtcNow.ToString('o'); blocking_findings = 0
    }
    $record | ConvertTo-Json | Set-Content -LiteralPath $approvalPath -Encoding utf8
}

function Invoke-Case {
    param([string]$Name, [scriptblock]$Mutation, [string]$ExpectedFailure = '')
    $root = Join-Path $fixtureRoot $Name
    $null = New-Item -ItemType Directory -Path $root
    $manifest = Join-Path $root 'CANDIDATE_MANIFEST.csv'
    $globalManifest = Join-Path $root 'GLOBAL_MANIFEST.csv'
    $row = $sourceRow.PSObject.Copy()
    $global = $sourceGlobal.PSObject.Copy()
    Set-Field $row 'candidate_id' ('FIXTURE_' + $Name.Replace('-', '_'))
    Set-Field $row 'approval_record_path' ''
    $global.source_path = Relative-Path $manifest
    $global.asset_id = 'fixture_' + $Name
    $case = [pscustomobject]@{ root = $root; row = $row; global = $global; extra = @() }
    if ($Mutation) { & $Mutation $case }
    @($case.row) + @($case.extra) | Export-Csv -LiteralPath $manifest -NoTypeInformation -Encoding utf8
    @($case.global) | Export-Csv -LiteralPath $globalManifest -NoTypeInformation -Encoding utf8
    $arguments = @('-NoProfile', '-File', $checker, '-ManifestPath', $manifest, '-GlobalManifestPath', $globalManifest)
    $output = @(& (Get-Process -Id $PID).Path @arguments 2>&1)
    $exitCode = $LASTEXITCODE
    $text = $output -join [Environment]::NewLine
    $passed = if ($ExpectedFailure) { $exitCode -eq 22 -and $text.Contains($ExpectedFailure) } else { $exitCode -eq 0 }
    $results.Add([pscustomobject]@{ case = $Name; passed = $passed; exit_code = $exitCode; expected_failure = $ExpectedFailure; output = $text })
    if (-not $passed) { [Console]::Error.WriteLine("[character-fixture] FAIL $Name exit=$exitCode`n$text") }
}

Invoke-Case 'valid-technical' $null
Invoke-Case 'valid-synthetic-approved-concept' { param($case) Add-SyntheticApproval $case }
Invoke-Case 'tampered-candidate-hash' { param($case) $case.row.sha256 = '0' * 64 } 'candidate exact hash rejected'
Invoke-Case 'wrong-reference-hash' { param($case) $case.row.reference_sha256 = '0' * 64 } 'Reference hash or clean registry provenance does not match'
Invoke-Case 'quarantine-reference-path' { param($case) $case.row.reference_path = 'art/candidates/_quarantine/forbidden.png' } 'Unsafe or empty reference path'
Invoke-Case 'quarantined-declared-hash' {
    param($case)
    $quarantine = Import-Csv -LiteralPath (Join-Path $repositoryRoot 'art/candidates/_quarantine/player_capybara_v1_unverified_reference/QUARANTINE_MANIFEST.csv')
    $case.row.reference_sha256 = $quarantine[0].sha256
} 'declares a quarantined hash'
Invoke-Case 'missing-review' { param($case) $case.row.review_record_path = Relative-Path (Join-Path $case.root 'missing-review.md') } 'Missing review_record file'
Invoke-Case 'missing-prompt' { param($case) $case.row.prompt_record_path = Relative-Path (Join-Path $case.root 'missing-prompt.md') } 'Missing prompt_record file'
Invoke-Case 'forged-approval-path' {
    param($case)
    $case.row.status = 'approved_concept'
    $case.global.status = 'approved_concept'
    $case.row.approval_record_path = Relative-Path (Join-Path $case.root 'missing-approval.json')
} 'Missing approval_record file'
Invoke-Case 'wrong-approved-image' {
    param($case)
    Add-SyntheticApproval $case
    $path = Join-Path $repositoryRoot $case.row.approval_record_path
    $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $record.sha256 = '0' * 64
    $record | ConvertTo-Json | Set-Content -LiteralPath $path -Encoding utf8
} 'Approval record does not identify this exact candidate'
Invoke-Case 'approval-without-passed-review' {
    param($case)
    Add-SyntheticApproval $case
    $review = Join-Path $repositoryRoot $case.row.review_record_path
    '- visual_review_status: changes_required' | Set-Content -LiteralPath $review -Encoding utf8
    $path = Join-Path $repositoryRoot $case.row.approval_record_path
    $record = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
    $record.review_record_sha256 = (Get-FileHash -LiteralPath $review -Algorithm SHA256).Hash.ToLowerInvariant()
    $record | ConvertTo-Json | Set-Content -LiteralPath $path -Encoding utf8
} 'Visual review does not explicitly record'
Invoke-Case 'duplicate-id' { param($case) $case.extra = @($case.row.PSObject.Copy()) } 'Duplicate candidate ID'
Invoke-Case 'duplicate-path' {
    param($case)
    $extra = $case.row.PSObject.Copy()
    $extra.candidate_id = 'SECOND_FIXTURE_ID'
    $case.extra = @($extra)
} 'Duplicate candidate file path'
Invoke-Case 'missing-global-registration' { param($case) $case.global.source_path = 'build/absent-manifest.csv' } 'must have one global registration, found 0'
Invoke-Case 'status-mismatch' { param($case) $case.global.status = 'approved_concept' } 'Global and local candidate status disagree'
Invoke-Case 'unapproved-game-path' { param($case) $case.row.game_path = 'game/assets/not-authorized.png' } 'cannot publish a game_path'
Invoke-Case 'game-file-path-with-empty-game-path' { param($case) $case.row.file_path = 'game/assets/not-authorized.png'; $case.row.game_path = '' } 'Candidate PNG must stay under art/candidates'
Invoke-Case 'raw-file-path-with-empty-game-path' { param($case) $case.row.file_path = 'art/generated_raw/character/not-a-candidate.png'; $case.row.game_path = '' } 'Candidate PNG must stay under art/candidates'
Invoke-Case 'unsupported-game-ready-status' { param($case) $case.row.status = 'game_ready'; $case.global.status = 'game_ready' } 'Unsupported candidate lifecycle status'
Invoke-Case 'wrong-dimensions' { param($case) $case.row.width = [string]([int]$case.row.width + 1) } 'Candidate PNG validation failed'
Invoke-Case 'opaque-disguised-as-candidate' {
    param($case)
    $legacyRows = @(Import-Csv -LiteralPath (Join-Path $repositoryRoot 'art/candidates/player_capybara_v1/CANDIDATE_MANIFEST.csv'))
    $opaque = $legacyRows | Where-Object { $_.pixel_format -eq 'Format24bppRgb' -and $_.rights_status -eq 'clean_text_only' } | Select-Object -First 1
    $reference = $legacyRows | Where-Object { $_.file_path -ne $opaque.file_path -and $_.rights_status -eq 'clean_text_only' } | Select-Object -First 1
    if (-not $opaque -or -not $reference) { throw 'Opaque negative case needs two existing clean text-only concepts.' }
    $case.row.file_path = $opaque.file_path
    $case.row.sha256 = $opaque.sha256
    $case.row.width = $opaque.width
    $case.row.height = $opaque.height
    $case.row.pixel_format = 'Format24bppRgb'
    $case.row.reference_path = $reference.file_path
    $case.row.reference_sha256 = $reference.sha256
} 'Candidate PNG validation failed'

# Exercise the actual pure coverage function with synthetic path sets, never production PNG writes.
$tokens = $null
$parseErrors = $null
$checkerAst = [Management.Automation.Language.Parser]::ParseFile($checker, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count) { throw 'Candidate checker has parse errors.' }
$coverageFunction = $checkerAst.Find({ param($node) $node -is [Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Get-UnregisteredCandidatePaths' }, $true)
if (-not $coverageFunction) { throw 'Missing production coverage function.' }
. ([scriptblock]::Create($coverageFunction.Extent.Text))
foreach ($case in @(
    @{ Name = 'coverage-registered'; Existing = @('art/candidates/example/one.png'); Registered = @('art/candidates/example/one.png'); Expected = @() },
    @{ Name = 'coverage-unregistered-png'; Existing = @('art/candidates/example/one.png', 'art/candidates/example/unregistered.png'); Registered = @('art/candidates/example/one.png'); Expected = @('art/candidates/example/unregistered.png') },
    @{ Name = 'coverage-scope-excludes-child-and-build'; Existing = @('art/candidates/example/one.png', 'art/candidates/example/qa/board.png', 'build/qa/board.png', 'art/candidates/other/other.png'); Registered = @('art/candidates/example/one.png'); Expected = @() },
    @{ Name = 'coverage-path-separators-and-case'; Existing = @('art/candidates/example/one.png'); Registered = @('ART\CANDIDATES\EXAMPLE\ONE.PNG'); Expected = @() }
)) {
    $actual = @(Get-UnregisteredCandidatePaths -DirectoryPath 'art/candidates/example' -ExistingPaths $case.Existing -RegisteredPaths $case.Registered)
    $passed = ($actual -join '|') -ceq ($case.Expected -join '|')
    $results.Add([pscustomobject]@{ case = $case.Name; passed = $passed; exit_code = $null; expected_failure = ''; output = "Unregistered paths: $($actual -join ', ')" })
    if (-not $passed) { [Console]::Error.WriteLine("[character-fixture] FAIL $($case.Name)") }
}

$productionScopePath = Join-Path $fixtureRoot 'production_scope.json'
$scopeOutput = @(& $checker -JsonOutputPath $productionScopePath 2>&1)
$scopeExit = $LASTEXITCODE
$scopeRows = if ($scopeExit -eq 0 -and (Test-Path -LiteralPath $productionScopePath)) {
    @((Get-Content -LiteralPath $productionScopePath -Raw | ConvertFrom-Json).candidates)
} else { @() }
$scopePassed = $scopeExit -eq 0 -and @($scopeRows | Where-Object { $_.manifest -match 'npc_river_residents_v001' }).Count -eq 0
$results.Add([pscustomobject]@{ case = 'independent-npc-visual-concepts-out-of-scope'; passed = $scopePassed;
    exit_code = $scopeExit; expected_failure = ''; output = ($scopeOutput -join ' ') })
if (-not $scopePassed) { [Console]::Error.WriteLine('[character-fixture] FAIL independent-npc-visual-concepts-out-of-scope') }

$reportPath = Join-Path $fixtureRoot 'results.json'
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $reportPath -Encoding utf8
$logDirectory = Join-Path $repositoryRoot 'build/logs'
$null = New-Item -ItemType Directory -Path $logDirectory -Force
Copy-Item -LiteralPath $reportPath -Destination (Join-Path $logDirectory "character-candidate-fixtures-$runId.json")
if (@($results | Where-Object { -not $_.passed }).Count) { exit 22 }
[Console]::WriteLine("[character-fixture] PASS: $($results.Count)/$($results.Count); $reportPath")
exit 0
