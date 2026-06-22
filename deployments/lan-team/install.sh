#!/usr/bin/env bash
# ============================================================
# LAN Team 部署 — 1 行安装
# curl -fsSL https://.../lan-team/install.sh | bash
#
# Thin wrapper: delegates to the root install.sh (which handles
# cloning, PATH, and the actual setup), then runs the stack with
# this deployment's config so the bind_address flips to 0.0.0.0.
# ============================================================
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Bootstrap the stack (clone / pull, symlink, PATH, base setup)
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/install.sh | bash

# 2. Apply the LAN-specific config (bind to 0.0.0.0 instead of 127.0.0.1)
export OPENAGENTS_STACK_HOME="$HOME/openagents-stack"
cp "$DEPLOY_DIR/config.lan.yaml" "$OPENAGENTS_STACK_HOME/config.yaml"

# 3. Re-run setup so the new bind_address is honored, then start
"$OPENAGENTS_STACK_HOME/bin/openagents-stack"
"$OPENAGENTS_STACK_HOME/bin/openagents-stack" --start

# 4. Print the LAN URL (the user needs to know their machine's IP
# so teammates can hit the backend from other devices on the network)
LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}' || echo "unknown")
echo ""
echo "✅ LAN mode ready"
echo "  Local:  http://localhost:8000"
echo "  LAN:    http://$LAN_IP:8000"
echo "  Admin:  admin / (see config.lan.yaml — change the default password hash before sharing)"
