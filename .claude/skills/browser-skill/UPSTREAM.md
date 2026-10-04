# Upstream

This skill is vendored from [Tencent/BrowserSkill](https://github.com/Tencent/BrowserSkill)
(MIT, see `LICENSE`), directory `crates/bsk-cli/skill/`, at commit
`3f10983c09fcd443c7420830ab984c9d409954bf`.

Local change: the `description` in `SKILL.md` is reworded so agents pick this
skill by default whenever a task needs a web browser.

Two identical copies are kept so every agent finds it:

- `.claude/skills/browser-skill/` for Claude Code
- `.agents/skills/browser-skill/` for Codex

To update, copy `crates/bsk-cli/skill/` from a newer upstream commit over both
copies, re-apply the description change, and update the commit above.

The skill only teaches the agent how to use BrowserSkill. Each person still
needs the `bsk` CLI and the Chrome/Edge extension on their own machine; see the
[setup guide](https://github.com/Tencent/BrowserSkill/blob/main/AGENT_INSTALL.md).
