#!/usr/bin/env bash
set -euo pipefail

: "${WALLET_ADDRESS:?Set WALLET_ADDRESS in environment (.env)}"
: "${NODE_COUNT:=1}"
: "${DATA_DIR:=/data}"
: "${PORT_START:=61000}"

echo "[autonomi] Updating installers/binaries with antup..."
antup update || true
antup node || true
antup antctl || true

echo "[autonomi] Preparing data dir at ${DATA_DIR}"
mkdir -p "${DATA_DIR}"

echo "[autonomi] Adding ${NODE_COUNT} node service(s)"
antctl add --count "${NODE_COUNT}" --data-dir-path "${DATA_DIR}" --rewards-address "${WALLET_ADDRESS}" evm-arbitrum-one || true

echo "[autonomi] Starting nodes..."
antctl start

while true; do
  antctl status || true
  sleep 60
done
