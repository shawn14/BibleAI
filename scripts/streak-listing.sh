#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
case "${1:-}" in apply|verify) export STREAK_LISTING_MODE="$1" ;; *) exit 2 ;; esac
export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH
node scripts/asc/asc.mjs scripts/asc/streak-listing.mjs
node -e "const r = require('./scripts/asc/streak-listing.out.json'); if (!r.ok) throw Error(r.error); console.log(r.result)"
