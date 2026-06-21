#!/usr/bin/env bash
# ============================================================
# 本地个人模式 — 1 行安装
# curl -fsSL https://.../install.sh | bash
# ============================================================
set -euo pipefail
echo "[1/2] Installing openagents-stack..."
if [[ ! -d "$HOME/openagents-stack" ]]; then
  git clone https://github.com/pioneerAlone/openagents-stack.git "$HOME/openagents-stack"
fi
cd "$HOME/openagents-stack"
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/openagents-stack/bin/openagents-stack" "$HOME/.local/bin/openagents-stack"
export PATH="$HOME/.local/bin:$PATH"
echo "[2/2] Running setup..."
./bin/openagents-stack
./bin/openagents-stack --start
echo "✅ Ready! Visit http://localhost:8000/docs"
