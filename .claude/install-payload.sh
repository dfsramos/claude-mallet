#!/bin/bash
# Install the Claude Mallet payload into ~/.claude/.
#
# Usage: install-payload.sh --from <extracted-payload-root> --repo <owner/repo> --sha <sha>
#
# Shared by install.md and the update skill so the replacement rules live in one
# tested place rather than in two prose documents.
#
# The central rule: entries are replaced INDIVIDUALLY, never by removing the
# containing directory. ~/.claude/skills/ holds user-authored skills alongside
# Mallet's; `rm -rf ~/.claude/skills` would destroy them.
#
# Because per-entry replacement leaves no record of what Mallet owns,
# framework.json carries a manifest. On the next run, anything the previous
# manifest claimed but the new payload no longer ships is removed; anything the
# manifest never claimed is left alone and reported as preserved.
#
# Does NOT touch ~/.claude/settings.json — that is merge-settings.sh's job.
set -uo pipefail

FROM=""; REPO_NAME=""; SHA=""
while [ $# -gt 0 ]; do
  case "$1" in
    --from) FROM="${2:-}"; shift 2 ;;
    --repo) REPO_NAME="${2:-}"; shift 2 ;;
    --sha)  SHA="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done

[ -n "$FROM" ] && [ -d "$FROM/.claude" ] && [ -f "$FROM/CLAUDE.md" ] || {
  echo "install-payload.sh: --from must point at an extracted payload containing .claude/ and CLAUDE.md" >&2
  exit 1
}
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

DEST="$HOME/.claude"
FJ="$DEST/framework.json"
KINDS="skills agents templates hooks"

mkdir -p "$DEST"
for k in $KINDS; do mkdir -p "$DEST/$k"; done

# ── Previous manifest, for orphan reconciliation ─────────────────────────────
prev_manifest() { # $1=kind
  [ -f "$FJ" ] || return 0
  jq -r --arg k "$1" '(.manifest[$k] // [])[]' "$FJ" 2>/dev/null
}

# ── Install each payload entry individually ──────────────────────────────────
for k in $KINDS; do
  [ -d "$FROM/.claude/$k" ] || continue
  for entry in "$FROM/.claude/$k"/*; do
    [ -e "$entry" ] || continue
    name=$(basename "$entry")
    rm -rf "$DEST/$k/$name"
    cp -r "$entry" "$DEST/$k/$name"
  done
done

[ -f "$FROM/.claude/statusline.sh" ] && cp "$FROM/.claude/statusline.sh" "$DEST/statusline.sh"
cp "$FROM/CLAUDE.md" "$DEST/CLAUDE.md"

# ── Reconcile orphans from the previous manifest ─────────────────────────────
REMOVED=""
for k in $KINDS; do
  while read -r old; do
    [ -n "$old" ] || continue
    [ -e "$FROM/.claude/$k/$old" ] && continue   # still shipped
    if [ -e "$DEST/$k/$old" ]; then
      rm -rf "$DEST/$k/$old"
      REMOVED="$REMOVED $k/$old"
    fi
  done < <(prev_manifest "$k")
done

# ── Report anything present but unclaimed: user-authored, left alone ─────────
PRESERVED=""
for k in $KINDS; do
  for entry in "$DEST/$k"/*; do
    [ -e "$entry" ] || continue
    name=$(basename "$entry")
    [ -e "$FROM/.claude/$k/$name" ] && continue  # ours
    PRESERVED="$PRESERVED $k/$name"
  done
done

# ── Permissions ─────────────────────────────────────────────────────────────
chmod +x "$DEST/hooks/"*.sh 2>/dev/null
chmod +x "$DEST/statusline.sh" 2>/dev/null

# ── Write framework.json with a fresh manifest ──────────────────────────────
manifest_json() { # $1=kind
  if [ -d "$FROM/.claude/$1" ]; then
    find "$FROM/.claude/$1" -mindepth 1 -maxdepth 1 -printf '%f\n' 2>/dev/null | sort | jq -R . | jq -s .
  else
    echo '[]'
  fi
}

jq -n \
  --arg repo "$REPO_NAME" \
  --arg version "$SHA" \
  --arg installed_at "$(date +%Y-%m-%d)" \
  --argjson skills    "$(manifest_json skills)" \
  --argjson agents    "$(manifest_json agents)" \
  --argjson templates "$(manifest_json templates)" \
  --argjson hooks     "$(manifest_json hooks)" \
  '{repo:$repo, version:$version, installed_at:$installed_at,
    manifest:{skills:$skills, agents:$agents, templates:$templates, hooks:$hooks}}' \
  > "${FJ}.tmp" && mv "${FJ}.tmp" "$FJ"

# ── Report ──────────────────────────────────────────────────────────────────
echo "installed payload into $DEST"
[ -n "$REMOVED" ]   && echo "removed (dropped from this release):$REMOVED"
[ -n "$PRESERVED" ] && echo "preserved (not Mallet's, left untouched):$PRESERVED"
exit 0
