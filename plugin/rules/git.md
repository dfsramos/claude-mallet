<!-- mallet:git-conventions -->
# Git conventions

- Branch off the default branch for each task, or use a worktree. Never commit to the default branch directly.
- Name branches `b/<description>` for bug fixes and `f/<description>` for everything else. Never reuse a branch from an earlier session.
- Commit, open a PR, then switch back to the default branch. Never merge a PR without explicit instruction.
- A commit message is a one-line subject with no body: imperative verb, capital first letter, ending with a period, e.g. `Add password reset email template.` Trailer lines such as `Co-Authored-By` go below the subject.
