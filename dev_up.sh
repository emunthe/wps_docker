#!/usr/bin/env bash
set -euo pipefail

# Detect VM IP if DEV_DOMAIN not set
if [[ -z "${DEV_DOMAIN:-}" ]]; then
  VM_IP="$(ip -4 addr | awk '/inet /{print $2}' | cut -d/ -f1 | grep -vE '^(127\.0\.0\.1|0\.0\.0\.0)$' | head -n1)"
  if [[ -z "$VM_IP" ]]; then
    echo "Could not detect VM IP automatically. Export DEV_DOMAIN='<ip>.nip.io' and retry."
    exit 1
  fi
  export DEV_DOMAIN="${VM_IP}.nip.io"
fi

echo "Using DEV_DOMAIN=${DEV_DOMAIN}"

# Bring up Traefik (HTTP only) + stacks with dev overrides
docker compose -f network_proxy/compose.yaml -f network_proxy/compose.override.dev.yaml up -d
docker compose -f stacks/compose.yaml -f stacks/compose.override.dev.yaml up -d espenmunthe
docker compose -f stacks/bandyforbundet/compose.yaml -f stacks/bandyforbundet/compose.override.dev.yaml up -d

echo
echo "Dev routes:"
echo "  Static:  http://espenmunthe.${DEV_DOMAIN}"
echo "  Bandy:   http://bandy.${DEV_DOMAIN}"
echo "Dashboard: http://${DEV_DOMAIN%.*.*}:8080/dashboard (or try http://<VM-IP>:8080)"
