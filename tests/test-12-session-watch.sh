#!/bin/bash
# Test: session-watch warns on context size in tokens, read from the last real
# assistant usage in the transcript tail, once per step; and the statusline turn
# segment counts only human-typed prompts — not tool results, agent hand-backs,
# or skill expansions.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has() { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }
hasnt() { if echo "$2" | grep -q "$3"; then echo "  FAIL $1 (unexpected '$3')"; fail=$((fail+1)); else echo "  PASS $1"; pass=$((pass+1)); fi; }

export HOME="$SCRATCH/home"; mkdir -p "$HOME/.claude"
export CLAUDE_PROJECT_DIR="$SCRATCH/repo"; mkdir -p "$CLAUDE_PROJECT_DIR"
export TMPDIR="$SCRATCH/tmp"; mkdir -p "$TMPDIR"
unset CLAUDE_CTX_WARN_THRESHOLD CLAUDE_CTX_WARN_STEP

HOOK="$REPO/plugin/hooks/user-prompt-submit.sh"

# Assistant record whose usage totals $1 tokens (split across the three fields).
asst() { # $1 total $2 model (default a real one)
  jq -nc --argjson t "$1" --arg m "${2:-claude-opus-5-5}" \
    '{type:"assistant", message:{role:"assistant", model:$m, content:[{type:"text",text:"ok"}],
      usage:{input_tokens:10, cache_creation_input_tokens:990, cache_read_input_tokens:($t - 1000), output_tokens:50}}}'
}
# Transcript: filler, then the given assistant totals in order.
mk() { # $1 file, then totals; a total "syn:N" writes a <synthetic> record
  f="$1"; shift; : > "$f"
  for i in $(seq 1 300); do echo '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"x","content":"r"}]}}' >> "$f"; done
  for t in "$@"; do
    case "$t" in syn:*) asst "${t#syn:}" "<synthetic>" >> "$f" ;; *) asst "$t" >> "$f" ;; esac
    echo '{"type":"user","origin":{"kind":"human"},"message":{"role":"user","content":"p"}}' >> "$f"
  done
}
run() { # $1 transcript $2 session
  jq -n --arg t "$1" --arg s "${2:-s1}" '{prompt:"hello", transcript_path:$t, session_id:$s}' | bash "$HOOK"
}

echo "== user-prompt-submit.sh session-watch =="
mk "$SCRATCH/big.jsonl" 20000 351000
OUT=$(run "$SCRATCH/big.jsonl" s1); RC=$?
ck    "1. exit 0 above threshold"          "$RC" "0"
ck    "1. output is valid JSON"            "$(echo "$OUT" | jq -e . >/dev/null; echo $?)" "0"
ck    "1. event name"                      "$(echo "$OUT" | jq -r .hookSpecificOutput.hookEventName)" "UserPromptSubmit"
has   "1. user line names the size"        "$(echo "$OUT" | jq -r .systemMessage)" "about 351k tokens"
has   "1. context carries the tag"         "$(echo "$OUT" | jq -r .hookSpecificOutput.additionalContext)" "^\[session-watch\] Context is about 351k tokens"
has   "1. context names the next step"     "$(echo "$OUT" | jq -r .hookSpecificOutput.additionalContext)" "next 50k step"
ck    "1. bucket stored"                   "$(cat "$TMPDIR/mallet-watch-s1.last")" "5"

OUT=$(run "$SCRATCH/big.jsonl" s1); RC=$?
ck    "2. repeat: exit 0"                  "$RC" "0"
ck    "2. repeat: silent"                  "$OUT" ""

mk "$SCRATCH/small.jsonl" 351000 40000
OUT=$(run "$SCRATCH/small.jsonl" s1); RC=$?
ck    "3. under threshold: exit 0"         "$RC" "0"
ck    "3. under threshold: silent"         "$OUT" ""
ck    "3. state file removed"              "$([ -e "$TMPDIR/mallet-watch-s1.last" ] && echo present || echo gone)" "gone"

OUT=$(echo '{}' | bash "$HOOK"); RC=$?
ck    "4. stdin {}: exit 0"                "$RC" "0"
ck    "4. stdin {}: silent"                "$OUT" ""
OUT=$(run "$SCRATCH/missing.jsonl" s4); RC=$?
ck    "4. missing transcript: exit 0"      "$RC" "0"
ck    "4. missing transcript: silent"      "$OUT" ""
OUT=$(jq -n --arg t "$SCRATCH/big.jsonl" '{transcript_path:$t}' | bash "$HOOK"); RC=$?
ck    "4. no session_id: silent, exit 0"   "$RC:$OUT" "0:"
printf 'not json\n{"type":"assistant"\n' > "$SCRATCH/junk.jsonl"
OUT=$(run "$SCRATCH/junk.jsonl" s4); RC=$?
ck    "4. unparseable transcript: exit 0"  "$RC:$OUT" "0:"

mk "$SCRATCH/syn.jsonl" 180000 syn:0
OUT=$(run "$SCRATCH/syn.jsonl" s5)
has   "5. <synthetic> skipped, previous real one used" "$(echo "$OUT" | jq -r .systemMessage)" "about 180k tokens"

