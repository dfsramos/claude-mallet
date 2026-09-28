#!/bin/bash
# Merge the Claude Mallet settings fragment into ~/.claude/settings.json.
#
# Since the move to the plugin the shipped fragment is empty, so a run removes
# the hook registrations and statusLine the user-level install added; the
# plugin registers its own hooks. Installed update skills still call this path.
#
# Only Mallet-owned keys are touched. The user's own settings — model,
# effortLevel, enabledPlugins, and any hooks Mallet does not own — survive
# untouched. Never overwrite this file wholesale: at user level it holds
# personal configuration, not framework payload.
#
# Usage: merge-settings.sh <path-to-settings.fragment.json>
set -euo pipefail

FRAGMENT="${1:-}"
TARGET="$HOME/.claude/settings.json"

# Hook scripts the user-level install placed in ~/.claude/hooks/. Anchored to
# that directory so a user's own script with the same file name elsewhere is
# never matched. typecheck is included: the transition removes its script, so
# any global registration of it would fail on every edit.
OWNED='\.claude/hooks/(session-start|user-prompt-submit|pre-compact|post-compact|write-guard|typecheck|push-confirm|explore-redirect)\.sh'

[ -n "$FRAGMENT" ] || { echo "usage: merge-settings.sh <fragment.json>" >&2; exit 1; }
[ -f "$FRAGMENT" ] || { echo "fragment not found: $FRAGMENT" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

jq -e . "$FRAGMENT" >/dev/null 2>&1 || { echo "fragment is not valid JSON: $FRAGMENT" >&2; exit 1; }

mkdir -p "$HOME/.claude"

# Treat a missing or empty target as an empty object.
if [ ! -s "$TARGET" ]; then
  echo '{}' > "$TARGET"
fi

# Fail closed on a corrupt target rather than clobbering something we cannot read.
jq -e . "$TARGET" >/dev/null 2>&1 || { echo "$TARGET is not valid JSON — aborting" >&2; exit 1; }

cp "$TARGET" "${TARGET}.bak-$(date +%Y%m%d%H%M%S)"

SL_EXISTS=false; [ -f "$HOME/.claude/statusline.sh" ] && SL_EXISTS=true

jq -n --slurpfile cur "$TARGET" --slurpfile frag "$FRAGMENT" --arg owned "$OWNED" --argjson slExists "$SL_EXISTS" '
  ($cur[0]  // {}) as $c |
  ($frag[0] // {}) as $f |

  # 1. Drop previously-installed Mallet hook entries, then discard event groups
  #    left with nothing. Non-Mallet entries (Stop, Notification, ...) survive.
  (
    ($c.hooks // {})
    | with_entries(
        .value |= (
          map(.hooks = ((.hooks // []) | map(select((.command // "") | test($owned) | not))))
          | map(select((.hooks | length) > 0))
        )
      )
    | with_entries(select((.value | length) > 0))
  ) as $kept |

  # 2. Append the fragment entries per event.
  ($f.hooks // {} | to_entries) as $add |

  $c
  + { hooks: (reduce $add[] as $e ($kept; .[$e.key] = ((.[$e.key] // []) + $e.value))) }

  # 3. Mallet owns statusLine. A statusLine still pointing at the removed
  #    ~/.claude/statusline.sh would render nothing, so it is dropped.
  | if $f.statusLine then .statusLine = $f.statusLine
    elif ((.statusLine.command // "") | test("\\.claude/statusline\\.sh")) and ($slExists | not) then del(.statusLine)
    else . end
' > "${TARGET}.tmp"

mv "${TARGET}.tmp" "$TARGET"
echo "merged $(basename "$FRAGMENT") into $TARGET"
