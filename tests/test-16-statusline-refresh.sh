#!/bin/bash
# Test: session-start keeps a stable statusline copy in CLAUDE_PLUGIN_DATA in
# step with the plugin version, so a statusLine pointing at it auto-updates.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }

export HOME="$SCRATCH/home"; mkdir -p "$HOME/.claude"
export CLAUDE_PROJECT_DIR="$SCRATCH/repo"; mkdir -p "$CLAUDE_PROJECT_DIR"
# A copy of the plugin, so the test can simulate an update without touching the repo.
cp -r "$REPO/plugin" "$SCRATCH/plugin"
export CLAUDE_PLUGIN_ROOT="$SCRATCH/plugin"
export CLAUDE_PLUGIN_DATA="$SCRATCH/data"
SS="$CLAUDE_PLUGIN_ROOT/hooks/session-start.sh"
COPY="$CLAUDE_PLUGIN_DATA/statusline.sh"

echo "== first startup =="
bash "$SS" </dev/null >/dev/null 2>&1; ck "exit 0" "$?" "0"
ck "copy created" "$(cmp -s "$COPY" "$CLAUDE_PLUGIN_ROOT/statusline/statusline.sh" && echo same)" "same"

echo "== plugin update =="
echo "# v2" >> "$CLAUDE_PLUGIN_ROOT/statusline/statusline.sh"
bash "$SS" </dev/null >/dev/null 2>&1
ck "copy refreshed" "$(tail -1 "$COPY")" "# v2"

echo "== no plugin environment =="
unset CLAUDE_PLUGIN_DATA
OUT=$(bash "$SS" </dev/null 2>&1); ck "exit 0 without CLAUDE_PLUGIN_DATA" "$?" "0"
ck "silent" "$OUT" ""

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
