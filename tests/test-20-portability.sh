#!/bin/bash
# Test: hook and statusline scripts stay within the bash 3.2 / BSD subset that
# macOS runs (conventions.md, Hook Authoring). The suite itself runs on Linux,
# so the forbidden constructs are caught statically, and the statusline is
# rendered end to end to prove every line still prints.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has() { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }

echo "== bash 4+ constructs =="
# Prints file:line:text for each match in code, ignoring comments, so a script
# can explain why it avoids a construct. -H keeps the file prefix even when
# find passes a single file.
hits() {
  find "$REPO/plugin/hooks" "$REPO/plugin/statusline" -name '*.sh' -exec grep -nHE "$1" {} + \
    | sed "s|$REPO/||" | while IFS= read -r l; do
      code=$(printf '%s\n' "$l" | cut -d: -f3- | sed 's/^[[:space:]]*#.*//; s/[[:space:]]#.*//')
      printf '%s\n' "$code" | grep -qE "$1" && printf '%s\n' "$l"
    done
}
ck "no nameref (local/declare -n)"   "$(hits '(local|declare|typeset) +-[a-zA-Z]*n')" ""
ck "no associative arrays"           "$(hits '(local|declare|typeset) +-[a-zA-Z]*A')" ""
ck "no mapfile / readarray"          "$(hits '(^|[^[:alnum:]_])(mapfile|readarray)[[:space:]]')" ""
ck "no case modification (\${v^^})"  "$(hits '\$\{[A-Za-z_][A-Za-z0-9_]*(\^|,)')" ""

echo "== locale-independent float formatting =="
ck "every printf/awk %f runs under LC_ALL=C" "$(hits '%[0-9]*\.?[0-9]*f' | grep -vE 'LC_ALL=C (printf|awk)')" ""

echo "== statusline renders all three lines =="
TRANSCRIPT="$SCRATCH/t.jsonl"
echo '{"message":{"role":"assistant","usage":{"input_tokens":1200,"cache_creation_input_tokens":0,"cache_read_input_tokens":3400,"output_tokens":560}}}' > "$TRANSCRIPT"
export TMPDIR="$SCRATCH"
OUT=$(jq -n --arg t "$TRANSCRIPT" '{session_id:"port-test", transcript_path:$t,
  model:{id:"m", display_name:"ModelX"}, effort:{level:"high"},
  cost:{total_cost_usd:0.12345}, context_window:{used_percentage:41.6}}' \
  | bash "$REPO/plugin/statusline/statusline.sh" 2>&1)
ck "exit 0" "$?" "0"
has "line 1: model and effort" "$OUT" "ModelX · effort: high"
has "line 2: cost"             "$OUT" '\$0.1235'
has "line 2: context %"        "$OUT" "◷ 42%"
has "line 3: token totals"     "$OUT" "Σ 5.2k"
ck "three lines" "$(echo "$OUT" | wc -l | tr -d ' ')" "3"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
