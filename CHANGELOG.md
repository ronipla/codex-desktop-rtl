# Changelog

## 0.2.0

- Added `Patch-Codex-Asar-RTL-v2.ps1` — auto-discovers the CSS slot inside `app.asar` instead of hardcoding `plugins-cards-grid-e7LodWnf.css`. Scores `webview/assets/*.css` candidates (`app-shell` priority 1000, `markdown` 900, etc.) and picks the best slot that fits the 189-byte RTL payload. Survives Codex updates that change Vite content hashes.
- Added `Register-AutoUpdate.ps1` and `CodexDesktopRTL-AutoUpdate.ps1` — register a daily + on-logon scheduled task that detects new Codex Desktop versions and re-applies the patch automatically. Skips while Codex is running and retries next cycle.
- Added `Install.cmd` / `Uninstall.cmd` entry points so the bundle is installable without the native EXE launcher.
- `CodexDesktopRTL-Portable.ps1` updated to prefer the v2 patcher when present and to copy the new auto-update scripts into `%LOCALAPPDATA%\CodexDesktopRTL\` on each run.
- Legacy `Patch-Codex-Asar-RTL.ps1` is kept as a fallback for parity testing.

## 0.1.0

- Added native Windows launcher.
- Added PowerShell runtime patcher.
- Added copied-app RTL/BiDi CSS injection.
- Added Electron ASAR integrity resource update.
- Added isolated Codex user data path for side-by-side launch.
- Added retry-based cleanup for reset/rebuild.
- Added richer status diagnostics.
- Added English and Hebrew documentation.
- Added security documentation and E2E testing notes.
