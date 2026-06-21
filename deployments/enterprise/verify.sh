#!/usr/bin/env bash
set -euo pipefail
echo "=== Verifying enterprise deployment ==="
echo "[1/4] HTTPS..."
curl -sk https://localhost:8000/health && echo "✅ HTTPS healthy" || echo "❌ HTTPS down"
echo "[2/4] nginx..."
nginx -t && echo "✅ nginx OK"
echo "[3/4] Backend..."
openagents-stack --check
echo "[4/4] SSO..."
[[ -n "${OAUTH2_CLIENT_SECRET:-}" ]] && echo "✅ SSO configured" || echo "⚠️ SSO not yet configured"
echo "=== Verification complete ==="
