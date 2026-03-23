---
description: Generate a handoff document for the next AI agent when context is too long or switching sessions. Usage: /handoff [topic]
---

# Handoff Command

When the current context is too long to continue effectively, generate a structured handoff document so that **any** AI agent (not just Claude Code) can pick up the work with zero prior context.

## Usage

```
/handoff                    # auto-generate topic from current task
/handoff auth-refactor      # explicit topic
/handoff db-migration       # explicit topic
```

## Process

### Step 1: Determine the filename

Construct the filename as: `{YYMMDD}-{HHMM}-{topic}-handoff.md`

- `YYMMDD` and `HHMM`: current date and time
- `topic`: use `$ARGUMENTS` if provided; otherwise infer a 2-4 word kebab-case slug from the current task (e.g., `auth-refactor`, `api-pagination`, `hook-cleanup`)

The file is written to the **current working directory**.

### Step 2: Gather raw information

Before writing anything, collect:

1. Review the full conversation to identify: task goal, decisions made, things tried, things that failed
2. Run `git status` and `git diff --name-only` to get the actual file change list
3. Run `git log --oneline -5` to get recent commits
4. Run `git branch --show-current` to get the current branch
5. Note any uncommitted changes

### Step 3: Write the handoff document

Use the Write tool to create the file with the structure below. Be specific — use file paths, function names, error messages, and command outputs. Avoid vague summaries.

---

## Handoff Document Structure

```markdown
# Handoff: {topic}

**Date:** YYYY-MM-DD HH:MM
**Branch:** {current branch}
**Uncommitted changes:** yes/no

> {2-3 sentence TL;DR: what project, what task, how far along}

## 1. Task Goal

What problem is being solved, what the expected output is, and what "done" looks like.

## 2. Current Progress

What has been completed so far. Include:
- Analysis, decisions, and discussion outcomes
- Code changes made (with file paths)
- Tests written or run
- Verification results

### Files Changed This Session

List from `git diff --name-only` and any uncommitted changes:

- `path/to/file.ts` - what was changed and why
- `path/to/other.ts` - what was changed and why

### Recent Commits

```
{output of git log --oneline -5}
```

## 3. Key Context

Background and constraints the next agent must know:

- **User requirements:** explicit asks from the user
- **Constraints:** technical limitations, compatibility requirements
- **Decisions made:** choices already settled (and why) — do not re-litigate these
- **Assumptions:** things assumed true but not verified

## 4. Key Findings

Conclusions, root causes, patterns, or anomalies discovered during this session. These are the **outputs** of analysis, not background info.

## 5. Unfinished Items

Ordered by priority:

1. {highest priority item}
2. {next item}
3. ...

## 6. Suggested Handoff Path

Tell the next agent:
- Which files/modules/logs to read first
- What to verify before continuing
- Recommended next action

## 7. Risks and Pitfalls

- Approaches already tried and failed (do NOT retry these)
- Easy misinterpretations or traps
- Areas that look simple but have hidden complexity

---

**Next agent's first step:** {one concrete, actionable instruction}
```

### Step 4: Confirm with the user

After writing, display:

```
Handoff saved to: {actual file path}

Review it — anything to correct or add?
```

Wait for user confirmation. Make edits if requested.

---

## Notes

- This is a technical handoff document, not a user-facing summary. Write for an agent, not a human reader.
- Prioritize actionable, specific information over completeness. A shorter document with exact file paths and error messages beats a longer one with vague descriptions.
- Do not include pleasantries, encouragement, or meta-commentary about the handoff process itself.
- The document must be self-contained — the next agent has NO access to the current conversation.
- If `$ARGUMENTS` is empty, infer the topic; never prompt the user for it.
