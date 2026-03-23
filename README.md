# puquan-skills

A collection of skills, commands, and rules for AI coding agents — [Claude Code](https://claude.ai/code), [OpenAI Codex CLI](https://github.com/openai/codex), and [Gemini CLI](https://github.com/google-gemini/gemini-cli).

## What Are Skills?

Skills are on-demand knowledge modules for AI coding agents. When an agent encounters a task matching a skill's description, it loads the skill to gain domain expertise, enforce workflows, or follow coding patterns — like **just-in-time instructions**.

## Skills

| Skill | Domain |
|-------|--------|
| `python-testing` | pytest, TDD, fixtures, mocking, coverage |
| `python-patterns` | Pythonic idioms, PEP 8, type hints |
| `postgres-patterns` | Query optimization, schema design, indexing |
| `api-design` | REST resource naming, status codes, pagination |
| `backend-patterns` | Node.js, Express, Next.js API routes |
| `frontend-patterns` | React, Next.js, state management |
| `security-review` | OWASP, auth, input validation, secrets |
| `deployment-patterns` | CI/CD, Docker, health checks, rollback |
| `agentic-engineering` | Eval-first agent development |
| `ai-first-engineering` | AI-augmented engineering team model |
| `agent-harness-construction` | Agent tool design and action spaces |
| `search-first` | Research-before-coding workflow |
| `acpx-peers` | External AI agent collaboration (Codex, Kimi) |
| `twitter-reader` | Fetch tweet content via jina.ai API |

## Commands

| Command | Purpose |
|---------|---------|
| `/plan` | Create implementation plan before coding |
| `/tdd` | Enforce test-driven development workflow |
| `/code-review` | Code review checklist |
| `/python-review` | Python-specific code review |
| `/refactor-clean` | Dead code cleanup |
| `/deep-review-with-update` | Exhaustive review + doc updates |
| `/handoff` | Generate session handoff document |
| `/skill-create` | Extract patterns from git history into new skills |

## Skill Anatomy

Each skill is a directory under `skills/`:

```
my-skill/
├── SKILL.md           # Required — YAML frontmatter + markdown instructions
├── references/        # Optional — supporting documentation
└── scripts/           # Optional — helper scripts
```

### SKILL.md Format

```markdown
---
name: my-skill
description: Brief description of WHEN this skill should trigger
---

# My Skill

## When to Activate
- Concrete trigger scenarios...

## Core Concepts
- Patterns and guidelines...

## Code Examples
```

The `description` field is the most important line — agents use it to decide whether to load the skill.

## Platform Support

| Platform | Skill Path | Instructions File |
|----------|-----------|-------------------|
| Claude Code | `~/.claude/skills/` | `CLAUDE.md` |
| Codex CLI | `~/.codex/skills/` or `.agents/skills/` | `AGENTS.md` |
| Gemini CLI | `~/.gemini/skills/` | `GEMINI.md` |

### Claude Code Frontmatter

| Field | Purpose |
|-------|---------|
| `name` | Skill name and `/slash-command` trigger |
| `description` | **Required** — agent auto-loads skills by matching this |
| `disable-model-invocation` | `true` = user-only, agent won't auto-trigger |
| `user-invocable` | `false` = agent-only, hidden from `/` menu |
| `allowed-tools` | Restrict tools available when skill is active |
| `context: fork` | Run in isolated sub-agent |

### Codex Frontmatter

Same `name` + `description` in SKILL.md. Optional `agents/openai.yaml` for UI metadata and `allow_implicit_invocation` control.

## Adding a New Skill

1. Create `skills/<skill-name>/SKILL.md`
2. Write a precise `description` — state when to trigger AND when not to
3. Keep under 500 lines; use `references/` for detailed docs
4. Write in imperative voice with concrete code examples
5. Include a "When to Activate" section with trigger scenarios
6. Test by invoking in a fresh agent session

## Installation

```bash
# Symlink skills/ to all three agent platforms
scripts/install-skills.sh

# Preview without changes
scripts/install-skills.sh --dry-run
```
