#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -n "${MAC_RUNNER_JOB_ID:-}" ]] || { echo 'Use mac-run BibleAI reading_core_test'; exit 1; }
mkdir -p build
binary=$(mktemp build/reading-core.XXXXXX)
trap 'rm -f "$binary"' EXIT
xcrun swiftc -parse-as-library BibleAI/Models/{BibleVerse,BibleBook,ReadingPlan,ReadingPlace,Highlight}.swift \
    BibleAI/Services/{CloudSyncMerge,CloudSync,EnhancedBibleService,ScriptureFeedModel,StudyLibrary}.swift \
    scripts/tests/reading/main.swift -o "$binary"
"$binary"
