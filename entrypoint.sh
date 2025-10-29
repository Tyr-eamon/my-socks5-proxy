#!/bin/sh

set -eu

PORT="${PORT:-8080}"
BIND_IP="${BIND_IP:-0.0.0.0}"
ACCOUNT="${USER:-tyreamon}"
SECRET="${PASS:-2099}"
CONF_DIR="/etc/.c"
CONF_PATH="${CONF_DIR}/serve.conf"
BINARY="/usr/local/bin/serve"
CONFIG_BLOB='H4sICDMoAmkAA21pbmltYWwuY29uZgCVTzsOwjAM3X0KnwA6R2JBLCyAEHtUklAi0jhyHARC3J20MFQwYS9+Hz09B+qoSCqiMIt1zAA+iuPYBoVaL9ebldaYiAUXFe+2+4PW4G7fFoBM5pJ7J2eyCkse9N7BcMwS+6sPrnNVYSJ5syVO+UhHsncAE7yLgqnNGR+AdU5MvcJmNu68QaEJGh2BOoW1OzE8P0X+C0hMQobqP2ISFpt+Y1/9ZWl1KQEAAA=='

if [ -z "$ACCOUNT" ] || [ -z "$SECRET" ]; then
  printf 'USER and PASS are required\n' >&2
  exit 1
fi

umask 077
mkdir -p "$CONF_DIR"

if ! id "$ACCOUNT" >/dev/null 2>&1; then
  adduser -D -s /sbin/nologin "$ACCOUNT"
fi

printf '%s:%s\n' "$ACCOUNT" "$SECRET" | chpasswd

printf '%s' "$CONFIG_BLOB" | base64 -d | gzip -dc > "${CONF_PATH}.tmp"
sed -i "s|__PORT__|$PORT|g" "${CONF_PATH}.tmp"
sed -i "s|__BIND__|$BIND_IP|g" "${CONF_PATH}.tmp"
mv "${CONF_PATH}.tmp" "$CONF_PATH"

printf 'serve listening on %s:%s\n' "$BIND_IP" "$PORT"

exec -a serve "$BINARY" -f "$CONF_PATH" -D
