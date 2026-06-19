# verify.sh - show status, verification helpers
# Source: `source lib/verify.sh`

show_status() {
  # Backend health
  if curl -sf "http://localhost:$OPENAGENTS_BACKEND_PORT/api/health" >/dev/null 2>&1; then
    ok "Backend:    healthy on :$OPENAGENTS_BACKEND_PORT"
  else
    warn "Backend:   not responding"
  fi

  # Docker containers
  if docker_available; then
    local containers
    containers=$(docker ps --filter "name=openagents" --format "{{.Names}}\t{{.Status}}" 2>/dev/null)
    if [[ -n "$containers" ]]; then
      log "Containers:"
      echo "$containers" | while IFS=$'\t' read -r name status; do
        log "  $name: $status"
      done
    else
      warn "No openagents containers running"
    fi
  fi

  # Launcher
  if command -v agn >/dev/null 2>&1; then
    log "Launcher:   $(agn --version 2>/dev/null | head -1)"
    local agents
    agents=$(agn list 2>/dev/null | grep -E "^\s*my-" || true)
    if [[ -n "$agents" ]]; then
      log "Agents:"
      echo "$agents" | while read -r line; do
        log "  $line"
      done
    fi
  else
    warn "Launcher not installed"
  fi

  # Upstream check
  echo ""
  check_upstream
}

# step_check_prereq moved to lib/checks.sh (SRP: checks vs verify)
# check_monorepo_health moved to lib/checks.sh
