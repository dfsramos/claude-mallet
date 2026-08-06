#!/bin/bash
# Test: merge-settings.sh preserves personal config and is idempotent.
# Portable: resolves the repo from this script's location and uses a temp dir.
# The real $HOME is never read or written.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
MERGE="$REPO/.claude/merge-settings.sh"
FRAG="$REPO/.claude/settings.fragment.json"

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }

export HOME="$SCRATCH/fake-home"
rm -rf "$HOME"; mkdir -p "$HOME/.claude"

# Synthetic fixture mirroring the shape of a real user settings.json: personal
# scalars, a plugin map, and two non-Mallet hooks that must survive the merge.
cat > "$HOME/.claude/settings.json" <<'JSON'
{
  "model": "opus",
  "effortLevel": "xhigh",
  "enabledPlugins": { "slack@claude-plugins-official": true },
  "skipWorkflowUsageWarning": true,
  "statusLine": { "type": "command", "command": "echo user-custom-statusline" },
  "hooks": {
    "Stop": [{ "hooks": [{ "type": "command", "command": "~/.claude/notify.sh done", "async": true }] }],
    "Notification": [{ "hooks": [{ "type": "command", "command": "~/.claude/notify.sh alert", "async": true }] }]
  }
}
JSON

echo "== run 1 =="
bash "$MERGE" "$FRAG" >/dev/null 2>&1 || { echo "  merge-settings.sh failed/absent"; }
S="$HOME/.claude/settings.json"

ck "model preserved"        "$(jq -r '.model // "MISSING"' "$S" 2>/dev/null)" "opus"
ck "effortLevel preserved"  "$(jq -r '.effortLevel // "MISSING"' "$S" 2>/dev/null)" "xhigh"
ck "enabledPlugins kept"    "$(jq -r '.enabledPlugins["slack@claude-plugins-official"] // "MISSING"' "$S" 2>/dev/null)" "true"
ck "skipWorkflowWarn kept"  "$(jq -r '.skipWorkflowUsageWarning // "MISSING"' "$S" 2>/dev/null)" "true"
ck "Stop hook survives"     "$(jq '[.hooks.Stop[]?.hooks[]? | select(.command|test("notify.sh"))] | length' "$S" 2>/dev/null)" "1"
ck "Notification survives"  "$(jq '[.hooks.Notification[]?.hooks[]? | select(.command|test("notify.sh"))] | length' "$S" 2>/dev/null)" "1"
ck "SessionStart added"     "$(jq '[.hooks.SessionStart[]?.hooks[]? | select(.command|test("session-start.sh"))] | length' "$S" 2>/dev/null)" "1"
ck "UserPromptSubmit added" "$(jq '[.hooks.UserPromptSubmit[]?.hooks[]? | select(.command|test("user-prompt-submit.sh"))] | length' "$S" 2>/dev/null)" "1"
ck "PreCompact added"       "$(jq '[.hooks.PreCompact[]?.hooks[]? | select(.command|test("pre-compact.sh"))] | length' "$S" 2>/dev/null)" "1"
ck "PreToolUse added"       "$(jq '[.hooks.PreToolUse[]?.hooks[]? | select(.command|test("write-guard.sh"))] | length' "$S" 2>/dev/null)" "1"
ck "statusLine is Mallet"   "$(jq -r '.statusLine.command // "MISSING" | test("statusline.sh") | tostring' "$S" 2>/dev/null)" "true"
ck "hook paths use HOME"    "$(jq '[.. | objects | select(.command?) | .command | select(test("CLAUDE_PROJECT_DIR"))] | length' "$S" 2>/dev/null)" "0"

echo "== run 2 (idempotency) =="
jq -S . "$S" > "$SCRATCH/after1.json" 2>/dev/null
bash "$MERGE" "$FRAG" >/dev/null 2>&1
jq -S . "$S" > "$SCRATCH/after2.json" 2>/dev/null
if diff -q "$SCRATCH/after1.json" "$SCRATCH/after2.json" >/dev/null 2>&1; then
  echo "  PASS idempotent"; pass=$((pass+1))
else
  echo "  FAIL idempotent"; diff "$SCRATCH/after1.json" "$SCRATCH/after2.json" | head -20; fail=$((fail+1))
fi
ck "no duplicate SessionStart" "$(jq '[.hooks.SessionStart[]?.hooks[]?] | length' "$S" 2>/dev/null)" "1"

echo "== corrupt-input guard =="
printf '{invalid' > "$HOME/.claude/settings.json"
bash "$MERGE" "$FRAG" >/dev/null 2>&1
ck "corrupt exits nonzero" "$?" "1"
ck "corrupt file untouched" "$(cat "$HOME/.claude/settings.json")" "{invalid"

echo "== empty-target case =="
rm -rf "$HOME"; mkdir -p "$HOME/.claude"
bash "$MERGE" "$FRAG" >/dev/null 2>&1
ck "created valid json" "$(jq -e . "$HOME/.claude/settings.json" >/dev/null 2>&1 && echo ok)" "ok"
ck "fresh has 4 hook events" "$(jq '.hooks | keys | length' "$HOME/.claude/settings.json" 2>/dev/null)" "4"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
