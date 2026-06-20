#!/usr/bin/env bash
# common.sh - shared functions for all scripts
# Source: `source lib/common.sh`

# ── State file (idempotency) ──
# Resolve OPENAGENTS_STACK_HOME: prefer env, then walk up from BASH_SOURCE to find repo root
if [[ -z "${OPENAGENTS_STACK_HOME:-}" ]]; then
  local_stack_home=""
  # common.sh path: ${BASH_SOURCE[1]} when sourced from a script (e.g. bin/openagents-stack)
  #                  ${BASH_SOURCE[0]} when sourced from bash -c
  # We try both. Also try the script that sourced us (BASH_SOURCE[1] in script context).
  for src in "${BASH_SOURCE[1]:-}" "${BASH_SOURCE[0]:-}"; do
    if [[ -n "$src" ]] && [[ -f "$src" ]]; then
      local_check="$(cd "$(dirname "$src")" 2>/dev/null && pwd)"
      while [[ -n "$local_check" ]] && [[ "$local_check" != "/" ]]; do
        if [[ -d "$local_check/bin" ]] && [[ -d "$local_check/lib" ]]; then
          local_stack_home="$local_check"
          break 2
        fi
        local_check="$(dirname "$local_check")"
      done
    fi
  done

  # Fallback: walk up from cwd
  if [[ -z "$local_stack_home" ]]; then
    local_check="$(pwd)"
    while [[ "$local_check" != "/" ]]; do
      if [[ -d "$local_check/bin" ]] && [[ -d "$local_check/lib" ]]; then
        local_stack_home="$local_check"
        break
      fi
      local_check="$(dirname "$local_check")"
    done
  fi

  # Final fallback: ~/openagents-stack
  if [[ -z "$local_stack_home" ]]; then
    local_stack_home="$HOME/openagents-stack"
  fi
  export OPENAGENTS_STACK_HOME="$local_stack_home"
fi
STATE_FILE="$OPENAGENTS_STACK_HOME/.deploy-state"
LOG_FILE="$OPENAGENTS_STACK_HOME/deploy.log"

# ── Logging ──
log()  { printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOG_FILE" >&2; }
ok()   { log "✅ $*"; }
warn() { log "⚠️  $*"; }
err()  { log "❌ $*"; exit 1; }
die()  { log "❌ $*"; exit 1; }

# ── State helpers ──
have()     { [[ -f "$STATE_FILE" ]] && grep -q "^$1$" "$STATE_FILE"; }
done_step(){ echo "$1" >> "$STATE_FILE"; }
reset_state() { rm -f "$STATE_FILE"; }

# ── Need (require command) ──
need() { command -v "$1" >/dev/null 2>&1 || err "$1 not installed: $2"; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

# ── Platform detection ──
detect_platform() {
  case "$OSTYPE" in
    darwin*)           PLATFORM="macos" ;;
    linux*)            PLATFORM="linux" ;;
    msys*|mingw*|cygwin*) PLATFORM="windows-bash" ;;
    *)                 err "Unsupported platform: $OSTYPE" ;;
  esac
  export PLATFORM
}
