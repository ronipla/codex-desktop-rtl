@echo off
setlocal
title CodexDesktopRTL Installer

echo.
echo ========================================
echo   CodexDesktopRTL - RTL Hebrew Patch
echo   Installer for Codex Desktop on Windows
echo ========================================
echo.

REM Check that Codex Desktop is installed via Windows Store
echo Checking for Codex Desktop installation...
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (-not (Get-ChildItem 'C:\Program Files\WindowsApps' -Directory -Filter 'OpenAI.Codex_*' -ErrorAction SilentlyContinue)) { Write-Host '  [X] Codex Desktop NOT found.' -ForegroundColor Red; Write-Host ''; Write-Host '  Please install Codex Desktop from the Microsoft Store first:' -ForegroundColor Yellow; Write-Host '  https://apps.microsoft.com/detail/9p5w0hwjtbqz' -ForegroundColor Cyan; Write-Host ''; exit 1 } else { Write-Host '  [OK] Codex Desktop found' -ForegroundColor Green }"
if errorlevel 1 (
    echo.
    pause
    exit /b 1
)

REM Stop any running Codex instances
echo.
echo Stopping running Codex instances (if any)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Process Codex -ErrorAction SilentlyContinue | Stop-Process -Force; Start-Sleep -Seconds 2"

REM Locate PowerShell 7 if available, else use Windows PowerShell
set "RTL_PWSH=C:\Program Files\PowerShell\7\pwsh.exe"
if not exist "%RTL_PWSH%" set "RTL_PWSH=powershell.exe"

REM Run the portable installer in install mode
echo.
echo Installing CodexDesktopRTL...
echo.
"%RTL_PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Payload\CodexDesktopRTL-Portable.ps1" -Mode install
if errorlevel 1 (
    echo.
    echo [X] Installation failed. See messages above.
    pause
    exit /b 1
)

REM Register auto-update task (checks for Codex updates daily)
echo.
echo Registering daily auto-update task...
"%RTL_PWSH%" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Payload\Register-AutoUpdate.ps1"

echo.
echo ========================================
echo   Installation complete!
echo ========================================
echo.
echo You can now launch Codex Desktop RTL from:
echo   - Desktop shortcut "Codex Desktop RTL"
echo   - Start Menu
echo.
echo Auto-update: A scheduled task will check daily for Codex updates
echo and re-apply the RTL patch automatically.
echo.
pause
endlocal
