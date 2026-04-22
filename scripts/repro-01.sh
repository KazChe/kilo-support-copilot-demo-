#!/usr/bin/env bash
# Bug 01 — auth/config
# Symptom: login fails with "authentication failed" even when API_KEY is set in the shell.
# This script is what the Triager runs to reproduce the failure deterministically.

set -euo pipefail

SHELL_KEY="my-shell-key"
PORT="${PORT:-3000}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SERVER_DIR="$ROOT_DIR/app/server"

cd "$SERVER_DIR"

if [ ! -d node_modules ]; then
  echo "[repro-01] installing server deps..."
  npm install --silent
fi

echo "[repro-01] starting server with API_KEY=$SHELL_KEY in the shell env..."
API_KEY="$SHELL_KEY" PORT="$PORT" npm start >/tmp/repro-01.server.log 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null || true' EXIT

for _ in $(seq 1 20); do
  if curl -sf "http://localhost:$PORT/" >/dev/null 2>&1; then break; fi
  sleep 0.2
done

echo ""
echo "[repro-01] attempting login with the same key we set in our shell..."
HTTP_CODE=$(
  curl -sS -o /tmp/repro-01.body -w "%{http_code}" \
    -X POST "http://localhost:$PORT/login" \
    -H "Authorization: Bearer $SHELL_KEY"
)
echo ""
echo "---- response ----"
echo "HTTP $HTTP_CODE"
cat /tmp/repro-01.body
echo ""
echo "---- server log tail ----"
tail -n 10 /tmp/repro-01.server.log || true
echo ""

if [ "$HTTP_CODE" = "200" ]; then
  echo "[repro-01] UNEXPECTED: login succeeded — bug did not reproduce."
  exit 1
else
  echo "[repro-01] bug reproduced (HTTP $HTTP_CODE)."
fi
