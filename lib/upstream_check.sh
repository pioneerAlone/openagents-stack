# upstream_check.sh - check upstream versions, warn (don't auto-upgrade)
# Source: `source lib/upstream_check.sh`

# ── Get latest launcher tag from GitHub ──
# Returns the raw tag_name string (e.g. "launcher-v0.8.6") or empty string.
get_latest_launcher_tag() {
  local response
  response=$(curl -sf "https://api.github.com/repos/openagents-org/openagents/releases/latest" 2>/dev/null)
  if [[ -z "$response" ]]; then
    echo ""
    return
  fi
  # Use python3 for reliable JSON parsing (avoids grep regex bugs)
  echo "$response" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('tag_name', ''))
except Exception:
    pass
" 2>/dev/null
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
