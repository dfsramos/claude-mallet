# Task: pipeline-workflow
Status: pending
Deps: 07

## Goal
Replace the implement-feature prose orchestrator and its pipeline-state file with a saved Workflow that uses the Mallet agents.

## Steps
1. Load the `workflow-authoring` skill before writing.
2. Create `workflows/implement-feature.js` (plugin root location; task 09 finalises paths): `args` = {feature, testCommand, critique, scopeValidation, review}; phases Spec → Plan → Critique → Implement → Test → Validate → Review, agentType `mallet:<agent>`, iteration caps from the current skill's budget table, schemas mirroring the agent Output Contracts (status/summary/handoff).
3. Replace the Clifford step with the built-in `/code-review` recipe only if the Workflow API can invoke it; otherwise keep `mallet:code-reviewer`. Record which in state.md.
4. Rewrite `.claude/skills/implement-feature/SKILL.md` as a thin launcher: collect feature, test command, and the three yes/no options, then run the workflow; resume via `resumeFromRunId` replaces `.mallet/pipeline-state/`.
5. Remove `.mallet/pipeline-state/` references (`grep -rn pipeline-state`), keeping the `.gitignore` line until the transition release ships.
