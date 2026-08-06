# State: hooks-layer

## Decisions
<!-- 2026-04-30: push-confirm is advisory (exit 0) not blocking (exit 2) — a hard block causes an infinite loop because the hook re-fires when Claude retries after user confirmation -->
<!-- 2026-04-30: stack detection happens at hooks-setup runtime, not baked into the hook scripts — scripts stay static and work across any project -->
<!-- 2026-04-30: idempotent by script path — hooks-setup skips registration if the script filename already appears in any existing hook command -->

## Blockers
<!-- none -->
