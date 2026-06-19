#!/usr/bin/env bash
# ============================================================
# create-agents.example.sh - REFERENCE script for users
# ============================================================
# This is NOT called by openagents-stack main flow.
# It's a working example for users who want to create workspaces
# and agents via CLI.
#
# Usage:
#   1. Edit WORKSPACE_NAME and AGENT_TYPES below
#   2. Run: bash examples/create-agents.example.sh
#
# Or do it manually:
#   export OPENAGENTS_ENDPOINT=http://localhost:8000
#   agn workspace create <name>
#   agn create my-agent --type <type>
#   agn connect my-agent <workspace-token>
# ============================================================
set -euo pipefail

# ── User-tunable ──
WORKSPACE_NAME="${WORKSPACE_NAME:-wangbo-team}"
AGENT_TYPES="${AGENT_TYPES:-hermes,claude,opencode}"
AGN="${AGN:-$HOME/.openagents/nodejs/node_modules/.bin/agn}"

# ── Source backend URL (set by openagents-stack env) ──
: "${OPENAGENTS_ENDPOINT:=http://localhost:8000}"
export OPENAGENTS_ENDPOINT

log()  { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"; }
ok()   { log "✅ $*"; }
warn() { log "⚠️  $*"; }
err()  { log "❌ $*"; exit 1; }

[[ -x "$AGN" ]] || err "agn not found at $AGN. Run openagents-stack first."

log "Workspace: $WORKSPACE_NAME"
log "Agents:    $AGENT_TYPES"
log "Endpoint:  $OPENAGENTS_ENDPOINT"
echo ""

# ── Create workspace ──
if ! "$AGN" workspace list 2>/dev/null | grep -q "$WORKSPACE_NAME"; then
  log "Creating workspace: $WORKSPACE_NAME"
  "$AGN" workspace create "$WORKSPACE_NAME" 2>&1 | tail -5
else
  ok "Workspace exists: $WORKSPACE_NAME"
fi

# ── Resolve slug + token ──
slug=$("$AGN" workspace list 2>/dev/null | tail -1 | awk '{print $1}')
[[ -z "$slug" ]] && err "Could not resolve workspace slug"

token=$(docker exec workspace-db-1 psql -U postgres -d openagents_workspace -tA \
  -c "SELECT password_hash FROM workspaces WHERE slug='$slug';" 2>/dev/null | tr -d ' ')
[[ -z "$token" ]] && err "Could not fetch workspace token from DB"
ok "Workspace slug: $slug"

# ── Create + connect agents ──
IFS=',' read -ra types <<< "$AGENT_TYPES"
for agent_type in "${types[@]}"; do
  agent_type=$(echo "$agent_type" | tr -d ' ')
  agent_name="my-${agent_type}"

  if ! "$AGN" list 2>/dev/null | grep -q "^\s*${agent_name}\s"; then
    log "Creating agent: $agent_name (type=$agent_type)"
    "$AGN" create "$agent_name" --type "$agent_type" 2>&1 | tail -3
  else
    ok "Agent exists: $agent_name"
  fi

  if ! "$AGN" list 2>/dev/null | grep -E "${agent_name}.*${slug}" >/dev/null; then
    log "Connecting $agent_name → $slug"
    "$AGN" connect "$agent_name" "$token" 2>&1 | tail -3
  else
    ok "Agent $agent_name already connected to $slug"
  fi
done

# ── Start daemon ──
log "Starting launcher daemon..."
"$AGN" up 2>&1 | tail -3

ok "Done! Workspace '$WORKSPACE_NAME' with ${#types[@]} agent(s) ready."
