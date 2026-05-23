# hetzner-hosting

Caddy reverse proxy that fronts every site on the Hetzner box. One container, one Caddyfile, one config file per domain. TLS certs come from Let's Encrypt automatically.

## Layout

```
Caddyfile           Global options; imports sites/*.caddy
docker-compose.yml  Caddy container (host network mode)
sites/              One .caddy file per domain
  *.caddy
  default.caddy     :80 catch-all for path-routed apps (doorworld)
scripts/
  deploy.sh         SSH into the server, git pull, validate, restart
logs/               Caddy access logs (created on server, not in git)
```

Server: `root@46.62.155.60`, repo lives at `/opt/hetzner-hosting`.

## How it runs

- [docker-compose.yml](docker-compose.yml) starts `caddy:2-alpine` with `network_mode: host`, so `reverse_proxy localhost:NNNN` inside a site file talks to a service running directly on the Hetzner host (NOT in another container). Each app on the host binds to a different port; Caddy maps domains to ports.
- [Caddyfile](Caddyfile) only sets global options and `import /etc/caddy/sites/*.caddy`. All real config is in [sites/](sites/).
- TLS: Caddy provisions Let's Encrypt certs automatically when a public domain hits :443. No manual cert handling. The LE email in [Caddyfile](Caddyfile#L4) is still commented out — uncomment when you want LE expiry notifications.

## Adding a new site

1. Create `sites/<domain>.caddy`. Use [sites/artestrade.eu.caddy](sites/artestrade.eu.caddy) as the template — it has the common headers, gzip/zstd, JSON access log, and the `mail.<domain>` redirect to MXroute webmail that every site uses.
2. Pick a free localhost port for the app (see the port map below) and point `reverse_proxy localhost:<port>` at it.
3. If the app has a separate API, add a `handle /api/* { reverse_proxy localhost:<api-port> }` block above the catch-all `reverse_proxy`. Block order matters — specific `handle` blocks must come before the bare `reverse_proxy`.
4. Make sure the domain's DNS A record points to `46.62.155.60` before deploying, otherwise Let's Encrypt's HTTP-01 challenge will fail and Caddy will keep retrying.
5. Commit, push, then run `./scripts/deploy.sh` from your machine. The script pulls on the server, runs `caddy validate`, and restarts only if validation passes. **If you skip validate and ship a broken file, Caddy will refuse to start and ALL sites go down** — always let the script do its thing.

## Port map (current)

These ports are bound by services on the host, not by this repo. If you add a site, allocate a new range to avoid collisions.

| Site | Web | API |
|---|---|---|
| artestrade.eu | 3200 | 3001 |
| artestradeservice.am | 3200 | 3001 |
| artmartrade.am | 3100 | — |
| interworld.ae | 3400 | 3401 |
| patrycia-trade.kg | 3600 | — |
| teisespaslaugos.lt | 3300 | 3301 |
| west-tradeservice.pl | 3500 | 3501 |
| doorworld (path-routed on :80) | 3000 | 3420 |
| biodegra (path-routed on :80, `/skaiciuokle`) | 3700 | — |
| matterofchalk.com | 3800 | — |

Note: artestrade.eu and artestradeservice.am share the same backend (3200) and API (3001) — that's deliberate, they're the same app on two domains.

## Things worth noting

- **`default.caddy` is special.** It binds bare `:80` and path-routes `/doorworld*` and `/doorworld/api*`. It only catches requests that don't match any other site's `Host`. Don't add a `Host`-less site to `sites/` or it'll fight this one.
- **doorworld is HTTP-only on purpose** (no TLS, served from `:80`). If you ever give doorworld its own domain, move it out of [sites/default.caddy](sites/default.caddy) into its own file so Caddy provisions a cert.
- **Mail subdomains all redirect to MXroute.** Email is hosted at MXroute, not on this box. The `mail.<domain>` blocks in each site file are just convenience redirects to `webmail.mxroute.com`. Don't try to run a mail server here.
- **Logs are mounted but the `logs/` dir is not in git.** It's created on the server. If you `docker compose up` somewhere new and Caddy complains about the mount, `mkdir logs` first.
- **`network_mode: host` is load-bearing.** Without it Caddy can't reach `localhost:<port>` services on the host. Don't switch to a bridge network unless you also move every backend into Docker and use service names.
- **Deploy is manual, no CI.** `./scripts/deploy.sh` is the only path to prod. Env vars `SERVER`, `REMOTE_DIR`, `CONTAINER` can override the defaults if you ever move the box.
- **No staging.** Test Caddyfile changes by running `docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile` on the server (the deploy script does this for you).
- **`restart` vs `reload`.** [deploy.sh](scripts/deploy.sh#L20) does a full `docker compose restart` — there's a ~1s blip. If you want zero-downtime, swap to `docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile`, but make sure validate has passed first.

## Quick commands (on the server)

```bash
# Tail a site's access log
tail -f /opt/hetzner-hosting/logs/artestrade-eu-access.log

# Validate config without restarting
docker compose exec caddy caddy validate --config /etc/caddy/Caddyfile

# Reload without dropping connections
docker compose exec caddy caddy reload --config /etc/caddy/Caddyfile

# See certs Caddy is managing
docker compose exec caddy ls /data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/
```
