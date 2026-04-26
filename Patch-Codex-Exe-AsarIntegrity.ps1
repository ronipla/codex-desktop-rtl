[CmdletBinding()]
param(
    [string]$ExePath,
    [string]$AsarPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type @"
using System;
using System.Runtime.InteropServices;

public static class ResourceUpdate {
    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern IntPtr BeginUpdateResource(string pFileName, bool bDeleteExistingResources);

    [DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Unicode)]
    public static extern bool UpdateResource(IntPtr hUpdate, string lpType, string lpName, ushort wLanguage, byte[] lpData, uint cbData);

    [DllImport("kernel32.dll", SetLastError=true)]
    public static extern bool EndUpdateResource(IntPtr hUpdate, bool fDiscard);
}
"@

if (-not (Test-Path -LiteralPath $ExePath)) {
    throw "Exe not found: $ExePath"
}
if (-not (Test-Path -LiteralPath $AsarPath)) {
    throw "ASAR not found: $AsarPath"
}

$bytes = [System.IO.File]::ReadAllBytes($AsarPath)
$headerSize = [BitConverter]::ToUInt32($bytes, 12)
$sha = [System.Security.Cryptography.SHA256]::Create()
try {
    $headerHash = [BitConverter]::ToString($sha.ComputeHash($bytes, 16, [int]$headerSize)).Replace("-", "").ToLowerInvariant()
}
finally {
    $sha.Dispose()
}

$resourceJson = "[{`"file`":`"resources\\app.asar`",`"alg`":`"sha256`",`"value`":`"$headerHash`"}]"
$resourceBytes = [System.Text.Encoding]::UTF8.GetBytes($resourceJson)

$backup = "$ExePath.pre-codex-rtl-integrity-bak"
if (-not (Test-Path -LiteralPath $backup)) {
    Copy-Item -LiteralPath $ExePath -Destination $backup -Force
}

$handle = [ResourceUpdate]::BeginUpdateResource($ExePath, $false)
if ($handle -eq [IntPtr]::Zero) {
    throw "BeginUpdateResource failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
}

$ok = $false
try {
    foreach ($lang in @(0, 1033)) {
        if (-not [ResourceUpdate]::UpdateResource($handle, "Integrity", "ElectronAsar", [ushort]$lang, $resourceBytes, [uint32]$resourceBytes.Length)) {
            throw "UpdateResource failed for lang ${lang}: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
        }
    }
    $ok = $true
}
finally {
    if (-not [ResourceUpdate]::EndUpdateResource($handle, -not $ok)) {
        throw "EndUpdateResource failed: $([Runtime.InteropServices.Marshal]::GetLastWin32Error())"
    }
}

Write-Host "Updated ElectronAsar integrity resource in $ExePath"
Write-Host "Header SHA256: $headerHash"
Write-Host "Resource JSON: $resourceJson"
