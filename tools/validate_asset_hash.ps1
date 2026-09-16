[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$ExpectedHash,
    [string[]]$QuarantineHashes = @()
)

$ErrorActionPreference = 'Stop'
$actualHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
$expected = $ExpectedHash.ToLowerInvariant()
# Check rights quarantine independently, including when the manifest also matches.
if ($actualHash -in $QuarantineHashes) {
    [Console]::Error.WriteLine("[art] FAIL: Quarantine hash match: path='$Path'; expected=$expected; actual=$actualHash")
    exit 22
}
if ($actualHash -ne $expected) {
    $bytes = [IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $Path).ProviderPath)
    $diagnostic = "bytes=$($bytes.Length)"
    if ([IO.Path]::GetExtension($Path) -ieq '.svg') {
        $text = [Text.Encoding]::UTF8.GetString($bytes)
        $crlf = [regex]::Matches($text, "`r`n").Count
        $lf = [regex]::Matches($text, "(?<!`r)`n").Count
        $cr = [regex]::Matches($text, "`r(?!`n)").Count
        $diagnostic += "; CRLF=$crlf; LF=$lf; lone_CR=$cr; required_svg_eol=LF"
    }
    [Console]::Error.WriteLine("[art] FAIL: File hash mismatch: path='$Path'; expected=$expected; actual=$actualHash; $diagnostic")
    exit 22
}
[Console]::WriteLine("[art] PASS: Exact asset hash verified: $Path")
exit 0
