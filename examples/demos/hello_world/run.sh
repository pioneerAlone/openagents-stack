#!/usr/bin/env bash
# ============================================================
# run.sh — 一键跑起 Hello World Demo
# 使用 openagents-stack 的 backend + monorepo 的 SDK network
# ============================================================
set -euo pipefail

OPENAGENTS_STACK_HOME="${OPENAGENTS_STACK_HOME:-$HOME/proj/openagents-stack}"
OPENAGENTS_MONOREPO="${OPENAGENTS_HOME:-$HOME/openagents}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================"
echo "  Hello World Demo for openagents-stack"
echo "============================================"
echo ""

# ── 0. 确保 openagents SDK 可用 ──
if ! python3 -m openagents --help > /dev/null 2>&1; then
  echo "[0/4] Installing openagents SDK..."
  if [[ -d "$OPENAGENTS_MONOREPO" ]]; then
    cd "$OPENAGENTS_MONOREPO" && pip3 install -e . > /dev/null 2>&1
    echo "  SDK installed"
  else
    echo "  ERROR: monorepo not found at $OPENAGENTS_MONOREPO"
    exit 1
  fi
fi

# ── 1. 启动 openagents-stack backend（port 8000）──
echo "[1/4] Starting openagents-stack backend..."
if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
  "$OPENAGENTS_STACK_HOME/bin/openagents-stack" --start
  echo "  Backend started on http://localhost:8000"
else
  echo "  Backend already running on http://localhost:8000"
fi

# ── 2. 启动 SDK network（port 8700，基于本目录的 network.yaml）──
echo "[2/4] Starting SDK network..."
cd "$SCRIPT_DIR"
if [[ -d "$OPENAGENTS_MONOREPO" ]]; then
  cd "$OPENAGENTS_MONOREPO"
  python3 -m openagents network start "$SCRIPT_DIR" &
  NETWORK_PID=$!
  echo "  SDK network starting (PID $NETWORK_PID) on http://localhost:8700"
  sleep 3
else
  echo "  ERROR: monorepo not found at $OPENAGENTS_MONOREPO"
  echo "  Clone with: git clone https://github.com/openagents-org/openagents.git $OPENAGENTS_MONOREPO"
  exit 1
fi

# ── 3. 启动 agent（Charlie）──
echo "[3/4] Starting agent (Charlie)..."
cd "$OPENAGENTS_MONOREPO"
python3 -m openagents agent start "$SCRIPT_DIR/agents/charlie.yaml" &
AGENT_PID=$!
echo "  Agent 'charlie' starting (PID $AGENT_PID)"
sleep 2

# ── 4. 启动 Studio（web UI）──
echo "[4/4] Starting Studio web UI..."
cd "$OPENAGENTS_MONOREPO"
python3 -m openagents studio -s &
STUDIO_PID=$!
echo "  Studio starting (PID $STUDIO_PID)"
sleep 2

echo ""
echo "============================================"
echo "  Demo ready!"
echo ""
echo "  Backend: http://localhost:8000"
echo "  Network: http://localhost:8700"
echo "  Studio:  http://localhost:8050"
echo ""
echo "  Open Studio and chat with 'charlie'!"
echo ""
echo "  Close demo:"
echo "    kill $NETWORK_PID $AGENT_PID $STUDIO_PID"
echo "    openagents-stack --stop"
echo "============================================"

# Wait for processes
wait $NETWORK_PID $AGENT_PID $STUDIO_PID 2>/dev/null || true