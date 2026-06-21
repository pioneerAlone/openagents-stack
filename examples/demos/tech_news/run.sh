#!/usr/bin/env bash
set -euo pipefail
OPENAGENTS_MONOREPO="${OPENAGENTS_HOME:-$HOME/openagents}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Tech News Stream (技术新闻流) ==="

if ! python3 -m openagents --help > /dev/null 2>&1; then
  echo "[0/4] Installing openagents SDK..."
  cd "$OPENAGENTS_MONOREPO" && pip3 install -e . > /dev/null 2>&1
fi

echo "[1/4] Starting backend..."
cd ~/proj/openagents-stack && ./bin/openagents-stack --start 2>/dev/null || true

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
