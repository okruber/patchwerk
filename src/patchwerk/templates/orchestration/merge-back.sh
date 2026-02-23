#!/usr/bin/env bash
# Serialized merge protocol for workers.
# Acquires the merge slot, rebases onto main, fast-forward merges, then releases.
#
# Usage: bash orchestration/merge-back.sh
#   Must be run from inside a worker worktree with committed changes.
#
# Workaround: bd merge-slot acquire/release have a bug ("invalid field for
# update: holder"), so we use bd update --claim / --status=open directly on
# the <prefix>-merge-slot bead instead.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=identity.sh
source "$SCRIPT_DIR/identity.sh"

if [[ "$AGENT_ID" == "conductor" ]]; then
  echo "ERROR: merge-back.sh must be run from a worker worktree, not the conductor."
  exit 1
fi

# Derive merge-slot bead ID from bd config prefix
SLOT_ID="$(bd config get issue_prefix 2>/dev/null | awk '{print $NF}')-merge-slot"

BRANCH="$(git rev-parse --abbrev-ref HEAD)"
echo "=== Merge Protocol: $AGENT_ID ($BRANCH) ==="

# Step 1: Acquire the merge slot (atomic claim: sets assignee + in_progress)
echo "[1/5] Acquiring merge slot..."
MAX_RETRIES=30
RETRY_DELAY=5
for ((i=1; i<=MAX_RETRIES; i++)); do
  if BD_ACTOR="$AGENT_ID" bd update "$SLOT_ID" --claim 2>/dev/null; then
    echo "  Merge slot acquired by $AGENT_ID"
    break
  fi
  if [[ $i -eq $MAX_RETRIES ]]; then
    echo "ERROR: Could not acquire merge slot after $MAX_RETRIES attempts."
    exit 1
  fi
  echo "  Slot held by another worker, retrying in ${RETRY_DELAY}s... ($i/$MAX_RETRIES)"
  sleep "$RETRY_DELAY"
done

# Helper: release the merge slot (reset to open, clear assignee)
release_slot() {
  BD_ACTOR="$AGENT_ID" bd update "$SLOT_ID" --status=open --assignee="" 2>/dev/null || true
}

# Step 2: Rebase onto latest main
echo "[2/5] Rebasing onto main..."
git fetch origin main
if ! git rebase origin/main; then
  echo "ERROR: Rebase conflict detected. Aborting rebase and releasing merge slot."
  git rebase --abort
  release_slot
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
if ! git merge "origin/$BRANCH" --ff-only; then
  echo "ERROR: Fast-forward merge failed. Main may have diverged."
  release_slot
  exit 1
fi

git push origin main

# Step 5: Release the merge slot
echo "[5/5] Releasing merge slot..."
release_slot

echo ""
echo "=== Merge complete: $BRANCH -> main ==="
