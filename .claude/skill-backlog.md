# Skill Backlog

Items logged during sessions for future review.

---

## Hooks Layer
**Triggered by:** everything-claude-code evaluation (2026-03-04)
**Description:** Claude Code supports event-driven hook scripts (PreToolUse, PostToolUse, session start/end) that fire automatically without user invocation. Two patterns worth implementing: (1) a session-end hook that persists state and extracts reusable patterns — automating what reviewing-sessions does manually; (2) a git push reminder hook that intercepts `git push` and prompts for review before executing. Requires hook scripts, a distribution mechanism, and project-level activation. Deserves its own focused session.

---

## MCP Server Catalog for Discovery
**Triggered by:** Context7 evaluation (2026-02-27)
**Description:** The discover skill currently knows about Context7 specifically. As the MCP ecosystem grows, consider maintaining a structured catalog of MCP servers worth recommending during discovery — each with criteria for when it applies (language, framework type, service category). Could live as a separate reference file the discover skill consults rather than hardcoding server knowledge inline.

---

