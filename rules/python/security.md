---
paths:
  - "**/*.py"
  - "**/*.pyi"
---
# Python Security

> This file extends [common/security.md](../common/security.md) with Python specific content.

## Secret Management

Prefer the project's existing configuration mechanism for secrets.
Load environment variables in a way that matches the runtime and deployment environment:

```python
import os

api_key = os.environ["OPENAI_API_KEY"]  # Raises KeyError if missing
```

## Security Scanning

- If the project uses **bandit**, run it as part of static security analysis:
  ```bash
  bandit -r src/
  ```

## Reference

Use the environment's available security guidance for framework-specific concerns.
