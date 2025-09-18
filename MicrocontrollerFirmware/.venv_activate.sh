#!/usr/bin/env bash
# Usage: source /absolute/path/.venv_activate.sh
export WORKSPACE="/home/kavia/workspace/code-generation/voice-controlled-home-automation-16899-17029/MicrocontrollerFirmware"
# activate venv
# shellcheck disable=SC1090
source "$WORKSPACE/.venv/bin/activate"
# set defaults only if not already set by agent at runtime
export MC_FW_PORT="${MC_FW_PORT:-5000}"
export MC_DEVICE_PATH="${MC_DEVICE_PATH:-/dev/ttyUSB0}"
