[CmdletBinding()]
param(
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '..'),
    [switch]$DocumentFixture
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath $RepositoryRoot).ProviderPath
if ($DocumentFixture) {
    $fixtureBoundary = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../build/governance-fixtures'))
    if (-not $repositoryRoot.StartsWith($fixtureBoundary + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'DocumentFixture can only inspect minimal generated fixtures under build/governance-fixtures.'
    }
}
$failures = [System.Collections.Generic.List[string]]::new()
$requiredFiles = @(
    'README.md', 'AGENTS.md', 'PLANS.md', 'CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md',
    'docs/README.md', 'docs/STATUS.md', 'docs/ISSUES.md', 'docs/QUALITY_GATES.md',
    'docs/RELEASE_READINESS.md', 'docs/design/GAME_DESIGN.md', 'docs/design/TECHNICAL_DESIGN.md',
    'docs/design/ART_BIBLE.md', 'docs/design/CONTENT_CATALOG.csv',
    'docs/production/ASSET_PIPELINE.md', 'docs/production/RIGHTS_AND_AI_POLICY.md',
    'docs/production/DEPENDENCIES.md', 'docs/production/ASSET_MANIFEST.csv'
)
$requiredToolFiles = @(
    '.github/workflows/ci.yml', 'game/export_presets.cfg', 'tools/build_smoke.ps1',
    'tools/check_governance.ps1', 'tools/test_governance.ps1', 'tools/check_project.ps1',
    'tools/check_format.ps1', 'tools/check_art_assets.ps1', 'tools/validate_png_assets.ps1',
    'tools/make_contact_sheet.ps1', 'tools/make_alpha_review_sheet.ps1', 'tools/render_svg_preview.ps1',
    'tools/check_svg_cutout_alpha.ps1', 'tools/check_localization.ps1',
    'tools/check_settings_restart.ps1', 'tools/check_save_restart.ps1'
)
$stageDirectories = @('stage-00', 'stage-00-5') + @(1..12 | ForEach-Object { 'stage-{0:D2}' -f $_ })
$stageIds = @('0', '0.5') + @(1..12 | ForEach-Object { [string]$_ })
$stageStatuses = @('not_started', 'in_progress', 'blocked', 'historical_passed', 'passed')
$taskStatuses = @('todo', 'in_progress', 'blocked', 'done', 'superseded')
$allTasks = [System.Collections.Generic.List[object]]::new()
$planPaths = [System.Collections.Generic.List[string]]::new()

function Read-RequiredFile {
    param([string]$RelativePath)
    $path = Join-Path $repositoryRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $failures.Add("Missing required file: $RelativePath")
        return ''
    }
    $content = Get-Content -LiteralPath $path -Raw
    if ([string]::IsNullOrWhiteSpace($content)) {
        $failures.Add("Required file is empty: $RelativePath")
        return ''
    }
    return $content
}

