#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/voice-controlled-home-automation-16899-17029/MicrocontrollerFirmware"
# shellcheck disable=SC1090
[ -f "$WORKSPACE/.venv_activate.sh" ] && source "$WORKSPACE/.venv_activate.sh" || true
cd "$WORKSPACE"
mkdir -p "$WORKSPACE/logs"
# resolve port: env -> .env.example -> default
MC_PORT="${MC_FW_PORT:-}"
if [ -z "$MC_PORT" ]; then
  MC_PORT=$(grep -E '^MC_FW_PORT=' .env.example 2>/dev/null | cut -d= -f2 || true)
  MC_PORT="${MC_PORT:-5000}"
fi
# start server and capture logs, run in background
"$WORKSPACE/.venv/bin/python" "$WORKSPACE/app.py" >"$WORKSPACE/logs/server.stdout" 2>"$WORKSPACE/logs/server.stderr" &
PID=$!
# record PID
echo "$PID" > "$WORKSPACE/logs/server.pid"
# give process a moment
sleep 0.6
# verify process exists
if ! ps -p "$PID" >/dev/null 2>&1; then
  echo "validation: failed to start server process" > "$WORKSPACE/validation.log"
  exit 3
fi
# echo PID for caller
echo "$PID"
