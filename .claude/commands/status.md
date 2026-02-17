Show the swarm dashboard. Run all of these commands and format the output as a clear status report:

```bash
bd worktree list
```

```bash
bd merge-slot check
```

```bash
bd ready
```

```bash
bd list --status=in_progress
```

Present the results as a dashboard with sections:
- **Worktrees**: which exist and their branches
- **Merge Slot**: free or held (and by whom)
- **Ready Issues**: issues available for workers to claim
- **In Progress**: issues currently being worked on (and by whom)
