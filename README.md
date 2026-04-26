# Codex Desktop RTL

Codex Desktop RTL launches a copied Codex Desktop app with an injected RTL/BiDi rendering fix for Hebrew mixed with English.

It does not modify the official Codex installation under `C:\Program Files\WindowsApps`.

## What It Does

- Finds the locally installed Codex Desktop package.
- Copies the app folder to `%LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected`.
- Patches a small CSS asset inside the copied `resources\app.asar`.
- Updates Electron ASAR integrity metadata inside the copied `Codex.exe`.
- Launches the copied Codex app.
- Creates a desktop shortcut named `Codex Desktop RTL`.
- Rebuilds the injected copy automatically when the official Codex Desktop app changes.
- Runs the copied Codex with an isolated user-data folder so it can open next to the official Codex session.
- Provides `status` and `reset` modes for diagnostics and repair.

## Run

```powershell
.\dist\CodexDesktopRTL.exe
```

Current artifact:

```text
dist/CodexDesktopRTL.exe
SHA256: CA5A8EAA809EEC5D69BFDBF3615BCBFF225C95AB08C1A139BF1D6EE36299C510
```

Windows may show a SmartScreen warning because the executable is not code-signed.

## Commands

The embedded runner supports:

```powershell
.\CodexDesktopRTL-Portable.ps1 -Mode run
.\CodexDesktopRTL-Portable.ps1 -Mode install
.\CodexDesktopRTL-Portable.ps1 -Mode status
.\CodexDesktopRTL-Portable.ps1 -Mode reset
```

## Build

Requirements:

- Windows.
- Codex Desktop installed.
- Visual Studio Build Tools 2019 or newer with `ml64.exe`, `link.exe`, and Windows SDK `rc.exe`.
- PowerShell 7 is preferred. Windows PowerShell is used as a fallback.

Build:

```powershell
.\Build-CodexDesktopRTL-All.ps1
```

## How It Works

The native launcher embeds the PowerShell patching scripts and icon as Windows resources. On run, it extracts those files to:

```text
%LOCALAPPDATA%\CodexDesktopRTL\Payload
```

Then it runs `CodexDesktopRTL-Portable.ps1`, which:

1. Locates the official Codex Desktop install path.
2. Copies the official app folder into `%LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected`.
3. Patches the copied `resources\app.asar`.
4. Updates the copied `Codex.exe` Electron ASAR integrity resource.
5. Creates or updates the desktop shortcut.
6. Launches the copied Codex app through a current-user scheduled task with `CODEX_ELECTRON_USER_DATA_PATH` set to `%LOCALAPPDATA%\CodexDesktopRTL\UserData`.

The official Codex Desktop installation is not changed.

## Documentation

- Hebrew README: [README.he.md](README.he.md)
- Architecture: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Distribution: [docs/DISTRIBUTION.md](docs/DISTRIBUTION.md)
- Testing: [docs/TESTING.md](docs/TESTING.md)
- Security: [docs/SECURITY.md](docs/SECURITY.md)
- Threat model: [docs/THREAT_MODEL.md](docs/THREAT_MODEL.md)
- Release process: [docs/RELEASE.md](docs/RELEASE.md)

## Current Limitations

- Windows only.
- Unsigned executable.
- The patch is tied to the current Codex Desktop ASAR layout and may need updates when Codex changes its build.
- This intentionally does not stop the official Codex process, so it will not kill the session that is running this work.
