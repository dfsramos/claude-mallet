#!/bin/bash
# Resolve where feature plans are written, and whether they are committed.
#
# Prints three lines on stdout:
#   DEFAULT=<default branch>
#   PLANS_DIR=<absolute directory holding .mallet/features/>
#   COMMIT=yes|no
#
# Plans are committed to the default branch so they are visible from every
# branch. When the session is on another branch, they are written through a
# worktree of the default branch that belongs to this repository alone, kept
# inside its .git directory: never shared between repositories (a fixed
# /tmp path once sent one repo's plan commits into another), invisible to
# `git status`, and not wiped by a /tmp cleanup.
#
# If .mallet/ is ignored, the user has chosen not to track it: plans stay in
# the current checkout and nothing is committed.
set -uo pipefail

TOP=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "not a git repository" >&2; exit 1; }
cd "$TOP" || exit 1

DEFAULT=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
if [ -z "$DEFAULT" ]; then
  if git show-ref --verify --quiet refs/heads/main; then DEFAULT=main
  elif git show-ref --verify --quiet refs/heads/master; then DEFAULT=master
  else DEFAULT=$(git branch --show-current)
  fi
fi
echo "DEFAULT=$DEFAULT"

if git check-ignore -q .mallet/features/probe; then
  echo "PLANS_DIR=$TOP"; echo "COMMIT=no"; exit 0
fi

if [ "$(git branch --show-current)" = "$DEFAULT" ]; then
  echo "PLANS_DIR=$TOP"; echo "COMMIT=yes"; exit 0
fi

# Git allows a branch in one worktree only; reuse whichever already has it.
PLANS=$(git worktree list --porcelain | awk -v want="branch refs/heads/$DEFAULT" '
  /^worktree / { path = substr($0, 10) }
  $0 == want   { print path; exit }')

if [ -z "$PLANS" ] || [ ! -d "$PLANS" ]; then
  PLANS="$(git rev-parse --path-format=absolute --git-common-dir)/mallet-plans"
  # A registration left behind by a deleted directory blocks `add`; -f is used
  # only for that case and only for this script's own path.
  FORCE=""
  git worktree list --porcelain | grep -qxF "worktree $PLANS" && [ ! -d "$PLANS" ] && FORCE="-f"
  if ! git worktree add -q $FORCE "$PLANS" "$DEFAULT" >&2; then
    echo "could not create the plans worktree at $PLANS" >&2; exit 1
  fi
fi

if git -C "$PLANS" rev-parse -q --verify '@{u}' >/dev/null 2>&1; then
  git -C "$PLANS" pull -q --ff-only >&2 || echo "warning: could not fast-forward $DEFAULT in $PLANS" >&2
fi

echo "PLANS_DIR=$PLANS"; echo "COMMIT=yes"
