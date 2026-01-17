---
name: uv-management
description: Use when working with Python package management, dependencies, or uv tooling.
  Covers installation, workflows, CI/CD, troubleshooting, and best practices for uv
  (the fast Python package installer and resolver). Essential for project setup,
  dependency management, virtual environments, and CI/CD configuration.
---

# UV Management

## When to Load This Skill

Load this skill when:
- Setting up new Python projects with uv
- Managing dependencies or virtual environments
- Configuring CI/CD pipelines for Python projects
- Troubleshooting package installation or dependency issues
- Migrating from pip/poetry/pipenv/conda to uv
- Working with monorepos or workspace configurations
- Configuring build systems or private package repositories

---

## 0 — Sanity Check

```bash
uv --version               # verify installation; exits 0
```

If the command fails, halt and report to the user.

---

## 1 — Daily Workflows

### 1.1 Project ("cargo‑style") Flow

```bash
uv init myproj                     # ① create pyproject.toml + .venv
cd myproj
uv add ruff pytest httpx           # ② fast resolver + lock update
uv run pytest -q                   # ③ run tests in project venv
uv lock                            # ④ refresh uv.lock (if needed)
uv sync --locked                   # ⑤ reproducible install (CI‑safe)
```

### 1.2 Script‑Centric Flow (PEP 723)

```bash
echo 'print("hi")' > hello.py
uv run hello.py                    # zero‑dep script, auto‑env
uv add --script hello.py rich      # embeds dep metadata
uv run --with rich hello.py        # transient deps, no state
```

### 1.3 CLI Tools (pipx Replacement)

```bash
uvx ruff check .                   # ephemeral run
uv tool install ruff               # user‑wide persistent install
uv tool list                       # audit installed CLIs
uv tool update --all               # keep them fresh
```

### 1.4 Python Version Management

```bash
uv python install 3.10 3.11 3.12
uv python pin 3.12                 # writes .python-version
uv run --python 3.10 script.py
```

### 1.5 Legacy Pip Interface

```bash
uv venv .venv
source .venv/bin/activate
uv pip install -r requirements.txt
uv pip sync   -r requirements.txt   # deterministic install
```

---

## 2 — Performance‑Tuning Knobs

| Env Var                   | Purpose                 | Typical Value |
| ------------------------- | ----------------------- | ------------- |
| `UV_CONCURRENT_DOWNLOADS` | saturate fat pipes      | `16` or `32`  |
| `UV_CONCURRENT_INSTALLS`  | parallel wheel installs | `CPU_CORES`   |
| `UV_OFFLINE`              | enforce cache‑only mode | `1`           |
| `UV_INDEX_URL`            | internal mirror         | `https://…`   |
| `UV_PYTHON`               | pin interpreter in CI   | `3.11`        |
| `UV_NO_COLOR`             | disable ANSI coloring   | `1`           |

Other handy commands:

```bash
uv cache dir && uv cache info      # show path + stats
uv cache clean                     # wipe wheels & sources
```

---

## 3 — CI/CD Recipes

### 3.1 GitHub Actions

```yaml
# .github/workflows/test.yml
name: tests
on: [push]
jobs:
  pytest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v5       # installs uv, restores cache
      - run: uv python install            # obey .python-version
      - run: uv sync --locked             # restore env
      - run: uv run pytest -q
```

### 3.2 Docker

```dockerfile
FROM ghcr.io/astral-sh/uv:0.7.4 AS uv
FROM python:3.12-slim

COPY --from=uv /usr/local/bin/uv /usr/local/bin/uv
COPY pyproject.toml uv.lock /app/
WORKDIR /app
RUN uv sync --production --locked
COPY . /app
CMD ["uv", "run", "python", "-m", "myapp"]
```

---

## 4 — Migration Matrix

| Legacy Tool / Concept | One‑Shot Replacement        | Notes                 |
| --------------------- | --------------------------- | --------------------- |
| `python -m venv`      | `uv venv`                   | 10× faster create     |
| `pip install`         | `uv pip install`            | same flags            |
| `pip-tools compile`   | `uv pip compile` (implicit) | via `uv lock`         |
| `pipx run`            | `uvx` / `uv tool run`       | no global Python req. |
| `poetry add`          | `uv add`                    | pyproject native      |
| `pyenv install`       | `uv python install`         | cached tarballs       |

