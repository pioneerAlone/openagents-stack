#!/usr/bin/env bash
# ============================================================
# quickstart-enterprise.sh — 35 分钟入门 openagents-stack（企业）
# ============================================================
set -euo pipefail

echo "============================================"
echo "  openagents-stack Quick Start (企业)"
echo "  35 分钟部署企业级 backend + HTTPS + SSO"
echo "============================================"
echo ""

# 1. 安装
echo "[1/6] Installing openagents-stack..."
if [[ ! -d "$HOME/openagents-stack" ]]; then
  git clone https://github.com/pioneerAlone/openagents-stack.git "$HOME/openagents-stack"
fi
cd "$HOME/openagents-stack"

mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/openagents-stack/bin/openagents-stack" "$HOME/.local/bin/openagents-stack"
export PATH="$HOME/.local/bin:$PATH"

# 2. HTTPS 证书 (self-signed for testing)
echo "[2/6] Generating HTTPS cert..."
mkdir -p /etc/ssl/certs /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048   -keyout /etc/ssl/private/openagents.key   -out /etc/ssl/certs/openagents.crt   -subj "/CN=openagents.company.com" 2>/dev/null

# 3. nginx 配置
echo "[3/6] Configuring nginx..."
cat > /etc/nginx/sites-enabled/openagents <<'NGINX'
server {
    listen 443 ssl;
    server_name openagents.company.com;
    ssl_certificate /etc/ssl/certs/openagents.crt;
    ssl_certificate_key /etc/ssl/private/openagents.key;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGINX
nginx -t && nginx -s reload

# 4. config
echo "[4/6] Configuring enterprise..."
cat > "$HOME/openagents-stack/config.enterprise.yaml" <<EOF
openagents_stack:
  backend_port: 8000
  bind_address: "127.0.0.1"
https:
  enabled: true
  domain: "openagents.company.com"
auth:
  type: oauth2
  oauth2:
    provider: "https://login.company.com"
    client_id: "openagents-stack"
    client_secret: "***"
tenants:
  - name: "engineering"
    workspace: eng-shared
    members: ["alice@company.com"]
EOF

# 5. 启动
echo "[5/6] Starting backend..."
./bin/openagents-stack --config config.enterprise.yaml
./bin/openagents-stack --start

# 6. 验证
echo "[6/6] Verifying..."
curl -k https://localhost:8000/health

echo ""
echo "============================================"
echo "  Ready! (企业模式)"
echo ""
echo "  HTTPS: https://openagents.company.com"
echo "  Auth:  OAuth2 @ login.company.com"
echo "============================================"
