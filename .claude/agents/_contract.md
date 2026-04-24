# Agent Output Contract

Every agent in the pipeline must return output in this exact structure. No prose outside these sections. The orchestrator parses this to decide next action and construct the next agent's input.

---

```markdown
## Status
[one of: approve | revise | blocked]

## Summary
[1–2 sentences. What happened. What the orchestrator should know.]

## Output
[Role-specific structured content — defined per agent. Must be machine-parseable: lists, tables, code blocks. No narrative paragraphs.]

## Handoff
[The minimal subset of Output that the *next* agent needs. Copy-pasteable into the next agent's prompt verbatim. Omit anything the next agent can derive itself.]
```

---

## Status semantics

| Status | Meaning | Orchestrator action |
|--------|---------|-------------------|
| `approve` | Work is complete and correct | Advance to next step |
| `revise` | Work needs a specific change | Re-run same or previous step with amendments |
| `blocked` | Cannot proceed — missing info or irresolvable conflict | Surface to user, pause pipeline |

## Revision notes

When Status is `revise`, the Output section must include a `## Amendments` subsection listing exactly what must change. Vague feedback ("improve clarity") is not valid — each amendment must be actionable.

## Iteration budget

The orchestrator enforces a 2-iteration cap per step. If a step returns `revise` twice consecutively, it becomes `blocked` automatically and surfaces to the user.
