---
title: acpx CLI Patterns
description: Command patterns for all acpx-peers modes.
---

# acpx CLI Patterns

## Universal Rules

1. **ALL acpx commands MUST use `run_in_background: true`** in Bash tool. Running foreground blocks Claude Code.
2. **Always use `--format quiet`** for clean output.
3. **No model flags needed.** acpx uses each agent's own config (codex = gpt-5.3-codex/high, kimi = K2.5).
4. **No `2>/dev/null` needed.** `--format quiet` handles suppression.
5. **Use `TaskOutput`** with `block: true, timeout: 600000` to wait for results.

## Prompt Length Strategy

| Length | Strategy | Form |
|--------|----------|------|
| < ~2000 chars | Inline | `acpx --format quiet <agent> exec 'prompt'` |
| > ~2000 chars | File | `acpx --format quiet <agent> exec --file .acpx-peers/prompt.md` |

File-based: write to `.acpx-peers/prompt.md` (overwritten each time, not accumulated).

## One-Shot Patterns

```bash
# Single agent, inline
acpx --format quiet codex exec 'your prompt here'

# Single agent, file-based
acpx --format quiet codex exec --file .acpx-peers/prompt.md

# Parallel dual-model (two separate run_in_background calls)
acpx --format quiet codex exec --file .acpx-peers/prompt.md
acpx --format quiet kimi exec --file .acpx-peers/prompt.md
```

## Persistent Session Patterns

```bash
# Create named session
acpx codex sessions new --name <name>

# Send prompt (context auto-preserved)
acpx --format quiet codex -s <name> 'your prompt'

# Follow-up (same session, context retained)
acpx --format quiet codex -s <name> 'follow-up question'

# Close
acpx codex sessions close <name>

# Status check
acpx codex sessions list
```

## Mode-Specific Patterns

### Review (one-shot or dual-model)
```bash
acpx --format quiet codex exec --file .acpx-peers/prompt.md
acpx --format quiet kimi exec --file .acpx-peers/prompt.md  # parallel if dual
```

### Debate (named sessions, multi-round)
```bash
acpx --format quiet codex -s debate-<date> 'round N prompt with context'
acpx --format quiet kimi -s debate-<date> 'round N prompt with context'
# Close when done
acpx codex sessions close debate-<date>
acpx kimi sessions close debate-<date>
```

### Delegate (task assignment)
```bash
acpx --format quiet codex exec --file .acpx-peers/delegate-task.md
```

### Consult (quick question, usually inline)
```bash
acpx --format quiet codex exec 'stuck on [problem]. tried [X]. error: [Y]. what am I missing?'
```

### Pair (persistent collaboration)
```bash
acpx codex sessions new --name pair-<topic>
acpx --format quiet codex -s pair-<topic> 'initial context'
acpx --format quiet codex -s pair-<topic> 'follow-up'
acpx codex sessions close pair-<topic>
```

## Agent Selection

| Agent | Best For |
|-------|----------|
| codex | General dev, reasoning, code review, debugging |
| kimi | Large context (>100k tokens), alternative perspective |
| both | High-stakes reviews, architecture, security |

## Runtime Files

```
.acpx-peers/
  prompt.md          # Temp prompt (overwritten each time)
  delegate-task.md   # Temp delegation spec (overwritten each time)
```

No response files -- acpx returns output to stdout, captured by Bash tool.
