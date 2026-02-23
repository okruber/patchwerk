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

## Swarm lifecycle

The swarm scripts follow a **setup once, use many times, teardown when done** pattern:

1. **`bash orchestration/setup.sh`** — Run once. Creates worker worktrees, merge slot, junctions, identity files, and launcher scripts. Idempotent (safe to re-run).
2. **`bash orchestration/launch.sh`** — Run each session. Creates detached tmux sessions (`patchwerk_conductor`, `patchwerk_worker-1`, etc.), each running Claude Code. Workers auto-run `/next` to claim work immediately.
3. **`bash orchestration/teardown.sh`** — Run when you're done with parallel work. Kills tmux sessions and removes worker worktrees. Preserves the merge slot for future use.

Requires tmux (`brew install tmux` on macOS). Sessions are named `patchwerk_*` for compatibility with [stacken-tui](https://github.com/okruber/stacken-tui).

### Merging worker changes to main

Workers merge their own work via `/next` (step 8), which runs `orchestration/merge-back.sh` automatically. The script:

1. Acquires the merge slot (blocks if another worker is merging)
2. Rebases the worker branch onto latest `origin/main`
3. Fast-forward merges into main and pushes
4. Releases the merge slot

Only one worker can merge at a time — the merge slot serializes access to prevent conflicts.

If the rebase fails, the script aborts cleanly, releases the slot, and asks you to resolve conflicts manually before re-running. To invoke manually from a worker worktree: `bash orchestration/merge-back.sh` (refuses to run from the main worktree).

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
