#!/usr/bin/env bash
# Detect which agent we are based on .swarm-identity or worktree directory name.
# Usage: source orchestration/identity.sh  (sets AGENT_ID)
#        bash orchestration/identity.sh     (prints agent ID)
set -euo pipefail

detect_identity() {
  local identity_file=".swarm-identity"

  # 1. Check for explicit identity file in current directory
  if [[ -f "$identity_file" ]]; then
    cat "$identity_file" | tr -d '[:space:]'
    return
  fi

  # 2. Check if we're in a worktree by looking at directory name
  local dirname
  dirname="$(basename "$(pwd)")"
  if [[ "$dirname" =~ ^worker-[0-9]+$ ]]; then
    echo "$dirname"
    return
  fi

  # 3. Check git worktree metadata to see if this is the main worktree
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    local git_common_dir git_dir
    git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)"
    git_dir="$(git rev-parse --git-dir 2>/dev/null)"

    # If git-dir equals git-common-dir, we're in the main worktree
    if [[ "$(realpath "$git_dir")" == "$(realpath "$git_common_dir")" ]]; then
      echo "conductor"
      return
    fi
  fi

  # 4. Default fallback
  echo "conductor"
}

AGENT_ID="$(detect_identity)"
export AGENT_ID

# When executed directly (not sourced), print the identity
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "$AGENT_ID"
fi
