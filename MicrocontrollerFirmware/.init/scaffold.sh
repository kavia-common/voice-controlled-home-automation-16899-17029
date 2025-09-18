#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/voice-controlled-home-automation-16899-17029/MicrocontrollerFirmware"
mkdir -p "$WORKSPACE" "$WORKSPACE/lib"
# app.py (bind 0.0.0.0 so container-local polling to 127.0.0.1 works)
if [ ! -f "$WORKSPACE/app.py" ]; then
  cat > "$WORKSPACE/app.py" <<'PY'
from flask import Flask, jsonify
import os
app = Flask(__name__)
PORT = int(os.getenv('MC_FW_PORT', '5000'))
@app.route('/')
def index():
    return jsonify({"status":"ok","port":PORT})
if __name__ == '__main__':
    # bind 0.0.0.0 so service is reachable inside container; tests poll 127.0.0.1
    app.run(host='0.0.0.0', port=PORT)
PY
fi
if [ ! -f "$WORKSPACE/requirements.txt" ]; then
  cat > "$WORKSPACE/requirements.txt" <<'REQ'
Flask>=2.0
requests>=2.0
REQ
fi
if [ ! -f "$WORKSPACE/lib/serial_helper.py" ]; then
  cat > "$WORKSPACE/lib/serial_helper.py" <<'PY'
# placeholder for pyserial helpers
try:
    import serial
except Exception:
    serial = None

def open_device(path, baud=115200):
    if serial is None:
        raise RuntimeError('pyserial not installed')
    return serial.Serial(path, baud)
PY
fi
if [ ! -f "$WORKSPACE/.env.example" ]; then
  cat > "$WORKSPACE/.env.example" <<'ENV'
MC_FW_PORT=5000
MC_DEVICE_PATH=/dev/ttyUSB0
ENV
fi
# create a runnable start wrapper that sources the venv and runs the app
if [ ! -f "$WORKSPACE/run.sh" ]; then
  cat > "$WORKSPACE/run.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
# usage: ./run.sh
# sources workspace venv activation helper and runs app.py
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/.venv_activate.sh"
exec "$SCRIPT_DIR/.venv/bin/python" "$SCRIPT_DIR/app.py"
SH
  chmod +x "$WORKSPACE/run.sh"
fi
exit 0
