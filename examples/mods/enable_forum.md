# 怎么在 openagents-stack 里启用 forum mod

## 这个 Mod 是干什么的

论坛：Reddit 风格讨论（话题 + 评论 + 投票）。

## 在 monorepo 的位置

- `sdk/src/openagents/mods/workspace/forum/`

## 准备工作

openagents-stack 已安装 workspace/backend（port 8000）。

## 4 步启用 forum

### 1. 编辑 monorepo 配置

编辑 `~/openagents/workspace/backend/app/mods/workspace_mod.py`，添加：

```python
from openagents.mods.workspace.forum import ForumMod
ForumMod().register(workspace)
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

- OpenAgents Launcher → Workspace → 论坛
