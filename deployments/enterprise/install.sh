#!/usr/bin/env bash
# ============================================================
# Enterprise 部署 — 1 行安装
# curl -fsSL https://.../enterprise/install.sh | bash
#
# Thin wrapper: bootstraps the stack, then layers enterprise-mode
# specifics (HTTPS cert + nginx reverse proxy in front of the
# backend, which itself stays bound to 127.0.0.1).
#
# NOTES for production use:
#   * Replace the self-signed cert below with a real one from
#     Let's Encrypt / your internal CA.
#   * Replace the hardcoded admin password hash in
#     config.enterprise.yaml before exposing to the network.
#   * This script writes to /etc/ssl and /etc/nginx — it needs
#     root. Run via sudo, or replace with your own provisioning
#     system (Ansible, Terraform, etc.).
# ============================================================
set -euo pipefail

DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Bootstrap the stack
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/install.sh | bash
export OPENAGENTS_STACK_HOME="$HOME/openagents-stack"

# 2. Enterprise config (HTTPS + auth, with bind on 127.0.0.1 behind nginx)
cp "$DEPLOY_DIR/config.enterprise.yaml" "$OPENAGENTS_STACK_HOME/config.yaml"

# 3. TLS cert (self-signed placeholder — replace in production)
if [[ ! -f /etc/ssl/certs/openagents.crt ]]; then
  echo "Generating self-signed cert (replace with a real cert for production)..."
  sudo mkdir -p /etc/ssl/certs /etc/ssl/private
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/openagents.key \
    -out /etc/ssl/certs/openagents.crt \
    -subj "/CN=openagents.company.com" 2>/dev/null
fi

# 4. nginx reverse proxy
if command -v nginx >/dev/null 2>&1; then
  sudo cp "$DEPLOY_DIR/nginx.conf" /etc/nginx/sites-enabled/openagents
  sudo nginx -t && sudo nginx -s reload
fi

# 5. Run setup + start
"$OPENAGENTS_STACK_HOME/bin/openagents-stack"
"$OPENAGENTS_STACK_HOME/bin/openagents-stack" --start

echo ""
echo "✅ Enterprise mode ready"
echo "  https://openagents.company.com (via nginx reverse proxy)"
echo "  Backend itself: http://127.0.0.1:8000 (not exposed)"
