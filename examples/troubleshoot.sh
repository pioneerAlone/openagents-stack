#!/usr/bin/env bash
# ============================================================
# troubleshoot.sh — 常见问题排查（5 步）
# ============================================================
set -euo pipefail

echo "=== openagents-stack Troubleshooting ==="
echo ""

# 1. 检查 docker
echo "[1/5] Docker..."
if docker info > /dev/null 2>&1; then
  echo "  ✅ Docker running ($(docker --version))"
else
  echo "  ❌ Docker not running — start OrbStack or Docker Desktop"
fi

# 2. 检查 backend
echo "[2/5] Backend..."
if curl -sf http://localhost:8000/health > /dev/null 2>&1; then
  echo "  ✅ Backend healthy (http://localhost:8000)"
else
  echo "  ❌ Backend not responding — run: openagents-stack --start"
fi

# 3. 检查 monorepo
echo "[3/5] Monorepo..."
if [[ -d "$HOME/openagents/workspace/backend" ]]; then
  echo "  ✅ Monorepo at $HOME/openagents"
else
  echo "  ❌ Monorepo missing — re-run: openagents-stack"
fi

# 4. 检查 launcher daemon
echo "[4/5] Launcher daemon..."
if [[ -d "$HOME/.openagents" ]]; then
  echo "  ✅ Launcher data at $HOME/.openagents"
else
  echo "  ⚠️  Launcher not initialized — run OpenAgents Launcher.app"
fi

# 5. 跑自检
echo "[5/5] openagents-stack --check..."
openagents-stack --check 2>/dev/null || echo "  ⚠️  Some checks failed — see above"

echo ""
echo "=== Troubleshooting complete ==="
echo "If issues persist, check:"
echo "  - openagents-stack --logs     (backend logs)"
echo "  - docker ps                   (container status)"
echo "  - curl localhost:8000/docs    (API docs)"
