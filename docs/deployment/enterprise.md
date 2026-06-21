# 部署模式详解 — enterprise

## 模式特点

- **时间**：35 分钟
- **目标**：企业级部署、多团队、多租户、高可用
- **网络**：HTTPS + 反向代理（nginx）
- **认证**：OAuth2 / SSO / LDAP
- **多租户**：强（每团队独立 workspace）
- **HTTPS**：必需
- **域名**：必需

## 适用场景

- ✅ 公司级使用
- ✅ 多团队独立 workspace
- ✅ 对外提供服务
- ✅ 高可用要求
- ✅ 严格安全审计
- ❌ 个人/小团队（用 `local-personal` 或 `lan-team`）

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/deployments/enterprise/install.sh | bash
```

脚本会自动：
1. 装 openagents-stack
2. 生成自签名 HTTPS 证书（生产用 Let's Encrypt）
3. 配置 nginx 反向代理
4. 创建 `config.enterprise.yaml`（OAuth2 + 多租户）
5. 启动 backend

## 手动安装

```bash
# 1. 装 docker
brew install --cask orbstack

# 2. 装 nginx
brew install nginx
# 生产环境用 certbot + Let's Encrypt

# 3. 装 openagents-stack
git clone https://github.com/pioneerAlone/openagents-stack.git ~/openagents-stack
cd ~/openagents-stack

# 4. 配置 HTTPS 证书
mkdir -p /etc/ssl/certs /etc/ssl/private
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/openagents.key \
  -out /etc/ssl/certs/openagents.crt \
  -subj "/CN=openagents.company.com"
# 生产环境用 Let's Encrypt:
# certbot certonly --nginx -d openagents.company.com

# 5. 配置 nginx
cp deployments/enterprise/nginx.conf /etc/nginx/sites-enabled/openagents
nginx -t && nginx -s reload

# 6. 创建 config.enterprise.yaml
cat > config.enterprise.yaml <<EOF
openagents_stack:
  backend_port: 8000
  bind_address: "127.0.0.1"  # 只监听本地（nginx 反向代理）

https:
  enabled: true
  domain: "openagents.company.com"
  cert_file: "/etc/ssl/certs/openagents.crt"
  key_file: "/etc/ssl/private/openagents.key"

auth:
  type: oauth2
  oauth2:
    provider: "https://login.company.com"
    client_id: "openagents-stack"
    client_secret: "***"
    scopes: ["openid", "profile", "email"]

tenants:
  - name: "engineering"
    workspace: eng-shared
    members: ["alice@company.com", "bob@company.com"]
  - name: "marketing"
    workspace: mkt-shared
    members: ["charlie@company.com", "diana@company.com"]

ha:
  enabled: false  # 单机演示；生产开 3 replicas
  replicas: 3
  load_balancer: "nginx"

monitoring:
  prometheus: {enabled: false}
  grafana: {enabled: false}

backup:
  enabled: false
  schedule: "0 2 * * *"
  retention_days: 30
  storage: "s3://backups/openagents-stack"
EOF

# 7. 启动
./bin/openagents-stack --config config.enterprise.yaml
./bin/openagents-stack --start
```

## nginx 配置详解

```nginx
server {
    listen 443 ssl http2;
    server_name openagents.company.com;

    ssl_certificate /etc/ssl/certs/openagents.crt;
    ssl_certificate_key /etc/ssl/private/openagents.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

## 多租户架构

每个租户独立 workspace：

```
engineering/   → eng-shared workspace
  alice@company.com
  bob@company.com
marketing/     → mkt-shared workspace
  charlie@company.com
  diana@company.com
```

## OAuth2 / SSO

支持的认证方式：
- **OAuth2**（如 Okta、Auth0、Keycloak）
- **SAML**
- **LDAP**
- **OIDC**

## 高可用（生产环境）

```yaml
ha:
  enabled: true
  replicas: 3  # 3 个 backend 容器
  load_balancer: "nginx"
```

## 监控（生产环境）

- **Prometheus**（port 9090）
- **Grafana**（port 3000）
- 告警（Alertmanager）

## 备份（生产环境）

```yaml
backup:
  enabled: true
  schedule: "0 2 * * *"  # 每天凌晨 2 点
  retention_days: 30
  storage: "s3://backups/openagents-stack"
```

## 升级

```bash
openagents-stack --upgrade --backup  # 升级前先备份
```

## 清理

```bash
openagents-stack --clean  # 删所有数据
```

## 常见问题

### Q: 证书过期？
A: 续签 Let's Encrypt 证书：`certbot renew`

### Q: OAuth2 配置错？
A: 检查 `client_id` `client_secret` `redirect_uri`

### Q: 多租户数据隔离？
A: 每个租户独立 workspace，独立数据

## 生产 checklist

- [ ] HTTPS 证书（Let's Encrypt）
- [ ] OAuth2 / SSO 配置
- [ ] nginx 反向代理
- [ ] Prometheus + Grafana
- [ ] S3 备份
- [ ] 3 个 backend 副本
- [ ] 防火墙规则
- [ ] 审计日志
