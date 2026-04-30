# Skill Backlog

Items logged during sessions for future review.

<!-- Format for new entries:
## <Title>
- **Triggered by:** <what happened that surfaced this need>
- **Description:** <what the skill would do and when it would be used>
-->

<!-- Example:
## stripe-refund
- **Triggered by:** Had to manually look up the refund API docs mid-session
- **Description:** Automate Stripe refund operations — partial/full refund, check refund status, handle already-refunded errors
-->

---

## Hooks Layer
- **Triggered by:** everything-claude-code evaluation (2026-03-04); reinforced by /insights report (2026-04-30)
- **Description:** The write-guard PreToolUse hook (shipped 2026-04-30) validated the hook pattern. Three further patterns are worth implementing as a focused session: (1) a session-end hook that persists state and extracts reusable patterns — automating what reviewing-sessions does manually; (2) a git push reminder hook that intercepts `git push` and prompts for review before executing; (3) a PostToolUse typecheck/lint hook that runs after Edit on TypeScript/PHP/etc. files to catch errors before they accumulate. A `hooks-setup` skill that guides users through adding these to any project would tie it together.

---

## MCP Server Catalog for Discovery
- **Triggered by:** Context7 evaluation (2026-02-27)
- **Description:** The discover skill currently knows about Context7 specifically. As the MCP ecosystem grows, consider maintaining a structured catalog of MCP servers worth recommending during discovery — each with criteria for when it applies (language, framework type, service category). Could live as a separate reference file the discover skill consults rather than hardcoding server knowledge inline.

---
