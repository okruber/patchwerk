Load the `swarm` skill if not already loaded.

You are a **worker agent**. Execute the following lifecycle:

## 1. Identity Check

Run `bash orchestration/identity.sh` to confirm you are a worker (not "conductor").
If you are the conductor, STOP and say: "This command is for workers only. Run /next from a worker worktree."

## 2. Clean Slate

```bash
git fetch origin main && git switch -C work origin/main --discard-changes
```

This ensures you start from the latest main on a fresh `work` branch. Any previous branch work is abandoned.

## 3. Find Work

Run `bd ready` to see issues available for claiming. Pick the **highest priority** issue (lowest priority number = highest priority).

If no issues are ready, report "No issues available. Ask the conductor to create work." and stop.

## 4. Claim the Issue

```bash
bd update <id> --status=in_progress --assignee=<your-worker-id>
```

Then run `bd show <id>` and display the full issue to the human.

## 5. Implement

Do the work described in the issue. Load relevant skills as needed (e.g., `dignified-python` for Python code, `fake-driven-testing` for tests).

## 6. VALIDATION GATE

**STOP HERE.** Ask the human to review your changes before proceeding. Show a summary of what you changed and wait for explicit approval.

Do NOT proceed past this point without human confirmation.

## 7. Commit

Stage and commit your changes in the worktree:

```bash
git add <specific-files>
git commit -m "<conventional commit message>"
```

## 8. Merge Back

```bash
bash orchestration/merge-back.sh
```

If the merge fails due to conflicts, report the issue and stop. The human will resolve it.

## 9. Close Issue

```bash
bd close <id>
```

## 10. Report

Summarize what was completed. Tell the human they can run `/next` again when ready for the next issue.
