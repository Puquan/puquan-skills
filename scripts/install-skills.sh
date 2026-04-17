#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: scripts/install-skills.sh [--dry-run]

Create symlinks from this repository's skills directory to:
  ~/.claude/skills
  ~/.codex/skills
  ~/.gemini/skills

Options:
  -n, --dry-run  Print planned actions without changing the filesystem
  -h, --help     Show this help message
EOF
}

DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_SKILLS_DIR="$REPO_ROOT/skills"

if [[ ! -d "$SOURCE_SKILLS_DIR" ]]; then
    echo "Skills source directory not found: $SOURCE_SKILLS_DIR" >&2
    exit 1
fi

TARGETS=(
    "$HOME/.claude/skills"
    "$HOME/.codex/skills"
    "$HOME/.gemini/skills"
)

run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        printf '[dry-run] %s\n' "$*"
        return 0
    fi

    "$@"
}

validate_target() {
    local target="$1"

    if [[ -L "$target" ]]; then
        local current_target
        current_target="$(readlink "$target")"

        if [[ "$current_target" == "$SOURCE_SKILLS_DIR" ]]; then
            return 0
        fi

        echo "Refusing to replace existing symlink: $target -> $current_target" >&2
        return 1
    fi

    if [[ -e "$target" ]]; then
        echo "Refusing to replace existing path: $target" >&2
        return 1
    fi
}

install_link() {
    local target="$1"
    local parent
    parent="$(dirname "$target")"

    if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$SOURCE_SKILLS_DIR" ]]; then
        echo "Already linked: $target -> $SOURCE_SKILLS_DIR"
        return 0
    fi

    run mkdir -p "$parent"
    run ln -s "$SOURCE_SKILLS_DIR" "$target"

    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would link: $target -> $SOURCE_SKILLS_DIR"
        return 0
    fi

    echo "Linked: $target -> $SOURCE_SKILLS_DIR"
}

for target in "${TARGETS[@]}"; do
    if validate_target "$target"; then
        install_link "$target"
    else
        echo "Skipped: $target (remove it manually to re-link)"
    fi
done
