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

## "God Nodes" Surface in Discover Skill
- **Triggered by:** Graphify evaluation (2026-06-04)
- **Description:** Graphify's GRAPH_REPORT.md surfaces the highest-degree nodes — the files/symbols everything routes through. Mallet's discover skill produces gap analysis and recommendations but doesn't surface centrality. Adding a "critical files" output to discover — even approximated via import counts or cross-reference grep — would help Claude and the user orient faster in unfamiliar codebases.

---

## 3-Layer Filter-Before-Fetch Retrieval Directive
- **Triggered by:** Claude-Mem evaluation (2026-06-04)
- **Description:** When retrieving from any large dataset (codebase search, issue lists, web results, grep output), follow a 3-layer sequence: (1) get a compact index of IDs/summaries, (2) identify relevant items, (3) fetch full detail only for those items. Mallet's current directives cover piping bulk output through filters and "Think in Code", but the explicit index→filter→fetch sequencing is more actionable and generalises across all retrieval tasks. Candidate for a directive in CLAUDE.md under Tool Preferences, or as a new "Retrieval" section.

---

## Progressive Disclosure for Mallet Memory System
- **Triggered by:** Claude-Mem evaluation (2026-06-04)
- **Description:** Claude-Mem injects memory in layers (cheap index first, expensive detail on demand) rather than all at once. Mallet's `MEMORY.md` is currently injected in full at session start — fine at small scale, but will degrade as memory grows. A tiered approach: inject the index (MEMORY.md as-is), fetch individual memory files only when relevant to the current task. Larger design decision — needs thought on how to trigger per-file reads from the session-start hook context.

---

## PreCompact Hook for Mission Continuity
- **Triggered by:** Context Mode evaluation (2026-06-04)
- **Description:** Mallet's mission continuity relies on a manual wrap-up step writing `active.md`. Context Mode uses a PreCompact hook that automatically captures in-progress state (files being edited, active tasks, errors, user decisions) before the conversation compacts, then restores it at session start. Mallet doesn't currently register a PreCompact hook at all. An automated snapshot hook would make continuity more reliable than the current manual flow. Needs design: what to capture, where to write it, and how to avoid conflicts with the existing `active.md` mechanism.

---

## Architecture Decision Records (ADR) Skill
- **Triggered by:** Ruflo evaluation (2026-06-04); Ruflo's `ruflo-adr` plugin
- **Description:** A `/adr` skill that scaffolds and maintains Architecture Decision Records in the standard Nygard format (`docs/adr/NNNN-title.md`): Context, Decision, Consequences. Invoked when a significant architectural choice is being made (database selection, framework adoption, key pattern choices). No equivalent exists in Mallet. Would complement the `plan-feature` skill — significant design decisions made during planning could be immediately captured as ADRs.

---

## 3-Tier Routing Dimension for task-calibrate
- **Triggered by:** Ruflo evaluation (2026-06-04); Ruflo's ADR-026/ADR-143
- **Description:** Ruflo defines Tier 1 = deterministic codemod (structural transforms with no LLM, $0), Tier 2 = Haiku, Tier 3 = Sonnet/Opus. Mallet's `task-calibrate` currently decides Sonnet vs Opus. Worth adding a "no model needed" tier for purely structural transforms (rename, reformat, mechanical find-and-replace) — tasks that should be identified as codemods or direct tool calls before reaching for any model at all.

---
