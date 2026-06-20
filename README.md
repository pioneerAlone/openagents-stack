# openagents-stack

One-click local setup for [openagents](https://github.com/openagents-org/openagents): launcher, docker backend, workspace, agents.

- **v0.1**: macOS only (Apple Silicon / Intel). Verified on macOS 14.x with OrbStack.
- **v0.2** (planned): +Linux.
- **v0.3** (planned): +Windows.

Pinned to upstream:

- launcher `v0.8.6` (verified working 2026-06-19)
- monorepo commit `45abec5` (the commit `launcher-v0.8.6` was built against; we do **not** track `develop`)

---

## Why

Setting up openagents locally means four pieces, and getting them to agree is fiddly:

1. Docker (OrbStack or Docker Desktop) running.
2. The launcher CLI (`agn`) + desktop app installed.
3. The docker backend (`workspace/backend`) cloned and `alembic upgrade head` applied.
4. A workspace + agent wired up so you can actually send a message.

`openagents-stack` is a single bash entry point that does all four, idempotently, and exposes the rest as subcommands (`--start`, `--stop`, `--status`, `--logs`, `--upgrade`, etc.) so you stay in control of when to start and stop.

---

## Quick start (macOS)

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/install.sh | bash
```

This installs the repo to `~/openagents-stack`, symlinks `bin/openagents-stack` into `~/.local/bin`, adds `~/.local/bin` to your `PATH` (in `~/.zshrc`), and runs the dependency installer. After this, **any new terminal** can run:

```bash
openagents-stack --check
openagents-stack --start
openagents-stack --status
openagents-stack --logs
```

No `cd`, no `source ~/.zshrc`, no full path.

### Prerequisites

- macOS (Apple Silicon or Intel)
- [Homebrew](https://brew.sh)
- git, curl
- Either [OrbStack](https://orbstack.dev) **or** Docker Desktop for Mac (OrbStack is recommended; lighter and faster on macOS)

### Manual install (alternative to the one-liner)

If you'd rather clone manually:

```bash
git clone https://github.com/pioneerAlone/openagents-stack.git ~/openagents-stack
cd ~/openagents-stack
./install.sh   # does what the one-liner does, but interactively
```

Or, if you only want the script in your PATH without running the dependency installer:

```bash
git clone https://github.com/pioneerAlone/openagents-stack.git ~/openagents-stack
mkdir -p ~/.local/bin
ln -sf ~/openagents-stack/bin/openagents-stack ~/.local/bin/
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
# new terminals now have `openagents-stack` available
```

### Start the backend

```bash
# Bring up db + backend containers, run alembic migrations
openagents-stack --start
```

The backend listens on `http://localhost:8000`. The launcher desktop app can now point at it.

### Create a workspace + agents

Workspaces and agents are intentionally **not** created by setup. You do this via the launcher desktop app, or via the CLI:

```bash
# Edit examples/create-agents.example.sh if you want different defaults, then:
bash examples/create-agents.example.sh
```

### Verify anytime

```bash
openagents-stack --check   # 12 preflight checks
openagents-stack --status  # backend / agents / upstream version
openagents-stack --logs    # tail backend logs (Ctrl-C to exit)
```

---

## Commands

| Command | What it does |
|---|---|
| `(default)` | Full setup (idempotent: install deps, clone monorepo, write env vars) |
| `--check` | Run preflight checks, change nothing |
| `--start` | Start the docker backend (db + backend containers + migrations) |
| `--stop` | Stop the docker backend |
| `--restart` | Restart the docker backend |
| `--logs` | Tail docker backend logs (Ctrl-C to exit) |
| `--status` | Show backend / agents / upstream version |
| `--upgrade` | Show latest upstream + ask to upgrade launcher/monorepo |
| `--upgrade --to <tag>` | Pin to a specific launcher tag |
| `--clean` | Stop backend + delete volumes (**DATA LOSS**) |
| `--reset` | Clear local state file, re-run all steps |
| `--dry-run` | Print what setup would do, change nothing |
| `--help` | This list |

---

## Paths (override via env vars)

| Path | Default | Env var |
|---|---|---|
| Monorepo (cloned) | `~/openagents/` | `OPENAGENTS_HOME` |
| Repo state (logs, cache, state file) | `~/openagents-stack/` | `OPENAGENTS_STACK_HOME` |
| Launcher data | `~/.openagents/` | (owned by launcher, not by us) |
| Docker compose project | `openagents` | (hardcoded) |
| Backend port | `8000` | `OPENAGENTS_BACKEND_PORT` |
| Default workspace name | `my-team` | `WORKSPACE_NAME` |
| Default agent types | `hermes,claude,opencode` | `AGENT_TYPES` |

Cache and lock files live under `OPENAGENTS_STACK_HOME`:

```
~/openagents-stack/
├── deploy.log               # append-only log of every step
├── .deploy-state            # one line per completed step (idempotency)
├── upgrade.lock             # held during --upgrade
└── cache/                   # downloaded .dmg/.deb artifacts
```

---

## How the launcher tracks backend health

The launcher desktop app probes `GET /v1/events` and `GET /v1/workspaces` to render state. The backend does **not** expose `/api/health`. So `openagents-stack` probes six endpoints and considers the backend healthy if **any** of them returns 2xx:

```
/health         (upstream default)
/api/health     (older versions)
/api/v1/health  (older versions)
/healthz        (k8s convention)
/v1/events      (what launcher actually hits)
/api/v1/events  (older)
```

If you see `Backend did not come up after 60s`, check `~/openagents-stack/deploy.log` and `docker compose -p openagents logs backend`.

---

## Pinned versions (don't follow develop)

`lib/versions.lock`:

```
OPENAGENTS_LAUNCHER_TAG="launcher-v0.8.6"
OPENAGENTS_MONOREPO_COMMIT="45abec5"
OPENAGENTS_MONOREPO_BRANCH="develop"
```

The launcher tag is the GitHub release tag the launcher app was downloaded from. The monorepo commit is the exact git commit that launcher-v0.8.6 was built against. We do **not** track `develop` because it changes daily and the backend's HTTP contract (`/v1/*` vs `/api/*` vs `/healthz`) drifts between releases.

To upgrade explicitly:

```bash
./bin/openagents-stack --upgrade           # show latest, ask y/n
./bin/openagents-stack --upgrade --to launcher-v0.9.0
```

---

## Architecture

```
~/openagents-stack/                       # this repo
├── bin/openagents-stack                  # single bash entry point
├── lib/                                  # cross-platform shared
│   ├── common.sh                         # log/ok/err/have/done_step
│   ├── config.sh                         # env var loading
│   ├── checks.sh                         # prerequisite checks
│   ├── selfcheck.sh                      # 12 preflight checks
│   ├── verify.sh                         # show_status helpers
│   ├── env.sh                            # write env vars to ~/.zshrc
│   ├── upstream_check.sh                 # compare pinned vs latest
│   ├── upgrade.sh                        # --upgrade with file lock
│   ├── docker.sh                         # docker detection helpers
│   ├── backend.sh                        # clone + start backend
│   ├── launcher.sh                       # install launcher (CLI + app)
│   ├── versions.lock                     # pinned launcher tag + monorepo commit
│   └── upgrade.lock                      # created at runtime during --upgrade
├── platform/                             # platform-specific (sourced on demand)
│   ├── macos/install_docker.sh
│   ├── macos/install_launcher.sh
│   ├── linux/install_docker.sh           # v0.2 (placeholder)
│   └── windows/install_docker.ps1       # v0.3 (placeholder)
├── examples/create-agents.example.sh     # workspace + agent creation reference
├── docs/architecture.md                  # design notes
└── .github/workflows/                    # CI (lint + smoke)
```

### Design choices

- **Setup installs dependencies only.** Starting the backend is a separate, deliberate user action (`--start`). Same for `--stop`. This matches `systemctl start nginx` style.
- **Setup does not create workspaces or agents.** That's done via the launcher desktop app or the CLI example script, after the user has confirmed the backend works.
- **Idempotent.** Each step writes its name to `.deploy-state` and re-runs are safe. `--reset` clears the state file.
- **Pinned, not floating.** We pin to a specific launcher release tag + a specific monorepo commit. We do not track `develop` (see above).
- **User-tunable paths.** `OPENAGENTS_HOME` and `OPENAGENTS_STACK_HOME` cover the two main paths. Other env vars documented above.
- **No `/tmp` writes.** Cache files, lock files, logs, and state all live under `OPENAGENTS_STACK_HOME`. `/tmp` is unreliable (cleared by macOS, lost on reboot).
- **Single source of truth for paths.** `lib/common.sh` resolves `OPENAGENTS_STACK_HOME` once, with three fallbacks (env var → script location → `~/openagents-stack`). The rest of the codebase reads `$OPENAGENTS_STACK_HOME` and never re-derives.

### Why not fork openagents-org/openagents?

Because we don't need to modify upstream. We just need to pin a specific version and orchestrate its lifecycle. Forking creates a maintenance burden (rebases on every `develop` push) without buying us anything.

---

## Troubleshooting

### Backend `did not come up on :8000 after 60s`

Check:

```bash
cd ~/openagents/workspace
docker compose -p openagents logs backend | tail -40
```

Common causes:

- `timers` / `workspaces` table missing → DB is empty, but alembic thinks it's at head. Fix: drop `alembic_version` table, then `--start` again.
- Stale volume from an old deploy → `docker volume ls` and `docker volume rm workspace_pgdata` (safe, contains only old data).

### `Daemon offline` in launcher desktop app

The launcher reads `~/.openagents/daemon.status.json`. If it's stale (older than 20s, or the PID inside is dead), launcher shows `Daemon offline` even if the daemon is healthy.

Fix: `Cmd+Q` the launcher, then reopen it. It re-issues `agents:daemon-status` IPC.

If persistent:

```bash
ps aux | grep agent-connector | grep -v grep    # is it actually running?
cat ~/.openagents/daemon.status.json             # what's in the file?
```

### Workspace creation returns "Invalid response" or 500

Check `docker logs openagents-backend-1 --tail 30`. If you see `relation "X" does not exist`, your alembic state is stale. Fix:

```bash
docker exec openagents-db-1 psql -U postgres -d openagents_workspace -c "DROP TABLE IF EXISTS alembic_version;"
./bin/openagents-stack --start    # alembic upgrade head will create all 24 tables
```

### Stale `workspace_pgdata` Docker volume

From earlier deploys. Safe to delete; contains no useful data:

```bash
docker volume rm workspace_pgdata
```

---

## License

MIT.
