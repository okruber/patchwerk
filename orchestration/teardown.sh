#!/usr/bin/env bash
# Remove worker worktrees and clean up swarm artifacts.
#
# Usage: bash orchestration/teardown.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$MAIN_REPO"

PREFIX="patchwerk"
WORKERS=("worker-1" "worker-2")

echo "=== Swarm Teardown ==="
echo ""

# Step 1: Kill tmux sessions
echo "[1/3] Killing tmux sessions..."
if command -v tmux &>/dev/null; then
  for name in "conductor" "${WORKERS[@]}"; do
    session="${PREFIX}_${name}"
    if tmux has-session -t "$session" 2>/dev/null; then
      tmux kill-session -t "$session"
      echo "  Killed $session"
    fi
  done
else
  echo "  tmux not found, skipping."
fi

# Step 2: Remove worktrees
echo "[2/3] Removing worktrees..."
for worker in "${WORKERS[@]}"; do
  if [[ -d "$worker" ]]; then
    bd worktree remove "$worker"
    echo "  Removed $worker/"
  else
    echo "  $worker/ not found, skipping."
  fi
done

# Step 3: Clean up identity files (should be gone with worktrees, but just in case)
echo "[3/3] Cleaning up..."
for worker in "${WORKERS[@]}"; do
  rm -f "$worker/.swarm-identity" 2>/dev/null || true
done

echo ""
echo "=== Teardown Complete ==="
echo "Worker worktrees removed. Merge slot preserved for future use."
