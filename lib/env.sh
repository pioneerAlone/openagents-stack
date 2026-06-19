# env.sh - manage environment variables in ~/.zshrc (or ~/.bashrc)
# Source: `source lib/env.sh`
# Idempotent: safe to re-run; detects existing entries and updates them

# ── Detect shell rc file ──
detect_shell_rc() {
  # Prefer zsh on macOS (default since Catalina)
  if [[ -n "${ZDOTDIR:-}" ]] && [[ -f "$ZDOTDIR/.zshrc" ]]; then
    echo "$ZDOTDIR/.zshrc"
  elif [[ -f "$HOME/.zshrc" ]]; then
    echo "$HOME/.zshrc"
  elif [[ -f "$HOME/.bashrc" ]]; then
    echo "$HOME/.bashrc"
  elif [[ -f "$HOME/.bash_profile" ]]; then
    echo "$HOME/.bash_profile"
  else
    # Create ~/.zshrc as default
    echo "$HOME/.zshrc"
  fi
}

# ── Write/update an export line idempotently ──
# Usage: write_env_var "OPENAGENTS_HOME" "$OPENAGENTS_HOME" "$rc_file"
# Result: appends "export X=Y" if not present, or updates if present
write_env_var() {
  local key="$1"
  local value="$2"
  local rc_file="${3:-$(detect_shell_rc)}"

  # Skip if value is empty
  [[ -z "$value" ]] && return 0

  # Ensure rc file exists
  [[ -f "$rc_file" ]] || touch "$rc_file"

  # Check if key already exists
  if grep -qE "^export ${key}=" "$rc_file" 2>/dev/null; then
    # Update existing line (replace)
    # macOS sed requires -i ''; GNU sed requires -i
    if sed --version >/dev/null 2>&1; then
      # GNU sed (Linux)
      sed -i "s|^export ${key}=.*$|export ${key}=\"${value}\"|" "$rc_file"
    else
      # BSD sed (macOS)
      sed -i '' "s|^export ${key}=.*$|export ${key}=\"${value}\"|" "$rc_file"
    fi
    log "  Updated $key in $rc_file"
  else
    # Append new line
    echo "export ${key}=\"${value}\"" >> "$rc_file"
    log "  Added $key to $rc_file"
  fi
}

# ── Mark with a comment header for easy removal later ──
mark_env_block() {
  local rc_file="${1:-$(detect_shell_rc)}"
  # Only add marker if not already present
  if ! grep -q "# >>> openagents-stack env >>>" "$rc_file" 2>/dev/null; then
    {
      echo ""
      echo "# >>> openagents-stack env >>>"
    } >> "$rc_file"
  fi
}

# ── Write all openagents env vars ──
write_all_env() {
  local rc_file
  rc_file=$(detect_shell_rc)

  mark_env_block "$rc_file"

  write_env_var "OPENAGENTS_HOME" "$OPENAGENTS_HOME" "$rc_file"
  write_env_var "OPENAGENTS_STACK_HOME" "$OPENAGENTS_STACK_HOME" "$rc_file"
  write_env_var "OPENAGENTS_BACKEND_PORT" "$OPENAGENTS_BACKEND_PORT" "$rc_file"
  write_env_var "OPENAGENTS_ENDPOINT" "http://localhost:$OPENAGENTS_BACKEND_PORT" "$rc_file"
  write_env_var "PATH" "\$HOME/.openagents/nodejs/node_modules/.bin:\$PATH" "$rc_file"

  # Mark end
  if ! grep -q "# <<< openagents-stack env <<<" "$rc_file" 2>/dev/null; then
    echo "# <<< openagents-stack env <<<" >> "$rc_file"
  fi

  ok "Environment written to $rc_file"
  warn "To activate in current shell, run: source $rc_file"
}
