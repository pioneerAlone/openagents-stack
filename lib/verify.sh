#!/usr/bin/env bash
# verify.sh - show status, verification helpers
# Source: `source lib/verify.sh`

show_status() {
  # Backend health (probe + endpoint list come from lib/backend.sh, shared
  # with --check and --upgrade so all three stay in sync)
  if probe_backend_health; then
    ok "Backend:    healthy on :$OPENAGENTS_BACKEND_PORT (via ${BACKEND_HEALTH_MATCHED})"
  else
    warn "Backend:   not responding on :$OPENAGENTS_BACKEND_PORT"
  fi

  # Docker containers — filter by the project label so we only show
  # our own stack's containers (was 'name=openagents' which silently
  # missed them once we renamed the compose project to oa-stack).
  if docker_available; then
    local containers
    containers=$(docker ps --filter "label=com.docker.compose.project=${COMPOSE_PROJECT}" --format "{{.Names}}\t{{.Status}}" 2>/dev/null)
    if [[ -n "$containers" ]]; then
      log "Containers:"
      echo "$containers" | while IFS=$'\t' read -r name status; do
        log "  $name: $status"
      done
    else
      warn "No ${COMPOSE_PROJECT} containers running"
    fi
  fi

  # Launcher
  if command -v agn >/dev/null 2>&1; then
    log "Launcher:   $(agn --version 2>/dev/null | head -1)"
    # Same row-count strategy as lib/selfcheck.sh check_agents: launcher
    # v0.2+ uses arbitrary agent names (claude-1, hermes-worker, ...),
    # so a name regex would silently misreport. awk counts data rows
    # after the 2-line table header.
    local agents
    agents=$(agn list 2>/dev/null | awk 'NR>2 && NF>=2 {n++} END {print n+0}')
    if [[ "${agents:-0}" -gt 0 ]]; then
      log "Agents:     $agents configured"
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
