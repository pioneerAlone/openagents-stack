# Architecture

> Last updated: 2026-06-19

## Goals

1. **Reproducible** — same script produces same result on clean macOS
2. **Pinned** — never breaks from upstream changes without explicit upgrade
3. **Extensible** — adding Linux/Windows = adding `platform/<os>/` only
4. **Self-checking** — detect existing installs (OrbStack, hermes, etc.) and reuse

## High-level

```
┌──────────────────────────────────────────────────────┐
│  User macOS                                          │
│                                                      │
│  ┌──────────────────┐                                │
│  │  ~/openagents-stack/  (this repo, source)         │
│  │  bin/openagents-stack (entry point)                │
│  └─────────┬────────┘                                │
│            │ invokes                                 │
│            ↓                                         │
│  ┌────────────────────────────────────────────┐      │
│  │  5-step flow                                │      │
│  │  0. Check git/curl/brew                     │      │
│  │  1. Install Docker (OrbStack or DD)        │      │
│  │  2. Install launcher (.pkg → CLI + app)    │      │
│  │  3. Clone monorepo + start docker backend  │      │
│  │  4. Create workspace + connect agents       │      │
│  └─────────┬──────────────────────────────────┘      │
│            │                                          │
│            ├─→ /tmp (scratch)                        │
│            ├─→ ~/openagents/ (monorepo, 5xx MB)      │
│            ├─→ ~/.openagents/ (launcher config)     │
│            └─→ docker containers                     │
│                                                      │
│  OrbStack / Docker Desktop (runtime)                 │
│      ↓                                               │
│  openagents-db (postgres 16)                        │
│  openagents-backend (FastAPI on :8000)              │
│      ↓                                               │
│  launcher daemon                                     │
│      ↓                                               │
│  hermes subprocesses (per agent spawn)               │
└──────────────────────────────────────────────────────┘
```

## Script design

### `bin/openagents-stack` (entry)

```
main()
├── step_check       →  lib/common.sh
├── step_docker      →  platform/macos/install_docker.sh  (or linux/windows later)
├── step_launcher    →  platform/macos/install_launcher.sh
├── step_backend     →  lib/backend.sh
├── step_agents      →  lib/agents.sh
└── print_summary
```

**Key principle**: `bin/openagents-stack` is the only entry point. Sub-scripts are `source`d, not executed — they share state via exported env vars.

### State management

| State | File | Idempotency |
|---|---|---|
| Which steps ran | `~/.openagents-stack/.deploy-state` | Skip if `have step_X` |
| Backend health | `curl /api/health` | Wait up to 60s |
| Upstream version | `lib/versions.lock` | Source of truth |

### Self-check (critical for "use existing")

Before installing anything, the script checks:

| Check | What | If exists |
|---|---|---|
| `command -v docker` | Docker runtime | Skip install_docker |
| `command -v agn` | Launcher CLI | Skip install_launcher |
| `command -v hermes` | Hermes CLI | (assumed) |
| `~/.hermes/profiles/<name>/` | Hermes profiles | (assumed) |
| `docker ps --filter name=openagents-backend` | Existing backend | Skip start |
| `git -C $OPENAGENTS_HOME log --oneline -1` | Pinned commit | Skip clone if matches |

This is what makes the script safe to re-run.

## Version pinning (the core design choice)

We **do not** follow `develop`. Instead we pin to a specific commit + tag combination that was verified working on 2026-06-19.

**Why**:

| Problem with develop | Why we avoid it |
|---|---|
| Daily launcher releases (1-2/day) | Untested in our stack |
| Backend can break v1 endpoint compat | Issue #438 (we hit it) |
| Alembic migrations can require manual data fix | We'd need to re-verify every day |

**Pin mechanism**:

```bash
# lib/versions.lock
OPENAGENTS_LAUNCHER_VERSION="0.2.143"   # npm: @openagents-org/agent-launcher
OPENAGENTS_MONOREPO_COMMIT="45abec5"    # git: openagents monorepo
```

Upgrade is **explicit** (user runs `--upgrade`).

## Update flow

```
User runs --upgrade
       ↓
lib/upstream_check.sh: curl GitHub API
       ↓
Compare: latest_launcher vs locked_launcher
       ↓
If user confirms (y/n):
       ↓
lib/upgrade.sh:
  1. Backup lib/versions.lock → .bak
  2. Resolve new launcher tag → monorepo commit
  3. Write new versions.lock
  4. rm -rf $OPENAGENTS_HOME
  5. git clone + git checkout <new_commit>
  6. docker compose down (old backend)
  7. docker compose up -d (new backend with new code)
  8. alembic upgrade head
       ↓
Verify health → ok
```

## Why this is NOT a fork

| Fork concerns | Our approach |
|---|---|
| Rebase conflicts on every upstream merge | We don't have any upstream code |
| Our changes pollute upstream | We have zero changes to upstream |
| Hard to track which commit we tested | We pin the exact commit |
| v1/* endpoint compat surprises | Same pinned commit = same behavior |

**Trade-off**: we lose automatic bug fixes. Mitigation: `--upgrade` + user tests in their env.

## Cross-platform architecture (future)

```
platform/
├── macos/         # v0.1 — done
│   ├── install_docker.sh
│   ├── install_launcher.sh
│   └── paths.sh
├── linux/         # v0.2 — TODO
│   ├── install_docker.sh
│   ├── install_launcher.sh
│   └── paths.sh
└── windows/       # v0.3 — TODO
    ├── install_docker.ps1
    ├── install_launcher.ps1
    └── paths.ps1
```

`lib/*.sh` is **platform-agnostic**. Platform-specific code is in `platform/<os>/`.

## Failure modes

| Failure | Recovery |
|---|---|
| Docker not installed | `install_docker_<os>.sh` installs |
| Launcher .pkg download fails | Re-run; no state change |
| Backend fails health check (60s) | `docker logs openagents-backend`; `--reset` to retry |
| Hermes profile missing | User runs `hermes setup` manually (out of scope) |
| Migration fails | `alembic downgrade -1` then re-run |
| Upgrade breaks | `cp lib/versions.lock.bak lib/versions.lock` + re-run |
| Port 8000 in use | We don't check this; user resolves |

## What we do NOT do (out of scope)

- ❌ Configure LLM API keys (user does this via `agn env`)
- ❌ Create hermes profiles (user does `hermes setup`)
- ❌ Fix upstream issues (file issue + pin workaround)
- ❌ Multi-instance (only one backend per host)
- ❌ Remote backend (always local)
- ❌ Backup/restore (manual `pg_dump`)

## See also

- `naming.md` — why paths and env vars are generic
- `updating.md` — how `--upgrade` works
