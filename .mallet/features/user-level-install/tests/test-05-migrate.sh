#!/bin/bash
# Test: the migrate mechanics — detection, state move, settings prune, CLAUDE.md strip.
# Builds six real git repos so `git ls-files` can distinguish tracked from untracked.
REPO=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)
SCRATCH=$(mktemp -d)
trap 'rm -rf "$SCRATCH"' EXIT
DETECT="$REPO/.claude/skills/migrate/detect.sh"
MIG="$REPO/.claude/skills/migrate/migrate-repo.sh"

pass=0; fail=0
ck()   { if [ "$2" = "$3" ]; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (got '$2' want '$3')"; fail=$((fail+1)); fi; }
has()  { if echo "$2" | grep -q "$3"; then echo "  PASS $1"; pass=$((pass+1)); else echo "  FAIL $1 (missing '$3')"; fail=$((fail+1)); fi; }

export HOME="$SCRATCH/home"; mkdir -p "$HOME/.claude"

# The historical Mallet payload the strip diffs against.
PAYLOAD="$SCRATCH/payload-CLAUDE.md"
printf '# Persona\n\n## Evidence-Based Approach\n\nBack claims with evidence.\n\n## Git Workflow\n\nBranch off master.\n' > "$PAYLOAD"

mkrepo() { # $1=name
  local d="$SCRATCH/$1"; mkdir -p "$d"; git -C "$d" init -q
  git -C "$d" config user.email t@t; git -C "$d" config user.name t
  echo "code" > "$d/main.txt"; git -C "$d" add main.txt; git -C "$d" commit -qm init
  echo "$d"
}
payload() { # $1=repo  — the framework payload a legacy install leaves behind
  mkdir -p "$1/.claude/skills/update" "$1/.claude/agents" "$1/.claude/hooks" "$1/.claude/templates"
  echo x > "$1/.claude/skills/update/SKILL.md"; echo x > "$1/.claude/agents/_contract.md"
  echo x > "$1/.claude/hooks/session-start.sh"; echo x > "$1/.claude/templates/t.md"
  echo x > "$1/.claude/statusline.sh"
  echo '{"repo":"o/r","version":"deadbeef","installed_at":"2026-01-01"}' > "$1/.claude/framework.json"
  echo '{"permissions":{"allow":["Bash"]}}' > "$1/.claude/settings.local.json"
}

# (a) untracked payload + project state + mixed settings.json
A=$(mkrepo a); payload "$A"
mkdir -p "$A/.claude/project/missions" "$A/.claude/project/skills/x" "$A/.claude/features/f1" "$A/.claude/pipeline-state"
echo "PROJ-CONV"    > "$A/.claude/project/CLAUDE.md"
echo "PROJ-MEM"     > "$A/.claude/project/memory.md"
echo "PROJ-LESSONS" > "$A/.claude/project/lessons.md"
echo "PROJ-MISSION" > "$A/.claude/project/missions/active.md"
echo "PROJ-SKILL"   > "$A/.claude/project/skills/x/SKILL.md"
echo "PROJ-DISC"    > "$A/.claude/project/discovery-2026-01-01.md"
echo "PROJ-FEAT"    > "$A/.claude/features/f1/plan.md"
echo "PROJ-PIPE"    > "$A/.claude/pipeline-state/s.md"
echo "PROJ-STRAY"   > "$A/.claude/project/unexpected.md"
cat > "$A/.claude/settings.json" <<'JSON'
{
  "statusLine": { "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/statusline.sh\"" },
  "hooks": {
    "SessionStart": [{ "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/session-start.sh\"" }] }],
    "PostToolUse": [{ "matcher": "Edit", "hooks": [{ "type": "command", "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/typecheck.sh\"" }] }]
  }
}
JSON

# (b) untracked CLAUDE.md, pure payload
B=$(mkrepo b); payload "$B"; cp "$PAYLOAD" "$B/CLAUDE.md"

