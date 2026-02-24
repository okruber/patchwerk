---
name: swarm
description: Load when running parallel agent workflows. Covers conductor/worker roles, merge protocol, worker lifecycle, and beads coordination commands.
---

# Swarm Orchestration Protocol

## When to Load This Skill

Load this skill when:
- Setting up or running a multi-agent swarm session
- Operating as a conductor or worker agent
- Using `/next`, `/setup-swarm`, `/teardown-swarm`, or `/status` commands
- Working with `bd worktree`, `bd merge-slot`, or the merge-back protocol

---

## Architecture

```
main worktree (conductor)     worker-1/     worker-2/
        |                        |              |
        |--- creates issues ---->|              |
        |                        |-- /next ---->|
        |                        |              |-- /next -->
        |<-- merge-back ---------|              |
        |<-- merge-back -------------------------|
```

**1 conductor** (main worktree) + **N workers** (dedicated worktrees).

Human is the orchestrator. Agents are tools.

---

## Roles

### Conductor (main worktree)

- Plans work and creates beads issues (`bd create`)
- Sets priorities and dependencies (`bd dep add`)
- Monitors progress (`/status`)
- Does NOT run `/next` — that's for workers only
- May do free-form work directly on main

### Worker (worktree: `worker-N/`)

- Runs `/next` to enter the claim-implement-merge lifecycle
- Works on exactly one issue at a time
- Always resets to `origin/main` before starting new work
- Merges back through the serialized merge protocol
- Never works on main directly

---

## Merge Protocol

The merge slot ensures only one worker merges at a time, preventing conflicts:

```
Worker commits changes
  |
  v
BD_ACTOR=<worker> bd update <prefix>-merge-slot --claim   # atomic acquire
  |
  v
git fetch origin main && git rebase origin/main   # get latest
  |
  v
git push origin <branch> --force-with-lease        # push rebased branch
  |
  v
(in main worktree) git merge origin/<branch> --ff-only
  |
  v
git push origin main
  |
  v
BD_ACTOR=<worker> bd update <prefix>-merge-slot --status=open --assignee=""
```

**On rebase conflict**: abort rebase, release slot, report to human.

**Never force-push main.** Only fast-forward merges are allowed.

---

## Worker Lifecycle (`/next`)

Each `/next` cycle:

1. **Identity check** — confirm we're a worker (not conductor)
2. **Clean slate** — `git fetch origin main && git switch -C work origin/main --discard-changes`
3. **Claim issue** — `bd ready` → pick highest priority → `bd update <id> --status=in_progress --assignee=<worker>`
4. **Implement** — do the work, load relevant skills as needed
5. **Human review** — STOP and ask human to review before proceeding
6. **Commit** — stage and commit in worktree
7. **Merge back** — run `orchestration/merge-back.sh`
8. **Close issue** — `bd close <id>`
9. **Report** — summarize what was done, ready for next `/next`

---

## Beads Commands Reference

| Command | Purpose |
|---------|---------|
| `bd ready` | Issues with no blockers, ready to claim |
| `bd list --status=open` | All open issues |
| `bd list --status=in_progress` | Currently claimed work |
| `bd show <id>` | Issue details with dependencies |
| `bd create --title="..." --type=task --priority=2` | Create new issue |
| `bd update <id> --status=in_progress` | Claim an issue |
| `bd update <id> --assignee=<worker>` | Assign to worker |
| `bd close <id>` | Mark issue complete |
| `bd dep add <issue> <depends-on>` | Add dependency |
| `bd worktree list` | Show all worktrees |
| `bd worktree create <name> --branch <name>` | Create worker worktree |
| `bd worktree remove <name>` | Remove worker worktree |
| `bd merge-slot create` | Initialize merge slot |
| `bd update <prefix>-merge-slot --claim` | Lock merge slot (workaround) |
| `bd update <prefix>-merge-slot --status=open --assignee=""` | Release merge slot (workaround) |
| `bd merge-slot check` | Check who holds the slot |
| `bd sync` | Sync beads state with git |

---

## Scripts Reference

| Script | Purpose | Run from |
|--------|---------|----------|
| `orchestration/setup.sh` | Create worktrees, merge slot, junctions | Main worktree |
| `orchestration/teardown.sh` | Remove worktrees, clean up | Main worktree |
| `orchestration/identity.sh` | Detect conductor vs worker identity | Any worktree |
| `orchestration/merge-back.sh` | Serialized merge protocol | Worker worktree |
| `orchestration/fix-junctions.sh <path>` | Recreate .claude/ junctions | Main worktree |

---

## Rules

1. **One issue per worker at a time.** No multitasking.
2. **Always reset to main before new work.** Workers start clean.
3. **Merge slot is mandatory.** No direct pushes to main from workers.
4. **Human validates before merge.** The validation gate is not optional.
5. **Conductor creates issues, workers consume them.** Clear separation.
6. **Load relevant skills for the work.** Swarm skill handles coordination; load `dignified-python`, `fake-driven-testing`, etc. for actual implementation.
