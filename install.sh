#!/usr/bin/env bash
# =============================================================================
# install.sh - one-line installer for openagents-stack
# =============================================================================
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/install.sh | bash
#
# What it does:
#   1. Clone the repo to ~/openagents-stack (or `git pull` if it exists)
#   2. Symlink bin/openagents-stack to ~/.local/bin/openagents-stack
#   3. Add ~/.local/bin to PATH in ~/.zshrc (idempotent, marked block)
#   4. Invoke bin/openagents-stack to install dependencies
#
# After install, from ANY new terminal you can run:
#   openagents-stack --check
#   openagents-stack --start
#   openagents-stack --status
# No `cd` to the repo dir, no `source ~/.zshrc` needed.
# =============================================================================

set -euo pipefail

REPO_URL="https://github.com/pioneerAlone/openagents-stack.git"
INSTALL_DIR="${OPENAGENTS_STACK_HOME:-$HOME/openagents-stack}"
BIN_LINK_DIR="$HOME/.local/bin"
BIN_NAME="openagents-stack"
SHELL_RC="$HOME/.zshrc"

# ── Step 1: Clone or update repo ──────────────────────────────────────────────
if [[ -d "$INSTALL_DIR/.git" ]]; then
  echo "==> Repo already at $INSTALL_DIR, pulling latest..."
  (cd "$INSTALL_DIR" && git pull --ff-only)
else
  echo "==> Cloning $REPO_URL to $INSTALL_DIR..."
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

# ── Step 2: Symlink bin/<name> to ~/.local/bin/<name> ────────────────────────
mkdir -p "$BIN_LINK_DIR"
ln -sf "$INSTALL_DIR/bin/$BIN_NAME" "$BIN_LINK_DIR/$BIN_NAME"
echo "==> Symlinked $BIN_LINK_DIR/$BIN_NAME -> $INSTALL_DIR/bin/$BIN_NAME"

# ── Step 3: Add ~/.local/bin to PATH (idempotent, marked block) ──────────────
# Use a unique marker so we never collide with user-managed PATH entries.
mkdir -p "$(dirname "$SHELL_RC")"
touch "$SHELL_RC"

PATH_MARKER="# >>> openagents-stack PATH >>>"
PATH_MARKER_END="# <<< openagents-stack PATH <<<"

if ! grep -qF "$PATH_MARKER" "$SHELL_RC"; then
  {
    echo ''
    echo "$PATH_MARKER"
    echo 'export PATH="$HOME/.local/bin:$PATH"'
    echo "$PATH_MARKER_END"
  } >> "$SHELL_RC"
  echo "==> Added ~/.local/bin to PATH in $SHELL_RC"
else
  echo "==> ~/.local/bin already in PATH (marker found)"
fi

# ── Step 4: Invoke the actual setup (install deps, clone monorepo, etc.) ──
echo ""
echo "==> Running openagents-stack setup..."
echo ""
"$INSTALL_DIR/bin/$BIN_NAME"

# ── Done ────────────────────────────────────────────────────────────────────
echo ""
echo "=================================================================="
echo "  ✅ Installed!"
echo ""
echo "  From any NEW terminal you can now run:"
echo "    openagents-stack --check"
echo "    openagents-stack --start"
echo "    openagents-stack --status"
echo ""
echo "  (No cd, no source needed. ~/.local/bin is in PATH.)"
echo ""
echo "  To uninstall:"
echo "    rm $BIN_LINK_DIR/$BIN_NAME"
echo "    rm -rf $INSTALL_DIR"
echo "    # then remove the >>> openagents-stack PATH >>> block from $SHELL_RC"
echo "=================================================================="
