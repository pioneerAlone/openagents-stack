"""EchoAgent — 最简 WorkerAgent 示例（回声明机器人）

用法:
  1. 安装 openagents SDK: pip install -e ~/openagents
  2. 运行: python echo_agent.py
  3. 在 launcher/Studio 里发消息，agent 会回复 "Echo: <你的消息>"
"""

from openagents.agents.worker_agent import WorkerAgent
from openagents.models.event_context import EventContext


class EchoAgent(WorkerAgent):
    default_agent_id = "echo"

    async def react(self, context: EventContext):
        """收到任何消息时，回复 "Echo: <原消息>" """
        event = context.incoming_event
        if event.source_id == self.agent_id:
            return  # 忽略自己的消息

        content = event.payload.get("content", "")
        messaging = self.client.mod_adapters.get(
            "openagents.mods.workspace.messaging"
        )
        if messaging and content:
            await messaging.send_channel_message(
                channel=event.payload.get("channel", "general"),
                text=f"Echo: {content}",
            )


if __name__ == "__main__":
    import asyncio
    agent = EchoAgent()
    asyncio.run(agent.setup())
    asyncio.get_event_loop().run_forever()
