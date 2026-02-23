<!-- ROUTING FILE: Load skills as directed. Read before writing code. -->

# Agent Configuration

## Project Overview

**Purpose**: Demonstration of agentic coding best practices using skill-based routing architecture. Collection of reusable configuration patterns for multi-project management.

**Tech Stack**:
- Language: Python
- Package Management: `uv` (preferred over `pip`)
- Testing: pytest via `devrun` agent
- Infrastructure: Google Cloud Platform (Cloud Run, Cloud Functions)
- VCS: Git (feature branches, never push unless asked)

**Architecture**: Skills provide domain-specific guidance (Python standards, testing patterns, debugging, GCP operations). AGENTS.md routes to appropriate skills based on context.

---

## CRITICAL: Before Writing Any Code

**CRITICAL: Prefer `uv` for package management. If the project uses `pip` conventionally, follow that convention.**

**For detailed uv workflows** → load `uv-management` skill

**CRITICAL: NEVER push code to remote (git push) unless the user explicitly requests it.**

**Load these skills FIRST:**

- **Non-trivial tasks** → `brainstorming` skill (context discovery, scope assessment, approach selection)
- **Package management with uv** → `uv-management` skill (workflows, CI/CD, troubleshooting)
- **Dockerfiles with Python/uv** → `uv-docker` skill (multistage builds, production patterns)
- **Python code** → `dignified-python` skill (LBYL, modern types, ABC interfaces)
- **Test code** → `fake-driven-testing` skill (5-layer architecture, test placement)
- **Debugging** → `debugging-framework` skill (4-phase systematic approach)
- **GCP operations** → `gcp-observability` skill (token-efficient workflows using gcloud CLI)
- **Swarm orchestration** → `swarm` skill (parallel agent work, merge protocol, worker lifecycle)

---

## Non-Trivial Task Detection

Before starting implementation, assess whether the task warrants brainstorming:

**Trigger brainstorming** (`/brainstorm` or load `brainstorming` skill):
- Touches 3+ files or 2+ modules
- Involves unfamiliar library, API, or pattern
- Ambiguous or underspecified description
- Feels like more than one session
- User asks "how should we..." or "what's the best way to..."

**Skip brainstorming** — proceed directly:
- Single-file change with clear scope
- Mechanical rename/refactor
- Docs-only change
- Bug fix with obvious root cause
- User says "just do it" or "skip brainstorming"

When in doubt, brainstorm. The cost of 2 minutes of discovery is far less than a dead-end implementation.

---

## Core Principles

- **Greenfield by default**: Get explicit approval before implementing backward compatibility
- **YAGNI/DRY/SOLID**: Best code is no code - only build what's needed now
- **Progressive disclosure**: Load skills for detailed guidance rather than embedding everything here
- **Simplicity over cleverness**: Readability and maintainability are primary concerns
- **Ask, don't assume**: Clarify requirements rather than guessing
- **Never discard on failure**: When fixing bugs/errors, modify existing code instead of rewriting
- **Version compatibility first**: When introducing new libraries/packages, **always use Context7** (`resolve-library-id` → `query-docs`) to fetch current documentation. Research version constraints, changelogs, and compatibility matrices before changing versions.

**For detailed Python standards** → load `dignified-python` skill

**For test architecture guidance** → load `fake-driven-testing` skill

**For debugging approach** → load `debugging-framework` skill

**For GCP operations** → load `gcp-observability` skill

---

## Tool Routing

### External Libraries → Use Context7 MCP

**ALWAYS** use Context7 when:
- Adding a new dependency to the project
- Working with a library's API for the first time in a session
- Debugging import errors, missing methods, or version conflicts
- Uncertain about current API signatures or patterns

**Workflow:**
1. `resolve-library-id` - convert library name to Context7 ID
2. `query-docs` - fetch current documentation with the resolved ID

Never rely on training data for external library APIs.

### Development Commands → Use `devrun` agent

Commands: pytest, ty, ruff, prettier, make

**FORBIDDEN prompts:**
- "fix any errors that arise"
- "make the tests pass"
- Any prompt implying devrun should modify files

**REQUIRED pattern:**
- "Run [command] and report results"
- "Execute [command] and parse output"

devrun is READ-ONLY. It runs commands and reports. Parent agent handles all fixes.

---

## Skill Loading Behavior

Skills persist for the entire session. Once loaded, they remain in context.

- DO NOT reload skills already loaded in this session
- Hook reminders fire as safety nets, not commands
- Check if loaded: Look for `<command-message>The "{name}" skill is loading</command-message>` earlier in conversation

---

## Quick Reference

**Naming**:
- Agent artifacts (`.claude/`, `.gemini/`): `kebab-case` (NOT underscores)
- Never name things 'improved', 'new', 'enhanced' - code naming should be evergreen

**Package management**: `uv` preferred over `pip` (load `uv-management` for workflows)

**Pre-implementation**: `/brainstorm` for non-trivial tasks (auto-triggered, or invoke manually)

**Version control**: Never push unless asked

---

## Project Constraints

**No time estimates in plans:**
- FORBIDDEN: Time estimates (hours, days, weeks)
- FORBIDDEN: Velocity predictions or completion dates
- FORBIDDEN: Effort quantification

**Test discipline:**
- FORBIDDEN: Writing tests for speculative or "maybe later" features
- ALLOWED: TDD workflow (write test → implement feature → refactor)
- MUST: Only test actively implemented code

<!-- BEGIN BEADS INTEGRATION -->
## Issue Tracking → `bd` (beads)

Use `bd` for ALL task tracking. No markdown TODOs, no other trackers.

```bash
bd ready                                      # find unblocked work
bd create "Title" --description="..." -t task|bug|feature|epic|chore -p 0-4
bd update <id> --status in_progress           # claim work
bd close <id> --reason "Done"                 # complete work
```

**Priorities**: `0` critical → `1` high → `2` medium (default) → `3` low → `4` backlog

**Discovered work**: link with `--deps discovered-from:<parent-id>`

<!-- END BEADS INTEGRATION -->

## Landing the Plane (Session Completion)

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd sync
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
