#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -n "${MAC_RUNNER_JOB_ID:-}" ]] || { echo 'Use mac-run BibleAI inspect_apple_account'; exit 1; }
node scripts/asc/asc.mjs scripts/asc/apple-account-preflight.mjs
node -e 'const r=JSON.parse(require("fs").readFileSync("scripts/asc/apple-account-preflight.out.json","utf8")); if(!r.ok) throw new Error(r.error); console.log(JSON.stringify(r.result,null,2))'
