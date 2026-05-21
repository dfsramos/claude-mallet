---
name: dispatching-parallel-agents
description: Invoke when 3 or more independent failures or independent problem domains need to be investigated or fixed simultaneously. Also when a large task can be cleanly partitioned into non-overlapping workstreams.
---
# Dispatching Parallel Agents

When multiple independent problems exist and each can be understood in isolation, dispatching one agent per domain is faster and produces cleaner results than a single agent context-switching between them.

---

## When to Use

All three conditions must hold:

1. **Three or more independent domains**: Each problem or workstream is understandable without knowledge of the others
2. **No shared state**: The agents will not read or write the same files during their work
3. **No sequential dependency**: Agent B does not need Agent A's output to begin

If failures are interconnected, or if resolving one reveals the shape of another, run sequentially — shared context matters.

**Do not use** when:
- Fewer than 3 independent domains (single-agent overhead not worth the coordination cost)
- Agents would compete for the same files (last-write-wins corruption)
- Full system understanding is needed before any sub-task can be scoped correctly
- Mid-task interactive decisions are required (parallel agents cannot pause for user input)

---

## Process

### 1. Identify Independent Domains

List every failure or workstream. For each, ask:
- Can this be understood without knowing about the others?
- Does it touch files no other domain touches?
- Can it be fully resolved by an agent that knows nothing about the other domains?

Discard anything that fails any test. Group the remaining into domains.

### 2. Scope Each Task

Write a self-contained task description for each domain agent. The agent will receive no shared context from the others, so each description must include:
- The specific failure or objective (exact error message, specific file, expected behaviour)
- Working directory and relevant file paths
- Test command to verify the fix
- Output contract: status (done/blocked), files changed, verification result

### 3. Dispatch in Parallel

Send all agents in a **single message** — one subagent tool call per domain. Do not send them sequentially. The point is concurrent execution.

Each agent:
- Reads its own relevant files
- Does its work independently
- Returns its result and a Handoff

### 4. Review and Integrate

When all agents have returned:
- Read every result before acting on any
- Check for conflicts: did any agent touch the same file unexpectedly?
- Apply any fixes needed to resolve conflicts
- Run the full test suite once — individual domain verifications do not substitute for integration

### 5. Surface Results

Report per domain:
```
Domain: <name>
Status: done | blocked
Files changed: [list]
Verification: [test result or manual confirmation]
Blocker (if blocked): [specific description]
```

---

## Example

Six test failures across three unrelated subsystems (auth, payment processing, email delivery):

- Agent A: Investigate and fix auth failures (tests `auth/**`)
- Agent B: Investigate and fix payment failures (tests `payment/**`)
- Agent C: Investigate and fix email failures (tests `email/**`)

Dispatched in one message. No agent touches the other's files. After all three return: run the full suite.

---

## Rationalizations to Reject

- "I can handle them sequentially, it's fine" — it is slower and cross-contaminates the debugging context
- "They might be related" — if they might be related, investigate that relationship first; do not split domains that share a root cause
- "I'll just do the most urgent one first" — urgency is not a reason to skip parallelism when conditions are met
