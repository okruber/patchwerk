#!/usr/bin/env bash
# Recreate .claude/ junctions in a worktree pointing back to the main repo.
# Required because core.symlinks=false means git won't recreate junctions in worktrees.
#
# Usage: bash orchestration/fix-junctions.sh <worktree-path>
#   e.g. bash orchestration/fix-junctions.sh worker-1
set -euo pipefail

WORKTREE="${1:?Usage: fix-junctions.sh <worktree-path>}"

# Resolve the main repo root (where this script lives)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_REPO="$(cd "$SCRIPT_DIR/.." && pwd)"

# Target directories in the worktree
CLAUDE_DIR="$WORKTREE/.claude"

# Source directories in the main repo
AGENT_DEFS="$MAIN_REPO/.agent-defs"
AGENT_SKILLS="$MAIN_REPO/.agent-skills"

# Ensure .claude directory exists in worktree
mkdir -p "$CLAUDE_DIR"

create_junction() {
  local target="$1"  # what to link to
  local link="$2"    # where the link goes

  # Remove existing link/directory if present
  if [[ -d "$link" ]]; then
    rm -rf "$link"
  fi

  if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "mingw"* || "$OSTYPE" == "cygwin" ]]; then
    # Windows: use cmd junction (works without admin privileges)
    local win_target win_link
    win_target="$(cygpath -w "$target")"
    win_link="$(cygpath -w "$link")"
    cmd //c "mklink /J \"$win_link\" \"$win_target\"" > /dev/null
  else
    # Unix: use symbolic link
    ln -s "$target" "$link"
  fi
}

echo "Fixing junctions in $WORKTREE..."

create_junction "$AGENT_DEFS" "$CLAUDE_DIR/agents"
echo "  .claude/agents -> $AGENT_DEFS"

create_junction "$AGENT_SKILLS" "$CLAUDE_DIR/skills"
echo "  .claude/skills -> $AGENT_SKILLS"

echo "Done."
