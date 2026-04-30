---
name: preflight
description: Invoke when the user runs /preflight, or when environment issues are suspected before starting git-heavy work (stale worktrees, Git LFS hooks blocking worktree creation, WSL2 quirks).
---
# Preflight Environment Check

Run these checks in sequence. Report all results in a single concise status block at the end. Output `[ok]`, `[warn]`, or `[block]` per check.

---

## 1. Worktree health

Run: `git worktree list --porcelain`

Flag:
- Entries where `gitdir` contains WSL paths (`/mnt/`, `//wsl.localhost/`, `\\wsl$`) — these are stale Windows-session worktrees that silently break git commands
- Entries where the listed worktree path no longer exists on disk (`[ -d <path> ]`)

If stale entries are found, run `git worktree prune --dry-run` and include what would be removed in the report. Do **not** prune without explicit user confirmation.

---

## 2. LFS hook check

Run: `cat .git/hooks/post-checkout 2>/dev/null | head -5`

Flag if the hook exists and contains `git lfs` — this hook runs on every `git worktree add` and will fail when LFS objects are missing, blocking worktree creation entirely.

If flagged, note the workaround: `git worktree add --no-checkout <path> <branch>` bypasses the hook.

---

## 3. Working tree state

Run: `git status --short && git branch --show-current`

Report: current branch name, and whether the working tree is clean or has staged/unstaged/untracked changes.

---

## 4. Status summary

Output one line per check using these prefixes:

- `[ok]` — check passed, no action needed
- `[warn] <detail>` — issue found, non-blocking but worth noting
- `[block] <detail>` — will cause failures if not resolved before proceeding

If all checks pass, output: `preflight ok — no issues found`.
