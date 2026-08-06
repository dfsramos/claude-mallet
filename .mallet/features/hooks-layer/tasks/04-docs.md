# Task: docs
Status: pending
Deps: 03

## Goal
Update `docs/hooks.md` and `docs/skills.md` to document the two new hooks and the hooks-setup skill.

## docs/hooks.md additions
Add sections for:
- **Typecheck Hook** — file, trigger (PostToolUse, matcher Edit), what it does, why it exists, supported stacks
- **Push-Confirm Hook** — file, trigger (PreToolUse, matcher Bash), what it does, why advisory not blocking, why it exists

Add a note to "Adding New Hooks" (or nearby) explaining the two tiers:
- **Default hooks** (active after install): session-start, user-prompt-submit, write-guard
- **Optional hooks** (activated via /hooks-setup): typecheck, push-confirm

## docs/skills.md additions
Add a **Hooks Setup** section documenting the hooks-setup skill:
- Trigger, what it detects, what it installs, idempotency behaviour