# (c) untracked CLAUDE.md with extra project sections
C=$(mkrepo c); payload "$C"; cp "$PAYLOAD" "$C/CLAUDE.md"
printf '\n---\n\n## Vault Context\n\nThis is an Obsidian vault.\nThe emoji conventions are load-bearing.\n' >> "$C/CLAUDE.md"

# (d) TRACKED CLAUDE.md with extra project sections — must be untouched
D=$(mkrepo d); payload "$D"; cp "$PAYLOAD" "$D/CLAUDE.md"
printf '\n---\n\n## House Rules\n\nDo not touch me.\n' >> "$D/CLAUDE.md"
git -C "$D" add CLAUDE.md; git -C "$D" commit -qm "add claude.md"
D_BEFORE=$(md5sum < "$D/CLAUDE.md")

# (e) broken framework.json using the `commit` key
E=$(mkrepo e); payload "$E"
echo '{"commit":"2ae59d1","installed_at":"2026-05-19T12:43:30Z"}' > "$E/.claude/framework.json"

# (f) already migrated
F=$(mkrepo f); mkdir -p "$F/.mallet"; echo "MEM" > "$F/.mallet/memory.md"
echo '{"permissions":{}}' > "$F/.claude/settings.local.json" 2>/dev/null || { mkdir -p "$F/.claude"; echo '{"permissions":{}}' > "$F/.claude/settings.local.json"; }

echo "== detection =="
OUT=$(bash "$DETECT" --roots "$SCRATCH" 2>&1)
for r in a b c d e; do has "detects fixture $r" "$OUT" "$SCRATCH/$r"; done
ck "skips already-migrated f" "$(echo "$OUT" | grep -c "$SCRATCH/f\b")" "0"
has "reads commit-key sha" "$OUT" "2ae59d1"

echo "== (a) full migration =="
bash "$MIG" "$A" --payload "$PAYLOAD" --yes >/dev/null 2>&1
ck "conventions.md"   "$(cat "$A/.mallet/conventions.md" 2>/dev/null)" "PROJ-CONV"
ck "memory.md"        "$(cat "$A/.mallet/memory.md" 2>/dev/null)" "PROJ-MEM"
ck "lessons.md"       "$(cat "$A/.mallet/lessons.md" 2>/dev/null)" "PROJ-LESSONS"
ck "missions/"        "$(cat "$A/.mallet/missions/active.md" 2>/dev/null)" "PROJ-MISSION"
ck "skills/"          "$(cat "$A/.mallet/skills/x/SKILL.md" 2>/dev/null)" "PROJ-SKILL"
ck "discovery"        "$(cat "$A/.mallet/discovery-2026-01-01.md" 2>/dev/null)" "PROJ-DISC"
ck "features/"        "$(cat "$A/.mallet/features/f1/plan.md" 2>/dev/null)" "PROJ-FEAT"
ck "pipeline-state/"  "$(cat "$A/.mallet/pipeline-state/s.md" 2>/dev/null)" "PROJ-PIPE"
ck "stray preserved"  "$(cat "$A/.mallet/unexpected.md" 2>/dev/null)" "PROJ-STRAY"
ck "payload gone"     "$([ -d "$A/.claude/skills" ] && echo present || echo gone)" "gone"
ck "agents gone"      "$([ -d "$A/.claude/agents" ] && echo present || echo gone)" "gone"
ck "framework.json gone" "$([ -f "$A/.claude/framework.json" ] && echo present || echo gone)" "gone"
ck "project/ gone"    "$([ -d "$A/.claude/project" ] && echo present || echo gone)" "gone"
ck "settings.local kept" "$(cat "$A/.claude/settings.local.json")" '{"permissions":{"allow":["Bash"]}}'
ck "no .mallet/.gitignore" "$([ -f "$A/.mallet/.gitignore" ] && echo present || echo absent)" "absent"

