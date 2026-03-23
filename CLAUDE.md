# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

A skill design and maintenance repository for AI coding agents (Claude Code, OpenAI Codex CLI, Gemini CLI). The work here is authoring, refining, and organizing skills — not building an application.

## Repository Structure

```
skills/       → One directory per skill (SKILL.md + optional references/scripts)
commands/     → Slash commands invoked via /name (e.g., /plan, /tdd, /code-review)
rules/        → Global rules auto-loaded into every agent session
  common/     → Language-agnostic (git, testing, security, coding style)
  python/     → Python-specific
  typescript/ → TypeScript-specific
scripts/      → install-skills.sh symlinks skills/ to ~/.claude, ~/.codex, ~/.gemini
```

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

| Field | Purpose |
|-------|---------|
| `description` | **Required** — agents auto-load skills by matching this to the current task |
| `name` | Display name and `/slash-command` name; defaults to directory name |
| `disable-model-invocation` | `true` = user-only via `/name`, agent won't auto-trigger |
| `user-invocable` | `false` = hidden from `/` menu, only agent can invoke |
| `allowed-tools` | Restrict available tools when skill is active |
| `context` | `fork` = run in isolated sub-agent |
| `agent` | Sub-agent type when `context: fork` (`Explore`, `Plan`, etc.) |

### Codex Frontmatter

Codex discovers skills from `.agents/skills/`. Optional `agents/openai.yaml` can specify:
- `display_name`, `short_description` — UI metadata
- `allow_implicit_invocation: false` — disable auto-matching
- `dependencies.tools` — required MCP tools

## Skill Quality Criteria

When creating or updating skills:

1. **Description is everything** — agents decide whether to load a skill based solely on `description`. State WHEN to trigger AND when NOT to trigger.
2. **Under 500 lines** — detailed references go in `references/` subdirectory.
3. **Self-contained** — skills load in isolation without surrounding context.
4. **Imperative voice** — "Review the code", not "This skill reviews code".
5. **One workflow per skill** — split broad topics into focused modules.
6. **Include a "When to Activate" section** — list concrete trigger scenarios (see `python-testing` as example).
7. **Code examples over prose** — agents learn patterns better from examples than descriptions.
8. **Test in a fresh session** — invoke the skill in a new agent session to verify behavior.

## Command Format (commands/*.md)

```markdown
---
description: Brief description shown in /help
---

# Command Name

## What This Command Does
## When to Use
## Workflow
```

Commands differ from skills: commands are always user-invoked via `/name`, skills can be auto-triggered by the agent.

## Rules (rules/*.md)

Rules are always-on constraints loaded into every session. Unlike skills, they have no frontmatter — just markdown. Organize by:
- `common/` — applies to all languages
- `python/` or `typescript/` — language-specific overrides

## Editing Conventions

- Skills are invoked via `Skill` tool in Claude Code, never `Read` directly
- The `acpx-peers` skill requires all `acpx` commands to use `run_in_background: true`
- When adding a skill, also consider whether it should have a corresponding `/command` entry
