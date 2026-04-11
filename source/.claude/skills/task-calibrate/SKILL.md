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

| Tier | Recommended Model | Why |
|------|------------------|-----|
| Architectural | **`opusplan`** | Opus reasons through the plan, Sonnet executes — best of both; use `/model opus` if you want Opus throughout |
| Complex | **`sonnet`** | Capable; Opus overhead not justified |
| Routine | **`haiku`** (new session, T ≤ 2) or **`sonnet`** (current session) | For pure boilerplate — config edits, single-file changes, repetitive code generation — Haiku produces identical results at a fraction of the output cost. Suggest a new session only when T ≤ 2 on the statusline; otherwise session-switch overhead exceeds savings. |
| Large Context | **`sonnet[1m]`** | Context size is the constraint, not reasoning power; 1M window avoids truncation |

### Subagent model selection

When spawning agents via the Agent tool, choose the model by what the subagent needs to *do*, not by the parent task tier:

| Subagent role | Model |
|---------------|-------|
| File reads, grep, search, single-question lookups | `haiku` |
| Code writing, synthesis, analysis, standard dev | `sonnet` |
| Architectural review, deep multi-file analysis | `sonnet` or `opus` |

---

## 3. Surface the Recommendation

State the classification and recommendation clearly, then ask whether to proceed or switch first. Keep it to 3–4 lines — no extended reasoning.

Format:
```
Task tier: [Architectural / Complex / Routine / Large Context]
Recommended model: [opusplan / sonnet / haiku / sonnet[1m]]
Reason: [one sentence]

Proceed on current model, or switch first?
```

If the task is Complex (Sonnet is already active), skip the question and proceed immediately — no need to interrupt.

For Routine tasks: if T ≤ 2 (visible on the statusline), offer the Haiku option before proceeding. Otherwise proceed on Sonnet.

Only pause for confirmation when recommending a model switch.

---

## 4. When a Switch Is Recommended

Give the user the switch command and wait for their response before starting work:

| Recommendation | Switch command |
|----------------|---------------|
| `opusplan` | `/model opusplan` |
| `opus` (full session) | `/model opus` |
| `haiku` | `/model haiku` |
| `sonnet[1m]` | `/model sonnet[1m]` |

Do not proceed with the task until the user either switches or explicitly says to continue on the current model.
