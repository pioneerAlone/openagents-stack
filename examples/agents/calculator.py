"""CalculatorAgent — 接入 LLM 的示例（计算器机器人）

用法:
  1. 安装 openagents SDK: pip install -e ~/openagents
  2. 设置 LLM API key: export OPENAI_API_KEY=sk-xxx
  3. 运行: python calculator.py
  4. 在 launcher/Studio 里发 "calculate 2+3"，agent 会回复结果

通用性: 展示如何让 WorkerAgent 调用 LLM 处理任务
"""

import os
from openagents.agents.worker_agent import WorkerAgent
from openagents.models.event_context import EventContext


class CalculatorAgent(WorkerAgent):
    default_agent_id = "calculator"

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.model = os.getenv("LLM_MODEL", "auto")

    async def react(self, context: EventContext):
        event = context.incoming_event
        if event.source_id == self.agent_id:
            return

        content = event.payload.get("content", "")
        if not content.lower().startswith("calculate"):
            return  # 只处理 "calculate ..." 开头的消息

        # 调用 LLM 计算
        from openagents.lms import get_lm
        lm = get_lm(self.model)
        result = await lm.generate(
            f"Calculate this and return ONLY the numeric result: {content}"
        )

        messaging = self.client.mod_adapters.get(
            "openagents.mods.workspace.messaging"
        )
        if messaging:
            await messaging.send_channel_message(
                channel=event.payload.get("channel", "general"),
                text=f"Result: {result}",
            )


if __name__ == "__main__":
    import asyncio
    agent = CalculatorAgent()
    asyncio.run(agent.setup())
    asyncio.get_event_loop().run_forever()
