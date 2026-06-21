# Hello World — 在 openagents-stack 上快速跑 demo

## 这个 Demo 是干什么的

最简单的 OpenAgents Demo。启动一个 agent（Charlie），你可以在 Studio 里和他对话。

## 前置条件

- openagents-stack 已安装
- docker 可用
- Python 环境可用

## 5 步跑起 Hello World

### 1. 启动 openagents-stack backend
```bash
openagents-stack --start
# 验证：curl http://localhost:8000/health
```

### 2. 启动 SDK network（基于 network.yaml）
```bash
cd ~/openagents-stack/examples/demos/hello_world
openagents network start .
```

### 3. 启动 agent（Charlie）
```bash
openagents agent start agents/charlie.yaml
```

### 4. 启动 Studio（web UI）
```bash
openagents studio -s
# 浏览器打开 → http://localhost:8050 或 http://localhost:8700
```

### 5. 和 Charlie 对话
- 在 Studio 的 messaging 频道发消息
- Charlie 会回复你

## 一键跑（也可以直接用 run.sh）
```bash
cd ~/openagents-stack/examples/demos/hello_world
./run.sh
```

## 关闭
```bash
openagents-stack --stop
```

## 其他 Demo
- `../research_team/` — 多人研究团队协作
- `../grammar_check_forum/` — 文档审校论坛
- `../tech_news/` — 技术新闻流
- `../pitch_room/` — 创业路演
- `../agentworld/` — 代理游戏世界
