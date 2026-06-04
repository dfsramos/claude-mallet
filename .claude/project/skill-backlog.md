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
- **Triggered by:** Context7 evaluation (2026-02-27); partially resolved by CLI-Anything addition (2026-06-04)
- **Description:** The discover skill knows about Context7, Impeccable, CLI-Anything, and Graphify inline. As the ecosystem grows further, consider a separate reference file the discover skill consults rather than hardcoding knowledge inline — each entry with install command and trigger criteria. CLI-Anything already demonstrates what a well-structured catalog looks like at the skill-pack layer; the same structure could work for MCP servers.

---

## PreToolUse as Behavior-Shaping Hook
- **Triggered by:** Graphify evaluation (2026-06-04)
- **Description:** Graphify installs a PreToolUse hook that intercepts raw file reads and steers Claude toward a richer source (the knowledge graph). Mallet's hooks currently gate, validate, and log — not redirect. Worth exploring a generalized pattern for "prefer X before Y" hooks that shape tool selection rather than block it. Example use: steer Claude toward `memory.md` or the discover output before broad codebase searches.

---

## Progressive Disclosure for Mallet Memory System
- **Triggered by:** Claude-Mem evaluation (2026-06-04)
- **Description:** Claude-Mem injects memory in layers (cheap index first, expensive detail on demand) rather than all at once. Mallet's `MEMORY.md` is currently injected in full at session start — fine at small scale, but will degrade as memory grows. A tiered approach: inject the index (MEMORY.md as-is), fetch individual memory files only when relevant to the current task. Larger design decision — needs thought on how to trigger per-file reads from the session-start hook context.

---


