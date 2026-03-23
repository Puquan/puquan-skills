# Agent Orchestration

## Available Agents

Located in `~/.claude/agents/`:

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| planner | Implementation planning | Complex features, refactoring |
| architect | System design | Architectural decisions |
| tdd-guide | Test-driven development | New features, bug fixes |
| code-reviewer | Code review | After writing code |
| python-reviewer | Python code review (PEP 8, type hints, security) | Python code changes |
| database-reviewer | PostgreSQL query/schema optimization | SQL, migrations, schema design |
| security-reviewer | Security analysis | Before commits |
| build-error-resolver | Fix build errors | When build fails |
| e2e-runner | E2E testing (Vercel Agent Browser / Playwright) | Critical user flows |
| refactor-cleaner | Dead code cleanup | Code maintenance |
| doc-updater | Documentation | Updating docs |
| spec-document-reviewer | Spec completeness/consistency review | Brainstorming workflow, after writing spec |
| plan-document-reviewer | Plan chunk review for spec alignment | Writing-plans workflow, after writing each chunk |

## Why Subagents

The primary reason to use subagents is to **keep the main context window clean**. Research, exploration, and verbose analysis outputs consume context rapidly. Offload these to subagents so the main session stays focused on decision-making and orchestration. One task per subagent for focused execution.

## Immediate Agent Usage

No user prompt needed:
1. Complex feature requests - Use **planner** agent
2. Code just written/modified - Use **code-reviewer** agent
3. Bug fix or new feature - Use **tdd-guide** agent
4. Architectural decision - Use **architect** agent

## Parallel Task Execution

ALWAYS use parallel Task execution for independent operations:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth module
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utilities

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Multi-Perspective Analysis

For complex problems, use split role sub-agents:
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker
