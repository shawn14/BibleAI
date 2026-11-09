#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
job=streak-listing
case "${1:-}" in
  apply|verify) export STREAK_LISTING_MODE="$1" ;;
  state) job=streak-review-state ;;
  *) exit 2 ;;
esac
export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH
node scripts/asc/asc.mjs "scripts/asc/$job.mjs"
node -e "const r = require(process.argv[1]); if (!r.ok) throw Error(r.error); console.log(JSON.stringify(r.result, null, 2))" "./scripts/asc/$job.out.json"
