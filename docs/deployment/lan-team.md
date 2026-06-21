# 部署模式详解 — lan-team

## 模式特点

- **时间**：6 分钟
- **目标**：小团队内部协作、局域网多用户
- **网络**：监听 `0.0.0.0:8000`（局域网所有机器可访问）
- **认证**：简单用户名 + 密码（不用 OAuth2）
- **多租户**：弱（共享 workspace）
- **HTTPS**：不需要
- **域名**：不需要

## 适用场景

- ✅ 5-20 人小团队
- ✅ 公司内部使用
- ✅ 不对外公开
- ❌ 公司级 SSO（用 `enterprise`）
- ❌ 公网访问（用 `enterprise`）

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/deployments/lan-team/install.sh | bash
```

脚本会自动：
1. 检查 docker
2. 装 openagents-stack
3. 检测 LAN IP（macOS: `en0`）
4. 生成 `config.lan.yaml`
5. 启动 backend（监听 `0.0.0.0`）

## 手动安装

```bash
# 1. 装 docker（同 local-personal）
brew install --cask orbstack

# 2. 装 openagents-stack
git clone https://github.com/pioneerAlone/openagents-stack.git ~/openagents-stack
cd ~/openagents-stack

# 3. 配置 LAN
export OPENAGENTS_ENDPOINT="http://192.168.1.100:8000"  # 你的 LAN IP

# 4. 创建 config.lan.yaml
cat > config.lan.yaml <<EOF
openagents_stack:
  backend_port: 8000
  bind_address: "0.0.0.0"
  workspace_name: team-shared
auth:
  type: simple
  users:
    - username: alice
      password_hash: "\$2b\$12\$..."
    - username: bob
      password_hash: "\$2b\$12\$..."
EOF

# 5. 启动
./bin/openagents-stack --config config.lan.yaml
./bin/openagents-stack --start --bind 0.0.0.0
```

## 端口

| 端口 | 用途 |
|------|------|
| 8000 | backend API（监听 `0.0.0.0`） |
| 8666 | launcher daemon |
| 8700 | SDK network |

## 团队成员怎么用

团队成员（不用装 docker）只需：

```bash
export OPENAGENTS_ENDPOINT="http://192.168.1.100:8000"
# 在他们机器上跑：
openagents agent start agents/<agent>.yaml
# 连到你的 backend
```

或者直接用浏览器访问：
```
http://192.168.1.100:8000/docs  # API 文档
http://192.168.1.100:8050      # Studio（如果装了）
```

## 防火墙

确保：
- 8000 端口在防火墙中开放
- 团队成员在同一局域网/VPN
- macOS: 系统设置 → 网络 → 防火墙 → 允许 8000 端口

## 配置详解

```yaml
# config.lan.yaml
openagents_stack:
  backend_port: 8000
  bind_address: "0.0.0.0"  # 关键：监听所有网卡
  workspace_name: team-shared

auth:
  type: simple  # 不是 oauth2
  users:
    - username: alice
      password_hash: "$2b$12$..."  # bcrypt 哈希
    - username: bob
      password_hash: "$2b$12$..."

workspace:
  name: team-shared
  members:
    - alice
    - bob
```

## 添加用户

```bash
# 用 htpasswd 生成 bcrypt 哈希
htpasswd -nb alice mypassword
# 输出：alice:$2y$05$...

# 加到 config.lan.yaml
```

## 升级

```bash
openagents-stack --upgrade
```

## 清理

```bash
openagents-stack --clean  # 删所有数据
```
