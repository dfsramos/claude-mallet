#!/bin/bash
# Test: session-start.sh injects no legacy memory file, flags a legacy
# per-project install on startup only, announces neither project skills nor an
# open mission any more, and offers Git conventions where a repo states none.
# Portable: resolves the repo from this script's location and uses a temp dir.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
H="$REPO/plugin/hooks"
FIX="$SCRATCH/fix02"

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has() { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }
hasnt() { if echo "$2" | grep -q "$3"; then echo "  FAIL $1 (unexpected '$3')"; fail=$((fail+1)); else echo "  PASS $1"; pass=$((pass+1)); fi; }

# Isolated fake HOME so the real ~/.claude is never read or written.
export HOME="$FIX/home"
export CLAUDE_PROJECT_DIR="$FIX/repo"
rm -rf "$FIX"; mkdir -p "$HOME/.claude" "$CLAUDE_PROJECT_DIR/.mallet"

echo "MEMORY-SENTINEL" > "$CLAUDE_PROJECT_DIR/.mallet/memory.md"
echo "report" > "$CLAUDE_PROJECT_DIR/.mallet/discovery-2026-01-01.md"
# No repo/version keys -> session-start must not attempt any network call.
echo '{"installed_at":"2026-01-01"}' > "$HOME/.claude/framework.json"

echo "== session-start.sh =="
OUT=$(bash "$H/session-start.sh" </dev/null 2>&1); ck "exit 0" "$?" "0"
hasnt "no .mallet/memory.md injection (auto memory replaces it)" "$OUT" "MEMORY-SENTINEL"

echo "== session-start.sh: legacy notice =="
ss() { echo "{\"source\":\"$1\"}" | bash "$H/session-start.sh" 2>&1; }
mkdir -p "$CLAUDE_PROJECT_DIR/.claude"; echo '{}' > "$CLAUDE_PROJECT_DIR/.claude/framework.json"
has   "startup: legacy notice" "$(ss startup)" "Legacy Mallet Install"
hasnt "clear: no legacy notice (startup only)" "$(ss clear)" "Legacy Mallet Install"
NOJQ="$SCRATCH/nojq"; mkdir -p "$NOJQ"
for b in bash sed tr grep head cut ls dirname basename cat cmp cp mv mkdir pwd; do ln -sf "$(command -v $b)" "$NOJQ/$b"; done
hasnt "no jq: clear still skips the legacy notice" "$(echo '{"source":"clear"}' | PATH="$NOJQ" bash "$H/session-start.sh" 2>&1)" "Legacy Mallet Install"
rm -rf "$CLAUDE_PROJECT_DIR/.claude"

echo "== session-start.sh: retired notices =="
# Project skills live in .claude/skills/, which Claude Code loads itself, and
# open work in auto memory; leftovers from earlier versions get no notice.
mkdir -p "$CLAUDE_PROJECT_DIR/.mallet/missions" "$CLAUDE_PROJECT_DIR/.mallet/skills/deploy-app"
printf '# Mission: Ship the widget\n\n## Pending\n- [ ] one\n' > "$CLAUDE_PROJECT_DIR/.mallet/missions/active.md"
printf -- '---\nname: deploy-app\ndescription: Invoke when the user says "deploy".\n---\n' > "$CLAUDE_PROJECT_DIR/.mallet/skills/deploy-app/SKILL.md"
for s in startup clear compact; do
  OUT=$(ss "$s")
  hasnt "$s: no open-mission notice" "$OUT" "Open Mission"
  hasnt "$s: no project-skills listing" "$OUT" "deploy-app"
done
rm -rf "$CLAUDE_PROJECT_DIR/.mallet/missions" "$CLAUDE_PROJECT_DIR/.mallet/skills"

echo "== session-start.sh with .mallet absent =="
rm -rf "$CLAUDE_PROJECT_DIR/.mallet"
OUT=$(bash "$H/session-start.sh" </dev/null 2>&1); ck "exit 0" "$?" "0"
ck "emits nothing" "$(echo -n "$OUT" | wc -c)" "0"

