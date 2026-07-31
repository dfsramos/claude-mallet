#!/bin/bash
# Merge the Claude Mallet settings fragment into ~/.claude/settings.json.
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

# Base hook scripts Mallet owns at user level. Deliberately excludes the three
# opt-in hooks (typecheck, push-confirm, explore-redirect): those register per
# repo, and stripping them here would silently drop a user's manual global
# registration that the fragment would not re-add.
OWNED='statusline\.sh|session-start\.sh|user-prompt-submit\.sh|pre-compact\.sh|write-guard\.sh'

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

jq -n --slurpfile cur "$TARGET" --slurpfile frag "$FRAGMENT" --arg owned "$OWNED" '
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

  # 3. Mallet owns statusLine.
  + (if $f.statusLine then { statusLine: $f.statusLine } else {} end)
' > "${TARGET}.tmp"

mv "${TARGET}.tmp" "$TARGET"
echo "merged $(basename "$FRAGMENT") into $TARGET"
