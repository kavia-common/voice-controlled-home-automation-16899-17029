#!/usr/bin/env bash
set -euo pipefail
# usage: ./run.sh
# sources workspace venv activation helper and runs app.py
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1090
source "$SCRIPT_DIR/.venv_activate.sh"
exec "$SCRIPT_DIR/.venv/bin/python" "$SCRIPT_DIR/app.py"
