[CmdletBinding()]
param(
    [string]$Owner = "ronipla",
    [string]$Repo = "codex-desktop-rtl",
    [string]$Version = "v0.1.0"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoFullName = "$Owner/$Repo"

gh auth status | Out-Null

$origin = git remote get-url origin 2>$null
if (-not $origin) {
    gh repo view $repoFullName *> $null
    if ($LASTEXITCODE -eq 0) {
        git remote add origin "https://github.com/$repoFullName.git"
        git push -u origin main
    } else {
        gh repo create $repoFullName --public --source . --remote origin --push
    }
} else {
    git push -u origin main
}

$exe = ".\dist\CodexDesktopRTL.exe"
$zip = ".\dist\CodexDesktopRTL-v0.1.0-Windows.zip"
$checksums = ".\dist\CHECKSUMS.txt"
$notes = ".\docs\RELEASE_NOTES_v0.1.0.md"

gh release view $Version --repo $repoFullName *> $null
if ($LASTEXITCODE -eq 0) {
    gh release edit $Version --repo $repoFullName --notes-file $notes
    gh release upload $Version $exe $zip $checksums --repo $repoFullName --clobber
} else {
    gh release create $Version $exe $zip $checksums --repo $repoFullName --title "Codex Desktop RTL $Version" --notes-file $notes
}

Write-Host "Published https://github.com/$repoFullName"
