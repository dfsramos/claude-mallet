---
name: write-task
description: Invoke when the user asks to create a ticket, task, issue, or sub-task in any tracker (Jira, Linear, GitHub issues, or similar); to write, fill in, or rewrite a task or ticket description; or to write a handover prompt "as a task" for another session or repository. Also invoke before composing any tracker task body on the user's behalf.
---
# Write Task

Write a tracker task that a later session can pick up and complete without the conversation that produced it. Every task body uses the skeleton below, whichever tracker it lands in, or none.

The reader is a future session or person who was not in this conversation. They will locate the code themselves. The task tells them what must become true, why, and how to know it is done.

---

## 1. Gather

Establish, from the conversation and anything already investigated:

- the outcome wanted, as one sentence
- why it is needed, and the evidence behind that: what was observed, how, and when
- the system, repository, or component involved, and where a reader should start looking
- related docs, issues, incidents, or pull requests
- the conditions that will be observably true when the work is done, including any ordering constraint that would cause an incident if violated

If the outcome or the reason is unclear, ask. Do not fill the gap with a guess.

---

## 2. Draft the body

Use this skeleton exactly. Keep the headings and the emoji, replace only the bracketed placeholders, and add no `---` dividers or container tags.

```markdown
# 📋 OBJECTIVE
* **Goal:** [Clear, single-sentence definition of the desired outcome]
* **Rationale:** [Brief explanation of why this change is necessary]

# 🔍 CURRENT STATE
* **Scope:** [The specific system, repository, service, or component involved]
* **Entry Points:** [Where to start looking; files, endpoints, or infrastructure components]
* **Context Docs:** [Links to relevant documentation, system architecture, or related issues]

# 🎯 TARGET STATE
The task is successfully completed **only** when the following criteria are verified:
- [ ] [Measurable condition 1]
- [ ] [Measurable condition 2]
- [ ] [Measurable condition 3]
```

Use as many Target State conditions as the work needs; three is a placeholder, not a quota.

### Filling rules

- **State intent, not implementation.** The session that picks the task up locates the code itself. Never write line numbers, never spell out the edits, and never prescribe a commit or deploy sequence. A line number in a tracker goes stale; a stated goal does not.
- **Entry Points are pointers, not instructions.** Name the components, files, endpoints, or infrastructure a reader should open first. Naming a file is fine; saying what to change inside it is not.
- **Target State conditions are checkable by someone else.** Each is observably true or false after the work, not an activity to perform. Prefer outcomes ("renders resolve their endpoint from a single setting") over activities ("remove the flag").
- **Evidence goes in Rationale.** When a claim about the current system justifies the work, say how and when it was verified, so a reader who was not in the investigation can trust it.
- **Ordering constraints are conditions.** If doing the work in the wrong order would cause an incident, state the order as a Target State condition, not in prose a reader may skim.
- Investigation detail that does not fit these rules (line numbers, candidate fixes, audit output) belongs in a comment on the task or in the session, not in the description.

### Writing rules

These apply to the task body and its title:

- No em dashes or en dashes. Use commas, periods, or "to" for ranges.
- No arrow characters. Write "->" if an arrow is needed.
- No hyphenated compound modifiers in prose: "filenames with version suffixes", not "version-suffixed filenames". Hyphens stay in dates, URLs, identifiers, file paths, and code.
- End every sentence and every bullet with a period.
- No capital letter after a colon in a bullet: `* **Scope:** the billing service.`
- Expand acronyms and anchor domain terms on first use, for a reader without the context.
- Every factual claim is traceable to a source or labelled as an estimate.
- Title: a plain sentence, with no `[BUG]` or `[TYPE]` prefixes.

---

## 3. Check the draft

Before showing it, read the draft against the rules above and fix any of these:

- a heading, emoji, or label missing or reworded, or a `---` divider present
- a line number, a described edit, or a commit or deploy sequence
- a Target State item phrased as an activity, or one nobody else could verify
- a Rationale claim with no stated evidence
- any punctuation the writing rules exclude

---

## 4. Confirm

Show the user the title and the full body. Wait for explicit confirmation or edits before creating anything in a tracker. If the user wants only the text, as with a handover prompt for another session, stop here and give it to them in a single fenced markdown block.

---

## 5. Create it in the tracker

Never assume a tracker exists. Find out from the environment:

- an issue tracker exposed as an MCP server: read the available tool list to see which, rather than guessing
- `gh`, for GitHub issues, when the repository has a GitHub remote
- whatever the project names as its source of work in `CLAUDE.md`, `.mallet/conventions.md`, or auto memory, which also decides between several candidates

If more than one tracker is available and nothing says which applies, ask. If none is available, return the body in chat as in step 4.

Tracker notes:

- **Jira**: a description sent through the REST API or an MCP tool must be ADF (Atlassian Document Format). Markdown `- [ ]` is stored as escaped literal text, so the checkboxes need a `taskList` of `taskItem` nodes with `state: "TODO"`. Use `heading` nodes for the three sections, a `bulletList` for Objective and Current State, and `strong` marks on the labels. A Jira CLI that converts markdown can take the skeleton directly.
- **GitHub issues** and **Linear**: both render the markdown skeleton as is, checkboxes included.

After creating it, report the task's identifier and URL. Read the created task back when the tool allows it, and check that the checkboxes rendered as checkboxes rather than literal `- [ ]` text.
