#!/usr/bin/env bash
# selfcheck.sh - detect existing components, output report
# Source: `source lib/selfcheck.sh`
# Called by: --check command, and at start of each step

# ── Result accumulator ──
declare -a CHECK_RESULTS=()

record() {
  CHECK_RESULTS+=("$1")
}

# ── Individual checks ──
check_docker() {
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    local ver runtime_name
    ver=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')

    # Identify runtime: OrbStack, Docker Desktop, colima, or other
    runtime_name="unknown"
    if docker context show 2>/dev/null | grep -q "orbstack"; then
      runtime_name="OrbStack"
    elif [[ -d "/Applications/Docker.app" ]] && [[ ! -d "/Applications/OrbStack.app" ]]; then
      runtime_name="Docker Desktop"
    elif docker info 2>/dev/null | grep -qi "colima"; then
      runtime_name="colima"
    elif docker info 2>/dev/null | grep -qi "rancher"; then
      runtime_name="Rancher Desktop"
    else
      # Fallback: check which app is installed
      if [[ -d "/Applications/OrbStack.app" ]]; then
        runtime_name="OrbStack"
      elif [[ -d "/Applications/Docker.app" ]]; then
        runtime_name="Docker Desktop"
      fi
    fi

    record "PASS|docker|$ver ($runtime_name)"
  else
    record "FAIL|docker|not installed"
  fi
}

check_docker_compose() {
  if docker compose version >/dev/null 2>&1; then
    local ver
    ver=$(docker compose version 2>/dev/null | awk '{print $4}')
    record "PASS|docker compose|$ver"
  else
    record "FAIL|docker compose|not available"
  fi
}

check_launcher_cli() {
  if command -v agn >/dev/null 2>&1; then
    local ver
    ver=$(agn --version 2>/dev/null | head -1)
    record "PASS|launcher cli|$ver"

    # A1: Compare the actually installed version against the pinned
    # tag in versions.lock. The pinned tag (e.g. launcher-v0.8.6) and
    # the actual CLI version (e.g. v0.2.143) are produced by different
    # teams and have drifted historically — a mismatch is a strong
    # signal that the running setup was built against a different
    # upstream than this stack expects.
    if [[ -n "${OPENAGENTS_LAUNCHER_TAG:-}" ]]; then
      local actual pinned
      actual=$(echo "$ver" | grep -oE 'v?[0-9]+\.[0-9]+\.[0-9]+' | head -1 | sed 's/^v//')
      pinned="${OPENAGENTS_LAUNCHER_TAG#launcher-}"
      pinned="${pinned#v}"
      if [[ -n "$actual" && -n "$pinned" && "$actual" != "$pinned" ]]; then
        record "WARN|launcher cli|installed v$actual != pinned v$pinned (run --upgrade or check versions.lock)"
      fi
    fi
  else
    record "FAIL|launcher cli|agn not in PATH"
  fi
}

check_launcher_app() {
  if [[ "$PLATFORM" == "macos" ]]; then
    if [[ -d "/Applications/OpenAgents Launcher.app" ]]; then
      record "PASS|launcher app|installed"
    else
      record "FAIL|launcher app|not installed (CLI will be useless without app)"
    fi
  else
    record "SKIP|launcher app|non-macos"
  fi
}

check_monorepo() {
  if [[ -d "$OPENAGENTS_HOME/.git" ]]; then
    local commit
    commit=$(git -C "$OPENAGENTS_HOME" rev-parse --short HEAD 2>/dev/null)
    if [[ "$commit" == "${OPENAGENTS_MONOREPO_COMMIT:0:7}" ]]; then
      record "PASS|monorepo|at pinned commit $commit"
    else
      record "WARN|monorepo|at $commit, expected ${OPENAGENTS_MONOREPO_COMMIT:0:7}"
    fi
  else
    record "FAIL|monorepo|not cloned at $OPENAGENTS_HOME"
  fi
}

check_backend_container() {
  if docker ps --filter "name=openagents-backend" --format "{{.Names}}" 2>/dev/null | grep -q openagents-backend; then
    record "PASS|backend container|running"
  else
    record "FAIL|backend container|not running"
  fi
}

check_db_container() {
  if docker ps --filter "name=openagents-db" --format "{{.Names}}" 2>/dev/null | grep -q openagents-db; then
    record "PASS|db container|running"
  else
    record "FAIL|db container|not running"
  fi
}

