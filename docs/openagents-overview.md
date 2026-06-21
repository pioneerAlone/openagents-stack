# openagents 全方位研究 — 综合应用指南

> 这是对 [openagents-org/openagents](https://github.com/openagents-org/openagents)
> 项目的全方位研究笔记。结合了：
>
> - **官网 + 文档**（22 个 docs/ 目录）
> - **SDK 源码**（sdk/src/openagents/，30 个 Python 文件）
> - **workspace backend**（你 6/19 11:21 部署的那个 Docker backend）
> - **Music-free 项目实践**（真实运行 5 个月，17 MB message dump）
> - **openagents-stack**（你自己的项目，pioneerAlone/openagents-stack）
>
> 目标：搞清楚 openagents 作为 "AI 代理互联网基础设施" 到底能做什么综合应用，
> 以及你的 openagents-stack 能接哪些综合应用。

---

## 1. 核心定位

### 1.1 一句话定义

> **openagents** 是一个开源的 "AI 代理网络" 框架，支持多个 AI 代理在持久的社区中
> 协作、共享资源、完成长期项目。提供 "代理互联网" 的基础设施。

### 1.2 三层结构

openagents 由三个独立但互补的产品组成：

| 产品 | 角色 | openagents-stack 状态 |
|---|---|---|
| **Workspace** | 协作层（人 + 代理聊天、文件、浏览器） | ✅ 已部署（8000 端口） |
| **Launcher** | 代理管理层（spawn、配置、连接） | ✅ 已安装 |
| **Network SDK** | 开发者层（Python SDK、协议、自定义 mod） | ❌ 未使用 |

你的 openagents-stack 走的是 "Workspace + Launcher 部署栈"；
Music-free 走的是 "Network SDK 开发栈"。两者互补。

### 1.3 与传统框架的本质区别

```
传统框架：单代理 + 单任务 = 一次性输出
openagents：多代理 + 人 + 持久网络 = 长期协作
```

---

## 2. 技术架构

### 2.1 五大层次

```
┌─────────────────────────────────────────┐
│  L1 应用层 (Studio / desktop app / 自建 UI)  │
├─────────────────────────────────────────┤
│  L2 协议层 (A2A / MCP / HTTP / gRPC / WS)  │
├─────────────────────────────────────────┤
│  L3 传输层 (5 种传输 + 5 种连接器)        │
├─────────────────────────────────────────┤
│  L4 事件层 (event_gateway + event_processor)  │
├─────────────────────────────────────────┤
│  L5 存储层 (workspace_manager + SQLite)     │
└─────────────────────────────────────────┘
```

### 2.2 25 个开箱即用 Mod（按类别）

openagents 提供 25 个 mod 包，按 9 大类组织：

| 类别 | 包 | 综合应用价值 |
|---|---|---|
| **communication** | messaging, simple_messaging | Slack/Discord 替代 |
| **coordination** | task_delegation | Jira/Linear 替代 |
| **core** | shared_cache | 文件/数据共享 |
| **discovery** | agent_discovery | 代理能力路由 |
| **games** | agentworld | AI 沙盒游戏 |
| **integrations** | n8n | No-code 工作流对接 |
| **work** | work | 项目管理 |
| **workspace** | default, documents, feed, forum, messaging, project, shared_artifact, wiki | 9 个工作区能力 |
| **test_mods** | basic_test | 测试 |

### 2.3 5 种传输 + 5 种连接器

| 传输 | 连接器 | 综合应用场景 |
|---|---|---|
| **HTTP** | http_connector | 本地快速测试 |
| **gRPC** | grpc_connector | 低延迟高吞吐（Music-free 用） |
| **WebSocket** | websocket_connector | 浏览器实时推送 |
| **A2A** | a2a_connector | 跨网络代理协作（Google 标准） |
| **MCP** | mcp 传输 | 接 Anthropic MCP 生态 |

### 2.4 事件系统（最底层基础设施）

**所有 mod 之间通信都靠事件**：

```
agent → emit event → event_processor → event_gateway → mod 监听
```

事件类型包括：
- `channel_message`（频道消息）
- `forum.topic.created`（论坛话题）
- `shared_cache.file.upload`（文件共享）
- `task.delegation.assigned`（任务委派）
- 等等

---

## 3. Music-free 项目实践分析

### 3.1 项目结构

```
Music-free/
├── main.py                          # 启 Python Network SDK
├── openagents/                      # fork 整个 openagents-org/openagents
│   ├── src/                         # SDK 源码
│   ├── studio/                      # ⭐ 自定义前端（修改了 3 个文件）
│   └── ...
├── music/
│   ├── network.yaml                 # 网络配置（HTTP + gRPC）
│   ├── mods/                        # 几乎为空（自己只 fork 没自写）
│   ├── events/                      # 几乎为空
│   ├── tools/                       # 几乎为空
│   ├── chat_ui.py                   # 自写的 FastAPI + HTML UI
│   └── agents/
│       ├── llm_agent.py             # LLM agent
│       ├── music_agent.py           # 音频分析
│       ├── sound_agent.py           # 音色合成
│       └── pitch.py                 # 音高检测
└── openagents.log                   # 5 MB 运行日志
```

### 3.2 关键发现

1. **他几乎不写自定义 mod / event / tool** — 全部用 SDK 开箱即用的 messaging + shared_cache
2. **他的所有业务代码都在 Python 代理里**（pitch.py、sound_agent.py）
3. **他自己写了前端**（FastAPI + HTML/JS）而不是用 Studio
4. **5 个月的历史**（17 MB message_dump）说明这是生产级项目，不只是 demo

### 3.3 他用的 5 个 SDK 接口

| SDK 接口 | Music-free 用法 |
|---|---|
| `Event(event_name, payload, relevant_mod)` | 上传文件到 shared_cache |
| `self.client.send_event(event)` | 派发事件 |
| `self.client.mod_adapters[...]` | 调 messaging / shared_cache mod |
| `self.workspace().channel(name).post()` | 发消息带文件 |
| `messaging.send_channel_message(channel, text)` | 发纯文本 |

### 3.4 他没做的事

- **没用** `task_delegation` mod（虽然这是协调多代理的关键）
- **没用** `wiki`、`forum`、`documents` mod（他的需求是音乐创作，不是知识沉淀）
- **没用** A2A 协议（单机部署）
- **没用** `n8n` 集成（虽然已经预留接口）

### 3.5 抽象出的通用模式

```
[人类客户端] → chat_ui → AgentClient → OpenAgents Network (8700/8600)
                                          ↓
                                  messaging mod (event bus)
                                          ↓
                  ┌─────────┬─────────┬─────────┐
                  ↓         ↓         ↓         ↓
              业务代理1  业务代理2  业务代理3  业务代理4
              (输入处理) (分析)   (输出生成) (数据抓取)
```

**核心：1 个入口 + 1 个网络 SDK + N 个代理 = 任何垂直领域 AI 服务**

---

## 4. 综合应用地图（4 个维度）

### 4.1 维度 1：按企业数字化层级

| 层级 | 开箱即用 Mod | 综合应用 |
|---|---|---|
| **沟通** | messaging + forum + feed | 企业 IM/论坛（替代 Slack/Discourse） |
| **知识** | wiki + documents + shared_cache | 企业 Wiki/Notion 替代 |
| **协作** | task_delegation + project | 项目管理（替代 Jira/Linear） |
| **代理** | WorkerAgent + LLM agents | 自动化业务流程 |

### 4.2 维度 2：按行业垂直应用

| 行业 | 综合应用设想 |
|---|---|
| **金融** | 研报自动化、风险监控、客户服务 |
| **医疗** | 诊疗辅助、文献回顾、多科会诊 |
| **教育** | 作文批改、学习社区、师资培训 |
| **政企** | 内部沟通、知识沉淀、舆情监控 |
| **开发** | 代码审查、CI 排错、接入 Claude Code/Aider |
| **创意** | 内容工作流、多模态管理 |
| **售后** | 多渠道客服、远程诊断、知识库 |

### 4.3 维度 3：按技术架构层

| 技术 | 文件 | 综合应用价值 |
|---|---|---|
| **A2A 协议** | a2a_registry.py, a2a_connector.py, a2a_task_store.py | 跨公司、跨平台代理互操作（Google 标准） |
| **MCP 传输** | transports/mcp.py | 接 Anthropic 的 Claude（Model Context Protocol） |
| **多网络** | network.py, workspace_manager.py | 一个网络支持多个工作区（多团队、多项目） |
| **事件路由** | event_gateway.py, event_processor.py | 可扩展事件系统 |
| **n8n 集成** | integrations/n8n/ | 接入 No-code 工作流 |

### 4.4 维度 4：按开发难度

| 开发者类型 | 综合应用门槛 |
|---|---|
| **非技术人员** | desktop app + 5 个开箱即用 launcher 集成 Claude/Aider |
| **Python 开发** | `pip install openagents` + 写 `WorkerAgent` 子类 |
| **企业架构师** | `network.yaml` 配置 + 25 个 Mod + 多网络部署 |
| **平台开发者** | 扩 SDK（自己写 mod/transports/connectors） |

---

## 5. 你的 openagents-stack 能接的 5 个综合应用

你的栈已经包含了：
- Docker backend（8000 端口）
- Launcher（桌面 app + agn CLI）
- Claude / hermes / opencode 3 个 agent（已配）

### 应用 1：个人 AI 助理群 ⭐

**难度**：简单  
**你已经会的事**：`agn create my-agent --type claude`

**架构**：

```
你的栈
├── launcher（已装）
├── docker backend（已起）
├── 3 个 agent（hermes/claude/opencode）
└── 扩展：
    ├── 日常助理 agent（hermes）- 写文档、回答问题
    ├── 代码审查 agent（claude）- review PR
    └── 浏览器自动化 agent（opencode）- 填表、抓数据
```

**实施**：直接 `agn create` 几个 agent 就行。

### 应用 2：小团队 AI 协作 ⭐⭐

**难度**：中等  
**要做的**：
1. 配置 forum + wiki + task_delegation mod
2. 创建 3-5 个 agent（PM/Dev/Reviewer/Test/Designer）
3. 团队通过 desktop app 进入同一个 workspace

**架构**：

```
你的栈 + 新增 mods
├── forum mod（团队讨论）
├── wiki mod（团队文档）
├── task_delegation mod（任务分配）
└── 3-5 个 agent
```

**综合应用**：企业 Slack + Notion + Jira + AI 代理四合一。

### 应用 3：垂直领域 AI 服务 ⭐⭐⭐

**难度**：较高  
**要做的**：复制 Music-free 模式到任何领域

```
你的 openagents-stack
+ 自定义 Python WorkerAgent（音乐/法律/医疗/教育...）
+ 自定义 FastAPI 前端（如果需要 web UI）
= 垂直领域 AI 服务
```

**10 个可套用的垂直场景**（基于 Music-free 模式）：

1. 音乐创作（Music-free 本体）
2. 法律文档审核（类比 grammar-check demo）
3. 学术研究团队（类比 research-team demo）
4. 电商客服多代理
5. 金融研报团队
6. 软件开发团队（PR 审查 + CI 排错）
7. 医疗辅助诊断
8. 教育作文批改
9. 多模态内容工作流（短视频/播客）
10. 软件项目管理

### 应用 4：跨组织代理联盟 ⭐⭐⭐⭐

**难度**：高  
**要做的**：
1. 部署你自己的网络（org A）
2. 对方也部署一个网络（org B）
3. 用 A2A 协议配置跨网络连接

**架构**：

```
你的网络（org A）
  └── 销售 agent
       ↑
       A2A 协议
       ↓
外部网络（org B）
  └── 库存 agent
```

### 应用 5：企业 AI 入口 ⭐⭐⭐⭐⭐

**难度**：最高  
**综合应用**：AI 办公助手 + 业务系统接入

**架构**：

```
公司全员
  └── Slack/钉钉/企业微信
       ↓
  openagents 网关（你的 openagents-stack）
       ↓
  ┌─────────┬─────────┬─────────┐
  IT agent  HR agent  财务 agent
  （查工单）（查薪资）（报销）
       ↓
  ┌─────────┬─────────┐
  │ 知识库  │ 业务系统  │
  └─────────┴─────────┘
```

---

## 6. 关键技术亮点

### 6.1 A2A 协议（Google 标准）

`task_delegation` mod 是 A2A 协议的实现：
- A2A Task model（双向任务委派：本地 + 远程）
- A2A TaskState（Pending/Running/Completed/Failed）
- A2A message history（进度报告）
- Timeout handling（自动超时）

**意义**：openagents 不只是自己玩（内部事件），还能和 Google 等公司的 A2A 代理互操作。

### 6.2 MCP 传输（Anthropic 标准）

`transports/mcp.py` 实现 MCP 协议：
- 可以接 Claude Desktop 的 MCP servers
- 可以接 Anthropic 的 Model Context Protocol 生态

**意义**：你的 openagents-stack 部署的网络可以被 Claude Desktop 当作 MCP server 用。

### 6.3 多网络支持

`workspace_manager.py` 实现多网络：
- 一个 openagents 进程可以跑多个网络
- 一个网络可以跑多个 workspace
- 一个 workspace 可以有多个 channel

**意义**：一个 4 GB RAM 的服务器可以支撑多个独立的代理社区。

---

## 7. 路径建议

### 7.1 立即能做（基于你的 openagents-stack）

1. ✅ 个人 AI 助理群 — `agn create` 几个 agent
2. ✅ 接入 MCP — 编辑 launcher 配置，让 Claude Desktop 能用你的网络

### 7.2 短期（1-2 周）

3. 写一个 `examples/agent-team/` 复刻 Music-free 的 4 代理模式
4. 写 `examples/integration/mcp-bridge/` 把 openagents 暴露为 MCP server

### 7.3 中期（1-2 月）

5. fork `studio/`（像 Music-free 那样）自定义前端
6. 配置 task_delegation + forum + wiki 跑小团队测试
7. 接 A2A 跨网络测试

### 7.4 长期（3+ 月）

8. 构建垂直领域 AI 服务（音乐/法律/医疗/教育）
9. 多网络部署（多租户 SaaS）
10. 贡献回上游 openagents-org

---

## 8. 与 openagents-stack 的关系

```
┌────────────────────────────────────────┐
│        openagents-org/openagents         │
│  (上游：网络 SDK + Mod 生态)           │
└────────────┬───────────────────────────┘
             │
             │ git clone (fork)
             ↓
┌────────────────────────────────────────┐
│     pioneerAlone/openagents-stack        │
│  (你的项目：Docker 部署栈)              │
│  - 部署 backend                         │
│  - 安装 launcher                        │
│  - 配 3 个 agent                        │
└────────────┬───────────────────────────┘
             │
             │ 扩展方向
             ↓
┌────────────────────────────────────────┐
│   你的综合应用                          │
│  - 个人 AI 助理群                      │
│  - 小团队协作                          │
│  - 垂直领域 AI 服务                    │
│  - 跨组织代理联盟                      │
│  - 企业 AI 入口                        │
└────────────────────────────────────────┘
```

**你的栈** = 部署基础设施  
**上游 SDK** = 应用开发能力  
**综合应用** = 你的栈能跑的实际业务

---

## 9. 结论

> **openagents 已经走过了"从实验室到产品"的转折点。**

- **技术层面**：5 种传输 + 25 个 Mod + A2A/MCP 标准支持——足够稳固
- **应用层面**：25 个 Mod 能覆盖 "企业 + 个人 + 垂直" 三大类综合应用
- **生态层面**：Music-free 证明了开发者能用 SDK 做出真正的产品
- **部署层面**：你的 openagents-stack 已经是 "可部署、已运行" 的栈

**openagents 的真正价值**：

> 它不是 "又一个聊天框"，是 **"代理们的微信 + GitHub + Notion + Jira + Slack + MCP + A2A 的综合体"**。

**5 类综合应用清单**：

| 难度 | 应用 | 你的栈能立刻做 |
|---|---|---|
| ⭐ | 个人 AI 助理群 | ✅ 能 |
| ⭐⭐ | 小团队协作 | 加 mod 配置 |
| ⭐⭐⭐ | 垂直领域 AI | 复刻 Music-free |
| ⭐⭐⭐⭐ | 跨组织代理联盟 | 配 A2A |
| ⭐⭐⭐⭐⭐ | 企业 AI 入口 | 接 Slack/钉钉 |

---

## 10. 参考资料

- **上游仓库**：<https://github.com/openagents-org/openagents>
- **官网**：<https://openagents.org>
- **官方文档**：<https://openagents.org/docs/getting-started/overview>
- **Music-free 实践**：<https://github.com/ccwwhhh/Music-free>
- **你的项目**：<https://github.com/pioneerAlone/openagents-stack>

---

*本文档基于 2026-06-19 之后的官方仓库 develop 分支研究编写。*
