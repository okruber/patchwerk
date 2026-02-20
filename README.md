<h1 align="center">🧪 Patchwerk 🧪</h1>

<p align="center">
  <img src="assets/patchwerk.png" alt="Patchwerk" width="200"/>
</p>

Distribute reusable agent configuration files across repos. A Python CLI that syncs skills, agent definitions, and tool config from a single source of truth.

## What it does

- `patchwerk init` — copy all bundled configs into a target repo (skips existing files)
- `patchwerk sync` — update managed paths to latest bundled versions
- `patchwerk diff` — dry-run preview of what sync would change

**Managed paths** (synced automatically):
- `.agent-skills/` — domain expertise modules for AI coding assistants
- `.agent-defs/` — task agent definitions (e.g. read-only devrun)
- `.mcp.json` — MCP server configuration

## Installation

```bash
# One-off use
uvx --from git+ssh://git@github.com/<user>/patchwerk.git patchwerk init

# Shell alias for repeated use
alias patchwerk='uvx --from git+ssh://git@github.com/<user>/patchwerk.git patchwerk'
```

## Architecture

```
src/patchwerk/
├── cli.py              # CLI: init, sync, diff, stage
└── templates/          # Symlink to repo root (bundled configs)

.agent-skills/          # Skills: Python, testing, debugging, GCP, Terraform, uv, Docker, swarm
.agent-defs/            # devrun agent (pytest/ruff/prettier — read-only)
.claude/
├── CLAUDE.md           # Entry point → @../AGENTS.md
├── commands/           # Custom commands (brainstorm, setup-swarm, etc.)
└── hooks/              # Git/session hooks
AGENTS.md               # Routing config + coding principles
orchestration/          # Swarm setup/teardown scripts for parallel agent work
```

**`src/patchwerk/templates/` is a symlink to the repo root** — no duplication, single source of truth.

## Skills included

| Skill | Domain |
|-------|--------|
| `dignified-python` | Python standards (LBYL, ABC, modern types) |
| `fake-driven-testing` | 5-layer testing architecture |
| `brainstorming` | Pre-implementation discovery |
| `uv-management` | Package management with uv |
| `uv-docker` | Multistage Docker builds with uv |
| `debugging-framework` | 4-phase systematic debugging |
| `gcp-observability` | GCP operations via gcloud CLI |
| `swarm` | Parallel agent orchestration |
| `terraform` | IaC patterns with Checkov/docs |
| `commit-messages` | Conventional commits |

## Maintainer workflow

```bash
# Stage local changes into the package
patchwerk stage

# Build and publish
uv build
```
