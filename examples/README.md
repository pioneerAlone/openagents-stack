# Examples — 4 种类,各管一摊

`examples/` 里有 54 个文件,但**不是**平铺的 53 个独立 demo — 它们是
4 种不同用途的入口,选你需要的那一类看就行。

| 类别 | 文件数 | 你想做什么时看它 |
|------|--------|------------------|
| [demos/](#demos)         | 6 + 1 README | 跑一个**完整的多 agent 协作场景**,在 Studio 里玩 |
| [mods/](#mods)           | 15 + 1 README | 给你的 workspace backend **加一个能力**(forum / wiki / feed / 文档…) |
| [agents/](#agents)       | 3 + 1 README | **写自己的 agent** — 3 个由简到难的 Python 例子 |
| quickstart-*.sh          | 3            | 1 行命令跑 setup,适合新装时用 |
| create-agents.example.sh | 1            | 用 CLI 批量建 workspaces + agents(现在被 `openagents-stack --workspaces` 取代) |
| troubleshoot.sh          | 1            | 出问题时的 5 步排查 |

> **第一次用?** → 跳过本目录,直接跑 `openagents-stack --check` 看后端
> 起了没;后端起来后 → 跑 `examples/demos/hello_world` 是最快验证全链路的方法。

---

## demos

6 个**完整可跑**的多 agent 协作场景。每个 demo 是一份 `network.yaml`
(描述 agents + mods + transports) + 一个 `run.sh`(起 Network + Studio)。

| Demo | 场景 | 适合 |
|------|------|------|
| [hello_world/](demos/hello_world/)     | 1 个 agent 收到任何消息都回 | 第一次跑,**验证 install** |
| [grammar_check/](demos/grammar_check/)   | 3 个 agent 互相审校文档       | 看 mod pattern |
| [pitch_room/](demos/pitch_room/)        | founder / engineer / investor 3 人模拟路演 | 看多角色协作 |
| [research_team/](demos/research_team/)  | router + analyst + web_searcher | 看 router pattern |
| [tech_news/](demos/tech_news/)          | 定时抓 news + commentator 评论 | 看定时任务 |
| [agentworld/](demos/agentworld/)        | 代理游戏世界                 | 看复杂 mod 编排 |

### 跑任意 demo(同一个流程)

```bash
cd examples/demos/hello_world   # 或任何其他
./run.sh
```

`run.sh` 会:
1. 检查/装 openagents SDK(`pip install -e ~/openagents`,只装一次)
2. 调 `openagents-stack --start` 拉起 Workspace backend (port 8000)
3. 起 Network layer (port 8700) — `python3 -m openagents network start`
4. 起 1-N 个 agent(从 `network.yaml` 读)
5. 起 Studio (port 8050)

浏览器开 [http://localhost:8050](http://localhost:8050) 就能玩。

> 端口和层的关系不清楚?看 [../docs/layers.md](../docs/layers.md)。

### 清理

```bash
# 停 Network + Studio
pkill -f "openagents network start"
pkill -f "openagents studio"

# 停 Workspace backend
openagents-stack --stop
```

---

## mods

15 份**启用指南**,每份教你**给 backend 加一个 mod**。

| Mod 类别 | 数量 | 文件 |
|---------|------|------|
| workspace   | 8 | `enable_default` `enable_messaging` `enable_documents` `enable_project` `enable_wiki` `enable_forum` `enable_feed` `enable_shared_artifact` |
| communication | 2 | `enable_simple_messaging` `enable_messaging` |
| core / shared | 2 | `enable_shared_cache` `enable_task_delegation` |
| discovery / games / integrations / work | 4 | `enable_agent_discovery` `enable_agentworld` `enable_n8n` `enable_work` |

每份文件是 4 步指南:
1. 编辑 monorepo 配置
2. 注册 mod
3. 重启 backend
4. 验证

```bash
# 例子:启用 forum mod
cat examples/mods/enable_forum.md
# 跟着 4 步做完
openagents-stack --restart
```

---

## agents

3 个 Python 文件,从简到难展示**怎么写自己的 agent**(WorkerAgent 接口)。

| 文件 | 难度 | 学什么 |
|------|------|--------|
| [echo_agent.py](agents/echo_agent.py)    | ⭐   | 最小 WorkerAgent — 收到消息就回 |
| [timer.py](agents/timer.py)             | ⭐⭐  | 定时器 agent — 接入事件循环 |
| [calculator.py](agents/calculator.py)   | ⭐⭐⭐ | LLM 集成 — 调 Claude/GPT 做算术 |

```bash
# 跑 echo_agent
pip install -e ~/openagents   # 装 SDK
python3 examples/agents/echo_agent.py
```

详细: [agents/README.md](agents/README.md)

---

## 4 个 quickstart / troubleshoot 脚本

| 脚本 | 干嘛的 | 何时跑 |
|------|--------|--------|
| [quickstart.sh](quickstart.sh)         | 1 行装 + 跑 hello_world | 全新安装时 |
| [quickstart-lan.sh](quickstart-lan.sh) | 同上,但走 LAN-team 配置 | 多台机器共享 backend |
| [quickstart-enterprise.sh](quickstart-enterprise.sh) | 同上,但走 enterprise 配置(nginx + 自签证书) | 公司部署 |
| [troubleshoot.sh](troubleshoot.sh)     | 5 步排查(Docker / backend / 网络 / agent / config) | 哪里挂了时 |

```bash
# 全新安装
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/install.sh | bash
# 安装后一键跑
./examples/quickstart.sh

# 出问题
./examples/troubleshoot.sh
```

---

## 跟"现在装好的 backend"交互

不需要进 examples/ 也能:

```bash
# 看 backend 状态
openagents-stack --status
openagents-stack --check

# 拿 Quick-connect URL(workspace slug + token,paste 进 Launcher 就能连)
openagents-stack --workspaces

# 升级
openagents-stack --upgrade
```

详见 `openagents-stack --help`。
