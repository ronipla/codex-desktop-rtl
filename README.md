# Codex Desktop RTL

Codex Desktop RTL is a Windows launcher that creates a local RTL-enabled Codex Desktop copy for Hebrew mixed with English.

This project is independent. It is not an OpenAI product, does not include Codex Desktop, and does not modify the official Codex installation under `C:\Program Files\WindowsApps`.

## Download

For normal users, download the ZIP and run the EXE inside it:

- [CodexDesktopRTL-v0.1.0-Windows.zip](dist/CodexDesktopRTL-v0.1.0-Windows.zip)

Advanced artifact:

- [CodexDesktopRTL.exe](dist/CodexDesktopRTL.exe)
- [CHECKSUMS.txt](dist/CHECKSUMS.txt)

## Installation

1. Install the official Codex Desktop app first.
2. Download `CodexDesktopRTL-v0.1.0-Windows.zip`.
3. Extract the ZIP.
4. Double-click `CodexDesktopRTL.exe`.
5. If Windows SmartScreen warns, choose `More info` and then `Run anyway` only if you trust the source.

After first run, a desktop shortcut named `Codex Desktop RTL` is created.

## What It Does

- Finds the locally installed official Codex Desktop package.
- Copies the official app folder to `%LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected`.
- Patches the copied `resources\app.asar` with an RTL/BiDi CSS fix.
- Updates Electron ASAR integrity metadata in the copied `Codex.exe`.
- Runs the copied app with an isolated user data directory.
- Creates or updates a desktop shortcut.
- Rebuilds the local copy when the official Codex app changes.

## What It Does Not Do

- Does not patch `C:\Program Files\WindowsApps`.
- Does not change the official Codex installation.
- Does not bundle Codex binaries.
- Does not install a service.
- Does not add a startup entry.
- Does not collect tokens, cookies, credentials, or conversation content.
- Does not open inbound network ports.

## Important Difference From Claude Desktop RTL

Claude Desktop RTL launches the official signed Claude app and injects RTL at runtime.

Codex Desktop RTL currently uses a copied/patched local app because this was the reliable path for Codex Desktop. This is more likely to trigger SmartScreen or enterprise EDR than the Claude runtime-injection approach. For broad workplace distribution, use code signing and test with endpoint security tools first.

## How It Works

`CodexDesktopRTL.exe` is a small native Windows launcher. It extracts the PowerShell runner, patch scripts, and icon to:

```text
%LOCALAPPDATA%\CodexDesktopRTL\Payload
```

The PowerShell runner then:

1. Locates the official Codex Desktop install path.
2. Copies it to `%LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected`.
3. Patches the copied `resources\app.asar`.
4. Updates the copied `Codex.exe` Electron ASAR integrity resource.
5. Creates `%LOCALAPPDATA%\CodexDesktopRTL\UserData`.
6. Launches the copied app with `CODEX_ELECTRON_USER_DATA_PATH` set to that isolated user data folder.

The official Codex installation is not changed.

## Files Written

```text
%LOCALAPPDATA%\CodexDesktopRTL\
  Payload\
  Codex-Injected\
  UserData\
  CodexDesktopRTL-Portable.ps1
  CodexDesktopRTL.cmd
  CodexDesktopRTL-Launch.cmd
  CodexDesktopRTL.ico
  CodexDesktopRTL.log
  source.marker
```

## Uninstall / Reset

Close Codex Desktop RTL, then run:

```powershell
%LOCALAPPDATA%\CodexDesktopRTL\CodexDesktopRTL-Portable.ps1 -Mode reset
```

Or manually delete:

```text
%LOCALAPPDATA%\CodexDesktopRTL
Desktop\Codex Desktop RTL.lnk
```

The official Codex Desktop installation is not affected.

## Versioning

This project uses semantic versioning:

- Patch releases: fixes for the same Codex ASAR layout, docs, packaging.
- Minor releases: new distribution paths or larger runtime changes.
- Major releases: install layout or security model changes.

Current Windows version: `0.1.0`.

## Common Issues

### SmartScreen warning

The EXE is not code-signed yet. This is expected for the current MVP. For workplace distribution, use an Authenticode-signed build.

### Codex opens a separate session

This is expected. The copied app uses `%LOCALAPPDATA%\CodexDesktopRTL\UserData` so it does not collide with the official Codex session.

### Codex is not found

Install the official Codex Desktop app first, then run `CodexDesktopRTL.exe` again.

### RTL stops working after Codex updates

Run reset, then run the EXE again:

```powershell
%LOCALAPPDATA%\CodexDesktopRTL\CodexDesktopRTL-Portable.ps1 -Mode reset
```

If the patch still fails, Codex likely changed its internal ASAR layout and the patcher must be updated.

### Antivirus or enterprise EDR warning

This build extracts PowerShell scripts and patches a copied Electron app. That is transparent and intentional, but unsigned MVP builds may still be flagged. Use code signing before workplace rollout.

## Security / Transparency

The tool only patches the per-user copy under `%LOCALAPPDATA%`. It does not alter the official Codex package. The tradeoff is that the copied app is locally modified, so this path is less enterprise-friendly than a signed, notarized, vendor-supported build.

See:

- [Security](docs/SECURITY.md)
- [Threat model](docs/THREAT_MODEL.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Testing](docs/TESTING.md)
- [Release process](docs/RELEASE.md)
