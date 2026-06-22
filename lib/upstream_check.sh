#!/usr/bin/env bash
# upstream_check.sh - check upstream versions, warn (don't auto-upgrade)
# Source: `source lib/upstream_check.sh`

# ── Get latest launcher version from npm registry ──
# The launcher is published to npm as @openagents-org/agent-launcher;
# npm's `dist-tags.latest` is the version users will get on `npm install`
# (without a pinned version). We use that as the "what's upstream" signal
# rather than the openagents monorepo's git tags, which have drifted.
get_latest_launcher_version() {
  local response
  response=$(curl -sf "https://registry.npmjs.org/@openagents-org/agent-launcher" 2>/dev/null)
  if [[ -z "$response" ]]; then
    echo ""
    return
  fi
  echo "$response" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d.get('dist-tags', {}).get('latest', ''))
except Exception:
    pass
" 2>/dev/null
}

# ── Check upstream and warn (idempotent, called at startup) ──
check_upstream() {
  local latest
  latest=$(get_latest_launcher_version)
  if [[ -z "$latest" ]]; then
    warn "Could not reach npm registry for version check"
    return 0
  fi
  if [[ "$latest" != "$OPENAGENTS_LAUNCHER_VERSION" ]]; then
    warn "Upstream has newer launcher: v$latest (pinned: v$OPENAGENTS_LAUNCHER_VERSION)"
    warn "To upgrade: openagents-stack --upgrade"
  else
    ok "Upstream matches pinned version: v$OPENAGENTS_LAUNCHER_VERSION"
  fi
}
