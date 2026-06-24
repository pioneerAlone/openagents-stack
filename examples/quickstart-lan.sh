#!/usr/bin/env bash
# ============================================================
# quickstart-lan.sh — 6 分钟入门 openagents-stack（局域网）
# Thin wrapper: delegates the bootstrap (clone / PATH / install) to
# the root install.sh, then layers LAN-specific config on top.
# See deployments/README.md for the pattern.
# ============================================================
set -euo pipefail

DEPLOY_DIR="https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/deployments/lan-team"
INSTALL_URL="https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/install.sh"

# 1. Run root installer (handles clone / pull / PATH / setup / first start)
curl -fsSL "$INSTALL_URL" | bash

# 2. Apply LAN config (binds to 0.0.0.0, simple auth, prints LAN IP)
export OPENAGENTS_STACK_HOME="$HOME/openagents-stack"
curl -fsSL "$DEPLOY_DIR/config.lan.yaml" -o "$OPENAGENTS_STACK_HOME/config.yaml"

# 3. Re-run setup so the new bind_address is honored, then restart
"$OPENAGENTS_STACK_HOME/bin/openagents-stack"
"$OPENAGENTS_STACK_HOME/bin/openagents-stack" --start

# 4. Start the hello_world demo (proves the install works end-to-end)
(cd "$OPENAGENTS_STACK_HOME/examples/demos/hello_world" && ./run.sh) &

# 5. Print the LAN URL
LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "unknown")
echo ""
echo "============================================"
echo "  ✅ LAN mode ready"
echo "  Local:  http://localhost:8000"
echo "  LAN:    http://$LAN_IP:8000"
echo "  Studio: http://localhost:8050 (started by demo in background)"
echo "============================================"
echo "  Team members on the same network only need:"
echo "    export OPENAGENTS_ENDPOINT=http://$LAN_IP:8000"
echo "    (no docker, no monorepo — just the agn CLI)"
echo "============================================"
