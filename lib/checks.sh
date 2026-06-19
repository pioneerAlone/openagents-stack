# checks.sh - preflight checks (read-only, output only)
# Source: `source lib/checks.sh`
# Used by: step_check_prereq in main flow

# ── Check prereq (called at start of step 0) ──
step_check_prereq() {
  log "[0/5] Check prerequisites"

  # Tools
  command -v git >/dev/null || err "git not installed"
  command -v curl >/dev/null || err "curl not installed"

  # brew (macOS only)
  if [[ "$PLATFORM" == "macos" ]]; then
    command -v brew >/dev/null || err "brew not installed. See: https://brew.sh"
  fi

  ok "Prerequisites OK"
  done_step step_check_prereq
}

# ── Verify monorepo clone health (called at start of step 3) ──
check_monorepo_health() {
  [[ -d "$OPENAGENTS_HOME/.git" ]] || return 1
  git -C "$OPENAGENTS_HOME" rev-parse --short HEAD >/dev/null 2>&1 || return 1
  return 0
}
