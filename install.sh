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
# We write the block to BOTH ~/.zshrc (interactive zsh, default on macOS) and
# ~/.bashrc + ~/.bash_profile (for users running bash interactively or in
# scripts that source bash_profile). Each file gets its own marked block so
# removing openagents-stack cleanly later is straightforward.
add_path_block() {
  local rc_file="$1"
  mkdir -p "$(dirname "$rc_file")"
  touch "$rc_file"

  local marker="# >>> openagents-stack PATH >>>"
  local marker_end="# <<< openagents-stack PATH <<<"

  if ! grep -qF "$marker" "$rc_file"; then
    {
      echo ''
      echo "$marker"
      echo 'export PATH="$HOME/.local/bin:$PATH"'
      echo "$marker_end"
    } >> "$rc_file"
    echo "==> Added ~/.local/bin to PATH in $rc_file"
  else
    echo "==> ~/.local/bin already in PATH in $rc_file (marker found)"
  fi
}

# zsh (interactive default on macOS since Catalina)
add_path_block "$HOME/.zshrc"
# bash — write to both .bashrc (interactive non-login) and .bash_profile
# (login shells on macOS skip .bashrc unless configured otherwise).
add_path_block "$HOME/.bashrc"
add_path_block "$HOME/.bash_profile"

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
