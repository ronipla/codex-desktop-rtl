# Contributing

## Development Rules

- Do not patch the official Codex Desktop installation in place.
- Keep runtime writes under `%LOCALAPPDATA%\CodexDesktopRTL`.
- Keep process termination scoped to the injected Codex copy only.
- Update `docs/TESTING.md` when changing launch or patch behavior.
- Rebuild artifacts with `.\Build-CodexDesktopRTL-All.ps1` before release.

## Local Build

```powershell
.\Build-CodexDesktopRTL-All.ps1
```

## E2E Test

```powershell
.\CodexDesktopRTL-Portable.ps1 -Mode reset
.\dist\CodexDesktopRTL.exe
.\CodexDesktopRTL-Portable.ps1 -Mode status
```

Verify that the copied Codex process runs from:

```text
%LOCALAPPDATA%\CodexDesktopRTL\Codex-Injected\Codex.exe
```

## Security

Do not add runtime code downloads. All code executed by the launcher should be embedded in the release artifact or committed in this repository.
