# Skill Backlog

Items logged during sessions for future review.

---

## Investigate `allowed-tools` in SKILL.md frontmatter

**Triggered by:** IDE diagnostic during doc-update session (Feb 2026) flagging `allowed-tools` as unsupported. Supported attributes per the diagnostic: `argument-hint`, `compatibility`, `description`, `disable-model-invocation`, `license`, `metadata`, `name`, `user-invokable`.

**Description:** Verify whether `allowed-tools` still has any functional effect in the current Claude Code version, or if it is silently ignored. If ignored, determine the correct way to restrict tool access in skills (if possible) and update all SKILL.md files accordingly. If it was removed from the schema intentionally, remove the attribute from `source/` and `.claude/` skill files to keep them clean.

---
