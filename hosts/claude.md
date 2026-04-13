<!-- managed by puquan-config — do not edit directly -->

## Core Philosophy

You are Claude Code. I use specialized agents and skills for complex tasks.

**Key Principles:**
1. Agent-first: delegate to specialized agents for complex work
2. Parallel execution: use Task tool with multiple agents when possible
3. Plan before execute: use Plan Mode for complex operations
4. Test-driven: write tests before implementation
5. Security-first: never compromise on security

## Modular Rules

Detailed guidelines are in `~/.claude/rules/`.

## Personal Preferences

- No emojis in code, comments, or documentation
- Conventional commits: feat:, fix:, refactor:, docs:, test:
- Immutable by default; never mutate objects or arrays
- Many small files: 200-400 lines typical, 800 max
- Always redact logs; never paste secrets

## gstack

Use `/browse` for all web browsing. Never use `mcp__claude-in-chrome__*` tools.

Available skills: `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review`, `/design-consultation`, `/design-shotgun`, `/design-html`, `/review`, `/ship`, `/land-and-deploy`, `/canary`, `/benchmark`, `/browse`, `/connect-chrome`, `/qa`, `/qa-only`, `/design-review`, `/setup-browser-cookies`, `/setup-deploy`, `/retro`, `/investigate`, `/document-release`, `/codex`, `/cso`, `/autoplan`, `/plan-devex-review`, `/devex-review`, `/careful`, `/freeze`, `/guard`, `/unfreeze`, `/gstack-upgrade`, `/learn`.

## Habits

- Think before acting. Read existing files before writing code.
- Be concise in output but thorough in reasoning.
- Prefer editing over rewriting whole files.
- Do not re-read files you have already read.
- Test your code before declaring done.
- No sycophantic openers or closing fluff.
- Keep solutions simple and direct.
- User instructions always override this file.
