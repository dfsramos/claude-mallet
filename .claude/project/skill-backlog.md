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

## PreToolUse as Behavior-Shaping Hook
- **Triggered by:** Graphify evaluation (2026-06-04)
- **Description:** Graphify installs a PreToolUse hook that intercepts raw file reads and steers Claude toward a richer source (the knowledge graph). Mallet's hooks currently gate, validate, and log — not redirect. Worth exploring a generalized pattern for "prefer X before Y" hooks that shape tool selection rather than block it. Example use: steer Claude toward `memory.md` or the discover output before broad codebase searches.

---

## "God Nodes" Surface in Discover Skill
- **Triggered by:** Graphify evaluation (2026-06-04)
- **Description:** Graphify's GRAPH_REPORT.md surfaces the highest-degree nodes — the files/symbols everything routes through. Mallet's discover skill produces gap analysis and recommendations but doesn't surface centrality. Adding a "critical files" output to discover — even approximated via import counts or cross-reference grep — would help Claude and the user orient faster in unfamiliar codebases.

---
