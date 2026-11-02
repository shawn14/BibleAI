#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -n "${MAC_RUNNER_JOB_ID:-}" ]] || { echo 'Use mac-run BibleAI growth_core_test'; exit 1; }
mkdir -p build
trap 'rm -f build/growth-core-test' EXIT
xcrun swiftc -parse-as-library -O BibleAI/Models/BibleVerse.swift BibleAI/Models/BibleBook.swift BibleAI/Models/ReadingPlan.swift BibleAI/Models/ReadingPlace.swift BibleAI/Models/SharedScriptureLink.swift BibleAI/Services/GrowthStore.swift scripts/tests/growth/main.swift -o build/growth-core-test
build/growth-core-test
