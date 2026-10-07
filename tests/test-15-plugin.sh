#!/bin/bash
# Test: the repository is a valid marketplace + plugin layout.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
P="$REPO/plugin"

pass=0; fail=0
ck() { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }

echo "== manifests =="
M="$REPO/.claude-plugin/marketplace.json"; PJ="$P/.claude-plugin/plugin.json"
ck "marketplace valid JSON" "$(jq -e . "$M" >/dev/null 2>&1 && echo ok)" "ok"
ck "plugin.json valid JSON" "$(jq -e . "$PJ" >/dev/null 2>&1 && echo ok)" "ok"
ck "plugin name"            "$(jq -r .name "$PJ")" "mallet"
ck "marketplace source"     "$(jq -r '.plugins[] | select(.name=="mallet") | .source' "$M")" "./plugin"
# No version anywhere: users then track commits (host-marketplace docs).
ck "no pinned version"      "$(jq -r '[.version, (.plugins[]?.version)] | map(select(. != null)) | length' "$PJ" "$M" | sort -u | tr -d '\n')" "0"
ck "no CLAUDE.md at plugin root (not loaded by plugins)" "$([ -e "$P/CLAUDE.md" ] && echo present || echo absent)" "absent"

echo "== hooks.json =="
H="$P/hooks/hooks.json"
ck "valid JSON" "$(jq -e . "$H" >/dev/null 2>&1 && echo ok)" "ok"
MISSING=0; UNROOTED=0
while read -r cmd; do
  case "$cmd" in *'${CLAUDE_PLUGIN_ROOT}'*) ;; *) UNROOTED=$((UNROOTED+1)) ;; esac
  script=$(echo "$cmd" | grep -oE '\$\{CLAUDE_PLUGIN_ROOT\}/[^" ]+' | sed "s|\${CLAUDE_PLUGIN_ROOT}|$P|")
  [ -f "$script" ] || { echo "    missing: $script"; MISSING=$((MISSING+1)); }
done < <(jq -r '.hooks[][] .hooks[].command' "$H")
ck "every hook script exists"          "$MISSING" "0"
ck "every command uses CLAUDE_PLUGIN_ROOT" "$UNROOTED" "0"

echo "== persona =="
OUT=$(CLAUDE_PLUGIN_ROOT="$P" bash "$P/hooks/persona.sh")
ck "hook prints PERSONA.md" "$OUT" "$(cat "$P/persona/PERSONA.md")"
CHARS=$(printf '%s' "$OUT" | wc -m | tr -d ' ')
# Hook stdout over 10,000 characters is replaced by a file path and a preview.
ck "persona under 9,800 chars (cap 10,000; now $CHARS)" "$([ "$CHARS" -lt 9800 ] && echo yes || echo no)" "yes"
OUT=$(cd /tmp && env -u CLAUDE_PLUGIN_ROOT bash "$P/hooks/persona.sh" | head -1)
ck "falls back to script location" "$OUT" "# Persona"

echo "== skills and agents =="
BAD=0
for d in "$P"/skills/*/; do
  n=$(basename "$d"); f="$d/SKILL.md"
  [ -f "$f" ] || { echo "    no SKILL.md: $n"; BAD=$((BAD+1)); continue; }
  [ "$(sed -n 's/^name: //p' "$f" | head -1)" = "$n" ] || { echo "    name mismatch: $n"; BAD=$((BAD+1)); }
  grep -q '^description: .\{20,\}' "$f" || { echo "    no description: $n"; BAD=$((BAD+1)); }
done
ck "skills well-formed" "$BAD" "0"
BAD=0
for f in "$P"/agents/*.md; do
  n=$(basename "$f" .md)
  [ "$(sed -n 's/^name: //p' "$f" | head -1)" = "$n" ] || { echo "    agent name mismatch: $n"; BAD=$((BAD+1)); }
done
ck "agents well-formed" "$BAD" "0"
ck "no nested SKILL.md beyond one level" "$(find "$P/skills" -mindepth 3 -name SKILL.md | wc -l | tr -d ' ')" "0"

echo "== no references to the removed user-level payload paths =="
REFS=$(grep -rnE '(~|\$HOME)/\.claude/(hooks|templates)/|agents/_contract' "$P" | grep -v '/skills/migrate/' | grep -v 'CLAUDE_PROJECT_DIR')
[ -n "$REFS" ] && echo "$REFS" | sed 's/^/    /'
ck "clean" "$(printf '%s' "$REFS" | grep -c . )" "0"

# Mallet skills are no longer copied to ~/.claude/skills/, so a skill that calls
# a sibling by that path breaks (after the transition it reaches only a stub).
NAMES=$(ls "$P/skills" | paste -sd'|')
SREFS=$(grep -rnE "(~|\$HOME)/\.claude/skills/($NAMES)/" "$P" --include='*.md')
SREFS=$(printf '%s' "$SREFS" | grep -v 'MALLET-TRANSITION-STUB')
[ -n "$SREFS" ] && echo "$SREFS" | sed 's/^/    /'
ck "no skill calls a Mallet skill by its old user-level path" "$(printf '%s' "$SREFS" | grep -c . )" "0"

echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
