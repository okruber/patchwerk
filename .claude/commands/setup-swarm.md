Initialize the swarm infrastructure for parallel agent work.

Run the setup script:

```bash
bash orchestration/setup.sh
```

After it completes, explain the output to the human and summarize the next steps:
- How many worktrees were created
- Where to open new Claude Code sessions (one per worker directory)
- How to create issues for workers to claim (`bd create`)
- How workers start their lifecycle (`/next`)
