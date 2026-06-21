"""TimerAgent — 接入事件的示例（计时器机器人）

用法:
  1. 安装 openagents SDK: pip install -e ~/openagents
  2. 运行: python timer.py
  3. 在 launcher/Studio 里发 "timer 5"，agent 会在 5 秒后回复

通用性: 展示如何让 WorkerAgent 响应事件并在延迟后执行操作
"""

import asyncio
from openagents.agents.worker_agent import WorkerAgent
from openagents.models.event_context import EventContext


class TimerAgent(WorkerAgent):
    default_agent_id = "timer"

    async def react(self, context: EventContext):
        event = context.incoming_event
        if event.source_id == self.agent_id:
            return

        content = event.payload.get("content", "")
        if not content.lower().startswith("timer"):
            return  # 只处理 "timer ..." 开头的消息

        # 解析秒数
        parts = content.split()
        if len(parts) < 2:
            seconds = 3
        else:
            try:
                seconds = int(parts[1])
            except ValueError:
                seconds = 3

        messaging = self.client.mod_adapters.get(
            "openagents.mods.workspace.messaging"
        )

        # 告知开始计时
        if messaging:
            await messaging.send_channel_message(
                channel=event.payload.get("channel", "general"),
                text=f"Timer started: {seconds}s",
            )

        # 等待
        await asyncio.sleep(seconds)

        # 通知时间到
        if messaging:
            await messaging.send_channel_message(
                channel=event.payload.get("channel", "general"),
                text=f"Time's up! ({seconds}s)",
            )


if __name__ == "__main__":
    import asyncio
    agent = TimerAgent()
    asyncio.run(agent.setup())
    asyncio.get_event_loop().run_forever()
