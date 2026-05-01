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

## Session-End Hook
- **Triggered by:** everything-claude-code evaluation (2026-03-04); re-evaluated 2026-05-01
- **Description:** Automatically persist state and extract reusable patterns at session end, replacing the manual reviewing-sessions flow. Deferred because automating the wrap-up removes the review step — the manual skill produces higher-quality output. Needs a clearer design before implementation: what does an automated wrap-up look like that preserves quality?

---

## MCP Server Catalog for Discovery
- **Triggered by:** Context7 evaluation (2026-02-27)
- **Description:** The discover skill currently knows about Context7 specifically. As the MCP ecosystem grows, consider maintaining a structured catalog of MCP servers worth recommending during discovery — each with criteria for when it applies (language, framework type, service category). Could live as a separate reference file the discover skill consults rather than hardcoding server knowledge inline.

---