echo "== (a) settings prune =="
S="$A/.claude/settings.json"
ck "base hook removed"    "$(jq '[.hooks.SessionStart // []] | flatten | length' "$S" 2>/dev/null)" "0"
ck "statusLine removed"   "$(jq 'has("statusLine")' "$S" 2>/dev/null)" "false"
ck "opt-in hook kept"     "$(jq '[.hooks.PostToolUse[]?.hooks[]? | select(.command|test("typecheck"))] | length' "$S" 2>/dev/null)" "1"
ck "opt-in uses HOME"     "$(jq -r '.hooks.PostToolUse[0].hooks[0].command' "$S" 2>/dev/null | grep -c 'HOME')" "1"
ck "no CLAUDE_PROJECT_DIR" "$(grep -c 'CLAUDE_PROJECT_DIR' "$S" 2>/dev/null | head -1)" "0"

echo "== (b) untracked pure payload CLAUDE.md deleted =="
bash "$MIG" "$B" --payload "$PAYLOAD" --yes >/dev/null 2>&1
ck "CLAUDE.md deleted" "$([ -f "$B/CLAUDE.md" ] && echo present || echo gone)" "gone"

echo "== (c) untracked CLAUDE.md stripped to project delta =="
bash "$MIG" "$C" --payload "$PAYLOAD" --yes >/dev/null 2>&1
ck  "CLAUDE.md kept"      "$([ -f "$C/CLAUDE.md" ] && echo yes || echo no)" "yes"
has "project section kept" "$(cat "$C/CLAUDE.md")" "Vault Context"
has "body kept"            "$(cat "$C/CLAUDE.md")" "load-bearing"
ck  "mallet persona gone" "$(grep -c 'Evidence-Based Approach' "$C/CLAUDE.md")" "0"
ck  "mallet git rule gone" "$(grep -c 'Branch off master' "$C/CLAUDE.md")" "0"

echo "== (d) TRACKED CLAUDE.md untouched =="
bash "$MIG" "$D" --payload "$PAYLOAD" --yes >/dev/null 2>&1
ck "byte-identical"  "$(md5sum < "$D/CLAUDE.md")" "$D_BEFORE"
ck "git index clean" "$(git -C "$D" status --porcelain -- CLAUDE.md | wc -l)" "0"
ck "still tracked"   "$(git -C "$D" ls-files CLAUDE.md)" "CLAUDE.md"
ck "payload still cleaned" "$([ -d "$D/.claude/agents" ] && echo present || echo gone)" "gone"

echo "== (e) broken schema still migrates =="
bash "$MIG" "$E" --payload "$PAYLOAD" --yes >/dev/null 2>&1
ck "payload gone" "$([ -f "$E/.claude/framework.json" ] && echo present || echo gone)" "gone"

echo "== backups written =="
ck "one backup per migrated repo" "$(ls "$HOME"/.claude/mallet-migration-backup-*.tar.gz 2>/dev/null | wc -l)" "5"
ck "backup extracts" "$(tar -tzf "$(ls "$HOME"/.claude/mallet-migration-backup-*a.tar.gz 2>/dev/null | head -1)" >/dev/null 2>&1 && echo ok)" "ok"

echo "== idempotency =="
BEFORE=$(find "$A" -path "$A/.git" -prune -o -type f -print | sort | md5sum)
bash "$MIG" "$A" --payload "$PAYLOAD" --yes >/dev/null 2>&1
ck "second run changes nothing" "$(find "$A" -path "$A/.git" -prune -o -type f -print | sort | md5sum)" "$BEFORE"
OUT=$(bash "$DETECT" --roots "$SCRATCH" 2>&1)
ck "nothing left to detect" "$(echo "$OUT" | grep -c "$SCRATCH/[abcde]\b")" "0"

echo "== no repo gitignore or exclude was touched =="
n=0
for d in "$A" "$B" "$C" "$D" "$E"; do
  [ -f "$d/.gitignore" ] && n=$((n+1))
  grep -q mallet "$d/.git/info/exclude" 2>/dev/null && n=$((n+1))
done
ck "no ignore files created/edited" "$n" "0"

echo
echo "pass=$pass fail=$fail"
[ "$fail" -eq 0 ]
