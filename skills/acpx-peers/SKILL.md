---
name: acpx-peers
description: Collaborate with external AI agents (Codex, Kimi) via acpx for review, delegation, consultation, and pairing. Use when seeking external validation, delegating development tasks, getting unstuck on debugging or architecture, or wanting a persistent collaboration partner. Replaces codex-audit and multi-audit skills.
---

# acpx-peers

External AI agents are **colleagues with different perspectives**, not superior authorities. Their value is in surfacing blind spots and providing alternative approaches -- not enforcing checklists.

## Core Principles

1. **Code Sovereignty** -- External agents NEVER write to the filesystem. All modifications by Claude only.
2. **Colleague, Not Authority** -- Claude can disagree with any agent's output.
3. **Parallel by Default** -- When using both agents, run them simultaneously.
4. **Background Required** -- ALL `acpx` commands use `run_in_background: true`. Non-negotiable.
5. **Filter, Don't Relay** -- Claude curates results; irrelevant findings are dropped silently.

## Available Agents

| Agent | Model | Strength |
|-------|-------|----------|
| codex | gpt-5.3-codex (high reasoning) | General dev, reasoning, code review, debugging |
| kimi | K2.5 (262k context) | Large context review, alternative perspective |

---

## Modes

### Mode 1: Review

Peer review of plans, code, or implementations. Replaces codex-audit and multi-audit.

**Sub-modes:** `plan`, `code`, `post-exec`, `debate`

**Required blocks** (see [prompt-templates.md](./references/prompt-templates.md)):
- Project Context Block
- Severity Calibration Block
- Claude's Pre-Assessment Block

**Workflow:**
1. Claude fills shared blocks (Project Context, Severity, Pre-Assessment)
2. Build prompt from template in [prompt-templates.md](./references/prompt-templates.md)
3. Execute via acpx (see [cli-patterns.md](./references/cli-patterns.md)):
   - Single model: `acpx --format quiet codex exec [--file .acpx-peers/prompt.md | 'inline']`
   - Dual model: parallel calls to codex + kimi, both `run_in_background: true`
4. Synthesize results per [synthesis-workflow.md](./references/synthesis-workflow.md)
5. Present curated findings to user

**Debate sub-mode** uses named sessions instead of file-based rounds:
1. Create sessions: `acpx codex -s debate-<date>`, `acpx kimi -s debate-<date>`
2. Each round sends prompt to both sessions (context auto-retained)
3. Max 3 rounds, exit when converged or trade-off identified
4. Close sessions when done

**Post-Execution Quick-Fix Path:** After post-exec audit, Claude can auto-fix consensus items and report. See [synthesis-workflow.md](./references/synthesis-workflow.md).

---

### Mode 2: Delegate

Assign development tasks to external agents. Claude specifies, agent produces, Claude reviews and integrates.

**Use cases:**
- Write unit tests for a module
- Generate API documentation
- Prototype alternative implementations
- Create migration scripts
- Produce boilerplate (CRUD, schemas, config)

**Workflow:**
1. Claude writes a Task Specification (see [prompt-templates.md](./references/prompt-templates.md) Delegate Template)
2. Execute: `acpx --format quiet codex exec --file .acpx-peers/delegate-task.md`
3. Claude reviews output through quality gate (see [synthesis-workflow.md](./references/synthesis-workflow.md))
4. Claude integrates selectively -- adapts to project conventions, discards what doesn't fit
5. Claude runs tests to verify

**Key rule:** Delegate output is a **suggestion**. Claude always reviews, adapts, and writes the final code.

---

### Mode 3: Consult

Ask for help when Claude is stuck or uncertain. Lightweight, focused Q&A.

**Use cases:**
- Debugging: stuck after 3+ attempts on same error
- Architecture: choosing between competing approaches
- Unfamiliar tech: need idiomatic patterns for a library/framework
- Performance: need help interpreting profiling output

**Workflow:**
1. Claude formulates a focused question with context (see [prompt-templates.md](./references/prompt-templates.md) Consult Template)
2. Execute: `acpx --format quiet codex exec 'question with context'` (usually short enough for inline)
3. Claude evaluates the answer, applies if useful
4. No formal synthesis -- just direct application of the insight

**No shared blocks needed.** Consult is lightweight: question + context + what would help.

---

### Mode 4: Pair

Persistent named session for ongoing multi-turn collaboration on a complex task.

**Use cases:**
- Extended debugging session requiring back-and-forth
- Collaborative architecture design exploration
- Working through a complex refactoring together

**Workflow:**
1. Start: `acpx codex sessions new --name pair-<topic>`
2. First prompt: `acpx --format quiet codex -s pair-<topic> 'initial context and question'`
3. Continue: `acpx --format quiet codex -s pair-<topic> 'follow-up based on answer'`
4. End: `acpx codex sessions close pair-<topic>`

**Pair vs Debate:** Pair is collaborative (working together toward a goal). Debate is adversarial (stress-testing a position with opposing perspectives).

---

## CLI Quick Reference

All commands: `run_in_background: true` + `--format quiet`.

| Action | Command |
|--------|---------|
| One-shot inline | `acpx --format quiet codex exec 'prompt'` |
| One-shot file | `acpx --format quiet codex exec --file .acpx-peers/prompt.md` |
| Parallel dual | Two background calls (codex + kimi) with same prompt |
| Named session | `acpx --format quiet codex -s <name> 'prompt'` |
| Close session | `acpx codex sessions close <name>` |

Prompt < ~2000 chars → inline. Longer → `--file`. See [cli-patterns.md](./references/cli-patterns.md).

---

## Auto-Trigger Conditions

| Condition | Mode | Action |
|-----------|------|--------|
| Complex plan (5+ steps) | review:plan | Suggest |
| Security-sensitive code | review:code | Suggest |
| Plan pipeline completed | review:post-exec | Suggest |
| Architecture trade-off | review:debate | Suggest |
| Unfamiliar technology | consult | Suggest |
| Large boilerplate needed | delegate | Suggest |
| **Debugging loop (3+ failed attempts)** | **consult** | **Auto-use** |

Only the debugging loop triggers auto-use. All others: suggest first, act on user approval. See [auto-trigger-rules.md](./references/auto-trigger-rules.md).

---

## Runtime Files

```
.acpx-peers/
  prompt.md          # Temp prompt (overwritten, not accumulated)
  delegate-task.md   # Temp delegation spec (overwritten)
```

No response files. acpx returns output to stdout, captured by Bash tool.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Agent timeout | Report to user, suggest retry or other agent |
| Unhelpful response | Claude evaluates independently, proceeds with own judgment |
| One agent fails (dual-model) | Fall back to single-model with the successful one |
| Both agents fail | Report errors, ask user how to proceed |

Never kill a background task without asking the user first.
