---
paths:
  - "plugin/hooks/**"
  - "plugin/statusline/**"
  - "tests/**"
---
# Hook and statusline code

## Output channels

Plugin hooks reach the model only through the channels each event supports: plain stdout on SessionStart and UserPromptSubmit (UserPromptSubmit also takes JSON `hookSpecificOutput.additionalContext`, with an optional `systemMessage` for the user; stdout must then be that one JSON object); JSON `hookSpecificOutput.additionalContext` on PreToolUse and PostToolUse; stderr with exit 2 to block. Anything else goes to the debug log. Inject dynamic content this way, into the message stream, rather than by changing system-prompt material (the persona, CLAUDE.md) mid-session, which invalidates the prompt cache. Keep any single hook's output under 10,000 characters, or Claude receives only a file path and a preview.

## Portability

Hook and statusline scripts must run on macOS as well as Linux, and the tests only run on Linux, so write to the common subset: bash 3.2 (no `mapfile`/`readarray`, no associative arrays, no `local -n` namerefs), BSD `sed` (no `\n` in a replacement; split with `tr`), POSIX ERE without `\b` for `grep -E`, and `%.Nf` formatting only under `LC_ALL=C`. `tests/test-20-portability.sh` checks the bash constructs and the `%.Nf` rule statically; to confirm a change on real bash 3.2, run the affected suites in the `bash:3.2` Docker image (`apk add jq git coreutils`).

## Before adding a hook

Prefer a native setting. `permissions` allow, ask and deny rules, `autoCompactWindow`, and the official language server plugins covered everything the hooks retired on 2026-10-20 did (session-watch, write-guard, command-guard, typecheck). A hook earns its place only when nothing native does the job, and it must then be worth running in every project: the plugin registers every hook globally, and the versioned plugin cache gives a per-project `settings.json` no stable path to register against.

## Mods

Claude Code mods (v2.1.287+, October 2026) are JavaScript event handlers that run inside Claude Code as part of a plugin; see https://code.claude.com/docs/en/plugins/mods/overview. Plugin shell hooks stay the baseline for anything Mallet must always do: managed `allowManagedModsOnly` blocks installed mods while plugin shell hooks keep running, mods do not load in the Desktop app's WSL sessions, and they need a recent Claude Code. Reach for a mod only for what a hook cannot do at all, such as drawing interface or reading session state like `$.session.usage()` (context percent, rate limits, cost) directly, and keep a hook fallback for the same behaviour.
