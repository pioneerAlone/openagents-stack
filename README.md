# openagents-stack

> One-click local setup for openagents on macOS.
>
> v0.1: macOS only. v0.2: +Linux. v0.3: +Windows.

## What this is

A local-only deployment stack for [openagents-org/openagents](https://github.com/openagents-org/openagents):

- ✅ **launcher** (desktop app + `agn` CLI)
- ✅ **docker backend** (workspace server + postgres)
- ✅ **workspace** (via `agn workspace create`)
- ✅ **agents** (hermes / claude / opencode via `agn create`)

## What this is NOT

- ❌ Not a fork of openagents monorepo
- ❌ Not a cloud service (no cloud workspaces)
- ❌ Not a replacement for the official install script

## Quick start (macOS)

```bash
git clone https://github.com/pioneerAlone/openagents-stack.git ~/openagents-stack
cd ~/openagents-stack
./bin/openagents-stack
```

That's it. The script will:

1. Check prerequisites (git / curl / brew)
2. Install Docker runtime (OrbStack or Docker Desktop)
3. Install launcher (download `.pkg`)
4. Clone openagents monorepo + start docker backend
5. Create workspace + connect agents

## Version pinning

This stack pins to specific upstream versions in `lib/versions.lock`:

- `OPENAGENTS_LAUNCHER_TAG=launcher-v0.8.6` (verified working)
- `OPENAGENTS_MONOREPO_COMMIT=45abec5` (verified working)

Updates are **explicit**:

```bash
./bin/openagents-stack --upgrade    # show latest + ask
./bin/openagents-stack --upgrade --to launcher-v0.8.7
```

## Commands

| Command | What |
|---|---|
| `./bin/openagents-stack` | Full setup (5 steps) |
| `./bin/openagents-stack --status` | Show backend / agents / upstream |
| `./bin/openagents-stack --stop` | Stop docker backend |
| `./bin/openagents-stack --clean` | Stop + delete volumes (data loss) |
| `./bin/openagents-stack --upgrade` | Show latest upstream + ask |
| `./bin/openagents-stack --upgrade --to <tag>` | Pin to specific version |
| `./bin/openagents-stack --reset` | Reset local state, re-run all steps |
| `./bin/openagents-stack --dry-run` | Print plan, don't change anything |
| `./bin/openagents-stack --help` | Show help |

## Layout

```
openagents-stack/
├── bin/openagents-stack      # 入口脚本
├── lib/                       # 跨平台共享
│   ├── common.sh
│   ├── config.sh
│   ├── upstream_check.sh
│   ├── upgrade.sh
│   └── versions.lock
├── platform/                  # 平台特定
│   ├── macos/
│   ├── linux/  (v0.2)
│   └── windows/  (v0.3)
├── tests/
├── docs/
│   ├── architecture.md
│   ├── naming.md
│   └── updating.md
└── examples/
```

## See also

- `docs/architecture.md` — system design
- `docs/naming.md` — why no personal names
- `docs/updating.md` — how upgrades work

## License

MIT
