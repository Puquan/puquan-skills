# Database Rules

## Anti-Patterns to Avoid

### No Mixin Extraction for Model Fields

Do NOT suggest extracting `SoftDeleteMixin`, `AuditMixin`, or similar mixins for database model fields like `deleted_at`, `deleted_by`, `created_by`.

Reasons:
- These fields vary across tables (some have `deleted_by`, some don't)
- Each field is 1-2 lines of code -- the "duplication" is trivial
- Explicit field definitions in each model are easier to read and verify
- A mixin for 2 lines of code is a premature abstraction that adds cognitive overhead

Three similar lines of code is better than a premature abstraction.

## PostgreSQL Conventions

- Use `TIMESTAMPTZ` for all timestamp columns (never bare `TIMESTAMP`)
- Use `UUID` for primary keys with `gen_random_uuid()` server default
- Use `String(N)` for status/enum columns + CHECK constraints (no PG native enums)
- Use `JSONB` for variable configuration fields
- Use composite foreign keys `(id, tenant_id)` for multi-tenant consistency
- Use partial indexes `WHERE deleted_at IS NULL` for soft-deleted tables