function Resolve-DocumentReference {
    param([string]$Reference, [string]$Document)
    $cleanReference = [Uri]::UnescapeDataString(($Reference.Trim('<>') -split '#', 2)[0])
    if (-not $cleanReference) { return (Join-Path $repositoryRoot $Document) }
    if ($cleanReference -match '^(?:https?://|mailto:)' -or [IO.Path]::IsPathRooted($cleanReference)) { return $null }
    $documentDirectory = Split-Path (Join-Path $repositoryRoot $Document) -Parent
    $relativeCandidate = [IO.Path]::GetFullPath((Join-Path $documentDirectory $cleanReference))
    $rootCandidate = [IO.Path]::GetFullPath((Join-Path $repositoryRoot $cleanReference))
    # Both repository-root paths and normal document-relative Markdown are supported.
    $candidate = if (Test-Path -LiteralPath $relativeCandidate) { $relativeCandidate } else { $rootCandidate }
    if (-not $candidate.StartsWith($repositoryRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { return $null }
    return $candidate
}

function Test-Evidence {
    param([string]$Evidence, [string]$Document, [string]$Owner)
    if ([string]::IsNullOrWhiteSpace($Evidence) -or $Evidence.Trim() -in @('-', '—')) {
        $failures.Add("Missing completion evidence: $Owner in $Document")
        return
    }
    $historical = $Evidence -match 'historical_report:'
    $references = @([regex]::Matches($Evidence, '\[[^\]]+\]\(([^)]+)\)') | ForEach-Object { $_.Groups[1].Value })
    if ($references.Count -eq 0) {
        $references = @([regex]::Matches($Evidence, '`([^`]+\.(?:md|json|log|png|csv|txt))`') | ForEach-Object { $_.Groups[1].Value })
    }
    if ($references.Count -eq 0 -and $Evidence -match '^\s*(?:historical_report:\s*)?([^\s]+\.(?:md|json|log|png|csv|txt))\s*$') { $references = @($Matches[1]) }
    if ($references.Count -eq 0) {
        $failures.Add("Completion evidence needs a resolvable local artifact link: $Owner in $Document")
        return
    }
    foreach ($reference in $references) {
        $path = Resolve-DocumentReference $reference $Document
        if (-not $path -or -not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $failures.Add("Missing evidence path '$reference': $Owner in $Document")
            continue
        }
        if ((Get-Item -LiteralPath $path).Length -eq 0) { $failures.Add("Empty evidence path '$reference': $Owner in $Document") }
        if ($historical) {
            $historicalContent = Get-Content -LiteralPath $path -Raw
            if ($historicalContent -notmatch '\b[0-9a-f]{40}\b' -or $historicalContent -notmatch '(?i)historical|历史') {
                $failures.Add("Historical evidence lacks a source commit and historical scope: $Owner in $Document")
            }
        }
    }
}

foreach ($relativePath in @($requiredFiles + $requiredToolFiles)) { $null = Read-RequiredFile $relativePath }
$contentRequirements = @(
    @{ Path = 'AGENTS.md'; Text = 'CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md' },
    @{ Path = 'docs/RELEASE_READINESS.md'; Text = 'capybara-rc1' },
    @{ Path = 'docs/production/DEPENDENCIES.md'; Text = '4.7.2-stable' }
)
foreach ($requirement in $contentRequirements) {
    $content = Read-RequiredFile $requirement.Path
    if (-not $content.Contains($requirement.Text)) { $failures.Add("Missing required reference '$($requirement.Text)' in $($requirement.Path)") }
}
$plansIndex = Read-RequiredFile 'PLANS.md'
$docsIndex = Read-RequiredFile 'docs/README.md'
$stageRoot = Join-Path $repositoryRoot 'docs/stages'
if (Test-Path -LiteralPath $stageRoot) {
    foreach ($directory in Get-ChildItem -LiteralPath $stageRoot -Directory) {
        if ($directory.Name -notin $stageDirectories) { $failures.Add("Unexpected stage directory: $($directory.Name)") }
    }
}

for ($stageIndex = 0; $stageIndex -lt $stageDirectories.Count; $stageIndex++) {
    $directory = $stageDirectories[$stageIndex]
    $stageId = $stageIds[$stageIndex]
    $planPath = "docs/stages/$directory/PLAN.md"
    $logPath = "docs/stages/$directory/LOG.md"
    $planPaths.Add($planPath)
    $plan = Read-RequiredFile $planPath
    $null = Read-RequiredFile $logPath
    foreach ($index in @(@{ Name = 'PLANS.md'; Text = $plansIndex }, @{ Name = 'docs/README.md'; Text = $docsIndex })) {
        if ($index.Text -notmatch ([regex]::Escape("stages/$directory/PLAN.md"))) { $failures.Add("Stage PLAN missing from $($index.Name): $directory") }
    }
    if (-not $plan) { continue }
    if ($plan -notmatch ('(?m)^- stage_id:\s*"' + [regex]::Escape($stageId) + '"\s*$')) { $failures.Add("Invalid semantic stage_id in $planPath; expected quoted string '$stageId'.") }
    $stageStatus = if ($plan -match '(?m)^- status:\s*(\S+)\s*$') { $Matches[1] } else { '' }
    if ($stageStatus -notin $stageStatuses) { $failures.Add("Invalid stage status '$stageStatus' in $planPath") }
    if ($stageStatus -in @('passed', 'historical_passed')) {
        $stageEvidence = if ($plan -match '(?m)^- evidence:\s*(.+)$') { $Matches[1] } else { '' }
        if ($stageStatus -eq 'historical_passed' -and $stageEvidence -notmatch 'historical_report:') { $failures.Add("historical_passed requires historical_report evidence in $planPath") }
        if ($stageStatus -eq 'passed' -and $stageEvidence -match 'historical_report:') { $failures.Add("Passed stage needs current verification, not historical_report evidence in $planPath") }
        Test-Evidence $stageEvidence $planPath "Stage $stageId"
    }
    $taskTable = $false
    $taskCount = 0
    foreach ($line in ($plan -split '\r?\n')) {
        if ($line -match '^\|\s*ID\s*\|') {
            $headers = @($line.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim() })
            $expected = @('ID', '交付任务', '优先级', '依赖 ID', '验收与证据要求', '状态', '证据')
            if (($headers -join '|') -ne ($expected -join '|')) { $failures.Add("Invalid task table schema in $planPath; expected $($expected -join ' | ')") }
            $taskTable = $true
            continue
        }
        if (-not $taskTable) { continue }
        if ($line -match '^\|[\s:|\-]+\|\s*$') { continue }
        if ($line -notmatch '^\|') { $taskTable = $false; continue }
        $cells = @($line.Trim().Trim('|') -split '\|' | ForEach-Object { $_.Trim().Trim('`') })
        if ($cells.Count -ne 7) { $failures.Add("Task must have 7 columns in $planPath`: $line"); continue }
        $taskCount++
        $task = [pscustomobject]@{
            Id = $cells[0]; Goal = $cells[1]; Priority = $cells[2]; Dependencies = $cells[3]
            Acceptance = $cells[4]; Status = $cells[5]; Evidence = $cells[6]; Stage = $stageId; Document = $planPath
        }
        $allTasks.Add($task)
        if ($task.Id -notmatch '^[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)+$') { $failures.Add("Invalid task ID '$($task.Id)' in $planPath") }
        if ($task.Priority -notin @('P0', 'P1', 'P2', 'P3')) { $failures.Add("Invalid priority on $($task.Id)") }
        if ($task.Status -notin $taskStatuses) { $failures.Add("Invalid task status on $($task.Id): $($task.Status)") }
        foreach ($field in @('Goal', 'Acceptance')) {
            if ([string]::IsNullOrWhiteSpace($task.$field) -or $task.$field -in @('-', '—')) { $failures.Add("Empty $field on $($task.Id)") }
        }
        if ($task.Status -eq 'done') { Test-Evidence $task.Evidence $planPath $task.Id }
        if ($stageStatus -eq 'passed' -and $task.Status -notin @('done', 'superseded')) { $failures.Add("Passed Stage $stageId contains unfinished task $($task.Id)") }
    }
    if ($taskCount -eq 0) { $failures.Add("No tasks in $planPath") }
}

$byId = @{}
$inDegree = @{}
$adjacency = @{}
foreach ($task in $allTasks) {
    if ($byId.ContainsKey($task.Id)) { $failures.Add("Duplicate task ID: $($task.Id)"); continue }
    $byId[$task.Id] = $task
    $inDegree[$task.Id] = 0
    $adjacency[$task.Id] = [System.Collections.Generic.List[string]]::new()
}
foreach ($task in $byId.Values) {
    foreach ($dependency in @($task.Dependencies -split ',' | ForEach-Object { $_.Trim().Trim('`') } | Where-Object { $_ -and $_ -notin @('-', '—') })) {
        if (-not $byId.ContainsKey($dependency)) { $failures.Add("Missing dependency $dependency on $($task.Id)"); continue }
        $adjacency[$dependency].Add($task.Id)
        $inDegree[$task.Id]++
        if ($task.Status -eq 'done' -and $task.Evidence -notmatch 'historical_report:' -and $byId[$dependency].Status -notin @('done', 'superseded')) {
            $failures.Add("Completed task $($task.Id) still has unfinished dependency $dependency")
        }
        # A regression may depend on later-stage capability; that exception needs an explicit rationale.
        $currentStage = [double]::Parse($task.Stage, [Globalization.CultureInfo]::InvariantCulture)
        $dependencyStage = [double]::Parse($byId[$dependency].Stage, [Globalization.CultureInfo]::InvariantCulture)
        if ($dependencyStage -gt $currentStage -and $task.Acceptance -notmatch '(?i)regression|回归|前置能力') { $failures.Add("Future-stage dependency $dependency on $($task.Id) needs an explicit regression/capability rationale.") }
    }
}
$queue = [System.Collections.Generic.Queue[string]]::new()
foreach ($id in $byId.Keys) { if ($inDegree[$id] -eq 0) { $queue.Enqueue($id) } }
$visitedCount = 0
while ($queue.Count -gt 0) {
    $id = $queue.Dequeue()
    $visitedCount++
    foreach ($dependent in $adjacency[$id]) { $inDegree[$dependent]--; if ($inDegree[$dependent] -eq 0) { $queue.Enqueue($dependent) } }
}
if ($visitedCount -ne $byId.Count) { $failures.Add('Stage task dependency graph contains a cycle.') }

$status = Read-RequiredFile 'docs/STATUS.md'
$safeBranch = if ($status -match '(?m)^- safe_branch:\s*`?([^`\s]+)`?\s*$') { $Matches[1] } else { '' }
$baseline = if ($status -match '(?m)^- review_baseline:\s*`?([0-9a-f]{40})`?\s*$') { $Matches[1] } else { '' }
if (-not $safeBranch -or $safeBranch -in @('codex/autonomous-v1', 'main')) { $failures.Add('STATUS needs an explicit safe development branch, separate from legacy main/autonomous-v1.') }
if ($baseline -ne '79092c078c63c1e1d5a6d056ebcedf8401a9ac59') { $failures.Add('STATUS review_baseline must identify the verified clean review snapshot.') }
if (-not $DocumentFixture -and $baseline -eq '79092c078c63c1e1d5a6d056ebcedf8401a9ac59') {
    $null = & git -C $repositoryRoot merge-base --is-ancestor $baseline HEAD 2>&1
    if ($LASTEXITCODE -ne 0) { $failures.Add('Current HEAD does not descend from the verified review baseline.') }
    foreach ($unsafeAncestor in @('4a9e2738a72f35508df23ce883884397029760d3', '25efe67')) {
        $null = & git -C $repositoryRoot rev-parse --verify "$unsafeAncestor^{commit}" 2>&1
        if ($LASTEXITCODE -eq 0) {
            $null = & git -C $repositoryRoot merge-base --is-ancestor $unsafeAncestor HEAD 2>&1
            if ($LASTEXITCODE -eq 0) { $failures.Add("Unsafe old development ancestry is reachable from HEAD: $unsafeAncestor") }
        }
    }
    $currentHistory = [Collections.Generic.HashSet[string]]::new([string[]]@(& git -C $repositoryRoot rev-list HEAD --not $baseline))
    $cleanDescendants = [Collections.Generic.HashSet[string]]::new([string[]]@(& git -C $repositoryRoot rev-list --ancestry-path "$baseline..HEAD"))
    foreach ($introducedCommit in $currentHistory) {
        if (-not $cleanDescendants.Contains($introducedCommit)) {
            $failures.Add("Foreign ancestry introduced outside the clean review descendants: $introducedCommit")
        }
    }
    foreach ($oldReference in @('refs/heads/codex/autonomous-v1', 'refs/tags/capybara-stage-02')) {
        $null = & git -C $repositoryRoot rev-parse --verify "$oldReference^{commit}" 2>&1
        if ($LASTEXITCODE -ne 0) { continue }
        foreach ($oldCommit in @(& git -C $repositoryRoot rev-list $oldReference --not $baseline)) {
            if ($currentHistory.Contains($oldCommit)) { $failures.Add("Old development history reconnected from $oldReference at $oldCommit") }
        }
    }
    $currentBranch = ([string](& git -C $repositoryRoot branch --show-current)).Trim()
    if ($currentBranch -and $currentBranch -notin @($safeBranch, 'main')) { $failures.Add("STATUS safe_branch '$safeBranch' differs from actual branch '$currentBranch'.") }
}

$activeDocuments = @($requiredFiles | Where-Object { $_.EndsWith('.md') }) + @($planPaths)
foreach ($document in $activeDocuments) {
    $path = Join-Path $repositoryRoot $document
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $content = Get-Content -LiteralPath $path -Raw
    foreach ($match in [regex]::Matches($content, '\[[^\]]+\]\(([^)]+)\)')) {
        $reference = $match.Groups[1].Value
        if ($reference -match '^(?:https?://|mailto:|#)') { continue }
        $target = Resolve-DocumentReference $reference $document
        if (-not $target -or -not (Test-Path -LiteralPath $target)) { $failures.Add("Broken active document link '$reference' in $document") }
    }
    foreach ($paragraph in ($content -split '(?:\r?\n){2,}')) {
        # Historical prose may cite retired files, but it must identify its immutable source scope.
        if ($paragraph -match '(?i)historical|历史' -and $paragraph -match '\b[0-9a-f]{40}\b') { continue }
        foreach ($referenceMatch in [regex]::Matches($paragraph, 'docs[/\\](?:[A-Za-z0-9_.-]+[/\\])*[A-Za-z0-9_.-]+\.(?:md|csv)')) {
            $reference = $referenceMatch.Value
            if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot $reference))) { $failures.Add("Stale active document reference '$reference' in $document; historical citations need a source commit and scope.") }
        }
    }
}
if (Test-Path -LiteralPath (Join-Path $repositoryRoot 'docs/BACKLOG.csv')) { $failures.Add('A second editable task source remains: docs/BACKLOG.csv. Derive summaries under build from stage PLAN files.') }

