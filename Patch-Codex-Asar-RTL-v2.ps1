[CmdletBinding()]
param(
    [string]$Target,
    [string]$BackupPath,
    [string]$CssPath  # optional: if specified, use this path; otherwise auto-discover
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# RTL CSS payload - 189 bytes
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
    param([byte[]]$Haystack, [byte[]]$Needle, [int]$From = 0)
    for ($i = $From; $i -le $Haystack.Length - $Needle.Length; $i++) {
        $matched = $true
        for ($j = 0; $j -lt $Needle.Length; $j++) {
            if ($Haystack[$i + $j] -ne $Needle[$j]) { $matched = $false; break }
        }
        if ($matched) { return $i }
    }
    return -1
}

function Walk-AsarFiles {
    param([object]$Node, [string]$Path = "")
    if ($Node.PSObject.Properties['files']) {
        foreach ($prop in $Node.files.PSObject.Properties) {
            $childPath = if ($Path) { "$Path/$($prop.Name)" } else { $prop.Name }
            Walk-AsarFiles -Node $prop.Value -Path $childPath
        }
    } else {
        # Only emit if this is a real file (has offset and size)
        if (-not $Node.PSObject.Properties['size']) { return }
        $offset = if ($Node.PSObject.Properties['offset']) { [int64]$Node.offset } else { [int64]0 }
        $hash = if ($Node.PSObject.Properties['integrity']) { [string]$Node.integrity.hash } else { $null }
        [PSCustomObject]@{
            Path = $Path
            Size = [int]$Node.size
            Offset = $offset
            Hash = $hash
        }
    }
}

function Get-AsarEntry {
    param([object]$Root, [string]$Path)
    $node = $Root
    foreach ($part in ($Path -split "/")) {
        if (-not $node.files) { throw "ASAR path is not a directory: $Path" }
        $prop = $node.files.PSObject.Properties[$part]
        if (-not $prop) { throw "ASAR path not found: $Path" }
        $node = $prop.Value
    }
    return $node
}

# Parse ASAR header
$headerSize = [BitConverter]::ToUInt32($bytes, 12)
$headerStart = 16
$headerEnd = $headerStart + [int]$headerSize
$headerText = $encoding.GetString($bytes, $headerStart, [int]$headerSize)
$headerJson = $headerText | ConvertFrom-Json

$rtlBytes = $encoding.GetBytes($rtlCss)
Write-Host "RTL CSS payload: $($rtlBytes.Length) bytes"

# Discover slot if not specified
if (-not $CssPath) {
    Write-Host "Auto-discovering CSS slot..."
    $candidates = @()

    # Strategy: prefer files with 'app-shell' (always loaded), then any small CSS in webview/assets
    $allFiles = @(Walk-AsarFiles -Node $headerJson)

    foreach ($file in $allFiles) {
        if ($file.Path -notlike "webview/assets/*") { continue }
        if (-not $file.Path.EndsWith(".css")) { continue }
        if ($file.Size -lt $rtlBytes.Length) { continue }
        if ($file.Size -gt 3000) { continue }
        if (-not $file.Hash) { continue }

        # Score: prefer always-loaded files (app-shell), then smaller files
        $score = 0
        if ($file.Path -like "*app-shell*") { $score = 1000 }
        elseif ($file.Path -like "*markdown*") { $score = 900 }
        elseif ($file.Path -like "*plugins-cards-grid*") { $score = 800 }
        elseif ($file.Path -like "*dialog*") { $score = 500 }
        elseif ($file.Path -like "*scroll-to-bottom*") { $score = 700 }  # very specific, OK to override
        else { $score = 100 }

        $candidates += [PSCustomObject]@{
            Score = $score
            Path = $file.Path
            Size = $file.Size
            Hash = $file.Hash
        }
    }

    if ($candidates.Count -eq 0) {
        throw "No suitable CSS slot found in asar (need >= $($rtlBytes.Length) bytes, <= 3000 bytes, in webview/assets/)"
    }

    $best = $candidates | Sort-Object Score -Descending | Select-Object -First 1
    $CssPath = $best.Path
    Write-Host "Selected slot: $CssPath (size=$($best.Size), score=$($best.Score))"
    Write-Host ""
    Write-Host "Top 5 candidates were:"
    $candidates | Sort-Object Score -Descending | Select-Object -First 5 | ForEach-Object {
        Write-Host "  [$($_.Score)] $($_.Path) (size=$($_.Size))"
    }
}

$entry = Get-AsarEntry -Root $headerJson -Path $CssPath

if (-not $entry.integrity -or -not $entry.integrity.hash) {
    throw "ASAR entry has no integrity hash: $CssPath"
}

$oldHash = [string]$entry.integrity.hash
$fileSize = [int]$entry.size
if ($rtlBytes.Length -gt $fileSize) {
    throw "RTL CSS is too long ($($rtlBytes.Length)) for selected slot ($fileSize)."
}

# Backup before write
if (-not (Test-Path -LiteralPath $BackupPath)) {
    Copy-Item -LiteralPath $Target -Destination $BackupPath -Force
}

# Build replacement: RTL CSS + space padding to file size
$replacement = New-Object byte[] $fileSize
[Array]::Copy($rtlBytes, 0, $replacement, 0, $rtlBytes.Length)
for ($i = $rtlBytes.Length; $i -lt $replacement.Length; $i++) {
    $replacement[$i] = 0x20  # space
}

# Compute file data offset (after header)
$dataStart = 8 + [BitConverter]::ToUInt32($bytes, 4)
$fileStart = $dataStart + [int64]$entry.offset

# Overwrite file content in asar
[Array]::Copy($replacement, 0, $bytes, [int]$fileStart, $fileSize)

# Recompute SHA256 for the slot
$sha = [System.Security.Cryptography.SHA256]::Create()
try {
    $newHash = [BitConverter]::ToString($sha.ComputeHash($bytes, [int]$fileStart, $fileSize)).Replace("-", "").ToLowerInvariant()
} finally {
    $sha.Dispose()
}

# Replace hash in header (could appear in multiple integrity entries due to block hashes)
$oldHashBytes = $encoding.GetBytes($oldHash)
$newHashBytes = $encoding.GetBytes($newHash)
if ($oldHashBytes.Length -ne 64 -or $newHashBytes.Length -ne 64) {
    throw "Unexpected ASAR integrity hash length."
}

$replaceAt = $headerStart
$replaced = 0
while ($true) {
    $replaceAt = Find-Bytes -Haystack $bytes -Needle $oldHashBytes -From $replaceAt
    if ($replaceAt -lt 0 -or $replaceAt -ge $headerEnd) { break }
    [Array]::Copy($newHashBytes, 0, $bytes, $replaceAt, 64)
    $replaceAt += 64
    $replaced++
}

if ($replaced -lt 1) {
    throw "Could not replace ASAR integrity hash $oldHash in header."
}

[System.IO.File]::WriteAllBytes($Target, $bytes)

Write-Host ""
Write-Host "=== PATCH SUCCESS ==="
Write-Host "Target: $Target"
Write-Host "Backup: $BackupPath"
Write-Host "CSS slot: $CssPath"
Write-Host "Slot size: $fileSize bytes (RTL uses $($rtlBytes.Length), padded with $($fileSize - $rtlBytes.Length) spaces)"
Write-Host "New SHA256: $newHash"
Write-Host "Hash replaced in header: $replaced occurrence(s)"
