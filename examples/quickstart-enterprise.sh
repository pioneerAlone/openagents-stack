#!/usr/bin/env bash
# ============================================================
# quickstart-enterprise.sh — 35 分钟入门 openagents-stack（企业）
# Thin wrapper: delegates the bootstrap to the root install.sh,
# then layers enterprise-mode specifics (HTTPS cert + nginx reverse
# proxy in front of the backend, which itself stays bound to 127.0.0.1).
#
# Production checklist before you ship this for real:
#   1. Replace the self-signed cert with one from Let's Encrypt / your CA
#   2. Replace the admin password hash in config.enterprise.yaml
#   3. Replace OAuth2 placeholders with real provider credentials
#   4. Move state into a managed DB / secret store instead of docker volume
# ============================================================
set -euo pipefail

DEPLOY_DIR="https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/deployments/enterprise"
INSTALL_URL="https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/install.sh"

# 1. Run root installer
curl -fsSL "$INSTALL_URL" | bash
export OPENAGENTS_STACK_HOME="$HOME/openagents-stack"

# 2. Enterprise config
curl -fsSL "$DEPLOY_DIR/config.enterprise.yaml" -o "$OPENAGENTS_STACK_HOME/config.yaml"

# 3. Self-signed TLS cert placeholder (replace with a real one for production)
if [[ ! -f /etc/ssl/certs/openagents.crt ]]; then
  echo "Generating self-signed cert (replace with a real cert for production)..."
  sudo mkdir -p /etc/ssl/certs /etc/ssl/private
  sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/openagents.key \
    -out /etc/ssl/certs/openagents.crt \
    -subj "/CN=openagents.company.com" 2>/dev/null
fi

# 4. nginx reverse proxy in front of the backend
if command -v nginx >/dev/null 2>&1; then
  sudo curl -fsSL "$DEPLOY_DIR/nginx.conf" -o /etc/nginx/sites-enabled/openagents
  sudo nginx -t && sudo nginx -s reload
fi

# 5. Run setup + start
"$OPENAGENTS_STACK_HOME/bin/openagents-stack"
"$OPENAGENTS_STACK_HOME/bin/openagents-stack" --start

# 6. Verify
echo ""
echo "============================================"
echo "  ✅ Enterprise mode ready"
echo "  https://openagents.company.com (via nginx)"
echo "  Backend itself: http://127.0.0.1:8000 (not exposed)"
echo "============================================"
