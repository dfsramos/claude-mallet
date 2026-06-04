---
name: adr
description: Invoke when the user says "record this decision", "create an ADR", "document why we chose X", or runs /adr. Also invoke during plan-feature when a significant architectural choice is made (database, framework, communication pattern, key library) and the rationale should be preserved.
---
# Architecture Decision Records

Capture a significant architectural decision in the standard Nygard format so the rationale survives beyond the session.

---

## 1. Locate the ADR Directory

Check whether `docs/adr/` exists in the project root.

- **Exists**: find the highest existing number (`ls docs/adr/*.md | sort | tail -1`) and increment it.
- **Does not exist**: create it. The first ADR is `0001`.

Number format: four digits, zero-padded — `0001`, `0042`, `0123`.

---

## 2. Gather the Decision

If the user hasn't already described the decision fully, ask the minimum necessary questions:

- **What was decided?** (one sentence — the actual choice made)
- **What problem or context forced this decision?** (forces, constraints, current state)
- **What alternatives were considered?** (even briefly — "we looked at X and Y")
- **What are the consequences?** (trade-offs accepted, follow-on work created, risks acknowledged)

Don't ask for information already present in the conversation. Extract what you can from context and only fill gaps.

---

## 3. Write the ADR

Create `docs/adr/NNNN-<kebab-case-title>.md`:

```markdown
# NNNN. <Title>

Date: YYYY-MM-DD
Status: Accepted

## Context

<What situation, constraint, or problem required a decision. Include relevant
forces: technical, organisational, timeline. Be specific — future readers
won't have the original conversation.>

## Decision

<The change that was decided on. One or two clear sentences. Active voice:
"We will use X" not "X was chosen".>

## Alternatives Considered

- **<Option A>** — <why it was ruled out or not chosen>
- **<Option B>** — <why it was ruled out or not chosen>

_(Omit if no meaningful alternatives were evaluated.)_

## Consequences

<What becomes easier or harder as a result. Trade-offs accepted. Follow-on
work created. Risks acknowledged. Be honest — especially about the downsides.>
```

Valid `Status` values: `Accepted` | `Deprecated` | `Superseded by [NNNN](NNNN-title.md)`

---

## 4. Update the Index

If `docs/adr/README.md` exists, append a row. If it doesn't exist, create it:

```markdown
# Architecture Decision Records

| # | Title | Status | Date |
|---|-------|--------|------|
| [0001](0001-title.md) | Title | Accepted | YYYY-MM-DD |
```

---

## 5. Offer to Link It

If there is an active feature plan (`.claude/features/`) or a mission file (`.claude/project/missions/active.md`) whose scope this decision belongs to, offer to add a reference:

> "Want me to link this ADR from the feature plan / active mission?"

Only offer — do not modify those files without confirmation.

---

## 6. Commit

Stage and commit the new ADR (and index if updated):

```
Add ADR-NNNN: <title>.
```
