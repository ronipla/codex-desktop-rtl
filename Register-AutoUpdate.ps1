[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Register a daily scheduled task that runs CodexDesktopRTL-AutoUpdate.ps1.
# That script checks if the official Codex Desktop has been updated since the
# last RTL injection and, if so, re-applies the patch automatically.

$root = Join-Path $env:LOCALAPPDATA "CodexDesktopRTL"
$autoUpdateScript = Join-Path $root "CodexDesktopRTL-AutoUpdate.ps1"

$pwsh = "C:\Program Files\PowerShell\7\pwsh.exe"
if (-not (Test-Path -LiteralPath $pwsh)) {
    $pwsh = "powershell.exe"
}

# Build the command to invoke
$command = "`"$pwsh`" -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$autoUpdateScript`""

$taskName = "CodexDesktopRTL-AutoUpdate"
schtasks /Delete /TN $taskName /F 2>$null | Out-Null

# Daily task runs without elevation needed
$dailyResult = schtasks /Create /TN $taskName /TR $command /SC DAILY /ST 03:00 /F 2>&1
$dailyOk = $LASTEXITCODE -eq 0
if ($dailyOk) {
    Write-Host "[OK] Daily auto-update task registered (03:00)"
} else {
    Write-Host "[!]  Failed to register daily task: $dailyResult"
}

# Logon task may need elevation depending on local policy. Try, but don't fail
# the whole install if this one is rejected.
$logonTask = "CodexDesktopRTL-AutoUpdate-Logon"
schtasks /Delete /TN $logonTask /F 2>$null | Out-Null
$logonResult = schtasks /Create /TN $logonTask /TR $command /SC ONLOGON /F 2>&1
$logonOk = $LASTEXITCODE -eq 0
if ($logonOk) {
    Write-Host "[OK] On-logon auto-update task registered"
} else {
    Write-Host "[i]  On-logon task not registered (needs elevation). Daily task is sufficient."
}

Write-Host ""
Write-Host "  Script: $autoUpdateScript"
