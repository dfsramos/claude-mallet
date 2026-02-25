#!/usr/bin/env bash
set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_SKILLS_DIR="${SCRIPT_DIR}/source/.claude/skills"
MIN_BASH_VERSION=4

# ── State ────────────────────────────────────────────────────────────────────

TARGET=""
PROMOTED=()
SKIPPED=()

# ── Functions ────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") <target-directory>

Harvest project-specific skills from a project and promote them to
the ai-framework base skills.

Scans <target-directory>/.claude/project/skills/ for skill directories,
lets you select which to promote, then copies them into the framework's
source/.claude/skills/ and removes them from the project.

Requires fzf for interactive selection if available; falls back to a
numbered menu.

Examples:
  $(basename "$0") /path/to/my-project
EOF
}

log() {
  echo "  $1"
}

warn() {
  echo "  [warn] $1"
}

err() {
  echo "  [error] $1" >&2
}

check_bash_version() {
  local major="${BASH_VERSINFO[0]}"
  if (( major < MIN_BASH_VERSION )); then
    err "Bash ${MIN_BASH_VERSION}+ is required (found ${BASH_VERSION})."
    exit 1
  fi
}

# Populate SKILL_NAMES array with skill directory names found in the project.
discover_skills() {
  local skills_dir="$1"
  SKILL_NAMES=()
  while IFS= read -r -d '' dir; do
    local name
    name="$(basename "$dir")"
    SKILL_NAMES+=("$name")
  done < <(find "$skills_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
}

# Select skills interactively. Populates SELECTED array.
select_skills_fzf() {
  local -n _skills="$1"
  local skills_dir="$2"
  local input
  input="$(printf '%s\n' "${_skills[@]}")"
  local chosen
  chosen="$(echo "$input" | fzf --multi --prompt="Select skills to promote (TAB to multi-select): " --height=40% --border)"
  SELECTED=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && SELECTED+=("$line")
  done <<< "$chosen"
}

select_skills_menu() {
  local -n _skills="$1"
  local total="${#_skills[@]}"

  echo ""
  echo "  Available skills:"
  for (( i=0; i<total; i++ )); do
    printf "    %2d) %s\n" $(( i+1 )) "${_skills[$i]}"
  done
  echo ""
  printf "  Enter numbers to promote (space-separated, or 'all'): "
  read -r input </dev/tty

  SELECTED=()
  if [[ "$input" == "all" ]]; then
    SELECTED=("${_skills[@]}")
    return
  fi

  for token in $input; do
    if [[ "$token" =~ ^[0-9]+$ ]] && (( token >= 1 && token <= total )); then
      SELECTED+=("${_skills[$(( token - 1 ))]}")
    else
      warn "Ignored invalid selection: ${token}"
    fi
  done
}

# Prompt the user for conflict resolution on an existing skill.
# Echoes "overwrite" or "skip".
prompt_conflict() {
  local skill="$1"
  while true; do
    printf '\n  Skill already exists in base: %s\n' "$skill" >/dev/tty
    printf '  [o]verwrite / [s]kip: ' >/dev/tty
    read -rp "" choice </dev/tty
    case "${choice}" in
      o) echo "overwrite"; return ;;
      s) echo "skip"; return ;;
      *) printf '  Invalid choice. Enter o or s.\n' >/dev/tty ;;
    esac
  done
}

promote_skill() {
  local skill="$1"
  local src="${TARGET}/.claude/project/skills/${skill}"
  local dst="${BASE_SKILLS_DIR}/${skill}"

  if [[ -d "$dst" ]]; then
    local action
    action="$(prompt_conflict "$skill")"
    if [[ "$action" == "skip" ]]; then
      log "Skipped: ${skill}"
      SKIPPED+=("$skill")
      return
    fi
    log "Overwriting base skill: ${skill}"
    rm -rf "$dst"
  fi

  cp -r "$src" "$dst"
  log "Promoted: ${skill} -> source/.claude/skills/${skill}"

  rm -rf "$src"
  log "Removed from project: .claude/project/skills/${skill}"

  PROMOTED+=("$skill")
}

print_summary() {
  echo ""
  echo "── Summary ──────────────────────────────────────────────────"
  echo "  Source project: ${TARGET}"
  echo "  Promoted: ${#PROMOTED[@]} skill(s)"
  for s in "${PROMOTED[@]}"; do
    echo "    + ${s}"
  done
  if (( ${#SKIPPED[@]} > 0 )); then
    echo "  Skipped: ${#SKIPPED[@]} skill(s)"
    for s in "${SKIPPED[@]}"; do
      echo "    - ${s}"
    done
  fi
  if (( ${#PROMOTED[@]} > 0 )); then
    echo ""
    echo "  Reminder: re-run install.sh on the project to install the"
    echo "  promoted skills as base skills:"
    echo ""
    echo "    ./install.sh ${TARGET}"
  fi
  echo "────────────────────────────────────────────────────────────"
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  while (( $# > 0 )); do
    case "$1" in
      --help) usage; exit 0 ;;
      -*)     err "Unknown option: $1"; usage; exit 1 ;;
      *)
        if [[ -z "$TARGET" ]]; then
          TARGET="$1"
        else
          err "Unexpected argument: $1"
          usage
          exit 1
        fi
        shift
        ;;
    esac
  done

  if [[ -z "$TARGET" ]]; then
    err "No target directory specified."
    usage
    exit 1
  fi

  if [[ ! -d "$TARGET" ]]; then
    err "Target directory does not exist: ${TARGET}"
    exit 1
  fi
  TARGET="$(cd "$TARGET" && pwd)"

  echo ""
  echo "── ai-framework harvest ─────────────────────────────────────"
  echo ""

  check_bash_version

  local project_skills_dir="${TARGET}/.claude/project/skills"
  if [[ ! -d "$project_skills_dir" ]]; then
    err "No project skills directory found at: ${project_skills_dir}"
    exit 1
  fi

  if [[ ! -d "$BASE_SKILLS_DIR" ]]; then
    err "Base skills directory not found: ${BASE_SKILLS_DIR}"
    err "Run this script from the ai-framework repo root."
    exit 1
  fi

  # Discover available skills
  declare -a SKILL_NAMES
  discover_skills "$project_skills_dir"

  if (( ${#SKILL_NAMES[@]} == 0 )); then
    log "No skills found in ${project_skills_dir}."
    exit 0
  fi

  log "Found ${#SKILL_NAMES[@]} skill(s) in project."
  echo ""

  # Select skills
  declare -a SELECTED
  if command -v fzf &>/dev/null; then
    select_skills_fzf SKILL_NAMES "$project_skills_dir"
  else
    warn "fzf not found — using numbered menu."
    select_skills_menu SKILL_NAMES
  fi

  if (( ${#SELECTED[@]} == 0 )); then
    log "No skills selected. Nothing to do."
    exit 0
  fi

  echo ""
  echo "  Promoting ${#SELECTED[@]} skill(s)..."
  echo ""

  for skill in "${SELECTED[@]}"; do
    promote_skill "$skill"
  done

  print_summary
}

main "$@"
