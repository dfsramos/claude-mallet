#!/bin/bash
# SessionStart hook: injects the Mallet persona.
#
# Plugins cannot ship a CLAUDE.md, so the persona reaches the model as
# SessionStart context instead. It is re-injected after clear and compact,
# which drop earlier context. Hook stdout over 10,000 characters is replaced by
# a file path and a 2,000-character preview, so PERSONA.md must stay under that
# (test-15 enforces it).

PERSONA="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/persona/PERSONA.md"
[ -f "$PERSONA" ] && cat "$PERSONA"
exit 0
