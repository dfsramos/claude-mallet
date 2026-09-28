---
name: hooks-setup
description: Invoke when the user runs /hooks-setup, asks to "set up hooks", "enable typecheck", "disable typecheck", or wants to turn optional Mallet hooks on or off in the current project.
disable-model-invocation: true
---
# Hooks Setup

Turns optional Mallet hooks on or off for the current project. The plugin registers every hook globally; an optional hook acts only in projects that carry its opt-in marker, so nothing here edits settings files.

| Hook | Event | Marker |
|---|---|---|
| typecheck | PostToolUse on Edit and Write | `.mallet/typecheck.enabled` |

---

## 1. Report current state

For each optional hook, check whether its marker exists at the project root and report on/off.

Also check `.claude/settings.json` and `.claude/settings.local.json` for a pre-plugin registration — any hook command containing `.claude/hooks/typecheck.sh`. That script no longer exists after the move to the plugin, so the entry fails on every edit. Offer to remove it (Edit, after showing the exact entry), and never touch other entries.

## 2. Detect the stack

| Stack | Indicator |
|---|---|
| TypeScript | `tsconfig.json` exists (the hook runs `npx tsc --noEmit` only when it does) |
| PHP | `vendor/bin/phpstan` exists |

If neither is present, say typecheck would do nothing here and stop unless the user still wants it.

## 3. Apply the user's choice

**typecheck** runs the type-checker after every file edit and puts the first 20 lines of errors into Claude's context.

- Enable: `mkdir -p .mallet && touch .mallet/typecheck.enabled`
- Disable: `rm .mallet/typecheck.enabled` (only the marker)

To confirm before `git push`, use a permission rule instead of a hook: add `"Bash(git push *)"` to `permissions.ask` in settings.

## 4. Confirm

Report the new state per hook, and any stale registration removed or left in place.
