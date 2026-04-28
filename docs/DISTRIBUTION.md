# Distribution Strategy

## Recommended Channels

### 1. GitHub Release

This is the current primary channel.

Users download:

```text
CodexDesktopRTL-v0.1.0-Windows.zip
CodexDesktopRTL.exe
```

The release also includes:

```text
CHECKSUMS.txt
```

The ZIP is the recommended artifact for non-technical users. It contains:

- `CodexDesktopRTL.exe`
- `README_HE.txt`
- `README_EN.txt`
- `CHECKSUMS.txt`

### 2. Signed Installer / MSI

For workplace use, this should be the main Windows target:

- Authenticode signed EXE.
- Per-user MSI.
- Clear publisher identity.
- Admin documentation.

### 3. WinGet

WinGet is appropriate after signing:

```powershell
winget install ronipla.CodexDesktopRTL
```

Do not submit to WinGet before signing unless SmartScreen and enterprise EDR friction is acceptable.

## Why Not Patch Codex In Place?

The official Codex package is installed under `C:\Program Files\WindowsApps`. Patching there would require admin/package permissions and would create a higher-risk support problem.

The safer route is a per-user copied app under:

```text
%LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected
```

## Workplace Friction

Current MVP friction:

- EXE is unsigned.
- It extracts and runs PowerShell scripts.
- It patches a copied Electron app.

This is acceptable for technical MVP testing, but broad workplace distribution should wait for code signing and a clean installer.

## Next Hardening Steps

1. Sign `CodexDesktopRTL.exe`.
2. Publish ZIP, EXE, and checksums with every release.
3. Add MSI.
4. Add WinGet after signing.
5. Add clean Windows VM test evidence to releases.
