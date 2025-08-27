#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROXY_COMPOSE="${PROJECT_ROOT}/network_proxy/compose.yaml"
MAIN_COMPOSE="${PROJECT_ROOT}/stacks/compose.yaml"
BANDY_COMPOSE="${PROJECT_ROOT}/stacks/bandyforbundet/compose.yaml"

ESPEN_DOMAIN="${ESPEN_DOMAIN:-espenmunthe.localhost}"
BANDY_DOMAIN="${BANDY_DOMAIN:-bandyforbundet.localhost}"

KEEP_VOLUMES="${KEEP_VOLUMES:-0}"   # 0: remove volumes, 1: keep volumes

compose_down() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  if [[ "$KEEP_VOLUMES" == "1" ]]; then
    docker compose -f "$file" down || true
  else
    docker compose -f "$file" down -v || true
  fi
}

compose_up() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  docker compose -f "$file" up -d --remove-orphans
}

probe_port() {
  local host="$1" port="$2" tries=30 i=1
  while (( i <= tries )); do
    if (echo > /dev/tcp/"$host"/"$port") >/dev/null 2>&1; then
      return 0
    fi
    sleep 1; ((i++))
  done
  return 1
}

probe_route() {
  local host="$1" tries=25 i=1
  while (( i <= tries )); do
    status="$(curl -skI https://127.0.0.1 -H "Host: ${host}" | sed -n '1s/\r$//p')"
    if [[ -n "$status" && "$status" != *"504"* && "$status" != *"502"* ]]; then
      echo "OK  ${host} -> ${status}"; return 0
    fi
    printf "waiting for %s (%d/%d): %s\n" "$host" "$i" "$tries" "${status:-no response}"
    sleep 2; ((i++))
  done
  echo "WARN ${host} not healthy yet."; return 1
}

command -v docker >/dev/null || { echo "docker not found in PATH"; exit 127; }

docker network inspect web >/dev/null 2>&1 || docker network create web

echo ">> Bringing stacks DOWN (KEEP_VOLUMES=${KEEP_VOLUMES})"
compose_down "$BANDY_COMPOSE"
compose_down "$MAIN_COMPOSE"
compose_down "$PROXY_COMPOSE"

echo ">> Bringing Traefik (proxy) UP"
compose_up "$PROXY_COMPOSE"

echo ">> Waiting for Traefik on 127.0.0.1:443 ..."
if probe_port 127.0.0.1 443; then
  echo "Traefik is reachable on 443."
else
  echo "WARN: Traefik not reachable on 443 yet; continuing."
fi

echo ">> Bringing global stack UP"
compose_up "$MAIN_COMPOSE"

echo ">> Bringing bandy stack UP"
compose_up "$BANDY_COMPOSE"

echo ">> Probing routes via Traefik"
probe_route "$ESPEN_DOMAIN" || true
probe_route "$BANDY_DOMAIN" || true

echo ">> Done."
