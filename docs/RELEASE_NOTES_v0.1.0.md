# Codex Desktop RTL v0.1.0

Initial Windows MVP.

## Included

- Native Windows launcher.
- Runtime RTL/BiDi ASAR patch for copied Codex Desktop app.
- Electron ASAR integrity resource update for the copied executable.
- Isolated `CODEX_ELECTRON_USER_DATA_PATH` so the copied app can run next to the official Codex session.
- Retry-based cleanup for reset/rebuild.
- Diagnostic status mode that reports whether the ASAR marker is present.
- Automatic rebuild when the official Codex Desktop app changes.
- Desktop shortcut creation.
- English and Hebrew documentation.
- Security notes.

## Artifacts

```text
CodexDesktopRTL.exe
SHA256: CA5A8EAA809EEC5D69BFDBF3615BCBFF225C95AB08C1A139BF1D6EE36299C510
```

## Known Limitations

- Windows only.
- Unsigned executable.
- No MSI yet.
- The patch may need updates when Codex Desktop changes its internal ASAR layout.
