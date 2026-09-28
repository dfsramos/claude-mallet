#!/bin/bash
# Wrapper so the shell suite runner picks up the workflow routing test.
command -v node >/dev/null || { echo "pass=0 fail=1 (node not found)"; exit 1; }
node "$(dirname "${BASH_SOURCE[0]}")/test-14-workflow.mjs"
