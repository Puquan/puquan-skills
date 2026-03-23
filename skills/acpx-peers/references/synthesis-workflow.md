---
title: Synthesis Workflow
description: How Claude filters, evaluates, and presents external agent responses.
---

# Synthesis Workflow

## Principle: Filter, Don't Relay

Claude acts as **filter and arbiter**, not a relay. External agent output is raw material for Claude's judgment.

---

## Single-Model Evaluation

After receiving one agent's response, Claude categorizes each finding:

| Claude's Assessment | Action |
|---------------------|--------|
| Agree + Important | **Should fix** -- recommend to user |
| Agree + Low priority | **Optional** -- list under improvements |
| Disagree | **Flag disagreement** with Claude's reasoning |
| Irrelevant to current phase | **Drop** silently |

## Dual-Model Synthesis

After receiving both Codex and Kimi responses:

| Situation | Action |
|-----------|--------|
| Both agree + Claude agrees | **Should fix** -- high confidence |
| One flags + Claude agrees | **Should fix** -- note which model caught it |
| Both agree + Claude disagrees | **Flag disagreement** -- present Claude's reasoning |
| One flags + Claude disagrees | **Optional** -- low priority unless compelling |
| Both flag different aspects of same issue | **Merge** into single finding |
| Irrelevant to current phase | **Drop** silently |

## Presentation Format

### Review Results (Single or Dual Model)

```
## Review Results

**Should fix** (Claude + reviewer(s) agree):
1. [Issue] -- [rationale]

**Optional improvements:**
1. [Issue] -- [why it can wait]

**Disagreements** (Claude disagrees with reviewer):
1. [Reviewer said X] -- [Claude's counter-reasoning]

**Model divergence** (Codex and Kimi disagree, dual-model only):
1. [Topic] -- Codex: [position] vs Kimi: [position] -- Claude's take: [assessment]

What would you like to do?
- Fix the "should fix" items
- Discuss a specific point
- See raw output from [agent]
- Enter Debate Mode on disagreements
```

### User Response Handling

| User Says | Action |
|-----------|--------|
| "Fix it" | Implement agreed fixes |
| "Skip" | Move on |
| "Show raw" | Display full agent output |
| "Debate" | Enter Debate Mode |
| "Your call" | Claude decides on its own judgment |

---

## Quick-Fix Path (Post-Execution Audit Only)

After receiving post-execution audit results, Claude can auto-fix clear consensus items:

| Category | Action |
|----------|--------|
| Reviewer(s) agree + clear fix | **Auto-fix**: Claude fixes immediately |
| Reviewer(s) agree + complex fix | **Recommend**: present to user with approach |
| Models disagree | **Flag**: present both perspectives |
| Conformance gap (missing feature) | **Flag**: may be intentional scope cut |

### Auto-Fix Report

```
Post-execution review complete.

**Auto-fixed** (consensus, clear fix):
1. [file:line] -- [what was wrong] -> [what Claude fixed]

**Needs your input:**
1. [Issue] -- [why it needs discussion]

**Disagreements:**
1. [Topic] -- [Reviewer said X] -- [Claude's take]

All auto-fixes applied. Tests: [PASS/FAIL].
```

---

## Delegate Quality Gate

After receiving delegate output, Claude reviews before integrating:

1. **Correctness check** -- Does the output do what was specified?
2. **Convention check** -- Does it follow project patterns (naming, structure, style)?
3. **Security check** -- Any obvious vulnerabilities introduced?
4. **Integration check** -- Will it work with existing code without conflicts?

| Assessment | Action |
|------------|--------|
| Good quality, fits conventions | Integrate directly |
| Good logic, needs style adjustments | Adapt and integrate |
| Partially useful | Extract useful parts, discard rest |
| Poor quality or wrong approach | Discard, do it manually or re-delegate with better spec |

**Code Sovereignty**: Claude is the only one that writes to the filesystem. Delegate output is always reviewed and adapted before integration.

---

## Consult Response Handling

Consult responses are lightweight -- no formal synthesis:

1. Claude evaluates the answer for correctness and relevance
2. If useful: apply the insight, continue working
3. If partially useful: extract the relevant part
4. If unhelpful: discard, try a different approach or ask the other agent
5. No formal report to user unless the answer changed Claude's approach significantly

---

## Debate Convergence

### Per-Round Evaluation

For each tracked point across models:

| Finding Type | Action |
|--------------|--------|
| Objective flaw (provably wrong) | Accept and fix |
| Subjective trade-off | Surface to user with all perspectives |
| Alternative approach | Evaluate merit, present pros/cons |
| Style/convention preference | Acknowledge and move on |

### Exit Conditions

- **Converged**: All parties agree on approach
- **Trade-off identified**: Core disagreement is genuine -- present both sides to user
- **Max rounds reached** (default 3): Summarize remaining differences for user decision
- **User decides**: User can cut in at any point

### Debate Report

```
# Debate Report

## Summary
Rounds: N | Agents: [codex, kimi] | Outcome: [Converged | Trade-off | User Decision Needed]

## Consensus
[Points all parties agree on]

## Key Trade-off (if applicable)
|  | Option A | Option B |
|--|----------|----------|
| Approach | [description] | [description] |
| Codex favors | [why] | |
| Kimi favors | | [why] |
| Claude favors | [position + reasoning] | |

## Action Items
[Concrete next steps]

## Decision Status
[READY TO PROCEED | AWAITING USER DECISION on: specific question]
```
