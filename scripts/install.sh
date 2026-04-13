#!/usr/bin/env bash
set -euo pipefail

# --- Constants ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIBRARY_DIR="$REPO_ROOT/library"
RULES_DIR="$REPO_ROOT/rules"
HOSTS_DIR="$REPO_ROOT/hosts"
MANIFESTS_DIR="$REPO_ROOT/manifests"
GSTACK_PATH="${GSTACK_PATH:-$HOME/projects/plugin/gstack}"
MANAGED_MARKER="<!-- managed by puquan-config"

CLAUDE_SKILLS="$HOME/.claude/skills"
CLAUDE_RULES="$HOME/.claude/rules"
CLAUDE_HARNESS="$HOME/.claude/CLAUDE.md"

CODEX_SKILLS="$HOME/.codex/skills"
CODEX_HARNESS="$HOME/.codex/AGENTS.md"

GEMINI_SKILLS="$HOME/.gemini/skills"

DRY_RUN=false

# --- Helpers ---
usage() {
    cat <<'EOF'
Usage: scripts/install.sh [install|uninstall|status] [--dry-run]

Manage per-agent skill symlinks and harness configs.

Commands:
  install    Create per-skill symlinks and copy harness configs (default)
  uninstall  Remove all managed symlinks and harness configs
  status     Show current link state without changes

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
    [[ -L "$path" ]] && [[ "$(readlink "$path")" == "$LIBRARY_DIR/"* || "$(readlink "$path")" == "$GSTACK_PATH"* ]]
}

is_managed_harness() {
    local path="$1"
    [[ -f "$path" ]] && head -1 "$path" 2>/dev/null | grep -q "$MANAGED_MARKER"
}

backup_file() {
    local path="$1"
    if [[ -f "$path" ]]; then
        local backup="${path}.bak.$(date +%Y%m%d%H%M%S)"
        run cp "$path" "$backup"
        log "Backed up: $path -> $backup"
    fi
}

