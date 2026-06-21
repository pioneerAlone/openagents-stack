# 部署模式详解 — local-personal

## 模式特点

- **时间**：5 分钟
- **目标**：本地个人使用、单机开发、自家测试
- **网络**：只监听 `localhost:8000`
- **认证**：无（只用 `localhost`）
- **多租户**：无（单用户）
- **HTTPS**：不需要
- **域名**：不需要

## 适用场景

- ✅ 开发者试用 openagents
- ✅ 自家机器跑个人 AI 助手
- ✅ CI/CD 测试环境
- ❌ 多用户协作（用 `lan-team`）
- ❌ 公网访问（用 `enterprise`）

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/deployments/local-personal/install.sh | bash
```

脚本会自动：
1. 检查 docker 是否运行
2. Clone openagents-stack
3. 加入 PATH
4. 跑 setup（装 launcher + clone monorepo + 装 backend）
5. 启动 backend

## 手动安装

```bash
# 1. 装 docker（OrbStack 或 Docker Desktop）
brew install --cask orbstack

# 2. 装 openagents-stack
git clone https://github.com/pioneerAlone/openagents-stack.git ~/openagents-stack
cd ~/openagents-stack
./bin/openagents-stack

# 3. 启动 backend
./bin/openagents-stack --start

# 4. 验证
curl http://localhost:8000/health
```

## 端口

| 端口 | 用途 |
|------|------|
| 8000 | backend API (FastAPI) |
| 8666 | launcher daemon |
| 8700 | SDK network (openagents network start) |
| 8050 | Studio web UI (openagents studio) |

## 配置

无需任何配置。`bin/openagents-stack` 会自动：
- 设置 `OPENAGENTS_HOME=~/openagents`
- 设置 `OPENAGENTS_BACKEND_PORT=8000`
- 加入 `~/.zshrc`

## 试用

```bash
# 跑 hello_world demo
cd ~/openagents-stack/examples/demos/hello_world
./run.sh

# 在浏览器打开 Studio
open http://localhost:8050
```

## 关闭

```bash
openagents-stack --stop
```

## 常见问题

### Q: 端口 8000 被占用？
A: `export OPENAGENTS_BACKEND_PORT=8888 && openagents-stack --start`

### Q: Docker 没起？
A: 启动 OrbStack 或 Docker Desktop

### Q: 忘记 PATH？
A: `export PATH="$HOME/.local/bin:$PATH"`

## 升级

```bash
openagents-stack --upgrade
```

## 清理

```bash
openagents-stack --clean  # 删除所有数据（不可恢复）
```
