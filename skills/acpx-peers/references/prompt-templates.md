---
title: Prompt Templates
description: All prompt templates for acpx-peers modes.
---

# Prompt Templates

## Shared Blocks

### Project Context Block (REQUIRED for Review mode)

Claude MUST fill this before sending any review prompt:

```
## Project Context
- Phase: [prototype | MVP | production | scaling]
- Current Priority: [e.g., "validate core logic" | "ship v1"]
- Known Conscious Trade-offs: [what the team chose to defer and WHY]
- Out of Scope for This Review: [areas to NOT comment on]
```

### Severity Calibration (REQUIRED for Review mode)

```
## Severity Guide
- CRITICAL: Will cause data loss, security breach, or system failure at the CURRENT phase
- HIGH: Significant risk before the next stated milestone
- MEDIUM: Worth improving for next phase, not blocking now
- LOW: Stylistic or aspirational
- NOTE: Not a problem -- observation or alternative worth knowing
```

### Claude's Pre-Assessment (REQUIRED for Review mode)

```
## Claude's Pre-Assessment

**Areas I'm confident about:**
[What Claude believes is solid and WHY]

**Areas I'm uncertain about:**
[What Claude wants reviewers to focus on]

**Specific questions:**
[2-3 targeted questions -- high-value review targets]
```

---

## Review Templates

### Plan Audit

```
You are a pragmatic engineering peer reviewing a technical plan.

Evaluate whether the plan is fit for its stated purpose and current phase -- not an ideal-state checklist.

[Project Context Block]
[Severity Calibration Block]
[Claude's Pre-Assessment Block]

## Plan Under Review
[plan content]

## Review Focus
1. Real risks at this phase
2. Blind spots the team likely missed
3. Claude's uncertainty areas
4. Feasibility -- are steps clear and realistic?

Do NOT flag out-of-scope features, suggest production infra for prototypes, or nitpick style.

## Output Format

**Strengths** (2-3 genuine):

**Findings** (real issues, calibrated to phase):
[SEVERITY] [CATEGORY] - [Title]
Issue: [what's wrong]
Impact: [real-world consequence at current phase]
Suggestion: [pragmatic fix]

**Answers to Claude's Questions:**

**Overall Assessment:**
Risk Level: [HIGH | MEDIUM | LOW]
Key Concern Count: [N at HIGH+]
Verdict: [LOOKS GOOD | MINOR ISSUES | NEEDS REVISION]
```

### Code Audit

```
You are a pragmatic engineering peer reviewing code changes.

Catch real bugs, security issues, and design problems that matter at this phase.

[Project Context Block]
[Severity Calibration Block]
[Claude's Pre-Assessment Block]

## Code Under Review
[diff or code]

## Review Focus
1. Correctness -- logic errors, race conditions, real edge cases
2. Security -- exploitable in current deployment context
3. Claude's uncertainty areas
4. Subtle bugs easy to miss in self-review

Do NOT suggest error handling for impossible scenarios, flag missing tests for prototypes, or comment on style.

## Output Format

**Strengths** (2-3):

**Findings** (real issues only):
[SEVERITY] [CATEGORY] - [Title]
Location: [file:line]
Issue: [what's wrong]
Impact: [what could go wrong]
Fix: [minimal pragmatic fix]

**Answers to Claude's Questions:**

**Overall Assessment:**
Risk Level: [HIGH | MEDIUM | LOW]
Key Concern Count: [N at HIGH+]
Verdict: [LOOKS GOOD | MINOR ISSUES | NEEDS REVISION]
```

### Post-Execution Audit

```
You are a pragmatic engineering peer reviewing an implementation against its design and plan.

Goal: does what was built match what was intended? Any bugs or oversights?

[Project Context Block]
[Severity Calibration Block]

## Upstream Artifacts

### Original Design
[design doc content]

### Implementation Plan
[plan content]

### Actual Code Changes
[git diff or key file contents]

## Claude's Post-Execution Self-Review

**What went well:**
[Areas matching design/plan]

**Where I deviated or am unsure:**
[Deviations, shortcuts, mismatches -- high-value targets]

**Specific questions:**
[2-3 targeted questions]

## Review Focus (priority order)
1. Conformance -- does code implement what design specified?
2. Plan deviations -- justified or problematic?
3. Correctness -- logic errors, edge cases
4. Integration -- do pieces work together?

Do NOT re-review the design, suggest architectural alternatives, or recommend features beyond design.

## Output Format

**Conformance Check:**
- [MATCH | PARTIAL | MISSING] [Component] -- [note]

**Findings** (real issues):
[SEVERITY] [CATEGORY] - [Title]
Location: [file:line]
Issue: [what's wrong]
Plan said: [expected]
Code does: [actual]
Fix: [minimal fix to align with design]

**Answers to Claude's Questions:**

**Overall Assessment:**
Conformance: [FULL | MOSTLY ALIGNED | SIGNIFICANT GAPS]
Bug Risk: [HIGH | MEDIUM | LOW]
Verdict: [SHIP IT | FIX AND SHIP | NEEDS REWORK]
```

### Debate Round N

```
## Round X Discussion

### Original Proposal
[Full original proposal]

### Previous Round Summary
- Codex argued: [key points]
- Kimi argued: [key points]
- Claude's position: [counter-arguments or questions]

### Please respond to:
1. Which points from the other reviewer do you accept?
2. Which do you still disagree with, and why specifically?
3. Any new considerations?

### Output Format
For each tracked point:
[STATUS] [CATEGORY] - [Title]
Previous position: [summary]
Counter-argument: [what other model/Claude said]
Your assessment: RESOLVED | STILL DISAGREE | PARTIALLY AGREE
Reasoning: [why]

Overall: CONVERGING | STILL DIVERGING | NEED USER INPUT
Key remaining disagreement (if any): [one sentence]
```

---

## Delegate Template

### Task Specification

```
You are an expert developer executing a specific task. Produce high-quality, ready-to-integrate output.

## Task
- Objective: [what to produce]
- Acceptance Criteria: [how to judge completeness]
- Constraints: [project conventions, tech stack, patterns to follow]
- Output Format: [code | documentation | analysis | migration script]

## Context
[Relevant code, architecture, dependencies -- enough for the agent to work independently]

## Project Conventions
[Language, framework, naming, file organization patterns to follow]

## Deliverables
Produce the output directly. No explanations unless the task requires documentation.
If you encounter blockers or ambiguity, state them clearly and produce best-effort output.
```

---

## Consult Template

### Question Block

```
I need your expertise on a specific problem.

## Question
[The focused question]

## Context
[What Claude has tried, what failed, relevant code/errors/output]

## What Would Help
[The specific kind of answer needed -- diagnosis, approach suggestion, code example, trade-off analysis]
```

No Project Context, Severity, or Pre-Assessment needed. Keep it lightweight and focused.
