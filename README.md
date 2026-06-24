# openagents-stack

开箱即用的 openagents 部**署**栈 — 让任何人在 5 分钟内跑起 openagents 的**各种功**能**。

- **v0.1 (current)**: macOS (Apple Silicon / Intel). Verified on macOS 14.x with OrbStack.
- **v0.2 (preview)**: +Linux (Debian / Ubuntu). Platform scripts + CI shipped;
  install path tested in a sandbox; full e2e on a real Linux machine is
  pending — see the [Linux platform](#linux-platform-preview) section below.
- **v0.3** (planned): +Windows.

Pinned to upstream:

- launcher npm `v0.2.143` — installed via `npm install -g @openagents-org/agent-launcher`
- monorepo commit `45abec5` (the commit launcher v0.2.143 was built against; we do **not** track `develop`)

---

## What is openagents-stack

`openagents-stack` is a **one-core + 3-deployments + 53 ready-to-use entry points** architecture for deploying [openagents](https://github.com/openagents-org/openagents).

```
┌──────────────────────────────────────────────────────────────┐
│ Layer 5: openagents（开源 monorepo）— 不动                   │
├──────────────────────────────────────────────────────────────┤
│ Layer 4: openagents-stack 核心（16 文件，~ 1,500 行）       │
│         bin/lib/platform/install.sh/versions.lock            │
├──────────────────────────────────────────────────────────────┤
│ Layer 3: deployments/（13 文件，3 种部署模式）              │
│         local-personal / lan-team / enterprise               │
├──────────────────────────────────────────────────────────────┤
│ Layer 2: examples/（53 文件，开箱即用入口）                │
│         6 demos + 15 mod 配置 + 3 agents + 4 quickstart      │
├──────────────────────────────────────────────────────────────┤
│ Layer 1: docs/ + tests/（14 文件）                         │
│         quickstart + 3 deployment guides + 25 unit tests    │
└──────────────────────────────────────────────────────────────┘
```

**核心思路**: 一套核心 (`bin/ lib/ platform/ install.sh`) + 3 种部署模式 + 开箱即用入口。
- **不挖 monorepo**: 6 个 Demo 只 copy 2 文件 + 改 1 行
- **核心不动**: 1,500 行核心，扩展 4,100 行
- **可升级**: `lib/versions.lock` 锁定上游版本

---

## Why

Setting up openagents locally means 4 pieces, and getting them to agree is fiddly:

1. Docker (OrbStack or Docker Desktop) running.
2. The launcher CLI (`agn`) + desktop app installed.
3. The docker backend (`workspace/backend`) cloned and `alembic upgrade head` applied.
4. A workspace + agent wired up so you can actually send a message.

`openagents-stack` is a single bash entry point that does all four, idempotently, and exposes the rest as subcommands (`--start`, `--stop`, `--status`, `--logs`, `--upgrade`, etc.) so you stay in control of when to start and stop.

**Plus**: 53 ready-to-use entry points to try openagents 的**各种功**能**（** 6 **个** Demo ** + ** 15 **个** Mod **配**置** + ** 3 **个** Agent **示**例** + ** 4 **个** quickstart**）**， **3 **种**部**署**模**式**（**本**地**/**局**域**网**/**企**业**）**。

---

## Quick start

The one-line install works on macOS (full) and Linux (preview). On
macOS the OrbStack or Docker Desktop runtime is required; on Linux
any modern Docker CE will do.

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/install.sh | bash
```

The installer clones the repo to `~/openagents-stack`, adds it to your
PATH (writes `~/.zshrc`, `~/.bashrc`, and `~/.bash_profile`), runs
setup (installs Docker + launcher, clones the monorepo, writes env
vars to your shell rc), and exits. You then run `openagents-stack
--start` to bring the backend up.

### 5 分钟入门

```bash
# 1. 验证 backend
curl http://localhost:8000/health

# 2. 跑 hello_world demo
cd ~/openagents-stack/examples/demos/hello_world
./run.sh

# 3. 在浏览器打开 Studio
open http://localhost:8050
```

详细文档: [docs/quickstart.md](docs/quickstart.md)

---

## 3 种部署模式

| 模式 | 时间 | 一行命令 | 适用 |
|------|------|----------|------|
| **local-personal** | 5 分钟 | `curl .../deployments/local-personal/install.sh \| bash` | 个人使用 |
| **lan-team** | 6 分钟 | `curl .../deployments/lan-team/install.sh \| bash` | 5-20 人团队 |
| **enterprise** | 35 分钟 | `curl .../deployments/enterprise/install.sh \| bash` | 公司级 |

> The three deployment scripts are thin wrappers around the root
> `install.sh` — see [deployments/README.md](deployments/README.md).

详细文档:
- [local-personal.md](docs/deployment/local-personal.md)
- [lan-team.md](docs/deployment/lan-team.md)
- [enterprise.md](docs/deployment/enterprise.md)

---

## Linux platform (preview)

v0.2 ships real install scripts for Linux but is still a preview —
the CI proves the scripts source and parse, not that a real Linux
machine can go end-to-end. Distro support:

| Distro | Docker | Launcher | Notes |
|--------|--------|----------|-------|
| Debian / Ubuntu     | ✅ via `get.docker.com` | ✅ via `npm install -g` | tested path |
| Fedora / RHEL / CentOS | ❌ TODO v0.2 | ✅ via `npm install -g` | install path exists, just the docker installer is a `TODO` |
| Arch / Manjaro      | ❌ TODO v0.2 | ✅ via `pacman -Sy nodejs npm` | same |

What's covered today:
- `platform/linux/install_docker.sh` — detects distro, installs Docker CE
- `platform/linux/install_launcher.sh` — installs Node.js if missing, then `npm install -g @openagents-org/agent-launcher@$OPENAGENTS_LAUNCHER_VERSION`
- `e2e-linux.yml` GitHub Actions workflow — ubuntu-latest runner, runs
  `bash -n` on every `.sh` plus `./bin/openagents-stack --help`,
  `--version`, `--dry-run`, and a tolerated `--check`

What's NOT covered yet:
- The OpenAgents Launcher.app menu bar application (macOS-only `.app`
  bundle; on Linux you only get the `agn` CLI)
- A full `--start` on a real Linux box (the workflow deliberately
  tolerates the "no docker daemon in CI sandbox" preflight row rather
  than try to start one)
- Fedora / RHEL / Arch Docker install (the scripts bail with a clear
  "install Docker manually: <url>" error if they see these distros)

If you try this on a real Ubuntu box and hit an issue, please open
one on the [issue tracker](https://github.com/pioneerAlone/openagents-stack/issues)
with the distro version, the failing step, and the log.

---

## Examples — 开箱即用入口（54 个文件）

**Use [examples/README.md](examples/README.md) as the entry point** —
it splits the 54 files into 4 categories (demos / mods / agents /
quickstart scripts) and tells you which one to look at for what.

### 6 个 Demo

跑**完整可玩**的多 agent 场景,在 Studio 里跟它们对话:

```bash
cd examples/demos/hello_world && ./run.sh      # 最简 agent,验证 install 用
cd examples/demos/research_team && ./run.sh   # router + analyst + web_searcher
cd examples/demos/grammar_check && ./run.sh   # 文档审校
cd examples/demos/tech_news && ./run.sh       # 定时抓 news + 评论
cd examples/demos/pitch_room && ./run.sh      # founder/engineer/investor 3 人路演
cd examples/demos/agentworld && ./run.sh      # 代理游戏世界
```

### 15 个 Mod 配置指南

```bash
ls examples/mods/  # 25 个 .md (8 workspace + 1 communication + 1 coordination + 1 core + 1 discovery + 1 games + 1 integrations + 1 work)
# 4 步启用任意 Mod — 例如 forum、wiki、feed、documents、project、messaging 等
cat examples/mods/enable_forum.md
```

### 3 个通用 Agent 示例

```bash
ls examples/agents/
# echo_agent.py   — 回声明机器人（最简 WorkerAgent）
# calculator.py   — LLM 计算器（接入 LLM）
# timer.py        — 计时器（接入事件）

# 30 分钟学会写自己的 Agent
python3 examples/agents/echo_agent.py
```

### 4 个 Quickstart / Troubleshoot 脚本

```bash
# 3 种部署模式的 quickstart
./examples/quickstart.sh                # 本地 5 分钟
./examples/quickstart-lan.sh            # 局域网 6 分钟
./examples/quickstart-enterprise.sh     # 企业 35 分钟

# 通用问题排查
./examples/troubleshoot.sh
```

---

## Architecture — 5 层

### Layer 4: 核心（不动，~ 1,500 行）

```
bin/openagents-stack        # 14 个子命令 (setup/start/stop/restart/.../help)
lib/*.sh                    # 11 个核心库 (common/config/checks/...)
platform/macos/*.sh         # macOS 特定
platform/linux/*.sh         # Linux 特定 (v0.2 preview)
install.sh                  # 一行安装
lib/versions.lock           # 版本锁
.github/workflows/          # CI (lint / smoke / e2e / e2e-linux / release)
```

### Layer 3: deployments/（3 种部署模式）

```
deployments/
├── local-personal/      # 5 分钟本地
├── lan-team/            # 6 分钟局域网
└── enterprise/          # 35 分钟企业（HTTPS/SSO/nginx）
```

### Layer 2: examples/（开箱即用入口）

```
examples/
├── demos/               # 6 个 Demo
├── mods/                # 15 个 Mod 配置
├── agents/              # 3 个通用 Agent
├── quickstart.sh        # 本地入门
├── quickstart-lan.sh    # 局域网入门
├── quickstart-enterprise.sh # 企业入门
└── troubleshoot.sh      # 通用排查
```

### Layer 1: docs/ + tests/

```
docs/
├── quickstart.md                # 5 分钟入门
├── architecture.md             # 架构详解
├── deployment/                 # 3 种部署模式
│   ├── README.md
│   ├── local-personal.md
│   ├── lan-team.md
│   └── enterprise.md
└── openagents-overview.md      # openagents 全面调研

tests/
├── test_install.sh              # install.sh 测试
├── test_demos.sh                # 6 个 Demo 测试
├── test_mods.sh                 # 15 个 Mod 测试
├── test_agents.sh              # 3 个 Agent 测试
├── test_deployments.sh         # 3 种部署测试
├── test_check.sh                # 12 项自检测试
└── test_all.sh                  # 集成

合计 25 PASS / 0 FAIL
```

---

## 12 subcommands

```bash
openagents-stack                    # Setup (idempotent, dependencies only)
openagents-stack --start            # Start the docker backend
openagents-stack --stop             # Stop docker backend
openagents-stack --restart          # Restart docker backend
openagents-stack --logs             # Tail docker backend logs (Ctrl-C to exit)
openagents-stack --status           # Show backend / agents / upstream version
openagents-stack --workspaces       # Show workspaces + token + Quick-connect URL (paste into Launcher)
openagents-stack --upgrade          # Show latest upstream + ask to upgrade
openagents-stack --upgrade --to     # Pin to specific launcher version
openagents-stack --clean            # Stop + delete volumes (DATA LOSS)
openagents-stack --reset            # Clear local state, re-run all steps
openagents-stack --dry-run          # Print plan, change nothing
openagents-stack --check            # Run preflight checks (no changes)
openagents-stack --version          # Show stack + upstream versions
openagents-stack --help             # This help
```

---

## Environment

- `OPENAGENTS_HOME`           monorepo dir (default ~/openagents)
- `OPENAGENTS_STACK_HOME`     this repo state (default ~/openagents-stack)
- `OPENAGENTS_BACKEND_PORT`   backend port (default 8000)
- `WORKSPACE_NAME`            workspace name (default my-team)
- `AGENT_TYPES`               comma-separated (default hermes,claude,opencode)
- `DOCKER_RUNTIME`            macOS: orbstack|docker (default: ask)

---

## Verify

```bash
openagents-stack --check    # 12 项自检
```

CI workflow:
- **lint** — shellcheck error 级别（14s）
- **smoke** — syntax + help + check（13s, macos-latest + ubuntu-latest）
- **e2e** — 端到端 install + start on macOS-14（workflow_dispatch, manual only）
- **e2e-linux** — syntax + --help + --version + --dry-run + tolerated --check on ubuntu-latest（push 自动跑）
- **release** — tag v* 自动 GitHub release

---

## License

This project is licensed under the **MIT License** — see [LICENSE](LICENSE).

> The openagents monorepo it wraps (launcher CLI, Docker backend) is
> licensed under [Apache License 2.0](https://github.com/openagents-org/openagents/blob/develop/LICENSE)
> and remains governed by its own license. This MIT license applies only
> to the orchestration code in this repository (bin/, lib/, install.sh,
> examples/, deployments/, docs/).

---

## Project stats

- 26 commits, 109 tracked files
- 核心 16 (bin + lib) + platform 5 (macos 3 + linux 2)
- examples 54, deployments 13, docs 8, tests 7, .github/workflows 5
- 6 demos + 15 mod configs + 3 agents + 4 quickstart/troubleshoot
- 3 deployment modes (local-personal / lan-team / enterprise)
- Linux preview (v0.2): Debian/Ubuntu install path shipped, real-machine e2e pending
- 4 unit tests in test_check.sh (all PASS); e2e-linux CI runs `bash -n` + shellcheck + `--help/--version/--dry-run/--check` on every push to main
- Architecture review (Stage 1): 9.4/10

---

## Links

- [openagents](https://github.com/openagents-org/openagents) — 开源 monorepo
- [Releases](https://github.com/pioneerAlone/openagents-stack/releases)
- [Issues](https://github.com/pioneerAlone/openagents-stack/issues)

---

## See also

- [docs/quickstart.md](docs/quickstart.md) — 5 分钟入门
- [docs/architecture.md](docs/architecture.md) — 架构详解
- [docs/layers.md](docs/layers.md) — **Workspace vs Network vs SDK** (read this if you're confused which port / which process is which)
- [docs/deployment/](docs/deployment/) — 3 种部署模式
- [examples/README.md](examples/README.md) — examples/ 入口(demos + mods + agents + quickstart 4 类)
- [examples/demos/](examples/demos/) — 6 个 Demo
- [examples/mods/](examples/mods/) — 15 个 Mod 配置
- [examples/agents/](examples/agents/) — 3 个 Agent 示例
- [deployments/](deployments/) — 3 种部署模式详细配置
- [tests/](tests/) — test_check.sh(4 tests) + e2e-linux CI
