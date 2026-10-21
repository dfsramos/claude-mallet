#!/bin/bash
# Test: compaction continuity comes from a SessionStart `compact` hook that
# emits fresh git state; the old PreCompact snapshot mechanism is gone from
# payload and merged settings, and a leftover mission file is not restored.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
H="$REPO/plugin/hooks"

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has() { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }
hasnt() { if echo "$2" | grep -q "$3"; then echo "  FAIL $1 (unexpected '$3')"; fail=$((fail+1)); else echo "  PASS $1"; pass=$((pass+1)); fi; }

export HOME="$SCRATCH/home"; mkdir -p "$HOME/.claude"
export CLAUDE_PROJECT_DIR="$SCRATCH/repo"
mkdir -p "$CLAUDE_PROJECT_DIR/.mallet/missions"
git -C "$CLAUDE_PROJECT_DIR" init -q -b trunk-x
git -C "$CLAUDE_PROJECT_DIR" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "first-commit-sentinel"
echo "dirty" > "$CLAUDE_PROJECT_DIR/untracked.txt"
# Earlier versions restored .mallet/missions/active.md here; open work now
# lives in auto memory, which Claude Code loads itself after compaction.
echo "MISSION-SENTINEL" > "$CLAUDE_PROJECT_DIR/.mallet/missions/active.md"

echo "== post-compact.sh =="
[ -f "$H/post-compact.sh" ] || { echo "  FAIL post-compact.sh missing"; echo "pass=$pass fail=1"; exit 1; }
OUT=$(bash "$H/post-compact.sh" 2>&1); ck "exit 0" "$?" "0"
has "branch"           "$OUT" "trunk-x"
has "recent commits"   "$OUT" "first-commit-sentinel"
has "uncommitted"      "$OUT" "untracked.txt"
hasnt "leftover mission file not restored" "$OUT" "MISSION-SENTINEL"
ck "output under 10,000 chars" "$([ ${#OUT} -lt 10000 ] && echo yes || echo "no (${#OUT})")" "yes"

echo "== post-compact.sh outside a git repo, no .mallet =="
export CLAUDE_PROJECT_DIR="$SCRATCH/plain"; mkdir -p "$CLAUDE_PROJECT_DIR"
OUT=$(bash "$H/post-compact.sh" 2>&1); ck "exit 0" "$?" "0"
hasnt "no git noise" "$OUT" "fatal"

echo "== payload =="
ck "pre-compact.sh removed" "$([ -f "$H/pre-compact.sh" ] && echo present || echo gone)" "gone"
ck "SessionStart compact registered by the plugin" "$(jq -r '[.hooks.SessionStart[] | select(.matcher | test("compact")) | .hooks[].command | select(test("post-compact.sh"))] | length' "$REPO/plugin/hooks/hooks.json")" "1"
hasnt "session-start no snapshot" "$(cat "$H/session-start.sh")" "compact-snapshot"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
