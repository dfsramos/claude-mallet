# Task: settings-fragment
Status: pending
Deps: —

## Goal
Convert `.claude/settings.json` into a `$HOME`-pathed merge fragment and define the idempotent jq merge routine that installs it into `~/.claude/settings.json`.

## Context
`~/.claude/settings.json` holds the user's `model`, `effortLevel`, `enabledPlugins`, and `Stop`/`Notification` notify hooks. The current install (`install.md:46`) and update (`update/SKILL.md:63`) both `rm -rf .claude/settings.json` before copying. Applied at user level that destroys personal config, so the payload must merge rather than replace.

## Steps

1. `git mv .claude/settings.json .claude/settings.fragment.json`

2. In `.claude/settings.fragment.json`, replace `$CLAUDE_PROJECT_DIR` with `$HOME` in all five command strings (lines 4, 13, 24, 35, 46):
   - `statusLine.command` → `bash "$HOME/.claude/statusline.sh"`
   - `SessionStart` → `bash "$HOME/.claude/hooks/session-start.sh"`
   - `UserPromptSubmit` → `bash "$HOME/.claude/hooks/user-prompt-submit.sh"`
   - `PreCompact` → `bash "$HOME/.claude/hooks/pre-compact.sh"`
   - `PreToolUse` (matcher `Write`) → `bash "$HOME/.claude/hooks/write-guard.sh"`

3. Create `.claude/merge-settings.sh` implementing the merge. It takes the fragment path as `$1` and rewrites `~/.claude/settings.json` in place:

```bash
#!/bin/bash
# Merge the Mallet settings fragment into ~/.claude/settings.json.
# Only Mallet-owned keys are touched; all other user settings survive.
set -euo pipefail

FRAGMENT="$1"
TARGET="$HOME/.claude/settings.json"

# Base hook scripts Mallet owns at user level. Deliberately excludes the three
# opt-in hooks (typecheck, push-confirm, explore-redirect) — those register per
# repo, and stripping them here would silently drop a user's manual global
# registration without the fragment re-adding it.
OWNED='statusline\.sh|session-start\.sh|user-prompt-submit\.sh|pre-compact\.sh|write-guard\.sh'

[ -f "$FRAGMENT" ] || { echo "fragment not found: $FRAGMENT" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

mkdir -p "$HOME/.claude"
[ -f "$TARGET" ] || echo '{}' > "$TARGET"

# Fail closed on a corrupt target rather than overwriting it.
jq -e . "$TARGET" >/dev/null 2>&1 || { echo "$TARGET is not valid JSON — aborting" >&2; exit 1; }

cp "$TARGET" "${TARGET}.bak-$(date +%Y%m%d%H%M%S)"

jq -n --slurpfile cur "$TARGET" --slurpfile frag "$FRAGMENT" --arg owned "$OWNED" '
  ($cur[0]  // {}) as $c |
  ($frag[0] // {}) as $f |
  # 1. Drop any previously-installed Mallet hook entries, then discard event
  #    groups left with no hooks. Non-Mallet entries (Stop, Notification) survive.
  (($c.hooks // {}) | with_entries(
     .value |= ( map(.hooks |= map(select((.command // "") | test($owned) | not)))
                 | map(select((.hooks // []) | length > 0)) )
   ) | with_entries(select((.value | length) > 0))) as $kept |
  # 2. Append the fragment’s entries per event.
  ($f.hooks // {} | to_entries) as $add |
  $c
  + { hooks: (reduce $add[] as $e ($kept; .[$e.key] = ((.[$e.key] // []) + $e.value))) }
  # 3. Mallet owns statusLine.
  + (if $f.statusLine then { statusLine: $f.statusLine } else {} end)
' > "${TARGET}.tmp"

mv "${TARGET}.tmp" "$TARGET"
echo "merged $FRAGMENT into $TARGET"
```

4. `chmod +x .claude/merge-settings.sh`

## TDD Checklist
- [ ] Write failing test: copy the real `~/.claude/settings.json` to `<scratchpad>/fixture.json`, point the script at it, assert `model`, `effortLevel`, `enabledPlugins`, and the `Stop`/`Notification` hooks all survive and the 4 base hooks plus `statusLine` are present
- [ ] Confirm test fails (red) before `merge-settings.sh` exists
- [ ] Implement steps 1–4
- [ ] Confirm test passes (green)
- [ ] Idempotency: run the merge twice, assert `jq -S . ` output is byte-identical and no hook entry is duplicated
- [ ] Corrupt-input guard: run against a fixture containing `{invalid`, assert non-zero exit and the fixture is unmodified
- [ ] Empty-target case: run against a missing file, assert a valid settings.json is created

## Notes
The strip regex is intentionally narrower than the full hook set — see the comment in the script. Widening it to include the opt-in hooks would make the merge lossy.
