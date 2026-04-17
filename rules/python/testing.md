---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Python Testing

> This file extends [common/testing.md](../common/testing.md) with Python specific content.

## Framework

Follow the repository's configured Python test stack first.
If the project does not define one, prefer **pytest**.

## Coverage

```bash
pytest --cov=<package_or_src_path> --cov-report=term-missing
```

## Test Organization

Use `pytest.mark` for test categorization when the project relies on markers:

```python
import pytest

@pytest.mark.unit
def test_calculate_total():
    ...

@pytest.mark.integration
def test_database_connection():
    ...
```

## Reference

For optional deeper pytest guidance, see skill: `python-testing`.
