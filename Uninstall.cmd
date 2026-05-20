@echo off
setlocal
title CodexDesktopRTL Uninstaller

echo.
echo ========================================
echo   CodexDesktopRTL - Uninstaller
echo ========================================
echo.

set "RTL_PWSH=C:\Program Files\PowerShell\7\pwsh.exe"
if not exist "%RTL_PWSH%" set "RTL_PWSH=powershell.exe"

echo This will remove:
echo   - Injected Codex copy at %LOCALAPPDATA%\CodexDesktopRTL\
echo   - Desktop shortcut
echo   - Scheduled auto-update task
echo.
echo Your settings and history (in UserData) will NOT be touched
echo unless you also choose the 'full reset' option below.
echo.
choice /C YN /M "Continue uninstall"
if errorlevel 2 exit /b 0

echo.
echo Stopping Codex instances...
"%RTL_PWSH%" -NoProfile -ExecutionPolicy Bypass -Command "Get-Process Codex -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*\CodexDesktopRTL\*' } | Stop-Process -Force; Start-Sleep -Seconds 2"

echo Removing scheduled auto-update task...
schtasks /Delete /TN "CodexDesktopRTL-AutoUpdate" /F 2>nul

echo Removing scheduled launch task...
schtasks /Delete /TN "CodexDesktopRTL" /F 2>nul

echo Removing desktop shortcut...
"%RTL_PWSH%" -NoProfile -ExecutionPolicy Bypass -Command "$lnk = Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) 'Codex Desktop RTL.lnk'; if (Test-Path $lnk) { Remove-Item $lnk -Force }"

echo.
choice /C YN /M "Also remove UserData (settings/history)? This is irreversible"
if errorlevel 2 (
    echo Keeping UserData. Removing only the injected app copy...
    "%RTL_PWSH%" -NoProfile -ExecutionPolicy Bypass -Command "$d = Join-Path $env:LOCALAPPDATA 'CodexDesktopRTL\Codex-Injected'; if (Test-Path $d) { Remove-Item $d -Recurse -Force }"
) else (
    echo Full reset: removing CodexDesktopRTL root...
    "%RTL_PWSH%" -NoProfile -ExecutionPolicy Bypass -Command "$d = Join-Path $env:LOCALAPPDATA 'CodexDesktopRTL'; if (Test-Path $d) { Remove-Item $d -Recurse -Force }"
)

echo.
echo Uninstall complete.
pause
endlocal
