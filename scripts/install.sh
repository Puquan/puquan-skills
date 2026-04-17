#!/usr/bin/env bash
set -euo pipefail

# --- Constants ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CLAUDE_LIBRARY_DIR="$REPO_ROOT/library/claude"
CODEX_LIBRARY_DIR="$REPO_ROOT/library/codex"
RULES_DIR="$REPO_ROOT/rules"
HOSTS_DIR="$REPO_ROOT/hosts"

CLAUDE_SKILLS="$HOME/.claude/skills"
CLAUDE_RULES="$HOME/.claude/rules"
CLAUDE_HARNESS="$HOME/.claude/CLAUDE.md"

CODEX_SKILLS="$HOME/.codex/skills"
CODEX_RULES="$HOME/.codex/rules"
CODEX_HARNESS="$HOME/.codex/AGENTS.md"

DRY_RUN=false

# --- Helpers ---
usage() {
    cat <<'EOF'
Usage: scripts/install.sh [install|uninstall|status] [--dry-run]

Manage per-agent skill symlinks and harness configs.

Commands:
  install    Create per-skill symlinks and copy harness configs (default)
  uninstall  Remove all managed symlinks and harness configs
  status     Show current link state

Options:
  -n, --dry-run  Print planned actions without executing
  -h, --help     Show this help message
EOF
}

run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        printf '[dry-run] %s\n' "$*"
        return 0
    fi
    "$@"
}

log() {
    echo "  $1"
}

is_managed_symlink() {
    local path="$1"
    if [[ ! -L "$path" ]]; then
        return 1
    fi
    local dest
    dest="$(readlink "$path")"
    [[ "$dest" == "$CLAUDE_LIBRARY_DIR/"* || "$dest" == "$CODEX_LIBRARY_DIR/"* ]]
}

is_managed_harness() {
    local path="$1"
    [[ -L "$path" ]] && [[ "$(readlink "$path")" == "$HOSTS_DIR/"* ]]
}

# --- Replace directory symlink with real directory ---
replace_dir_symlink() {
    local target_dir="$1"

    if [[ -L "$target_dir" ]]; then
        local tmp_system=""
        if [[ -d "$target_dir/.system" ]]; then
            tmp_system="$(mktemp -d)"
            run cp -R "$target_dir/.system" "$tmp_system/.system"
            log "Preserved .system/ from $target_dir"
        fi

        run rm "$target_dir"
        run mkdir -p "$target_dir"

        if [[ -n "$tmp_system" && -d "$tmp_system/.system" ]]; then
            run mv "$tmp_system/.system" "$target_dir/.system"
            rm -rf "$tmp_system"
            log "Restored .system/ to $target_dir"
        fi
    elif [[ ! -d "$target_dir" ]]; then
        run mkdir -p "$target_dir"
    fi
}

# --- Clean stale managed symlinks ---
clean_stale_symlinks() {
    local target_dir="$1"
    local removed=0

    if [[ ! -d "$target_dir" ]]; then
        return
    fi

    for link in "$target_dir"/*/; do
        link="${link%/}"
        [[ -L "$link" ]] || continue
        local dest
        dest="$(readlink "$link")"
        if [[ "$dest" == "$CLAUDE_LIBRARY_DIR/"* || "$dest" == "$CODEX_LIBRARY_DIR/"* ]]; then
            if [[ ! -e "$link" ]]; then
                run rm "$link"
                removed=$((removed + 1))
            fi
        fi
    done

    if [[ $removed -gt 0 ]]; then
        log "Removed $removed stale symlinks from $target_dir"
    fi
}

# --- Link rules directory ---
link_rules() {
    local src="$1" dest="$2"
    [[ -d "$src" ]] || return
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        log "Rules already linked: $dest"
    elif [[ -L "$dest" ]]; then
        run rm "$dest"
        run ln -s "$src" "$dest"
        log "Re-linked rules: $dest"
    elif [[ ! -e "$dest" ]]; then
        run ln -s "$src" "$dest"
        log "Linked rules: $dest -> $src"
    else
        # Plain directory: back up and replace with symlink
        local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        run mv "$dest" "$backup"
        log "Backed up existing rules dir: $backup"
        run ln -s "$src" "$dest"
        log "Linked rules: $dest -> $src"
    fi
}

# --- Link harness config file ---
link_harness() {
    local src="$1" dest="$2"
    [[ -f "$src" ]] || return
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        log "Harness already linked: $dest"
    elif [[ -L "$dest" ]]; then
        run rm "$dest"
        run ln -s "$src" "$dest"
        log "Re-linked harness: $dest"
    elif [[ ! -e "$dest" ]]; then
        run ln -s "$src" "$dest"
        log "Linked harness: $dest -> $src"
    else
        local backup="${dest}.bak.$(date +%Y%m%d%H%M%S)"
        run mv "$dest" "$backup"
        log "Backed up existing harness: $backup"
        run ln -s "$src" "$dest"
        log "Linked harness: $dest -> $src"
    fi
}

# --- Install skills from a library dir into a skills dir ---
install_skills() {
    local library_dir="$1"
    local skills_dir="$2"
    local label="$3"

    replace_dir_symlink "$skills_dir"
    clean_stale_symlinks "$skills_dir"

    local count=0
    for skill_dir in "$library_dir"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local name
        name="$(basename "$skill_dir")"
        [[ "$name" == .* ]] && continue

        local target="$skills_dir/$name"
        if [[ -L "$target" && "$(readlink "$target")" == "$skill_dir" ]]; then
            count=$((count + 1))
            continue
        fi
        [[ -L "$target" ]] && run rm "$target"
        run ln -s "$skill_dir" "$target"
        count=$((count + 1))
    done
    log "Linked $count skills ($label)"
}

# --- Install ---
do_install() {
    echo "=== Installing to Claude Code ==="

    if [[ ! -d "$CLAUDE_LIBRARY_DIR" ]]; then
        echo "ERROR: Library directory not found: $CLAUDE_LIBRARY_DIR" >&2
        exit 1
    fi

    install_skills "$CLAUDE_LIBRARY_DIR" "$CLAUDE_SKILLS" "claude"
    link_rules "$RULES_DIR" "$CLAUDE_RULES"

    link_harness "$HOSTS_DIR/claude.md" "$CLAUDE_HARNESS"

    echo ""
    echo "=== Installing to Codex ==="

    if [[ ! -d "$CODEX_LIBRARY_DIR" ]]; then
        echo "ERROR: Library directory not found: $CODEX_LIBRARY_DIR" >&2
        exit 1
    fi

    install_skills "$CODEX_LIBRARY_DIR" "$CODEX_SKILLS" "codex"
    link_rules "$RULES_DIR" "$CODEX_RULES"

    link_harness "$HOSTS_DIR/codex.md" "$CODEX_HARNESS"

    echo ""
    echo "Done."
}

# --- Uninstall ---
do_uninstall() {
    echo "=== Uninstalling Claude ==="
    if [[ -d "$CLAUDE_SKILLS" ]]; then
        local removed=0
        for link in "$CLAUDE_SKILLS"/*/; do
            link="${link%/}"
            if is_managed_symlink "$link"; then
                run rm "$link"
                removed=$((removed + 1))
            fi
        done
        log "Removed $removed managed skill symlinks"
    fi

    [[ -L "$CLAUDE_RULES" ]] && run rm "$CLAUDE_RULES" && log "Removed rules symlink"

    if is_managed_harness "$CLAUDE_HARNESS"; then
        run rm "$CLAUDE_HARNESS"
        log "Removed managed harness: $CLAUDE_HARNESS"
    fi

    echo ""
    echo "=== Uninstalling Codex ==="
    if [[ -d "$CODEX_SKILLS" ]]; then
        local removed=0
        for link in "$CODEX_SKILLS"/*/; do
            link="${link%/}"
            if is_managed_symlink "$link"; then
                run rm "$link"
                removed=$((removed + 1))
            fi
        done
        log "Removed $removed managed skill symlinks"
    fi

    [[ -L "$CODEX_RULES" ]] && run rm "$CODEX_RULES" && log "Removed rules symlink"

    if is_managed_harness "$CODEX_HARNESS"; then
        run rm "$CODEX_HARNESS"
        log "Removed managed harness: $CODEX_HARNESS"
    fi

    echo ""
    echo "Done. Use backed-up .bak files to restore previous configs."
}

# --- Status ---
do_status() {
    echo "=== Claude Code ==="
    if [[ -L "$CLAUDE_SKILLS" ]]; then
        echo "  skills: DIRECTORY SYMLINK -> $(readlink "$CLAUDE_SKILLS") (old style)"
    elif [[ -d "$CLAUDE_SKILLS" ]]; then
        local total managed broken
        total=$(find "$CLAUDE_SKILLS" -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
        managed=$(find "$CLAUDE_SKILLS" -maxdepth 1 -type l -exec readlink {} \; 2>/dev/null | grep -c "$CLAUDE_LIBRARY_DIR" || true)
        broken=$(find "$CLAUDE_SKILLS" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l | tr -d ' ')
        echo "  skills: $total symlinks ($managed managed, $broken broken)"
    else
        echo "  skills: NOT FOUND"
    fi

    if is_managed_harness "$CLAUDE_HARNESS"; then
        echo "  harness: -> $(readlink "$CLAUDE_HARNESS")"
    elif [[ -f "$CLAUDE_HARNESS" ]]; then
        echo "  harness: exists (not managed)"
    else
        echo "  harness: NOT FOUND"
    fi

    if [[ -L "$CLAUDE_RULES" ]]; then
        echo "  rules: -> $(readlink "$CLAUDE_RULES")"
    elif [[ -d "$CLAUDE_RULES" ]]; then
        echo "  rules: directory (not symlink)"
    else
        echo "  rules: NOT FOUND"
    fi

    echo ""
    echo "=== Codex ==="
    if [[ -L "$CODEX_SKILLS" ]]; then
        echo "  skills: DIRECTORY SYMLINK -> $(readlink "$CODEX_SKILLS") (old style)"
    elif [[ -d "$CODEX_SKILLS" ]]; then
        local total managed broken
        total=$(find "$CODEX_SKILLS" -maxdepth 1 -type l 2>/dev/null | wc -l | tr -d ' ')
        managed=$(find "$CODEX_SKILLS" -maxdepth 1 -type l -exec readlink {} \; 2>/dev/null | grep -c "$CODEX_LIBRARY_DIR" || true)
        broken=$(find "$CODEX_SKILLS" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l | tr -d ' ')
        echo "  skills: $total symlinks ($managed managed, $broken broken)"
    else
        echo "  skills: NOT FOUND"
    fi

    if is_managed_harness "$CODEX_HARNESS"; then
        echo "  harness: -> $(readlink "$CODEX_HARNESS")"
    elif [[ -f "$CODEX_HARNESS" ]]; then
        echo "  harness: exists (not managed)"
    else
        echo "  harness: NOT FOUND"
    fi

    if [[ -L "$CODEX_RULES" ]]; then
        echo "  rules: -> $(readlink "$CODEX_RULES")"
    elif [[ -d "$CODEX_RULES" ]]; then
        echo "  rules: directory (not symlink)"
    else
        echo "  rules: NOT FOUND"
    fi

    echo ""
    echo "=== Library ==="
    echo "  claude: $(find "$CLAUDE_LIBRARY_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') skills"
    echo "  codex:  $(find "$CODEX_LIBRARY_DIR"  -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ') skills"
}

# --- Parse args ---
COMMAND="install"

while [[ $# -gt 0 ]]; do
    case "$1" in
        install|uninstall|status)
            COMMAND="$1"
            shift
            ;;
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

# --- Execute ---
case "$COMMAND" in
    install)   do_install ;;
    uninstall) do_uninstall ;;
    status)    do_status ;;
esac
