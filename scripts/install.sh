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
Usage: scripts/install.sh [install|uninstall|status|clean] [--dry-run]

Manage per-agent skill symlinks and harness configs.

Commands:
  install    Create per-skill symlinks and copy harness configs (default)
  uninstall  Remove all managed symlinks and harness configs
  status     Show current link state and detect pollution
  clean      Remove unmanaged entries from skills directories
             (e.g. leftover dirs from gstack setup or plugin installs)

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
    # Managed if pointing to library/, gstack root, or gstack sub-dirs
    [[ "$dest" == "$LIBRARY_DIR/"* || "$dest" == "$GSTACK_PATH" || "$dest" == "$GSTACK_PATH/"* ]]
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

    # Symlink gstack sub-skills (per-skill, not whole-repo)
    local gstack_manifest="$MANIFESTS_DIR/gstack-skills.txt"
    if [[ -d "$GSTACK_PATH" && -f "$gstack_manifest" ]]; then
        local gstack_count=0
        while IFS= read -r name || [[ -n "$name" ]]; do
            [[ -z "$name" || "$name" == \#* ]] && continue

            # 'gstack' entry points to the repo root (meta-skill)
            # all others point to sub-directories
            local source
            if [[ "$name" == "gstack" ]]; then
                source="$GSTACK_PATH"
            else
                source="$GSTACK_PATH/$name"
            fi

            if [[ ! -d "$source" ]]; then
                log "WARNING: gstack skill not found: $name"
                continue
            fi

            local target="$CLAUDE_SKILLS/$name"
            if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
                gstack_count=$((gstack_count + 1))
                continue
            fi
            # Remove stale symlink or conflicting real directory
            [[ -L "$target" ]] && run rm "$target"
            if [[ -d "$target" && ! -L "$target" ]]; then
                run rm -rf "$target"
                log "Replaced unmanaged directory: $name"
            fi
            run ln -s "$source" "$target"
            gstack_count=$((gstack_count + 1))
        done < "$gstack_manifest"
        log "Linked $gstack_count gstack skills"
    elif [[ ! -d "$GSTACK_PATH" ]]; then
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

        # Remove gstack symlinks
        local gstack_removed=0
        for link in "$CLAUDE_SKILLS"/*/; do
            link="${link%/}"
            [[ -L "$link" ]] || continue
            local dest
            dest="$(readlink "$link")"
            if [[ "$dest" == "$GSTACK_PATH" || "$dest" == "$GSTACK_PATH/"* ]]; then
                run rm "$link"
                gstack_removed=$((gstack_removed + 1))
            fi
        done
        # Also check the gstack entry itself (not a subdir)
        if [[ -L "$CLAUDE_SKILLS/gstack" ]]; then
            local dest
            dest="$(readlink "$CLAUDE_SKILLS/gstack")"
            if [[ "$dest" == "$GSTACK_PATH" ]]; then
                run rm "$CLAUDE_SKILLS/gstack"
                gstack_removed=$((gstack_removed + 1))
            fi
        fi
        log "Removed $gstack_removed gstack symlinks"
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

        local gstack_count
        gstack_count=$(find "$CLAUDE_SKILLS" -maxdepth 1 -type l -exec readlink {} \; 2>/dev/null | grep -c "^$GSTACK_PATH" || true)
        echo "  gstack skills: $gstack_count (from $GSTACK_PATH)"
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
    echo "=== Pollution Check ==="
    local has_pollution=false
    detect_pollution "$CLAUDE_SKILLS" "Claude skills"
    [[ ${#POLLUTION_ENTRIES[@]} -gt 0 ]] && has_pollution=true
    detect_pollution "$CODEX_SKILLS" "Codex skills"
    [[ ${#POLLUTION_ENTRIES[@]} -gt 0 ]] && has_pollution=true
    if [[ "$has_pollution" == "false" ]]; then
        echo "  All clean"
    else
        echo "  Run 'scripts/install.sh clean' to remove unmanaged entries"
    fi

    echo ""
    check_unlisted_skills
}

# --- Detect unmanaged entries (pollution) ---
# Returns entries via the POLLUTION_ENTRIES array
detect_pollution() {
    local target_dir="$1"
    local label="$2"
    POLLUTION_ENTRIES=()

    [[ -d "$target_dir" ]] || return

    for item in "$target_dir"/*/; do
        item="${item%/}"
        local name
        name="$(basename "$item")"

        # Skip hidden dirs (.system, etc.)
        [[ "$name" == .* ]] && continue

        # Skip our managed symlinks (pointing to library/ or gstack)
        if [[ -L "$item" ]]; then
            local dest
            dest="$(readlink "$item")"
            if [[ "$dest" == "$LIBRARY_DIR/"* || "$dest" == "$GSTACK_PATH"* ]]; then
                continue
            fi
        fi

        # Everything else is unmanaged: real dirs, foreign symlinks, stale files
        POLLUTION_ENTRIES+=("$name")
    done

    if [[ ${#POLLUTION_ENTRIES[@]} -gt 0 ]]; then
        echo "  Unmanaged entries in $label: ${#POLLUTION_ENTRIES[@]}"
        for entry in "${POLLUTION_ENTRIES[@]}"; do
            if [[ -L "$target_dir/$entry" ]]; then
                echo "    - $entry (symlink -> $(readlink "$target_dir/$entry"))"
            elif [[ -d "$target_dir/$entry" ]]; then
                echo "    - $entry (directory)"
            else
                echo "    - $entry (file)"
            fi
        done
    fi
}

# --- Clean: remove unmanaged entries ---
do_clean() {
    echo "=== Scanning for pollution ==="
    echo ""

    local total_removed=0

    for target_info in "$CLAUDE_SKILLS:Claude" "$CODEX_SKILLS:Codex"; do
        local target_dir="${target_info%%:*}"
        local label="${target_info##*:}"

        echo "--- $label ($target_dir) ---"
        detect_pollution "$target_dir" "$label"

        if [[ ${#POLLUTION_ENTRIES[@]} -eq 0 ]]; then
            echo "  Clean: no unmanaged entries"
            echo ""
            continue
        fi

        for entry in "${POLLUTION_ENTRIES[@]}"; do
            local path="$target_dir/$entry"
            if [[ -L "$path" ]]; then
                run rm "$path"
                log "Removed foreign symlink: $entry"
            elif [[ -d "$path" ]]; then
                run rm -rf "$path"
                log "Removed unmanaged directory: $entry"
            else
                run rm "$path"
                log "Removed unmanaged file: $entry"
            fi
            total_removed=$((total_removed + 1))
        done
        echo ""
    done

    # Clean stale Codex prompts from compound-engineering
    local codex_prompts="$HOME/.codex/prompts"
    if [[ -d "$codex_prompts" ]]; then
        echo "--- Codex prompts ($codex_prompts) ---"
        local prompts_removed=0
        for f in "$codex_prompts"/*.md; do
            [[ -f "$f" ]] || continue
            local fname
            fname="$(basename "$f")"
            # Only remove compound-engineering generated prompts (ce-*.md pattern)
            if [[ "$fname" == ce-*.md ]]; then
                run rm "$f"
                log "Removed plugin prompt: $fname"
                prompts_removed=$((prompts_removed + 1))
                total_removed=$((total_removed + 1))
            fi
        done
        if [[ $prompts_removed -eq 0 ]]; then
            echo "  Clean: no plugin prompts"
        fi
        echo ""
    fi

    echo "Total removed: $total_removed"
    if [[ "$DRY_RUN" == "true" && $total_removed -gt 0 ]]; then
        echo "(dry-run: nothing was actually removed)"
    fi
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
        install|uninstall|status|clean)
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
    clean)     do_clean ;;
esac
