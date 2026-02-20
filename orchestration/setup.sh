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
echo "[1/5] Creating worktrees..."
for worker in "${WORKERS[@]}"; do
  if [[ -d "$worker" ]]; then
    echo "  $worker/ already exists, skipping."
  else
    bd worktree create "$worker" --branch "$worker"
    echo "  Created $worker/"
  fi
done

# Step 2: Create merge slot
echo "[2/5] Creating merge slot..."
bd merge-slot create 2>/dev/null || echo "  Merge slot already exists."

# Step 3: Fix junctions in each worktree
echo "[3/5] Fixing junctions..."
for worker in "${WORKERS[@]}"; do
  bash "$SCRIPT_DIR/fix-junctions.sh" "$worker"
done

# Step 4: Write identity files
echo "[4/5] Writing identity files..."
for worker in "${WORKERS[@]}"; do
  echo "$worker" > "$worker/.swarm-identity"
  echo "  Wrote $worker/.swarm-identity"
done

# Step 5: Generate worker launcher scripts
echo "[5/5] Generating launcher scripts..."
for worker in "${WORKERS[@]}"; do
  worker_abs="$MAIN_REPO/$worker"

  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* || "$OSTYPE" == "cygwin" ]]; then
    # Windows: generate .bat file that clears CLAUDECODE and launches claude
    launcher="$worker_abs/launch-worker.bat"
    win_path="$(cygpath -w "$worker_abs")"
    cat > "$launcher" <<BATCH
@echo off
title Claude Code - $worker
set CLAUDECODE=
cd /d "$win_path"
echo Starting Claude Code in $worker...
echo.
claude
if errorlevel 1 (
  echo.
  echo Claude Code exited with an error. Press any key to close.
  pause >nul
)
BATCH
    echo "  Generated $launcher"
  else
    # Unix: generate shell script that strips env and launches claude
    launcher="$worker_abs/launch-worker.sh"
    cat > "$launcher" <<'SHELL'
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL
    cat >> "$launcher" <<SHELL
cd "\$SCRIPT_DIR"
echo "Starting Claude Code in $worker..."
unset CLAUDECODE
exec claude
SHELL
    chmod +x "$launcher"
    echo "  Generated $launcher"
  fi
done

echo ""
echo "=== Setup Complete ==="
echo ""

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* || "$OSTYPE" == "cygwin" ]]; then
  echo "To launch workers, open each .bat file from Windows Explorer:"
  for worker in "${WORKERS[@]}"; do
    echo "  $(cygpath -w "$MAIN_REPO/$worker/launch-worker.bat")"
  done
  echo ""
  echo "Or from a NEW terminal (not this one):"
  for worker in "${WORKERS[@]}"; do
    echo "  cd $MAIN_REPO/$worker && unset CLAUDECODE && claude"
  done
else
  echo "To launch workers:"
  for worker in "${WORKERS[@]}"; do
    echo "  bash $MAIN_REPO/$worker/launch-worker.sh"
  done
  echo ""
  echo "Or manually in a new terminal:"
  for worker in "${WORKERS[@]}"; do
    echo "  cd $MAIN_REPO/$worker && unset CLAUDECODE && claude"
  done
fi

echo ""
echo "In each worker session, run /next to claim and start work."
echo "Use this session (conductor) to plan and create issues with bd."
echo ""
echo "Useful commands:"
echo "  bd ready                  # See issues available for workers"
echo "  bd list --status=open     # All open issues"
echo "  bd worktree list          # Check worktree status"
echo "  bd merge-slot check       # Check merge slot status"
