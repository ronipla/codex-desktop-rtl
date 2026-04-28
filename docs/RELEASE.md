# Release Process

## Build

```powershell
.\Build-CodexDesktopRTL-All.ps1
```

Expected outputs:

```text
dist/CodexDesktopRTL.exe
dist/CodexDesktopRTL-v0.1.0-Windows.zip
dist/CHECKSUMS.txt
```

## Verify

```powershell
Get-FileHash .\dist\CodexDesktopRTL.exe -Algorithm SHA256
Get-FileHash .\dist\CodexDesktopRTL-v0.1.0-Windows.zip -Algorithm SHA256
Get-Content .\dist\CHECKSUMS.txt
```

Run the E2E checklist in `docs/TESTING.md`.

## GitHub Release

After GitHub authentication is configured:

```powershell
gh auth login
.\Publish-GitHub.ps1
```

The GitHub Release should include:

- `CodexDesktopRTL-v0.1.0-Windows.zip` for normal users.
- `CodexDesktopRTL.exe` for direct/manual testing.
- `CHECKSUMS.txt` for hash verification.

## MSI

MSI is not part of this MVP. Recommended future path:

- WiX Toolset.
- Per-user install by default.
- Signed MSI and signed EXE.
- GitHub Actions release build.

## Versioning

Use semantic versioning:

- Patch version for fixes to the same Codex ASAR layout.
- Minor version when adding packaging/distribution paths.
- Major version if runtime behavior changes in a way that affects user data or install layout.
