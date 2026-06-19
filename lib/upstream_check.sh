# upstream_check.sh - check upstream versions, warn (don't auto-upgrade)
# Source: `source lib/upstream_check.sh`

# ── Get latest launcher tag from GitHub ──
get_latest_launcher_tag() {
  curl -sf "https://api.github.com/repos/openagents-org/openagents/releases/latest" 2>/dev/null \
    | grep -oE '"tag_name":\s*"[^"]+"' \
    | head -1 \
    | sed 's/.*"tag_name":\s*"\([^"]*\)".*/\1/' || echo ""
}

# ── Check upstream and warn (idempotent, called at startup) ──
check_upstream() {
  local latest
  latest=$(get_latest_launcher_tag)
  if [[ -z "$latest" ]]; then
    warn "Could not reach GitHub API for version check"
    return 0
  fi
  if [[ "$latest" != "$OPENAGENTS_LAUNCHER_TAG" ]]; then
    warn "Upstream has newer launcher: $latest (pinned: $OPENAGENTS_LAUNCHER_TAG)"
    warn "To upgrade: openagents-stack --upgrade"
  else
    ok "Upstream matches pinned version: $OPENAGENTS_LAUNCHER_TAG"
  fi
}
