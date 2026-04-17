---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Python Coding Style

> This file extends [common/coding-style.md](../common/coding-style.md) with Python specific content.

## Standards

- Follow **PEP 8** conventions
- Use **type annotations** on all function signatures

## Immutability

Prefer immutable data structures:

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class User:
    name: str
    email: str

from typing import NamedTuple

class Point(NamedTuple):
    x: float
    y: float
```

## Formatting

- Follow the project's configured formatter and linter first
- If the project does not define a Python toolchain, default to **ruff** for linting
- Use **black** and **isort** only when the project already uses them or explicitly asks for them

## Reference

For supplemental examples and idioms, see skill: `python-patterns`.
