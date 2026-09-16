[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$requiredFiles = @(
    'CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md',
    'AGENTS.md',
    'PLANS.md',
    'docs\AUTONOMOUS_STATUS.md',
    'docs\QUALITY_GATES.md',
    'docs\KNOWN_ISSUES.md',
    'docs\RELEASE_READINESS.md',
    'docs\AUTONOMOUS_RECOVERY.md',
    'docs\DEPENDENCIES.md',
    'docs\BACKLOG.csv'
)
$requiredToolFiles = @(
    '.github\workflows\ci.yml',
    'game\export_presets.cfg',
    'tools\build_smoke.ps1',
    'tools\check_governance.ps1',
    'tools\check_project.ps1',
    'tools\check_format.ps1'
    'tools\check_art_assets.ps1'
    'tools\validate_png_assets.ps1'
    'tools\make_contact_sheet.ps1'
    'tools\make_alpha_review_sheet.ps1'
    'tools\render_svg_preview.ps1'
    'tools\check_svg_cutout_alpha.ps1'
    'tools\check_localization.ps1'
    'tools\check_settings_restart.ps1'
    'tools\check_save_restart.ps1'
)
$legacyFiles = @(
    '00_START_HERE_E_DRIVE.md',
    'README_FIRST.md',
    'MASTER_PROMPT_FOR_CODEX.md',
    'CAPYBARA_COMPLETE_PLAN_FOR_CODEX.md',
    'SEND_TO_CODEX_FIRST_MESSAGE.txt',
    'SEND_TO_CODEX_AFTER_PLAN.txt',
    'SEND_TO_CODEX_MESSAGES.md'
)
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($relativePath in $requiredFiles) {
    $fullPath = Join-Path $repositoryRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        $failures.Add("Missing required governance file: $relativePath")
        continue
    }
    if ((Get-Item -LiteralPath $fullPath).Length -eq 0) {
        $failures.Add("Governance file is empty: $relativePath")
    }
}

foreach ($relativePath in $requiredToolFiles) {
    $fullPath = Join-Path $repositoryRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        $failures.Add("Missing required Stage 0.5 tool or CI file: $relativePath")
    }
}

$contentRequirements = @(
    @{ Path = 'AGENTS.md'; Text = 'CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md' },
    @{ Path = 'PLANS.md'; Text = 'docs/AUTONOMOUS_STATUS.md' },
    @{ Path = 'docs\AUTONOMOUS_STATUS.md'; Text = 'codex/autonomous-v1' },
    @{ Path = 'docs\QUALITY_GATES.md'; Text = 'Stage 0.5' },
    @{ Path = 'docs\KNOWN_ISSUES.md'; Text = 'GIT-001' },
    @{ Path = 'docs\RELEASE_READINESS.md'; Text = 'capybara-rc1' },
    @{ Path = 'docs\DEPENDENCIES.md'; Text = '4.7.2-stable' }
)

foreach ($requirement in $contentRequirements) {
    $fullPath = Join-Path $repositoryRoot $requirement.Path
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        continue
    }
    $content = Get-Content -LiteralPath $fullPath -Raw
    if (-not $content.Contains($requirement.Text)) {
        $failures.Add("Missing required reference '$($requirement.Text)' in $($requirement.Path)")
    }
}

foreach ($relativePath in $legacyFiles) {
    $fullPath = Join-Path $repositoryRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        $failures.Add("Missing legacy snapshot that should remain auditable: $relativePath")
        continue
    }
    $content = Get-Content -LiteralPath $fullPath -Raw
    if (-not $content.Contains('历史启动快照')) {
        $failures.Add("Legacy instruction file lacks a deprecation banner: $relativePath")
    }
}

$packageManifestPath = Join-Path $repositoryRoot 'PACKAGE_MANIFEST.json'
if (Test-Path -LiteralPath $packageManifestPath -PathType Leaf) {
    try {
        $packageManifest = Get-Content -LiteralPath $packageManifestPath -Raw | ConvertFrom-Json
        if ($packageManifest.status -ne 'historical_starter_snapshot') {
            $failures.Add('PACKAGE_MANIFEST.json is not marked as a historical starter snapshot.')
        }
        if ($packageManifest.superseded_by -ne 'CODEX_AUTONOMOUS_GAME_PRODUCTION_GOAL_v2.md') {
            $failures.Add('PACKAGE_MANIFEST.json does not point to the active goal contract.')
        }
    }
    catch {
        $failures.Add("PACKAGE_MANIFEST.json is not valid JSON: $($_.Exception.Message)")
    }
}
else {
    $failures.Add('PACKAGE_MANIFEST.json is missing.')
}

$deprecatedToolPath = 'E:' + '\Tools\Godot'
$governanceFiles = $requiredFiles | ForEach-Object { Join-Path $repositoryRoot $_ }
$deprecatedMatches = Select-String -LiteralPath $governanceFiles -SimpleMatch $deprecatedToolPath
if ($deprecatedMatches) {
    $failures.Add("Deprecated tool path is present in active governance files: $deprecatedToolPath")
}

