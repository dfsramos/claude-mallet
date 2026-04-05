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

---

## 2. Apply the Model Matrix

| Tier | Main Session | Why |
|------|-------------|-----|
| Architectural | **Opus** | Fewer first-attempt reasoning errors on complex design → fewer correction rounds; net cost often lower than 3–4 Sonnet turns |
| Complex | **Sonnet** | Capable; Opus overhead not justified |
| Routine | **Sonnet** | Overkill for Opus; session switch cost exceeds Haiku savings |

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
Task tier: [Architectural / Complex / Routine]
Recommended model: [Opus / Sonnet]
Reason: [one sentence]

Proceed on Sonnet, or start a new session with Opus first?
```

If the task is Routine or Complex (Sonnet is already active), skip the question and proceed immediately — no need to interrupt.

Only pause for confirmation when recommending an upgrade to Opus.

---

## 4. When Opus Is Recommended

Give the user the switch command and wait for their response before starting work:

```
To switch: restart the session with `claude --model claude-opus-4-6`
```

Do not proceed with the task until the user either confirms they want to switch or explicitly says to continue on Sonnet.
