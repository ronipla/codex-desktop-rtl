[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$dist = Join-Path $root "dist"
$version = "0.1.0"
$zip = Join-Path $dist ("CodexDesktopRTL-v{0}-Windows.zip" -f $version)

New-Item -ItemType Directory -Force -Path $dist | Out-Null

& (Join-Path $root "Build-CodexDesktopRTL-NativeLauncher.ps1")

$exe = Join-Path $dist "CodexDesktopRTL.exe"
$checksums = Join-Path $dist "CHECKSUMS.txt"
$releaseReadme = Join-Path $dist "README.txt"
$zipStage = Join-Path $dist "_zip-CodexDesktopRTL"

if (Test-Path -LiteralPath $zipStage) {
    Remove-Item -LiteralPath $zipStage -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $zipStage | Out-Null
Copy-Item -LiteralPath $exe -Destination (Join-Path $zipStage "CodexDesktopRTL.exe") -Force

$exeHash = (Get-FileHash -LiteralPath (Join-Path $zipStage "CodexDesktopRTL.exe") -Algorithm SHA256).Hash
Set-Content -LiteralPath (Join-Path $zipStage "CHECKSUMS.txt") -Encoding ASCII -Value "$exeHash  CodexDesktopRTL.exe"
Set-Content -LiteralPath (Join-Path $zipStage "README_HE.txt") -Encoding UTF8 -Value @"
Codex Desktop RTL - Windows

איך משתמשים:
1. לחלץ את קובץ ה-ZIP.
2. ללחוץ פעמיים על CodexDesktopRTL.exe.
3. אם Windows SmartScreen מזהיר: לבחור More info ואז Run anyway רק אם סומכים על המקור.
4. נדרש ש-Codex Desktop הרשמי כבר יהיה מותקן.

מה זה עושה:
- לא משנה את ההתקנה הרשמית של Codex.
- יוצר עותק מקומי תחת AppData.
- מזריק תיקון RTL/BiDi לעותק המקומי.
- יוצר קיצור דרך בשם Codex Desktop RTL.

SHA256:
$exeHash  CodexDesktopRTL.exe
"@
Set-Content -LiteralPath (Join-Path $zipStage "README_EN.txt") -Encoding UTF8 -Value @"
Codex Desktop RTL - Windows

How to use:
1. Extract the ZIP.
2. Double-click CodexDesktopRTL.exe.
3. If Windows SmartScreen warns, choose More info and Run anyway only if you trust the source.
4. Official Codex Desktop must already be installed.

What it does:
- Does not modify the official Codex installation.
- Creates a local AppData copy.
- Injects an RTL/BiDi fix into the local copy.
- Creates a desktop shortcut named Codex Desktop RTL.

SHA256:
$exeHash  CodexDesktopRTL.exe
"@

if (Test-Path -LiteralPath $zip) {
    Remove-Item -LiteralPath $zip -Force
}
Compress-Archive -Path (Join-Path $zipStage "*") -DestinationPath $zip -CompressionLevel Optimal
Remove-Item -LiteralPath $zipStage -Recurse -Force

$hashLines = Get-FileHash $exe, $zip -Algorithm SHA256 | ForEach-Object {
    "{0}  {1}" -f $_.Hash, (Split-Path $_.Path -Leaf)
}
$hashLines | Set-Content -Path $checksums -Encoding ASCII

Set-Content -LiteralPath $releaseReadme -Encoding ASCII -Value @"
Release artifacts for Codex Desktop RTL v$version.

Windows:
  CodexDesktopRTL.exe
  CodexDesktopRTL-v$version-Windows.zip

Verify hashes with:
  Get-FileHash .\CodexDesktopRTL.exe -Algorithm SHA256
  Get-FileHash .\CodexDesktopRTL-v$version-Windows.zip -Algorithm SHA256

Expected hashes are listed in CHECKSUMS.txt.
"@

Get-Item $exe, $zip, $checksums, $releaseReadme |
    Select-Object FullName, Length, LastWriteTime |
    Format-Table -AutoSize
