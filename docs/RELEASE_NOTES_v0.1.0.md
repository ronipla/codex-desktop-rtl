# Codex Desktop RTL v0.1.0

Initial Windows MVP.

## Included

- Native Windows launcher.
- Runtime RTL/BiDi ASAR patch for copied Codex Desktop app.
- Electron ASAR integrity resource update for the copied executable.
- Isolated `CODEX_ELECTRON_USER_DATA_PATH` so the copied app can run next to the official Codex session.
- Automatic rebuild when the official Codex Desktop app changes.
- Desktop shortcut creation.
- English and Hebrew documentation.
- Security notes.

## Artifacts

```text
CodexDesktopRTL.exe
SHA256: A0877E325CF6F1D663E52B771E71D4C698EFE9F102237502D2B133008ADA7A99
```

## Known Limitations

- Windows only.
- Unsigned executable.
- No MSI yet.
- The patch may need updates when Codex Desktop changes its internal ASAR layout.
