---
name: acpx-peers
description: Use when a spec, plan, or completed implementation needs external peer review via acpx, especially when follow-up rounds may be needed.
---

# acpx-peers

Peer review with external AI agents via `acpx` CLI. They are colleagues — not authorities.

## Core Rules

1. **Run acpx commands asynchronously** — don't block your main thread. In Claude Code use `run_in_background: true`; in other harnesses use the equivalent non-blocking mechanism.
2. **Use `--format quiet`** on prompt/exec commands for clean output. Session management commands (`sessions ensure/list/close`) don't need it.
3. **Code sovereignty** — external agents never write to the filesystem.
4. **Reference files by path** — peer agents can read local files. Just tell them which file to review instead of pasting content into the prompt.
5. **Use sessions** — multi-round is the default. Use `exec` only for simple one-off questions that don't need follow-up.
6. **Never call yourself.** Pick peers that are different agents from you. See agent selection below.

## Agent Selection

You are one of the agents in the acpx network. **Choose peers, not yourself:**

| If you are... | Your peers are |
|---------------|---------------|
| Claude Code | `codex`, `kimi` |
| Codex | `claude`, `kimi` |
| Gemini | `codex`, `claude`, `kimi` |
| Kimi | `codex`, `claude` |

Available agents and their strengths:

| Agent | Default Model | Strength |
|-------|--------------|----------|
| codex | gpt-5.4 (high reasoning) | General dev, reasoning, code review, debugging |
| claude | Claude (Opus/Sonnet) | Architecture, nuanced analysis, long context |
| kimi | K2.5 (262k context) | Large docs, alternative perspective |

Agents use their own local config by default. acpx does not override — it passes through to whatever model the agent is configured to use.

### Codex Model/Reasoning Override

Override the default model or reasoning level per command:

```bash
# Use a different model
acpx --model gpt-5.4 codex exec 'prompt'

# Set reasoning level within a session
acpx codex set thought_level high -s <session-name>
```

Codex reasoning levels: `low`, `medium` (default), `high`, `extra_high`.

Global flags go **before** the agent name:

```bash
acpx --format quiet --model gpt-5.4 codex -s review-auth-0323 --file .acpx-peers/prompt.md
```

In all examples below, `<peer>` means whichever agent you chose — substitute accordingly.

---

## Workflow: Multi-Round Review

### Step 1: Open Session

Use a unique name per review to avoid mixing contexts with old sessions:

```bash
acpx <peer> sessions ensure --name review-<topic>-<date>
```

`ensure` is idempotent — creates if new, reuses if exists.

### Step 2: Send First Round

Peer agents have local filesystem access — just point them to the file:

```bash
acpx --format quiet <peer> -s review-<topic>-<date> 'We are building [one sentence].
Phase: [prototype | MVP | production].

Review docs/specs/my-design.md. Focus on:
1. Real risks at this phase
2. Blind spots we likely missed

Skip style nitpicks and out-of-scope features.'
```

For long or complex prompts, write to a file and use `--file` to send. Note: `--file` sends the file **content** as the prompt text — it does not tell the peer to read that path.

```bash
mkdir -p .acpx-peers
# Write your prompt to .acpx-peers/prompt.md, then:
acpx --format quiet <peer> -s review-<topic>-<date> --file .acpx-peers/prompt.md
```

Wait for the response before proceeding (in Claude Code: `TaskOutput` with `block: true, timeout: 600000`).

That's it. No severity calibration blocks. No pre-assessment templates. The document is already on disk — let the reviewer read it.

### Step 3: Evaluate Response

Read the review. For each finding, decide:

| Assessment | Action |
|-----------|--------|
| Agree + important | Fix it |
| Agree + minor | Note for later |
| Disagree | Push back in next round |
| Irrelevant | Ignore |

### Step 4: Fix, Then Continue Conversation

Fix what you agree with. Then tell the reviewer what you did:

```bash
acpx --format quiet <peer> -s review-<topic>-<date> 'Fixed the following:
- [issue 1]: [what you changed]
- [issue 2]: [what you changed]

Disagreed on [issue 3] because [reason].

Anything else you see?'
```

If you need to send a long follow-up, use `--file`:

```bash
mkdir -p .acpx-peers
# Write follow-up to .acpx-peers/round2.md, then:
acpx --format quiet <peer> -s review-<topic>-<date> --file .acpx-peers/round2.md
```

### Step 5: Repeat Until Consensus

Continue the conversation until:
- Reviewer says "looks good" or equivalent
- All substantive issues are resolved
- Remaining disagreements are acknowledged trade-offs

If after 3-4 rounds you still disagree on substantive issues, stop and ask the user to decide. Don't loop indefinitely.

Typical reviews take 2-3 rounds.

### Step 6: Close Session

```bash
acpx <peer> sessions close review-<topic>-<date>
rm -f .acpx-peers/prompt.md .acpx-peers/round*.md
```

---

## When to Use

| Workflow Stage | Trigger | What to Review |
|---------------|---------|---------------|
| After brainstorming | Spec/design doc written | The spec document |
| After writing-plans | Plan document written | The plan document |
| After executing-plans | Implementation complete | Code diff or key files |

### When NOT to Use

- Simple single-file edits or bug fixes
- User explicitly asked to skip review
- Trivial changes that don't need a second opinion

---

## Dual-Model Review

For high-stakes reviews (security, architecture), run two peers in parallel:

```bash
acpx <peer1> sessions ensure --name review-<topic>-<date>
acpx <peer2> sessions ensure --name review-<topic>-<date>

# Send to both — run these asynchronously
acpx --format quiet <peer1> -s review-<topic>-<date> --file .acpx-peers/prompt.md
acpx --format quiet <peer2> -s review-<topic>-<date> --file .acpx-peers/prompt.md
```

Wait for both to respond before synthesizing. If both flag the same issue, high confidence. If they disagree, use your judgment or ask the user.

Follow-up rounds work the same — send to both sessions.

---

## CLI Quick Reference

```bash
# Session management
acpx <peer> sessions ensure --name <name>     # Create or reuse
acpx <peer> sessions list                      # List active sessions
acpx <peer> sessions close <name>              # Clean up

# Send message (within session, use --format quiet)
acpx --format quiet <peer> -s <name> 'inline prompt'
acpx --format quiet <peer> -s <name> --file path/to/prompt.md

# One-shot (no session, for simple one-off questions)
acpx --format quiet <peer> exec 'quick question'
acpx --format quiet <peer> exec --file .acpx-peers/prompt.md
```

---

## Error Handling

| Situation | Action |
|-----------|--------|
| Agent timeout | Retry once, then report to user |
| Unhelpful response | Proceed with own judgment |
| One agent fails (dual-model) | Continue with the other |
| Session lost (TTL expired) | Create new session, resend context |
