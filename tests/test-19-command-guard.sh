#!/bin/bash
# Test: command-guard.sh denies git hook bypasses and force-pushing the default
# branch, asks before other destructive commands, and stays silent otherwise or
# without the opt-in marker.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }

export HOME="$SCRATCH/home"; mkdir -p "$HOME"
export CLAUDE_PROJECT_DIR="$SCRATCH/repo"
mkdir -p "$CLAUDE_PROJECT_DIR/.mallet"
git -C "$CLAUDE_PROJECT_DIR" init -q -b master
git -C "$CLAUDE_PROJECT_DIR" -c user.email=t@t -c user.name=t commit -q --allow-empty -m init
touch "$CLAUDE_PROJECT_DIR/.mallet/command-guard.enabled"

decide() { # $1 command -> deny | ask | none
  local out
  out=$(jq -n --arg c "$1" '{tool_name:"Bash", tool_input:{command:$c}}' | bash "$REPO/plugin/hooks/command-guard.sh")
  [ -n "$out" ] && echo "$out" | jq -r .hookSpecificOutput.permissionDecision || echo none
}

echo "== deny =="
ck "commit --no-verify"           "$(decide 'git commit --no-verify -m x')" "deny"
ck "commit -an"                   "$(decide 'git commit -an -m x')" "deny"
ck "push --no-verify"             "$(decide 'git push --no-verify origin feature')" "deny"
ck "core.hooksPath override"      "$(decide 'git -c core.hooksPath=/dev/null commit -m x')" "deny"
ck "force-push default by name"   "$(decide 'git push --force origin master')" "deny"
ck "force-push from default"      "$(decide 'git push -f')" "deny"
ck "deny inside a chain"          "$(decide 'npm test && git commit --no-verify -m x')" "deny"
ck "quoted hooksPath override"    "$(decide 'git -c "core.hooksPath=/dev/null" commit -m x')" "deny"
ck "--git-dir before subcommand"  "$(decide 'git --git-dir .git commit --no-verify -m x')" "deny"
ck "force-push full ref"          "$(decide 'git push -f origin HEAD:refs/heads/master')" "deny"
ck "deny behind env assignment"   "$(decide 'FOO=1 git commit --no-verify -m x')" "deny"

echo "== ask =="
git -C "$CLAUDE_PROJECT_DIR" checkout -q -b feature
ck "force-push feature branch"    "$(decide 'git push --force-with-lease origin feature')" "ask"
ck "reset --hard"                 "$(decide 'git reset --hard HEAD~1')" "ask"
ck "clean -fd"                    "$(decide 'git clean -fd')" "ask"
ck "checkout -- ."                "$(decide 'git checkout -- .')" "ask"
ck "branch -D"                    "$(decide 'git branch -D old')" "ask"
ck "rm -rf src"                   "$(decide 'rm -rf src')" "ask"
ck "rm -r -f docs"                "$(decide 'rm -r -f docs')" "ask"
ck "psql drop table"              "$(decide 'psql -c "DROP TABLE users"')" "ask"
ck "sqlcmd delete from"           "$(decide 'sqlcmd -Q "delete from orders where 1=1"')" "ask"
ck "kubectl delete"               "$(decide 'kubectl delete pod web-1')" "ask"
ck "TRUNCATE users"               "$(decide 'psql -c "TRUNCATE users"')" "ask"
ck "TRUNCATE TABLE users;"        "$(decide 'psql -c "TRUNCATE TABLE users;"')" "ask"
ck "sudo terraform destroy"       "$(decide 'sudo terraform destroy -auto-approve')" "ask"
ck "SQL after ; inside quotes"    "$(decide 'psql -c "select 1; drop table x"')" "ask"
ck "SQL fed by heredoc"           "$(decide "$(printf 'psql app <<EOF\ndrop table x;\nEOF')")" "ask"
ck "SQL piped into client"        "$(decide 'echo "delete from t" | mysql db')" "ask"
ck "rm -rf glob judged literally" "$(cd "$SCRATCH" && mkdir -p g/dist && cd g && decide 'rm -rf *')" "ask"

echo "== allow =="
ck "plain commit"                 "$(decide 'git commit -m "add -n flag docs"')" "none"
ck "normal push"                  "$(decide 'git push origin feature')" "none"
ck "rm -rf node_modules dist"     "$(decide 'rm -rf node_modules dist')" "none"
ck "rm single file"               "$(decide 'rm notes.txt')" "none"
ck "psql select"                  "$(decide 'psql -c "select * from users"')" "none"
ck "git status"                   "$(decide 'git status --porcelain')" "none"
ck "heredoc commit message"       "$(decide "$(printf 'git commit -m "$(cat <<%sEOF%s\nfix\n\ngit commit --no-verify is blocked\nEOF\n)"' "'" "'")")" "none"
ck "multi-line commit message"    "$(decide "$(printf 'git commit -m "title\n\ngit push --force is now denied"')")" "none"
ck "SQL words in commit message"  "$(decide 'git commit -m "fix psql truncate handling"')" "none"
ck "git log -n is not commit -n"  "$(decide 'git log --grep commit -n 5')" "none"
ck "rm build dir with 2>&1"       "$(decide 'rm -rf node_modules 2>&1')" "none"
ck "restore --staged ."           "$(decide 'git restore --staged .')" "none"
ck "client word only as a path"   "$(decide 'git add clickhouse && git commit -m "add truncate table handling"')" "none"
ck "terraform plan -destroy"      "$(decide 'terraform plan -destroy')" "none"

echo "== opt-in =="
rm "$CLAUDE_PROJECT_DIR/.mallet/command-guard.enabled"
ck "no marker, no decision"       "$(decide 'git commit --no-verify -m x')" "none"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
