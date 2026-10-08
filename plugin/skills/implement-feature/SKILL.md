---
name: implement-feature
description: Invoke when the user asks to implement a feature, add functionality, or make a non-trivial code change through the full spec → plan → critique → implement → test → validate → review pipeline, or asks to resume such a pipeline.
---
# Implement Feature

Runs the `feature-pipeline` workflow, which passes the work through the Mallet personas — Frida (spec), Callum (plan), Percy (critique), Ingrid (implement), Tobias (test), Sylvie (scope), Clifford (review) — each in its own subagent. This skill only collects inputs, launches the workflow, and handles what the workflow cannot: questions for the user.

---

## 1. Collect inputs

From the conversation, or by asking in a single message:
- **Feature description** (required)
- **Test command** (required — e.g. `pytest`, `npm test`, `dotnet test ./Solution.sln`)
- **Working directory** (default: project root)
- Three yes/no options, all defaulting to yes:
  1. **Plan critique** — Percy challenges the plan before any code is written
  2. **Scope validation** — Sylvie checks the result against the acceptance criteria before review
  3. **Code review** — Clifford reviews the diff

Gather short context for Frida if it is cheap: the stack, the relevant directory, prior decisions from the conversation. Pass file paths, not file contents.

## 2. Launch

Call the Workflow tool with `name: "feature-pipeline"` (or `mallet:feature-pipeline` where the plugin namespaces it) and:

```json
{
  "feature": "<description>",
  "testCommand": "<command>",
  "workingDir": "<path>",
  "context": "<short context, optional>",
  "critique": true,
  "scopeValidation": true,
  "review": true
}
```

Set `agentPrefix` to `""` only when the personas are installed without the plugin namespace (for example, copied into `~/.claude/agents/`).

## 3. Handle the result

The workflow returns `status`, `stoppedAt`, `detail`, and a `runLog`.

| `status` | Action |
|---|---|
| `done` | Report the run log, changed files, test summary, and Clifford's non-blocking notes. Offer to open a PR. |
| `blocked` at `spec` | Put Frida's unknowns to the user, then re-run with their replies in `answers`. |
| `blocked` at `plan` | Show the remaining `amendments`. If they are small and concrete, offer to fold them into implementation; otherwise ask how to proceed. |
| `blocked` at `implement`, `test`, or `review` | Show the blocker or the remaining failures and wait for direction — a `test` block with no failures usually means a build or environment problem. |
| `revise` at `validate` | Show Sylvie's `gaps` and ask whether to re-enter at planning (edit `feature`/`answers`) or implementation. |

## Resume

A run that was interrupted, or re-run with unchanged earlier inputs, resumes through the Workflow tool's `resumeFromRunId`: completed agent calls return their cached results and only the changed step onward runs again. Keep the `runId` from the launch result.
