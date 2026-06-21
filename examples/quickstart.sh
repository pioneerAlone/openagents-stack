#!/usr/bin/env bash
# ============================================================
# quickstart.sh — 5 分钟入门 openagents-stack（本地模式）
# 用法: curl -fsSL .../quickstart.sh | bash
# ============================================================
set -euo pipefail

echo "============================================"
echo "  openagents-stack Quick Start (本地)"
echo "  5 分钟跑起 openagents 的 backend + demo"
echo "============================================"
echo ""

# 1. 安装 openagents-stack
echo "[1/3] Installing openagents-stack..."
if [[ ! -d "$HOME/openagents-stack" ]]; then
  git clone https://github.com/pioneerAlone/openagents-stack.git "$HOME/openagents-stack"
fi
cd "$HOME/openagents-stack"

# 2. 加入 PATH
mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/openagents-stack/bin/openagents-stack" "$HOME/.local/bin/openagents-stack"
if ! grep -q '.local/bin' "$HOME/.zshrc" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
fi
export PATH="$HOME/.local/bin:$PATH"

# 3. 跑 setup + hello_world demo
echo "[2/3] Running setup..."
./bin/openagents-stack

echo "[3/3] Starting backend + hello_world demo..."
./bin/openagents-stack --start
cd examples/demos/hello_world && ./run.sh

echo ""
echo "============================================"
echo "  Ready!"
echo ""
echo "  Backend: http://localhost:8000"
echo "  Studio:  http://localhost:8050"
echo ""
echo "  Try other demos:"
echo "    cd examples/demos/research_team && ./run.sh"
echo "    cd examples/demos/grammar_check && ./run.sh"
echo "============================================"
