# Skill Backlog

Items logged during sessions for future review.

<!-- Format for new entries:
## <Title>
- **Triggered by:** <what happened that surfaced this need>
- **Description:** <what the skill would do and when it would be used>
-->

<!-- Example:
## stripe-refund
- **Triggered by:** Had to manually look up the refund API docs mid-session
- **Description:** Automate Stripe refund operations — partial/full refund, check refund status, handle already-refunded errors
-->

---


## self-assessment
- **Triggered by:** 2026-10-08, "run a self-assessment on mallet" had no skill; the session improvised a four-area parallel review (persona, skills and agents, executable code, repo health), verified the reviewers' claims, ranked the findings, then fixed them in groups with a review gate per group.
- **Description:** Project skill for this repo (`.mallet/skills/self-assessment/`). Fans out the four read-only reviewers, checks each high-severity claim against the code or the Claude Code docs before reporting (two claims in that run were wrong), produces a ranked findings table and suggested fix groups, and per group runs fail-before/pass-after tests, the `bash:3.2` Docker check for hooks, docs parity, a CHANGELOG entry, and an independent review before committing.
