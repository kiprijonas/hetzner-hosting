#!/usr/bin/env bash
# Pull latest config on the server, validate, and reload the Caddy container.
set -euo pipefail

SERVER="${SERVER:-root@46.62.155.60}"
REMOTE_DIR="${REMOTE_DIR:-/opt/hetzner-hosting}"
CONTAINER="${CONTAINER:-caddy}"

ssh -o StrictHostKeyChecking=accept-new "$SERVER" bash -s <<EOF
set -euo pipefail
cd "$REMOTE_DIR"

echo "==> git pull"
git pull --ff-only

echo "==> caddy validate"
docker compose exec -T "$CONTAINER" caddy validate --config /etc/caddy/Caddyfile

echo "==> caddy restart"
docker compose restart "$CONTAINER"

echo "==> done"
EOF
