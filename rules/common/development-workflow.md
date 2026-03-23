# Development Workflow

> This file extends [common/git-workflow.md](./git-workflow.md) with the full feature development process that happens before git operations.

The Feature Implementation Workflow describes the development pipeline: research, planning, TDD, code review, and then committing to git.

## Feature Implementation Workflow

0. **Research & Reuse** _(mandatory before any new implementation)_
   - **GitHub code search first:** Run `gh search repos` and `gh search code` to find existing implementations, templates, and patterns before writing anything new.
   - **Exa MCP for research:** Use `exa-web-search` MCP during the planning phase for broader research, data ingestion, and discovering prior art.
   - **Check package registries:** Search npm, PyPI, crates.io, and other registries before writing utility code. Prefer battle-tested libraries over hand-rolled solutions.
   - **Search for adaptable implementations:** Look for open-source projects that solve 80%+ of the problem and can be forked, ported, or wrapped.
   - Prefer adopting or porting a proven approach over writing net-new code when it meets the requirement.

1. **Plan First (only when no plan exists)**
   - If a plan/spec/task document already exists and the user asks to execute/implement → **skip to step 2 (TDD)**
   - Read ONLY the plan document and directly relevant source files, then start coding immediately
   - Do NOT create a new plan when one already exists
   - If no plan exists:
     - Use **planner** agent to create implementation plan
     - Generate planning docs before coding: PRD, architecture, system_design, tech_doc, task_list
     - Identify dependencies and risks
     - Break down into phases

1.5. **Mid-Execution Course Correction**
   - If implementation deviates from the plan, encounters unexpected complexity, or produces results that don't match intent: **STOP immediately**
   - Do not push through hoping it will work out — re-enter Plan Mode and revise the approach
   - Re-planning is cheaper than debugging a wrong direction

2. **TDD Approach**
   - Use **tdd-guide** agent
   - Write tests first (RED)
   - Implement to pass tests (GREEN)
   - Refactor (IMPROVE)
   - Verify 80%+ coverage

3. **Code Review**
   - Use **code-reviewer** agent immediately after writing code
   - Address CRITICAL and HIGH issues
   - Fix MEDIUM issues when possible
   - **Incremental fix strategy**: When multiple issues are found (from any review or audit),
     fix them one at a time — fix one issue, run tests, verify pass, then move to the next.
     Do NOT batch-fix all issues at once.

3.5. **External Review Escalation** _(optional, triggered by conditions)_
   - Use **acpx-peers** skill when internal review is insufficient:
     - Security-sensitive changes → `review:code` (dual-model: codex + kimi)
     - Architectural uncertainty → `review:debate` or `consult`
     - Stuck debugging (3+ attempts) → `consult` (auto-triggered)
   - **Superpowers workflow integration:**
     - After `brainstorming` design doc → suggest `review:plan` if 5+ components
     - After `writing-plans` → suggest `review:plan` if cross-module
     - After `executing-plans` → suggest `review:post-exec` for conformance check
     - During `executing-plans`, boilerplate step → suggest `delegate`
   - Internal code-reviewer remains the default; external is the escalation path

4. **Commit & Push**
   - Detailed commit messages
   - Follow conventional commits format
   - See [git-workflow.md](./git-workflow.md) for commit message format and PR process