# --- Replace directory symlink with real directory ---
# Preserves .system/ and other non-managed contents
replace_dir_symlink() {
    local target_dir="$1"

    if [[ -L "$target_dir" ]]; then
        # Save any .system/ directory that Codex might have inside
        local tmp_system=""
        if [[ -d "$target_dir/.system" ]]; then
            tmp_system="$(mktemp -d)"
            run cp -R "$target_dir/.system" "$tmp_system/.system"
            log "Preserved .system/ from $target_dir"
        fi

        run rm "$target_dir"
        run mkdir -p "$target_dir"

        # Restore .system/
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
        if [[ "$dest" == "$LIBRARY_DIR/"* || "$dest" == "$GSTACK_PATH"* ]]; then
            # Check if the target still exists
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

# --- Install ---
do_install() {
    echo "=== Installing to Claude Code ==="

    # Validate library exists
    if [[ ! -d "$LIBRARY_DIR" ]]; then
        echo "ERROR: Library directory not found: $LIBRARY_DIR" >&2
        exit 1
    fi

    # Replace directory-level symlink if present
    replace_dir_symlink "$CLAUDE_SKILLS"

    # Clean stale managed symlinks
    clean_stale_symlinks "$CLAUDE_SKILLS"

    # Symlink each skill from library/
    local claude_count=0
    for skill_dir in "$LIBRARY_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local name
        name="$(basename "$skill_dir")"
        [[ "$name" == .* ]] && continue

        local target="$CLAUDE_SKILLS/$name"
        if [[ -L "$target" && "$(readlink "$target")" == "$skill_dir" ]]; then
            claude_count=$((claude_count + 1))
            continue
        fi
        [[ -L "$target" ]] && run rm "$target"
        run ln -s "$skill_dir" "$target"
        claude_count=$((claude_count + 1))
    done
    log "Linked $claude_count custom skills"

    # Symlink gstack
    if [[ -d "$GSTACK_PATH" ]]; then
        local gstack_target="$CLAUDE_SKILLS/gstack"
        if [[ -L "$gstack_target" && "$(readlink "$gstack_target")" == "$GSTACK_PATH" ]]; then
            log "gstack already linked"
        else
            [[ -L "$gstack_target" ]] && run rm "$gstack_target"
            [[ -d "$gstack_target" ]] && log "WARNING: $gstack_target is a directory, skipping gstack" || {
                run ln -s "$GSTACK_PATH" "$gstack_target"
                log "Linked gstack: $gstack_target -> $GSTACK_PATH"
            }
        fi
    else
        log "WARNING: gstack not found at $GSTACK_PATH (set GSTACK_PATH to override)"
    fi

    # Symlink rules
    if [[ -d "$RULES_DIR" ]]; then
        if [[ -L "$CLAUDE_RULES" && "$(readlink "$CLAUDE_RULES")" == "$RULES_DIR" ]]; then
            log "Rules already linked"
        elif [[ -L "$CLAUDE_RULES" ]]; then
            run rm "$CLAUDE_RULES"
            run ln -s "$RULES_DIR" "$CLAUDE_RULES"
            log "Re-linked rules"
        elif [[ ! -e "$CLAUDE_RULES" ]]; then
            run ln -s "$RULES_DIR" "$CLAUDE_RULES"
            log "Linked rules: $CLAUDE_RULES -> $RULES_DIR"
        else
            log "WARNING: $CLAUDE_RULES exists and is not a symlink, skipping rules"
        fi
    fi

    # Copy harness config
    if [[ -f "$HOSTS_DIR/claude.md" ]]; then
        if ! is_managed_harness "$CLAUDE_HARNESS"; then
            backup_file "$CLAUDE_HARNESS"
        fi
        run cp "$HOSTS_DIR/claude.md" "$CLAUDE_HARNESS"
        log "Installed harness: $CLAUDE_HARNESS"
    fi

    echo ""
    echo "=== Installing to Codex ==="

    # Replace directory-level symlink if present
    replace_dir_symlink "$CODEX_SKILLS"

    # Clean stale managed symlinks
    clean_stale_symlinks "$CODEX_SKILLS"

    # Read include list
    local codex_include="$MANIFESTS_DIR/codex-include.txt"
    if [[ ! -f "$codex_include" ]]; then
        echo "ERROR: Codex include list not found: $codex_include" >&2
        exit 1
    fi

    local codex_count=0
    while IFS= read -r name || [[ -n "$name" ]]; do
        [[ -z "$name" || "$name" == \#* ]] && continue
        local skill_dir="$LIBRARY_DIR/$name"
        if [[ ! -d "$skill_dir" ]]; then
            log "WARNING: Skill not found in library: $name"
            continue
        fi

        local target="$CODEX_SKILLS/$name"
        if [[ -L "$target" && "$(readlink "$target")" == "$skill_dir" ]]; then
            codex_count=$((codex_count + 1))
            continue
        fi
        [[ -L "$target" ]] && run rm "$target"
        run ln -s "$skill_dir" "$target"
        codex_count=$((codex_count + 1))
    done < "$codex_include"
    log "Linked $codex_count skills from include list"

    # Copy harness config
    if [[ -f "$HOSTS_DIR/codex.md" ]]; then
        if ! is_managed_harness "$CODEX_HARNESS"; then
            backup_file "$CODEX_HARNESS"
        fi
        run cp "$HOSTS_DIR/codex.md" "$CODEX_HARNESS"
        log "Installed harness: $CODEX_HARNESS"
    fi

    echo ""
    echo "=== Cleaning up Gemini ==="

    if [[ -L "$GEMINI_SKILLS" ]]; then
        run rm "$GEMINI_SKILLS"
        log "Removed Gemini skills symlink"
    else
        log "No Gemini symlink to remove"
    fi

    echo ""
    echo "=== Checking for unlisted skills ==="
    check_unlisted_skills

    echo ""
    echo "Done."
}

# --- Uninstall ---
do_uninstall() {
    echo "=== Uninstalling Claude skills ==="
    if [[ -d "$CLAUDE_SKILLS" ]]; then
        local removed=0
        for link in "$CLAUDE_SKILLS"/*/; do
            link="${link%/}"
            if is_managed_symlink "$link"; then
                run rm "$link"
                removed=$((removed + 1))
            fi
        done
        log "Removed $removed managed symlinks"

        # Remove gstack symlink
        if [[ -L "$CLAUDE_SKILLS/gstack" ]]; then
            local dest
            dest="$(readlink "$CLAUDE_SKILLS/gstack")"
            if [[ "$dest" == "$GSTACK_PATH"* ]]; then
                run rm "$CLAUDE_SKILLS/gstack"
                log "Removed gstack symlink"
            fi
        fi
    fi

    # Restore harness if managed
    if is_managed_harness "$CLAUDE_HARNESS"; then
        run rm "$CLAUDE_HARNESS"
        log "Removed managed harness: $CLAUDE_HARNESS"
    fi

    echo ""
    echo "=== Uninstalling Codex skills ==="
    if [[ -d "$CODEX_SKILLS" ]]; then
        local removed=0
        for link in "$CODEX_SKILLS"/*/; do
            link="${link%/}"
            if is_managed_symlink "$link"; then
                run rm "$link"
                removed=$((removed + 1))
            fi
        done
        log "Removed $removed managed symlinks"
    fi

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
        managed=$(find "$CLAUDE_SKILLS" -maxdepth 1 -type l -exec readlink {} \; 2>/dev/null | grep -c "$LIBRARY_DIR" || true)
        broken=$(find "$CLAUDE_SKILLS" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l | tr -d ' ')
        echo "  skills: $total symlinks ($managed managed, $broken broken)"

        if [[ -L "$CLAUDE_SKILLS/gstack" ]]; then
            echo "  gstack: -> $(readlink "$CLAUDE_SKILLS/gstack")"
        else
            echo "  gstack: NOT LINKED"
        fi
    else
        echo "  skills: NOT FOUND"
    fi

    if is_managed_harness "$CLAUDE_HARNESS"; then
        echo "  harness: managed"
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
        managed=$(find "$CODEX_SKILLS" -maxdepth 1 -type l -exec readlink {} \; 2>/dev/null | grep -c "$LIBRARY_DIR" || true)
        broken=$(find "$CODEX_SKILLS" -maxdepth 1 -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l | tr -d ' ')
        echo "  skills: $total symlinks ($managed managed, $broken broken)"
    else
        echo "  skills: NOT FOUND"
    fi

    if is_managed_harness "$CODEX_HARNESS"; then
        echo "  harness: managed"
    elif [[ -f "$CODEX_HARNESS" ]]; then
        echo "  harness: exists (not managed)"
    else
        echo "  harness: NOT FOUND"
    fi

    echo ""
    echo "=== Gemini ==="
    if [[ -L "$GEMINI_SKILLS" ]]; then
        echo "  skills: SYMLINK -> $(readlink "$GEMINI_SKILLS") (should be removed)"
    elif [[ -d "$GEMINI_SKILLS" ]]; then
        echo "  skills: directory exists"
    else
        echo "  skills: not present (clean)"
    fi

    echo ""
    echo "=== Library ==="
    echo "  path: $LIBRARY_DIR"
    echo "  skills: $(find "$LIBRARY_DIR" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"

    echo ""
    check_unlisted_skills
}

# --- Check for skills not in any manifest ---
check_unlisted_skills() {
    local codex_include="$MANIFESTS_DIR/codex-include.txt"
    local unlisted=()

    for skill_dir in "$LIBRARY_DIR"/*/; do
        [[ -d "$skill_dir" ]] || continue
        local name
        name="$(basename "$skill_dir")"
        [[ "$name" == .* ]] && continue

        if ! grep -qx "$name" "$codex_include" 2>/dev/null; then
            unlisted+=("$name")
        fi
    done

    if [[ ${#unlisted[@]} -gt 0 ]]; then
        echo "Skills not in codex-include.txt (Claude-only): ${#unlisted[@]}"
        for s in "${unlisted[@]}"; do
            echo "  - $s"
        done
    fi
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
