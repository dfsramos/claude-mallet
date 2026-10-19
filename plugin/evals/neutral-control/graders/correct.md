---
type: llm
---

PASS if the reply says that merge keeps both histories and records a merge commit while rebase rewrites the branch's commits onto the new base to give a linear history, and gives a sensible rule for choosing (for example rebase local or unshared work, merge shared branches or when history should show the integration).

FAIL if the reply confuses the two, says rebase does not rewrite commits, or gives no guidance on when to use each.
