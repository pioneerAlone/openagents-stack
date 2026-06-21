#!/usr/bin/env bash
set -euo pipefail
echo "=== Enterprise Deployment ==="
echo ""
echo "[1/5] Installing..."
if [[ ! -d "$HOME/openagents-stack" ]]; then
  git clone https://github.com/pioneerAlone/openagents-stack.git "$HOME/openagents-stack"
fi
cd "$HOME/openagents-stack"
echo "[2/5] HTTPS cert..."
mkdir -p /etc/ssl/certs /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/openagents.key \
  -out /etc/ssl/certs/openagents.crt \
  -subj "/CN=openagents.company.com" 2>/dev/null
echo "[3/5] nginx..."
cat > /etc/nginx/sites-enabled/openagents <<'NGINX'
server {
    listen 443 ssl;
    server_name openagents.company.com;
    ssl_certificate /etc/ssl/certs/openagents.crt;
    ssl_certificate_key /etc/ssl/private/openagents.key;
    location / { proxy_pass http://127.0.0.1:8000; }
}
NGINX
nginx -t && nginx -s reload
echo "[4/5] Config..."
cp config.enterprise.yaml config.yaml
echo "[5/5] Starting..."
./bin/openagents-stack --config config.yaml
./bin/openagents-stack --start
echo "✅ Ready! https://openagents.company.com"
