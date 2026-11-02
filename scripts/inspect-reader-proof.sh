#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -n "${MAC_RUNNER_JOB_ID:-}" ]] || { echo 'Run through mac-run BibleAI inspect_reader'; exit 1; }
result=$(python3 - <<'PYTHON'
from pathlib import Path
paths = sorted(Path('build/proof').glob('*.xcresult'))
if not paths: raise SystemExit('No native test result to inspect')
print(paths[-1].resolve())
PYTHON
)
stem=${result%.xcresult}
xcrun xcresulttool get test-results summary --path "$result" --format json > "$result.summary.json"
xcrun xcresulttool export attachments --path "$result" --output-path "$stem-attachments"
printf 'Native result: %s\n' "$result"
cat "$result.summary.json"
