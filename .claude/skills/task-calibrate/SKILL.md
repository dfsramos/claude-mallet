---
name: task-calibrate
description: Invoke when the UserPromptSubmit hook flags a high-complexity task, or when the user asks which model or effort level to use for a task. Also invokable explicitly via "/task-calibrate" or "check model for this".
---
# Task Calibration

Assess the current task and surface a model and effort recommendation before work begins.

---

## 1. Classify the Task

Read the user's prompt and classify it against the matrix below. When in doubt, assign the higher tier.

| Tier | Characteristics |
|------|----------------|
| **Mechanical** | Purely structural transforms requiring no judgement: rename a symbol, reformat, find-and-replace a string, sort lines, mechanically apply a pattern. The correct answer is deterministic regardless of model. |
| **Ultracode** | Comprehensive audits, codebase-wide sweeps, "find all bugs / audit everything / review all", large migrations across many files, tasks where parallel breadth produces better results than sequential depth — or wherever "ultracode" or "ultra" appears explicitly in the prompt. This is an *execution mode*, not purely a model tier: use the Workflow tool. |
| **Architectural** | System design, major tradeoffs, cross-cutting decisions, evaluating approaches, new framework primitives, migrations, "from scratch" features, decisions with lasting consequences |
| **Complex** | Multi-file refactors, debugging across files, feature implementation (3–10 files), writing skills with multiple interacting concerns |
| **Routine** | Single-file edits, config changes, skill/hook tweaks, simple refactors, answering factual questions about the codebase |
| **Large Context** | Tasks where volume of input is the constraint: large codebase discovery, debugging with extensive logs, comparing many files, long document analysis |

---

## 2. Apply the Model Matrix

| Tier | Recommended | Switch | Why |
|------|------------|--------|-----|
| Mechanical | No model needed | — | Use direct tools (Edit, Bash, grep) — no model invocation required. Flag this explicitly so the user doesn't wait for a model response on a deterministic operation. |
| Ultracode | `sonnet` (broad sweep) or `opus` (deep per-agent analysis) | Workflow tool | Execution mode, not model tier. `sonnet` for fan-out coverage tasks; `opus` when each agent needs deep reasoning. See Ultracode Agent Personas below. |
| Architectural | `opusplan` | `/model opusplan` | Opus plans, Sonnet executes; use `/model opus` for Opus throughout |
| Complex | `sonnet` | `/model sonnet` | Capable for multi-file work; Opus overhead not justified |
| Routine | `haiku` (new session, T ≤ 2) or `sonnet` (current session) | `/model haiku` | Haiku produces identical results on boilerplate at a fraction of the cost. Suggest a new session only when T ≤ 2; session-switch overhead exceeds savings otherwise |
| Large Context | `sonnet[1m]` | `/model sonnet[1m]` | Volume is the constraint, not reasoning; 1M window avoids truncation |

### Ultracode: when not to use it

Ultracode is not appropriate when:
- Steps are sequentially dependent (step N requires step N-1's output to begin)
- Mid-task user decisions are required (parallel agents cannot pause for input)
- The task is a single focused change (< 3 independent workstreams)
- Full system understanding must be built before any sub-task can be scoped

### Ultracode: Agent Personas

When authoring Workflow scripts, bind agents to existing mallet personas via `agentType` wherever the role matches. Novel roles should be described inline with the same named-persona style.

| `agentType` | Persona | Role |
|-------------|---------|------|
| `code-analyst` | Callum | Reads code → produces change plans |
| `code-reviewer` | Clifford | Reviews diffs for correctness and maintainability |
| `feature-analyst` | Frida | Turns feature requests into structured specs |
| `implementer` | Ingrid | Applies change plans to the codebase |
| `plan-critic` | Percy | Adversarially challenges plans before implementation |
| `scope-validator` | Sylvie | Verifies final implementation against spec |
| `test-runner` | Tobias | Runs tests, returns signal only |

All workflow agents must follow the output contract in `.claude/agents/_contract.md`.

### Subagent model selection

When spawning agents via the Agent tool, choose the model by what the subagent needs to *do*, not by the parent task tier:

| Subagent role | Model |
|---------------|-------|
| File reads, grep, search, single-question lookups | `haiku` |
| Code writing, synthesis, analysis, standard dev | `sonnet` |
| Architectural review, deep multi-file analysis | `sonnet` or `opus` |

---

## 3. Surface the Recommendation

Compare the recommendation against the active model (visible on the statusline) and act:

- **Already on the recommended model** → proceed silently, no interruption.
- **Switch recommended** → state the recommendation in the format below and wait for the user to switch or explicitly continue on the current model.
- **Routine + T ≤ 2** → offer the Haiku-in-new-session option alongside the current-session option.
- **Ultracode, explicit signal in prompt** → proceed with Workflow tool directly; no confirmation needed (the prompt keyword is the opt-in).
- **Ultracode, hook-triggered only** → surface the recommendation below and wait for confirmation before invoking Workflow.

Format (only when a switch is warranted):

```
Task tier: [Ultracode / Architectural / Complex / Routine / Large Context]
Recommended model: [opusplan / sonnet / haiku / sonnet[1m]]
Execution mode: [Workflow (multi-agent) / single-agent]
Switch / trigger: /model <name>  |  include "ultracode" in prompt to proceed
Reason: [one sentence]
```

Keep it to 4–5 lines — no extended reasoning. Do not proceed until the user responds (ultracode hook-only case) or proceed directly (ultracode explicit-signal case).
