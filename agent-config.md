 This is a layered, modular agent configuration system for Claude Code that separates concerns and makes the workflow stack-agnostic.

  Core Structure

  .claude/
  ├── CLAUDE.md              → @../AGENTS.md (just a pointer)
  └── skills/
      ├── dignified-python/  → Python coding standards (LBYL, types, ABC)
      ├── fake-driven-testing/ → 5-layer test architecture
      └── agents/
          ├── devrun.md      → Read-only test runner
          └── haiku-devrun.md → Cost-optimized test runner

  AGENTS.md                  → Central configuration (root level)

  How It Works

  1. Entry Point: CLAUDE.md

  - Claude Code automatically loads .claude/CLAUDE.md
  - Contains only: @../AGENTS.md
  - This reference syntax tells Claude to load the AGENTS.md file from project root
  - Makes the .claude/ directory stack-agnostic - can be reused across projects

  2. Central Config: AGENTS.md

  Contains your project-specific guidance:
  - Working relationship (ask for clarification, push back when needed)
  - Development principles (YAGNI, DRY, SOLID, ABOUTME comments)
  - Debugging framework (4-phase root cause analysis)
  - GCP observability (gcloud CLI over MCP, token management)
  - References to skills that should be loaded

  3. Skills: Specialized Domain Knowledge

  Loaded on-demand when relevant:

  dignified-python:
  - LBYL exception handling
  - Modern type syntax (list[str], str | None)
  - pathlib operations, ABC interfaces
  - Version-specific guidance (3.10-3.13)

  fake-driven-testing:
  - 5-layer defense-in-depth testing strategy
  - Gateway/adapter patterns with Fakes
  - Test placement guidelines (70% over fakes, 5% integration)
  - Complete workflows for adding features/fixing bugs

  4. Agents: Task Executors

  Specialized sub-agents for specific tasks:

  devrun / haiku-devrun:
  - READ-ONLY - cannot modify files
  - Runs dev tools: pytest, ty, ruff, prettier, make
  - Parses output and returns structured results
  - Parent agent handles all fixes based on results

  Workflow Example

  User: "Add authentication and write tests"
    ↓
  Claude loads: .claude/CLAUDE.md
    ↓
    @../AGENTS.md loaded
    ↓
  AGENTS.md says: "Load dignified-python and fake-driven-testing skills"
    ↓
  Claude loads both skills, now has:
    - Your working style & debugging approach
    - Python standards (LBYL, modern types)
    - 5-layer test architecture knowledge
    ↓
  Claude implements feature following:
    - TDD workflow (fake-driven-testing)
    - Python best practices (dignified-python)
    - Your debugging framework (AGENTS.md)
    ↓
  When ready to test, spawns devrun agent:
    ↓
  devrun runs: pytest tests/
    ↓
  devrun returns: "3 tests passed, 1 failed at line 42"
    ↓
  Claude (parent) fixes the issue based on devrun results

  Key Benefits

  1. Stack-Agnostic: .claude/ folder can be reused across projects
  2. Separation of Concerns: General guidance vs domain expertise vs tooling
  3. On-Demand Loading: Skills only loaded when relevant
  4. Cost-Efficient: devrun uses Haiku for cheap test runs
  5. Read-Only Safety: Agents can't accidentally modify files
  6. Maintainable: Update AGENTS.md for project-specific changes, update skills for domain knowledge

  Flow of Authority

  CLAUDE.md (pointer)
      ↓
  AGENTS.md (your rules + skill routing)
      ↓
      ├→ dignified-python skill (Python standards)
      ├→ fake-driven-testing skill (test architecture)
      └→ devrun agents (read-only execution)