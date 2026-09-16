[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..')).ProviderPath
$manifestPath = Join-Path $repositoryRoot 'art/candidates/player_capybara_v1/PROTOTYPE_MANIFEST.csv'
$prototype = @(Import-Csv -LiteralPath $manifestPath)[0]
$sourcePath = Join-Path $repositoryRoot $prototype.file_path
$validator = Join-Path $PSScriptRoot 'validate_asset_hash.ps1'
$powerShellBin = [Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
$runId = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ') + "-p$PID"
$fixtureRoot = Join-Path $repositoryRoot "build/art-pipeline/svg-checkout/$runId"
New-Item -ItemType Directory -Path $fixtureRoot | Out-Null
$encoding = [Text.UTF8Encoding]::new($false)
# LF is the manifest's exact byte contract, never a normalization in the validator.
$sourceText = [IO.File]::ReadAllText($sourcePath).Replace("`r`n", "`n")
$sourceLineCount = [regex]::Matches($sourceText, "`n").Count
$currentAttributes = [IO.File]::ReadAllText((Join-Path $repositoryRoot '.gitattributes'))
$results = [Collections.Generic.List[object]]::new()

function Invoke-FixtureGit {
    param([string]$Directory, [string[]]$Arguments)
    $output = & git -C $Directory @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Fixture git failed: $($Arguments -join ' '): $($output -join ' ')" }
}

function Assert-HashResult {
    param([string]$Name, [string]$File, [int]$ExpectedExit, [string]$Message, [string]$Quarantine = '')
    $arguments = @('-NoProfile', '-File', $validator, '-Path', $File, '-ExpectedHash', $prototype.sha256)
    if ($Quarantine) { $arguments += @('-QuarantineHashes', $Quarantine) }
    $output = & $powerShellBin @arguments 2>&1
    $code = $LASTEXITCODE
    $messageText = $output -join [Environment]::NewLine
    $results.Add([ordered]@{
        case = $Name; exit_code = $code; expected_exit = $ExpectedExit
        bytes = (Get-Item -LiteralPath $File).Length
        sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $File).Hash.ToLowerInvariant()
        output = $messageText
    })
    if ($code -ne $ExpectedExit -or -not $messageText.Contains($Message)) {
        throw "$Name failed: expected exit $ExpectedExit and '$Message'; got exit $code : $messageText"
    }
}

try {
    foreach ($policy in @('legacy', 'current')) {
        foreach ($autocrlf in @('true', 'false')) {
            $name = "$policy-autocrlf-$autocrlf"
            $directory = Join-Path $fixtureRoot $name
            New-Item -ItemType Directory -Path $directory | Out-Null
            $attributes = if ($policy -eq 'legacy') { "* text=auto`n" } else { $currentAttributes }
            $file = Join-Path $directory 'prototype.svg'
            [IO.File]::WriteAllText((Join-Path $directory '.gitattributes'), $attributes, $encoding)
            [IO.File]::WriteAllText($file, $sourceText, $encoding)
            Invoke-FixtureGit $directory @('init', '-q')
            Invoke-FixtureGit $directory @('config', 'core.autocrlf', $autocrlf)
            # Explicit LF fallback makes false deterministic on every host; true
            # still forces CRLF without the SVG attribute (including on Windows).
            Invoke-FixtureGit $directory @('config', 'core.eol', 'lf')
            Invoke-FixtureGit $directory @('add', '--', '.gitattributes', 'prototype.svg')
            Remove-Item -LiteralPath $file
            Invoke-FixtureGit $directory @('checkout', '--', 'prototype.svg')
            if ($policy -eq 'legacy' -and $autocrlf -eq 'true') {
                Assert-HashResult $name $file 22 'File hash mismatch'
                if (-not $results[$results.Count - 1].output.Contains("CRLF=$sourceLineCount;")) {
                    throw 'Legacy checkout did not convert the source LF lines to CRLF.'
                }
            }
            else {
                Assert-HashResult $name $file 0 'Exact asset hash verified'
            }
            if ($policy -eq 'current') {
                # Synthetic quarantine membership exercises the same production
                # gate without copying any quarantined image or changing manifests.
                Assert-HashResult "$name-quarantine" $file 22 'Quarantine hash match' $prototype.sha256
                [IO.File]::AppendAllText($file, "<!-- deliberate regression tamper -->`n", $encoding)
                Assert-HashResult "$name-content-tamper" $file 22 'File hash mismatch'
                $tamperedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file).Hash
                Assert-HashResult "$name-tamper-and-quarantine" $file 22 'Quarantine hash match' $tamperedHash
            }
        }
    }
}
catch {
    [Console]::Error.WriteLine("[svg-checkout] FAIL: $($_.Exception.Message)")
    $results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $fixtureRoot 'results.json') -Encoding utf8
    exit 22
}
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $fixtureRoot 'results.json') -Encoding utf8
[Console]::WriteLine("[svg-checkout] PASS: $($results.Count) real Git checkout and hash rejection cases; evidence=$fixtureRoot")
exit 0
