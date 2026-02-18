#!/usr/bin/env bash
set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${SCRIPT_DIR}/source"
MIN_BASH_VERSION=4

# No hardcoded file list — all files under source/ are discovered at runtime.

# Directories to create at target (not present in source)
RUNTIME_DIRS=(
  ".claude/sessions"
)

# Gitignore entries to add if target is a git repo
GITIGNORE_ENTRIES=(
  ".claude/sessions/*"
)

# ── State ────────────────────────────────────────────────────────────────────

FORCE=false
DRY_RUN=false
TARGET=""
CONFLICT_ALL=""
INSTALLED=()
SKIPPED=()
BACKED_UP=()

# ── Functions ────────────────────────────────────────────────────────────────

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS] <target-directory>

Install ai-framework configuration into an existing project.

Options:
  --force     Overwrite existing files without prompting
  --dry-run   Show what would be done without making changes
  --help      Show this help message

Examples:
  $(basename "$0") /path/to/my-project
  $(basename "$0") --force /path/to/my-project
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

# Prompt the user for conflict resolution on an existing file.
# Returns: "overwrite", "backup", or "skip"
prompt_conflict() {
  local file="$1"
  while true; do
    printf '\n  File already exists: %s\n' "$file" >/dev/tty
    printf '  [o]verwrite / [O]verwrite all / [b]ackup+overwrite / [B]ackup all / [s]kip / [S]kip all\n' >/dev/tty
    read -rp "  Choice: " choice </dev/tty
    case "${choice}" in
      o)   echo "overwrite"; return ;;
      O)   CONFLICT_ALL="overwrite"; echo "overwrite"; return ;;
      b)   echo "backup"; return ;;
      B)   CONFLICT_ALL="backup"; echo "backup"; return ;;
      s)   echo "skip"; return ;;
      S)   CONFLICT_ALL="skip"; echo "skip"; return ;;
      *)   printf '  Invalid choice. Enter o/O/b/B/s/S.\n' >/dev/tty ;;
    esac
  done
}

install_file() {
  local relative="$1"
  local src="${SOURCE_DIR}/${relative}"
  local dst="${TARGET}/${relative}"
  local dst_dir
  dst_dir="$(dirname "$dst")"

  # Source file must exist
  if [[ ! -f "$src" ]]; then
    err "Source file missing: ${src}"
    return 1
  fi

  # Handle existing file at destination
  if [[ -f "$dst" ]]; then
    if [[ "$FORCE" == true ]]; then
      action="overwrite"
    elif [[ -n "$CONFLICT_ALL" ]]; then
      action="$CONFLICT_ALL"
    else
      action="$(prompt_conflict "$dst")"
    fi

    case "$action" in
      overwrite)
        if [[ "$DRY_RUN" == true ]]; then
          log "[dry-run] Would overwrite: ${relative}"
        else
          mkdir -p "$dst_dir"
          cp "$src" "$dst"
          log "Overwritten: ${relative}"
        fi
        INSTALLED+=("$relative")
        ;;
      backup)
        if [[ "$DRY_RUN" == true ]]; then
          log "[dry-run] Would backup ${dst} -> ${dst}.bak"
          log "[dry-run] Would overwrite: ${relative}"
        else
          cp "$dst" "${dst}.bak"
          log "Backed up: ${dst} -> ${dst}.bak"
          cp "$src" "$dst"
          log "Overwritten: ${relative}"
        fi
        BACKED_UP+=("$relative")
        INSTALLED+=("$relative")
        ;;
      skip)
        if [[ "$DRY_RUN" == true ]]; then
          log "[dry-run] Would skip: ${relative}"
        else
          log "Skipped: ${relative}"
        fi
        SKIPPED+=("$relative")
        ;;
    esac
  else
    if [[ "$DRY_RUN" == true ]]; then
      log "[dry-run] Would install: ${relative}"
    else
      mkdir -p "$dst_dir"
      cp "$src" "$dst"
      log "Installed: ${relative}"
    fi
    INSTALLED+=("$relative")
  fi
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
  # Only act if target is a git repo
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
  echo "  Target: ${TARGET}"
  echo "  Installed: ${#INSTALLED[@]} file(s)"
  if (( ${#SKIPPED[@]} > 0 )); then
    echo "  Skipped: ${#SKIPPED[@]} file(s)"
    for f in "${SKIPPED[@]}"; do
      echo "    - ${f}"
    done
  fi
  if (( ${#BACKED_UP[@]} > 0 )); then
    echo "  Backed up: ${#BACKED_UP[@]} file(s)"
    for f in "${BACKED_UP[@]}"; do
      echo "    - ${f}"
    done
  fi
  echo ""
  echo "  Next steps:"
  echo "    1. Customize CLAUDE.md to match your workflow"
  echo "    2. Run 'claude' in the target directory to start a session"
  echo "────────────────────────────────────────────────────────────"
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  # Parse arguments
  while (( $# > 0 )); do
    case "$1" in
      --force)   FORCE=true; shift ;;
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

  # Resolve to absolute path
  if [[ ! -d "$TARGET" ]]; then
    err "Target directory does not exist: ${TARGET}"
    exit 1
  fi
  TARGET="$(cd "$TARGET" && pwd)"

  echo ""
  echo "── ai-framework installer ───────────────────────────────────"
  echo ""

  # Prerequisites
  echo "  Checking prerequisites..."
  check_bash_version
  check_claude_cli
  echo ""

  # Verify source directory
  if [[ ! -d "$SOURCE_DIR" ]]; then
    err "Source directory not found: ${SOURCE_DIR}"
    err "Run this script from the ai-framework repo root."
    exit 1
  fi

  # Install files — enumerate source/ directory at runtime
  echo "  Installing files..."
  while IFS= read -r -d '' src; do
    relative="${src#"${SOURCE_DIR}/"}"
    install_file "$relative"
  done < <(find "$SOURCE_DIR" -type f -print0 | sort -z)
  echo ""

  # Runtime directories
  echo "  Creating runtime directories..."
  create_runtime_dirs
  echo ""

  # Permissions
  echo "  Setting permissions..."
  set_permissions
  echo ""

  # Gitignore
  echo "  Updating .gitignore..."
  update_gitignore

  # Summary
  print_summary
}

main "$@"
