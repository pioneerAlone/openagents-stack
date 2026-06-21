#!/usr/bin/env bash
set -euo pipefail
LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "192.168.1.100")
echo "=== Verifying lan-team deployment ==="
curl -sf "http://localhost:8000/health" && echo "✅ Local healthy"
curl -sf "http://$LAN_IP:8000/health" && echo "✅ LAN accessible" || echo "⚠️ LAN not accessible (check firewall)"
openagents-stack --check
