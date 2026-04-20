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
| **Architectural** | System design, major tradeoffs, cross-cutting decisions, evaluating approaches, new framework primitives, migrations, "from scratch" features, decisions with lasting consequences |
| **Complex** | Multi-file refactors, debugging across files, feature implementation (3–10 files), writing skills with multiple interacting concerns |
| **Routine** | Single-file edits, config changes, skill/hook tweaks, simple refactors, answering factual questions about the codebase |
| **Large Context** | Tasks where volume of input is the constraint: large codebase discovery, debugging with extensive logs, comparing many files, long document analysis |

---

## 2. Apply the Model Matrix

| Tier | Recommended | Switch | Why |
|------|------------|--------|-----|
| Architectural | `opusplan` | `/model opusplan` | Opus plans, Sonnet executes; use `/model opus` for Opus throughout |
| Complex | `sonnet` | `/model sonnet` | Capable for multi-file work; Opus overhead not justified |
| Routine | `haiku` (new session, T ≤ 2) or `sonnet` (current session) | `/model haiku` | Haiku produces identical results on boilerplate at a fraction of the cost. Suggest a new session only when T ≤ 2; session-switch overhead exceeds savings otherwise |
| Large Context | `sonnet[1m]` | `/model sonnet[1m]` | Volume is the constraint, not reasoning; 1M window avoids truncation |

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

Format (only when a switch is warranted):

```
Task tier: [Architectural / Complex / Routine / Large Context]
Recommended model: [opusplan / sonnet / haiku / sonnet[1m]]
Switch: /model <name>
Reason: [one sentence]
```

Keep it to 3–4 lines — no extended reasoning. Do not proceed until the user responds.
