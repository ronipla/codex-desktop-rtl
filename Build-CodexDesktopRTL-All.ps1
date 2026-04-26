[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$dist = Join-Path $root "dist"

New-Item -ItemType Directory -Force -Path $dist | Out-Null

& (Join-Path $root "Build-CodexDesktopRTL-NativeLauncher.ps1")

$exe = Join-Path $dist "CodexDesktopRTL.exe"
$checksums = Join-Path $dist "CHECKSUMS.txt"
$hash = Get-FileHash -LiteralPath $exe -Algorithm SHA256
"$($hash.Hash)  CodexDesktopRTL.exe" | Set-Content -Path $checksums -Encoding ASCII

Get-Item $exe, $checksums |
    Select-Object FullName, Length, LastWriteTime |
    Format-Table -AutoSize
