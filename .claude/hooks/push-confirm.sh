#!/bin/bash
# push-confirm.sh — PreToolUse hook that warns Claude before any git push runs via Bash.
# Advisory only: always exits 0 so Claude can proceed after verifying intent.

input=$(cat)

tool_name=$(printf '%s' "$input" | jq -r '.tool_name')

if [ "$tool_name" != "Bash" ]; then
  exit 0
fi

command=$(printf '%s' "$input" | jq -r '.tool_input.command')

if printf '%s' "$command" | grep -qE '(^|[;&|]\s*)git\s+push(\s|$)'; then
  printf '[push-confirm] WARNING: The following command contains git push:\n\n  %s\n\nVerify this push was explicitly requested by the user before proceeding.\n' "$command"
fi

exit 0
