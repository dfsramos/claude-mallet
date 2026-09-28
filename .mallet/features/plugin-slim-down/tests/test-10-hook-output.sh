#!/bin/bash
# Test: advisory hooks deliver their messages through channels the model reads.
# PostToolUse stdout is debug-log only unless it is JSON additionalContext;
# exit-2 feedback is read from stderr.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
H="$REPO/.claude/hooks"

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has() { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }

export HOME="$SCRATCH/home"; mkdir -p "$HOME"

echo "== typecheck.sh =="
export CLAUDE_PROJECT_DIR="$SCRATCH/ts"
mkdir -p "$CLAUDE_PROJECT_DIR" "$SCRATCH/bin"
echo '{}' > "$CLAUDE_PROJECT_DIR/tsconfig.json"
printf '#!/bin/sh\necho "src/a.ts(1,1): error TS2322: bad type"\n' > "$SCRATCH/bin/npx"; chmod +x "$SCRATCH/bin/npx"
IN='{"tool_name":"Edit","tool_input":{"file_path":"'"$CLAUDE_PROJECT_DIR"'/src/a.ts"}}'
OUT=$(echo "$IN" | PATH="$SCRATCH/bin:$PATH" bash "$H/typecheck.sh"); ck "exit 0" "$?" "0"
CTX=$(echo "$OUT" | jq -r '.hookSpecificOutput.additionalContext // empty' 2>/dev/null)
has "additionalContext carries tsc error" "$CTX" "TS2322"
ck  "hookEventName is PostToolUse" "$(echo "$OUT" | jq -r '.hookSpecificOutput.hookEventName' 2>/dev/null)" "PostToolUse"
OUT=$(echo '{"tool_name":"Edit","tool_input":{"file_path":"/x/readme.md"}}' | bash "$H/typecheck.sh")
ck "non-ts edit silent" "$OUT" ""

echo "== write-guard.sh =="
touch "$SCRATCH/exists.txt"
ERR=$(echo '{"tool_name":"Write","tool_input":{"file_path":"'"$SCRATCH"'/exists.txt"}}' | bash "$H/write-guard.sh" 2>&1 >"$SCRATCH/stdout"); RC=$?
ck  "existing file blocked (exit 2)" "$RC" "2"
has "reason on stderr" "$ERR" "already exists"
ck  "stdout empty" "$(cat "$SCRATCH/stdout")" ""
echo '{"tool_name":"Write","tool_input":{"file_path":"'"$SCRATCH"'/new.txt"}}' | bash "$H/write-guard.sh" >/dev/null 2>&1
ck "new file allowed" "$?" "0"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