$runtimeTextExtensions = @(
    '.gd', '.gdshader', '.glsl', '.godot', '.tscn', '.tres', '.cfg', '.import', '.gdextension',
    '.json', '.csv', '.yaml', '.yml', '.ps1', '.psm1', '.psd1', '.cmd', '.bat', '.sh',
    '.py', '.js', '.ts', '.svg', '.md', '.txt', '.uid'
)
$runtimeFiles = foreach ($directory in @('game', 'tools', '.github')) {
    $path = Join-Path $repositoryRoot $directory
    if (Test-Path -LiteralPath $path) {
        Get-ChildItem -LiteralPath $path -Recurse -File | Where-Object {
            $_.FullName -notmatch '[\\/]\.godot[\\/]' -and $_.Name -notin @('check_governance.ps1', 'test_governance.ps1')
        }
    }
}
foreach ($file in $runtimeFiles) {
    if ($file.Extension.ToLowerInvariant() -notin $runtimeTextExtensions) { continue }
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $file.FullName) {
        $lineNumber++
        if ($line -match '(?i)([A-Z]:\\(?:Users|Capybara|GameDev|Tools|Program Files)|\\\\[^\\\s]+\\)') { $failures.Add("Absolute local path in executable project/config: $($file.FullName):$lineNumber") }
        # Inspect actual local docs references, not prose mentioning a prohibited git command.
        foreach ($referenceMatch in [regex]::Matches($line, 'docs[/\\](?:[A-Za-z0-9_.-]+[/\\])*[A-Za-z0-9_.-]+\.(?:md|csv)')) {
            $reference = $referenceMatch.Value
            if (-not (Test-Path -LiteralPath (Join-Path $repositoryRoot $reference))) { $failures.Add("Stale executable document reference '$reference' in $($file.Name):$lineNumber") }
        }
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) { [Console]::Error.WriteLine("[governance] FAIL: $failure") }
    exit 10
}
if (-not $DocumentFixture) {
    & (Get-Process -Id $PID).Path -NoProfile -File (Join-Path $PSScriptRoot 'test_governance.ps1')
    if ($LASTEXITCODE -ne 0) { exit 10 }
}
[Console]::WriteLine("[governance] PASS: $($stageDirectories.Count) stages, $($allTasks.Count) tasks, evidence/dependencies, active links, safe branch and executable paths verified.")
exit 0
