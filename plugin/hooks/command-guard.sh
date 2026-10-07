#!/usr/bin/env bash
# PreToolUse hook on Bash: a narrow safety net for git hook bypasses and
# destructive commands. It denies bypassing git hooks and force-pushing the
# default branch, and asks before other hard-to-undo commands.
#
# Pattern matching on command strings is never complete — quoting, variables,
# and aliases defeat it. This catches the common direct forms and asks rather
# than pretending to judge; it does not replace permission rules or review.
#
# Opt-in per project: acts only when .mallet/command-guard.enabled exists
# (created by the hooks-setup skill).

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
[ -f "$PROJECT_DIR/.mallet/command-guard.enabled" ] || exit 0

INPUT="$(cat)"
[ "$(printf '%s' "$INPUT" | jq -r '.tool_name // empty')" = "Bash" ] || exit 0
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')"
[ -n "$CMD" ] || exit 0

DENY=""; ASK=""
deny() { DENY="${DENY:+$DENY; }$1"; }
ask()  { ASK="${ASK:+$ASK; }$1"; }

default_branch() {
  local b
  b="$(cd "$PROJECT_DIR" && git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null)"
  [ -n "$b" ] && { echo "${b#*/}"; return; }
  if (cd "$PROJECT_DIR" && git show-ref --verify --quiet refs/heads/main 2>/dev/null); then echo main; else echo master; fi
}

# Remove quoted strings across the whole command first, newlines included, so
# text inside a commit message or heredoc-fed string can never look like a
# command. Newlines are parked on \001 because sed works line by line.
# Redirections like 2>&1 and &> are dropped so the split below does not read
# their & as a command separator.
STRIPPED="$(printf '%s' "$CMD" | tr '\n' '\001' | sed -E "s/\"[^\"]*\"//g; s/'[^']*'//g; s/[0-9]*>&[0-9-]*//g; s/&>/>/g" | tr '\001' '\n')"

# A quoted hooksPath override would vanish with the quotes, so check the raw text.
printf '%s' "$CMD" | grep -qiE "(^|[;&|[:space:]])git[^;&|]*[[:space:]](-c[[:space:]]*[\"']?|config[[:space:]]+([^[:space:]]+[[:space:]]+)*[\"']?)core\.hookspath" \
  && deny "redirects git hooks (core.hooksPath)"

SQL_CLIENT=""

