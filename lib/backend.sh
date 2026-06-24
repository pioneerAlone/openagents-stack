#!/usr/bin/env bash
# backend.sh - clone monorepo + start docker backend
# Source: `source lib/backend.sh`

# Compose project name used for every `docker compose` invocation in the
# stack. -p is namespaced as "oa-stack" rather than "openagents" to avoid
# collision with the monorepo's root docker-compose.yml (which the stack
# does not use, but users may pull up by hand and would otherwise land
# containers in the same project label as ours).
COMPOSE_PROJECT="oa-stack"
# Export so child scripts (cmd_logs in bin/openagents-stack) and any user
# shell that sources backend.sh can read the same name.
export COMPOSE_PROJECT

# Sub-paths we need from the monorepo. Used by `git_clone_monorepo` to
# sparse-checkout: 162 MB → ~8 MB. Anything else in the monorepo
# (packages/agent-connector, packages/go, sdk/, tests/, docs/, …) is
# not needed by the stack and stays on the remote.
MONOREPO_SPARSE_PATHS=(
  "workspace"
  "packages/launcher"
)

# Helper: find the real backend container name (handles project prefix)
get_backend_container() {
  # docker compose names containers as ${project}-${service}-${index}
  # -p oa-stack → project prefix is "oa-stack"
  # Service is "backend" → real name is "oa-stack-backend-1"
  docker ps -a --filter "label=com.docker.compose.project=${COMPOSE_PROJECT}" --filter "label=com.docker.compose.service=backend" --format "{{.Names}}" 2>/dev/null | head -1
}

# Helper: find the real db container name
get_db_container() {
  docker ps -a --filter "label=com.docker.compose.project=${COMPOSE_PROJECT}" --filter "label=com.docker.compose.service=db" --format "{{.Names}}" 2>/dev/null | head -1
}

# ── Backend health probing ──
# Upstream's health endpoint has changed shape across releases
# (/health → /api/health → /api/v1/health → /healthz), and /v1/events
# is what the openagents launcher actually probes and gets 200 from when
# the backend is healthy. Try each path in order; first match wins.
#
# If you ever add a new endpoint, append to this array only — probe_backend_health
# and check_backend_health both consume it, so the change picks up everywhere.
BACKEND_HEALTH_ENDPOINTS=(
  "/health"
  "/api/health"
  "/api/v1/health"
  "/healthz"
  "/v1/events"
  "/api/v1/events"
)

# Probe backend health across known endpoint shapes.
# Returns 0 if any endpoint responds 2xx/3xx, 1 otherwise.
# On success, sets BACKEND_HEALTH_MATCHED to the path that worked (callers
# that want to show "healthy via /v1/events" use this).
probe_backend_health() {
  for path in "${BACKEND_HEALTH_ENDPOINTS[@]}"; do
    if curl -sf --max-time 3 "http://localhost:${OPENAGENTS_BACKEND_PORT}${path}" >/dev/null 2>&1; then
      BACKEND_HEALTH_MATCHED="$path"
      return 0
    fi
  done
  BACKEND_HEALTH_MATCHED=""
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

  # ── 0.5. Migration warning: detect containers from an older stack
  # version (compose project "openagents" instead of current "oa-stack")
  # and tell the user how to clean up. v0.1.0-beta1 and earlier used
  # the bare project name; this release renames it to oa-stack.
  local legacy_container
  legacy_container=$(docker ps -a --filter "label=com.docker.compose.project=openagents" --filter "label=com.docker.compose.service=backend" --format "{{.Names}}" 2>/dev/null | head -1 || true)
  if [[ -n "$legacy_container" ]]; then
    warn "Found legacy backend container '$legacy_container' from an older openagents-stack version (pre-0.1.0)."
    warn "  It's now using compose project 'openagents'; this version uses 'oa-stack' to avoid conflicts."
    warn "  The legacy container is NOT touched by --start/--stop/--clean."
    warn "  To remove it:  docker rm -f $legacy_container"
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
      (cd "$OPENAGENTS_HOME/workspace" && \
        docker compose -p "${COMPOSE_PROJECT}" down 2>/dev/null) || true
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
  log "  Starting docker compose (db + backend)..."
  (cd "$OPENAGENTS_HOME/workspace" && \
    docker compose -p "${COMPOSE_PROJECT}" up -d db backend)

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
  docker compose -p ${COMPOSE_PROJECT} ps
  docker compose -p ${COMPOSE_PROJECT} logs backend
  cat $OPENAGENTS_HOME/workspace/.env 2>/dev/null || echo 'no .env'"
  fi

  # 3d. Run migrations
  log "  Running alembic migrations..."
  (cd "$OPENAGENTS_HOME/workspace" && \
    docker compose -p "${COMPOSE_PROJECT}" exec -T backend alembic upgrade head)

  done_step step_start_backend
  ok "Backend ready"
}

