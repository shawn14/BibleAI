#!/bin/bash
# This entry point stays closed until the matching draft and its distribution rights are verified.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "No App Review mutation: resolve the UK KJV decision, prepare the exact draft and valid signed build, then verify rights and review item IDs before submitting $1 ($2)." >&2
exit 2
