#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/voice-controlled-home-automation-16899-17029/MicrocontrollerFirmware"
# Ensure logs dir
mkdir -p "$WORKSPACE/logs"
# resolve port: env -> .env.example -> default
MC_PORT="${MC_FW_PORT:-}"
if [ -z "$MC_PORT" ]; then
  MC_PORT=$(grep -E '^MC_FW_PORT=' .env.example 2>/dev/null | cut -d= -f2 || true)
  MC_PORT="${MC_PORT:-5000}"
fi
# Poll with incremental backoff up to ~20s
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
  echo "HTTP 200" > "$WORKSPACE/logs/validation_evidence.txt"
  echo "200"
  exit 0
else
  echo "NO_RESPONSE"
  exit 2
fi
