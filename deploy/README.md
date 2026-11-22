# Self-hosting via Cloudflare Tunnel

```
push to main → GitHub Actions builds image → ghcr.io → server pulls every 5 min → Caddy ← cloudflared ← Cloudflare edge
```

## One-time setup

1. **Make the image public.** After the first workflow run: GitHub → your profile → Packages →
   `mywebpersonal` → Package settings → Change visibility → Public.
   (Otherwise run `docker login ghcr.io` on the server with a read-only token.)
2. **Create the tunnel.** Cloudflare dashboard → Zero Trust → Networks → Tunnels → Create (cloudflared).
   Copy the token. Add a public hostname: `zamrabbaney.site` → service `http://web:80`.
3. **On the server** (Docker + Compose plugin installed):
   ```bash
   sudo git clone https://github.com/lildwagz/myWebPersonal /opt/mywebpersonal
   cd /opt/mywebpersonal/deploy && sudo cp .env.example .env && sudo nano .env   # paste TUNNEL_TOKEN
   sudo docker compose up -d
   sudo cp systemd/mywebpersonal-update.* /etc/systemd/system/
   sudo systemctl daemon-reload && sudo systemctl enable --now mywebpersonal-update.timer
   ```
4. **Cloudflare cache rule** (optional, recommended): Caching → Cache Rules → hostname equals
   `zamrabbaney.site` → Eligible for cache, Edge TTL e.g. 2 hours. Then add repo secrets
   `CLOUDFLARE_ZONE_ID` and `CLOUDFLARE_API_TOKEN` (permission: Zone → Cache Purge) so each deploy purges.
5. **Cut over from Netlify** last: remove the Netlify custom domain only after the tunnel serves correctly.

## Operations

- Roll back: set `image: ghcr.io/lildwagz/mywebpersonal:sha-<commit>` in `compose.yaml`, `docker compose up -d`.
- Logs: `docker compose logs -f web cloudflared`
- Local preview of the production image: `docker build -t site . && docker run --rm -p 8080:80 site`
