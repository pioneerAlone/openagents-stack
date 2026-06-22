#!/usr/bin/env bash
# upgrade.sh - explicit upgrade (user-confirmed, idempotent, lock-protected)
# Source: `source lib/upgrade.sh`

# Lock file in OPENAGENTS_STACK_HOME (user-writable, not /tmp)
UPGRADE_LOCK="$OPENAGENTS_STACK_HOME/upgrade.lock"

# ── Acquire lock (prevent concurrent upgrades) ──
acquire_upgrade_lock() {
  if [[ -f "$UPGRADE_LOCK" ]]; then
    local pid
    pid=$(cat "$UPGRADE_LOCK" 2>/dev/null || echo "?")
    if kill -0 "$pid" 2>/dev/null; then
      err "Another upgrade is running (pid $pid). Aborting."
    else
      warn "Stale lock found (pid $pid no longer running). Removing."
      rm -f "$UPGRADE_LOCK"
    fi
  fi
  echo "$$" > "$UPGRADE_LOCK"
}

release_upgrade_lock() {
  rm -f "$UPGRADE_LOCK"
}

# ── Resolve the monorepo commit for a specific launcher tag ──
# This is more accurate than using develop HEAD.
resolve_commit_for_tag() {
  local tag="$1"
  # Try git ls-remote first (most reliable)
  local sha
  sha=$(git ls-remote "https://github.com/openagents-org/openagents.git" "refs/tags/${tag}^{}" 2>/dev/null \
        | awk '{print $1}' | head -1)
  if [[ -n "$sha" ]]; then
    echo "$sha"
    return 0
  fi
  # Fallback: try API (peeled commit object)
  sha=$(curl -sf "https://api.github.com/repos/openagents-org/openagents/git/refs/tags/${tag}" 2>/dev/null \
        | grep -oE '"sha":\s*"[a-f0-9]+"' | head -1 | sed 's/.*"sha":\s*"\([a-f0-9]*\)".*/\1/')
  if [[ -n "$sha" ]]; then
    echo "$sha"
    return 0
  fi
  # Last resort: use develop HEAD
  warn "Could not resolve exact commit for tag $tag, using develop HEAD"
  curl -sf "https://api.github.com/repos/openagents-org/openagents/commits/${OPENAGENTS_MONOREPO_BRANCH}" 2>/dev/null \
    | grep -oE '"sha":\s*"[a-f0-9]+"' | head -1 | sed 's/.*"sha":\s*"\([a-f0-9]*\)".*/\1/'
}

upgrade_to() {
  local target="${1:-}"

  # ── U1: Acquire lock (idempotency / race condition protection) ──
  acquire_upgrade_lock
  trap release_upgrade_lock EXIT

  echo "============================================"
  echo "  openagents-stack upgrade"
  echo "============================================"
  echo "  Pinned launcher: v$OPENAGENTS_LAUNCHER_VERSION"
  echo "  Pinned commit:   $OPENAGENTS_MONOREPO_COMMIT"
  echo "  Upstream latest: v$(get_latest_launcher_version)"
  echo ""

  if [[ -z "$target" ]]; then
    target=$(get_latest_launcher_version)
    if [[ -z "$target" ]]; then
      err "Could not fetch latest version. Use --to <version> explicitly."
    fi
    read -rp "Upgrade to v$target? (y/n): " ans
    [[ "$ans" == "y" ]] || { log "Cancelled"; return 0; }
  fi

  if [[ "$target" == "$OPENAGENTS_LAUNCHER_VERSION" ]]; then
    ok "Already at v$target. Nothing to do."
    return 0
  fi

  # ── U2: Backup + atomic write of versions.lock ──
  # Use a timestamped backup so repeated --upgrade doesn't accumulate
  # `versions.lock.bak` files in the repo.
  local bak="${LIB_DIR}/versions.lock.bak.$(date +%Y%m%dT%H%M%S)"
  log "Backing up versions.lock to $bak"
  cp "$LIB_DIR/versions.lock" "$bak"

  # ── U4: Resolve the EXACT commit corresponding to the tag (not develop HEAD) ──
  log "Resolving commit for tag $target..."
  local new_commit
  new_commit=$(resolve_commit_for_tag "$target")
  if [[ -z "$new_commit" ]]; then
    err "Could not resolve commit for tag $target. Aborting."
  fi
  log "  Resolved: ${new_commit:0:7}"

  # Atomic write: write to temp file, then move
  local tmp_lock="${LIB_DIR}/versions.lock.new"
  cat > "$tmp_lock" <<EOF
# OpenAgents Stack pinned versions
# Updated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")

OPENAGENTS_LAUNCHER_VERSION="$target"
OPENAGENTS_MONOREPO_COMMIT="$new_commit"
OPENAGENTS_MONOREPO_BRANCH="$OPENAGENTS_MONOREPO_BRANCH"
EOF
  mv "$tmp_lock" "$LIB_DIR/versions.lock"
  ok "Pinned to: launcher=v$target, commit=$new_commit"

  # Re-clone monorepo with new commit
  if [[ -d "$OPENAGENTS_HOME/.git" ]]; then
    log "Re-cloning monorepo with new commit..."
    rm -rf "$OPENAGENTS_HOME"
  fi

  # Match git_clone_monorepo: metadata-only + sparse, then fetch the
  # pinned commit on top. Keeps upgrade as cheap as first install.
  git clone --filter=blob:none --sparse --depth 1 \
    https://github.com/openagents-org/openagents.git "$OPENAGENTS_HOME"
  cd "$OPENAGENTS_HOME"
  git sparse-checkout set "${MONOREPO_SPARSE_PATHS[@]}"
  git fetch --depth 1000 origin "$new_commit" 2>/dev/null \
    || warn "Could not fetch $new_commit, using branch HEAD"
  git checkout "$new_commit" 2>/dev/null || warn "Could not checkout $new_commit, using branch HEAD"
  # Pin a local branch name so subsequent `git status` etc. don't sit
  # in detached HEAD. Branch name = OPENAGENTS_MONOREPO_BRANCH.
  git checkout -B "$OPENAGENTS_MONOREPO_BRANCH" "$new_commit" 2>/dev/null || true

  # Restart backend
  log "Restarting backend..."
  cd "$OPENAGENTS_HOME/workspace"
  docker compose -p "${COMPOSE_PROJECT}" down 2>/dev/null || true
  docker compose -p "${COMPOSE_PROJECT}" up -d db backend

  # Wait for health
  for i in {1..30}; do
    # Use the same probe helper lib/backend.sh exposes to --check,
    # so upgrade doesn't drift from the project's known-good endpoints.
    if probe_backend_health; then
      ok "Backend healthy after upgrade (via ${BACKEND_HEALTH_MATCHED})"
      docker compose -p "${COMPOSE_PROJECT}" exec -T backend alembic upgrade head
      return 0
    fi
    sleep 2
  done
  err "Backend did not come up after upgrade. Check: docker logs openagents-backend"
}
