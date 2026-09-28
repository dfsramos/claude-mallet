# Task: verify
Status: pending
Deps: 12

## Goal
Prove the plugin loads, the hooks behave, and existing installs transition safely.

## Steps
1. Run every suite under `tests/`; all green.
2. `claude plugin validate .`.
3. Launch `claude --plugin-dir .` in a scratch repo: confirm persona context present, `mallet:*` skills listed, manual-only skills absent from the model-visible list, write-guard blocks an overwrite with its reason visible, typecheck context visible.
4. Run the transition against a copy of the real `~/.claude/` in a fake HOME; diff before/after.
5. Spawn an independent reviewer subagent over the full diff since `5752e35`; process findings with receiving-code-review.
