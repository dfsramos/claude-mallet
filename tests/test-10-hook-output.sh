#!/bin/bash
# Test: advisory hooks deliver their messages through channels the model reads.
# PostToolUse stdout is debug-log only unless it is JSON additionalContext;
# exit-2 feedback is read from stderr.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
H="$REPO/plugin/hooks"

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has() { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }
hasnt() { if echo "$2" | grep -q "$3"; then echo "  FAIL $1 (unexpected '$3')"; fail=$((fail+1)); else echo "  PASS $1"; pass=$((pass+1)); fi; }

export HOME="$SCRATCH/home"; mkdir -p "$HOME"

echo "== typecheck.sh + typecheck-stop.sh =="
export TMPDIR="$SCRATCH/tmp"; mkdir -p "$TMPDIR"
export CLAUDE_PROJECT_DIR="$SCRATCH/ts"
mkdir -p "$CLAUDE_PROJECT_DIR/.mallet" "$SCRATCH/bin"
echo '{}' > "$CLAUDE_PROJECT_DIR/tsconfig.json"
touch "$CLAUDE_PROJECT_DIR/.mallet/typecheck.enabled"
# Local tsc stub; a PATH npx stub records any call, which must never happen.
mkdir -p "$CLAUDE_PROJECT_DIR/node_modules/.bin"
TSC_STUB='#!/bin/sh\necho "src/a.ts(1,1): error TS2322: bad type"\necho "src/old.ts(9,9): error TS2304: pre-existing"\n'
printf "$TSC_STUB" > "$CLAUDE_PROJECT_DIR/node_modules/.bin/tsc"; chmod +x "$CLAUDE_PROJECT_DIR/node_modules/.bin/tsc"
printf '#!/bin/sh\ntouch "%s/npx-called"\n' "$SCRATCH" > "$SCRATCH/bin/npx"; chmod +x "$SCRATCH/bin/npx"
LIST="$TMPDIR/mallet-typecheck-s1.list"
edit() { echo '{"session_id":"s1","tool_name":"'"$1"'","tool_input":{"file_path":"'"$2"'"}}' | PATH="$SCRATCH/bin:$PATH" bash "$H/typecheck.sh"; }
stop() { echo '{"session_id":"s1","stop_hook_active":'"${1:-false}"'}' | PATH="$SCRATCH/bin:$PATH" bash "$H/typecheck-stop.sh"; }
OUT=$(edit Edit "$CLAUDE_PROJECT_DIR/src/a.ts"); ck "edit records silently" "$OUT" ""
edit Write "$CLAUDE_PROJECT_DIR/src/a.ts" >/dev/null
edit Edit "/x/readme.md" >/dev/null
ck "only ts/php recorded" "$(sort -u "$LIST")" "$CLAUDE_PROJECT_DIR/src/a.ts"
OUT=$(stop true); ck "stop_hook_active: silent" "$OUT" ""
ck "stop_hook_active: list kept" "$([ -s "$LIST" ] && echo kept)" "kept"
OUT=$(stop); ck "stop exit 0" "$?" "0"
CTX=$(echo "$OUT" | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null)
has   "error in edited file reported" "$CTX" "TS2322"
hasnt "error in unedited file left out" "$CTX" "TS2304"
ck    "hookEventName is Stop" "$(echo "$OUT" | jq -r .hookSpecificOutput.hookEventName 2>/dev/null)" "Stop"
ck    "list cleared" "$([ -e "$LIST" ] && echo present || echo cleared)" "cleared"
OUT=$(stop); ck "nothing edited: silent" "$OUT" ""
edit Edit "$CLAUDE_PROJECT_DIR/src/clean.ts" >/dev/null
OUT=$(stop); ck "no errors in edited files: silent" "$OUT" ""

# The project path is stripped literally, never as a regex: '|' would break a
# sed s||| expression, and '.' would match any character.
WEIRD="$SCRATCH/we|ird.dir"
mkdir -p "$WEIRD/.mallet" "$WEIRD/node_modules/.bin"
echo '{}' > "$WEIRD/tsconfig.json"; touch "$WEIRD/.mallet/typecheck.enabled"
printf "$TSC_STUB" > "$WEIRD/node_modules/.bin/tsc"; chmod +x "$WEIRD/node_modules/.bin/tsc"
OUT=$(CLAUDE_PROJECT_DIR="$WEIRD"; edit Edit "$WEIRD/src/a.ts" >/dev/null; stop 2>&1)
has "metacharacters in project path: error still matched" "$(echo "$OUT" | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null)" "TS2322"

