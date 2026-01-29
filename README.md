<h1 align="center">🧪 Patchwerk 🧪</h1>

<p align="center">
  <img src="assets/patchwerk.png" alt="Patchwerk" width="200"/>
</p>

Reusable agent configuration patterns for AI coding assistants.

## Architecture

**Multi-framework support** via symlinks: `.claude/` and `.gemini/` both point to centralized config.

```
AGENTS.md (root)           → Project config + skill routing
  ├→ .agent-skills/        → Domain expertise (Python, testing, GCP, etc.)
  └→ .agent-defs/          → Task agents (devrun for pytest/ruff/etc.)
```

**Entry**: `.claude/CLAUDE.md` → `@../AGENTS.md`

**Skills load on-demand**: Python standards, testing architecture, debugging, GCP ops, Terraform, uv/Docker patterns.

## Key Features

- Single-source-of-truth via symlinks
- Stack-agnostic reusability
- Read-only safety for test runners
- Progressive disclosure (skills loaded when relevant)