---
name: uv-docker
description: Use when writing or optimizing Dockerfiles for Python applications using uv.
  Covers multistage builds, uv installation patterns, and production-ready configurations.
---

# Dockerfiles with uv

## When to Load This Skill

Load this skill when:
- Writing new Dockerfiles for Python applications
- Optimizing existing Python Dockerfiles
- Migrating from pip to uv in containers
- Debugging Docker build issues with Python dependencies

---

## 1 — Basic Multistage Structure

```dockerfile
# Stage 1: Build dependencies
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim as builder

WORKDIR /app

# Copy dependency files first for better caching
COPY pyproject.toml uv.lock ./

# Install dependencies to a virtual environment
RUN uv sync --frozen --no-cache

# Stage 2: Runtime
FROM debian:bookworm-slim

# Install uv for runtime
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

WORKDIR /app

# Copy virtual environment from builder stage
COPY --from=builder /app/.venv /app/.venv

# Copy application code
COPY . .

# Ensure we use the virtual environment
ENV PATH="/app/.venv/bin:$PATH"

CMD ["uv", "run", "python", "main.py"]
```

**Key benefits:**
- **Smaller final image** - Build dependencies aren't included in production
- **Faster builds** - uv's speed advantage for dependency resolution
- **Better caching** - Dependency installation cached separately from code changes
- **Security** - No build tools in production image

---

## 2 — UV Installation Patterns

```dockerfile
# Option 1: Use UV's Python images directly
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Option 2: Install UV on minimal base
FROM debian:bookworm-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Option 3: Install UV on existing Python image
FROM python:3.12-slim
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
```

---

## 3 — Dependency Sync Commands

```dockerfile
# Standard sync (equivalent to pip install)
RUN uv sync --frozen --no-cache

# Production-only (skip dev dependencies)
RUN uv sync --frozen --no-cache --no-dev
```

---

## 4 — Environment Variables

```dockerfile
# Activate virtual environment
ENV PATH="/app/.venv/bin:$PATH"

# Optional: Set UV cache directory
ENV UV_CACHE_DIR=/tmp/uv-cache
```

---

## 5 — Production-Ready Example

```dockerfile
# Build stage
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim as builder

# Install system dependencies for building C extensions
RUN apt-get update && apt-get install -y \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy and install dependencies
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-cache --no-dev

# Production stage
FROM debian:bookworm-slim

# Install uv and runtime dependencies
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Create non-root user
RUN useradd --create-home --shell /bin/bash app

WORKDIR /app

# Copy virtual environment
COPY --from=builder /app/.venv /app/.venv

# Copy application code
COPY --chown=app:app . .

# Switch to non-root user
USER app

# Activate virtual environment
ENV PATH="/app/.venv/bin:$PATH"

EXPOSE 8000

CMD ["uv", "run", "python", "main.py"]
```

---

## 6 — Tips

1. **Order matters** - Copy `pyproject.toml` and `uv.lock` before application code for better layer caching
2. **Use `--frozen`** - Ensures exact dependency versions from lockfile
3. **Use `--no-cache`** - Prevents UV cache from bloating the image
4. **Use `--no-dev`** - Skip development dependencies in production
5. **Set PATH** - Ensure the virtual environment is activated properly
