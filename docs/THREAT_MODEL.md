# Threat Model

## Scope

In scope:

- Windows native launcher.
- PowerShell runtime runner.
- ASAR patcher.
- EXE integrity resource patcher.
- GitHub release artifact.

Out of scope:

- Codex Desktop internals beyond the copied files being patched.
- OpenAI account security.
- Codex conversation/session storage managed by the official app.
- Windows package manager security.
- macOS/Linux support.

## Assumptions

- The user intentionally installs and runs this tool.
- The official Codex Desktop app is already installed locally.
- The current Windows user account is trusted.
- The machine is not already compromised by same-user malware.
- The tool is distributed through a trusted GitHub repository or release channel.

## Assets

- User trust in the downloaded EXE.
- Official Codex Desktop app integrity.
- Codex account/session data handled by Codex Desktop.
- `%LOCALAPPDATA%\CodexDesktopRTL` runtime files.
- Build artifacts and GitHub release assets.

## Trust Boundaries

| Boundary | Description | Security relevance |
| --- | --- | --- |
| User to downloaded artifact | User runs `CodexDesktopRTL.exe`. | Artifact tampering would lead to code execution. |
| Launcher to `%LOCALAPPDATA%` | EXE extracts scripts to user-writable storage. | Same-user tampering is possible. |
| Runner to official Codex package | Runner reads/copies from `WindowsApps`. | It trusts the installed Codex package. |
| Runner to copied Codex app | Runner modifies copied ASAR and EXE resource. | Integrity must match or Electron refuses to load. |
| Runner to scheduled task | Runner creates a current-user scheduled task. | Task command must stay constrained to the copied Codex path. |
| Copied Codex to isolated user data | RTL copy uses separate user data. | Prevents single-instance collision but creates separate local state. |

## Entry Points

- `CodexDesktopRTL.exe`
- `CodexDesktopRTL-Portable.ps1`
- Desktop shortcut `Codex Desktop RTL.lnk`
- Build scripts

## Threats And Mitigations

### T1: Malicious or tampered release artifact

Impact: High. Running a tampered EXE gives arbitrary code execution as the user.

Existing controls:

- Small source footprint.
- SHA256 hashes documented.
- No runtime network code download.

Recommended controls:

- Authenticode signing.
- GitHub Release checksums.
- Reproducible build notes.
- CI build provenance.

### T2: Same-user tampering of extracted payload

Impact: Medium. Files under `%LOCALAPPDATA%` are writable by the user and therefore by malware running as that user.

Existing controls:

- Payload is re-extracted by the EXE on run.

Recommended controls:

- Verify embedded payload hashes before execution.
- Sign scripts or verify signatures in a future version.

### T3: Accidental damage to official Codex installation

Impact: Medium.

Existing controls:

- The tool copies Codex to `%LOCALAPPDATA%`.
- It patches only the copied app.
- It does not require admin rights.

Recommended controls:

- Keep this design.
- Never add in-place patching of `WindowsApps`.

### T4: Codex update breaks the patch

Impact: Low for security, medium for reliability.

Existing controls:

- Source signature detects app updates.
- Patcher fails if the expected ASAR entry is missing.
- Status mode reports whether the patched marker exists.

Recommended controls:

- Add CI fixtures where legally possible.
- Add a clearer unsupported-version error with the detected Codex version.

### T5: Isolated user-data surprises

Impact: Low to medium. Users may need to sign in again because the RTL copy has separate Electron user data.

Existing controls:

- The isolated path is documented.
- It avoids killing or hijacking the official Codex session.

Recommended controls:

- Add an optional shared-user-data mode only if it can be done safely.

## Highest Priority Security Work

1. Code signing for `CodexDesktopRTL.exe`.
2. Publish checksums and release provenance.
3. Add embedded payload hash verification.
4. Test in a clean Windows VM.
5. Add MSI/WinGet only after signing.
