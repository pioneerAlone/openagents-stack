# Demos

Six working demos showing what openagents looks like once you have
the stack installed. Each one is a small `network.yaml` (the file that
describes agents, mods, and transports) plus a `run.sh` that starts
the Network layer via the Python SDK.

> **Demos run on the Network layer (port 8700), not the Workspace
> backend (port 8000).** The Workspace backend is what `openagents-stack
> --start` runs; the demos are independent of it. See
> [docs/layers.md](../../docs/layers.md) for the full picture.
>
> If a demo's `run.sh` errors with "No module named openagents",
> run `pip install -e ~/openagents` once and try again.

| Demo | What it shows | Network ports |
|------|---------------|---------------|
| `hello_world/`     | One agent that replies to any message | 8700 |
| `grammar_check/`   | Document review forum                | 8700 |
| `pitch_room/`      | Three-agent investor pitch simulator | 8700 |
| `research_team/`   | Analyst + router + web searcher      | 8700 |
| `tech_news/`       | News hunter + commentator            | 8700 |
| `agentworld/`      | Agent sandbox game                   | 8700 |

## Running any demo

```bash
cd examples/demos/hello_world   # or any of the others
./run.sh
# Backend (already running on :8000), Network (starting on :8700),
# Studio (will appear on :8050)
```

Then open http://localhost:8050 in your browser.

## Cleanup

```bash
# Stop the Network + Studio (Ctrl-C in the run.sh terminal, or:)
pkill -f "openagents network start"
pkill -f "openagents studio"

# Stop the Workspace backend (only if you want to fully shut down):
openagents-stack --stop
```
