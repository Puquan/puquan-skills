# Common Patterns

## Skeleton Projects

Use proven examples as references, not as mandatory templates.

When implementing substantial new functionality:
1. Look for existing project patterns or battle-tested skeletons
2. Reuse the parts that fit the task and the repository conventions
3. Avoid importing a framework or scaffold that adds more complexity than the task needs
4. Prefer incremental adoption over copying an entire skeleton blindly

## Design Patterns

### Repository Pattern

Use a repository layer when it clarifies a real boundary between business logic and data access:
- Define only the operations the consuming layer actually needs
- Let concrete implementations handle storage details (database, API, file, etc.)
- Keep business logic dependent on the interface, not the storage mechanism
- Do not add a repository for one-off or trivial access paths

### API Response Format

If a project uses response envelopes, keep them consistent with the existing API contract:
- Include only the fields the project standard requires
- Keep success and error payloads predictable for clients
- Include pagination metadata when the endpoint is paginated
- Do not introduce a new envelope shape when the project already has one