# Split into simple commands on ; & | and newlines (portable: tr, not sed \n).
while IFS= read -r SEG; do
  # Drop leading whitespace, environment assignments, and sudo.
  SEG="$(printf '%s' "$SEG" | sed -E 's/^[[:space:]]+//; s/^([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)+//; s/^sudo[[:space:]]+//')"
  [ -n "$SEG" ] || continue

  case "$SEG" in
    git|git[[:space:]]*)
      # Skip git's global options (-C dir, -c key=val, --git-dir dir, --flag) to reach the subcommand.
      REST="$(printf '%s' "$SEG" | sed -E 's/^git//; s/^([[:space:]]+(-[Cc][[:space:]]+[^[:space:]]+|--(git-dir|work-tree|namespace|exec-path|super-prefix|config-env)[[:space:]]+[^-[:space:]][^[:space:]]*|-[^[:space:]]+))*[[:space:]]+//')"
      SUB="${REST%%[[:space:]]*}"
      ARGS=" ${REST#"$SUB"} "
      case "$SUB" in
        commit|push|merge|rebase|am|cherry-pick|revert)
          printf '%s' "$ARGS" | grep -qE -- '[[:space:]]--no-verify[[:space:]]' && deny "skips git hooks (--no-verify)" ;;
      esac
      case "$SUB" in
        commit)
          printf '%s' "$ARGS" | grep -qE '[[:space:]]-[a-zA-Z]*n[a-zA-Z]*[[:space:]]' && deny "skips git hooks (commit -n)" ;;
        push)
          if printf '%s' "$ARGS" | grep -qE -- '[[:space:]](--force|--force-with-lease(=[^[:space:]]*)?|-[a-zA-Z]*f[a-zA-Z]*|\+[^[:space:]]+)[[:space:]]'; then
            DB="$(default_branch)"
            CUR="$(cd "$PROJECT_DIR" && git branch --show-current 2>/dev/null)"
            POS="$(printf '%s' "$ARGS" | tr ' ' '\n' | grep -vE '^(-|$)')"
            NPOS="$(printf '%s\n' "$POS" | grep -c .)"
            if printf '%s\n' "$POS" | sed 's/^+//; s/.*://; s#^refs/heads/##' | grep -qxF "$DB" || { [ "$CUR" = "$DB" ] && [ "$NPOS" -le 1 ]; }; then
              deny "force-pushes the default branch ($DB)"
            else
              ask "force-push rewrites remote history"
            fi
          fi ;;
        reset)    printf '%s' "$ARGS" | grep -qE -- '[[:space:]]--hard[[:space:]]' && ask "git reset --hard discards uncommitted work" ;;
        clean)    printf '%s' "$ARGS" | grep -qE -- '[[:space:]](-[a-zA-Z]*f[a-zA-Z]*|--force)[[:space:]]' && ask "git clean -f deletes untracked files" ;;
        checkout|restore)
          # restore --staged without --worktree only unstages; it discards nothing.
          if printf '%s' "$ARGS" | grep -qE '[[:space:]]\.[[:space:]]' && \
             ! { [ "$SUB" = restore ] && printf '%s' "$ARGS" | grep -qE -- '[[:space:]](--staged|-S)[[:space:]]' && ! printf '%s' "$ARGS" | grep -qE -- '[[:space:]](--worktree|-W)[[:space:]]'; }; then
            ask "discards all working-tree changes"
          fi ;;
        branch)   printf '%s' "$ARGS" | grep -qE -- '[[:space:]](-D|--delete[[:space:]]+--force|--force[[:space:]]+--delete)[[:space:]]' && ask "force-deletes a branch" ;;
        stash)    printf '%s' "$ARGS" | grep -qE '^[[:space:]]+(drop|clear)[[:space:]]' && ask "drops stashed work" ;;
      esac
      ;;
    rm[[:space:]]*)
      # rm with both -r and -f, unless every target is a regenerable build directory.
      FLAGS="$(printf '%s' " $SEG" | grep -oE '[[:space:]](-[a-zA-Z]+|--recursive|--force)' | tr -d ' \n-')"
      case "$FLAGS" in *[rR]*f*|*f*[rR]*|*recursive*force*|*force*recursive*)
        SAFE=1; ANY=0
        set -f   # judge the literal targets, not what a glob expands to here
        for T in ${SEG#rm}; do
          case "$T" in -*) continue ;; esac
          ANY=1
          case "$(basename "$T")" in node_modules|dist|build|.next|out|target|coverage|__pycache__|.cache|.turbo|.pytest_cache) ;; *) SAFE=0 ;; esac
        done
        set +f
        [ "$ANY" = 1 ] && [ "$SAFE" = 1 ] || ask "rm -rf deletes files without recovery"
      ;; esac
      ;;
    psql|psql[[:space:]]*|mysql|mysql[[:space:]]*|mariadb|mariadb[[:space:]]*|sqlcmd|sqlcmd[[:space:]]*|sqlite3|sqlite3[[:space:]]*|clickhouse|clickhouse[[:space:]]*|clickhouse-client|clickhouse-client[[:space:]]*)
      SQL_CLIENT=1 ;;
    kubectl[[:space:]]*)
      printf '%s' "$SEG" | grep -qE '^kubectl([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+delete\b' && ask "kubectl delete removes cluster resources" ;;
    terraform[[:space:]]*)
      printf '%s' "$SEG" | grep -qE '^terraform([[:space:]]+-[^[:space:]]+)*[[:space:]]+destroy\b' && ask "terraform destroy removes infrastructure" ;;
  esac
done < <(printf '%s\n' "$STRIPPED" | tr ';|&' '\n\n\n')

# SQL: a database client runs as a command; the statement may be anywhere
# (quoted -c argument, heredoc, or piped in), so keywords match the full text.
if [ -n "$SQL_CLIENT" ] && printf '%s' "$CMD" | grep -qiE '\b(drop[[:space:]]+(table|database|schema|index|view)|delete[[:space:]]+from|alter[[:space:]]+table[^;]*[[:space:]]drop)\b|\btruncate[[:space:]]+(table[[:space:]]+)?[^[:space:];]'; then
  ask "destructive SQL statement"
fi

# Deny reasons are shown to Claude; ask reasons are shown to the user.
if [ -n "$DENY" ]; then
  jq -n --arg r "[command-guard] Blocked: ${DENY}. Mallet keeps git hooks and the default branch's history intact; if this is genuinely required, ask the user to run it." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
elif [ -n "$ASK" ]; then
  jq -n --arg r "[command-guard] ${ASK}. Check the targets before allowing." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$r}}'
fi
exit 0
