#!/bin/bash
# Submit the specific build from our prepared draft; no automatic release or review replacement.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH=/opt/homebrew/bin:/usr/local/bin:$PATH
export READING_VERSION="${1:?version}" READING_BUILD="${2:?build}"
[[ "$READING_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && "$READING_BUILD" =~ ^[0-9]+$ ]]
[[ "$(git branch --show-current)" == main && -z "$(git status --porcelain)" ]]
git fetch origin main
[[ "$(git rev-parse HEAD)" == "$(git rev-parse origin/main)" ]]
test -s "docs/testing/build$READING_BUILD-qa-signoff.md"
bash scripts/reading-subscription-check.sh
node scripts/asc/asc.mjs scripts/asc/submit-reading-review.mjs
cat scripts/asc/submit-reading-review.out.json