$runtimeFiles = @(
    Get-ChildItem -LiteralPath (Join-Path $repositoryRoot 'game') -Recurse -File |
        Where-Object { $_.FullName -notlike '*\.godot\*' }
    Get-ChildItem -LiteralPath (Join-Path $repositoryRoot 'tools') -Recurse -File |
        Where-Object { $_.Name -ne 'check_governance.ps1' }
    Get-ChildItem -LiteralPath (Join-Path $repositoryRoot '.github') -Recurse -File
)
# The absolute-path policy covers executable text and configuration. Compressed image
# bytes can accidentally match a UNC pattern and are validated by the asset pipeline.
$runtimeTextExtensions = @(
    '.gd', '.gdshader', '.glsl', '.godot', '.tscn', '.tres', '.cfg', '.import',
    '.gdextension', '.json', '.csv', '.yaml', '.yml', '.ps1', '.psm1', '.psd1',
    '.cmd', '.bat', '.sh', '.py', '.js', '.ts', '.svg', '.md', '.txt', '.uid'
)
$runtimePathMatches = foreach ($file in $runtimeFiles) {
    if ($file.Extension.ToLowerInvariant() -notin $runtimeTextExtensions) {
        continue
    }
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $file.FullName) {
        $lineNumber += 1
        if ($line -match '(?i)([A-Z]:\\(?:Users|Capybara|GameDev|Tools|Program Files)|\\\\[^\\\s]+\\)') {
            '{0}:{1}: {2}' -f $file.FullName, $lineNumber, $line
        }
    }
}
if ($runtimePathMatches) {
    $failures.Add("Absolute local paths are present in executable project/config files: $($runtimePathMatches -join '; ')")
}

$backlogPath = Join-Path $repositoryRoot 'docs\BACKLOG.csv'
try {
    $backlogRows = @(Import-Csv -LiteralPath $backlogPath)
    $requiredBacklogColumns = @(
        'id', 'phase', 'epic', 'task', 'priority', 'dependencies',
        'acceptance_criteria', 'status', 'owner_notes'
    )
    $actualColumns = @($backlogRows[0].PSObject.Properties.Name)
    foreach ($column in $requiredBacklogColumns) {
        if ($column -notin $actualColumns) {
            $failures.Add("BACKLOG.csv is missing required column: $column")
        }
    }
    $duplicateIds = @($backlogRows | Group-Object id | Where-Object { $_.Count -gt 1 })
    if ($duplicateIds.Count -gt 0) {
        $failures.Add("BACKLOG.csv contains duplicate IDs: $($duplicateIds.Name -join ', ')")
    }
    $validStatuses = @('todo', 'in_progress', 'done', 'superseded')
    $invalidStatuses = @($backlogRows | Where-Object { $_.status -notin $validStatuses })
    if ($invalidStatuses.Count -gt 0) {
        $failures.Add("BACKLOG.csv contains invalid statuses: $($invalidStatuses.id -join ', ')")
    }
    $requiredValueColumns = @('id', 'phase', 'epic', 'task', 'priority', 'acceptance_criteria', 'status')
    foreach ($row in $backlogRows) {
        foreach ($column in $requiredValueColumns) {
            if ([string]::IsNullOrWhiteSpace($row.$column)) {
                $failures.Add("BACKLOG.csv row '$($row.id)' has an empty required field: $column")
            }
        }
        $parsedPhase = 0.0
        if (-not [double]::TryParse($row.phase, [ref]$parsedPhase)) {
            $failures.Add("BACKLOG.csv row '$($row.id)' has an invalid numeric phase: $($row.phase)")
        }
        if ($row.priority -notin @('P0', 'P1', 'P2', 'P3')) {
            $failures.Add("BACKLOG.csv row '$($row.id)' has an invalid priority: $($row.priority)")
        }
    }

    $rowById = @{}
    foreach ($row in $backlogRows) {
        $rowById[$row.id] = $row
    }
    $adjacency = @{}
    $inDegree = @{}
    foreach ($row in $backlogRows) {
        $adjacency[$row.id] = [System.Collections.Generic.List[string]]::new()
        $inDegree[$row.id] = 0
    }
    foreach ($row in $backlogRows) {
        $dependencies = @($row.dependencies -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        foreach ($dependency in $dependencies) {
            if (-not $rowById.ContainsKey($dependency)) {
                $failures.Add("BACKLOG.csv task $($row.id) references missing dependency $dependency")
                continue
            }
            $currentPhase = [double]$row.phase
            $dependencyPhase = [double]$rowById[$dependency].phase
            if ($dependencyPhase -gt $currentPhase) {
                $failures.Add("BACKLOG.csv task $($row.id) depends on future Stage task $dependency")
            }
            $adjacency[$dependency].Add($row.id)
            $inDegree[$row.id] += 1
        }
    }

    $queue = [System.Collections.Generic.Queue[string]]::new()
    foreach ($row in $backlogRows) {
        if ($inDegree[$row.id] -eq 0) {
            $queue.Enqueue($row.id)
        }
    }
    $visitedCount = 0
    while ($queue.Count -gt 0) {
        $id = $queue.Dequeue()
        $visitedCount += 1
        foreach ($dependentId in $adjacency[$id]) {
            $inDegree[$dependentId] -= 1
            if ($inDegree[$dependentId] -eq 0) {
                $queue.Enqueue($dependentId)
            }
        }
    }
    if ($visitedCount -ne $backlogRows.Count) {
        $failures.Add('BACKLOG.csv dependency graph contains a cycle.')
    }
}
catch {
    $failures.Add("BACKLOG.csv validation failed: $($_.Exception.Message)")
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        [Console]::Error.WriteLine("[governance] FAIL: $failure")
    }
    exit 10
}

[Console]::WriteLine("[governance] PASS: $($requiredFiles.Count) governance files, $($requiredToolFiles.Count) tool/CI files, $($legacyFiles.Count) legacy banners, and $($backlogRows.Count) backlog rows verified.")
exit 0
