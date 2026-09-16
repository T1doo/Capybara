[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$catalogPath = Join-Path $repositoryRoot 'game\localization\translations.csv'
$failures = [System.Collections.Generic.List[string]]::new()
if (-not (Test-Path -LiteralPath $catalogPath -PathType Leaf)) {
    [Console]::Error.WriteLine('[localization] FAIL: translations.csv is missing.')
    exit 14
}

$rows = @(Import-Csv -LiteralPath $catalogPath)
$catalog = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal
)
foreach ($row in $rows) {
    $key = [string]$row.keys
    if ([string]::IsNullOrWhiteSpace($key)) {
        $failures.Add('Catalog contains an empty key.')
        continue
    }
    if (-not $catalog.Add($key)) {
        $failures.Add("Duplicate catalog key: $key")
    }
    foreach ($locale in @('en', 'zh_CN')) {
        if ([string]::IsNullOrWhiteSpace([string]$row.$locale)) {
            $failures.Add("Missing $locale text for key: $key")
        }
    }
}

$referenced = [System.Collections.Generic.HashSet[string]]::new(
    [StringComparer]::Ordinal
)
$sourceFiles = @(& git -C $repositoryRoot ls-files -- 'game/*.gd' 'game/*.tscn' 'game/*.tres') |
    Where-Object { $_ -notmatch '^game/tests/' }
if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine('[localization] FAIL: could not list game sources.')
    exit $LASTEXITCODE
}
$patterns = @(
    'tr\(&"(?<key>[A-Z][A-Z0-9_]+)"\)',
    'text\s*=\s*"(?<key>[A-Z][A-Z0-9_]+)"',
    '(?:name_key|description_key|prompt_key)\s*=\s*&"(?<key>[A-Z][A-Z0-9_]+)"'
)
foreach ($relativePath in $sourceFiles) {
    $content = Get-Content -LiteralPath (Join-Path $repositoryRoot $relativePath) -Raw
    foreach ($pattern in $patterns) {
        foreach ($match in [regex]::Matches($content, $pattern)) {
            [void]$referenced.Add($match.Groups['key'].Value)
        }
    }
}

foreach ($action in @(
    'MOVE_LEFT', 'MOVE_RIGHT', 'MOVE_UP', 'MOVE_DOWN',
    'INTERACT', 'PAUSE_GAME', 'TOGGLE_INVENTORY'
)) {
    [void]$referenced.Add("UI_ACTION_$action")
}
foreach ($key in $referenced) {
    if (-not $catalog.Contains($key)) {
        $failures.Add("Referenced localization key is missing: $key")
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        [Console]::Error.WriteLine("[localization] FAIL: $failure")
    }
    exit 14
}

[Console]::WriteLine(
    "[localization] PASS: $($catalog.Count) bilingual keys; $($referenced.Count) referenced keys resolved."
)
exit 0
