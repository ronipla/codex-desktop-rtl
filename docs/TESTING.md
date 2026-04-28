# Testing

## Manual E2E Test Performed

```powershell
.\CodexDesktopRTL-Portable.ps1 -Mode reset
.\dist\CodexDesktopRTL.exe
.\CodexDesktopRTL-Portable.ps1 -Mode status
tar -tf .\dist\CodexDesktopRTL-v0.1.0-Windows.zip
```

Verify:

- `CodexDesktopRTL.exe` exits with code `0`.
- `%LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected\Codex.exe` exists.
- `%LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected\resources\app.asar` exists.
- The patched ASAR contains `unicode-bidi:plaintext`.
- The desktop shortcut `Codex Desktop RTL.lnk` exists.
- A Codex process runs from `%LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected\Codex.exe`.
- The copied app uses `%LOCALAPPDATA%\CodexDesktopRTL\UserData` via `CODEX_ELECTRON_USER_DATA_PATH`.
- Status mode reports `AsarContainsBidiMarker: True`.
- The ZIP includes `CodexDesktopRTL.exe`, `README_HE.txt`, `README_EN.txt`, and `CHECKSUMS.txt`.

Result on the development machine:

```json
{
  "LauncherExitCode": 0,
  "InjectedExeExists": true,
  "AsarExists": true,
  "AsarContainsBidiMarker": true,
  "ShortcutExists": true,
  "UserDataExists": true,
  "RunningInjectedCodexProcesses": 1,
  "StatusReportsMarker": true
}
```

## Known Gaps

- SmartScreen behavior is not tested because the EXE is unsigned.
- This is not yet packaged as MSI.
- The UI needs manual visual verification with a Hebrew/English Codex conversation.
