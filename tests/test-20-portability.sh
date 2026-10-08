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
hasnt() { if echo "$2" | grep -q "$3"; then echo "  FAIL $1 (unexpected '$3')"; fail=$((fail+1)); else echo "  PASS $1"; pass=$((pass+1)); fi; }

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

echo "== statusline renders both lines =="
export TMPDIR="$SCRATCH"
SL() { # $1 context_window JSON
  jq -n --argjson cw "$1" '{session_id:"port-test",
    model:{id:"m", display_name:"ModelX"}, effort:{level:"high"},
    cost:{total_cost_usd:0.12345}, context_window:$cw,
    rate_limits:{five_hour:{used_percentage:12.4}}}' \
    | bash "$REPO/plugin/statusline/statusline.sh" 2>&1
}
OUT=$(SL '{"total_input_tokens":351400,"used_percentage":35.1}')
ck "exit 0" "$?" "0"
has   "line 1: model and effort" "$OUT" "ModelX · effort: high"
has   "line 2: cost"             "$OUT" '\$0.1235'
has   "line 2: context tokens"   "$OUT" "ctx 351k (35%)"
has   "line 2: 5h limit"         "$OUT" "5h: 12%"
ck    "two lines" "$(echo "$OUT" | wc -l | tr -d ' ')" "2"
hasnt "no turn count"            "$OUT" "T:"
has   "1M+ context in M"         "$(SL '{"total_input_tokens":1020000,"used_percentage":102}')" "ctx 1.02M (102%)"
has   "percentage only, before tokens are known" "$(SL '{"total_input_tokens":0,"used_percentage":8}')" "ctx 8%"
hasnt "no context segment without data"          "$(SL '{}')" "ctx"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
