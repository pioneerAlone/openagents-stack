#!/usr/bin/env bash
set -euo pipefail

# Resolve STACK_HOME the same way hello_world/run.sh does: env override,
# then follow the symlink at ~/.local/bin/openagents-stack back to its
# target, then fall back to install.sh's default.
OPENAGENTS_STACK_HOME="${OPENAGENTS_STACK_HOME:-}"
if [[ -z "$OPENAGENTS_STACK_HOME" ]]; then
  if command -v openagents-stack >/dev/null 2>&1; then
    _bin="$(command -v openagents-stack)"
    [[ -L "$_bin" ]] && _bin="$(readlink "$_bin")"
    OPENAGENTS_STACK_HOME="$(cd "$(dirname "$_bin")/.." && pwd)"
  else
    OPENAGENTS_STACK_HOME="$HOME/openagents-stack"
  fi
fi
OPENAGENTS_MONOREPO="${OPENAGENTS_HOME:-$HOME/openagents}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== AgentWorld (代理游戏世界) ==="

if ! python3 -m openagents --help > /dev/null 2>&1; then
  echo "[0/4] Installing openagents SDK..."
  cd "$OPENAGENTS_MONOREPO" && pip3 install -e . > /dev/null 2>&1
fi

echo "[1/4] Starting backend..."
"$OPENAGENTS_STACK_HOME/bin/openagents-stack" --start 2>/dev/null || true

echo "[2/4] Starting network..."
cd "$OPENAGENTS_MONOREPO" && python3 -m openagents network start "$SCRIPT_DIR" &
sleep 3

echo "[3/4] Starting agent..."
AGENT=$(find "$SCRIPT_DIR/agents" -name "*.yaml" 2>/dev/null | head -1)
if [[ -n "$AGENT" ]]; then
  cd "$OPENAGENTS_MONOREPO" && python3 -m openagents agent start "$AGENT" &
  sleep 2
fi

echo "[4/4] Starting Studio..."
cd "$OPENAGENTS_MONOREPO" && python3 -m openagents studio -s &
sleep 2

echo ""
echo "=== Demo ready! ==="
echo "Studio: http://localhost:8050"
wait
