# Deployment modes

openagents-stack ships three top-level install entry points. Each one
is a thin wrapper around the root [install.sh](../install.sh): they
share the same bootstrap (clone, PATH, base setup) and only differ in
the config they layer on top.

| Mode | Config it applies | What changes vs. default |
|------|-------------------|--------------------------|
| `local-personal/` | (none — uses defaults) | bind 127.0.0.1, no auth, single user |
| `lan-team/`       | `config.lan.yaml`     | bind 0.0.0.0, simple username/password, prints LAN IP for teammates |
| `enterprise/`     | `config.enterprise.yaml` | bind 127.0.0.1, generates self-signed cert, installs nginx reverse proxy in front |

## Usage

```bash
# 1. Choose your mode and run its install.sh. It will:
#    a) curl the root install.sh and run it (idempotent — re-runs are safe)
#    b) copy this mode's config to ~/openagents-stack/config.yaml
#    c) re-run setup so the new config is applied
#    d) start the backend

curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/deployments/local-personal/install.sh | bash   # ~5 min
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/deployments/lan-team/install.sh       | bash   # ~6 min
curl -fsSL https://raw.githubusercontent.com/pioneerAlone/openagents-stack/main/deployments/enterprise/install.sh     | bash   # ~35 min, needs sudo
```

## Adding a new mode

1. `mkdir deployments/<my-mode>/`
2. Drop a `config.<my-mode>.yaml` (inherits fields from
   [config.example.yaml](../config.example.yaml); only override what
   differs)
3. Add a `README.md` describing what your mode does
4. Add an `install.sh` that follows the pattern in
   `local-personal/install.sh` — don't reimplement the bootstrap

## Why thin wrappers, not standalone installers

Each deployment is a few hundred bytes of shell that just sets a
config. The bootstrap logic (clone, PATH, install deps) lives in one
place (`install.sh`) so a bug fix there is picked up by every mode
without you having to copy-paste it three times. If you find yourself
writing more than ~30 lines for a new mode, you're probably
reimplementing bootstrap that should live in `install.sh`.
