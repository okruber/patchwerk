#!/usr/bin/env bash
# One-time swarm initialization. Run from the main worktree.
# Creates worker worktrees, merge slot, junctions, and identity files.
#
# Usage: bash orchestration/setup.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$MAIN_REPO"

WORKERS=("worker-1" "worker-2")

echo "=== Swarm Setup ==="
echo "Main repo: $MAIN_REPO"
echo ""

# Step 1: Create worker worktrees
echo "[1/4] Creating worktrees..."
for worker in "${WORKERS[@]}"; do
  if [[ -d "$worker" ]]; then
    echo "  $worker/ already exists, skipping."
  else
    bd worktree create "$worker" --branch "$worker"
    echo "  Created $worker/"
  fi
done

# Step 2: Create merge slot
echo "[2/4] Creating merge slot..."
bd merge-slot create 2>/dev/null || echo "  Merge slot already exists."

# Step 3: Fix junctions in each worktree
echo "[3/4] Fixing junctions..."
for worker in "${WORKERS[@]}"; do
  bash "$SCRIPT_DIR/fix-junctions.sh" "$worker"
done

# Step 4: Write identity files
echo "[4/4] Writing identity files..."
for worker in "${WORKERS[@]}"; do
  echo "$worker" > "$worker/.swarm-identity"
  echo "  Wrote $worker/.swarm-identity"
done

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "  1. Open a new Claude Code session in $MAIN_REPO/$( echo "${WORKERS[0]}" )/"
echo "  2. Open a new Claude Code session in $MAIN_REPO/$( echo "${WORKERS[1]}" )/"
echo "  3. In each worker session, run /next to claim and start work"
echo "  4. Use this session (conductor) to plan and create issues with bd"
echo ""
echo "Useful commands:"
echo "  bd ready                  # See issues available for workers"
echo "  bd list --status=open     # All open issues"
echo "  bd worktree list          # Check worktree status"
echo "  bd merge-slot check       # Check merge slot status"
