#!/bin/bash
# Migrate ONE repo off a legacy per-project Claude Mallet install.
#
# Usage: migrate-repo.sh <repo> [--payload <historical-CLAUDE.md>] [--yes]
#
# Without --yes, prints the plan and changes nothing.
# --payload supplies the historical Mallet CLAUDE.md to diff against; when
# omitted, the caller is expected to have fetched it (the CLAUDE.md strip is
# skipped rather than guessed at).
#
# Guarantees:
#   - Never deletes a git-tracked file, and never touches a tracked CLAUDE.md.
#   - Never edits .gitignore or .git/info/exclude — the VCS policy for .mallet/
#     is the user's choice, not Mallet's.
#   - Never touches .claude/settings.local.json.
#   - Aborts a repo before any deletion if its backup cannot be written.
set -uo pipefail

REPO=""; PAYLOAD=""; APPLY=0
while [ $# -gt 0 ]; do
  case "$1" in
    --payload) PAYLOAD="${2:-}"; shift 2 ;;
    --yes)     APPLY=1; shift ;;
    -*)        shift ;;
    *)         [ -z "$REPO" ] && REPO="$1"; shift ;;
  esac
done

[ -n "$REPO" ] && [ -d "$REPO" ] || { echo "usage: migrate-repo.sh <repo> [--payload f] [--yes]" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
REPO=$(cd "$REPO" && pwd)
NAME=$(basename "$REPO")

say() { echo "[$NAME] $*"; }
tracked() { git -C "$REPO" ls-files --error-unmatch "$1" >/dev/null 2>&1; }

# ── Is there anything to do? ────────────────────────────────────────────────
# Refuse the install dir and the framework source repo outright — migrating
# either would delete a working install or the payload source.
if [ "$REPO" = "$(cd "$HOME" 2>/dev/null && pwd -P)" ]; then
  say "REFUSING: this is the Mallet install directory, not a legacy per-project install"
  exit 1
fi
if [ -f "$REPO/.claude/settings.fragment.json" ] || [ -f "$REPO/.claude/install-payload.sh" ]; then
  say "REFUSING: this is the Mallet source repo — its .claude/ is the payload, not a legacy install"
  exit 1
fi

LEGACY=0
[ -f "$REPO/.claude/framework.json" ] && LEGACY=1
[ -f "$REPO/.claude/skills/update/SKILL.md" ] && [ -f "$REPO/.claude/agents/_contract.md" ] && LEGACY=1
if [ "$LEGACY" -eq 0 ]; then
  say "no legacy payload — already migrated, nothing to do"
  exit 0
fi

if [ "$APPLY" -eq 0 ]; then
  say "would migrate: move .claude/project|features|pipeline-state -> .mallet/,"
  say "  remove untracked framework payload, prune .claude/settings.json,"
  say "  strip untracked CLAUDE.md. Re-run with --yes to apply."
  exit 0
fi

# ── Backup first; no backup, no deletion ────────────────────────────────────
mkdir -p "$HOME/.claude"
BACKUP="$HOME/.claude/mallet-migration-backup-$(date +%Y%m%d%H%M%S)-${NAME}.tar.gz"
if ! tar -czf "$BACKUP" -C "$REPO" .claude CLAUDE.md 2>/dev/null; then
  # CLAUDE.md may legitimately be absent; retry with just .claude/
  if ! tar -czf "$BACKUP" -C "$REPO" .claude 2>/dev/null; then
    say "ABORT: could not write backup $BACKUP — no changes made"
    exit 1
  fi
fi
say "backup: $BACKUP"

# ── 1. Relocate state to .mallet/ ───────────────────────────────────────────
mkdir -p "$REPO/.mallet"
move() { # $1=src abs, $2=dest abs
  [ -e "$1" ] || return 0
  mkdir -p "$(dirname "$2")"
  if tracked "${1#$REPO/}"; then
    git -C "$REPO" mv -k "${1#$REPO/}" "${2#$REPO/}" 2>/dev/null || mv "$1" "$2"
  else
    mv "$1" "$2"
  fi
}

P="$REPO/.claude/project"
if [ -d "$P" ]; then
  # The one rename: project/CLAUDE.md is directive-loaded, not harness-loaded,
  # so it becomes conventions.md and stops colliding with a real CLAUDE.md.
  move "$P/CLAUDE.md" "$REPO/.mallet/conventions.md"
  # Everything else keeps its name, including files this version has never
  # heard of — they are reported, never discarded.
  for entry in "$P"/* "$P"/.[!.]*; do
    [ -e "$entry" ] || continue
    base=$(basename "$entry")
    say "moved .claude/project/$base -> .mallet/$base"
    move "$entry" "$REPO/.mallet/$base"
  done
  rmdir "$P" 2>/dev/null || say "note: .claude/project/ not empty, left in place"
fi

move "$REPO/.claude/features"       "$REPO/.mallet/features"
move "$REPO/.claude/pipeline-state" "$REPO/.mallet/pipeline-state"

# No .gitignore is written here — see the header. The user chooses.

# ── 2. Remove the framework payload, untracked only ─────────────────────────
for p in .claude/agents .claude/hooks .claude/skills .claude/templates \
         .claude/statusline.sh .claude/framework.json .claude/merge-settings.sh \
         .claude/settings.fragment.json; do
  [ -e "$REPO/$p" ] || continue
  if tracked "$p"; then
    say "SKIPPED (tracked): $p — run 'git rm -r --cached $p' yourself if you want it gone"
  else
    rm -rf "$REPO/$p"
    say "removed $p"
  fi
done

# ── 3. Prune .claude/settings.json ──────────────────────────────────────────
S="$REPO/.claude/settings.json"
if [ -f "$S" ] && jq -e . "$S" >/dev/null 2>&1; then
  if tracked ".claude/settings.json"; then
    say "SKIPPED (tracked): .claude/settings.json"
  else
    # Base hooks are global now. The three opt-in hooks are a per-repo CHOICE
    # and must survive — only their script path is repointed to $HOME.
    jq '
      def base: "statusline\\.sh|session-start\\.sh|user-prompt-submit\\.sh|pre-compact\\.sh|write-guard\\.sh";
      def optin: "typecheck\\.sh|push-confirm\\.sh|explore-redirect\\.sh";
      (if (.statusLine.command? // "") | test("\\.claude/statusline\\.sh")
         then del(.statusLine) else . end)
      | (if .hooks then
          .hooks |= (
            with_entries(
              .value |= (
                map(.hooks = ((.hooks // [])
                      | map(select((.command // "") | test(base) | not))
                      | map(if (.command // "") | test(optin)
                            then .command |= sub("\\$\\{?CLAUDE_PROJECT_DIR\\}?/\\.claude/hooks/"; "$HOME/.claude/hooks/")
                            else . end)))
                | map(select((.hooks | length) > 0))
              )
            )
            | with_entries(select((.value | length) > 0))
          )
        else . end)
      | (if (.hooks? | type == "object") and ((.hooks | length) == 0) then del(.hooks) else . end)
    ' "$S" > "${S}.tmp" 2>/dev/null && mv "${S}.tmp" "$S" || rm -f "${S}.tmp"

    if [ "$(jq -S -c . "$S" 2>/dev/null)" = "{}" ]; then
      rm -f "$S"
      say "removed .claude/settings.json (nothing left after pruning)"
    else
      say "pruned .claude/settings.json"
    fi
  fi
fi

# ── 4. Strip CLAUDE.md — untracked only ─────────────────────────────────────
MD="$REPO/CLAUDE.md"
if [ -f "$MD" ]; then
  if tracked "CLAUDE.md"; then
    say "SKIPPED (tracked): CLAUDE.md — left exactly as committed"
  elif [ -z "$PAYLOAD" ] || [ ! -f "$PAYLOAD" ]; then
    say "SKIPPED: CLAUDE.md — no historical payload supplied to diff against"
  else
    DELTA=$(diff "$PAYLOAD" "$MD" | sed -n 's/^> \{0,1\}//p')
    # Trim leading blank lines and a leading horizontal rule left behind by the
    # payload/project boundary.
    DELTA=$(printf '%s\n' "$DELTA" | sed -e '/./,$!d' -e '1{/^---$/d}' -e '/./,$!d')
    if [ -z "$(printf '%s' "$DELTA" | tr -d '[:space:]')" ]; then
      rm -f "$MD"
      say "removed CLAUDE.md (pure Mallet payload, nothing project-authored)"
    else
      printf '%s\n' "$DELTA" > "$MD"
      say "stripped CLAUDE.md to its project-authored content"
    fi
  fi
fi

say "done"
