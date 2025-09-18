#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/voice-controlled-home-automation-16899-17029/MicrocontrollerFirmware"
# shellcheck disable=SC1090
[ -f "$WORKSPACE/.venv_activate.sh" ] && source "$WORKSPACE/.venv_activate.sh" || true
cd "$WORKSPACE"
mkdir -p "$WORKSPACE/logs"
# ensure build step present (no-op)
mkdir -p "$WORKSPACE/logs"
echo "build: noop" > "$WORKSPACE/logs/build.log"
# resolve port: env -> .env.example -> default
MC_PORT="${MC_FW_PORT:-}"
if [ -z "$MC_PORT" ]; then
  MC_PORT=$(grep -E '^MC_FW_PORT=' .env.example 2>/dev/null | cut -d= -f2 || true)
  MC_PORT="${MC_PORT:-5000}"
fi
# Start server
"$WORKSPACE/.venv/bin/python" "$WORKSPACE/app.py" >"$WORKSPACE/logs/server.stdout" 2>"$WORKSPACE/logs/server.stderr" &
PID=$!
# give process a moment
sleep 0.6
# verify process exists
if ! ps -p "$PID" >/dev/null 2>&1; then
  echo "validation: failed to start server process" > "$WORKSPACE/validation.log"
  echo "server failed to start" > "$WORKSPACE/logs/validation_evidence.txt"
  exit 3
fi
# verify executable of PID points to venv python
if [ -r "/proc/$PID/exe" ]; then
  EXE=$(readlink -f "/proc/$PID/exe" || true)
  VENV_PY=$(readlink -f "$WORKSPACE/.venv/bin/python" || true)
  if [ "$EXE" != "$VENV_PY" ]; then
    echo "validation: server executable mismatch: $EXE" > "$WORKSPACE/validation.log"
    echo "exe_mismatch: $EXE" > "$WORKSPACE/logs/validation_evidence.txt"
    kill "$PID" 2>/dev/null || true
    wait "$PID" 2>/dev/null || true
    exit 4
  fi
else
  echo "validation: cannot read /proc/$PID/exe; skipping exe check" > "$WORKSPACE/validation.log"
fi
# incremental backoff polling up to ~20s
SUCCESS=0
sleeps=(0.2 0.4 0.8 1.6 3.2 6.4)
for s in "${sleeps[@]}"; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$MC_PORT/" || true)
  if [ "$code" = "200" ]; then
    SUCCESS=1
    break
  fi
  sleep "$s"
done
if [ $SUCCESS -eq 1 ]; then
  echo "validation: OK (HTTP 200)" > "$WORKSPACE/validation.log"
  echo "HTTP 200" > "$WORKSPACE/logs/validation_evidence.txt"
  # stop process gracefully
  kill "$PID" 2>/dev/null || true
  sleep 2
  if ps -p "$PID" >/dev/null 2>&1; then
    kill -9 "$PID" 2>/dev/null || true
  fi
  wait "$PID" 2>/dev/null || true
  exit 0
else
  echo "validation: FAILED" > "$WORKSPACE/validation.log"
  echo "server stdout:" >> "$WORKSPACE/validation.log" && sed -n '1,200p' "$WORKSPACE/logs/server.stdout" >> "$WORKSPACE/validation.log" 2>/dev/null || true
  echo "server stderr:" >> "$WORKSPACE/validation.log" && sed -n '1,200p' "$WORKSPACE/logs/server.stderr" >> "$WORKSPACE/validation.log" 2>/dev/null || true
  echo "FAILED" > "$WORKSPACE/logs/validation_evidence.txt"
  kill "$PID" 2>/dev/null || true
  sleep 2
  if ps -p "$PID" >/dev/null 2>&1; then
    kill -9 "$PID" 2>/dev/null || true
  fi
  wait "$PID" 2>/dev/null || true
  exit 5
fi
