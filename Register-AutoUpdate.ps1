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

# Run daily at 03:00 plus on user logon
schtasks /Create /TN $taskName /TR $command /SC DAILY /ST 03:00 /F | Out-Null

# Also a logon-time check (with a short delay so Codex isn't blocked at startup)
$logonTask = "CodexDesktopRTL-AutoUpdate-Logon"
schtasks /Delete /TN $logonTask /F 2>$null | Out-Null
schtasks /Create /TN $logonTask /TR $command /SC ONLOGON /F | Out-Null

Write-Host "[OK] Auto-update task registered:"
Write-Host "       - Daily at 03:00"
Write-Host "       - On user logon"
Write-Host "  Script: $autoUpdateScript"
