# Task: frontmatter
Status: pending
Deps: 04

## Goal
Use current skill and agent frontmatter to restrict tools, set effort, and keep manual-only skills out of the always-loaded description list.

## Steps
1. Agents `code-reviewer`, `plan-critic`, `scope-validator`, `feature-analyst`, `code-analyst`: add `disallowedTools: Edit, Write, NotebookEdit`. `test-runner`: `disallowedTools: Edit, Write, NotebookEdit`. `implementer`: unchanged tools.
2. Add `effort:` — high for plan-critic, code-reviewer, scope-validator, code-analyst, feature-analyst, implementer; low for test-runner. Replace `model: sonnet`/`haiku` with `model: inherit` except test-runner (`haiku`).
3. Move `.claude/agents/_contract.md` content inline into each agent's Output Contract section (each already restates its contract; delete the file and the "read _contract.md" instructions in implement-feature and CLAUDE.md).
4. Skills `update`, `hooks-setup`, `preflight`, `calibrate`: add `disable-model-invocation: true`. Leave `migrate` model-invocable (session-start notice triggers it).
5. `create-pr`: add `allowed-tools: Bash(git *), Bash(gh pr view *)` (gh pr create stays behind the user's ask rule).
6. Move `.claude/templates/knowledge-skill/SKILL.md` to `.claude/skills/plan-feature/knowledge-skill-template.md`; reference it from plan-feature via `${CLAUDE_SKILL_DIR}`; update CLAUDE.md Skill Authoring pointer. Keep `templates/mallet-gitignore` next to the skill that offers it (grep for its referrer).
7. Verify with `claude agents` / skill listing after task 09 load test.
