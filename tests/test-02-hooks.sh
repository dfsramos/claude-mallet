#!/bin/bash
# Test: hooks resolve state from .mallet/ and never from a payload path.
# Portable: resolves the repo from this script's location and uses a temp dir.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
H="$REPO/plugin/hooks"
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
echo "MISSION-SENTINEL" > "$CLAUDE_PROJECT_DIR/.mallet/missions/active.md"
echo "report" > "$CLAUDE_PROJECT_DIR/.mallet/discovery-2026-01-01.md"
# No repo/version keys -> session-start must not attempt any network call.
echo '{"installed_at":"2026-01-01"}' > "$HOME/.claude/framework.json"

echo "== session-start.sh =="
OUT=$(bash "$H/session-start.sh" 2>&1); ck "exit 0" "$?" "0"
hasnt "no .mallet/memory.md injection (auto memory replaces it)" "$OUT" "MEMORY-SENTINEL"

echo "== session-start.sh with .mallet absent =="
rm -rf "$CLAUDE_PROJECT_DIR/.mallet"
OUT=$(bash "$H/session-start.sh" 2>&1); ck "exit 0" "$?" "0"
ck "emits nothing" "$(echo -n "$OUT" | wc -c)" "0"

echo "== user-prompt-submit.sh never emits [ultracode] =="
OUT=$(printf '{"prompt":"ultracode: do a comprehensive, thorough audit of the entire codebase"}' | bash "$H/user-prompt-submit.sh" 2>&1)
hasnt "no ultracode scoring" "$OUT" "ultracode"
ck "removed hooks gone" "$(ls "$H" | grep -cE 'push-confirm|explore-redirect')" "0"

echo "== statusline renders without framework.json =="
OUT=$(printf '{"workspace":{"project_dir":"%s"},"cost":{"total_cost_usd":0.5}}' "$CLAUDE_PROJECT_DIR" | bash "$REPO/plugin/statusline/statusline.sh" 2>&1)
has "renders cost" "$OUT" "0.5000"

echo "== no stale path references =="
ck "hooks clean" "$(grep -rln '\.claude/project' "$H" "$REPO/plugin/statusline/statusline.sh" 2>/dev/null | wc -l)" "0"
ck "user-prompt-submit reads no payload paths" "$(grep -cE '\.claude/(skills|agents|hooks|templates)' "$H/user-prompt-submit.sh" 2>/dev/null | head -1)" "0"
ck "write-guard unchanged" "$(grep -c '\.claude/' "$H/write-guard.sh" 2>/dev/null | head -1)" "0"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
