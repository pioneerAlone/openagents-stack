# 部署模式

openagents-stack 支持 3 种部署场景：

| 模式 | 说明 | 时间 |
|------|------|------|
| `local-personal/` | 本地个人使用 | 5 分钟 |
| `lan-team/` | 局域网团队协作 | 6 分钟 |
| `enterprise/` | 企业部署（HTTPS+SSO） | 35 分钟 |

## 使用

```bash
# 本地
curl -fsSL https://.../deployments/local-personal/install.sh | bash

# 局域网
curl -fsSL https://.../deployments/lan-team/install.sh | bash

# 企业
curl -fsSL https://.../deployments/enterprise/install.sh | bash
```
