# Coding Style

## Immutability (CRITICAL)

ALWAYS create new objects, NEVER mutate existing ones:

```
// Pseudocode
WRONG:  modify(original, field, value) → changes original in-place
CORRECT: update(original, field, value) → returns new copy with change
```

Rationale: Immutable data prevents hidden side effects, makes debugging easier, and enables safe concurrency.

## File Organization

MANY SMALL FILES > FEW LARGE FILES:
- High cohesion, low coupling
- 200-400 lines typical, 800 max
- Extract utilities from large modules
- Organize by feature/domain, not by type

## Error Handling

ALWAYS handle errors comprehensively:
- Handle errors explicitly at every level
- Provide user-friendly error messages in UI-facing code
- Log detailed error context on the server side
- Never silently swallow errors

## Input Validation

ALWAYS validate at system boundaries:
- Validate all user input before processing
- Use schema-based validation where available
- Fail fast with clear error messages
- Never trust external data (API responses, user input, file content)
- Use `get(key) or default` instead of `get(key, default)` for JSONB/JSON data where values can be explicit null

## Comments

Explain WHY, not WHAT:
- Comment non-obvious decisions and trade-offs
- Self-documenting code preferred over comments
- Never state the obvious (e.g. "increment counter")

## Root Cause Over Fallback

When fixing issues, address the root cause, not the symptom:
- Do NOT add fallbacks, default values, or defensive checks to mask upstream bugs
- Ask "why is this value wrong/missing?" before adding a null check
- A fallback is only justified at true system boundaries (external API, user input)
- Internal code should be trusted — if it produces unexpected values, fix the source

Before submitting non-trivial changes, pause and ask:
- "Am I fixing the root cause or adding a band-aid?"
- "Is there a more direct solution that eliminates the need for this fallback?"
- Skip this for obvious, trivial fixes

## Code Smell Detection

Watch for and fix these anti-patterns:
- **Deep nesting**: Use early returns instead of nested if/else
- **Long functions**: Split into smaller, focused functions
- **Magic numbers**: Extract to named constants

## Bulk Rename / Replace Safety

When using `replace_all` or bulk string replacements:
- ALWAYS grep the result after replacement to verify no doubled substrings (e.g. `ErrorError`, `ServiceService`)
- Check that the replacement target does not already contain the replacement string
- For class/variable renames, search for ALL variants (imports, type hints, string literals, error messages) before replacing

## Code Quality Checklist

Before marking work complete:
- [ ] Code is readable and well-named
- [ ] Functions are small (<50 lines)
- [ ] Files are focused (<800 lines)
- [ ] No deep nesting (>4 levels)
- [ ] Proper error handling
- [ ] No hardcoded values (use constants or config)
- [ ] No mutation (immutable patterns used)
- [ ] No `type: ignore` comments (see below)

## Type Ignore Ban (Python)

NEVER use `# type: ignore` to suppress type checker errors:
- Fix the root cause: wrong annotation, missing type, or incorrect code
- If a third-party stub is wrong, use a properly typed wrapper
- The only exception: a proven false positive in a third-party stub with no workaround, documented with a comment explaining why

## Static vs Runtime Testing

Don't write runtime tests for guarantees already enforced by the type checker:
- Frozen dataclass immutability → Pyright prevents mutation statically
- Enum exhaustiveness → Pyright catches missing cases
- Type narrowing → Pyright validates at compile time
- Runtime tests should verify behavior that cannot be caught statically
