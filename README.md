# puquan-skills

A config repository for AI coding agents — [Claude Code](https://claude.ai/code) and [OpenAI Codex CLI](https://github.com/openai/codex). Manages custom skills, rules, and harness configs using **Thin Harness, Fat Skills** architecture.

## Architecture

```
library/      -> 60 custom skills (SKILL.md + optional references/)
rules/        -> Always-on rules for Claude Code sessions
hosts/        -> Thin harness configs (CLAUDE.md, AGENTS.md)
manifests/    -> Per-agent skill selection lists
scripts/      -> install.sh manages per-agent per-skill symlinks
```

### Thin Harness, Fat Skills

- **CLAUDE.md / AGENTS.md** are thin indexes (~40-60 lines) — pointers, not rulebooks
- **Skills** contain the actual knowledge and workflows
- **Rules** provide always-on constraints (coding style, git, security)
- **Plugins** (compound-engineering, gstack) provide their own skills separately

## Installation

```bash
# Install per-agent symlinks + harness configs
scripts/install.sh install

# Preview without changes
scripts/install.sh install --dry-run

# Check current state
scripts/install.sh status

# Remove all managed symlinks
scripts/install.sh uninstall
```

### What gets installed

| Agent | Skills | Harness | Rules |
|-------|--------|---------|-------|
| Claude Code | 60 custom + gstack plugin | `hosts/claude.md` -> `~/.claude/CLAUDE.md` | `rules/` -> `~/.claude/rules/` |
| Codex CLI | 50 (from `manifests/codex-include.txt`) | `hosts/codex.md` -> `~/.codex/AGENTS.md` | Embedded in AGENTS.md |

## Adding a New Skill

1. Create `library/<skill-name>/SKILL.md` with YAML frontmatter
2. If Codex-compatible, add to `manifests/codex-include.txt`
3. Run `scripts/install.sh install`
4. Test in a fresh agent session

### SKILL.md Format

```markdown
---
name: my-skill
description: Brief description of WHEN this skill should trigger
---

# My Skill

## When to Activate
- Concrete trigger scenarios...
```

The `description` field is the most important line — agents use it to decide whether to load the skill.

## Plugin Skills (not in this repo)

| Plugin | Skills | Managed by |
|--------|--------|-----------|
| compound-engineering | 41 (ce:plan, ce:work, ce:review, git-commit, etc.) | Claude Code plugin marketplace |
| gstack | 36 (browse, ship, review, qa, investigate, etc.) | Symlinked from `$GSTACK_PATH` |
