#!/usr/bin/env bash
set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/source"
MIN_BASH_VERSION=4

# Directories to create at target (not present in source)
RUNTIME_DIRS=(
  ".claude/sessions"
)

# Gitignore entries to add if target is a git repo
GITIGNORE_ENTRIES=(
  ".claude/sessions/*"
)

# ── State ────────────────────────────────────────────────────────────────────

DRY_RUN=false
TARGET=""
INSTALLED=()

# ── Functions ────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <target-directory>

Install ai-framework configuration into an existing project.
Existing files at the destination are always overwritten.

Options:
  --dry-run   Show what would be done without making changes
  --help      Show this help message

Examples:
  $(basename "$0") /path/to/my-project
  $(basename "$0") --dry-run /path/to/my-project
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

check_claude_cli() {
  if ! command -v claude &>/dev/null; then
    warn "Claude Code CLI not found on PATH. Install it before using the framework."
    warn "See: https://docs.anthropic.com/en/docs/claude-code"
  else
    log "Claude Code CLI found: $(command -v claude)"
  fi
}

install_file() {
  local relative="$1"
  local src="${SOURCE_DIR}/${relative}"
  local dst="${TARGET}/${relative}"
  local dst_dir
  dst_dir="$(dirname "$dst")"

  if [[ ! -f "$src" ]]; then
    err "Source file missing: ${src}"
    return 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    if [[ -f "$dst" ]]; then
      log "[dry-run] Would overwrite: ${relative}"
    else
      log "[dry-run] Would install: ${relative}"
    fi
  else
    local existed=false
    [[ -f "$dst" ]] && existed=true
    mkdir -p "$dst_dir"
    cp "$src" "$dst"
    if [[ "$existed" == true ]]; then
      log "Overwritten: ${relative}"
    else
      log "Installed: ${relative}"
    fi
  fi

  INSTALLED+=("$relative")
}

create_runtime_dirs() {
  for dir in "${RUNTIME_DIRS[@]}"; do
    local dst="${TARGET}/${dir}"
    if [[ -d "$dst" ]]; then
      log "Directory exists: ${dir}/"
    elif [[ "$DRY_RUN" == true ]]; then
      log "[dry-run] Would create: ${dir}/"
    else
      mkdir -p "$dst"
      log "Created: ${dir}/"
    fi
  done
}

set_permissions() {
  local hooks_dir="${TARGET}/.claude/hooks"
  if [[ ! -d "$hooks_dir" ]]; then
    return
  fi

  while IFS= read -r -d '' script; do
    local relative="${script#"${TARGET}/"}"
    if [[ "$DRY_RUN" == true ]]; then
      log "[dry-run] Would chmod +x: ${relative}"
    else
      chmod +x "$script"
      log "Set executable: ${relative}"
    fi
  done < <(find "$hooks_dir" -name '*.sh' -print0 2>/dev/null)
}

update_gitignore() {
  if [[ ! -d "${TARGET}/.git" ]]; then
    log "Not a git repo — skipping .gitignore update."
    return
  fi

  local gitignore="${TARGET}/.gitignore"

  for entry in "${GITIGNORE_ENTRIES[@]}"; do
    if [[ -f "$gitignore" ]] && grep -qF "$entry" "$gitignore"; then
      log ".gitignore already contains: ${entry}"
    elif [[ "$DRY_RUN" == true ]]; then
      log "[dry-run] Would add to .gitignore: ${entry}"
    else
      echo "$entry" >> "$gitignore"
      log "Added to .gitignore: ${entry}"
    fi
  done
}

print_summary() {
  echo ""
  echo "── Summary ──────────────────────────────────────────────────"
  if [[ "$DRY_RUN" == true ]]; then
    echo "  Mode: dry-run (no changes made)"
  fi
  echo "  Target:    ${TARGET}"
  echo "  Installed: ${#INSTALLED[@]} file(s)"
  echo ""
  echo "  Next steps:"
  echo "    1. Customize CLAUDE.md to match your workflow"
  echo "    2. Run 'claude' in the target directory to start a session"
  echo "────────────────────────────────────────────────────────────"
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  while (( $# > 0 )); do
    case "$1" in
      --dry-run) DRY_RUN=true; shift ;;
      --help)    usage; exit 0 ;;
      -*)        err "Unknown option: $1"; usage; exit 1 ;;
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
  echo "── ai-framework installer ───────────────────────────────────"
  echo ""

  echo "  Checking prerequisites..."
  check_bash_version
  check_claude_cli
  echo ""

  if [[ ! -d "$SOURCE_DIR" ]]; then
    err "Source directory not found: ${SOURCE_DIR}"
    err "Run this script from the ai-framework repo root."
    exit 1
  fi

  echo "  Installing files..."
  while IFS= read -r -d '' src; do
    relative="${src#"${SOURCE_DIR}/"}"
    install_file "$relative"
  done < <(find "$SOURCE_DIR" -type f -print0 | sort -z)
  echo ""

  echo "  Creating runtime directories..."
  create_runtime_dirs
  echo ""

  echo "  Setting permissions..."
  set_permissions
  echo ""

  echo "  Updating .gitignore..."
  update_gitignore

  print_summary
}

main "$@"
