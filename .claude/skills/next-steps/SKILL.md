---
name: next-steps
description: Invoke when the user asks what is pending, what is left, what is next, what the next steps are, or runs /next-steps. Also invoke when the user asks for the status of outstanding work, asks which items are not yet tracked anywhere, or asks to be given the remaining work in a referenceable list.
---
# Next Steps

Report what is still outstanding as a numbered table the user can refer to by number.

Read only. This skill does not create tickets, write code, or persist state — `checkpoint` writes state, `reviewing-sessions` reflects on the session, this one only reports what remains. The single exception is step 6, and only when the user prunes items in reply.

---

## 1. Discover the task sources

Never assume a tracker exists. Establish what this environment actually has before collecting anything.

Always check:
- `.mallet/missions/*.md` — every file, not only `active.md`. More than one mission can be live at once, and they frequently overlap.
- The current session, for work agreed verbally but not yet recorded anywhere.
- `.mallet/skill-backlog.md` and `.mallet/memory.md` if present, for deferred items.

Environment dependent, use whichever exist:
- An issue tracker exposed as an MCP server. Read the available tool list to find out which, rather than guessing — it may be Jira, Linear, Notion, or nothing.
- `gh` for GitHub issues and open pull requests, if the repo has a remote.
- Whatever the project names as its source of work in `CLAUDE.md`, `.mallet/conventions.md`, or `.mallet/memory.md` — a Miro board, a spreadsheet, a shared document.

If nothing exists beyond the mission files, say so and carry on. A personal project with no tracker is a normal case, not a gap to apologise for.

Note which sources you consulted. Report them in step 5.

---

## 2. Collect the candidate items

Gather outstanding work from every source found. Include:
- pending items from mission files
- work agreed in this session that was never written down
- open tracker items that belong to this thread of work

Exclude:
- anything already completed, unless the user asked for a full picture
- items the user has previously declared done or not needed, which live in a `## Cleared` section of the mission file and stay there
- unrelated backlog. If a tracker sweep pulls in items with no connection to the current thread, keep them out of the main table and mention the count separately.

---

## 3. Verify before reporting

The mission file records what was true when it was written. Check the current state rather than trusting it.

- Re-read each referenced tracker item's real status. Items recorded as "needs reopening" are often already reopened, and items recorded as open are sometimes closed.
- Search the tracker for items covering work the mission file lists as untracked. An item may have been raised by someone else in the meantime.
- Where a claim about the system justifies the work, confirm it still holds if that is cheap to do. Say when a claim is carried forward unverified.

Every correction found here is worth stating explicitly, because it changes what the user does next.

Keep verification cheap. It runs every time this skill runs, so it must not cost more than the report is worth.
- Never issue a tracker query that returns item bodies. Many tracker MCP tools ignore a field restriction and return full descriptions anyway, and a handful of verbose items will exceed the response limit.
- Ask for statuses in one batched query by identifier. If the response overflows to a file, pull just the fields you need with `jq` rather than reading the file back.
- Do not re-verify something already confirmed earlier in the same session unless something has plausibly changed it since.

---

## 4. Produce the table

Number from 1. Order by readiness to start, most actionable first, so dependencies stay visible. An item that unblocks two others belongs above them even when it is the larger piece of work.

```markdown
| # | What | Why | Effort | Relevant repo(s) | Tracked as |
|---|------|-----|--------|------------------|------------|
| 1 | <the action, specific enough to start from> | <consequence of not doing it, with evidence> | Quick / Medium / Long | <repo, or "unconfirmed" with the candidates> | <tracker key, or "None"> |
```

Column rules:
- **What** — the action, concrete enough that someone could begin. Name files, services or identifiers where they are known.
- **Why** — the consequence, not a restatement of the what. Carry the evidence: the measurement, the incident, the failure it caused. This is the column that earns the item its place.
- **Effort** — a rough read of how quickly the item can be delivered, so the user can clear small things without re-reading everything. Infer it only from what steps 1 to 3 already collected: whether the change location is known, how many systems it touches, whether the outcome is defined or has to be discovered, and whether it waits on another person. Never run a query or open a file to establish it.
  - `Quick` — location known, one repo or system, outcome defined, depends on nobody else. One pull request, one config value, one comment.
  - `Medium` — one system but the exact change has to be established first, or it spans two, or it is small but waits on another person or team.
  - `Long` — the outcome requires discovery because the cause is unknown, or it scales with an unbounded set, or it spans several systems.
  - `Unclear` when the collected signals conflict or are absent. Do not guess, and do not spend a query resolving it.
  - Blocked items carry the blocker here instead, since effort means nothing until it lifts.
- **Relevant repo(s)** — where the change would land. If it is genuinely unclear, say "unconfirmed" and name the candidates rather than picking one.
- **Tracked as** — the tracker's own identifier, whatever the tracker is: a Jira key, a Linear ID, a GitHub issue number, a board card. Write "None" when untracked. Never leave it blank and never invent one.

Numbers are per response. Say so if the list has changed since the last run, since the user will refer back to them.

Keep the main table to the current thread's work. Anything that surfaced during source discovery but belongs to a different thread goes in a one line footnote with a count, not a row. If the thread itself genuinely carries more than about a dozen items, table the ten most ready and footnote the rest by title alone.

When the user is optimising for throughput rather than sequence, add a short list under the table of the `Quick` items by number.

Below the table, add only what the table cannot carry:
- how many items have no tracker entry, listed by number
- items that would land as a single change and so probably want one tracker entry rather than several
- overlaps with work already in flight, especially where two people would edit the same area
- anything blocked, and on what

---

## 5. Report coverage

State which sources were consulted, in one line. If a source that would normally apply was unavailable — no tracker configured, no network, no permission — say which, so the user knows the table's limits.

---

## 6. If the user prunes in reply

The usual response to this table is instructions by number: some items are done, some are not needed, the rest stay. When that happens, persist it.

- Move pruned items into a `## Cleared <date>` section of the mission file they came from, with a one line note on why. Do not delete them — "not needed now" is not "never needed", and the detail is expensive to reconstruct.
- Leave the surviving items in `Pending`.
- Re-issue the table, renumbered, covering only what remains.

---

## Keep the format

Once this table format is in use in a thread, keep using it for later questions about pending work. Do not revert to prose for a follow up, and do not change the columns unless asked.
