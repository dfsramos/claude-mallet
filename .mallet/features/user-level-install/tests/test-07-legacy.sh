#!/bin/bash
# Test: session-start.sh notices a leftover per-project payload, quietly and suppressibly.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
SS="$REPO/.claude/hooks/session-start.sh"

pass=0; fail=0
ck()   { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has()  { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }
hasnt(){ if echo "$2" | grep -q "$3"; then echo "  FAIL $1 (unexpected '$3')"; fail=$((fail+1)); else echo "  PASS $1"; pass=$((pass+1)); fi; }

export HOME="$SCRATCH/home"; mkdir -p "$HOME/.claude"

echo "== framework.json marker =="
export CLAUDE_PROJECT_DIR="$SCRATCH/r1"; mkdir -p "$CLAUDE_PROJECT_DIR/.claude"
echo '{"repo":"o/r","version":"x"}' > "$CLAUDE_PROJECT_DIR/.claude/framework.json"
OUT=$(bash "$SS" 2>&1); ck "exit 0" "$?" "0"
has "notice emitted"    "$OUT" "Legacy Mallet Install Detected"
has "mentions migrate"  "$OUT" "migrate"

echo "== payload-pair marker (no framework.json) =="
export CLAUDE_PROJECT_DIR="$SCRATCH/r2"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/skills/update" "$CLAUDE_PROJECT_DIR/.claude/agents"
echo x > "$CLAUDE_PROJECT_DIR/.claude/skills/update/SKILL.md"
echo x > "$CLAUDE_PROJECT_DIR/.claude/agents/_contract.md"
OUT=$(bash "$SS" 2>&1)
has "pair detected" "$OUT" "Legacy Mallet Install Detected"

echo "== clean migrated repo stays silent =="
export CLAUDE_PROJECT_DIR="$SCRATCH/r3"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude" "$CLAUDE_PROJECT_DIR/.mallet"
echo '{"permissions":{}}' > "$CLAUDE_PROJECT_DIR/.claude/settings.local.json"
echo "MEM" > "$CLAUDE_PROJECT_DIR/.mallet/memory.md"
OUT=$(bash "$SS" 2>&1)
hasnt "no false positive" "$OUT" "Legacy Mallet Install Detected"
has   "memory still injected" "$OUT" "MEM"

echo "== half-payload does not trigger =="
export CLAUDE_PROJECT_DIR="$SCRATCH/r4"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/agents"
echo x > "$CLAUDE_PROJECT_DIR/.claude/agents/_contract.md"
OUT=$(bash "$SS" 2>&1)
hasnt "agents alone is not enough" "$OUT" "Legacy Mallet Install Detected"

echo "== suppression file =="
export CLAUDE_PROJECT_DIR="$SCRATCH/r1"
mkdir -p "$CLAUDE_PROJECT_DIR/.mallet"
touch "$CLAUDE_PROJECT_DIR/.mallet/.migration-declined"
OUT=$(bash "$SS" 2>&1)
hasnt "suppressed" "$OUT" "Legacy Mallet Install Detected"

echo "== the install dir itself is not a legacy install =="
# A session whose project dir IS $HOME would otherwise see ~/.claude/skills/update
# and ~/.claude/agents/_contract.md and nag forever.
export CLAUDE_PROJECT_DIR="$HOME"
mkdir -p "$HOME/.claude/skills/update" "$HOME/.claude/agents"
echo x > "$HOME/.claude/skills/update/SKILL.md"
echo x > "$HOME/.claude/agents/_contract.md"
echo '{"repo":"o/r","version":"x"}' > "$HOME/.claude/framework.json"
OUT=$(bash "$SS" 2>&1)
hasnt "install dir exempt" "$OUT" "Legacy Mallet Install Detected"

echo "== the framework source repo is not a legacy install =="
export CLAUDE_PROJECT_DIR="$SCRATCH/src"
mkdir -p "$CLAUDE_PROJECT_DIR/.claude/skills/update" "$CLAUDE_PROJECT_DIR/.claude/agents"
echo x > "$CLAUDE_PROJECT_DIR/.claude/skills/update/SKILL.md"
echo x > "$CLAUDE_PROJECT_DIR/.claude/agents/_contract.md"
echo '{}' > "$CLAUDE_PROJECT_DIR/.claude/settings.fragment.json"
OUT=$(bash "$SS" 2>&1)
hasnt "source repo exempt" "$OUT" "Legacy Mallet Install Detected"

echo "== unset CLAUDE_PROJECT_DIR is safe =="
unset CLAUDE_PROJECT_DIR
OUT=$(bash "$SS" 2>&1); ck "exit 0" "$?" "0"
hasnt "no notice" "$OUT" "Legacy Mallet Install Detected"

echo "== check is cheap: no find/curl =="
ck "no find in legacy block" "$(sed -n '/Legacy per-project/,/^fi$/p' "$SS" | grep -c 'find \|curl ')" "0"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