echo "== session-start.sh: Git conventions =="
G="$FIX/gitrepo"; mkdir -p "$G/sub"; git -C "$G" -c init.defaultBranch=main init -q
export CLAUDE_PROJECT_DIR="$G"
gc() { echo "{\"source\":\"$1\"}" | CLAUDE_PLUGIN_ROOT="$REPO/plugin" bash "$H/session-start.sh" 2>&1; }
OUT=$(gc startup)
has   "git repo without rules: notice" "$OUT" "Git Conventions"
has   "notice carries the default rules" "$OUT" 'b/<description>'
hasnt "notice omits the marker comment" "$OUT" "mallet:git-conventions -->"
has   "notice names the rule file to copy" "$OUT" "$REPO/plugin/rules/git.md"
has   "clear: notice" "$(gc clear)" "Git Conventions"
has   "compact: notice (compaction drops it)" "$(gc compact)" "Git Conventions"
hasnt "resume: no notice" "$(gc resume)" "Git Conventions"
export CLAUDE_PROJECT_DIR="$FIX/repo"
hasnt "not a git repo: no notice" "$(gc startup)" "Git Conventions"
export CLAUDE_PROJECT_DIR="$G"
printf '# Project\n\n## Git workflow\n- commit to main\n' > "$G/CLAUDE.md"
hasnt "CLAUDE.md with a Git heading: no notice" "$(gc startup)" "Git Conventions"
printf '# Project\n\n## Digital assets\n\n## GitHub Actions\n' > "$G/CLAUDE.md"
has   "heading must name git as a word" "$(gc startup)" "Git Conventions"
rm "$G/CLAUDE.md"
mkdir -p "$G/.claude/rules/team"; cp "$REPO/plugin/rules/git.md" "$G/.claude/rules/team/git.md"
hasnt "copied rule file (nested) found by its marker" "$(gc startup)" "Git Conventions"
rm -rf "$G/.claude"
printf '## Git\n' > "$G/CLAUDE.local.md"
hasnt "CLAUDE.local.md counts" "$(gc startup)" "Git Conventions"
rm "$G/CLAUDE.local.md"
printf '## Git\n' > "$G/CLAUDE.md"; export CLAUDE_PROJECT_DIR="$G/sub"
hasnt "session in a subdirectory finds the parent CLAUDE.md" "$(gc startup)" "Git Conventions"
rm "$G/CLAUDE.md"; export CLAUDE_PROJECT_DIR="$G"
mkdir -p "$HOME/.claude/rules"; printf '## Git conventions\n' > "$HOME/.claude/rules/git.md"
hasnt "user-level rules count" "$(gc startup)" "Git Conventions"
rm -rf "$HOME/.claude/rules"
has   "rules gone again: notice is back" "$(gc startup)" "Git Conventions"
hasnt "no git on PATH: silent" "$(echo '{"source":"startup"}' | PATH="$NOJQ" CLAUDE_PLUGIN_ROOT="$REPO/plugin" bash "$H/session-start.sh" 2>&1)" "Git Conventions"
export CLAUDE_PROJECT_DIR="$FIX/repo"

echo "== hooks.json =="
ck "removed hooks gone" "$(ls "$H" | grep -cE 'push-confirm|explore-redirect|user-prompt-submit|write-guard|command-guard|typecheck')" "0"
ck "only SessionStart hooks are registered" "$(jq -r '.hooks | keys | join(",")' "$H/hooks.json")" "SessionStart"
ck "every registered script exists" "$(jq -r '.hooks[][].hooks[].command' "$H/hooks.json" | sed 's/.*hooks\/\([a-z-]*\.sh\).*/\1/' | while read -r f; do [ -f "$H/$f" ] || echo "missing $f"; done)" ""

echo "== statusline renders without framework.json =="
OUT=$(printf '{"workspace":{"project_dir":"%s"},"cost":{"total_cost_usd":0.5}}' "$CLAUDE_PROJECT_DIR" | bash "$REPO/plugin/statusline/statusline.sh" 2>&1)
has "renders cost" "$OUT" "0.5000"

echo "== no stale path references =="
ck "hooks clean" "$(grep -rln '\.claude/project' "$H" "$REPO/plugin/statusline/statusline.sh" 2>/dev/null | wc -l)" "0"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
