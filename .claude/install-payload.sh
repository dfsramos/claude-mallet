#!/bin/bash
# Transition a user-level Mallet install (~/.claude/) to the mallet plugin.
#
# Usage: install-payload.sh --from <extracted-archive-root> --repo <owner/repo> --sha <sha>
#
# Mallet now ships as a Claude Code plugin. This script keeps the path and flags
# of the old installer because installed `update` skills run exactly
#   bash "$WORK/.claude/install-payload.sh" --from "$WORK" --repo ... --sha ...
# so an existing install transitions on its next update with no manual step.
#
# What it does, in order:
#   1. Backs up everything it may touch.
#   2. Removes only what framework.json's manifest says Mallet installed.
#      User-authored skills, agents, and hooks are never touched.
#   3. Replaces skills/migrate with a stub holding detect.sh, because the
#      update skill runs ~/.claude/skills/migrate/detect.sh right after this.
#   4. Removes ~/.claude/statusline.sh only if it is still Mallet's.
#   5. Removes ~/.claude/CLAUDE.md only if it is byte-identical (ignoring CR)
#      to the CLAUDE.md of the installed version; otherwise keeps it and says so.
#   6. Marks framework.json as transitioned, which makes a re-run a no-op.
#
# Settings are handled by merge-settings.sh, which the update skill runs next.
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

command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }

DEST="$HOME/.claude"
FJ="$DEST/framework.json"
MARKETPLACE="${REPO_NAME:-dfsramos/claude-mallet}"

next_steps() {
  echo ""
  echo "Mallet is now a plugin. In Claude Code, run:"
  echo "  /plugin marketplace add ${MARKETPLACE}"
  echo "  /plugin install mallet@claude-mallet"
  echo "  /mallet:setup        (statusline, auto-update, legacy memory files)"
}

if [ ! -f "$FJ" ]; then
  echo "no user-level Mallet install found at $DEST — nothing to transition"
  next_steps; exit 0
fi
if ! jq -e . "$FJ" >/dev/null 2>&1; then
  echo "ABORT: $FJ is not valid JSON — no changes made" >&2
  exit 1
fi
if [ "$(jq -r '.transitioned // empty' "$FJ")" = "plugin" ]; then
  echo "already transitioned to the plugin — no changes made"
  next_steps; exit 0
fi

OLD_SHA=$(jq -r '.version // empty' "$FJ")
OLD_REPO=$(jq -r '.repo // empty' "$FJ")

# ── 1. Backup ───────────────────────────────────────────────────────────────
BACKUP="$DEST/mallet-pretransition-backup-$(date +%Y%m%d%H%M%S).tar.gz"
MEMBERS=""
for m in skills agents templates hooks statusline.sh CLAUDE.md framework.json settings.json; do
  [ -e "$DEST/$m" ] && MEMBERS="$MEMBERS $m"
done
# shellcheck disable=SC2086
if ! tar -czf "$BACKUP" -C "$DEST" $MEMBERS; then
  echo "ABORT: could not write backup $BACKUP — no changes made" >&2
  exit 1
fi
echo "backup: $BACKUP"

# ── 2–3. Remove manifest-claimed entries; stub migrate ──────────────────────
REMOVED=""
for k in skills agents templates hooks; do
  while read -r name; do
    # A manifest entry is a bare directory or file name. Anything else is not
    # something this installer wrote, so it is never acted on.
    case "$name" in ''|.|..|*/*) continue ;; esac
    [ -e "$DEST/$k/$name" ] || continue
    rm -rf "${DEST:?}/$k/$name"
    REMOVED="$REMOVED $k/$name"
  done < <(jq -r --arg k "$k" '(.manifest[$k] // [])[]' "$FJ")
done

mkdir -p "$DEST/skills/migrate"
cat > "$DEST/skills/migrate/detect.sh" <<'STUB'
#!/bin/bash
# Left by the Mallet plugin transition so that an in-progress `update` run
# finishes cleanly. /mallet:setup offers to remove this directory.
echo "Mallet is now a plugin; the plugin's migrate skill handles legacy per-project installs."
exit 0
STUB
chmod +x "$DEST/skills/migrate/detect.sh"
echo "Remove this directory once the mallet plugin is installed." > "$DEST/skills/migrate/MALLET-TRANSITION-STUB"

# ── 4. Statusline ───────────────────────────────────────────────────────────
KEPT=""
if [ -f "$DEST/statusline.sh" ]; then
  if grep -q 'Claude Mallet' "$DEST/statusline.sh"; then
    rm -f "$DEST/statusline.sh"; REMOVED="$REMOVED statusline.sh"
  else
    KEPT="$KEPT statusline.sh(not Mallet's)"
  fi
fi

# ── 5. CLAUDE.md ────────────────────────────────────────────────────────────
if [ -f "$DEST/CLAUDE.md" ]; then
  VERDICT="could not fetch the installed version's CLAUDE.md to compare"
  if [ -n "$OLD_SHA" ] && [ -n "$OLD_REPO" ] && command -v curl >/dev/null; then
    ORIG=$(mktemp)
    if curl -sfL --max-time 10 "https://raw.githubusercontent.com/${OLD_REPO}/${OLD_SHA}/CLAUDE.md" -o "$ORIG" && [ -s "$ORIG" ]; then
      if diff -q --strip-trailing-cr "$ORIG" "$DEST/CLAUDE.md" >/dev/null; then
        VERDICT=""
      else
        VERDICT="it differs from Mallet ${OLD_SHA:0:7}'s copy, so it may hold your own rules"
      fi
    fi
    rm -f "$ORIG"
  fi
  if [ -z "$VERDICT" ]; then
    rm -f "$DEST/CLAUDE.md"; REMOVED="$REMOVED CLAUDE.md"
  else
    KEPT="$KEPT CLAUDE.md"
    echo "kept ~/.claude/CLAUDE.md: $VERDICT."
    echo "  The plugin now injects the persona itself; remove Mallet's sections from this file"
    echo "  (the backup has the original) or the persona will load twice."
  fi
fi

# ── 6. Mark transitioned ────────────────────────────────────────────────────
jq --arg at "$(date +%Y-%m-%d)" --arg from "$OLD_SHA" \
  '{repo, transitioned: "plugin", at: $at, from_version: $from}' "$FJ" > "$FJ.tmp" && mv "$FJ.tmp" "$FJ"

# ── Report ──────────────────────────────────────────────────────────────────
PRESERVED=""
for k in skills agents templates hooks; do
  for entry in "$DEST/$k"/*; do
    [ -e "$entry" ] || continue
    [ "$k/$(basename "$entry")" = "skills/migrate" ] && continue
    PRESERVED="$PRESERVED $k/$(basename "$entry")"
  done
done
echo "transitioned $DEST to the mallet plugin"
[ -n "$REMOVED" ]   && echo "removed:$REMOVED"
[ -n "$KEPT" ]      && echo "kept:$KEPT"
[ -n "$PRESERVED" ] && echo "preserved (not Mallet's, left untouched):$PRESERVED"
next_steps
exit 0
