# Dynmap Standby (beta)

A small nginx proxy for a Dynmap server that sleeps. When Dynmap is up, this forwards map requests. When the upstream refuses connections or responds with 502, 503, or 504, it shows a standby page. It does not wake the Minecraft server; your existing join-to-wake setup does that.

Test the container with `sh tests/smoke.sh` on a Linux host with Docker and curl. The smoke test builds the image and checks proxy health and the upstream-down page.

## Run with Docker Compose

Docker Compose builds the image from this repository. Paste this block into `compose.yaml` (or use the included file) and run `docker compose up -d --build`:

```yaml
services:
  dynmap-standby:
    build: https://github.com/dhrandy/dynmap-standby.git#main
    ports:
      - "${STANDBY_PORT:-42879}:8080"
    environment:
      UPSTREAM_HOST: ${UPSTREAM_HOST:-127.0.0.1}
      UPSTREAM_PORT: ${UPSTREAM_PORT:-8123}
      JOIN_ADDRESS: ${JOIN_ADDRESS:-}
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    healthcheck:
      test: ["CMD", "wget", "-q", "-O", "/dev/null", "http://127.0.0.1:8080/healthz"]
      interval: 30s
      timeout: 3s
      retries: 3
      start_period: 10s
```

Set `UPSTREAM_HOST` to the Minecraft/Dynmap machine's address reachable from Docker, `UPSTREAM_PORT` to Dynmap's actual web port, and optionally set `JOIN_ADDRESS` if you want the join address displayed. Leave it unset or blank to omit the address box entirely. The old `your-server.example.com` placeholder also omits the box; it will not appear in the served HTML. The default host is loopback, so it shows standby until changed to your Dynmap host. The port is a common Dynmap default; confirm yours. `STANDBY_PORT` changes the host port (default `42879`). No `.env` file is needed: the `${VAR:-default}` values work as-is; change them in the file or in your Docker manager's environment settings. The Dockerfile is for the remote build, not a separate command to run. The HTML is a single local file with no assets or build step.

For Dockhand, paste the same Compose block into a new stack, change the upstream host/port and host port as needed (leave JOIN_ADDRESS empty to hide it), then deploy. Plain Docker Compose is the default; Dockhand, CasaOS, and Synology are just examples. The machine running Docker must be able to reach Dynmap on its LAN address. Docker needs access to GitHub to build the image from the repo. If your Docker manager doesn't support remote Git build contexts, clone the repo and change `build:` to `build: .`, then deploy from that folder.

Point your HTTPS reverse proxy at `http://<docker-host-lan-ip>:42879` after deploying. Keep the public hostname and TLS settings unchanged. Do not forward the container port directly from the router; restrict LAN access if possible. The standby HTML has a robots noindex/nofollow meta tag and this container serves `/robots.txt` with `Disallow: /` even while Dynmap is awake. That blocks well-behaved crawlers from indexing the map too. Because the standby page is a successful HTML response, an external monitor checking only HTTP status will not distinguish sleep from an active map. `/healthz` checks the proxy itself, not Dynmap.

A player can press "Try the map again" after joining and waiting for Dynmap to start. Short upstream timeouts mean the standby page replaces failed map requests promptly. Browser websockets and map requests pass through nginx. If the Dynmap host changes, edit the stack settings and redeploy. Setting or clearing JOIN_ADDRESS needs a container restart (no image rebuild required). To update, stop the stack, pull/build the latest source, then start it again.
