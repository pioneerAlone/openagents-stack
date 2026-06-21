# 怎么在 openagents-stack 里启用 n8n mod

## 这个 Mod 是干什么的

n8n：n8n 集成（No-code 工作流）。

## 在 monorepo 的位置

- `sdk/src/openagents/mods/integrations/n8n/`

## 准备工作

openagents-stack 已安装 workspace/backend（port 8000）。

## 4 步启用 n8n

### 1. 编辑 monorepo 配置

编辑 `~/openagents/workspace/backend/app/mods/workspace_mod.py`，添加：

```python
from openagents.mods.integrations.n8n import N8NMod
N8NMod().register(workspace)
```

### 2. 重启 backend

```bash
openagents-stack --restart
```

### 3. 验证

```bash
curl http://localhost:8000/health
# 特定 mod 的端点查看 backend app/routers/
```

### 4. 在 launcher 里使用

- OpenAgents Launcher → Workspace → n8n
