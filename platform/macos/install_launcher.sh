#!/usr/bin/env bash
# platform/macos/install_launcher.sh
# macOS-specific launcher install: discover + download from GitHub releases

install_launcher_macos() {
  # Discover latest version's macOS asset (we're called from step_install_launcher
  # which has already set OPENAGENTS_LAUNCHER_TAG via versions.lock).
  local tag="${OPENAGENTS_LAUNCHER_TAG}"
  # tag is e.g. "launcher-v0.8.6" — display without the "launcher-" prefix
  local display_tag="${tag#launcher-}"
  log "Fetching ${display_tag} macOS asset from GitHub..."

  # Detect arch
  local arch
  arch="$(uname -m)"
  case "$arch" in
    arm64|aarch64) arch="arm64" ;;
    x86_64)        arch="x64"   ;;
    *) err "Unknown arch: $arch" ;;
  esac

  # Get asset URL via GitHub API (don't hardcode .pkg — current releases use .dmg)
  local asset_url
  asset_url=$(curl -sf "https://api.github.com/repos/openagents-org/openagents/releases/tags/${tag}" 2>/dev/null \
    | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    for a in d.get('assets', []):
        if a['name'].endswith(f'-mac-${arch}.dmg'):
            print(a['browser_download_url'])
            break
except Exception:
    pass
" 2>/dev/null)
  if [[ -z "$asset_url" ]]; then
    err "No macOS .dmg asset found for ${tag} (arch=${arch}). Check: https://github.com/openagents-org/openagents/releases/tag/${tag}"
  fi

  # Download to OPENAGENTS_STACK_HOME/cache/ (user-writable, not /tmp)
  local cache_dir="$OPENAGENTS_STACK_HOME/cache"
  mkdir -p "$cache_dir"
  local filename
  filename="$cache_dir/$(basename "$asset_url")"
  log "Downloading to $filename"

  # Try multiple mirrors in case of network issues
  local download_ok=false
  local mirrors=(
    "$asset_url"
    "${asset_url/https:\/\/github.com\/openagents-org\/openagents\/releases\/download/https:\/\/objects.githubusercontent.com\/github-production-release-asset-2e65be\/1234567890\/}"
  )
  for mirror in "${mirrors[@]}"; do
    log "  Trying: $(echo "$mirror" | sed 's|.*/||')"
    if curl -L -o "$filename" -sf --max-time 300 --connect-timeout 30 "$mirror" 2>&1 | tail -3; then
      if [[ -s "$filename" ]] && [[ $(stat -f%z "$filename" 2>/dev/null || stat -c%s "$filename" 2>/dev/null) -gt 1000000 ]]; then
        ok "Downloaded from mirror: $filename ($(du -h "$filename" | awk '{print $1}'))"
        download_ok=true
        break
      fi
    fi
    warn "Mirror failed, trying next..."
    rm -f "$filename"
  done

  if ! $download_ok; then
    err "All mirrors failed. Tried:
  - $asset_url
  - GitHub objects CDN (auto-transform)

Possible fixes:
  1. Check VPN / proxy: github.com or objects.githubusercontent.com blocked?
  2. Try a different network
  3. Manual download: open https://github.com/openagents-org/openagents/releases/tag/launcher-v0.8.6 in a browser
  4. Use a mirror: https://mirror.ghproxy.com/
"
  fi

  # Install .dmg: mount → copy .app → unmount
  log "Mounting .dmg (will prompt for password)..."
  local mountpoint
  mountpoint=$(hdiutil attach -nobrowse "$filename" 2>/dev/null | awk '/\/Volumes/{print $3}' | head -1)
  if [[ -z "$mountpoint" ]]; then
    err "Failed to mount .dmg. Try opening manually: open $filename"
  fi
  ok "Mounted at: $mountpoint"

  # Find .app inside mountpoint
  local app_path
  app_path=$(find "$mountpoint" -maxdepth 3 -name "OpenAgents Launcher.app" -type d | head -1)
  if [[ -z "$app_path" ]]; then
    hdiutil detach "$mountpoint" 2>/dev/null || true
    err "OpenAgents Launcher.app not found in .dmg"
  fi

  # Copy to /Applications
  log "Installing to /Applications (sudo)..."
  sudo rm -rf "/Applications/OpenAgents Launcher.app" 2>/dev/null || true
  sudo cp -R "$app_path" "/Applications/OpenAgents Launcher.app" || {
    hdiutil detach "$mountpoint" 2>/dev/null || true
    err "Failed to copy to /Applications"
  }
  sudo xattr -dr com.apple.quarantine "/Applications/OpenAgents Launcher.app" 2>/dev/null || true
  hdiutil detach "$mountpoint" 2>/dev/null || true
  ok "Installed: /Applications/OpenAgents Launcher.app"

  # Add to PATH if not already (agn is in .app's Resources)
  if ! command -v agn >/dev/null 2>&1; then
    if [[ -f "$HOME/.zshrc" ]] && ! grep -q "openagents/nodejs/node_modules/.bin" "$HOME/.zshrc"; then
      echo "export PATH=\"\$HOME/.openagents/nodejs/node_modules/.bin:\$PATH\"" >> "$HOME/.zshrc"
      log "Added agn to PATH in ~/.zshrc"
    fi
    export PATH="$HOME/.openagents/nodejs/node_modules/.bin:$PATH"
  fi
}
