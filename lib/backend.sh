#!/usr/bin/env bash
# backend.sh - clone monorepo + start docker backend
# Source: `source lib/backend.sh`

# Helper: find the real backend container name (handles project prefix)
get_backend_container() {
  # docker compose names containers as ${project}-${service}-${index}
  # -p openagents → project prefix is "openagents"
  # Service is "backend" → real name is "openagents-backend-1"
  docker ps -a --filter "label=com.docker.compose.project=openagents" --filter "label=com.docker.compose.service=backend" --format "{{.Names}}" 2>/dev/null | head -1
}

# Probe backend health across known endpoint shapes
# Returns 0 if any endpoint responds 2xx/3xx, 1 otherwise
probe_backend_health() {
  for path in "/health" "/api/health" "/api/v1/health" "/healthz" "/v1/events" "/api/v1/events"; do
    if curl -sf --max-time 3 "http://localhost:${OPENAGENTS_BACKEND_PORT}${path}" >/dev/null 2>&1; then
      return 0
    fi
  done
  return 1
}

# Helper: check if backend is currently running and healthy
# Note: we probe multiple endpoints because upstream's health endpoint
# has changed across releases (e.g. /api/health, /api/v1/health, /healthz)
backend_already_running() {
  local container
  container=$(get_backend_container)
  if [[ -z "$container" ]]; then
    return 1
  fi
  # Check if running
  local state
  state=$(docker inspect --format '{{.State.Running}}' "$container" 2>/dev/null)
  if [[ "$state" != "true" ]]; then
    return 1
  fi
  probe_backend_health
}

step_start_backend() {
  log "[3/5] Start backend (clone + docker compose up + migrations)"

  # ── 0. Check if already running (actual state, not state file) ──
  if backend_already_running; then
    local container
    container=$(get_backend_container)
    ok "Backend already running and healthy (container: $container)"
    done_step step_start_backend
    return 0
  fi

  # If container exists but unhealthy, ask user
  local existing_container
  existing_container=$(get_backend_container)
  if [[ -n "$existing_container" ]]; then
    warn "Found existing container $existing_container (not healthy)"
    read -rp "  Restart? (y/n) [n]: " ans
    ans="${ans:-n}"
    if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
      log "  Stopping existing container..."
      cd "$OPENAGENTS_HOME/workspace"
      docker compose -p openagents down 2>/dev/null || true
      cd - >/dev/null
    else
      log "  Leaving existing container. Will not start new one."
      return 1
    fi
  fi

  # 3a. Clone or update monorepo
  if [[ -d "$OPENAGENTS_HOME/.git" ]]; then
    local current_commit
    current_commit=$(git -C "$OPENAGENTS_HOME" rev-parse --short HEAD 2>/dev/null || echo "")
    if [[ "$current_commit" == "${OPENAGENTS_MONOREPO_COMMIT:0:7}" ]]; then
      ok "Monorepo already at pinned commit ($current_commit)"
    else
      log "  Re-cloning monorepo (current: $current_commit, pinned: ${OPENAGENTS_MONOREPO_COMMIT:0:7})..."
      rm -rf "$OPENAGENTS_HOME"
      git_clone_monorepo
    fi
  else
    git_clone_monorepo
  fi

  # 3b. Start docker
  cd "$OPENAGENTS_HOME/workspace"
  log "  Starting docker compose (db + backend)..."
  docker compose -p openagents up -d db backend

  # 3c. Wait for health
  log "  Waiting for backend health (max 60s)..."
  for i in {1..30}; do
    if probe_backend_health; then
      ok "Backend healthy on port $OPENAGENTS_BACKEND_PORT"
      break
    fi
    sleep 2
  done

  if ! probe_backend_health; then
    # Get the REAL container name (handles project prefix)
    local real_container
    real_container=$(get_backend_container)
    log "Backend failed. Container: ${real_container:-not found}"
    if [[ -n "$real_container" ]]; then
      log "Last 20 lines of $real_container:"
      docker logs "$real_container" --tail 20 2>&1 | sed 's/^/  /' | tee -a "$LOG_FILE" >&2
    fi
    err "Backend did not come up on :$OPENAGENTS_BACKEND_PORT after 60s

Debug steps:
  cd $OPENAGENTS_HOME/workspace
  docker compose -p openagents ps
  docker compose -p openagents logs backend
  cat $OPENAGENTS_HOME/workspace/.env 2>/dev/null || echo 'no .env'"
  fi

  # 3d. Run migrations
  log "  Running alembic migrations..."
  docker compose -p openagents exec -T backend alembic upgrade head

  done_step step_start_backend
  ok "Backend ready"
}

git_clone_monorepo() {
  log "  Cloning openagents monorepo to $OPENAGENTS_HOME (commit ${OPENAGENTS_MONOREPO_COMMIT:0:7})..."
  # --depth 1000: 2+ years of develop history at typical commit rates.
  # Bump this if you ever pin a much older commit; the previous --depth 50
  # only covered ~7 days and broke within a week of pinning.
  git clone --branch "$OPENAGENTS_MONOREPO_BRANCH" --depth 1000 \
    https://github.com/openagents-org/openagents.git "$OPENAGENTS_HOME"
  cd "$OPENAGENTS_HOME"
  git checkout "$OPENAGENTS_MONOREPO_COMMIT" 2>/dev/null || {
    err "Could not checkout pinned commit $OPENAGENTS_MONOREPO_COMMIT"
  }
  ok "  Cloned at commit $(git rev-parse --short HEAD)"
}

step_stop_backend() {
  log "Stopping backend..."
  local prev_dir
  prev_dir=$(pwd)
  if [[ -d "$OPENAGENTS_HOME/workspace" ]]; then
    cd "$OPENAGENTS_HOME/workspace"
    docker compose -p openagents stop 2>/dev/null || true
    cd "$prev_dir"
  else
    warn "Monorepo not cloned at $OPENAGENTS_HOME/workspace; nothing to stop"
  fi
  ok "Backend stopped"
}

step_clean_backend() {
  log "Cleaning backend (down + delete volumes)..."
  local prev_dir
  prev_dir=$(pwd)
  if [[ -d "$OPENAGENTS_HOME/workspace" ]]; then
    cd "$OPENAGENTS_HOME/workspace"
    docker compose -p openagents down -v 2>/dev/null || true
    cd "$prev_dir"
  else
    warn "Monorepo not cloned; attempting docker compose down anyway"
    docker compose -p openagents down -v 2>/dev/null || true
  fi
  ok "Backend cleaned (volumes deleted)"
}
