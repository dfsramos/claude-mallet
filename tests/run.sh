#!/bin/bash
# Run every suite; print one line each; exit non-zero if any failed.
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1
failed=0
for t in test-*.sh; do
  printf '%-30s ' "$t"
  out=$(bash "$t" 2>&1); rc=$?
  echo "$out" | tail -1
  [ $rc -eq 0 ] || failed=$((failed + 1))
done
echo "suites failed: $failed"
[ "$failed" -eq 0 ]
