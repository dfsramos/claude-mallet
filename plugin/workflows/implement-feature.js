export const meta = {
  name: 'implement-feature',
  description: 'Spec, plan, critique, implement, test, validate, and review a feature with the Mallet agent personas',
  whenToUse: 'Launched by the implement-feature skill, which collects the feature, test command, and options and passes them as args',
  phases: [
    { title: 'Spec', detail: 'Frida turns the request into scope and acceptance criteria' },
    { title: 'Plan', detail: 'Callum writes the change plan; Percy challenges it' },
    { title: 'Implement', detail: 'Ingrid applies the plan; Tobias runs the tests' },
    { title: 'Validate', detail: 'Sylvie checks the result against the spec' },
    { title: 'Review', detail: 'Clifford reviews the diff' },
  ],
}

// args: { feature, testCommand, workingDir?, context?, answers?,
//         critique?, scopeValidation?, review?, agentPrefix? }
// Agents cannot pause for the user, so any `blocked` result ends the run and
// is returned to the launching skill, which asks the user and re-runs with
// `answers` filled in.
const A = args || {}
if (!A.feature || !A.testCommand) throw new Error('args.feature and args.testCommand are required')
const DIR = A.workingDir || '.'
const PREFIX = A.agentPrefix === undefined ? 'mallet:' : A.agentPrefix
const opt = k => A[k] !== false

// Iteration budget: plan + critique share 2 revisions; implement + test +
// review share 2; review itself gets one revision cycle.
const PLAN_CAP = 2
const BUILD_CAP = 2

const CONTRACT = {
  type: 'object',
  properties: {
    status: { type: 'string', enum: ['approve', 'revise', 'blocked'] },
    summary: { type: 'string', description: '1-2 sentences for the orchestrator' },
    output: { type: 'string', description: 'The role-specific Output section, as markdown' },
    handoff: { type: 'string', description: 'The Handoff section verbatim: what the next agent needs' },
    amendments: { type: 'array', items: { type: 'string' }, description: 'Actionable changes required when status is revise' },
    changedFiles: { type: 'array', items: { type: 'string' }, description: 'Paths modified: reported by the implementer, read from git by the scope validator' },
  },
  required: ['status', 'summary', 'handoff'],
}

const runLog = []
async function run(persona, agentName, phaseName, prompt) {
  const r = await agent(prompt, { agentType: PREFIX + agentName, phase: phaseName, label: persona, schema: CONTRACT })
  const res = r || { status: 'blocked', summary: `${persona} returned nothing (skipped or failed)`, handoff: '' }
  runLog.push({ agent: persona, status: res.status, summary: res.summary })
  return res
}
const finish = (status, stoppedAt, detail, extra) => ({ status, stoppedAt, detail, runLog, ...extra })
const block = s => `\n\n${s}`

// ── 1. Spec ────────────────────────────────────────────────────────────────
phase('Spec')
const spec = await run('Frida', 'feature-analyst', 'Spec',
  `FEATURE: ${A.feature}` +
  (A.context ? block(`CONTEXT:\n${A.context}`) : '') +
  (A.answers ? block(`ANSWERS TO EARLIER UNKNOWNS:\n${A.answers}`) : ''))
if (spec.status !== 'approve') return finish('blocked', 'spec', spec.output || spec.summary)

// ── 2–3. Plan and critique ─────────────────────────────────────────────────
phase('Plan')
let plan = null
let amendments = []
for (let i = 0; ; i++) {
  plan = await run('Callum', 'code-analyst', 'Plan',
    `SPEC:\n${spec.handoff}` +
    block(`FILES: none pre-selected — locate the candidate files yourself under WORKING_DIR.`) +
    block(`WORKING_DIR: ${DIR}`) +
    (amendments.length ? block(`AMENDMENTS:\n- ${amendments.join('\n- ')}`) : ''))
  if (plan.status === 'blocked') return finish('blocked', 'plan', plan.output || plan.summary)

  if (plan.status === 'approve' && !opt('critique')) break
  if (plan.status === 'approve') {
    const critic = await run('Percy', 'plan-critic', 'Plan',
      `SPEC:\n${spec.handoff}` + block(`PLAN:\n${plan.handoff}`))
    if (critic.status === 'approve') break
    amendments = critic.amendments && critic.amendments.length ? critic.amendments : [critic.handoff]
  } else {
    amendments = plan.amendments && plan.amendments.length ? plan.amendments : [plan.summary]
  }
  if (i + 1 >= PLAN_CAP) {
    return finish('blocked', 'plan', 'Plan revision cap reached. Small, concrete amendments can be folded into the implementation instead.', { amendments, plan: plan.handoff })
  }
  log(`Plan revision ${i + 1}/${PLAN_CAP}: ${amendments.length} amendment(s)`)
}

