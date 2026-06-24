#!/usr/bin/env bash
# ============================================================
# quickstart.sh — 5 分钟入门 openagents-stack（本地模式）
# Thin wrapper around the root install.sh. Nothing to layer on top
# of the default config — local-personal mode is the install.sh
# default. Just kicks off the install and starts the hello_world
# demo to prove the install works end-to-end.
# ============================================================
set -euo pipefail

INSTALL_URL="https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/install.sh"

# 1. Run root installer (handles clone / pull / PATH / setup / first start)
curl -fsSL "$INSTALL_URL" | bash

# 2. Start the hello_world demo (proves the install works end-to-end)
export OPENAGENTS_STACK_HOME="$HOME/openagents-stack"
(cd "$OPENAGENTS_STACK_HOME/examples/demos/hello_world" && ./run.sh) &

echo ""
echo "============================================"
echo "  ✅ Local mode ready"
echo "  Backend: http://localhost:8000"
echo "  Studio:  http://localhost:8050 (started by demo in background)"
echo "============================================"
echo "  For LAN or enterprise modes, see:"
echo "    examples/quickstart-lan.sh"
echo "    examples/quickstart-enterprise.sh"
echo "============================================"
