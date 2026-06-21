#!/usr/bin/env bash
# ============================================================
# quickstart-lan.sh — 6 分钟入门 openagents-stack（局域网）
# ============================================================
set -euo pipefail

echo "============================================"
echo "  openagents-stack Quick Start (局域网)"
echo "  6 分钟跑起团队共享的 backend"
echo "============================================"
echo ""

# 1. 安装
echo "[1/4] Installing openagents-stack..."
if [[ ! -d "$HOME/openagents-stack" ]]; then
  git clone https://github.com/pioneerAlone/openagents-stack.git "$HOME/openagents-stack"
fi
cd "$HOME/openagents-stack"

mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/openagents-stack/bin/openagents-stack" "$HOME/.local/bin/openagents-stack"
export PATH="$HOME/.local/bin:$PATH"

# 2. 配置 LAN IP
LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "192.168.1.100")
echo "[2/4] Configuring LAN (IP: $LAN_IP)..."
export OPENAGENTS_ENDPOINT="http://$LAN_IP:8000"

# 3. 配置 config（简单用户名+密码）
cat > "$HOME/openagents-stack/config.lan.yaml" <<EOF
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

# 4. 启动
echo "[3/4] Running setup + start..."
./bin/openagents-stack --config config.lan.yaml
./bin/openagents-stack --start --bind 0.0.0.0

# 5. Hello world
echo "[4/4] Starting hello_world demo..."
cd examples/demos/hello_world && ./run.sh

echo ""
echo "============================================"
echo "  Ready!"
echo ""
echo "  本机:  http://localhost:8000"
echo "  团队:  http://$LAN_IP:8000"
echo "  Studio: http://localhost:8050"
echo ""
echo "  团队成员执行 (不用装 docker):"
echo "    export OPENAGENTS_ENDPOINT=http://$LAN_IP:8000"
echo "    openagents-stack --start  # 只连到你的 backend"
echo "============================================"
