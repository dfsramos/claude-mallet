#!/bin/bash
# Test: hooks resolve state from .mallet/ and framework.json from $HOME.
# Portable: resolves the repo from this script's location and uses a temp dir.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
H="$REPO/.claude/hooks"
FIX="$SCRATCH/fix02"

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has() { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }
hasnt() { if echo "$2" | grep -q "$3"; then echo "  FAIL $1 (unexpected '$3')"; fail=$((fail+1)); else echo "  PASS $1"; pass=$((pass+1)); fi; }

# Isolated fake HOME so the real ~/.claude is never read or written.
export HOME="$FIX/home"
export CLAUDE_PROJECT_DIR="$FIX/repo"
rm -rf "$FIX"; mkdir -p "$HOME/.claude" "$CLAUDE_PROJECT_DIR/.mallet/missions"

echo "MEMORY-SENTINEL" > "$CLAUDE_PROJECT_DIR/.mallet/memory.md"
echo "SNAPSHOT-SENTINEL" > "$CLAUDE_PROJECT_DIR/.mallet/compact-snapshot.md"
echo "MISSION-SENTINEL" > "$CLAUDE_PROJECT_DIR/.mallet/missions/active.md"
echo "report" > "$CLAUDE_PROJECT_DIR/.mallet/discovery-2026-01-01.md"
# No repo/version keys -> session-start must not attempt any network call.
echo '{"installed_at":"2026-01-01"}' > "$HOME/.claude/framework.json"

echo "== session-start.sh =="
OUT=$(bash "$H/session-start.sh" 2>&1); ck "exit 0" "$?" "0"
has  "injects .mallet/memory.md"   "$OUT" "MEMORY-SENTINEL"
has  "injects compact snapshot"    "$OUT" "SNAPSHOT-SENTINEL"
ck   "snapshot consumed (deleted)" "$([ -f "$CLAUDE_PROJECT_DIR/.mallet/compact-snapshot.md" ] && echo present || echo gone)" "gone"

echo "== pre-compact.sh =="
OUT=$(bash "$H/pre-compact.sh" 2>&1); ck "exit 0" "$?" "0"
has "stdout has mission" "$OUT" "MISSION-SENTINEL"
ck  "writes to .mallet/" "$([ -f "$CLAUDE_PROJECT_DIR/.mallet/compact-snapshot.md" ] && echo yes || echo no)" "yes"
hasnt "no stderr noise" "$OUT" "No such file"

echo "== pre-compact.sh with .mallet absent (mkdir -p) =="
rm -rf "$CLAUDE_PROJECT_DIR/.mallet"
OUT=$(bash "$H/pre-compact.sh" 2>&1); ck "exit 0" "$?" "0"
ck  "created .mallet/ and wrote" "$([ -f "$CLAUDE_PROJECT_DIR/.mallet/compact-snapshot.md" ] && echo yes || echo no)" "yes"
hasnt "no tee error" "$OUT" "No such file"

echo "== session-start.sh with .mallet absent =="
rm -rf "$CLAUDE_PROJECT_DIR/.mallet"
OUT=$(bash "$H/session-start.sh" 2>&1); ck "exit 0" "$?" "0"
ck "emits nothing" "$(echo -n "$OUT" | wc -c)" "0"

echo "== explore-redirect.sh =="
mkdir -p "$CLAUDE_PROJECT_DIR/.mallet"
echo "report" > "$CLAUDE_PROJECT_DIR/.mallet/discovery-2026-01-01.md"
OUT=$(printf '{"tool_name":"Bash","tool_input":{"command":"grep -rn foo ."}}' | bash "$H/explore-redirect.sh" 2>&1)
has "finds .mallet/ discovery"  "$OUT" "discovery report exists"
has "message says .mallet/"     "$OUT" "\.mallet/discovery-2026-01-01\.md"
hasnt "no stale .claude/project" "$OUT" "\.claude/project"

echo "== statusline.sh reads \$HOME/framework.json =="
echo '{"repo":"a/b","version":"deadbeefcafe1234","installed_at":"2026-01-01"}' > "$HOME/.claude/framework.json"
OUT=$(printf '{"workspace":{"project_dir":"%s"},"cost":{"total_cost_usd":0.5}}' "$CLAUDE_PROJECT_DIR" | bash "$H/../statusline.sh" 2>&1)
has "renders version from HOME" "$OUT" "deadbee"

echo "== no stale path references =="
ck "hooks clean" "$(grep -rln '\.claude/project' "$H" "$REPO/.claude/statusline.sh" 2>/dev/null | wc -l)" "0"
ck "user-prompt-submit unchanged" "$(grep -c '\.claude/' "$H/user-prompt-submit.sh" 2>/dev/null | head -1)" "0"
ck "write-guard unchanged" "$(grep -c '\.claude/' "$H/write-guard.sh" 2>/dev/null | head -1)" "0"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
