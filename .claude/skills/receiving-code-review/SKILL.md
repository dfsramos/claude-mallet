---
name: receiving-code-review
description: Invoke when a code review has been returned (from Clifford, a human reviewer, or any review output) and you need to process and act on the feedback.
---
# Receiving Code Review

When a code review arrives, process it methodically. Performative acceptance ("You're absolutely right — I'll fix that immediately!") is not a response; it is noise. Technical correctness matters more than social comfort.

---

## 1. Understand Completely

Read the full review before acting on any single item. Classify every issue:
- **Blocking:** must be resolved before the work is mergeable
- **Non-blocking:** should be addressed but does not block

Do not begin fixing until you have read and classified every item.

---

## 2. Verify Against Reality

Before accepting any feedback as correct, verify it against the actual code:

- Does the flagged file and line match what is in the codebase right now?
- Does the reviewer's described behaviour match what the code actually does?
- Does the suggested fix account for the full call chain, not just the local site?

A reviewer may be working from a diff view, a stale mental model, or incomplete context. Technical correctness is the standard — not reviewer seniority or confidence.

---

## 3. Evaluate Technically

For each blocking issue, apply these tests before implementing the fix:

| Test | Question |
|------|----------|
| Correctness | Does accepting this feedback produce code that is more correct? |
| Functionality | Does it break existing working behaviour? |
| Context | Does the reviewer have full context, or is the flag based on a local view? |
| Scope | Does the suggestion go beyond the spec (YAGNI)? |
| Architecture | Does it conflict with established patterns in this codebase? |

If a suggestion fails any test, do not silently comply — surface the conflict with a specific technical explanation.

---

## 4. Respond Factually

When addressing review feedback (in a PR comment, to the orchestrator, or to the user):

- Describe the actual fix: "Changed the guard condition at `auth.ts:42` from `=== null` to `== null` to handle undefined" — not "Great catch, fixed!"
- When pushing back, state the technical reason: "This would break the existing `SessionStore` contract at `store.ts:15` — the interface requires synchronous return"
- Do not use performative language: "Absolutely", "Great point", "You're right", "Of course"

---

## 5. Implement Methodically

For each blocking issue that passes the technical evaluation:

1. Locate the exact site (file + line)
2. Understand why the issue exists before changing it
3. Apply a targeted fix — do not refactor surrounding code unless it is the direct cause
4. Confirm the fix resolves the flagged issue without introducing new problems
5. Note the change in your Handoff so the next reviewer has full context

Batch all blocking fixes before requesting re-review. Do not re-submit for review after each individual fix.

---

## Non-blocking Issues

Non-blocking issues do not block merge. Address them if they are clearly correct and low-risk. Defer them if they require design decisions or touch code outside the current scope — note them for a follow-up task. Never silently discard them.

---

## Rationalizations to Reject

- "The reviewer is senior so they must be right" — seniority does not override technical correctness
- "It would be awkward to push back" — an incorrect fix shipped under social pressure is still wrong code
- "I'll just accept it to keep things moving" — accepting a wrong suggestion adds technical debt; a one-sentence technical disagreement costs less
