#!/usr/bin/env bash
set -euo pipefail
echo "=== Verifying local-personal deployment ==="
curl -sf http://localhost:8000/health && echo "✅ Backend healthy" || echo "❌ Backend down"
openagents-stack --check