mk "$SCRATCH/r160.jsonl" 160000
mk "$SCRATCH/r210.jsonl" 160000 210000
has   "6. warns at 160k"                   "$(run "$SCRATCH/r160.jsonl" s6 | jq -r .systemMessage)" "about 160k"
ck    "6. bucket 1"                        "$(cat "$TMPDIR/mallet-watch-s6.last")" "1"
has   "6. warns again at 210k"             "$(run "$SCRATCH/r210.jsonl" s6 | jq -r .systemMessage)" "about 210k"
ck    "6. bucket 2"                        "$(cat "$TMPDIR/mallet-watch-s6.last")" "2"

echo "== thresholds and the 200-line tail =="
OUT=$(CLAUDE_CTX_WARN_THRESHOLD=100000 CLAUDE_CTX_WARN_STEP=10000 run "$SCRATCH/r160.jsonl" s7)
has   "env threshold and step apply"       "$(echo "$OUT" | jq -r .hookSpecificOutput.additionalContext)" "next 10k step"
ck    "env bucket"                         "$(cat "$TMPDIR/mallet-watch-s7.last")" "7"
OUT=$(CLAUDE_CTX_WARN_STEP=0 run "$SCRATCH/r160.jsonl" s8); RC=$?
ck    "step 0 falls back to default"       "$RC:$(cat "$TMPDIR/mallet-watch-s8.last")" "0:1"
OUT=$(CLAUDE_CTX_WARN_THRESHOLD=0100000 CLAUDE_CTX_WARN_STEP=010000 run "$SCRATCH/r160.jsonl" s12 2>&1)
ck    "leading zeros read as decimal"      "$(cat "$TMPDIR/mallet-watch-s12.last"):$(echo "$OUT" | grep -c 'base')" "7:0"
{ cat "$SCRATCH/r160.jsonl"; jq -nc '{type:"assistant", message:{model:"m", usage:{input_tokens:0}}}'; } > "$SCRATCH/zero.jsonl"
echo 1 > "$TMPDIR/mallet-watch-s13.last"
run "$SCRATCH/zero.jsonl" s13 >/dev/null
ck    "all-zero usage skipped, state kept" "$(cat "$TMPDIR/mallet-watch-s13.last")" "1"
{ asst 400000; for i in $(seq 1 250); do echo '{"type":"user","message":{"role":"user","content":"x"}}'; done; } > "$SCRATCH/old.jsonl"
ck    "usage older than the tail is not read" "$(run "$SCRATCH/old.jsonl" s9)" ""
{ cat "$SCRATCH/r160.jsonl"; printf '{"type":"assistant","message":{"usa'; } > "$SCRATCH/partial.jsonl"
has   "half-written last line is skipped"  "$(run "$SCRATCH/partial.jsonl" s10 | jq -r .systemMessage)" "about 160k"
jq -nc '{type:"assistant", isSidechain:true, message:{model:"m", usage:{input_tokens:500000}}}' >> "$SCRATCH/r160.jsonl"
has   "sidechain records ignored"          "$(run "$SCRATCH/r160.jsonl" s11 | jq -r .systemMessage)" "about 160k"

echo "== session-watch with calibrate =="
echo '{"model":"claude-opus-5-5","effort":"high"}' > "$TMPDIR/mallet-calibrate-c1.json"
OUT=$(run "$SCRATCH/big.jsonl" c1)
ck    "one JSON object when both fire"     "$(echo "$OUT" | jq -s length)" "1"
has   "calibrate folded into context"      "$(echo "$OUT" | jq -r .hookSpecificOutput.additionalContext)" "^\[calibrate\] active model: claude-opus-5-5; effort: high"
hasnt "calibrate not in the user line"     "$(echo "$OUT" | jq -r .systemMessage)" "calibrate"
echo '{"model":"claude-opus-5-5","effort":"max"}' > "$TMPDIR/mallet-calibrate-c1.json"
OUT=$(run "$SCRATCH/big.jsonl" c1)
ck    "calibrate alone stays plain text"   "$OUT" "[calibrate] active model: claude-opus-5-5; effort: max"

echo "== statusline.sh =="
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
L="$SCRATCH/legacy.jsonl"
{
  echo '{"type":"user","message":{"role":"user","content":"typed"}}'
  echo '{"type":"user","message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"x","content":"r"}]}}'
  echo '{"type":"user","isMeta":true,"message":{"role":"user","content":"meta"}}'
} > "$L"
SL() { jq -n --arg t "$1" '{transcript_path:$t, workspace:{project_dir:"'"$CLAUDE_PROJECT_DIR"'"}}' | bash "$REPO/plugin/statusline/statusline.sh" | sed 's/\x1b\[[0-9;]*m//g'; }
OUT=$(SL "$T");  has "counts 2 human prompts" "$OUT" "T:2"
OUT=$(SL "$L");  has "legacy: counts 1"       "$OUT" "T:1"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
