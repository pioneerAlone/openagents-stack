#!/usr/bin/env bash
# platform/macos/install_launcher.sh
# macOS-specific launcher install: installs the npm package
# @openagents-org/agent-launcher globally, which provides both the
# `agn` CLI and the OpenAgents Launcher.app menu bar application.
#
# The historical approach (download a .dmg from a "launcher-v*" GitHub
# release) was abandoned: launcher releases happen on npm, not on
# openagents monorepo tags. Pinned version comes from versions.lock as
# OPENAGENTS_LAUNCHER_VERSION.

install_launcher_macos() {
  # Install npm + Node if needed (launcher is a Node.js package)
  if ! command -v npm >/dev/null 2>&1; then
    log "Installing Node.js (npm) via Homebrew (launcher is a Node package)..."
    command -v brew >/dev/null 2>&1 || err "brew not found; install Node.js manually first: https://nodejs.org"
    brew install node
  fi

  # Make sure the user's global npm bin dir is on PATH. npm config get prefix
  # gives the global install root; on macOS with Homebrew Node it's usually
  # /opt/homebrew/bin or /usr/local/bin, both already on PATH. If the user
  # installed Node via nvm or otherwise, prefix may differ — warn if so.
  local npm_prefix
  npm_prefix="$(npm config get prefix 2>/dev/null)"
  if [[ -n "$npm_prefix" ]] && [[ ":$PATH:" != *":$npm_prefix/bin:"* ]]; then
    warn "npm global bin ($npm_prefix/bin) is not on PATH. Add it to ~/.zshrc:"
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

  # OpenAgents Launcher.app comes bundled inside the npm package.
  # npm global installs land under $(npm config get prefix)/lib/node_modules/@openagents-org/agent-launcher/.
  local app_src="$npm_prefix/lib/node_modules/@openagents-org/agent-launcher/OpenAgents Launcher.app"
  if [[ ! -d "$app_src" ]]; then
    # Some npm setups put it under share/ or elsewhere; do a targeted search.
    app_src="$(find "$npm_prefix/lib/node_modules/@openagents-org/agent-launcher" -maxdepth 4 -name "OpenAgents Launcher.app" -type d 2>/dev/null | head -1)"
  fi
  if [[ -z "$app_src" || ! -d "$app_src" ]]; then
    warn "OpenAgents Launcher.app not found inside npm package — menu bar app will be unavailable, but `agn` CLI is."
  else
    log "Installing menu bar app to /Applications (sudo)..."
    sudo rm -rf "/Applications/OpenAgents Launcher.app" 2>/dev/null || true
    sudo cp -R "$app_src" "/Applications/OpenAgents Launcher.app" \
      || err "Failed to copy app to /Applications"
    sudo xattr -dr com.apple.quarantine "/Applications/OpenAgents Launcher.app" 2>/dev/null || true
    ok "App installed: /Applications/OpenAgents Launcher.app"
  fi
}
