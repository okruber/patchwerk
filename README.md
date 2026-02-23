<h1 align="center">🧪 Patchwerk 🧪</h1>

<p align="center">
  <img src="assets/patchwerk.png" alt="Patchwerk" width="200"/>
</p>

Distribute reusable agent configuration files across repos. A Python CLI that syncs skills, agent definitions, and tool config from a single source of truth.

## What it does

Patchwerk separates **framework content** (skill routing, coding principles, session protocol) from **project-specific content** (tech stack, architecture, purpose). Framework updates propagate to all projects via `sync`; project-specific files are written once on `init` and never overwritten.

| Command | Purpose |
|---------|---------|
| `patchwerk init` | Bootstrap a new repo with all configs (skips existing files) |
| `patchwerk sync` | Update managed paths to latest framework versions |
| `patchwerk diff` | Dry-run preview of what sync would change |
| `patchwerk stage` | (Maintainer) Bundle repo files into the package for distribution |

**Managed paths** (overwritten on sync):
- `.agent-skills/` — domain expertise modules, including `framework/core.md`
- `.agent-defs/` — task agent definitions (e.g. read-only devrun)
- `.mcp.json` — MCP server configuration
- `.claude/settings.json` — Claude Code project settings

**Project-specific files** (written on init, never overwritten):
- `AGENTS.md` — project overview + `@` import of framework core
- `.claude/CLAUDE.md` — entry point, imports AGENTS.md

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
└── templates/          # Bundled configs distributed to target repos

.agent-skills/
├── framework/
│   └── core.md         # Framework: skill routing, principles, session protocol
├── dignified-python/   # Skill modules (synced to all projects)
├── fake-driven-testing/
└── ...
.agent-defs/            # devrun agent (pytest/ruff/prettier — read-only)
.claude/
├── CLAUDE.md           # Entry point → @../AGENTS.md
├── commands/           # Custom commands (brainstorm, setup-swarm, etc.)
└── hooks/              # Git/session hooks
AGENTS.md               # Project overview → @.agent-skills/framework/core.md
orchestration/          # Swarm setup/teardown scripts for parallel agent work
```

### Import chain

Claude Code resolves `@` directives recursively (up to 5 hops):

```
.claude/CLAUDE.md  →  @../AGENTS.md  →  @.agent-skills/framework/core.md
     (entry point)      (project-specific)      (framework, synced)
```

This means each project keeps its own `AGENTS.md` with project-specific context (purpose, tech stack, architecture), while the framework content in `core.md` stays in sync across all projects.

## Workflows

### New project setup

```bash
cd ~/Projects/my-new-repo
patchwerk init

# Edit AGENTS.md — fill in the project overview placeholders
$EDITOR AGENTS.md
```

`init` copies all templates, skipping files that already exist. The skeleton `AGENTS.md` has TODO placeholders for project-specific fields.

### Keeping projects up to date

```bash
# Preview what would change
patchwerk --target ~/Projects/my-other-repo diff

# Apply updates
patchwerk --target ~/Projects/my-other-repo sync
```

`sync` overwrites managed paths (skills, agent-defs, mcp.json, settings.json) but leaves `AGENTS.md` and other project-specific files untouched. When framework principles change in patchwerk, a single `sync` delivers them everywhere.

### Migrating an existing project

If a project has an old monolithic `AGENTS.md` (full framework content inline):

1. Run `patchwerk sync` to deliver `framework/core.md`
2. Replace the project's `AGENTS.md` with a thin version:

```markdown
<!-- ROUTING FILE: Load skills as directed. Read before writing code. -->

# Agent Configuration

## Project Overview

**Purpose**: Your project description here

**Tech Stack**:
- Language: Go
- Package Management: go modules
- Testing: go test
- VCS: Git (feature branches, never push unless asked)

**Architecture**: Brief architecture description

---

@.agent-skills/framework/core.md
```

### Maintainer: updating the framework

```bash
# Edit framework content in patchwerk repo
$EDITOR .agent-skills/framework/core.md

# Stage into the package for distribution
patchwerk stage

# Build and publish
uv build
```

`stage` bundles `.agent-skills/`, `.agent-defs/`, `.claude/`, `.gemini/`, `.mcp.json`, and `orchestration/` into the package. It does **not** stage `AGENTS.md` — the template skeleton is maintained separately from patchwerk's own project-specific `AGENTS.md`.

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
