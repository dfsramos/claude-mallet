#!/bin/bash
# Discover legacy per-project Claude Mallet installs.
#
# Usage:
#   detect.sh                      # candidates from session transcripts
#   detect.sh --roots <dir> [...]  # candidates from a filesystem scan
#
# Output: one TSV row per legacy install —
#   <repo>\t<sha>\t<recorded-repo>\t<claude-md-state>
# where claude-md-state is tracked | untracked | absent.
#
# Detection is by FILE PRESENCE, never schema: installs in the wild include a
# framework.json of {"commit": ..., "installed_at": ...} with no `repo` or
# `version` key, which any schema check would reject.
set -uo pipefail

ROOTS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --roots)
      shift
      while [ $# -gt 0 ] && [ "${1#--}" = "$1" ]; do ROOTS+=("$1"); shift; done
      ;;
    *) shift ;;
  esac
done

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

# ── Candidate paths ─────────────────────────────────────────────────────────
# Transcripts record an exact `cwd`. The ~/.claude/projects/ directory NAMES are
# ambiguous — /mnt/c/Repositories/Cludo/cludo-lambdas encodes to
# -mnt-c-Repositories-Cludo-cludo-lambdas, where `-` is both a path separator
# and a literal character — so the names are never parsed.
candidates() {
  if [ "${#ROOTS[@]}" -gt 0 ]; then
    for r in "${ROOTS[@]}"; do
      find "$r" -maxdepth 4 -type d -name .claude -not -path '*/node_modules/*' 2>/dev/null \
        | while read -r d; do dirname "$d"; done
    done
  else
    find "$HOME/.claude/projects" -maxdepth 2 -name '*.jsonl' -print0 2>/dev/null \
      | xargs -0 -r jq -r 'select(.cwd) | .cwd' 2>/dev/null
  fi
}

# Resolve to repository roots and deduplicate — transcripts record
# subdirectories and worktrees as separate cwd values.
#
# On Windows, transcripts record `cwd` with backslashes (e.g.
# `C:\Projects\repo`), which POSIX `-d`/`-f` tests under git-bash silently
# reject rather than error on — the whole scan looks empty instead of
# failing loud. The native Windows `jq.exe` also emits CRLF line endings,
# so a trailing \r survives `read -r` and breaks the same tests even after
# the backslash swap. Strip the \r, then normalize to forward slashes.
roots_of() {
  while read -r p; do
    p="${p%$'\r'}"
    p=${p//'\'/'/'}
    [ -n "$p" ] && [ -d "$p" ] || continue
    git -C "$p" rev-parse --show-toplevel 2>/dev/null
  done | sort -u
}

# ── Classify ────────────────────────────────────────────────────────────────
HOME_REAL=$(cd "$HOME" 2>/dev/null && pwd -P)

for repo in $(candidates | sort -u | roots_of); do
  fj="$repo/.claude/framework.json"

  # Never treat the install itself as a legacy install.
  [ "$(cd "$repo" 2>/dev/null && pwd -P)" = "$HOME_REAL" ] && continue
  # Never treat the framework source repo as one either — its .claude/ IS the
  # payload. Only the source carries these two files.
  [ -f "$repo/.claude/settings.fragment.json" ] && continue
  [ -f "$repo/.claude/install-payload.sh" ] && continue

  is_legacy=0
  [ -f "$fj" ] && is_legacy=1
  [ -f "$repo/.claude/skills/update/SKILL.md" ] && [ -f "$repo/.claude/agents/_contract.md" ] && is_legacy=1
  [ "$is_legacy" -eq 1 ] || continue

  sha="unknown"; recorded="-"
  if [ -f "$fj" ] && jq -e . "$fj" >/dev/null 2>&1; then
    sha=$(jq -r '.version // .commit // "unknown"' "$fj" 2>/dev/null)
    recorded=$(jq -r '.repo // "-"' "$fj" 2>/dev/null)
  fi

  if [ -f "$repo/CLAUDE.md" ]; then
    if git -C "$repo" ls-files --error-unmatch CLAUDE.md >/dev/null 2>&1; then
      md=tracked
    else
      md=untracked
    fi
  else
    md=absent
  fi

  printf '%s\t%s\t%s\t%s\n' "$repo" "$sha" "$recorded" "$md"
done
