[CmdletBinding()]
param(
    [ValidateSet("run", "install", "status", "reset")]
    [string]$Mode = "run"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$payload = $PSScriptRoot
$localAppData = [Environment]::GetFolderPath("LocalApplicationData")
if (-not $localAppData) {
    $localAppData = "C:\Users\ronip\AppData\Local"
}

$root = Join-Path $localAppData "CodexDesktopRTL"
$injectedDir = Join-Path $root "Codex-Injected"
$injectedExe = Join-Path $injectedDir "Codex.exe"
$injectedAsar = Join-Path $injectedDir "resources\app.asar"
$log = Join-Path $root "CodexDesktopRTL.log"
$sourceMarker = Join-Path $root "source.marker"
$installedRunner = Join-Path $root "CodexDesktopRTL-Portable.ps1"
$installedCmd = Join-Path $root "CodexDesktopRTL.cmd"
$launchCmd = Join-Path $root "CodexDesktopRTL-Launch.cmd"
$installedIcon = Join-Path $root "CodexDesktopRTL.ico"
$userDataDir = Join-Path $root "UserData"

New-Item -ItemType Directory -Force -Path $root | Out-Null
New-Item -ItemType Directory -Force -Path $userDataDir | Out-Null

foreach ($name in @(
    "CodexDesktopRTL-Portable.ps1",
    "Patch-Codex-Asar-RTL.ps1",
    "Patch-Codex-Exe-AsarIntegrity.ps1",
    "CodexDesktopRTL.ico"
)) {
    $src = Join-Path $payload $name
    if (Test-Path -LiteralPath $src) {
        Copy-Item -LiteralPath $src -Destination (Join-Path $root $name) -Force
    }
}

Set-Content -Path $installedCmd -Encoding ASCII -Value @"
@echo off
set "RTL_PWSH=C:\Program Files\PowerShell\7\pwsh.exe"
if exist "%RTL_PWSH%" (
  "%RTL_PWSH%" -NoProfile -ExecutionPolicy Bypass -File "$installedRunner"
) else (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$installedRunner"
)
"@

Set-Content -Path $launchCmd -Encoding ASCII -Value @"
@echo off
set "CODEX_ELECTRON_USER_DATA_PATH=$userDataDir"
cd /d "$injectedDir"
start "" "$injectedExe"
"@

function Log {
    param([string]$Message)
    Add-Content -Path $log -Value ("{0} {1}" -f (Get-Date).ToString("s"), $Message)
}

function Find-OfficialCodexApp {
    $roots = New-Object System.Collections.Generic.List[string]

    Get-Process Codex -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -like "*\WindowsApps\OpenAI.Codex_*\app\Codex.exe" } |
        ForEach-Object { $roots.Add((Split-Path -Parent $_.Path)) }

    $repoKey = "HKCU:\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppModel\Repository\Packages"
    Get-ChildItem $repoKey -ErrorAction SilentlyContinue |
        Where-Object { $_.PSChildName -like "OpenAI.Codex_*" } |
        ForEach-Object {
            $packageRoot = $_.GetValue("PackageRootFolder")
            if ($packageRoot) {
                $roots.Add((Join-Path ([string]$packageRoot) "app"))
            }
        }

    $windowsApps = "C:\Program Files\WindowsApps"
    if (Test-Path -LiteralPath $windowsApps) {
        Get-ChildItem -LiteralPath $windowsApps -Directory -Filter "OpenAI.Codex_*" -ErrorAction SilentlyContinue |
            ForEach-Object { $roots.Add((Join-Path $_.FullName "app")) }
    }

    $candidate = $roots |
        Select-Object -Unique |
        ForEach-Object {
            if ((Test-Path -LiteralPath (Join-Path $_ "Codex.exe")) -and (Test-Path -LiteralPath (Join-Path $_ "resources\app.asar"))) {
                $_
            }
        } |
        Select-Object -First 1

    if (-not $candidate) {
        throw "Codex Desktop was not found. Install Codex Desktop first."
    }

    return $candidate
}

function Get-SourceSignature {
    param([string]$SourceApp)

    $asar = Join-Path $SourceApp "resources\app.asar"
    $exe = Join-Path $SourceApp "Codex.exe"
    $asarInfo = Get-Item -LiteralPath $asar
    $exeInfo = Get-Item -LiteralPath $exe
    return @(
        $SourceApp
        $asarInfo.Length
        $asarInfo.LastWriteTimeUtc.Ticks
        $exeInfo.Length
        $exeInfo.LastWriteTimeUtc.Ticks
    ) -join "|"
}

