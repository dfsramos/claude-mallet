#!/bin/bash
# Test: plan-feature's plans-worktree.sh resolves where plans are written and
# committed — per repo, on the detected default branch, never across repos.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PW="$REPO/plugin/skills/plan-feature/plans-worktree.sh"
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
# Isolate from the machine's global git config (e.g. a global .mallet/ ignore).
export XDG_CONFIG_HOME="$SCRATCH/xdg" GIT_CONFIG_GLOBAL=/dev/null GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
val() { echo "$1" | sed -n "s/^$2=//p"; }
mkrepo() { # $1 dir $2 default branch
  git init -q -b "$2" "$1" && git -C "$1" commit -q --allow-empty -m init
}
plan_commit() { # $1 plans dir $2 slug — mirrors the skill's commit step
  mkdir -p "$1/.mallet/features/$2" && echo "# $2" > "$1/.mallet/features/$2/plan.md"
  git -C "$1" add ".mallet/features/$2/" && git -C "$1" commit -q -m "Add feature plan: $2." -- ".mallet/features/$2/"
}

[ -f "$PW" ] || { echo "  FAIL plans-worktree.sh missing"; echo "pass=0 fail=1"; exit 1; }

echo "== on the default branch: current checkout =="
mkrepo "$SCRATCH/a" master
OUT=$(cd "$SCRATCH/a" && bash "$PW"); ck "exit 0" "$?" "0"
ck "default detected" "$(val "$OUT" DEFAULT)" "master"
ck "plans in checkout" "$(val "$OUT" PLANS_DIR)" "$(cd "$SCRATCH/a" && pwd -P)"
ck "commit" "$(val "$OUT" COMMIT)" "yes"
ck "no worktree added" "$(git -C "$SCRATCH/a" worktree list | wc -l | tr -d ' ')" "1"

echo "== on a feature branch: per-repo worktree on the default branch =="
git -C "$SCRATCH/a" checkout -q -b feat
OUT=$(cd "$SCRATCH/a" && bash "$PW")
PA=$(val "$OUT" PLANS_DIR)
ck "worktree inside .git" "$PA" "$(cd "$SCRATCH/a" && pwd -P)/.git/mallet-plans"
ck "worktree on master"   "$(git -C "$PA" branch --show-current)" "master"
ck "invisible to status"  "$(git -C "$SCRATCH/a" status --porcelain | wc -l | tr -d ' ')" "0"
plan_commit "$PA" a-plan
ck "plan committed on a's master" "$(git -C "$SCRATCH/a" log --format=%s -1 master)" "Add feature plan: a-plan."
ck "feature branch untouched"     "$(git -C "$SCRATCH/a" log --format=%s -1 feat)" "init"
OUT2=$(cd "$SCRATCH/a" && bash "$PW")
ck "re-run reuses the worktree" "$(val "$OUT2" PLANS_DIR)" "$PA"

echo "== two repos never share a plans directory =="
mkrepo "$SCRATCH/b" master; git -C "$SCRATCH/b" checkout -q -b feat
PB=$(val "$(cd "$SCRATCH/b" && bash "$PW")" PLANS_DIR)
ck "distinct dirs" "$([ "$PA" != "$PB" ] && echo yes)" "yes"
plan_commit "$PB" b-plan
ck "b's plan on b's master"  "$(git -C "$SCRATCH/b" log --format=%s -1 master)" "Add feature plan: b-plan."
ck "a's master unaffected"   "$(git -C "$SCRATCH/a" log --format=%s -1 master)" "Add feature plan: a-plan."

