# Quickstart — 5 分钟跑起 openagents-stack

## 一键安装

```bash
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/install.sh | bash
```

安装后会自动：
1. Clone openagents-stack 到 `~/openagents-stack`
2. 创建 `~/.local/bin/openagents-stack` symlink
3. 加入 PATH 到 `~/.zshrc`
4. 运行 setup（装依赖）
5. 启动 backend

## 5 分钟跑起

```bash
# 1. 验证 backend
curl http://localhost:8000/health

# 2. 跑 hello_world demo
cd ~/openagents-stack/examples/demos/hello_world
./run.sh

# 3. 在浏览器打开 Studio
# http://localhost:8050
```

## 试试其他 Demo

```bash
cd ~/openagents-stack/examples/demos/research_team && ./run.sh
cd ~/openagents-stack/examples/demos/grammar_check && ./run.sh
cd ~/openagents-stack/examples/demos/tech_news && ./run.sh
cd ~/openagents-stack/examples/demos/pitch_room && ./run.sh
cd ~/openagents-stack/examples/demos/agentworld && ./run.sh
```

## 写自己的 Agent

```bash
# 30 分钟学会：3 个通用示例
ls ~/openagents-stack/examples/agents/
# echo_agent.py  - 回声明机器人
# calculator.py  - LLM 计算器
# timer.py       - 计时器

# 运行
python3 ~/openagents-stack/examples/agents/echo_agent.py
```

## 启用各种 Mod

```bash
ls ~/openagents-stack/examples/mods/
# 15 个 .md 文件 — 4 步启用各种 Mod
# forum、wiki、feed、documents、project、messaging 等
```

## 3 种部署模式

| 模式 | 时间 | 一行命令 |
|------|------|----------|
| 本地 | 5 分钟 | `curl .../deployments/local-personal/install.sh \| bash` |
| 局域网 | 6 分钟 | `curl .../deployments/lan-team/install.sh \| bash` |
| 企业 | 35 分钟 | `curl .../deployments/enterprise/install.sh \| bash` |

## 关闭

```bash
openagents-stack --stop
```

## 下一步

- 看 [docs/deployment/local-personal.md](deployment/local-personal.md) — 部署模式详解
- 看 [docs/architecture.md](architecture.md) — 架构详解
- 看 [README.md](../README.md) — 项目概览
