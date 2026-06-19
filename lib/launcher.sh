# launcher.sh - install openagents launcher (CLI + desktop app)
# Source: `source lib/launcher.sh`

# Each platform provides its own install_launcher_<platform>
# Source platform-specific launcher installer (provides install_launcher_<PLATFORM>)
# Caller should have already sourced the platform file before this point, but we source defensively.
# Note: PLATFORM and PLATFORM_DIR must be set by caller (bin/openagents-stack does this)
if [[ -n "${PLATFORM_DIR:-}" ]] && [[ -n "${PLATFORM:-}" ]] && [[ -f "$PLATFORM_DIR/${PLATFORM}/install_launcher.sh" ]]; then
  source "$PLATFORM_DIR/${PLATFORM}/install_launcher.sh"
fi

step_install_launcher() {
  log "[2/5] Install launcher"

  # ── Step 1: Check what's installed locally ──
  local has_cli=false
  local has_app=false
  command -v agn >/dev/null 2>&1 && has_cli=true
  [[ "$PLATFORM" == "macos" ]] && [[ -d "/Applications/OpenAgents Launcher.app" ]] && has_app=true

  if ! $has_cli && ! $has_app; then
    # Nothing installed → install
    log "  Need to install: nothing found locally"
    install_launcher_$PLATFORM
  elif ! $has_cli || ! $has_app; then
    # Partial install → complete
    log "  Partial install: CLI=$has_cli app=$has_app → completing"
    install_launcher_$PLATFORM
  else
    # ── Step 2: Both installed → check version ──
    local current_version
    current_version=$(agn --version 2>/dev/null | head -1 | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    local pinned_version="${OPENAGENTS_LAUNCHER_TAG#launcher-}"  # strip "launcher-" prefix

    if [[ -z "$current_version" ]]; then
      warn "Could not detect installed version. Proceeding with reinstall to be safe."
      install_launcher_$PLATFORM
    elif [[ "$current_version" == "$pinned_version" ]]; then
      ok "Launcher already at pinned version $current_version (no install needed)"
      done_step step_install_launcher
      return 0
    else
      # Version mismatch → ask user
      echo ""
      warn "Version mismatch detected:"
      echo "  Installed: $current_version"
      echo "  Pinned:    $pinned_version (from versions.lock)"
      echo ""
      read -rp "  Upgrade? (y/n) [n]: " ans
      ans="${ans:-n}"
      if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
        log "  Upgrading from $current_version → $pinned_version"
        install_launcher_$PLATFORM
      else
        log "  Keeping installed version $current_version"
        warn "Note: openagents-stack expects $pinned_version. Some features may not work."
      fi
    fi
  fi

  # ── Step 3: Verify both after install ──
  command -v agn >/dev/null 2>&1 || err "Launcher CLI installation failed; agn not in PATH"
  if [[ "$PLATFORM" == "macos" ]] && [[ ! -d "/Applications/OpenAgents Launcher.app" ]]; then
    err "Launcher app installation failed; /Applications/OpenAgents Launcher.app not found"
  fi
  ok "Launcher installed: CLI + app"
  done_step step_install_launcher

  # Start desktop app if installed and not running
  if [[ "$PLATFORM" == "macos" ]] && [[ -d "/Applications/OpenAgents Launcher.app" ]]; then
    if ! pgrep -f "OpenAgents Launcher" >/dev/null 2>&1; then
      open "/Applications/OpenAgents Launcher.app" 2>/dev/null && log "Desktop app started" || warn "Could not start desktop app"
    fi
  fi
}
