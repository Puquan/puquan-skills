---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
---
# TypeScript/JavaScript Testing

> This file extends [common/testing.md](../common/testing.md) with TypeScript/JavaScript specific content.

## Test Tooling

- Follow the repository's configured test stack first
- Use the project's existing unit, integration, and E2E tools when they exist

## E2E Testing

If the project needs a browser E2E framework and does not already standardize on one, prefer
**Playwright** for critical user flows.
