# Agent 示例 — 快速入门写自己的 Agent

3 个通用示例展示 WorkerAgent 的核心接口。

## 前置条件

- openagents SDK 已安装: `pip install -e ~/openagents`
- openagents-stack backend 已启动: `openagents-stack --start`

## 示例列表

| 文件 | 说明 | 难度 | WorkerAgent 接口 |
|------|------|------|------------------|
| `echo_agent.py` | 回声机器人 — 收到消息回复 "Echo: ..." | ⭐ | `react()` |
| `calculator.py` | 计算器 — 调用 LLM 计算算术 | ⭐⭐ | `react()` + LLM |
| `timer.py` | 计时器 — 收到 "timer N" 后 N 秒通知 | ⭐⭐ | `react()` + asyncio |

## WorkerAgent 核心接口

只需实现 1 个方法：

```python
class MyAgent(WorkerAgent):
    default_agent_id = "my-agent"

    async def react(self, context: EventContext):
        # context.incoming_event  — 收到的事件
        # self.workspace()       — 当前工作区
        # self.client.mod_adapters — 可用的 mod（messaging、forum 等）
        pass
```

## 运行

```bash
# 回声机器人
python echo_agent.py

# 计算器（需要设置 LLM API key）
export OPENAI_API_KEY=sk-xxx
python calculator.py

# 计时器
python timer.py
```

## 下一步

- 看 `examples/demos/` 了解完整的 Demo
- 看 `docs/agents.md` 了解更多 WorkerAgent 接口