// ── 4–7. Implement, test, validate, review ─────────────────────────────────
phase('Implement')
let fixes = ''
let fixesFrom = ''
let impl = null
let tests = null
let validated = false
let reviewed = false
let reviewRevised = false
const changed = new Set()

for (let i = 0; ; i++) {
  impl = await run('Ingrid', 'implementer', 'Implement',
    `PLAN:\n${plan.handoff}` + block(`WORKING_DIR: ${DIR}`) + (fixes ? block(`FAILURES${fixesFrom}:\n${fixes}`) : ''))
  if (impl.status === 'blocked') return finish('blocked', 'implement', impl.output || impl.summary)
  ;(impl.changedFiles || []).forEach(f => changed.add(f))

  tests = await run('Tobias', 'test-runner', 'Implement',
    `COMMAND: ${A.testCommand}` + block(`WORKING_DIR: ${DIR}`) + block(`SCOPE: ${[...changed].join(', ') || 'all'}`))
  if (tests.status === 'blocked') return finish('blocked', 'test', `Build or environment problem: ${tests.output || tests.summary}`)
  if (tests.status === 'revise') {
    if (i + 1 >= BUILD_CAP) return finish('blocked', 'test', 'Implementation revision cap reached with failing tests.', { failures: tests.handoff })
    fixes = tests.handoff
    fixesFrom = ''
    log(`Test failures — implementation revision ${i + 1}/${BUILD_CAP}`)
    continue
  }

  // Spec compliance before code quality: a review of wrongly-scoped work is wasted.
  if (opt('scopeValidation') && !validated) {
    const scope = await run('Sylvie', 'scope-validator', 'Validate',
      `SPEC:\n${spec.handoff}` + block(`CHANGED_FILES:\n${[...changed].join('\n')}`) + block(`WORKING_DIR: ${DIR}`))
    // Sylvie reads the change set from git, so files the implementer left out of its report still reach review.
    ;(scope.changedFiles || []).forEach(f => changed.add(f))
    if (scope.status !== 'approve') {
      return finish('revise', 'validate', 'Scope gaps found. Ask the user whether to re-enter at planning or implementation.', { gaps: scope.output || scope.handoff })
    }
    validated = true
  }

  if (opt('review') && !reviewed) {
    const review = await run('Clifford', 'code-reviewer', 'Review',
      `CHANGED_FILES:\n${[...changed].join('\n')}` + block(`WORKING_DIR: ${DIR}`) + block(`SPEC:\n${spec.handoff}`))
    reviewed = true
    if (review.status === 'revise') {
      // One fix cycle, then Clifford reviews the fix. A second revise, or the
      // shared build cap, ends the run rather than reporting unreviewed work as done.
      if (reviewRevised || i + 1 >= BUILD_CAP) {
        return finish('blocked', 'review', 'Blocking review issues remain after the revision cycle.', { blocking: review.handoff })
      }
      reviewRevised = true
      reviewed = false
      fixes = review.handoff
      fixesFrom = ' (code review)'
      log('Blocking review issues — one revision cycle, then re-review')
      continue
    }
    runLog.push({ agent: 'Clifford', status: 'notes', summary: review.output || '' })
  }
  break
}

return finish('done', null, 'Pipeline complete', {
  changedFiles: [...changed],
  tests: tests && tests.summary,
})
