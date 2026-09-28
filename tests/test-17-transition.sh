#!/bin/bash
# Test: install-payload.sh transitions a user-level install to the plugin —
# removing only what the manifest claims, keeping user content and a modified
# CLAUDE.md, leaving a runnable detect.sh stub, and doing nothing on a re-run.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
T="$REPO/.claude/install-payload.sh"

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has() { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }
exists() { [ -e "$1" ] && echo yes || echo no; }

# curl stub: serves the "installed version's" CLAUDE.md from a fixture, or fails.
mkdir -p "$SCRATCH/bin"
cat > "$SCRATCH/bin/curl" <<'STUB'
#!/bin/bash
out=""; url=""
while [ $# -gt 0 ]; do case "$1" in -o) out="$2"; shift 2;; http*) url="$1"; shift;; *) shift;; esac; done
echo "$url" >> "$CURL_LOG"
[ "$CURL_MODE" = "fail" ] && exit 22
cp "$ORIG_CLAUDE_MD" "$out"
STUB
chmod +x "$SCRATCH/bin/curl"
export PATH="$SCRATCH/bin:$PATH" CURL_LOG="$SCRATCH/curl.log" ORIG_CLAUDE_MD="$SCRATCH/orig.md"
printf '# Persona\r\nold persona text\r\n' > "$ORIG_CLAUDE_MD"   # CRLF, as in old releases

seed() { # fresh fake HOME holding a user-level install
  export HOME="$SCRATCH/home-$1"; D="$HOME/.claude"; rm -rf "$HOME"
  mkdir -p "$D"/skills/{adr,update,migrate,task-calibrate,my-own-skill} "$D"/agents "$D"/templates/knowledge-skill "$D"/hooks
  for s in adr update migrate task-calibrate my-own-skill; do echo "$s" > "$D/skills/$s/SKILL.md"; done
  echo x > "$D/skills/migrate/detect.sh"
  echo a > "$D/agents/code-reviewer.md"; echo c > "$D/agents/_contract.md"; echo u > "$D/agents/my-agent.md"
  echo t > "$D/templates/knowledge-skill/SKILL.md"
  echo h > "$D/hooks/session-start.sh"; echo mine > "$D/hooks/my-hook.sh"
  echo '# Statusline: shows Claude Mallet version, git branch, and usage.' > "$D/statusline.sh"
  printf '# Persona\nold persona text\n' > "$D/CLAUDE.md"                # LF copy of the same text
  echo '{"model":"opus"}' > "$D/settings.json"
  cat > "$D/framework.json" <<'JSON'
{"repo":"dfsramos/claude-mallet","version":"6ba3db63689b26df2c62fadad331b0fc1ac61012","installed_at":"2026-08-13",
 "manifest":{"skills":["adr","update","migrate","task-calibrate"],"agents":["code-reviewer.md","_contract.md"],
             "templates":["knowledge-skill"],"hooks":["session-start.sh","../../etc","*/x",""]}}
JSON
}

echo "== standard transition =="
seed a; : > "$CURL_LOG"
OUT=$(bash "$T" --from "$SCRATCH/unused" --repo dfsramos/claude-mallet --sha newsha 2>&1); ck "exit 0" "$?" "0"
ck "manifest skill removed"      "$(exists "$D/skills/adr")" "no"
ck "old update skill removed"    "$(exists "$D/skills/update")" "no"
ck "renamed skill removed"       "$(exists "$D/skills/task-calibrate")" "no"
ck "user skill preserved"        "$(cat "$D/skills/my-own-skill/SKILL.md")" "my-own-skill"
ck "manifest agents removed"     "$(exists "$D/agents/code-reviewer.md")$(exists "$D/agents/_contract.md")" "nono"
ck "user agent preserved"        "$(exists "$D/agents/my-agent.md")" "yes"
ck "template removed"            "$(exists "$D/templates/knowledge-skill")" "no"
ck "manifest hook removed"       "$(exists "$D/hooks/session-start.sh")" "no"
ck "user hook preserved"         "$(exists "$D/hooks/my-hook.sh")" "yes"
ck "path-like manifest entries ignored" "$(exists "$HOME/etc")" "no"
ck "Mallet statusline removed"   "$(exists "$D/statusline.sh")" "no"
ck "identical CLAUDE.md removed (CR ignored)" "$(exists "$D/CLAUDE.md")" "no"
has "fetched the installed version" "$(cat "$CURL_LOG")" "raw.githubusercontent.com/dfsramos/claude-mallet/6ba3db63689b26df2c62fadad331b0fc1ac61012/CLAUDE.md"
ck "detect.sh stub runs"         "$(bash "$D/skills/migrate/detect.sh" >/dev/null; echo $?)" "0"
ck "stub has no SKILL.md"        "$(exists "$D/skills/migrate/SKILL.md")" "no"
ck "stub marker present"         "$(exists "$D/skills/migrate/MALLET-TRANSITION-STUB")" "yes"
ck "framework.json transitioned" "$(jq -r .transitioned "$D/framework.json")" "plugin"
ck "manifest dropped"            "$(jq -r '.manifest // "none"' "$D/framework.json")" "none"
ck "settings untouched"          "$(jq -c . "$D/settings.json")" '{"model":"opus"}'
ck "backup written"              "$(ls "$D" | grep -c '^mallet-pretransition-backup-.*\.tar\.gz$')" "1"
ck "backup holds CLAUDE.md"      "$(tar -xzOf "$D"/mallet-pretransition-backup-*.tar.gz ./CLAUDE.md 2>/dev/null || tar -xzOf "$D"/mallet-pretransition-backup-*.tar.gz CLAUDE.md)" "$(printf '# Persona\nold persona text')"
has "prints plugin install"      "$OUT" "/plugin install mallet@claude-mallet"
has "reports preserved"          "$OUT" "skills/my-own-skill"

echo "== re-run is a no-op =="
before=$(find "$D" | sort | md5sum)
OUT=$(bash "$T" --from x --repo dfsramos/claude-mallet --sha newsha 2>&1)
has "reports already transitioned" "$OUT" "already transitioned"
ck  "nothing changed" "$(find "$D" | sort | md5sum)" "$before"

echo "== modified CLAUDE.md and customised statusline are kept =="
seed b; echo "## My own rule" >> "$D/CLAUDE.md"; echo '# my statusline' > "$D/statusline.sh"
OUT=$(bash "$T" --from x --repo r --sha s 2>&1)
ck  "modified CLAUDE.md kept" "$(tail -1 "$D/CLAUDE.md")" "## My own rule"
has "explains why"            "$OUT" "may hold your own rules"
ck  "custom statusline kept"  "$(exists "$D/statusline.sh")" "yes"

echo "== CLAUDE.md kept when the original cannot be fetched =="
seed c; export CURL_MODE=fail
OUT=$(bash "$T" --from x --repo r --sha s 2>&1); unset CURL_MODE
ck  "kept on fetch failure" "$(exists "$D/CLAUDE.md")" "yes"
has "says it could not compare" "$OUT" "could not fetch"

echo "== no install / corrupt install =="
export HOME="$SCRATCH/home-none"; mkdir -p "$HOME/.claude"
OUT=$(bash "$T" --from x 2>&1); ck "no install: exit 0" "$?" "0"; has "says nothing to do" "$OUT" "nothing to transition"
seed d; printf '{bad' > "$D/framework.json"
bash "$T" --from x >/dev/null 2>&1; ck "corrupt framework.json aborts" "$?" "1"
ck "nothing removed on abort" "$(exists "$D/skills/adr")" "yes"

echo "== update skill flow: payload script, then settings merge, then detect.sh =="
seed e
cat > "$D/settings.json" <<'JSON'
{"model":"opus","statusLine":{"type":"command","command":"bash \"$HOME/.claude/statusline.sh\""},
 "hooks":{"UserPromptSubmit":[{"matcher":"","hooks":[{"type":"command","command":"bash \"$HOME/.claude/hooks/user-prompt-submit.sh\""}]}]}}
JSON
bash "$T" --from x --repo dfsramos/claude-mallet --sha s >/dev/null 2>&1 \
  && bash "$REPO/.claude/merge-settings.sh" "$REPO/.claude/settings.fragment.json" >/dev/null 2>&1 \
  && bash "$HOME/.claude/skills/migrate/detect.sh" >/dev/null 2>&1
ck "all three steps succeed" "$?" "0"
ck "settings: hooks and statusLine gone, model kept" "$(jq -c '{model, statusLine, hooks}' "$D/settings.json")" '{"model":"opus","statusLine":null,"hooks":{}}'

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
