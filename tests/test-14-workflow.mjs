// Test: implement-feature.js routing, run against scripted agent() responses.
// Run: node .mallet/features/plugin-slim-down/tests/test-14-workflow.mjs
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const repo = join(dirname(fileURLToPath(import.meta.url)), '..')
const src = readFileSync(join(repo, 'plugin/workflows/implement-feature.js'), 'utf8')
  .replace(/^export const meta/m, 'const meta')
const AsyncFunction = (async () => {}).constructor
const body = new AsyncFunction('args', 'agent', 'phase', 'log', src)

let pass = 0, fail = 0
const ck = (name, got, want) => {
  const ok = JSON.stringify(got) === JSON.stringify(want)
  console.log(`  ${ok ? 'PASS' : 'FAIL'} ${name}${ok ? '' : ` (got ${JSON.stringify(got)} want ${JSON.stringify(want)})`}`)
  ok ? pass++ : fail++
}

// script: map persona label -> array of responses consumed in order
async function runWith(script, args) {
  const calls = []
  const agent = async (prompt, opts) => {
    calls.push({ who: opts.label, type: opts.agentType, prompt })
    const q = script[opts.label] || []
    const r = q.length > 1 ? q.shift() : q[0]
    return r === undefined ? { status: 'approve', summary: 'ok', handoff: `${opts.label}-handoff` } : r
  }
  const res = await body({ feature: 'f', testCommand: 't', ...args }, agent, () => {}, () => {})
  return { res, calls, who: calls.map(c => c.who) }
}
const ok = (extra = {}) => ({ status: 'approve', summary: 'ok', handoff: 'h', ...extra })
const rev = (extra = {}) => ({ status: 'revise', summary: 'no', handoff: 'fix-this', amendments: ['a1'], ...extra })

console.log('== happy path ==')
let r = await runWith({ Ingrid: [ok({ changedFiles: ['src/a.ts'] })] }, {})
ck('status done', r.res.status, 'done')
ck('order', r.who, ['Frida', 'Callum', 'Percy', 'Ingrid', 'Tobias', 'Sylvie', 'Clifford'])
ck('agent types prefixed', r.calls[0].type, 'mallet:feature-analyst')
ck('changed files collected', r.res.changedFiles, ['src/a.ts'])

console.log('== options off ==')
r = await runWith({}, { critique: false, scopeValidation: false, review: false })
ck('skips optional steps', r.who, ['Frida', 'Callum', 'Ingrid', 'Tobias'])
r = await runWith({}, { agentPrefix: '' })
ck('bare agent types when prefix empty', r.calls[0].type, 'feature-analyst')

console.log('== spec blocked ==')
r = await runWith({ Frida: [{ status: 'blocked', summary: 's', handoff: '', output: 'Unknowns: X?' }] }, {})
ck('stops at spec', [r.res.status, r.res.stoppedAt, r.who], ['blocked', 'spec', ['Frida']])
r = await runWith({}, { answers: 'X is 3' })
ck('answers forwarded', r.calls[0].prompt.includes('X is 3'), true)

console.log('== critique loop ==')
r = await runWith({ Percy: [rev(), ok()] }, {})
ck('one revision then proceeds', r.who.slice(0, 5), ['Frida', 'Callum', 'Percy', 'Callum', 'Percy'])
ck('amendments passed to Callum', r.calls[3].prompt.includes('AMENDMENTS:\n- a1'), true)
r = await runWith({ Percy: [rev()] }, {})
ck('cap reached -> blocked at plan', [r.res.status, r.res.stoppedAt], ['blocked', 'plan'])
ck('two plan attempts only', r.who.filter(w => w === 'Callum').length, 2)

console.log('== test failures ==')
r = await runWith({ Tobias: [rev({ handoff: 'TypeError at a.ts:3' }), ok()] }, {})
ck('re-implements with failures', r.calls.filter(c => c.who === 'Ingrid')[1].prompt.includes('FAILURES:\nTypeError at a.ts:3'), true)
ck('then completes', r.res.status, 'done')
r = await runWith({ Tobias: [rev()] }, {})
ck('persistent failures -> blocked at test', [r.res.status, r.res.stoppedAt], ['blocked', 'test'])
r = await runWith({ Tobias: [{ status: 'blocked', summary: 'build broke', handoff: '' }] }, {})
ck('env problem -> blocked immediately', [r.res.stoppedAt, r.who.filter(w => w === 'Ingrid').length], ['test', 1])

console.log('== scope and review ==')
r = await runWith({ Sylvie: [rev()] }, {})
ck('scope gaps -> revise, no review', [r.res.status, r.res.stoppedAt, r.who.includes('Clifford')], ['revise', 'validate', false])
r = await runWith({ Clifford: [rev({ handoff: 'null deref' }), ok()] }, {})
ck('review revise -> one fix cycle', r.who, ['Frida', 'Callum', 'Percy', 'Ingrid', 'Tobias', 'Sylvie', 'Clifford', 'Ingrid', 'Tobias'])
ck('review fixes forwarded', r.calls[7].prompt.includes('null deref'), true)
ck('done after fix cycle', r.res.status, 'done')

console.log('== agent returns null ==')
r = await runWith({ Callum: [null] }, {})
ck('null treated as blocked', [r.res.status, r.res.stoppedAt], ['blocked', 'plan'])

console.log('== missing args ==')
let threw = false
try { await body({ feature: 'f' }, async () => ok(), () => {}, () => {}) } catch { threw = true }
ck('throws without testCommand', threw, true)

console.log(`pass=${pass} fail=${fail}`)
process.exit(fail ? 1 : 0)
