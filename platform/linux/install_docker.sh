#!/usr/bin/env bash
# platform/linux/install_docker.sh
# Linux-specific Docker install.
#
# v0.2 status: supported distros are Debian / Ubuntu (and derivatives).
# Fedora / RHEL / Arch support is TODO. Detects the distro via
# /etc/os-release and dispatches; refuses with a clear message on
# unsupported distros rather than silently breaking.
#
# This is invoked by lib/common.sh + step_install_docker in bin/openagents-stack.

install_docker_linux() {
  # /etc/os-release is the modern, distro-agnostic source of truth
  # (works on Debian, Ubuntu, Fedora, RHEL, Arch, Alpine, …).
  if [[ ! -f /etc/os-release ]]; then
    err "Cannot detect distro: /etc/os-release not found. Install Docker manually: https://docs.docker.com/engine/install/"
  fi
  # shellcheck disable=SC1091
  source /etc/os-release
  local id="${ID:-unknown}"
  local like="${ID_LIKE:-}"

  case "$id" in
    debian|ubuntu)
      log "Installing Docker CE on $id ($VERSION_CODENAME)..."
      # Docker's official convenience script — does apt repo setup,
      # keyring, and `apt install docker-ce` in one shot. Avoids the
      # 6 separate steps of doing it manually.
      if [[ "${OPENAGENTS_STACK_NONINTERACTIVE:-}" == "1" ]]; then
        curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
        sh /tmp/get-docker.sh
      else
        curl -fsSL https://get.docker.com | sh
      fi
      ;;
    fedora|rhel|centos|rocky|almalinux)
      err "$id support is TODO (v0.2). Open an issue or run install_docker_linux manually."
      ;;
    arch|manjaro|endeavouros)
      err "Arch support is TODO (v0.2). Install Docker manually: pacman -S docker"
      ;;
    *)
      # If ID_LIKE includes "debian" or "ubuntu", the curl|sh script
      # above will probably work. Otherwise bail.
      if [[ "$like" == *debian* || "$like" == *ubuntu* ]]; then
        log "Unknown ID=$id but ID_LIKE=$like; trying Debian-style install..."
        curl -fsSL https://get.docker.com | sh
      else
        err "Unsupported Linux distro: ID=$id ID_LIKE=$like. Install Docker manually: https://docs.docker.com/engine/install/"
      fi
      ;;
  esac

  # Post-install: in many CI / sandboxed envs, the docker daemon
  # itself can't be started (no systemd, no privileges). The caller
  # (step_install_docker) will then check `docker info` and warn that
  # the daemon is unavailable. That's expected — we install the binary
  # and let the user / CI start the daemon themselves.
  docker_available || warn "docker installed but daemon not reachable. Start it with: sudo systemctl start docker"
  ok "Docker ready: $(docker --version)"
}
