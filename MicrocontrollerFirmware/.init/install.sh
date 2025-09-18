#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/voice-controlled-home-automation-16899-17029/MicrocontrollerFirmware"
# ensure logs dir and venv activation helper
mkdir -p "$WORKSPACE/logs"
if [ ! -f "$WORKSPACE/.venv_activate.sh" ]; then
  echo "venv activation helper missing" >&2
  exit 2
fi
# shellcheck disable=SC1090
source "$WORKSPACE/.venv_activate.sh"
cd "$WORKSPACE"
PIP_LOG="$WORKSPACE/logs/pip.install.log"
: > "$PIP_LOG"
# install from requirements with full logging; fail on error
if [ -f requirements.txt ]; then
  if ! "$WORKSPACE/.venv/bin/python" -m pip install -r requirements.txt >>"$PIP_LOG" 2>&1; then
    echo "pip install (requirements.txt) failed; see $PIP_LOG" >&2
    tail -n 200 "$PIP_LOG" > "$WORKSPACE/logs/pip.install.tail" || true
    exit 3
  fi
fi
USE_SERIAL=${USE_SERIAL:-0}
USE_VOICE=${USE_VOICE:-0}
POCKETSPHINX=${POCKETSPHINX:-0}
if [ "$USE_SERIAL" -eq 1 ]; then
  if ! "$WORKSPACE/.venv/bin/python" -m pip install pyserial >>"$PIP_LOG" 2>&1; then
    echo "pyserial install failed; see $PIP_LOG" >&2; exit 4
  fi
fi
if [ "$USE_VOICE" -eq 1 ]; then
  if ! "$WORKSPACE/.venv/bin/python" -m pip install SpeechRecognition >>"$PIP_LOG" 2>&1; then
    echo "SpeechRecognition install failed; see $PIP_LOG" >&2; exit 5
  fi
fi
if [ "$POCKETSPHINX" -eq 1 ]; then
  cat >>"$PIP_LOG" <<'TXT'
POCKETSPHINX requested but requires native system packages (e.g., swig, libpulse-dev, libasound2-dev) and build tools.
Non-interactive install must run: sudo apt-get update && sudo apt-get install -y swig libpulse-dev libasound2-dev
After that, rerun deps step to pip install pocketsphinx.
TXT
  echo "pocketsphinx requires native apt packages; cannot auto-install in this step" >&2
  exit 6
fi
# write pip freeze and compare venv vs global for key packages
"$WORKSPACE/.venv/bin/python" - <<PY > "$WORKSPACE/logs/deps.status" 2>&1
import importlib, subprocess
for pkg in ('flask','requests'):
    try:
        m = importlib.import_module(pkg)
        venv = getattr(m,'__version__','unknown')
    except Exception:
        venv = 'missing'
    try:
        out = subprocess.run(['python3','-c', f"import {pkg}; print(getattr({pkg},'__version__','unknown'))"], capture_output=True, text=True)
        global_v = out.stdout.strip()
    except Exception:
        global_v = 'unknown'
    line = f"{pkg} venv {venv} global {global_v}"
    print(line)
    if venv != 'missing' and global_v not in ('unknown','') and venv != global_v:
        print('WARNING: version mismatch for', pkg)
PY
"$WORKSPACE/.venv/bin/python" -m pip freeze > "$WORKSPACE/logs/pip.freeze" 2>/dev/null || true
# guard logs size: keep last 5000 lines
for f in "$WORKSPACE/logs/pip.install.log" "$WORKSPACE/logs/server.stdout" "$WORKSPACE/logs/server.stderr"; do
  [ -f "$f" ] && tail -n 5000 "$f" > "$f.tmp" && mv "$f.tmp" "$f" || true
done
exit 0
