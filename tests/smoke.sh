#!/bin/sh
# Run from the repository root on a Linux machine with Docker.
set -eu

image=dynmap-standby:smoke
name=dynmap-standby-smoke-$$
port=42880

docker build -t "$image" .
trap 'docker rm -f "$name" >/dev/null 2>&1 || true' EXIT HUP INT TERM
# Deliberately unreachable loopback port: a sleeping Dynmap must render standby.
docker run -d --name "$name" -p "127.0.0.1:$port:8080" \
    -e UPSTREAM_HOST=127.0.0.1 -e UPSTREAM_PORT=19999 \
    -e JOIN_ADDRESS=your-server.example.com "$image" >/dev/null

i=0
until curl -fsS "http://127.0.0.1:$port/healthz" | grep -qx ok; do
    i=$((i + 1))
    if [ "$i" -ge 20 ]; then docker logs "$name"; exit 1; fi
    sleep 1
done
curl -fsS "http://127.0.0.1:$port/" | grep -q 'The world is sleeping'
if curl -fsS "http://127.0.0.1:$port/" | grep -q 'class="address"'; then
    echo "Address box unexpectedly present" >&2
    exit 1
fi
if curl -fsS "http://127.0.0.1:$port/" | grep -q 'your-server.example.com'; then
    echo "Placeholder leaked into page" >&2
    exit 1
fi
curl -fsS "http://127.0.0.1:$port/robots.txt" | grep -q "Disallow: /"
curl -fsS "http://127.0.0.1:$port/" | grep -q "noindex,nofollow"
printf 'Standby and proxy health checks passed.\n'
