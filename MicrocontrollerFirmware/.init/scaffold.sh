#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/voice-controlled-home-automation-16899-17029/MicrocontrollerFirmware"
mkdir -p "$WORKSPACE" && cd "$WORKSPACE"
# idempotent exit if package.json already present
[ -f package.json ] && exit 0
# ensure vue CLI available
if ! command -v vue >/dev/null 2>&1; then echo 'vue CLI missing' >&2; exit 3; fi
VUE_VER=$(vue --version 2>/dev/null || echo "0")
# choose package manager
PKG_MANAGER=npm
[ -f yarn.lock ] && PKG_MANAGER=yarn
# avoid running interactive scaffold in a populated dir
if [ -n "$(ls -A "$WORKSPACE")" ]; then echo 'workspace not empty and package.json missing; aborting to avoid vue prompts' >&2; exit 4; fi
# run documented, non-standard-flag-free scaffold
vue create . --default --packageManager "$PKG_MANAGER" --no-git || { echo 'vue create failed' >&2; exit 5; }
# handle rare pre-seeded TypeScript indicator
if [ -f tsconfig.json ]; then
  if ! node -e "try{p=require('./package.json'); console.log(Boolean(p.devDependencies&&p.devDependencies['@vue/cli-plugin-typescript']||p.dependencies&&p.dependencies['@vue/cli-plugin-typescript']));}catch(e){process.exit(0)}" | grep -q true; then
    if [ "$PKG_MANAGER" = "yarn" ]; then yarn add -D @vue/cli-plugin-typescript || true; else npm i -D @vue/cli-plugin-typescript --no-audit --no-fund || true; fi
    vue invoke typescript || true
  fi
fi
[ -f package.json ] || { echo "scaffold failed: package.json missing" >&2; exit 6; }
# evidence
touch /tmp/step-scaffold-002.ok
