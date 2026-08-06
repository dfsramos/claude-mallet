# Task: hook-hardening
Status: done
Deps: 02

## Goal
Stop `statusline.sh` from blanking the whole statusline when `framework.json` is unreadable, and cache the session-start update check so it stops hitting the GitHub API on every session.

## Context
Both are pre-existing bugs that only become material at global scope.

`statusline.sh` exits early at line 12 (`[ ! -f "$FRAMEWORK_JSON" ] && exit 0`) and again at line 18 (`[ -z "$LOCAL_HASH" ] && exit 0`). The version segment is only part of line 1, but these exits suppress lines 2 and 3 as well — cost, context %, rate limits, turn count, and the token breakdown all vanish because a metadata file is missing.

`session-start.sh:35-38` makes two uncached `curl` calls to `api.github.com` on every session start. Per-repo that was bounded by how many Mallet repos existed; always-on means every session in every directory, against a 60 req/hr unauthenticated limit. Exhausting it silently disables update notification for the rest of the hour.

## Steps

1. `.claude/statusline.sh` — make the version segment optional instead of gating:
   - Delete line 12 (`[ ! -f "$FRAMEWORK_JSON" ] && exit 0`)
   - Delete line 18 (`[ -z "$LOCAL_HASH" ] && exit 0`)
   - Keep line 13 (`command -v jq &>/dev/null || exit 0`) — jq is required by every downstream segment
   - Guard the two `jq` reads at lines 15–16 so they only run when the file exists:
     ```bash
     LOCAL_HASH=""; INSTALLED_AT=""
     if [ -f "$FRAMEWORK_JSON" ]; then
       LOCAL_HASH=$(jq -r '.version // empty' "$FRAMEWORK_JSON" 2>/dev/null)
       INSTALLED_AT=$(jq -r '.installed_at // empty' "$FRAMEWORK_JSON" 2>/dev/null)
     fi
     ```
   - Change line 73 from seeding the array with the version to seeding it empty, then pushing conditionally:
     ```bash
     line1_parts=()
     [ -n "$LOCAL_HASH" ] && line1_parts+=("Claude Mallet ${LOCAL_HASH:0:7}")
     [ -n "$INSTALLED_AT" ] && line1_parts+=("$INSTALLED_AT")
     ```
   - Leave lines 75–79 (repo/branch) unchanged. `emit_line` already returns early on an empty array (line 46), so line 1 is simply omitted when nothing is available.

2. `.claude/hooks/session-start.sh` — cache the update check. Replace the body of the `if [ -f "$FRAMEWORK_JSON" ] ...` block (lines 30–51) so the network calls are guarded by a 24-hour cache at `$HOME/.claude/.mallet-update-check`:
   - Cache format: one line, `<epoch> <latest_sha>`. A literal `-` in the SHA field records "checked, no update available".
   - Read the cache first. If it exists and `$(( $(date +%s) - epoch )) -lt 86400`, use the cached SHA and skip both `curl` calls entirely.
   - On a cache miss, run the existing two `curl` calls (keep `--max-time 3` and `-sf`), then write the result to the cache.
   - Write the cache even when no update is available, otherwise every session re-checks.
   - If either `curl` fails, write nothing to the cache and exit 0 silently — a failed check must not be recorded as "up to date", and must never block session start.
   - Emit the existing `--- Framework Update Available ---` block only when the resolved latest SHA differs from `LOCAL_HASH`.

3. Keep `exit 0` as the final line of `session-start.sh`.

## TDD Checklist
- [x] Write failing test: run `statusline.sh` with a session JSON containing `cost` and `context_window` but with `HOME` pointed at a directory holding no `framework.json`; assert cost and context output still appear
- [x] Confirm it fails (red) — current behaviour emits nothing
- [x] Apply step 1
- [x] Confirm it passes (green), and that a *present* `framework.json` still renders `Claude Mallet <sha>` as the first segment
- [x] Write failing test for the cache: run `session-start.sh` twice with a fresh `HOME`, counting `curl` invocations via a stub `curl` earlier on `PATH`; assert exactly one network attempt across both runs
- [x] Confirm it fails (red)
- [x] Apply step 2
- [x] Confirm it passes (green)
- [x] Assert a stub `curl` that exits non-zero leaves no cache file behind and the hook still exits 0
- [x] Assert a cache entry older than 86400s triggers a fresh check
- [x] Regression: with an update genuinely available, the `--- Framework Update Available ---` block is still emitted

## Notes
`date +%s` is used directly; this is a shell hook, not a workflow script, so there is no restriction on it.
