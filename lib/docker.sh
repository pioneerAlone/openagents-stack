# docker.sh - docker detection helpers
# Source: `source lib/docker.sh`

docker_available() { command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; }
docker_compose_available() { docker compose version >/dev/null 2>&1; }
