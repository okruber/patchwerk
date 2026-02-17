#!/usr/bin/env bash
# Serialized merge protocol for workers.
# Acquires the merge slot, rebases onto main, fast-forward merges, then releases.
#
# Usage: bash orchestration/merge-back.sh
#   Must be run from inside a worker worktree with committed changes.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=identity.sh
source "$SCRIPT_DIR/identity.sh"

if [[ "$AGENT_ID" == "conductor" ]]; then
  echo "ERROR: merge-back.sh must be run from a worker worktree, not the conductor."
  exit 1
fi

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "=== Merge Protocol: $AGENT_ID ($BRANCH) ==="

# Step 1: Acquire the merge slot (blocks if another worker holds it)
echo "[1/5] Acquiring merge slot..."
bd merge-slot acquire --holder="$AGENT_ID" --wait

# Step 2: Rebase onto latest main
echo "[2/5] Rebasing onto main..."
git fetch origin main
if ! git rebase origin/main; then
  echo "ERROR: Rebase conflict detected. Aborting rebase and releasing merge slot."
  git rebase --abort
  bd merge-slot release --holder="$AGENT_ID"
  echo ""
  echo "Manual resolution required:"
  echo "  1. Fix conflicts in your worktree"
  echo "  2. Run merge-back.sh again"
  exit 1
fi

# Step 3: Push rebased branch
echo "[3/5] Pushing rebased branch..."
git push origin "$BRANCH" --force-with-lease

# Step 4: Fast-forward merge into main (done from main worktree)
echo "[4/5] Merging into main..."
cd "$MAIN_REPO"
git fetch origin
git checkout main
git merge "origin/$BRANCH" --ff-only

if [[ $? -ne 0 ]]; then
  echo "ERROR: Fast-forward merge failed. Main may have diverged."
  bd merge-slot release --holder="$AGENT_ID"
  exit 1
fi

git push origin main

# Step 5: Release the merge slot
echo "[5/5] Releasing merge slot..."
bd merge-slot release --holder="$AGENT_ID"

echo ""
echo "=== Merge complete: $BRANCH -> main ==="
