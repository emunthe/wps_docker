#!/usr/bin/env bash
set -euo pipefail
LE_DIR="$(dirname "$0")/../network_proxy/letsencrypt"
mkdir -p "$LE_DIR"
touch "$LE_DIR/acme.json"
chmod 600 "$LE_DIR/acme.json"
