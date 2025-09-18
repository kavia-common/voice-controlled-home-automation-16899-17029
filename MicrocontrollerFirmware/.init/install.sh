#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/voice-controlled-home-automation-16899-17029/MicrocontrollerFirmware"
cd "$WORKSPACE"
[ -f package.json ] || { echo "package.json not found; run scaffold first" >&2; exit 6; }
# detect package manager preference
if [ -f yarn.lock ]; then PKG=yarn; elif [ -f package-lock.json ]; then PKG=npm; else PKG=npm; fi
# capture versions (guard failures)
NPM_VER=$(npm -v 2>/dev/null || echo "0")
YARN_VER=$(yarn -v 2>/dev/null || echo "0")
# install dependencies with guarded flags
if [ "$PKG" = "yarn" ]; then
  if [ -f yarn.lock ]; then
    # try frozen lockfile; if it fails, fall back to normal install
    if yarn install --frozen-lockfile 2>/tmp/vue_yarn_frozen_err.log; then :; else
      yarn install || { echo 'yarn install failed' >&2; exit 7; }
    fi
  else
    yarn install || { echo 'yarn install failed' >&2; exit 7; }
  fi
else
  # npm path: prefer npm ci when a lockfile exists and node_modules absent
  if [ -f package-lock.json ] && [ ! -d node_modules ]; then
    # try npm ci guarded; fall back to npm i
    if npm ci --no-audit --no-fund 2>/tmp/vue_npm_ci_err.log; then :; else
      npm i --no-audit --no-fund || { echo 'npm install failed' >&2; exit 9; }
    fi
  else
    npm i --no-audit --no-fund || { echo 'npm install failed' >&2; exit 9; }
  fi
fi
# create .env template only if absent
ENV_FILE="$WORKSPACE/.env"
if [ ! -f "$ENV_FILE" ]; then
  cat > "$ENV_FILE" <<'EOF'
VUE_APP_BACKEND_URL=http://localhost:3000/api
VUE_APP_VOICE_KEY=REPLACE_WITH_KEY
NODE_ENV=development
PORT=8080
EOF
fi
# create file-based mock only if absent
MOCK_DIR="$WORKSPACE/src/mocks"
mkdir -p "$MOCK_DIR"
MOCK_FILE="$MOCK_DIR/mock-api.json"
if [ ! -f "$MOCK_FILE" ]; then
  cat > "$MOCK_FILE" <<'JSON'
{
  "status": "ok",
  "devices": [ { "id": "lamp-1", "state": "off" } ]
}
JSON
fi
# add serve:headless script idempotently (guard node failures)
# The node one-liner is tolerant: it will not abort the shell on error
node -e "try{const fs=require('fs'); const p=JSON.parse(fs.readFileSync('package.json','utf8')); p.scripts=p.scripts||{}; if(!p.scripts['serve:headless']) p.scripts['serve:headless']='vue-cli-service serve --mode development --port 8080 --host 0.0.0.0'; fs.writeFileSync('package.json', JSON.stringify(p,null,2));}catch(e){process.exit(0)}" || true
# mark success
touch /tmp/step-deps-003.ok
