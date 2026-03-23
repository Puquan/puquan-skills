---
title: Auto-Trigger Rules
description: When Claude should proactively use or suggest external agents.
---

# Auto-Trigger Rules

## Proactive Suggestions

Claude suggests using external agents (asks user first) when:

| Condition | Mode | Agent | Prompt Example |
|-----------|------|-------|----------------|
| Complex plan created (5+ steps) | review:plan | codex or both | "Want me to get a second opinion on this plan?" |
| Security-sensitive code written (auth, payments, data handling) | review:code | both | "This touches security -- want a cross-review?" |
| Full plan pipeline completed (brainstorming -> executing-plans) | review:post-exec | codex or both | "Implementation complete -- want a conformance check?" |
| Architecture trade-off with no clear winner | review:debate | both | "Genuine trade-off here -- want to debate this with external agents?" |
| Unfamiliar technology or library | consult | codex | "I'm not fully confident with [tech] -- let me consult Codex." |
| Large boilerplate needed (tests, docs, migrations) | delegate | codex | "This is boilerplate-heavy -- want me to delegate to Codex?" |

## Auto-Use (No Asking)

Claude uses external agents automatically and reports results:

| Condition | Mode | Rationale |
|-----------|------|-----------|
| Debugging loop: same error after 3+ failed attempts | consult | Break the loop with a fresh perspective |

**Conservative by default.** Only the debugging-loop scenario warrants auto-invocation. All other cases: suggest first, act on user approval.

## Integration with Superpowers Workflow

The acpx-peers skill integrates at these touchpoints in the brainstorming -> writing-plans -> executing-plans pipeline:

| Pipeline Stage | Trigger | Suggested Mode |
|---------------|---------|----------------|
| After brainstorming (design doc written) | Design involves 5+ components | review:plan |
| After writing-plans (plan written) | Plan has 5+ steps or cross-module changes | review:plan |
| After executing-plans (code implemented) | Always suggest | review:post-exec |
| During executing-plans (stuck on a step) | 3+ failed attempts on same step | auto consult |
| During executing-plans (boilerplate step) | Test generation, docs, migrations | suggest delegate |

## When NOT to Use External Agents

- Simple single-file edits or bug fixes
- Tasks where the user explicitly said to skip review
- When the user is time-pressured and asked for speed
- Trivial boilerplate that Claude can generate faster than round-tripping to an agent
