# Dynmap Standby (beta)

A small nginx proxy for a Dynmap server that sleeps. When Dynmap is up, this forwards map requests. When the upstream refuses connections or responds with 502, 503, or 504, it shows a standby page. It does not wake Minecraft; your existing join-to-wake setup does that. The standby page will not update by itself. After joining and the server wakes, press "Try the map again" or refresh.

Test the container with `sh tests/smoke.sh` on a Linux host with Docker and curl. The smoke test builds the image and checks proxy health and the upstream-down page.

## Run with Docker Compose

Docker Compose builds the image from this repository. Paste this block into `compose.yaml` (or use the included file) and run `docker compose up -d --build`:

```yaml
services:
  dynmap-standby:
    container_name: dynmap-standby
    build: https://github.com/dhrandy/dynmap-standby.git#main
    ports:
      - "${STANDBY_PORT:-42879}:8080"
    environment:
      UPSTREAM_HOST: ${UPSTREAM_HOST:-192.168.x.x}
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

`192.168.x.x` is an example only. Set `UPSTREAM_HOST` to the Minecraft/Dynmap machine's LAN address reachable from Docker, and `UPSTREAM_PORT` to Dynmap's web port. `JOIN_ADDRESS` is optional. Leave it blank to remove the address box from the served page; `your-server.example.com` is also treated as blank. `STANDBY_PORT` changes the host port (default `42879`). No `.env` file is needed: `${VAR:-default}` values work as-is; edit the file or your Docker manager's environment settings. The Dockerfile is used by the remote build and is not a separate command to run.

For Dockhand or another Compose manager, paste the same block into a stack and set the upstream and host port values as needed. Plain Docker Compose is the default; Dockhand, CasaOS, and Synology are examples. Docker must be able to reach Dynmap over the LAN. If your manager does not support remote Git build contexts, clone the repo and change `build:` to `build: .`.

Put an HTTPS reverse proxy in front of the host port. Do not forward the container port directly from the router; restrict LAN access if possible. The standby page has `noindex,nofollow` metadata, and `/robots.txt` returns `Disallow: /` even while Dynmap is awake. The standby page returns successful HTML, so an external monitor checking only HTTP status cannot tell whether Dynmap is awake. `/healthz` checks the proxy itself, not Dynmap.

Short upstream timeouts replace failed map requests promptly. Websockets and map requests pass through nginx. Changing `UPSTREAM_HOST`, `UPSTREAM_PORT`, or `JOIN_ADDRESS` requires a container restart, no image rebuild. To update, stop the stack, pull/build the latest source, then start it again.
