---
name: calibrate
description: Invoke when the user runs /calibrate, or asks which model or effort level suits the current task, e.g. "check model for this", "is this the right model?", "what effort should I use?".
disable-model-invocation: true
---
# Calibrate

Give a reasoned model and effort recommendation for the task at hand. The always-on version of this check is the Task Calibration directive, which raises a one-line note on its own; this skill is the long form when the user asks.

---

## 1. Establish the active setting

- **Model:** the environment section names it; a `[calibrate]` hook line, if present, confirms it.
- **Effort:** `${CLAUDE_EFFORT}` (substituted live when this skill loads; ultracode reports as `xhigh`).
- **Available models:** only those the environment lists as current. Never recommend a model from memory.

## 2. Characterise the task

Judge the work itself, not the vocabulary of the prompt:

| Signal | Points toward |
|---|---|
| Design decisions with lasting consequences, cross-cutting tradeoffs, root cause unknown across several systems, security-sensitive logic | higher effort; the most capable model if the active one is not |
| Multi-file implementation with a clear spec, focused debugging with a reproduction | the active model at `high` is usually right |
| Mechanical transforms, single-file edits, lookups, formatting | lower effort; a faster model is enough |
| Very large inputs (long logs, many files) | context window matters more than reasoning; check `/context` first |
| Many independent parts that each need the same treatment | a Workflow (multi-agent) rather than a bigger model |

## 3. Recommend

```
Active:       <model>, effort <level> (<source>)
Recommended:  <same | /model X | /effort Y | Workflow>
Why:          <one sentence tied to the task, not the prompt wording>
```

If the active setting already fits, say so in one line and stop. Switching models mid-session invalidates the prompt cache, so recommend a model switch only when the gain clearly outweighs that.
