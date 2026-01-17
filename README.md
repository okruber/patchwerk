<h1 align="center">🧪 Patchwerk 🧪</h1>

<p align="center">
  <img src="assets/patchwerk.png" alt="Patchwerk" width="200"/>
</p>

This repository is a patchwork of configuration files, scripts, and utilities stitched together from various sources across the internet.

## Agent Configuration System

A layered, modular agent configuration system for Claude Code that separates concerns and makes the workflow stack-agnostic.

### Structure

```
.claude/
├── CLAUDE.md              → @../AGENTS.md (pointer only)
└── skills/
    ├── dignified-python/  → Python standards (LBYL, types, ABC)
    ├── fake-driven-testing/ → 5-layer test architecture
    └── agents/
        └── devrun.md      → Read-only test runner

AGENTS.md                  → Central configuration (root level)
```

### How It Works

1. **Entry Point**: Claude Code loads `.claude/CLAUDE.md`, which contains only `@../AGENTS.md`
2. **Central Config**: `AGENTS.md` contains project-specific guidance and routes to skills
3. **Skills**: Domain knowledge loaded on-demand (Python standards, testing patterns)
4. **Agents**: Task executors like `devrun` (read-only, runs pytest/ruff/etc)

### Flow

```
CLAUDE.md (pointer)
    ↓
AGENTS.md (rules + skill routing)
    ↓
    ├→ dignified-python skill
    ├→ fake-driven-testing skill
    └→ devrun agents (read-only)
```

### Benefits

- **Stack-Agnostic**: `.claude/` folder reusable across projects
- **Separation of Concerns**: General guidance vs domain expertise vs tooling
- **On-Demand Loading**: Skills only loaded when relevant
- **Read-Only Safety**: Agents can't accidentally modify files