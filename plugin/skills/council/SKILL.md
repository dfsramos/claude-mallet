---
name: council
description: Invoke when the user runs /council or asks to "council this", "pressure-test this decision", or get independent views on a choice that is expensive to reverse before making it. From adr or plan-feature, offer it for such a choice and run it once the user agrees.
---
# Council

Test a decision against four independent advisors before it is made. Each advisor starts from a written brief in its own context, never the conversation, so none inherits the framing or the agreement built up so far. The main session chairs: it writes the brief, convenes the advisors, and weighs what comes back.

| Agent | Name | Lens |
|---|---|---|
| `mallet:council-contrarian` | Cassandra | What would make the decision fail |
| `mallet:council-first-principles` | Felix | Whether it addresses the right problem, framed the right way |
| `mallet:council-expansionist` | Esme | The upside and the options being missed |
| `mallet:council-executor` | Ezra | The first concrete steps and what blocks them |

A council costs four subagent runs, two of them on `opus`. Use it for decisions that are expensive to reverse — architecture, data models, vendor or framework choices, removing a capability, a direction for the next months of work — not for routine choices.

---

## 1. Write the Brief

The brief is everything an advisor will know, so it must stand alone:

- **Question** — the decision, in one sentence, as a choice to make
- **Context** — what the system or situation is, and why the decision is coming up now
- **Options** — every option on the table, including doing nothing, each in a sentence or two
- **Constraints** — the hard ones (deadlines, contracts, compliance, budget) separated from preferences
- **Settled** — what is already decided and out of scope

Keep the current preference, if there is one, out of the brief: it would anchor all four advisors the same way. Note it for yourself and test it against their answers when you chair.

Write facts as facts and give file paths for claims about the code, so advisors can check them. Show the brief to the user and wait for their confirmation or corrections before convening: a wrong brief makes all four advisors wrong in the same way.

---

## 2. Convene

Dispatch all four advisors in parallel, in one message, and send each exactly the same `BRIEF` and, when the decision concerns a codebase, `WORKING_DIR`. Identical inputs keep the advisors independent: each brings only its own lens.

If an advisor fails or returns nothing, dispatch it once more. If it fails again, chair with the three answers and name the missing lens in the verdict.

---

## 3. Chair the Verdict

Read all four answers, then weigh them — do not average them:

- **Check the claims that decide the outcome.** Where an advisor's point rests on a fact about the code or the situation, verify it before giving it weight.
- **Agreement is weaker evidence than it looks.** The advisors share a model family; four of them agreeing means the point survived four framings, not four independent experts.
- **The verdict follows the objections that hold, not the vote count.** Any advisor can raise a deciding objection — Ezra's blocker as much as Cassandra's risk. Cassandra is built to find one, so the existence of her objection is not evidence; whether it holds once checked is.
- **An objection that holds shapes the verdict.** It moves the verdict to `go with changes` or further, or the summary names it as a risk the user would be accepting.
- **A `reframe` verdict comes first.** If Felix shows the options solve the wrong problem, settle that before choosing between them.
- **Test your own leaning last.** Compare the preference you kept out of the brief with the verdict, and say where they differ.

Present the result:

```markdown
## Council: <question>

**Verdict:** <go | go with changes | no-go | reframe> — <one sentence>

**Strongest objection:** <the point> — <holds / does not hold, and why>
**Upside worth taking:** <from Esme, with its cost — or "none worth the cost">
**First action:** <from Ezra, matched to the option the verdict favours>

| Advisor | Verdict | Key point |
|---|---|---|
| Cassandra | ... | ... |
| Felix | ... | ... |
| Esme | ... | ... |
| Ezra | ... | ... |

**What would change this verdict:** <the fact or result that would reverse it>
```

The decision stays the user's: present the verdict as a recommendation with its evidence, for the user to decide.

---

## 4. Record

- **Called from `adr`:** use the council's findings in the ADR — rejected options and why under Alternatives Considered, the strongest objection and its answer under Consequences.
- **An architectural decision without an ADR:** offer to record one with `adr`.
- **Otherwise:** the summary in the conversation is the record.
