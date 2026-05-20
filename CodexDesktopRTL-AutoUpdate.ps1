[CmdletBinding()]
param()

# Auto-updater for CodexDesktopRTL.
# Checks if the official Codex Desktop has a newer signature than the last
# RTL injection. If yes, re-runs the install. Safe to run periodically — it
# is a no-op when nothing has changed.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Join-Path $env:LOCALAPPDATA "CodexDesktopRTL"
$log = Join-Path $root "AutoUpdate.log"
$sourceMarker = Join-Path $root "source.marker"
$portableScript = Join-Path $root "CodexDesktopRTL-Portable.ps1"

function Log {
    param([string]$Message)
    $line = "{0} {1}" -f (Get-Date).ToString("s"), $Message
    Add-Content -Path $log -Value $line
}

if (-not (Test-Path -LiteralPath $portableScript)) {
    Log "CodexDesktopRTL-Portable.ps1 not found at $portableScript - exiting"
    exit 0
}

function Find-OfficialCodexApp {
    $roots = New-Object System.Collections.Generic.List[string]
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

try {
    $source = Find-OfficialCodexApp
    if (-not $source) {
        Log "Official Codex not found - exiting"
        exit 0
    }

    $currentSig = Get-SourceSignature -SourceApp $source

    $existingSig = $null
    if (Test-Path -LiteralPath $sourceMarker) {
        $existingSig = Get-Content -Raw -LiteralPath $sourceMarker
    }

    if ($existingSig -eq $currentSig) {
        Log "No update needed (signature matches)"
        exit 0
    }

    Log "Update detected. Existing=$existingSig Current=$currentSig"

    # Check Codex is not running
    $running = Get-Process Codex -ErrorAction SilentlyContinue |
        Where-Object { $_.Path -like "*\CodexDesktopRTL\Codex-Injected\Codex.exe" }
    if ($running) {
        Log "Codex is running - skipping update this round, will retry next cycle"
        exit 0
    }

    # Run installer
    Log "Running portable installer in install mode..."
    & $portableScript -Mode install *>&1 | ForEach-Object { Log $_ }
    Log "Update complete"
} catch {
    Log "ERROR: $($_.Exception.Message)"
    Log "Stack: $($_.ScriptStackTrace)"
    exit 1
}
