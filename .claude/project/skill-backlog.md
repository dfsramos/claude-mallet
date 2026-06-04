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

## MCP Server Catalog for Discovery
- **Triggered by:** Context7 evaluation (2026-02-27); partially resolved by CLI-Anything addition (2026-06-04)
- **Description:** The discover skill knows about Context7, Impeccable, CLI-Anything, and Graphify inline. As the ecosystem grows further, consider a separate reference file the discover skill consults rather than hardcoding knowledge inline — each entry with install command and trigger criteria. CLI-Anything already demonstrates what a well-structured catalog looks like at the skill-pack layer; the same structure could work for MCP servers.

---

## Progressive Disclosure for Mallet Memory System
- **Triggered by:** Claude-Mem evaluation (2026-06-04)
- **Description:** Claude-Mem injects memory in layers (cheap index first, expensive detail on demand) rather than all at once. Mallet's `MEMORY.md` is currently injected in full at session start — fine at small scale, but will degrade as memory grows. A tiered approach: inject the index (MEMORY.md as-is), fetch individual memory files only when relevant to the current task. Larger design decision — needs thought on how to trigger per-file reads from the session-start hook context.

---


