#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -n "${MAC_RUNNER_JOB_ID:-}" ]] || { echo 'Use mac-run BibleAI render_store_videos'; exit 1; }
# The descriptive simulator filename keeps this CPU-heavy encode inside mac-run resource guards.
# It processes retained captures only; it never builds, boots, or runs a Simulator.
python3 docs/aso/creative-src/encode_refresh.py
