#!/usr/bin/env bash
# platform/linux/install_launcher.sh
# Linux-specific launcher install: same as macOS (npm package),
# minus the OpenAgents Launcher.app menu bar application (Linux
# has no .app bundle, and the agn CLI is what the stack actually
# depends on).

install_launcher_linux() {
  # Install npm + Node if needed (launcher is a Node.js package)
  if ! command -v npm >/dev/null 2>&1; then
    log "Installing Node.js (npm) for the launcher..."
    if command -v apt-get >/dev/null 2>&1; then
      # Debian / Ubuntu path
      curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
      sudo apt-get install -y nodejs
    elif command -v dnf >/dev/null 2>&1; then
      # Fedora / RHEL path
      curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo -E bash -
      sudo dnf install -y nodejs
    elif command -v pacman >/dev/null 2>&1; then
      # Arch path
      sudo pacman -Sy --noconfirm nodejs npm
    else
      err "No supported package manager found. Install Node.js manually: https://nodejs.org"
    fi
  fi

  # Make sure the user's global npm bin dir is on PATH.
  local npm_prefix
  npm_prefix="$(npm config get prefix 2>/dev/null)"
  if [[ -n "$npm_prefix" ]] && [[ ":$PATH:" != *":$npm_prefix/bin:"* ]]; then
    warn "npm global bin ($npm_prefix/bin) is not on PATH. Add it to your shell rc file:"
    warn "  export PATH=\"\$npm_prefix/bin:\$PATH\""
  fi

  # Install pinned version
  log "Installing @openagents-org/agent-launcher@$OPENAGENTS_LAUNCHER_VERSION via npm..."
  if ! npm install -g "@openagents-org/agent-launcher@$OPENAGENTS_LAUNCHER_VERSION" 2>&1 | tail -10; then
    err "npm install -g @openagents-org/agent-launcher failed. Check: npm config get prefix"
  fi

  # Verify
  if ! command -v agn >/dev/null 2>&1; then
    err "agn still not in PATH after npm install -g. PATH=$PATH"
  fi
  local installed_ver
  installed_ver="$(agn --version 2>/dev/null | head -1)"
  ok "Launcher CLI installed: $installed_ver (at $(command -v agn))"

  # Note: there's no OpenAgents Launcher.app on Linux (it's a .app
  # bundle which is a macOS-only concept). The agn CLI is what the
  # stack depends on; the menu bar app is a user convenience that's
  # not part of the install story on Linux.
  log "Note: OpenAgents Launcher.app is macOS-only; on Linux the agn CLI is the only launcher surface."
}
