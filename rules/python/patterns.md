---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Python Patterns

> This file extends [common/patterns.md](../common/patterns.md) with Python specific content.

Use these as reference patterns, not mandatory abstractions.

## Protocol (Duck Typing)

```python
from typing import Protocol

class Repository(Protocol):
    def find_by_id(self, entity_id: str) -> dict | None: ...
    def save(self, entity: dict) -> dict: ...
```

## Dataclasses as DTOs

Use dataclasses for plain data transfer when they fit the project's model style:

```python
from dataclasses import dataclass

@dataclass(frozen=True)
class CreateUserRequest:
    name: str
    email: str
    age: int | None = None
```

## Context Managers & Generators

- Use context managers (`with` statement) for resource management
- Use generators for lazy evaluation and memory-efficient iteration

## Reference

For supplemental examples and deeper pattern guidance, see skill: `python-patterns`.
