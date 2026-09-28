---
name: create-pr
description: Invoke when the user says "create PR", "open a PR", "make a pull request", or similar.
---
# Create PR

## 1. Gather the Patch

Detect the default branch from the remote, then diff against it:

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
git diff "$BASE"...HEAD
git log "$BASE"...HEAD --oneline
```

If the branch has not diverged from the base, fall back to `git diff HEAD~1` or `git diff --cached` depending on what is staged.

---

## 2. Generate the PR Summary

Using the patch output, generate a high-level, non-technical summary suitable for internal communication with Product, Support, and Customer-facing teams.

### Output Requirements

- Output must be inside a **single markdown code block**
- Content must be ready to paste directly into a GitHub PR description
- Do not include citations, artificial references, or metadata markers
- Do not include raw diff blocks unless explicitly requested
- Keep tone neutral, concise, and operationally focused
- Length: 2–4 short paragraphs total
- Avoid deep technical implementation detail

### Required Sections (use exactly these H2 headings and icons)

**🔧 What Changed**
Briefly describe what the patch adds, removes, or adjusts in plain language.

**📍 Why It Was Introduced**
Explain the issue, limitation, regression, or edge case that prompted the change. Clarify what previously failed or was missing under certain conditions.

**👀 Potential Customer or Support Impact**
Describe how customers or internal teams might observe changes — including indirect effects such as:
- Long-running sessions
- Retry behavior
- Caching differences
- Background tasks
- Time-sensitive logic
- Logging or monitoring changes

Highlight any potentially surprising runtime behavior.

**✅ Risk and Mitigation**
Confirm testing and validation performed. Mention:
- Edge cases considered
- Feature flags (if any)
- Rollout dependencies
- Observability updates (logs, metrics, alerts)
- Backward compatibility considerations

### Closing Line

End the summary with the exact line:

> This summary was AI-generated and may contain errors or omissions.

---

## 3. Behavioral Constraints

- Prioritize clarity over completeness
- Do not speculate beyond what the patch reasonably implies
- If something cannot be inferred confidently, state that explicitly
- Maintain customer trust and operational confidence as the framing principle
- Do not add unnecessary preamble or explanation outside the markdown block

---

## 4. Push the Branch

Check whether the branch is on origin:

```bash
git rev-parse --abbrev-ref '@{u}'
```

- If the command fails (no upstream), ask the user: "Branch is not on origin. Push with `git push -u origin HEAD`?" Wait for explicit confirmation before pushing.
- If it succeeds, run `git status -sb` to check for unpushed commits. If the branch is ahead of upstream, ask before pushing.

Never push without confirmation.

---

## 5. Open the PR

After presenting the summary for review, create the PR using `gh pr create`, passing the generated summary as the body:

```bash
gh pr create --title "<imperative title>" --body "$(cat <<'EOF'
<generated summary here>
EOF
)"
```

Wait for the user to confirm or adjust the summary before running this command.
