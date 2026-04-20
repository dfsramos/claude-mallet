---
name: systematic-debugging
description: Invoke when debugging an error, investigating unexpected behaviour, or fixing something that isn't working. Also when a previous fix attempt has failed or made things worse.
---
# Systematic Debugging

**Root cause must be established before any fix is attempted.** Do not make changes speculatively.

---

## 1. Root Cause Investigation

Before touching any code:

- Read the full error message and stack trace — note the exact file, line, and error type
- Reproduce the failure consistently; if it cannot be reproduced, do not proceed to fix
- Review recent changes (`git log`, `git diff`) for anything that correlates with the symptom
- Add targeted diagnostic instrumentation at component boundaries to confirm assumptions

Do not proceed to step 2 until the failure is reproducible and the error origin is confirmed.

---

## 2. Pattern Analysis

- Find the closest working analogue in the codebase, if one exists
- If an analogue exists: compare failing and passing implementations completely, not selectively; list every difference, including ones that appear irrelevant
- If no analogue exists (unique code path): map all dependencies touched by the failing code path and reason from first principles

---

## 3. Hypothesis and Testing

- State a specific, falsifiable hypothesis: "The failure is caused by X because Y"
- Change one variable at a time — never make multiple simultaneous changes
- After each change, re-run the reproduction case and observe the result
- Discard or refine the hypothesis based on evidence; do not proceed on partial confirmation

---

## 4. Implementation

Once root cause is confirmed:

1. If the bug has testable behaviour: write a failing test that reproduces it; confirm it fails before applying the fix. Skip this step only when the bug resists reliable test coverage (e.g., race conditions, intermittent UI glitches) — note why.
2. Apply a single targeted fix
3. Confirm the reproduction case now passes (the new test, or the manual repro if no test was written)
4. Confirm no existing tests regressed

---

## Red Flags

Stop and re-investigate if any of these arise:

- A fix was applied before root cause was confirmed
- More than one thing was changed simultaneously
- The test was written after the fix, not before
- The fix works but the reason is unclear
- A different symptom appeared after the fix
