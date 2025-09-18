from flask import Flask, jsonify, request
import os
from typing import Dict, Any, Tuple

# In this simple microcontroller firmware API simulation, we provide:
# - POST /commands: accept commands for a given deviceId
# - GET /status: return the current device status
#
# We perform basic request/response validation aligned with the provided OpenAPI spec.
# Internal "hardware" logic is stubbed via in-memory state to simulate physical device control.

app = Flask(__name__)

# Configuration
PORT = int(os.getenv("MC_FW_PORT", "5000"))
API_KEY_HEADER = "X-API-KEY"
REQUIRE_API_KEY = os.getenv("MC_FW_REQUIRE_API_KEY", "false").lower() in ("1", "true", "yes")
EXPECTED_API_KEY = os.getenv("MC_FW_API_KEY", "")

# Simulated hardware state store: { deviceId: status }
_device_state: Dict[str, str] = {}

def _require_api_key() -> Tuple[bool, Dict[str, Any]]:
    """
    Validate API key header if required by configuration.
    Returns a tuple (ok, error_json). If ok is True, proceed; otherwise return error_json in response.
    """
    if not REQUIRE_API_KEY:
        return True, {}
    header_val = request.headers.get(API_KEY_HEADER)
    if not header_val:
        return False, {"error": "Missing API key", "header": API_KEY_HEADER}
    if EXPECTED_API_KEY and header_val != EXPECTED_API_KEY:
        return False, {"error": "Invalid API key"}
    return True, {}

def _validate_json(required_keys_types: Dict[str, type], allow_additional: bool = True) -> Tuple[bool, Dict[str, Any]]:
    """
    Basic JSON validator. Ensures presence and type of required keys.
    Returns (ok, data_or_error). If ok True, second value is parsed json; else it's an error payload.
    """
    if not request.is_json:
        return False, {"error": "Expected application/json"}
    data = request.get_json(silent=True)
    if data is None or not isinstance(data, dict):
        return False, {"error": "Invalid JSON payload"}
    # Validate required keys and types
    for key, expected_type in required_keys_types.items():
        if key not in data:
            return False, {"error": f"Missing required field '{key}'"}
        if not isinstance(data[key], expected_type):
            return False, {"error": f"Field '{key}' must be of type {expected_type.__name__}"}
    # If not allowing additional, ensure no extras
    if not allow_additional:
        extras = set(data.keys()) - set(required_keys_types.keys())
        if extras:
            return False, {"error": f"Unexpected fields: {', '.join(sorted(extras))}"}
    return True, data

# PUBLIC_INTERFACE
@app.route("/", methods=["GET"])
def index():
    """Root health check endpoint.
    Returns simple ok and port information.
    """
    return jsonify({"status": "ok", "port": PORT})

# PUBLIC_INTERFACE
@app.route("/commands", methods=["POST"])
def post_commands():
    """Send control commands to devices.
    Summary: Send control commands to devices.
    Request (application/json):
      - deviceId: string (required)
      - command: string (required)
    Security:
      - Header X-API-KEY if enabled via env MC_FW_REQUIRE_API_KEY=true
    Returns:
      200: {"status": "accepted"} on success
      400: Validation errors
    """
    # Security check (optional)
    ok, sec = _require_api_key()
    if not ok:
        return jsonify(sec), 401

    # Validate request body
    ok, parsed = _validate_json({"deviceId": str, "command": str}, allow_additional=True)
    if not ok:
        return jsonify(parsed), 400

    device_id = parsed["deviceId"].strip()
    command = parsed["command"].strip().lower()

    if not device_id:
        return jsonify({"error": "deviceId cannot be empty"}), 400
    if not command:
        return jsonify({"error": "command cannot be empty"}), 400

    # Simulate physical device operation:
    # For demo purposes, accept any string command and set it as the current status.
    # In a real firmware controller, this would write to serial or GPIO and update state after confirmation.
    _device_state[device_id] = command

    # Optionally: communicate to backend here (stubbed)
    # e.g., requests.post(BACKEND_URL, json={...}) if needed/configured.

    return jsonify({"status": "accepted"}), 200

# PUBLIC_INTERFACE
@app.route("/status", methods=["GET"])
def get_status():
    """Get device status.
    Summary: Get device status.
    Query parameters (optional):
      - deviceId: string (if omitted, returns an aggregate sample or first device)
    Security:
      - Header X-API-KEY if enabled via env MC_FW_REQUIRE_API_KEY=true
    Returns:
      200: {"deviceId": string, "status": string}
           If device unknown, returns status 'unknown' but echoes deviceId.
    """
    # Security check (optional)
    ok, sec = _require_api_key()
    if not ok:
        return jsonify(sec), 401

    device_id = request.args.get("deviceId", "", type=str).strip()

    # If deviceId not provided, derive one: choose a default key or fallback "default"
    if not device_id:
        if _device_state:
            device_id = next(iter(_device_state.keys()))
        else:
            device_id = "default"

    status = _device_state.get(device_id, "unknown")
    return jsonify({"deviceId": device_id, "status": status}), 200


if __name__ == "__main__":
    # Bind 0.0.0.0 so service is reachable inside container; tests poll 127.0.0.1
    app.run(host="0.0.0.0", port=PORT)
