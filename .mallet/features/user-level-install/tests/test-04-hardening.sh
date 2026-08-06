#!/bin/bash
# Test: statusline survives a missing framework.json; session-start caches its update check.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
SL="$REPO/.claude/statusline.sh"
SS="$REPO/.claude/hooks/session-start.sh"

pass=0; fail=0
ck()   { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has()  { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }
hasnt(){ if echo "$2" | grep -q "$3"; then echo "  FAIL $1 (unexpected '$3')"; fail=$((fail+1)); else echo "  PASS $1"; pass=$((pass+1)); fi; }

export HOME="$SCRATCH/home"
export CLAUDE_PROJECT_DIR="$SCRATCH/repo"
mkdir -p "$HOME/.claude" "$CLAUDE_PROJECT_DIR"

SESSION_JSON=$(printf '{"workspace":{"project_dir":"%s"},"cost":{"total_cost_usd":1.2345},"context_window":{"used_percentage":42},"rate_limits":{"five_hour":{"used_percentage":10}}}' "$CLAUDE_PROJECT_DIR")

echo "== statusline with NO framework.json =="
OUT=$(echo "$SESSION_JSON" | bash "$SL" 2>&1)
has   "cost still rendered"        "$OUT" '\$1\.2345'
has   "context % still rendered"   "$OUT" '42%'
has   "rate limit still rendered"  "$OUT" '5h: 10%'
hasnt "no version segment"         "$OUT" 'Claude Mallet'

echo "== statusline with framework.json present =="
echo '{"repo":"a/b","version":"abcdef1234567890","installed_at":"2026-01-01"}' > "$HOME/.claude/framework.json"
OUT=$(echo "$SESSION_JSON" | bash "$SL" 2>&1)
has "version segment present" "$OUT" 'Claude Mallet abcdef1'
has "installed_at present"    "$OUT" '2026-01-01'
has "cost still rendered"     "$OUT" '\$1\.2345'

echo "== statusline with malformed framework.json =="
printf '{broken' > "$HOME/.claude/framework.json"
OUT=$(echo "$SESSION_JSON" | bash "$SL" 2>&1)
ck  "exit 0"              "$?" "0"
has "cost still rendered" "$OUT" '\$1\.2345'

echo "== session-start update-check caching =="
# Stub curl earlier on PATH; each call appends a line to a counter file.
mkdir -p "$SCRATCH/bin"
cat > "$SCRATCH/bin/curl" <<'STUB'
#!/bin/bash
echo "call" >> "$CURL_LOG"
for a in "$@"; do
  case "$a" in
    *"/commits/"*) echo '{"sha":"beef1234567890abcdef","commit":{"committer":{"date":"2026-08-01T00:00:00Z"}}}'; exit 0;;
    *"api.github.com/repos/"*) echo '{"default_branch":"master"}'; exit 0;;
  esac
done
exit 0
STUB
chmod +x "$SCRATCH/bin/curl"
export PATH="$SCRATCH/bin:$PATH"
export CURL_LOG="$SCRATCH/curl.log"

echo '{"repo":"a/b","version":"aaaaaaaaaaaaaaaa","installed_at":"2026-01-01"}' > "$HOME/.claude/framework.json"
: > "$CURL_LOG"
OUT1=$(bash "$SS" 2>&1)
N1=$(wc -l < "$CURL_LOG")
OUT2=$(bash "$SS" 2>&1)
N2=$(wc -l < "$CURL_LOG")

has "run 1 reports update"        "$OUT1" 'Framework Update Available'
has "run 1 shows latest sha"      "$OUT1" 'beef123'
ck  "run 1 made network calls"    "$([ "$N1" -gt 0 ] && echo yes || echo no)" "yes"
ck  "run 2 made NO new calls"     "$N2" "$N1"
has "run 2 still reports update"  "$OUT2" 'Framework Update Available'
ck  "cache file written"          "$([ -f "$HOME/.claude/.mallet-update-check" ] && echo yes || echo no)" "yes"

echo "== stale cache triggers a fresh check =="
printf '0 beef1234567890abcdef\n' > "$HOME/.claude/.mallet-update-check"
: > "$CURL_LOG"
bash "$SS" >/dev/null 2>&1
ck "stale cache re-checked" "$([ "$(wc -l < "$CURL_LOG")" -gt 0 ] && echo yes || echo no)" "yes"

echo "== curl failure is not cached as up-to-date =="
cat > "$SCRATCH/bin/curl" <<'STUB'
#!/bin/bash
exit 22
STUB
chmod +x "$SCRATCH/bin/curl"
rm -f "$HOME/.claude/.mallet-update-check"
OUT=$(bash "$SS" 2>&1); rc=$?
ck    "exit 0 on curl failure"   "$rc" "0"
ck    "no cache written"         "$([ -f "$HOME/.claude/.mallet-update-check" ] && echo present || echo absent)" "absent"
hasnt "no bogus update notice"   "$OUT" 'Framework Update Available'

echo "== no update available is cached =="
cat > "$SCRATCH/bin/curl" <<'STUB'
#!/bin/bash
echo "call" >> "$CURL_LOG"
for a in "$@"; do
  case "$a" in
    *"/commits/"*) echo '{"sha":"aaaaaaaaaaaaaaaa","commit":{"committer":{"date":"2026-08-01T00:00:00Z"}}}'; exit 0;;
    *"api.github.com/repos/"*) echo '{"default_branch":"master"}'; exit 0;;
  esac
done
exit 0
STUB
chmod +x "$SCRATCH/bin/curl"
rm -f "$HOME/.claude/.mallet-update-check"
: > "$CURL_LOG"
OUT=$(bash "$SS" 2>&1)
N1=$(wc -l < "$CURL_LOG")
bash "$SS" >/dev/null 2>&1
N2=$(wc -l < "$CURL_LOG")
hasnt "no update notice when current" "$OUT" 'Framework Update Available'
ck    "up-to-date result cached"      "$N2" "$N1"

echo "== memory injection still works =="
mkdir -p "$CLAUDE_PROJECT_DIR/.mallet"
echo "MEM-SENTINEL" > "$CLAUDE_PROJECT_DIR/.mallet/memory.md"
OUT=$(bash "$SS" 2>&1)
has "memory still injected" "$OUT" "MEM-SENTINEL"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
