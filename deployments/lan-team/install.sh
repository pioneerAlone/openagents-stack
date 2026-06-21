#!/usr/bin/env bash
set -euo pipefail
LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "192.168.1.100")
echo "=== LAN Team Deployment ==="
echo "Your LAN IP: $LAN_IP"
echo ""
echo "[1/3] Installing..."
if [[ ! -d "$HOME/openagents-stack" ]]; then
  git clone https://github.com/pioneerAlone/openagents-stack.git "$HOME/openagents-stack"
fi
cd "$HOME/openagents-stack"
echo "[2/3] Configuring LAN..."
export OPENAGENTS_ENDPOINT="http://$LAN_IP:8000"
cat > config.lan.yaml <<EOF
openagents_stack:
  backend_port: 8000
  bind_address: "0.0.0.0"
  workspace_name: team-shared
auth:
  type: simple
  users:
    - username: admin
      password_hash: "\$2b\$12\$LJ3m4ys3GZqLzEpKqWxF.OQc.QoFQYE"
EOF
echo "[3/3] Starting..."
./bin/openagents-stack --config config.lan.yaml
./bin/openagents-stack --start --bind 0.0.0.0
echo ""
echo "✅ Ready!"
echo "  Local:  http://localhost:8000"
echo "  LAN:    http://$LAN_IP:8000"
