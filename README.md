# Codex Desktop RTL

Codex Desktop RTL is a Windows launcher that creates a local RTL-enabled Codex Desktop copy for Hebrew mixed with English.

This project is independent. It is not an OpenAI product, does not include Codex Desktop, and does not modify the official Codex installation under `C:\Program Files\WindowsApps`.

## Download

Download the latest release from the [Releases page](https://github.com/ronipla/codex-desktop-rtl/releases/latest):

- [CodexDesktopRTL-v0.2.0-Windows.zip](https://github.com/ronipla/codex-desktop-rtl/releases/download/v0.2.0/CodexDesktopRTL-v0.2.0-Windows.zip)
- [CHECKSUMS.txt](https://github.com/ronipla/codex-desktop-rtl/releases/download/v0.2.0/CodexDesktopRTL-v0.2.0-Windows.zip.CHECKSUMS.txt)

Older artifacts (v0.1.0, EXE launcher):

- See [dist/](dist/)

## Installation

1. Install the official Codex Desktop app from the Microsoft Store first.
2. Download `CodexDesktopRTL-v0.2.0-Windows.zip` from the Releases page.
3. Extract the ZIP anywhere (Desktop, Downloads, etc.).
4. Close all open Codex windows.
5. Double-click `Install.cmd` inside the extracted folder.
6. If Windows SmartScreen warns, choose `More info` and then `Run anyway` only if you trust the source.

After installation, launch from the new desktop shortcut named `Codex Desktop RTL`.

A daily + on-logon scheduled task is registered so future Codex Desktop updates re-apply the RTL patch automatically — no manual action required.

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

Current Windows version: `0.2.0`.

### What's new in 0.2.0

- **Auto-discovery patcher (`Patch-Codex-Asar-RTL-v2.ps1`)** — no longer hardcodes the CSS slot. Scans the asar for suitable candidates (`app-shell`, `markdown`, etc.) and picks the best one. Survives Codex updates that change Vite content hashes.
- **Auto-update scheduled task** — daily and on-logon checks for new Codex Desktop versions and re-applies the patch.
- **Plain `Install.cmd` / `Uninstall.cmd`** entry points so users without the EXE launcher can install too.
- The legacy `Patch-Codex-Asar-RTL.ps1` is kept as a fallback.

## Common Issues

### SmartScreen warning

The EXE is not code-signed yet. This is expected for the current MVP. For workplace distribution, use an Authenticode-signed build.

### Codex opens a separate session

This is expected. The copied app uses `%LOCALAPPDATA%\CodexDesktopRTL\UserData` so it does not collide with the official Codex session.

### Codex is not found

Install the official Codex Desktop app first, then run `CodexDesktopRTL.exe` again.

### RTL stops working after Codex updates

**Since v0.2.0** this is handled automatically — a scheduled task checks daily (and on every logon) whether the official Codex Desktop has been updated and re-applies the RTL patch if so. Logs at `%LOCALAPPDATA%\CodexDesktopRTL\AutoUpdate.log`.

If you need to force a manual refresh:

```powershell
%LOCALAPPDATA%\CodexDesktopRTL\CodexDesktopRTL-Portable.ps1 -Mode run
```

If the patch fails on a brand-new Codex layout, run reset and try again:

```powershell
%LOCALAPPDATA%\CodexDesktopRTL\CodexDesktopRTL-Portable.ps1 -Mode reset
```

The v2 patcher auto-discovers the CSS slot inside the asar, so most Vite hash changes (the most common reason older versions broke) no longer require any update to this tool.

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
