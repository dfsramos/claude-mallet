#!/bin/bash
# Test: calibrate — the statusline records the live model and effort per
# session; user-prompt-submit injects them only when they change; the old
# regex complexity scoring is gone.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has() { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }
hasnt() { if echo "$2" | grep -q "$3"; then echo "  FAIL $1 (unexpected '$3')"; fail=$((fail+1)); else echo "  PASS $1"; pass=$((pass+1)); fi; }

export HOME="$SCRATCH/home"; mkdir -p "$HOME/.claude"
export TMPDIR="$SCRATCH/tmp"; mkdir -p "$TMPDIR"
export CLAUDE_PROJECT_DIR="$SCRATCH/repo"; mkdir -p "$CLAUDE_PROJECT_DIR/.claude"

render() { # $1 model id, $2 effort level (empty = field absent)
  local e=""; [ -n "$2" ] && e=',"effort":{"level":"'"$2"'"}'
  echo '{"session_id":"sess-1","model":{"id":"'"$1"'","display_name":"X"},"workspace":{"project_dir":"'"$CLAUDE_PROJECT_DIR"'"}'"$e"'}' \
    | bash "$REPO/plugin/statusline/statusline.sh" >/dev/null
}
prompt() { # $1 prompt text, $2 session id
  jq -n --arg p "$1" --arg s "${2:-sess-1}" '{prompt:$p, session_id:$s}' | bash "$REPO/plugin/hooks/user-prompt-submit.sh"
}

echo "== statusline records state =="
render "claude-opus-5-5" "xhigh"
ck "state file model"  "$(jq -r .model  "$TMPDIR/mallet-calibrate-sess-1.json" 2>/dev/null)" "claude-opus-5-5"
ck "state file effort" "$(jq -r .effort "$TMPDIR/mallet-calibrate-sess-1.json" 2>/dev/null)" "xhigh"

echo "== hook emits on first prompt, then only on change =="
OUT=$(prompt "hi");         has "first prompt emits"  "$OUT" "\[calibrate\] active model: claude-opus-5-5; effort: xhigh"
OUT=$(prompt "again");      ck  "unchanged is silent" "$OUT" ""
render "claude-opus-5-5" "low"
OUT=$(prompt "next");       has "effort change emits" "$OUT" "effort: low"
render "claude-sonnet-5" "low"
OUT=$(prompt "next");       has "model change emits"  "$OUT" "claude-sonnet-5"

echo "== model without an effort parameter =="
render "claude-haiku-4-5" ""
ck "model kept when effort absent" "$(jq -r .model "$TMPDIR/mallet-calibrate-sess-1.json" 2>/dev/null)" "claude-haiku-4-5"
OUT=$(prompt "next");       has "emits model, effort unknown" "$OUT" "claude-haiku-4-5; effort: unknown"

echo "== fallback to settings when the statusline is not Mallet's =="
echo '{"effortLevel":"high"}' > "$HOME/.claude/settings.json"
OUT=$(prompt "hi" "sess-2"); has "settings fallback" "$OUT" "effort: high (from settings; /effort changes not visible)"
hasnt "no unknown model placeholder" "$OUT" "model: unknown"
OUT=$(prompt "hi" "sess-2"); ck  "fallback silent when unchanged" "$OUT" ""
echo '{"effortLevel":"max"}' > "$CLAUDE_PROJECT_DIR/.claude/settings.local.json"
OUT=$(prompt "hi" "sess-2"); has "project local settings win" "$OUT" "effort: max"

echo "== nothing known: silent =="
rm -f "$HOME/.claude/settings.json" "$CLAUDE_PROJECT_DIR/.claude/settings.local.json"
OUT=$(prompt "hi" "sess-3"); ck "no data, no output" "$OUT" ""

echo "== regex scoring gone =="
OUT=$(prompt "Should we redesign the architecture and evaluate the tradeoff of a migration from scratch?" "sess-3")
hasnt "no task-calibrate reminder" "$OUT" "task-calibrate"

echo "== unsafe session ids are sanitised =="
OUT=$(prompt "hi" "../../evil"); ck "exit ok" "$?" "0"
ck "no file escapes TMPDIR" "$(ls "$SCRATCH" | sort | tr '\n' ' ')" "home repo tmp "

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
