#!/usr/bin/env bash
# config.sh - environment variables and paths
# Source: `source lib/config.sh`

# ── Paths (override via env) ──
: "${OPENAGENTS_HOME:=$HOME/openagents}"
: "${OPENAGENTS_STACK_HOME:=$HOME/openagents-stack}"
: "${OPENAGENTS_BACKEND_PORT:=8000}"

# ── User-tunable defaults ──
: "${WORKSPACE_NAME:=my-team}"
: "${AGENT_TYPES:=hermes,claude,opencode}"
: "${DOCKER_RUNTIME:=}"  # macOS: orbstack|docker (empty = ask)

# ── Paths derived ──
export OPENAGENTS_HOME
export OPENAGENTS_STACK_HOME
export OPENAGENTS_BACKEND_PORT
export WORKSPACE_NAME
export AGENT_TYPES
export DOCKER_RUNTIME

# ── Source versions.lock ──
load_versions() {
  if [[ ! -f "$LIB_DIR/versions.lock" ]]; then
    err "lib/versions.lock not found"
  fi
  # shellcheck disable=SC1090
  source "$LIB_DIR/versions.lock"
  export OPENAGENTS_LAUNCHER_TAG
  export OPENAGENTS_MONOREPO_COMMIT
  export OPENAGENTS_MONOREPO_BRANCH
}
load_versions
