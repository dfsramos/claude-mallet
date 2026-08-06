#!/bin/bash
# Test: install-payload.sh replaces per entry, never per directory, and
# reconciles the manifest so removed skills do not linger forever.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
IP="$REPO/.claude/install-payload.sh"

pass=0; fail=0
ck()  { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has() { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }

export HOME="$SCRATCH/home"

# A fake extracted payload.
W="$SCRATCH/work"
mkdir -p "$W/.claude/skills/adr" "$W/.claude/skills/migrate" "$W/.claude/agents" \
         "$W/.claude/templates/knowledge-skill" "$W/.claude/hooks"
echo "adr-v2"      > "$W/.claude/skills/adr/SKILL.md"
echo "migrate-v1"  > "$W/.claude/skills/migrate/SKILL.md"
echo "contract"    > "$W/.claude/agents/_contract.md"
echo "tpl"         > "$W/.claude/templates/knowledge-skill/SKILL.md"
echo "#!/bin/bash" > "$W/.claude/hooks/session-start.sh"
echo "statusline"  > "$W/.claude/statusline.sh"
echo "# Persona"   > "$W/CLAUDE.md"

# A pre-existing user-level ~/.claude with personal content.
mkdir -p "$HOME/.claude/skills/backburner" "$HOME/.claude/skills/adr" \
         "$HOME/.claude/skills/removed-skill" "$HOME/.claude/agents"
echo "USER-AUTHORED"  > "$HOME/.claude/skills/backburner/SKILL.md"
echo "adr-v1"         > "$HOME/.claude/skills/adr/SKILL.md"
echo "stale"          > "$HOME/.claude/skills/removed-skill/SKILL.md"
echo "USER-AGENT"     > "$HOME/.claude/agents/my-agent.md"
# A prior install recorded removed-skill in its manifest; backburner was never in it.
cat > "$HOME/.claude/framework.json" <<'JSON'
{"repo":"o/r","version":"oldsha0000","installed_at":"2026-01-01",
 "manifest":{"skills":["adr","removed-skill"],"agents":[],"templates":[],"hooks":[]}}
JSON
# Must be left completely alone by this script.
echo '{"model":"opus"}' > "$HOME/.claude/settings.json"

echo "== run =="
OUT=$(bash "$IP" --from "$W" --repo "o/r" --sha "newsha1111222233334444" 2>&1)
ck "exit 0" "$?" "0"

echo "== user content survives =="
ck "user skill kept"    "$(cat "$HOME/.claude/skills/backburner/SKILL.md" 2>/dev/null)" "USER-AUTHORED"
ck "user agent kept"    "$(cat "$HOME/.claude/agents/my-agent.md" 2>/dev/null)" "USER-AGENT"
ck "settings untouched" "$(cat "$HOME/.claude/settings.json")" '{"model":"opus"}'
has "reports preserved" "$OUT" "backburner"

echo "== payload installed =="
ck "adr updated"      "$(cat "$HOME/.claude/skills/adr/SKILL.md")" "adr-v2"
ck "migrate added"    "$(cat "$HOME/.claude/skills/migrate/SKILL.md")" "migrate-v1"
ck "agent installed"  "$(cat "$HOME/.claude/agents/_contract.md")" "contract"
ck "template installed" "$(cat "$HOME/.claude/templates/knowledge-skill/SKILL.md")" "tpl"
ck "hook installed"   "$(cat "$HOME/.claude/hooks/session-start.sh")" "#!/bin/bash"
ck "statusline installed" "$(cat "$HOME/.claude/statusline.sh")" "statusline"
ck "CLAUDE.md installed"  "$(cat "$HOME/.claude/CLAUDE.md")" "# Persona"

echo "== manifest orphan removed =="
ck "orphan deleted"   "$([ -d "$HOME/.claude/skills/removed-skill" ] && echo present || echo gone)" "gone"
has "reports removal" "$OUT" "removed-skill"

echo "== executable bits =="
ck "hook executable"       "$([ -x "$HOME/.claude/hooks/session-start.sh" ] && echo yes || echo no)" "yes"
ck "statusline executable" "$([ -x "$HOME/.claude/statusline.sh" ] && echo yes || echo no)" "yes"

echo "== framework.json =="
F="$HOME/.claude/framework.json"
ck "sha written"      "$(jq -r '.version' "$F")" "newsha1111222233334444"
ck "repo written"     "$(jq -r '.repo' "$F")" "o/r"
ck "manifest skills"  "$(jq -r '.manifest.skills | sort | join(",")' "$F")" "adr,migrate"
ck "manifest agents"  "$(jq -r '.manifest.agents | join(",")' "$F")" "_contract.md"
ck "manifest hooks"   "$(jq -r '.manifest.hooks | join(",")' "$F")" "session-start.sh"
ck "manifest templates" "$(jq -r '.manifest.templates | join(",")' "$F")" "knowledge-skill"
ck "no user skill in manifest" "$(jq -r '.manifest.skills | index("backburner") // "no"' "$F")" "no"

echo "== idempotency =="
B=$(find "$HOME/.claude" -type f | sort | xargs md5sum 2>/dev/null | md5sum)
bash "$IP" --from "$W" --repo "o/r" --sha "newsha1111222233334444" >/dev/null 2>&1
A=$(find "$HOME/.claude" -type f | sort | xargs md5sum 2>/dev/null | md5sum)
ck "second run identical" "$A" "$B"

echo "== missing payload is refused =="
bash "$IP" --from "$SCRATCH/nope" --repo "o/r" --sha "x" >/dev/null 2>&1
ck "nonzero exit on bad --from" "$?" "1"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
