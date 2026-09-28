#!/bin/bash
# Test: merge-settings.sh with the shipped (empty) fragment removes what the
# user-level install registered and nothing else, and is idempotent.
# The real $HOME is never read or written.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
MERGE="$REPO/.claude/merge-settings.sh"
FRAG="$REPO/.claude/settings.fragment.json"

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }

export HOME="$SCRATCH/fake-home"
mkdir -p "$HOME/.claude"
S="$HOME/.claude/settings.json"

ck "shipped fragment is empty" "$(jq -c . "$FRAG")" "{}"

# Shape of a real user-level install: Mallet registrations alongside personal
# config, a user hook, and a user script that merely shares a Mallet file name.
cat > "$S" <<'JSON'
{
  "model": "opus",
  "effortLevel": "xhigh",
  "enabledPlugins": { "slack@claude-plugins-official": true },
  "permissions": { "ask": ["Bash(git push *)"] },
  "statusLine": { "type": "command", "command": "bash \"$HOME/.claude/statusline.sh\"" },
  "hooks": {
    "SessionStart": [
      { "matcher": "startup", "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/session-start.sh\"" }] },
      { "matcher": "compact", "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/post-compact.sh\"" }] },
      { "matcher": "startup", "hooks": [{ "type": "command", "command": "bash ~/scripts/session-start.sh" }] }
    ],
    "UserPromptSubmit": [{ "matcher": "", "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/user-prompt-submit.sh\"" }] }],
    "PreToolUse": [{ "matcher": "Write", "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/write-guard.sh\"" }] }],
    "PostToolUse": [{ "matcher": "Edit", "hooks": [{ "type": "command", "command": "bash \"$HOME/.claude/hooks/typecheck.sh\"" }] }],
    "Stop": [{ "hooks": [{ "type": "command", "command": "~/.claude/notify.sh done", "async": true }] }]
  }
}
JSON

echo "== transition cleanup =="
bash "$MERGE" "$FRAG" >/dev/null 2>&1; ck "exit 0" "$?" "0"
ck "model preserved"          "$(jq -r .model "$S")" "opus"
ck "effortLevel preserved"    "$(jq -r .effortLevel "$S")" "xhigh"
ck "plugins preserved"        "$(jq -r '.enabledPlugins["slack@claude-plugins-official"]' "$S")" "true"
ck "permissions preserved"    "$(jq -r '.permissions.ask[0]' "$S")" "Bash(git push *)"
ck "Mallet hooks removed"     "$(jq '[.. | objects | select(.command?) | .command | select(test("\\.claude/hooks/"))] | length' "$S")" "0"
ck "same-named user hook kept" "$(jq -r '.hooks.SessionStart[0].hooks[0].command' "$S")" "bash ~/scripts/session-start.sh"
ck "Stop hook kept"           "$(jq -r '.hooks.Stop[0].hooks[0].command' "$S")" "~/.claude/notify.sh done"
ck "emptied events dropped"   "$(jq -r '.hooks | keys | join(",")' "$S")" "SessionStart,Stop"
ck "stale statusLine dropped" "$(jq -r '.statusLine // "none"' "$S")" "none"
ck "backup written"           "$(ls "$HOME/.claude/" | grep -c '^settings.json.bak-')" "1"

echo "== idempotency =="
jq -S . "$S" > "$SCRATCH/a1.json"; bash "$MERGE" "$FRAG" >/dev/null 2>&1; jq -S . "$S" > "$SCRATCH/a2.json"
ck "second run changes nothing" "$(diff -q "$SCRATCH/a1.json" "$SCRATCH/a2.json" >/dev/null && echo same)" "same"

echo "== statusLine kept when the Mallet script is still present or not Mallet's =="
echo '{"statusLine":{"type":"command","command":"bash \"$HOME/.claude/statusline.sh\""}}' > "$S"
echo "# user-customised" > "$HOME/.claude/statusline.sh"
bash "$MERGE" "$FRAG" >/dev/null 2>&1
ck "kept while script exists" "$(jq -r '.statusLine.command' "$S")" 'bash "$HOME/.claude/statusline.sh"'
echo '{"statusLine":{"type":"command","command":"echo mine"}}' > "$S"
bash "$MERGE" "$FRAG" >/dev/null 2>&1
ck "user statusLine untouched" "$(jq -r '.statusLine.command' "$S")" "echo mine"

echo "== corrupt-input guard =="
printf '{invalid' > "$S"
bash "$MERGE" "$FRAG" >/dev/null 2>&1; ck "corrupt exits nonzero" "$?" "1"
ck "corrupt file untouched" "$(cat "$S")" "{invalid"

echo "== empty target =="
rm -f "$S"
bash "$MERGE" "$FRAG" >/dev/null 2>&1
ck "creates valid json" "$(jq -e . "$S" >/dev/null 2>&1 && echo ok)" "ok"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