function Stop-InjectedCodex {
    Get-Process Codex -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -like "*\CodexDesktopRTL\Codex-Injected\Codex.exe" } |
        Stop-Process -Force -ErrorAction SilentlyContinue
}

function Write-Status {
    $official = $null
    try {
        $official = Find-OfficialCodexApp
    } catch {
        $official = $null
    }

    [pscustomobject]@{
        Mode = $Mode
        Root = $root
        OfficialCodexApp = $official
        InjectedExe = $injectedExe
        InjectedExists = (Test-Path -LiteralPath $injectedExe)
        AsarExists = (Test-Path -LiteralPath $injectedAsar)
        Shortcut = (Join-Path ([Environment]::GetFolderPath("DesktopDirectory")) "Codex Desktop RTL.lnk")
        UserDataDir = $userDataDir
        Log = $log
    } | Format-List
}

Log "Starting mode=$Mode"

if ($Mode -eq "status") {
    Write-Status
    return
}

Stop-InjectedCodex
Start-Sleep -Seconds 1

$source = $null
$signature = $null
try {
    $source = Find-OfficialCodexApp
    $signature = Get-SourceSignature -SourceApp $source
} catch {
    if (-not (Test-Path -LiteralPath $injectedExe)) {
        throw
    }
    Log "Official Codex not found; using existing injected copy"
}

if ($Mode -eq "reset") {
    if (Test-Path -LiteralPath $injectedDir) {
        Remove-Item -LiteralPath $injectedDir -Recurse -Force
    }
    if (Test-Path -LiteralPath $sourceMarker) {
        Remove-Item -LiteralPath $sourceMarker -Force
    }
    if (Test-Path -LiteralPath $userDataDir) {
        Remove-Item -LiteralPath $userDataDir -Recurse -Force
        New-Item -ItemType Directory -Force -Path $userDataDir | Out-Null
    }
    Log "Reset completed"
    Write-Host "Reset completed: $root"
    return
}

$existingSignature = $null
if (Test-Path -LiteralPath $sourceMarker) {
    $existingSignature = Get-Content -Raw -LiteralPath $sourceMarker
}

$needsCopy = -not (Test-Path -LiteralPath $injectedExe)
if ($signature -and ($existingSignature -ne $signature)) {
    $needsCopy = $true
}

if ($needsCopy) {
    if (-not $source) {
        throw "Codex Desktop was not found. Install Codex Desktop first."
    }
    Log "Copying from $source"
    if (Test-Path -LiteralPath $injectedDir) {
        Remove-Item -LiteralPath $injectedDir -Recurse -Force
    }
    Copy-Item -LiteralPath $source -Destination $injectedDir -Recurse -Force
    Set-Content -Path $sourceMarker -Encoding ASCII -Value $signature
}

Log "Patching ASAR"
& (Join-Path $payload "Patch-Codex-Asar-RTL.ps1") `
    -Target $injectedAsar `
    -BackupPath (Join-Path $root "app.asar.pre-rtl-bak") |
    ForEach-Object { Log $_ }

Log "Patching EXE integrity"
& (Join-Path $payload "Patch-Codex-Exe-AsarIntegrity.ps1") `
    -ExePath $injectedExe `
    -AsarPath $injectedAsar |
    ForEach-Object { Log $_ }

$desktop = [Environment]::GetFolderPath("DesktopDirectory")
if ($desktop) {
    $shortcutPath = Join-Path $desktop "Codex Desktop RTL.lnk"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $installedCmd
    $shortcut.WorkingDirectory = $root
    if (Test-Path -LiteralPath $installedIcon) {
        $shortcut.IconLocation = $installedIcon
    } else {
        $shortcut.IconLocation = $injectedExe
    }
    $shortcut.Save()
}

$task = "CodexDesktopRTL"
schtasks /Delete /TN $task /F 2>$null | Out-Null
if ($Mode -eq "install") {
    Log "Install completed"
    Write-Host "Installed Codex Desktop RTL in $root"
} else {
    $runAt = (Get-Date).AddMinutes(1).ToString("HH:mm")
    $command = ('cmd.exe /c ""{0}""' -f $launchCmd)
    schtasks /Create /TN $task /TR $command /SC ONCE /ST $runAt /F | Out-Null
    schtasks /Run /TN $task | Out-Null
    Log "Launched"
}
