# platform/macos/install_docker.sh
# macOS-specific docker install: OrbStack (default) or Docker Desktop

install_docker_macos() {
  if docker_available; then
    log "Docker already available: $(docker --version)"
    return 0
  fi

  # Determine runtime
  local runtime="${DOCKER_RUNTIME:-}"
  if [[ -z "$runtime" ]]; then
    echo ""
    echo "Choose container runtime for macOS:"
    echo "  1) OrbStack (recommended, lightweight, macOS-native)"
    echo "  2) Docker Desktop (official, heavier)"
    read -rp "Enter 1 or 2 [1]: " choice
    case "${choice:-1}" in
      2) runtime="docker" ;;
      *) runtime="orbstack" ;;
    esac
  fi

  case "$runtime" in
    docker)
      log "Installing Docker Desktop..."
      brew install --cask docker
      open /Applications/Docker.app
      log "Waiting for Docker Desktop (60s)..."
      sleep 60
      ;;
    orbstack|*)
      log "Installing OrbStack..."
      brew install --cask orbstack
      open /Applications/OrbStack.app
      log "Waiting for OrbStack (30s)..."
      sleep 30
      ;;
  esac

  # Wait for docker to be ready
  for i in {1..30}; do
    if docker_available; then
      ok "Docker ready: $(docker --version)"
      return 0
    fi
    sleep 2
  done
  err "Docker did not become available. Check: docker info"
}
