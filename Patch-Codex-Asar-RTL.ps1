[CmdletBinding()]
param(
    [string]$Target,
    [string]$BackupPath,
    [string]$CssPath = "webview/assets/plugins-cards-grid-e7LodWnf.css"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$rtlCss = @'
article,p,li{direction:rtl!important;text-align:right!important;unicode-bidi:plaintext!important}pre,code,textarea,input,[contenteditable]{direction:ltr!important;text-align:left!important}
'@.Trim()

if (-not (Test-Path -LiteralPath $Target)) {
    throw "Target not found: $Target"
}

if (-not $BackupPath) {
    $BackupPath = "$Target.pre-rtl-bak"
}

$encoding = [System.Text.Encoding]::UTF8
$bytes = [System.IO.File]::ReadAllBytes($Target)

function Find-Bytes {
    param(
        [byte[]]$Haystack,
        [byte[]]$Needle,
        [int]$From = 0
    )
    for ($i = $From; $i -le $Haystack.Length - $Needle.Length; $i++) {
        $matched = $true
        for ($j = 0; $j -lt $Needle.Length; $j++) {
            if ($Haystack[$i + $j] -ne $Needle[$j]) {
                $matched = $false
                break
            }
        }
        if ($matched) {
            return $i
        }
    }
    return -1
}

function Get-AsarEntry {
    param(
        [object]$Root,
        [string]$Path
    )

    $node = $Root
    foreach ($part in ($Path -split "/")) {
        if (-not $node.files) {
            throw "ASAR path is not a directory: $Path"
        }
        $prop = $node.files.PSObject.Properties[$part]
        if (-not $prop) {
            throw "ASAR path not found: $Path"
        }
        $node = $prop.Value
    }
    return $node
}

$headerSize = [BitConverter]::ToUInt32($bytes, 12)
$headerStart = 16
$headerEnd = $headerStart + [int]$headerSize
$headerText = $encoding.GetString($bytes, $headerStart, [int]$headerSize)
$headerJson = $headerText | ConvertFrom-Json
$entry = Get-AsarEntry -Root $headerJson -Path $CssPath

if (-not $entry.integrity -or -not $entry.integrity.hash) {
    throw "ASAR entry has no integrity hash: $CssPath"
}

$oldHash = [string]$entry.integrity.hash
$fileSize = [int]$entry.size
$rtlBytes = $encoding.GetBytes($rtlCss)
if ($rtlBytes.Length -gt $fileSize) {
    throw "RTL CSS is too long ($($rtlBytes.Length)) for fixed patch slot ($fileSize)."
}

if (-not (Test-Path -LiteralPath $BackupPath)) {
    Copy-Item -LiteralPath $Target -Destination $BackupPath -Force
}

$replacement = New-Object byte[] $fileSize
[Array]::Copy($rtlBytes, 0, $replacement, 0, $rtlBytes.Length)
for ($i = $rtlBytes.Length; $i -lt $replacement.Length; $i++) {
    $replacement[$i] = 0x20
}

$dataStart = 8 + [BitConverter]::ToUInt32($bytes, 4)
$fileStart = $dataStart + [int64]$entry.offset
[Array]::Copy($replacement, 0, $bytes, [int]$fileStart, $fileSize)

$sha = [System.Security.Cryptography.SHA256]::Create()
try {
    $newHash = [BitConverter]::ToString($sha.ComputeHash($bytes, [int]$fileStart, $fileSize)).Replace("-", "").ToLowerInvariant()
}
finally {
    $sha.Dispose()
}

$oldHashBytes = $encoding.GetBytes($oldHash)
$newHashBytes = $encoding.GetBytes($newHash)
if ($oldHashBytes.Length -ne 64 -or $newHashBytes.Length -ne 64) {
    throw "Unexpected ASAR integrity hash length."
}

$replaceAt = $headerStart
$replaced = 0
while ($true) {
    $replaceAt = Find-Bytes -Haystack $bytes -Needle $oldHashBytes -From $replaceAt
    if ($replaceAt -lt 0 -or $replaceAt -ge $headerEnd) {
        break
    }
    [Array]::Copy($newHashBytes, 0, $bytes, $replaceAt, 64)
    $replaceAt += 64
    $replaced++
}

if ($replaced -lt 1) {
    throw "Could not replace ASAR integrity hash $oldHash in header."
}

[System.IO.File]::WriteAllBytes($Target, $bytes)

Write-Host "Patched $Target"
Write-Host "Backup: $BackupPath"
Write-Host "CSS slot: $CssPath"
Write-Host "CSS SHA256: $newHash"