echo "== default branch detection =="
mkrepo "$SCRATCH/m" main; git -C "$SCRATCH/m" checkout -q -b feat
ck "main detected" "$(val "$(cd "$SCRATCH/m" && bash "$PW")" DEFAULT)" "main"
mkrepo "$SCRATCH/origin" trunk; git -C "$SCRATCH/origin" branch -q master
git clone -q "$SCRATCH/origin" "$SCRATCH/clone" && git -C "$SCRATCH/clone" checkout -q -b feat
OUT=$(cd "$SCRATCH/clone" && bash "$PW")
ck "origin/HEAD wins over a local master" "$(val "$OUT" DEFAULT)" "trunk"
ck "fast-forwardable upstream pulled" "$(git -C "$(val "$OUT" PLANS_DIR)" status -sb | head -1 | grep -c behind)" "0"

echo "== .mallet/ ignored: local plans, no commits =="
mkrepo "$SCRATCH/i" master; echo ".mallet/" > "$SCRATCH/i/.gitignore"
git -C "$SCRATCH/i" add .gitignore && git -C "$SCRATCH/i" commit -q -m ignore && git -C "$SCRATCH/i" checkout -q -b feat
OUT=$(cd "$SCRATCH/i" && bash "$PW")
ck "commit no"            "$(val "$OUT" COMMIT)" "no"
ck "plans in checkout"    "$(val "$OUT" PLANS_DIR)" "$(cd "$SCRATCH/i" && pwd -P)"
ck "no worktree added"    "$(git -C "$SCRATCH/i" worktree list | wc -l | tr -d ' ')" "1"

echo "== default branch already checked out elsewhere: reuse it =="
mkrepo "$SCRATCH/w" master; git -C "$SCRATCH/w" checkout -q -b feat
git -C "$SCRATCH/w" worktree add -q "$SCRATCH/w-master" master
ck "reuses existing worktree" "$(val "$(cd "$SCRATCH/w" && bash "$PW")" PLANS_DIR)" "$(cd "$SCRATCH/w-master" && pwd -P)"

echo "== stale registration of our own worktree is recreated =="
rm -rf "$PA"
OUT=$(cd "$SCRATCH/a" && bash "$PW"); ck "exit 0" "$?" "0"
ck "recreated" "$(git -C "$(val "$OUT" PLANS_DIR)" branch --show-current)" "master"

echo "== detached HEAD with no resolvable default branch fails loudly =="
mkrepo "$SCRATCH/d" trunk; git -C "$SCRATCH/d" checkout -q --detach
OUT=$(cd "$SCRATCH/d" && bash "$PW" 2>/dev/null); ck "exit 1" "$?" "1"
ck "no COMMIT line" "$(val "$OUT" COMMIT)" ""

echo "== detached HEAD with a resolvable default uses the worktree =="
mkrepo "$SCRATCH/e" master; git -C "$SCRATCH/e" checkout -q --detach
OUT=$(cd "$SCRATCH/e" && bash "$PW")
ck "worktree on master" "$(git -C "$(val "$OUT" PLANS_DIR)" branch --show-current)" "master"

echo "== called from inside a linked worktree =="
mkrepo "$SCRATCH/l" master; git -C "$SCRATCH/l" branch -q feat
git -C "$SCRATCH/l" checkout -q --detach; git -C "$SCRATCH/l" worktree add -q "$SCRATCH/l-feat" feat
OUT=$(cd "$SCRATCH/l-feat" && bash "$PW")
ck "shares the main repo's plans worktree" "$(val "$OUT" PLANS_DIR)" "$(cd "$SCRATCH/l" && pwd -P)/.git/mallet-plans"

echo "== path with spaces =="
mkrepo "$SCRATCH/sp ace" master; git -C "$SCRATCH/sp ace" checkout -q -b feat
OUT=$(cd "$SCRATCH/sp ace" && bash "$PW"); ck "exit 0" "$?" "0"
plan_commit "$(val "$OUT" PLANS_DIR)" s-plan
ck "committed on master" "$(git -C "$SCRATCH/sp ace" log --format=%s -1 master)" "Add feature plan: s-plan."

echo "== outside a repository =="
mkdir -p "$SCRATCH/plain"; (cd "$SCRATCH/plain" && bash "$PW" >/dev/null 2>&1); ck "exit 1" "$?" "1"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