git_clone_monorepo() {
  log "  Cloning openagents monorepo to $OPENAGENTS_HOME (commit ${OPENAGENTS_MONOREPO_COMMIT:0:7})..."

  # Two-phase clone to minimize what we download.
  #   1. metadata-only clone (--filter=blob:none, --depth 1) — fast, ~600 KB
  #   2. sparse-checkout to the sub-paths we actually need (~8 MB instead of 162 MB)
  # Then we fetch enough history to reach the pinned commit and check it out.
  #
  # The pinned-commit check is the only reason we need any history; if the
  # commit is older than --depth we'd need to deepen, but in practice the
  # stack re-pins versions.lock on every --upgrade and users only stay
  # a few weeks behind, so depth 1000 is more than enough.
  git clone --filter=blob:none --sparse --depth 1 \
    https://github.com/openagents-org/openagents.git "$OPENAGENTS_HOME"
  cd "$OPENAGENTS_HOME"
  git sparse-checkout set "${MONOREPO_SPARSE_PATHS[@]}"

  log "  Fetching pinned commit ${OPENAGENTS_MONOREPO_COMMIT:0:7}..."
  git fetch --depth 1000 origin "$OPENAGENTS_MONOREPO_COMMIT" 2>/dev/null \
    || err "Could not fetch pinned commit $OPENAGENTS_MONOREPO_COMMIT"

  git checkout "$OPENAGENTS_MONOREPO_COMMIT" 2>/dev/null \
    || err "Could not checkout pinned commit $OPENAGENTS_MONOREPO_COMMIT"
  # Pin a local branch so `git status` etc. don't sit in detached HEAD.
  git checkout -B "$OPENAGENTS_MONOREPO_BRANCH" "$OPENAGENTS_MONOREPO_COMMIT" 2>/dev/null || true
  ok "  Cloned at commit $(git rev-parse --short HEAD)"
}

step_stop_backend() {
  log "Stopping backend..."
  if [[ -d "$OPENAGENTS_HOME/workspace" ]]; then
    (cd "$OPENAGENTS_HOME/workspace" && \
      docker compose -p "${COMPOSE_PROJECT}" stop 2>/dev/null) || true
  else
    warn "Monorepo not cloned at $OPENAGENTS_HOME/workspace; nothing to stop"
  fi
  ok "Backend stopped"
}

step_clean_backend() {
  log "Cleaning backend (down + delete volumes)..."
  if [[ -d "$OPENAGENTS_HOME/workspace" ]]; then
    (cd "$OPENAGENTS_HOME/workspace" && \
      docker compose -p "${COMPOSE_PROJECT}" down -v 2>/dev/null) || true
  else
    warn "Monorepo not cloned; attempting docker compose down anyway"
    docker compose -p "${COMPOSE_PROJECT}" down -v 2>/dev/null || true
  fi
  ok "Backend cleaned (volumes deleted)"
}

# ── List workspaces from backend (slug + name + token + connection info) ──
# Calls the backend's GET /v1/workspaces (auth-free) to get the list, then
# queries the Postgres container directly to fetch the password_hash /
# "token" for each one — the backend API deliberately doesn't return
# the token in list responses, only after a POST create. This command
# is what the user runs to get the connection info they need to paste
# into the Launcher.
list_workspaces() {
  # Backend must be up
  if ! probe_backend_health; then
    err "Backend is not running on :$OPENAGENTS_BACKEND_PORT. Run: openagents-stack --start"
  fi

  # 1. Fetch the workspace list (no auth required)
  local list_json
  list_json=$(curl -sf "http://localhost:${OPENAGENTS_BACKEND_PORT}/v1/workspaces" 2>/dev/null) \
    || err "GET /v1/workspaces failed (backend up but API call rejected)"

  # Parse out: slug, name, workspaceId for each. We use python3 for
  # reliable JSON parsing (avoid regex bugs that bit us in C1).
  local parsed
  parsed=$(echo "$list_json" | python3 -c "
import sys, json
d = json.load(sys.stdin)
for w in d.get('data', []):
    print(f\"{w.get('slug','')}\t{w.get('name','')}\t{w.get('workspaceId','')}\")
" 2>/dev/null)

  if [[ -z "$parsed" ]]; then
    warn "No workspaces found on backend (response: $(echo "$list_json" | head -c 200))"
    return 0
  fi

  # 2. Find the running db container + query tokens
  local db_container
  db_container=$(get_db_container)
  if [[ -z "$db_container" ]]; then
    err "Could not find the db container (label=${COMPOSE_PROJECT}, service=db) — is the backend running?"
  fi

  # Pull all (slug, token) pairs in one SQL call
  local token_rows
  token_rows=$(docker exec "$db_container" psql -U postgres -d openagents_workspace -tA \
    -c "SELECT slug || E'\t' || password_hash FROM workspaces WHERE status != 'deleted' AND password_hash IS NOT NULL;" \
    2>/dev/null) || err "psql into $db_container failed — is the db running?"

  # 3. Merge and print
  local endpoint="http://localhost:${OPENAGENTS_BACKEND_PORT}"
  echo ""
  echo "Workspaces registered with the backend ($(echo "$parsed" | wc -l | tr -d ' ') found):"
  echo ""

  while IFS=$'\t' read -r slug name wsid; do
    [[ -z "$slug" ]] && continue
    local token
    token=$(echo "$token_rows" | awk -F'\t' -v s="$slug" '$1==s {print $2}')
    if [[ -z "$token" ]]; then
      warn "$slug: token not found in db (workspace may be in a partial state)"
      continue
    fi
    cat <<EOF
  ┌─ workspace ──────────────────────────────────────────
  │  slug:     $slug
  │  name:     $name
  │  id:       $wsid
  │  endpoint: $endpoint
  │  token:    $token
  │
  │  → Quick-connect URL (paste into Launcher's "快速连接" dialog):
  │      ${endpoint}/${slug}?token=${token}
  │
  │  → agn CLI (paste the export, then run connect):
  │      export OPENAGENTS_ENDPOINT=$endpoint
  │      agn workspace connect "$slug" "$token"
  └─────────────────────────────────────────────────────
EOF
  done <<< "$parsed"

  echo ""
  log "Tip: --status also shows workspace count; this command gives you the token + connect command."
}