# Workspace package: tsc hoisted to the monorepo root is found by walking up.
PKG="$SCRATCH/mono/packages/app"
mkdir -p "$PKG/.mallet" "$SCRATCH/mono/node_modules/.bin"
echo '{}' > "$PKG/tsconfig.json"; touch "$PKG/.mallet/typecheck.enabled"
printf "$TSC_STUB" > "$SCRATCH/mono/node_modules/.bin/tsc"; chmod +x "$SCRATCH/mono/node_modules/.bin/tsc"
OUT=$(CLAUDE_PROJECT_DIR="$PKG"; edit Edit "$PKG/src/a.ts" >/dev/null; stop 2>&1)
has "hoisted tsc found from a workspace package" "$(echo "$OUT" | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null)" "TS2322"

# A check killed mid-run (hook timeout) must leave the list for the next turn.
printf '#!/bin/sh\nsleep 10\n' > "$CLAUDE_PROJECT_DIR/node_modules/.bin/tsc"
edit Edit "$CLAUDE_PROJECT_DIR/src/a.ts" >/dev/null
echo '{"session_id":"s1"}' | timeout 1 bash "$H/typecheck-stop.sh" >/dev/null 2>&1
ck "killed check keeps the list" "$([ -s "$LIST" ] && echo kept || echo gone)" "kept"
rm -f "$LIST"

# No local tsc: skip rather than let npx fetch the unrelated `tsc` package.
rm "$CLAUDE_PROJECT_DIR/node_modules/.bin/tsc"
edit Edit "$CLAUDE_PROJECT_DIR/src/a.ts" >/dev/null
OUT=$(stop); ck "no local tsc: silent" "$OUT" ""
ck "npx never called" "$([ -e "$SCRATCH/npx-called" ] && echo called || echo no)" "no"
rm "$CLAUDE_PROJECT_DIR/.mallet/typecheck.enabled"
edit Edit "$CLAUDE_PROJECT_DIR/src/a.ts" >/dev/null
ck "no marker, nothing recorded" "$([ -e "$LIST" ] && echo present || echo none)" "none"

echo "== write-guard.sh =="
touch "$SCRATCH/exists.txt"
ERR=$(echo '{"tool_name":"Write","tool_input":{"file_path":"'"$SCRATCH"'/exists.txt"}}' | bash "$H/write-guard.sh" 2>&1 >"$SCRATCH/stdout"); RC=$?
ck  "existing file blocked (exit 2)" "$RC" "2"
has "reason on stderr" "$ERR" "already exists"
ck  "stdout empty" "$(cat "$SCRATCH/stdout")" ""
echo '{"tool_name":"Write","tool_input":{"file_path":"'"$SCRATCH"'/new.txt"}}' | bash "$H/write-guard.sh" >/dev/null 2>&1
ck "new file allowed" "$?" "0"
mkdir -p "$SCRATCH/cfg"; echo '{}' > "$SCRATCH/cfg/tsconfig.json"; echo 'x' > "$SCRATCH/cfg/app.ts"
OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"'"$SCRATCH"'/cfg/tsconfig.json"}}' | bash "$H/write-guard.sh"); RC=$?
ck  "lint config edit asks"   "$(echo "$OUT" | jq -r .hookSpecificOutput.permissionDecision 2>/dev/null)" "ask"
ck  "ask exits 0"             "$RC" "0"
has "ask reason names file"   "$(echo "$OUT" | jq -r .hookSpecificOutput.permissionDecisionReason 2>/dev/null)" "tsconfig.json"
OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"'"$SCRATCH"'/cfg/app.ts"}}' | bash "$H/write-guard.sh")
ck  "source edit untouched"   "$OUT" ""
OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"'"$SCRATCH"'/cfg/.eslintrc.json"}}' | bash "$H/write-guard.sh")
ck  "new config file not asked" "$OUT" ""

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
