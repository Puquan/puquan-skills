# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

A config repository for AI coding agents (Claude Code, OpenAI Codex CLI). Manages custom skills, rules, and harness configs using **Thin Harness, Fat Skills** architecture.

## Repository Structure

```
library/
  claude/  -> Claude Code 技能（每个技能逐个软链到 ~/.claude/skills/）
  codex/   -> Codex 技能（每个技能逐个软链到 ~/.codex/skills/）
rules/        -> Global rules (symlinked to both ~/.claude/rules and ~/.codex/rules)
  common/     -> Language-agnostic (git, testing, security, coding style)
  python/     -> Python-specific
  typescript/ -> TypeScript-specific
hosts/        -> Thin harness configs per agent
  claude.md   -> Installed to ~/.claude/CLAUDE.md
  codex.md    -> Installed to ~/.codex/AGENTS.md
scripts/      -> install.sh manages per-agent per-skill symlinks
```

## Installation

```bash
# Install (creates per-skill symlinks + copies harness configs)
scripts/install.sh install

# Preview without changes
scripts/install.sh install --dry-run

# Check current state
scripts/install.sh status

# Remove all managed symlinks
scripts/install.sh uninstall
```

### What install.sh does

- **Claude**: Symlinks each skill from `library/claude/` to `~/.claude/skills/`. Symlinks `rules/` to `~/.claude/rules`. Copies `hosts/claude.md` to `~/.claude/CLAUDE.md`.
- **Codex**: Symlinks each skill from `library/codex/` to `~/.codex/skills/`. Symlinks `rules/` to `~/.codex/rules`. Copies `hosts/codex.md` to `~/.codex/AGENTS.md`.

Symlink direction (`~/.claude/skills/foo → {repo}/library/claude/foo`) means edits in either location modify the same file — no explicit sync needed.

## SKILL.md Format

```markdown
---
name: skill-name              # Lowercase, hyphens only, max 64 chars
description: When to trigger   # CRITICAL — agents match tasks to skills via this field
---

# Skill Title

Instructions in markdown...
```

### Claude Code Frontmatter

| Field                      | Purpose                                                                     |
| -------------------------- | --------------------------------------------------------------------------- |
| `description`              | **Required** — agents auto-load skills by matching this to the current task |
| `name`                     | Display name and `/slash-command` name; defaults to directory name          |
| `disable-model-invocation` | `true` = user-only via `/name`, agent won't auto-trigger                    |
| `user-invocable`           | `false` = hidden from `/` menu, only agent can invoke                       |
| `allowed-tools`            | Restrict available tools when skill is active                               |
| `context`                  | `fork` = run in isolated sub-agent                                          |
| `agent`                    | Sub-agent type when `context: fork` (`Explore`, `Plan`, etc.)               |

## Skill Quality Criteria

When creating or updating skills:

1. **Description is everything** — agents decide whether to load a skill based solely on `description`. State WHEN to trigger AND when NOT to trigger.
2. **Under 500 lines** — detailed references go in `references/` subdirectory.
3. **Self-contained** — skills load in isolation without surrounding context.
4. **Imperative voice** — "Review the code", not "This skill reviews code".
5. **One workflow per skill** — split broad topics into focused modules.
6. **Include a "When to Activate" section** — list concrete trigger scenarios.
7. **Code examples over prose** — agents learn patterns better from examples than descriptions.
8. **Test in a fresh session** — invoke the skill in a new agent session to verify behavior.

## Adding a New Skill

1. Create `library/claude/<skill-name>/SKILL.md` and/or `library/codex/<skill-name>/SKILL.md`
2. Run `scripts/install.sh install` to update symlinks
3. Test in a fresh Claude Code session

## Rules (rules/*.md)

Rules are always-on constraints loaded into every session. Unlike skills, they have no frontmatter — just markdown. Organize by:
- `common/` — applies to all languages
- `python/` or `typescript/` — language-specific overrides

## Editing Conventions

- Skills are invoked via `Skill` tool in Claude Code, never `Read` directly
- The `acpx-peers` skill requires all `acpx` commands to use `run_in_background: true`
- Harness files (`hosts/*.md`) start with `<!-- managed by puquan-config -->` — edit in repo, not in `~/.claude/`