check_backend_health() {
  # Probe multiple endpoints because upstream has changed health paths
  # across releases (/api/health, /api/v1/health, /healthz, /health)
  # /v1/events is what launcher actually probes and gets 200 when healthy
  for path in "/api/health" "/api/v1/health" "/healthz" "/health" "/v1/events" "/api/v1/events"; do
    if curl -sf --max-time 3 "http://localhost:${OPENAGENTS_BACKEND_PORT}${path}" >/dev/null 2>&1; then
      record "PASS|backend health|200 OK (${path})"
      return
    fi
  done
  record "FAIL|backend health|not responding on :$OPENAGENTS_BACKEND_PORT (tried: /api/health, /api/v1/health, /healthz, /health, /v1/events, /api/v1/events)"
}

check_port_8000() {
  if lsof -iTCP:"$OPENAGENTS_BACKEND_PORT" -sTCP:LISTEN 2>/dev/null | grep -q LISTEN; then
    record "INFO|port $OPENAGENTS_BACKEND_PORT|in use (likely our backend)"
  else
    record "INFO|port $OPENAGENTS_BACKEND_PORT|free"
  fi
}

check_workspace() {
  if command -v agn >/dev/null 2>&1; then
    # launcher v0.2+ uses hash slugs (e.g. e26b9e15), not human-readable names.
    # Count data rows: skip the 2-line table header (NAME/TYPE/... + separator).
    local count
    count=$(agn workspace list 2>/dev/null | awk 'NR>2 && NF>=2 {n++} END {print n+0}')
    if [[ "$count" -gt 0 ]]; then
      record "PASS|workspace|$count found"
    else
      record "WARN|workspace|none found"
    fi
  else
    record "SKIP|workspace|agn not available"
  fi
}

check_agents() {
  if command -v agn >/dev/null 2>&1; then
    # Same approach: count data rows. launcher agent names vary widely
    # (claude-1, hermes-worker, my-foo, ...), so we don't regex on names.
    local count
    count=$(agn list 2>/dev/null | awk 'NR>2 && NF>=2 {n++} END {print n+0}')
    if [[ "$count" -gt 0 ]]; then
      record "PASS|agents|$count configured"
    else
      record "WARN|agents|none configured"
    fi
  else
    record "SKIP|agents|agn not available"
  fi
}

# ── Run all checks, output table ──
run_all_checks() {
  CHECK_RESULTS=()
  check_docker
  check_docker_compose
  check_launcher_cli
  check_launcher_app
  check_monorepo
  check_backend_container
  check_db_container
  check_backend_health
  check_port_8000
  check_workspace
  check_agents

  echo "┌──────────────────────────────────────────────────────────────┐"
  echo "│  openagents-stack preflight                                  │"
  echo "│  Platform: $PLATFORM"
  echo "│  Monorepo: $OPENAGENTS_HOME"
  echo "│  Pinned:   launcher=$OPENAGENTS_LAUNCHER_TAG commit=${OPENAGENTS_MONOREPO_COMMIT:0:7}"
  echo "├──────────────────────────────────────────────────────────────┤"
  for r in "${CHECK_RESULTS[@]}"; do
    IFS='|' read -r status name msg <<< "$r"
    case "$status" in
      PASS) icon="✓"; color="\033[32m" ;;
      FAIL) icon="✗"; color="\033[31m" ;;
      WARN) icon="!"; color="\033[33m" ;;
      SKIP) icon="-"; color="\033[90m" ;;
      INFO) icon="i"; color="\033[36m" ;;
      *)    icon="?"; color="\033[0m" ;;
    esac
    printf "│  %b%s%b  %-18s %s\n" "$color" "$icon" "\033[0m" "$name" "$msg"
  done
  echo "├──────────────────────────────────────────────────────────────┤"

  # Suggest action based on which check failed
  local has_fail=false
  local backend_down=false
  for r in "${CHECK_RESULTS[@]}"; do
    if [[ "$r" == FAIL* ]]; then
      has_fail=true
      # If backend-related checks failed, suggest --start instead
      if [[ "$r" == FAIL*backend* ]] || [[ "$r" == FAIL*db* ]] || [[ "$r" == FAIL*health* ]] || [[ "$r" == FAIL*monorepo* ]]; then
        backend_down=true
      fi
    fi
  done
  if $backend_down; then
    echo "│  → Run: openagents-stack --start                            │"
  elif $has_fail; then
    echo "│  → Run: openagents-stack (to install dependencies)           │"
  else
    echo "│  → All required components present                           │"
    echo "│  → Start backend with: openagents-stack --start             │"
  fi
  echo "└──────────────────────────────────────────────────────────────┘"
}
