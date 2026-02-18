---
---

# Interface Design - ABC vs Protocol

## Core Rule

**Use ABC for interfaces, NEVER Protocol (for internal code)**

---

## Decision Framework

| Aspect | ABC | Protocol |
|--------|-----|----------|
| **Use case** | Internal interfaces you own | Third-party library boundaries |
| **Inheritance** | Explicit (classes must inherit) | Structural (duck typing) |
| **Validation** | Runtime (instantiation fails if incomplete) | Static only (type checker) |
| **Benefits** | Explicit enforcement, runtime validation, code reuse | No inheritance required, loose coupling |
| **When to use** | erk internal code, owned implementations | External library wrappers |

---

## ABC Interface Pattern

```python
# ✅ CORRECT: Use ABC for interfaces
from abc import ABC, abstractmethod

class Repository(ABC):
    @abstractmethod
    def save(self, entity: Entity) -> None:
        """Save entity to storage."""
        ...

    @abstractmethod
    def load(self, id: str) -> Entity:
        """Load entity by ID."""
        ...

class PostgresRepository(Repository):
    def save(self, entity: Entity) -> None:
        # Implementation
        pass

    def load(self, id: str) -> Entity:
        # Implementation
        pass

# ❌ WRONG: Using Protocol (for internal code)
from typing import Protocol

class Repository(Protocol):
    def save(self, entity: Entity) -> None: ...
    def load(self, id: str) -> Entity: ...
```

---

## Benefits of ABC

1. **Explicit inheritance** - Clear class hierarchy
2. **Runtime validation** - Errors if abstract methods not implemented
3. **Better IDE support** - Autocomplete and refactoring work better
4. **Documentation** - Clear contract definition

---

## Complete DI Example

```python
from abc import ABC, abstractmethod
from dataclasses import dataclass

# Define the interface
class DataStore(ABC):
    @abstractmethod
    def get(self, key: str) -> str | None:
        """Retrieve value by key."""
        ...

    @abstractmethod
    def set(self, key: str, value: str) -> None:
        """Store value with key."""
        ...

# Real implementation
class RedisStore(DataStore):
    def get(self, key: str) -> str | None:
        return self.client.get(key)

    def set(self, key: str, value: str) -> None:
        self.client.set(key, value)

# Fake for testing
class FakeStore(DataStore):
    def __init__(self) -> None:
        self._data: dict[str, str] = {}

    def get(self, key: str) -> str | None:
        if key not in self._data:
            return None
        return self._data[key]

    def set(self, key: str, value: str) -> None:
        self._data[key] = value

# Business logic accepts interface
@dataclass
class Service:
    store: DataStore  # Depends on abstraction

    def process(self, item: str) -> None:
        cached = self.store.get(item)
        if cached is None:
            result = expensive_computation(item)
            self.store.set(item, result)
        else:
            result = cached
        use_result(result)
```

---

## When to Use Protocol

Use Protocol ONLY when:

1. **Wrapping third-party libraries** - You don't control the implementation
2. **Minimal coupling needed** - Duck typing is sufficient
3. **Cannot modify the class** - Working with external code

```python
# ✅ ACCEPTABLE: Protocol for third-party library wrapper
from typing import Protocol

class LoggerLike(Protocol):
    """Protocol for any logger (stdlib logging, structlog, etc.)"""
    def info(self, msg: str) -> None: ...
    def error(self, msg: str) -> None: ...

def process_with_logging(data: Data, logger: LoggerLike) -> None:
    logger.info("Starting processing")
    # ... process data ...
    logger.error("Error occurred")
```

---

## Decision Checklist

### Before choosing ABC vs Protocol:

- [ ] Do I own the implementations? (Use ABC)
- [ ] Am I wrapping third-party libraries? (Use Protocol)
- [ ] Do I need runtime validation? (Use ABC)
- [ ] Do I want to share implementation code? (Use ABC)

**Default: ABC for internal code, Protocol for external boundaries**
