#!/bin/bash
# One approved App ID capability change; no upload, submission, pricing or customer writes.
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -n "${MAC_RUNNER_JOB_ID:-}" ]] || { echo 'Use mac-run BibleAI enable_apple_account after explicit approval'; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { echo 'Require committed source before the Apple capability change'; exit 1; }
APPLY_APPLE_ACCOUNT=1 node scripts/asc/asc.mjs scripts/asc/apple-account-enable.mjs
node -e 'const r=JSON.parse(require("fs").readFileSync("scripts/asc/apple-account-enable.out.json","utf8")); if(!r.ok) throw new Error(r.error); console.log(JSON.stringify(r.result,null,2))'
