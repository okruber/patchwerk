---
name: brainstorming
description: Structured pre-implementation protocol. Context discovery, scope assessment, approach selection, and beads decomposition before any code is written.
---

# Brainstorming Protocol

## When to Load This Skill

Load this skill when:
- A task touches 3+ files or 2+ modules
- Working with an unfamiliar library, API, or pattern
- The task description is ambiguous or underspecified
- The work feels like more than one session
- The user asks "how should we..." or "what's the best way to..."
- The user invokes `/brainstorm`

Do NOT load this skill when:
- Single-file change with clear scope
- Mechanical rename/refactor
- Docs-only change
- Bug fix with obvious root cause
- User says "just do it" or "skip brainstorming"

---

## Protocol

Six steps, in order. **NEVER write code during brainstorming.**

### Step 1: Context Discovery

Silent — no questions to the user yet. Build an internal understanding:

1. Read project configs (`pyproject.toml`, `.python-version`, `Dockerfile`, etc.)
2. Search for existing patterns/code related to the task (Glob/Grep)
3. Check recent git history: `git log --oneline -20`
4. Note environment: OS, Python version, key dependencies
5. Identify relevant existing abstractions, interfaces, or conventions

Output: an internal context summary (share key findings with the user, not raw dumps). This prevents dead-end first implementations.

### Step 2: Scope Assessment

Classify the task:

| Size | Criteria | Artifact |
|------|----------|----------|
| **Quick-fix** | Single-file, obvious change, trivially scoped (typo, one-liner, config tweak) | No bead — skip to implementation |
| **Planned** | Everything else | Bead(s) via `bd create` |

**Beads are the default.** Only skip for trivially obvious fixes. When in doubt, create a bead — persistence you don't need beats lost context.

For **Planned** work, decompose into beads where each bead = one unit of work an agent can implement:
- A bead should have a single concern (one module, one feature slice, one interface + its fake)
- A bead should be completable without context from unfinished sibling beads
- If a task is already one unit of work: 1 bead
- If a task has separable parts: multiple beads with dependencies via `bd dep add`

Scope each bead by what an agent can hold in context — not by time or session count.

### Step 3: Clarifying Questions

Max 5 questions, asked one at a time. Use multiple-choice options when possible.

- Only ask what can't be answered from code (Step 1 already explored the codebase)
- Skip entirely if context discovery answered everything

### Step 4: Propose Approaches

Present 2-3 options with trade-offs:

For each approach:
- One-sentence summary
- Key files affected
- What you gain / what you lose
- Cite existing patterns found in Step 1

The user picks one. **This is the approval gate** — no implementation begins without a chosen approach.

### Step 5: Produce Artifact

Based on scope assessment from Step 2:

- **Quick-fix**: No bead. Proceed directly to implementation.
- **Single unit of work**: Create 1 bead via `bd create` with:
  - Goal (what, not how)
  - Key files to touch
  - Chosen approach from Step 4
  - Acceptance criteria
  Then begin implementation.
- **Multiple units of work**: Create beads via `bd create` (one per unit), add dependencies via `bd dep add`, present the dependency graph to the user. User picks which bead to start or spins up a swarm.

### Step 6: Transition

- **Quick-fix / single bead**: Begin implementation. Exit plan mode if active.
- **Multiple beads**: User decides execution strategy:
  - Solo: `bd ready` to pick the next available bead
  - Parallel: `/setup-swarm` to spin up workers

---

## Rules

1. **NEVER write code during brainstorming.** The protocol produces understanding and artifacts, not implementation.
2. **NEVER skip context discovery.** Step 1 prevents the dead-end first implementations that waste sessions.
3. **Max 3 approaches, max 5 questions.** Brainstorming should be focused, not exhaustive.
4. **"Just do it" = Quick-fix.** Classify as quick-fix, skip bead, proceed to implementation immediately.
5. **Context persists.** Don't re-discover mid-session. Step 1 findings carry forward.
6. **Beads are the default.** Only skip for trivially obvious single-file fixes.
