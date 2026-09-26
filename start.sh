#!/bin/sh
set -eu

: "${UPSTREAM_HOST:=127.0.0.1}"
: "${UPSTREAM_PORT:=8123}"
: "${JOIN_ADDRESS:=your-server.example.com}"

# Keep shell and HTML metacharacters out of generated configuration and markup.
case "$UPSTREAM_HOST" in *[!A-Za-z0-9.:-]*|'') echo 'Invalid UPSTREAM_HOST' >&2; exit 1;; esac
case "$UPSTREAM_PORT" in *[!0-9]*|'') echo 'Invalid UPSTREAM_PORT' >&2; exit 1;; esac
case "$JOIN_ADDRESS" in *[!A-Za-z0-9.:-]*|'') echo 'Invalid JOIN_ADDRESS' >&2; exit 1;; esac

export UPSTREAM_HOST UPSTREAM_PORT JOIN_ADDRESS
envsubst '${UPSTREAM_HOST} ${UPSTREAM_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf
envsubst '${JOIN_ADDRESS}' < /etc/nginx/standby.html.template > /usr/share/nginx/html/standby.html
exec nginx -g 'daemon off;'
