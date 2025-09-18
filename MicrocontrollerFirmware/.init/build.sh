#!/usr/bin/env bash
set -euo pipefail
# No-op build step for pure-Python Flask app; present to satisfy validation build requirement
# Idempotent and quick
WORKSPACE="/home/kavia/workspace/code-generation/voice-controlled-home-automation-16899-17029/MicrocontrollerFirmware"
mkdir -p "$WORKSPACE/logs"
echo "build: noop" > "$WORKSPACE/logs/build.log"
