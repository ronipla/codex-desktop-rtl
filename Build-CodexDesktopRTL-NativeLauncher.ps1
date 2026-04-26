[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = $PSScriptRoot
$dist = Join-Path $root "dist"
$build = Join-Path $root "build-native-launcher"
$programFiles = if ($env:ProgramFiles) { $env:ProgramFiles } else { [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFiles) }
$programFilesX86 = if (${env:ProgramFiles(x86)}) { ${env:ProgramFiles(x86)} } else { [Environment]::GetFolderPath([Environment+SpecialFolder]::ProgramFilesX86) }
if (-not $programFiles) {
    $programFiles = "C:\Program Files"
}
if (-not $programFilesX86) {
    $programFilesX86 = "C:\Program Files (x86)"
}

function Find-VcVars {
    $candidates = New-Object System.Collections.Generic.List[string]

    $vswhere = Join-Path $script:programFilesX86 "Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path $vswhere) {
        $found = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -find "VC\Auxiliary\Build\vcvars64.bat" 2>$null
        foreach ($item in $found) {
            if ($item) {
                $candidates.Add($item)
            }
        }
    }

    $knownRoots = @(
        (Join-Path $script:programFilesX86 "Microsoft Visual Studio\2019\BuildTools"),
        (Join-Path $script:programFilesX86 "Microsoft Visual Studio\2019\Community"),
        (Join-Path $script:programFilesX86 "Microsoft Visual Studio\2019\Professional"),
        (Join-Path $script:programFilesX86 "Microsoft Visual Studio\2019\Enterprise"),
        (Join-Path $script:programFiles "Microsoft Visual Studio\2022\BuildTools"),
        (Join-Path $script:programFiles "Microsoft Visual Studio\2022\Community"),
        (Join-Path $script:programFiles "Microsoft Visual Studio\2022\Professional"),
        (Join-Path $script:programFiles "Microsoft Visual Studio\2022\Enterprise")
    )

    foreach ($knownRoot in $knownRoots) {
        $candidates.Add((Join-Path $knownRoot "VC\Auxiliary\Build\vcvars64.bat"))
    }

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return (Resolve-Path $candidate).Path
        }
    }

    throw "vcvars64.bat not found. Install Visual Studio Build Tools with C++ build tools."
}

function Find-RcExe {
    $sdkRoot = Join-Path $script:programFilesX86 "Windows Kits\10\bin"
    if (Test-Path $sdkRoot) {
        $candidate = Get-ChildItem -LiteralPath $sdkRoot -Recurse -Filter rc.exe -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -like "*\x64\rc.exe" } |
            Sort-Object FullName -Descending |
            Select-Object -First 1

        if ($candidate) {
            return $candidate.FullName
        }
    }

    throw "rc.exe not found. Install the Windows 10/11 SDK."
}

New-Item -ItemType Directory -Force -Path $dist | Out-Null
if (Test-Path $build) {
    $resolved = (Resolve-Path $build).Path
    if (-not $resolved.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove unexpected path: $resolved"
    }
    Remove-Item -LiteralPath $build -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $build | Out-Null

$vcvars = Find-VcVars
$rc = Find-RcExe

$cmd = @"
call "$vcvars"
cd /d "$root"
"$rc" /nologo /fo "$build\CodexDesktopRTLLauncher.res" "$root\CodexDesktopRTLLauncher.rc"
ml64 /nologo /c /Fo"$build\CodexDesktopRTLLauncher.obj" "$root\CodexDesktopRTLLauncher.asm"
link /nologo /entry:main /subsystem:windows "$build\CodexDesktopRTLLauncher.obj" "$build\CodexDesktopRTLLauncher.res" kernel32.lib user32.lib /out:"$dist\CodexDesktopRTL.exe"
"@

$bat = Join-Path $build "build.cmd"
Set-Content -Path $bat -Value $cmd -Encoding ASCII
cmd.exe /c $bat
if ($LASTEXITCODE -ne 0) {
    throw "Native launcher build failed with exit code $LASTEXITCODE"
}

if (-not (Test-Path (Join-Path $dist "CodexDesktopRTL.exe"))) {
    throw "CodexDesktopRTL.exe was not created."
}

Write-Host "Built $(Join-Path $dist "CodexDesktopRTL.exe")"
