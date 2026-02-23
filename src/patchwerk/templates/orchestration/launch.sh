#!/usr/bin/env bash
# Launch the swarm as separate tmux sessions (one per agent).
# Compatible with stacken-tui, which discovers patchwerk_* sessions.
# Workers auto-run /next to claim work immediately.
#
# Prerequisites: tmux installed, worktrees created via setup.sh
#
# Usage: bash orchestration/launch.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$MAIN_REPO"

PREFIX="patchwerk"
WORKERS=("worker-1" "worker-2")

# --- Pre-flight checks ---

if ! command -v tmux &>/dev/null; then
  echo "ERROR: tmux is not installed. Install it first:"
  echo "  macOS:  brew install tmux"
  echo "  Linux:  sudo apt install tmux"
  exit 1
fi

missing=()
for worker in "${WORKERS[@]}"; do
  if [[ ! -d "$MAIN_REPO/$worker" ]]; then
    missing+=("$worker")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "ERROR: Missing worktrees: ${missing[*]}"
  echo "Run setup first:  bash orchestration/setup.sh"
  exit 1
fi

# --- Helper: create or replace a detached tmux session ---

launch_session() {
  local name="$1"
  local dir="$2"
  local cmd="$3"

  if tmux has-session -t "$name" 2>/dev/null; then
    echo "  Killing existing session: $name"
    tmux kill-session -t "$name"
  fi

  tmux new-session -d -s "$name" -c "$dir"
  tmux send-keys -t "$name" "$cmd" Enter
  echo "  Started: $name"
}

# --- Launch sessions ---

echo "=== Launching Swarm ==="
echo ""

# Conductor
launch_session "${PREFIX}_conductor" "$MAIN_REPO" "claude"

# Workers
for worker in "${WORKERS[@]}"; do
  launch_session "${PREFIX}_${worker}" "$MAIN_REPO/$worker" "claude \"/next\""
done

echo ""
echo "=== Swarm Running ==="
echo ""
echo "Monitor with stacken-tui, or attach directly:"
echo "  tmux attach -t ${PREFIX}_conductor"
for worker in "${WORKERS[@]}"; do
  echo "  tmux attach -t ${PREFIX}_${worker}"
done
echo ""
echo "Tear down sessions:  bash orchestration/teardown.sh"
