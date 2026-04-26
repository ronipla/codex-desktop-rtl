# Architecture

## Components

- `dist/CodexDesktopRTL.exe`: Native Windows launcher built from `CodexDesktopRTLLauncher.asm` and `CodexDesktopRTLLauncher.rc`.
- `CodexDesktopRTL-Portable.ps1`: Runtime orchestrator. Finds Codex, copies it, patches it, creates a shortcut, and launches it.
- `Patch-Codex-Asar-RTL.ps1`: Binary-safe ASAR patcher. Replaces a small global CSS asset inside the copied ASAR and updates the affected ASAR file integrity hash.
- `Patch-Codex-Exe-AsarIntegrity.ps1`: Updates the copied `Codex.exe` `Integrity/ElectronAsar` Windows resource to match the patched ASAR header hash.

## Runtime Flow

```text
User
  |
  v
CodexDesktopRTL.exe
  |
  v
extract embedded payload to %LOCALAPPDATA%\CodexDesktopRTL\Payload
  |
  v
CodexDesktopRTL-Portable.ps1
  |
  +--> find official Codex Desktop package
  +--> copy official app to %LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected
  +--> patch copied resources\app.asar
  +--> update copied Codex.exe integrity resource
  +--> create/update desktop shortcut
  +--> launch copied Codex.exe with isolated user data
```

## Files Written At Runtime

```text
%LOCALAPPDATA%\CodexDesktopRTL\
  Payload\
  Codex-Injected\
  UserData\
  CodexDesktopRTL.cmd
  CodexDesktopRTL-Launch.cmd
  CodexDesktopRTL.ico
  CodexDesktopRTL.log
  app.asar.pre-rtl-bak
  source.marker
```

## Update Detection

`CodexDesktopRTL-Portable.ps1` computes a source signature from the official Codex app path, `app.asar` length/timestamp, and `Codex.exe` length/timestamp. If that signature changes, the injected copy is rebuilt.

## Why Copy Instead Of Patching In Place

The official Codex Desktop app lives under `C:\Program Files\WindowsApps`, which is protected by Windows package permissions. Patching the official app in place would require elevated permissions and would increase the risk of damaging the real install.

This project patches only a per-user copy under `%LOCALAPPDATA%`.

## Isolated User Data

Codex Desktop uses a single-instance lock tied to its Electron user-data path. The launcher sets:

```text
CODEX_ELECTRON_USER_DATA_PATH=%LOCALAPPDATA%\CodexDesktopRTL\UserData
```

This lets the RTL copy run next to the official Codex Desktop session without killing it.

## Patch Strategy

The patcher replaces `webview/assets/plugins-cards-grid-e7LodWnf.css`, a small CSS asset that is loaded by `webview/index.html`. The replacement keeps the exact same byte length, then updates:

- the CSS file SHA256 inside the ASAR header
- the Electron ASAR integrity resource inside the copied `Codex.exe`

If Codex changes the ASAR layout or the CSS slot disappears, the patch fails closed.
