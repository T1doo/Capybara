[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$textExtensions = @(
    '.csv', '.gd', '.gdshader', '.godot', '.import', '.json', '.md', '.ps1',
    '.svg', '.tscn', '.txt', '.uid', '.yaml', '.yml'
)
$visibleFiles = @(& git -C $repositoryRoot ls-files --cached --others --exclude-standard) |
    Sort-Object -Unique
if ($LASTEXITCODE -ne 0) {
    [Console]::Error.WriteLine('[format] Failed to list Git-visible files.')
    exit $LASTEXITCODE
}

$violations = [System.Collections.Generic.List[string]]::new()
$inspectedCount = 0
foreach ($relativePath in $visibleFiles) {
    $extension = [IO.Path]::GetExtension($relativePath).ToLowerInvariant()
    if ($extension -notin $textExtensions) {
        continue
    }
    $fullPath = Join-Path $repositoryRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        continue
    }
    $inspectedCount += 1
    $lines = @(Get-Content -LiteralPath $fullPath)
    for ($index = 0; $index -lt $lines.Count; $index += 1) {
        $line = $lines[$index]
        $lineNumber = $index + 1
        if ($line -match '[\t ]+$') {
            $markdownHardBreak = $extension -eq '.md' -and $line -match '\S  $'
            if (-not $markdownHardBreak) {
                $violations.Add("${relativePath}:${lineNumber}: trailing whitespace")
            }
        }
        if ($extension -eq '.gd' -and $line -match '^ +\S') {
            $violations.Add("${relativePath}:${lineNumber}: GDScript indentation must use tabs")
        }
    }

    if ($extension -eq '.gd' -and $lines.Count -gt 350) {
        $violations.Add("${relativePath}: GDScript file exceeds 350 lines ($($lines.Count))")
    }
    if ($extension -eq '.json') {
        try {
            Get-Content -LiteralPath $fullPath -Raw | ConvertFrom-Json | Out-Null
        }
        catch {
            $violations.Add("${relativePath}: invalid JSON: $($_.Exception.Message)")
        }
    }
    if ($extension -eq '.ps1') {
        $tokens = $null
        $parseErrors = $null
        [Management.Automation.Language.Parser]::ParseFile(
            $fullPath,
            [ref]$tokens,
            [ref]$parseErrors
        ) | Out-Null
        foreach ($parseError in @($parseErrors)) {
            $violations.Add("${relativePath}:$($parseError.Extent.StartLineNumber): PowerShell parse error: $($parseError.Message)")
        }
    }
}

if ($violations.Count -gt 0) {
    foreach ($violation in $violations) {
        [Console]::Error.WriteLine("[format] FAIL: $violation")
    }
    exit 12
}

[Console]::WriteLine("[format] PASS: $inspectedCount existing Git-visible text paths inspected.")
exit 0
