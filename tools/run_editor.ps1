[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$gameRoot = Join-Path $repositoryRoot 'game'
$godotBin = $env:GODOT_BIN

if ([string]::IsNullOrWhiteSpace($godotBin)) {
    [Console]::Error.WriteLine('[run-editor] GODOT_BIN is not set.')
    exit 2
}

if (-not (Test-Path -LiteralPath $godotBin -PathType Leaf)) {
    [Console]::Error.WriteLine("[run-editor] GODOT_BIN does not point to a file: $godotBin")
    exit 3
}

& $godotBin --editor --path $gameRoot
exit $LASTEXITCODE
