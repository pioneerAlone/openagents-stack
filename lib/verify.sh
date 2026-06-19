# verify.sh - show status, verification helpers
# Source: `source lib/verify.sh`

show_status() {
  # Backend health (probe multiple endpoints because upstream changed health paths)
  # /v1/events is what launcher actually probes and gets 200 when healthy
  local backend_ok=false
  local matched_path=""
  for path in "/health" "/api/health" "/api/v1/health" "/healthz" "/v1/events" "/api/v1/events"; do
    if curl -sf --max-time 3 "http://localhost:${OPENAGENTS_BACKEND_PORT}${path}" >/dev/null 2>&1; then
      backend_ok=true
      matched_path="$path"
      break
    fi
  done
  if $backend_ok; then
    ok "Backend:    healthy on :$OPENAGENTS_BACKEND_PORT (via $matched_path)"
  else
    warn "Backend:   not responding on :$OPENAGENTS_BACKEND_PORT"
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
