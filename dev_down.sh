#!/usr/bin/env bash
set -euo pipefail
docker compose -f stacks/bandyforbundet/compose.yaml -f stacks/bandyforbundet/compose.override.dev.yaml down
docker compose -f stacks/compose.yaml -f stacks/compose.override.dev.yaml down
docker compose -f network_proxy/compose.yaml -f network_proxy/compose.override.dev.yaml down
