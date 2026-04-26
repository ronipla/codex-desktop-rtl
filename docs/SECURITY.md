# Security

## Security Posture

Codex Desktop RTL is a local desktop utility. It does not run a server, does not expose an HTTP API, and does not intentionally collect or transmit user data.

The security-sensitive behavior is local code execution:

- The EXE extracts embedded scripts.
- The scripts copy and patch a local Electron app.
- The copied app is launched as the current user.

## What The Tool Does Not Do

- It does not modify the official Codex Desktop installation.
- It does not require administrator rights.
- It does not install a service.
- It does not add a startup entry.
- It does not open inbound network ports.
- It does not read Codex conversation contents.
- It does not collect tokens, cookies, or credentials.
- It does not bundle OpenAI/Codex binaries.

## Files Written At Runtime

All runtime writes are under:

```text
%LOCALAPPDATA%\CodexDesktopRTL
```

## Current Risks

- The executable is not code-signed, so SmartScreen or enterprise EDR may warn.
- The tool patches a copied Electron ASAR and therefore can break after Codex updates.
- Files under `%LOCALAPPDATA%` are writable by the current user and same-user malware.

## Mitigations

- The official app is copied, not patched in place.
- The patcher fails if the expected ASAR entry is missing.
- The copied app is rebuilt when the official app changes.
- Release artifacts should include SHA256 checksums.
- Code signing should be added before broad workplace distribution.
