#!/usr/bin/env bash
# stitch - stitches patchwerk config into a new project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}ERROR: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

info() {
    echo "$1"
}

# Determine script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${1:-.}"

# Resolve absolute path
TARGET_DIR="$(cd "$TARGET_DIR" 2>/dev/null && pwd)" || error "Target directory '$1' does not exist"

info "Stitch - Patchwerk Config Installer"
info "===================================="
info ""
info "Source: $SCRIPT_DIR"
info "Target: $TARGET_DIR"
info ""

# Safety check - don't install into patchwerk itself
if [ "$SCRIPT_DIR" = "$TARGET_DIR" ]; then
    error "Cannot install into patchwerk directory itself"
fi

# Check if git repo
if [ ! -d "$TARGET_DIR/.git" ]; then
    warn "Target is not a git repository"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check for existing files and warn
WILL_OVERWRITE=false
for file in .claude AGENTS.md AGENTS.md.example; do
    if [ -e "$TARGET_DIR/$file" ]; then
        warn "Will overwrite: $file"
        WILL_OVERWRITE=true
    fi
done

if [ "$WILL_OVERWRITE" = true ]; then
    read -p "Continue and overwrite? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

info ""
info "Installing configuration..."
info ""

# Copy .claude directory
if [ -d "$SCRIPT_DIR/.claude" ]; then
    rm -rf "$TARGET_DIR/.claude"
    cp -r "$SCRIPT_DIR/.claude" "$TARGET_DIR/.claude"
    success "Copied .claude/ directory"
else
    error ".claude/ directory not found in $SCRIPT_DIR"
fi

# Copy AGENTS.md
if [ -f "$SCRIPT_DIR/AGENTS.md" ]; then
    cp "$SCRIPT_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"
    success "Copied AGENTS.md"
else
    error "AGENTS.md not found in $SCRIPT_DIR"
fi

# Copy AGENTS.md.example
if [ -f "$SCRIPT_DIR/AGENTS.md.example" ]; then
    cp "$SCRIPT_DIR/AGENTS.md.example" "$TARGET_DIR/AGENTS.md.example"
    success "Copied AGENTS.md.example"
else
    warn "AGENTS.md.example not found - skipping"
fi

info ""
success "Installation complete!"
info ""
info "Next steps:"
info "  1. Review AGENTS.md and customize for your project"
info "  2. Review .claude/CLAUDE.md if needed"
info "  3. Customize skills in .claude/skills/ as needed"
info ""
info "For template guidance, see AGENTS.md.example"
