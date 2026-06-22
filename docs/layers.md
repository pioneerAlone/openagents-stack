# Workspace vs Network vs SDK — three layers, one monorepo

If you've looked at the openagents monorepo and gotten confused about
which "thing" you actually need, you're not alone. The monorepo
contains three independent products that share a single git repo but
are otherwise separate codebases, separate processes, and separate
ports.

```
┌──────────────────────────────────────────────────────────────┐
│  Studio  (web UI)           http://localhost:8050 (sdk)      │
│                                                              │
│  ─── openagents-stack doesn't manage this ───                │
├──────────────────────────────────────────────────────────────┤
│  Network layer  (port 8700/8600)                             │
│  • HTTP transport (serves Studio + MCP at /studio /mcp)      │
│  • gRPC transport (high-throughput agent comms)              │
│  • network.yaml defines agents + mods + transports           │
│  • Started by: `python -m openagents network start <dir>`    │
│  • Used by:    hello_world / pitch_room / research_team /    │
│                agentworld / tech_news / grammar_check demos  │
│  • Source:      monorepo/ + packages/launcher                 │
├──────────────────────────────────────────────────────────────┤
│  Workspace backend  (port 8000)  ← openagents-stack manages  │
│  • FastAPI + Postgres + alembic migrations                   │
│  • Launcher talks to it via OPENAGENTS_ENDPOINT              │
│  • Holds workspace metadata (slugs, password hashes, etc.)   │
│  • Started by: `openagents-stack --start`                    │
│  • Source:      monorepo/workspace/                          │
├──────────────────────────────────────────────────────────────┤
│  Launcher  (agn CLI + menu-bar app)                          │
│  • Owns agents (claude-1, hermes-worker, …)                  │
│  • Connects agents to workspace + network                    │
│  • Lives outside Docker (installed on your machine)          │
│  • Started by: `agn up`                                      │
└──────────────────────────────────────────────────────────────┘
```

## Which layer does what

| You want to…                                  | Need         | Command                          |
|-----------------------------------------------|--------------|----------------------------------|
| Run the launcher + connect agents to backend  | Launcher + Workspace | `openagents-stack --start` then `agn up` |
| Run a multi-agent demo (hello_world, etc.)   | Network + SDK | `pip install -e ~/openagents && ./run.sh` |
| See Studio in your browser                    | Network (auto-spawns with `network start`) | `python -m openagents studio` |
| Reset the Postgres database                   | Workspace    | `openagents-stack --clean`       |
| Reset all your agents and tokens              | Launcher     | delete `~/.openagents/`          |

## What `openagents-stack --start` does NOT do

- It does **not** start the Network layer (port 8700). That's done by
  the demo's `run.sh` via the Python SDK.
- It does **not** start Studio. Studio is a Python process from the
  SDK (`python -m openagents studio -s`).
- It does **not** install the Python SDK. Demos that need the SDK
  pip-install the monorepo themselves (see `examples/demos/*/run.sh`).

The reason: openagents-stack wraps the **Workspace backend** (the
piece that needs Docker, Postgres, alembic — the hard part). The
Network layer is plain Python and pip-installs in seconds, so demos
handle it inline. Mixing the two responsibilities into one orchestrator
would bloat the install for everyone who only needs the backend.

## Mental model

> "openagents-stack gets you a running **workspace** to manage. Demos
> spin up a **network** on top to show what the workspace manages."

If you only care about deploying the backend and connecting the
launcher, you never need to think about Network or Studio — they
appear automatically when you start a demo. If you care about
shipping a custom network, you only need the SDK and a network.yaml,
no openagents-stack at all.

## Port reference

| Port | Layer      | Started by                                 |
|------|------------|--------------------------------------------|
| 8000 | Workspace  | `openagents-stack --start`                 |
| 8050 | Studio     | `python -m openagents studio -s`           |
| 8600 | Network gRPC | demo's `run.sh`                          |
| 8700 | Network HTTP (Studio + MCP) | demo's `run.sh`         |

If you see "port already in use", use `lsof -iTCP:PORT -sTCP:LISTEN`
to find the previous owner; it's almost always the layer above.
