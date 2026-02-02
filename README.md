<h1 align="center">🧪 Patchwerk 🧪</h1>

<p align="center">
  <img src="assets/patchwerk.png" alt="Patchwerk" width="200"/>
</p>

Reusable agent configuration patterns for AI coding assistants.

## Architecture

**Multi-framework support** via symlinks: `.claude/`, `.gemini/`, and `.codex/` point to centralized config.

```
AGENTS.md (root)           → Project config + skill routing
  ├→ .agent-skills/        → Domain expertise (Python, testing, GCP, etc.)
  └→ .agent-defs/          → Task agents (devrun for pytest/ruff/etc.)
```

**Entry**: `.claude/CLAUDE.md` and `.gemini/GEMINI.md` → `@../AGENTS.md`. Codex CLI reads `AGENTS.md` directly and loads skills from `.codex/skills`.

**Skills load on-demand**: Python standards, testing architecture, debugging, GCP ops, Terraform, uv/Docker patterns.

## Symlink Notes

`.claude/skills`, `.gemini/skills`, and `.codex/skills` are symlinks to the canonical sources:

- `.agent-skills/`

`.claude/agents` and `.gemini/agents` are symlinks to:

- `.agent-defs/`

On Windows, make sure symlinks are preserved (Developer Mode or admin shell) and that Git is configured with `core.symlinks=true`. Otherwise, symlinks may be checked out as real directories and drift from the single source of truth.

## Codex devrun

`devrun` is exposed as a Codex skill via:

- `.agent-skills/devrun/SKILL.md` → `.agent-defs/devrun.md`

Use `$devrun` in Codex to run tools in read-only mode (run command, parse output, no edits).

## Key Features

- Single-source-of-truth via symlinks
- Stack-agnostic reusability
- Read-only safety for test runners
- Progressive disclosure (skills loaded when relevant)
- Codex CLI support via `.codex/skills` and `$devrun`
