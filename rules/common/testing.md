# Testing Requirements

## Coverage Expectations

Target **80%+** coverage when the project tracks coverage as a quality gate.
If a project uses different thresholds or does not enforce coverage yet, follow the project rule and
still add or update the tests needed for the changed behavior.

Prefer a balanced test mix when the project supports it:
1. **Unit Tests** - Individual functions, utilities, components
2. **Integration Tests** - API endpoints, database operations
3. **E2E Tests** - Critical user flows (framework chosen per language)

## Test Strategy

For new features, prefer TDD when it fits the team's workflow:
1. Write or update a failing test first when practical
2. Implement the smallest change that makes it pass
3. Refactor carefully
4. Run the affected checks

For existing code paths, at minimum:
1. Add or update tests that cover the changed behavior
2. Run the relevant tests after the change
3. Run coverage checks when the project expects them

## Troubleshooting Test Failures

1. Use the environment's available testing or TDD workflow, if one exists
2. Check test isolation
3. Verify mocks are correct
4. Fix implementation, not tests (unless tests are wrong)

## Agent Support

- Use project- or environment-specific testing helpers when they exist

## Test Structure (AAA Pattern)

Prefer Arrange-Act-Assert structure for tests:

```typescript
test('calculates similarity correctly', () => {
  // Arrange
  const vector1 = [1, 0, 0]
  const vector2 = [0, 1, 0]

  // Act
  const similarity = calculateCosineSimilarity(vector1, vector2)

  // Assert
  expect(similarity).toBe(0)
})
```

### Test Naming

Use descriptive names that explain the behavior under test:

```typescript
test('returns empty array when no markets match query', () => {})
test('throws error when API key is missing', () => {})
test('falls back to substring search when Redis is unavailable', () => {})
```