---

## 5 — Troubleshooting Fast‑Path

| Symptom                    | Resolution                                                     |
| -------------------------- | -------------------------------------------------------------- |
| `Python X.Y not found`     | `uv python install X.Y` or set `UV_PYTHON`                     |
| Proxy throttling downloads | `UV_HTTP_TIMEOUT=120 UV_INDEX_URL=https://mirror.local/simple` |
| C‑extension build errors   | `unset UV_NO_BUILD_ISOLATION`                                  |
| Need fresh env             | `uv cache clean && rm -rf .venv && uv sync`                    |
| Still stuck?               | `RUST_LOG=debug uv ...` and open a GitHub issue                |

---

## 6 — Exec Pitch (30 s)

```text
• 10–100× faster dependency & env management in one binary.
• Universal lockfile ⇒ identical builds on macOS / Linux / Windows / ARM / x86.
• Backed by the Ruff team; shipping new releases ~monthly.
```

---

## 7 — Agent Cheat‑Sheet (Copy/Paste)

```bash
# new project
a=$PWD && uv init myproj && cd myproj && uv add requests rich

# test run
uv run python -m myproj ...

# lock + CI restore
uv lock && uv sync --locked

# adhoc script
uv add --script tool.py httpx
uv run tool.py

# manage CLI tools
uvx ruff check .
uv tool install pre-commit

# Python versions
uv python install 3.12
uv python pin 3.12
```

---

## 8 — Additional Topics

### 8.1 Lock File Workflows

**When to use lock file flags:**

- `uv sync --locked` - **CI/production**: Fail if lock file is out of sync with pyproject.toml
- `uv sync --frozen` - **Strict reproducibility**: Install exactly what's in lock file, no updates
- `uv lock` - **Development**: Regenerate lock file from pyproject.toml

**Committing uv.lock:**

- **DO commit** for applications and services (ensures reproducible deployments)
- **DON'T commit** for libraries (users should resolve their own dependencies)
- **Always commit** if using `--locked` in CI

**Lock file conflicts:**

```bash
# Merge conflict in uv.lock? Regenerate it:
git checkout --theirs pyproject.toml   # or --ours, depending on intent
uv lock                                 # regenerate lock file
git add uv.lock pyproject.toml
```

### 8.2 Workspace Configuration (Monorepos)

**Setup workspace in pyproject.toml:**

```toml
[tool.uv.workspace]
members = ["packages/*", "apps/*"]
```

**Workspace structure:**

```
myproject/
├── pyproject.toml              # workspace root
├── uv.lock                     # single lock for all members
├── packages/
│   ├── pkg-a/
│   │   └── pyproject.toml
│   └── pkg-b/
│       └── pyproject.toml
└── apps/
    └── web/
        └── pyproject.toml
```

**Workspace commands:**

```bash
uv sync                         # sync all workspace members
uv add --package pkg-a requests # add dep to specific member
uv run --package web python -m web  # run command in member context
```

### 8.3 pyproject.toml Patterns

**Minimal pyproject.toml:**

```toml
[project]
name = "myapp"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "requests>=2.31.0",
    "pydantic>=2.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"
```

**Full-featured with dependency groups:**

```toml
[project]
name = "myapp"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = [
    "requests>=2.31.0",
    "pydantic>=2.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0",
    "ruff>=0.1.0",
]
docs = [
    "mkdocs>=1.5",
    "mkdocs-material>=9.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.uv]
dev-dependencies = [
    "mypy>=1.0",
    "pre-commit>=3.0",
]
```

**Installing with groups:**

```bash
uv sync                         # install project + dev deps
uv sync --no-dev                # production install only
uv sync --extra docs            # install with optional 'docs' group
```

### 8.4 Private Package Repositories

**Using private indexes:**

```bash
# Set via environment variable
export UV_INDEX_URL=https://pypi.company.com/simple

# Or via command line
uv pip install --index-url https://pypi.company.com/simple mypackage

# Multiple indexes (fallback to PyPI)
uv pip install --extra-index-url https://pypi.company.com/simple mypackage
```

