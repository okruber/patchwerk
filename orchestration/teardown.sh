#!/usr/bin/env bash
# Remove worker worktrees and clean up swarm artifacts.
#
# Usage: bash orchestration/teardown.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$MAIN_REPO"

WORKERS=("worker-1" "worker-2")

echo "=== Swarm Teardown ==="
echo ""

# Step 1: Remove worktrees
echo "[1/2] Removing worktrees..."
for worker in "${WORKERS[@]}"; do
  if [[ -d "$worker" ]]; then
    bd worktree remove "$worker"
    echo "  Removed $worker/"
  else
    echo "  $worker/ not found, skipping."
  fi
done

# Step 2: Clean up identity files (should be gone with worktrees, but just in case)
echo "[2/2] Cleaning up..."
for worker in "${WORKERS[@]}"; do
  rm -f "$worker/.swarm-identity" 2>/dev/null || true
done

echo ""
echo "=== Teardown Complete ==="
echo "Worker worktrees removed. Merge slot preserved for future use."
