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
- When the error surfaces deep in a call chain, trace the bad value backward, caller by caller, to the point where it first goes wrong. The fix belongs there, not where the error surfaced
- When a test passes alone but fails in the full suite, bisect the suite to find the earlier test that pollutes shared state

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
2. Apply a single targeted fix at the origin found in step 1
3. Confirm the reproduction case now passes (the new test, or the manual repro if no test was written)
4. If the bad value crossed a boundary on its way in (external input, an API entry point, persisted state), add validation at that boundary as a separate change, so the same class of bug fails loudly at the edge next time
5. Confirm no existing tests regressed

---

## Red Flags

Stop and re-investigate if any of these arise:

- A fix was applied before root cause was confirmed
- More than one thing was changed simultaneously
- The test was written after the fix, not before
- The fix works but the reason is unclear
- A different symptom appeared after the fix
- Three different fix locations have all failed — this signals an architectural problem, not a hypothesis failure; stop and map the system
- The user signals you are guessing — "Is that not happening?", "Will it show us…?", "Stop guessing", "We're stuck?" — return to step 1 and gather evidence before proposing anything else

**Rationalizations to reject** — these justify skipping root cause investigation and are always wrong:
- "I have a strong hunch" — hunches applied without confirmation create new bugs
- "This fix is obvious" — obvious fixes applied to wrong root causes waste time and obscure the real issue
- "We're under pressure to ship" — a wrong fix under pressure still ships a bug
- "I'll just try it and see" — speculative changes corrupt the hypothesis space and make root cause harder to find afterward

---

## When No Root Cause Is Found

Sometimes a complete investigation shows the failure is environmental, timing-dependent, or outside the codebase. Then:

1. Record what was investigated and what each check ruled out
2. Add handling suited to the failure: a retry, a timeout, or a clear error message
3. Add logging that would capture the cause the next time it happens

This is mitigation, not a fix: it applies only once the cause is established as environmental or external, or the investigation is exhausted, and the report says plainly that the cause is unknown. Most "no root cause" conclusions are incomplete investigations, so before taking this path, confirm every step of section 1 was actually done.

---

## Condition-Based Waiting

When debugging intermittent failures or async timing issues, replace arbitrary `sleep` delays with polling for the actual condition:

```
poll until <condition is true>:
  check every 10ms
  timeout after N seconds → fail with descriptive message
```

Arbitrary sleeps are fragile: they either wait too long (slow) or expire before the condition is met (flaky). Condition-based polling is faster on fast machines and more reliable on slow ones. A sleep that works locally is not a fix — it is a bet on timing.
