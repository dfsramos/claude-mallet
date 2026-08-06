# Feature: hooks-layer
Status: done
Created: 2026-04-30
Branch: —

## Goal
Add two opt-in hook scripts (typecheck, push-confirm) and a `hooks-setup` skill that detects the project stack and registers selected hooks idempotently.

## Context
The framework ships hooks that are active by default (write-guard, session-start, user-prompt-submit). This feature adds a second tier: optional hooks that only make sense for specific projects. `hooks-setup` is the activation mechanism — it detects the stack, presents the available hooks, and appends registrations to `settings.json` without duplicating existing entries.

push-confirm is advisory (exit 0) not blocking (exit 2) because a blocking hook creates an infinite loop: Claude retries after user confirmation, the hook fires again and blocks again.

## Tasks
- [x] 01-typecheck-hook — Write `.claude/hooks/typecheck.sh` [deps: —] [parallel: yes]
- [x] 02-push-confirm-hook — Write `.claude/hooks/push-confirm.sh` [deps: —] [parallel: yes]
- [x] 03-hooks-setup-skill — Write `.claude/skills/hooks-setup/SKILL.md` [deps: 01, 02] [parallel: no]
- [x] 04-docs — Update `docs/hooks.md` and `docs/skills.md` [deps: 03] [parallel: no]
