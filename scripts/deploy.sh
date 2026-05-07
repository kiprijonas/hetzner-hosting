#!/usr/bin/env bash
# Pull latest config on the server, validate, and reload Caddy.
set -euo pipefail

SERVER="${SERVER:-root@46.62.155.60}"
REMOTE_DIR="${REMOTE_DIR:-/opt/hetzner-hosting}"
CADDYFILE="${CADDYFILE:-$REMOTE_DIR/Caddyfile}"

ssh -o StrictHostKeyChecking=accept-new "$SERVER" bash -s <<EOF
set -euo pipefail
cd "$REMOTE_DIR"

echo "==> git pull"
git pull --ff-only

echo "==> caddy validate"
caddy validate --config "$CADDYFILE" --adapter caddyfile

echo "==> caddy reload"
caddy reload --config "$CADDYFILE" --adapter caddyfile

echo "==> done"
EOF
