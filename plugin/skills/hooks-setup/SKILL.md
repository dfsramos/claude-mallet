---
name: hooks-setup
description: Invoke when the user runs /hooks-setup, asks to "set up hooks", "enable typecheck", "disable typecheck", "enable the command guard", or wants to turn optional Mallet hooks on or off in the current project.
disable-model-invocation: true
---
# Hooks Setup

Turns optional Mallet hooks on or off for the current project. The plugin registers every hook globally; an optional hook acts only in projects that carry its opt-in marker, so nothing here edits settings files.

| Hook | Event | Marker |
|---|---|---|
| typecheck | Records edits (PostToolUse), checks them once when the turn ends (Stop) | `.mallet/typecheck.enabled` |
| command-guard | PreToolUse on Bash | `.mallet/command-guard.enabled` |

---

## 1. Report current state

For each optional hook, check whether its marker exists at the project root and report on/off.

Also check `.claude/settings.json` and `.claude/settings.local.json` for a pre-plugin registration — any hook command containing `.claude/hooks/typecheck.sh`. That script no longer exists after the move to the plugin, so the entry fails on every edit. Offer to remove it (Edit, after showing the exact entry), and never touch other entries.

## 2. Detect the stack

| Stack | Indicator |
|---|---|
| TypeScript | `tsconfig.json` exists (the hook runs `npx tsc --noEmit` only when it does) |
| PHP | `vendor/bin/phpstan` exists |

If neither is present, say typecheck would do nothing here and skip it unless the user still wants it. command-guard applies to any stack.

## 3. Apply the user's choice

**typecheck** type-checks the files edited in a turn once, when Claude finishes the turn, and hands errors in those files back so Claude fixes them before stopping. Errors elsewhere in the project are left out.

- Enable: `mkdir -p .mallet && touch .mallet/typecheck.enabled`
- Disable: `rm .mallet/typecheck.enabled` (only the marker)

**command-guard** denies bypassing git hooks (`--no-verify`, `commit -n`, `core.hooksPath`) and force-pushing the default branch, and asks before other destructive commands: other force-pushes, `git reset --hard`, `git clean -f`, discarding all changes, `git branch -D`, dropping stashes, `rm -rf` outside build directories, destructive SQL passed to a database client, `kubectl delete`, and `terraform destroy`. Recommend it when the user allows broad Bash permissions or uses auto mode, where little else stands between Claude and these commands.

- Enable: `mkdir -p .mallet && touch .mallet/command-guard.enabled`
- Disable: `rm .mallet/command-guard.enabled` (only the marker)

To confirm before `git push`, use a permission rule instead of a hook: add `"Bash(git push *)"` to `permissions.ask` in settings.

## 4. Confirm

Report the new state per hook, and any stale registration removed or left in place.
