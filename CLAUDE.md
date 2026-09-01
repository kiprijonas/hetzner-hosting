# CLAUDE.md

This repo is only the Caddy reverse proxy for the Hetzner box (`root@46.62.155.60`). The sites it fronts are separate repos, one per site, running as Docker containers on localhost ports (see the port map in README.md).

## Building a new site

**Always start from the `web-template` project at `C:\Users\kipra\web-template`.** Copy it and follow its stack and layout:

- React 19 + TypeScript + Vite + Tailwind CSS + React Router
- Multi-stage Dockerfile: `node:24-alpine` build → `serve -s dist -l 3000` (SPA fallback included)
- docker-compose maps `127.0.0.1:<site-port>:3000` (allocate `<site-port>` from the README port map — next free multiple of 100 in the 3000–3900 band); set `container_name` and network name to the project
- Per its README: update `container_name`/port in docker-compose.yml; the Caddy config does NOT come from the template's Caddyfile — it goes in this repo as `sites/<domain>.caddy` (use the `add-site` skill)

Example built this way: `C:\Users\kipra\araschgroup-web` (araschgroup.az, port 3900).

## Deploying a site app to the box

Site repos live on the server under `/opt/<name>`. Two patterns in use:

1. **GitHub remote** (matterofchalk-web): clone on the server, `git pull && docker compose up -d --build`.
2. **Push-to-prod bare repo** (araschgroup-web): bare repo at `/opt/<name>.git` with a `post-receive` hook that checks out into `/opt/<name>` and runs `docker compose up -d --build`. Local remote: `git remote add prod root@46.62.155.60:/opt/<name>.git`, then deploy = `git push prod main`.

## Wiring the domain into Caddy

Use the `add-site` skill (`.claude/skills/add-site`): it creates `sites/<domain>.caddy` from the template, updates the README port map, and deploys via `scripts/deploy.sh`. DNS A record must point to `46.62.155.60` before Let's Encrypt can issue a cert. Note: `deploy.sh` output can be misleading — verify the restart/reload actually happened (`docker ps` status age), or run `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile` on the server after validate passes.
