#!/bin/bash
# Test: the session-watch counter and the statusline turn segment count only
# human-typed prompts — not tool results, agent hand-backs, or skill expansions.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has() { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }
hasnt() { if echo "$2" | grep -q "$3"; then echo "  FAIL $1 (unexpected '$3')"; fail=$((fail+1)); else echo "  PASS $1"; pass=$((pass+1)); fi; }

export HOME="$SCRATCH/home"; mkdir -p "$HOME/.claude"
export CLAUDE_PROJECT_DIR="$SCRATCH/repo"; mkdir -p "$CLAUDE_PROJECT_DIR"

# Current transcript shape: typed prompts carry origin.kind == "human".
T="$SCRATCH/t.jsonl"
{
  echo '{"type":"user","origin":{"kind":"human"},"message":{"role":"user","content":"first typed prompt"}}'
  echo '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"ok"}]}}'
  for i in 1 2 3 4 5; do echo '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"x","content":"r"}]}}'; done
  echo '{"type":"user","isMeta":true,"origin":{"kind":"peer"},"message":{"role":"user","content":"Another Claude session sent a message"}}'
  echo '{"type":"user","isMeta":true,"message":{"role":"user","content":[{"type":"text","text":"Base directory for this skill"}]}}'
  echo '{"type":"user","isSidechain":true,"message":{"role":"user","content":"subagent prompt"}}'
  echo '{"type":"user","origin":{"kind":"human"},"message":{"role":"user","content":[{"type":"text","text":"second typed prompt with attachment"}]}}'
} > "$T"

# Legacy transcript shape: no origin field at all.
L="$SCRATCH/legacy.jsonl"
{
  echo '{"type":"user","message":{"role":"user","content":"typed"}}'
  echo '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"x","content":"r"}]}}'
  echo '{"type":"user","isMeta":true,"message":{"role":"user","content":"meta"}}'
} > "$L"

run_hook() { # $1 transcript
  jq -n --arg t "$1" '{prompt:"hello", transcript_path:$t, session_id:"s1"}' \
    | bash "$REPO/plugin/hooks/user-prompt-submit.sh"
}

# Pad a transcript with N-1 human prompts so the next prompt is the Nth.
pad() { # $1 file $2 count
  : > "$1"; for i in $(seq 1 "$2"); do echo '{"type":"user","origin":{"kind":"human"},"message":{"role":"user","content":"p"}}' >> "$1"; done
  for i in $(seq 1 200); do echo '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"x","content":"r"}]}}' >> "$1"; done
}

echo "== user-prompt-submit.sh =="
pad "$SCRATCH/p49.jsonl" 49
has   "warns at prompt 50"        "$(run_hook "$SCRATCH/p49.jsonl")" "50 prompts"
pad "$SCRATCH/p10.jsonl" 10
hasnt "silent at prompt 11 despite 200 tool results" "$(run_hook "$SCRATCH/p10.jsonl")" "session-watch"

echo "== statusline.sh =="
SL() { jq -n --arg t "$1" '{transcript_path:$t, workspace:{project_dir:"'"$CLAUDE_PROJECT_DIR"'"}}' | bash "$REPO/plugin/statusline/statusline.sh" | sed 's/\x1b\[[0-9;]*m//g'; }
OUT=$(SL "$T");  has "counts 2 human prompts" "$OUT" "T:2"
OUT=$(SL "$L");  has "legacy: counts 1"       "$OUT" "T:1"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