**Authentication patterns:**

```bash
# Token in URL (not recommended, visible in logs)
UV_INDEX_URL=https://token:secret@pypi.company.com/simple

# Using netrc (~/.netrc)
machine pypi.company.com
login __token__
password pypi-AgEIcHl...

# Using keyring (most secure)
pip install keyring
keyring set https://pypi.company.com/simple __token__
```

**In pyproject.toml:**

```toml
[[tool.uv.index]]
url = "https://pypi.company.com/simple"
name = "company"

[project]
dependencies = [
    "internal-pkg @ https://pypi.company.com/packages/internal-pkg-1.0.tar.gz",
]
```

### 8.5 Editable Installs

**Local development:**

```bash
# Install current package in editable mode
uv pip install -e .

# Install with optional dependencies
uv pip install -e ".[dev,test]"

# Install workspace member
uv pip install -e ./packages/pkg-a

# Multiple editable installs (common in monorepos)
uv pip install -e ./packages/pkg-a -e ./packages/pkg-b -e .
```

**Path dependencies in pyproject.toml:**

```toml
[project]
dependencies = [
    "pkg-a @ file:///path/to/packages/pkg-a",
    # or relative paths
    "pkg-b @ file:./packages/pkg-b",
]
```

### 8.6 Pre-commit Integration

**Basic .pre-commit-config.yaml:**

```yaml
repos:
  - repo: local
    hooks:
      - id: uv-lock-check
        name: Check uv.lock is up to date
        entry: uv lock --check
        language: system
        pass_filenames: false

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.1.9
    hooks:
      - id: ruff
        args: [--fix]
      - id: ruff-format
```

**Setup:**

```bash
uv tool install pre-commit
pre-commit install
pre-commit run --all-files  # test all hooks
```

### 8.7 Virtual Environment Activation

**uv run vs activated venv:**

```bash
# Option 1: Use uv run (recommended for commands)
uv run pytest
uv run python script.py
uv run myapp

# Option 2: Activate venv (better for interactive work)
source .venv/bin/activate      # Linux/macOS
# or
.venv\Scripts\activate         # Windows

python script.py               # uses activated venv
deactivate                     # exit venv
```

**Trade-offs:**
- `uv run` - Always uses correct venv, works in any directory, adds slight overhead
- Activated venv - Faster (no wrapper), better for REPL/debugging, must activate first

### 8.8 Build Isolation

**When to disable build isolation:**

```bash
# C-extensions need system libraries (e.g., PostgreSQL, OpenSSL)
UV_NO_BUILD_ISOLATION=1 uv pip install psycopg2

# Or use pre-built wheels instead (better)
uv pip install psycopg2-binary
```

**In CI with system dependencies:**

```yaml
# GitHub Actions example
- name: Install system dependencies
  run: sudo apt-get install -y libpq-dev

- name: Install Python packages
  run: uv sync
  env:
    UV_NO_BUILD_ISOLATION: 1
```

**Note:** Disabling build isolation means packages can see your entire environment. Only use when necessary and prefer binary wheels when available.

---

## Quick Reference Commands

```bash
# Project lifecycle
uv init                         # create new project
uv add <package>               # add dependency
uv remove <package>            # remove dependency
uv sync                        # install all dependencies
uv lock                        # update lock file
uv run <cmd>                   # run command in venv

# Environment management
uv venv                        # create virtual environment
uv python list                 # list available Python versions
uv python install 3.12         # install Python version
uv python pin 3.12            # set project Python version

# CLI tools
uvx <tool>                    # run tool ephemerally
uv tool install <tool>        # install tool globally
uv tool list                  # list installed tools
uv tool uninstall <tool>      # remove installed tool

# Dependency inspection
uv pip list                   # list installed packages
uv pip show <package>         # show package details
uv pip tree                   # show dependency tree (if available)

# Cache management
uv cache clean                # clear all caches
uv cache dir                  # show cache directory
uv cache info                 # show cache statistics

# Troubleshooting
uv --version                  # check uv version
RUST_LOG=debug uv <cmd>      # debug logging
uv cache clean && rm -rf .venv && uv sync  # nuclear option
```
