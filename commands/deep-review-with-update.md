---
description: Deep, exhaustive review of all recent changes. No shortcuts. Updates docs/changelog/postmortem as needed.
---

# Deep Review

Exhaustive, no-shortcuts review. Not a quick scan — the most thorough review you can do.

## Mindset

- Think extremely deep. Question every decision.
- Reject anything heuristic, cheap, short-term, or inelegant.
- Every line must be sharp, wise, valuable, and built for the long term.
- Zero redundancy. Zero waste. Maximum efficiency.
- "Good enough" is not good enough.

## Execution

### 1. Scope

Determine what changed:
- `git log --oneline -20` for narrative
- `git diff HEAD~10 --stat` for scope (adjust range to $ARGUMENTS if provided)
- Read every changed file in full. No skimming.

### 2. Deep Review via Agents

Dispatch in parallel:
- **code-reviewer** agent on all changed files (quality, patterns, substance)
- **security-reviewer** agent on security-sensitive changes

These agents already cover code quality checklists, security checklists, and best practices. Do not duplicate their work here.

### 3. Architecture Judgment

This is what the agents cannot do — your unique value. For each change, ask:
- Why does this exist? Is there a simpler way?
- Is this the right abstraction level?
- Does this create coupling or redundancy?
- Will this need rewriting in 3 months?
- Is the naming precise?

### 4. Documentation

Check and update as needed:
- README, design docs, changelog, postmortem, API docs
- If stale or missing, update them as part of this review.

### 5. Verdict

```
DEEP REVIEW: [PASS / NEEDS WORK / FAIL]

Summary: [2-3 sentences]

Critical Issues (must fix):
- [file:line] description → fix

Improvements (should fix):
- [file:line] description → fix

Docs Updated:
- [list, or "none needed"]
```

## Rules

- Do NOT rubber-stamp. If everything looks perfect, look harder.
- Focus on substance, not style nits.
- If something needs fixing, fix it (with user approval).

## Arguments

$ARGUMENTS can be:
- (empty) - Last 10 commits (default)
- `--since <ref>` - Since a specific commit/tag/branch
- `--file <path>` - Single file deep review
- `--scope <dir>` - Changes within a directory
