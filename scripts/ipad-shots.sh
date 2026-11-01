#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -n "${MAC_RUNNER_JOB_ID:-}" ]] || { echo "Run through mac-run BibleAI test_reader"; exit 1; }
# mac-run is the execution boundary; no direct Terminal invocation or lock bypass.
[[ -f Pods/Manifest.lock ]] || { echo 'CocoaPods missing: run prepare_dependencies first'; exit 1; }
# screenshots only; no clean-tree requirement
[[ $(df -Pk . | awk 'NR==2 {print $4}') -ge 15728640 ]] || { echo 'Need 15 GiB free'; exit 1; }
xcrun simctl list devices booted --json | python3 -c 'import json,sys; a=json.load(sys.stdin); assert not any(d["state"]=="Booted" for g in a["devices"].values() for d in g), "Another simulator is booted; coordinate with its owner"'
read -r device runtime < <(xcrun simctl list --json | python3 -c '
import json,sys
j=json.load(sys.stdin)
r=next((r for r in reversed(j["runtimes"]) if r.get("isAvailable") and "iOS" in r["name"]), None)
d=next((d for d in j["devicetypes"] if d["name"].startswith("iPad Pro 13-inch")), None)
if not r or not d: sys.exit("No iPad Pro 13-inch / iOS runtime")
print(d["identifier"],r["identifier"])')
[[ -n "$device" && -n "$runtime" ]]
stamp=$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p build/ipad
log="$PWD/build/ipad/$stamp.log"
result="$PWD/build/ipad/$stamp.xcresult"
owned=$(xcrun simctl create "BibleAI iPad shots $stamp" "$device" "$runtime")
cleanup() {
  xcrun simctl shutdown "$owned" >/dev/null 2>&1 || true
  xcrun simctl delete "$owned"
  echo "INTERACTION CLEANUP PASSED $owned" | tee "$PWD/build/ipad/$stamp.cleanup.log"
}
trap cleanup EXIT
xcrun simctl boot "$owned"
xcrun simctl bootstatus "$owned" -b
{
  echo "SOURCE $(git rev-parse HEAD)"
  xcodebuild test -jobs 2 -workspace BibleAI.xcworkspace -scheme BibleAIReaderTests \
    -destination "platform=iOS Simulator,id=$owned" -derivedDataPath build/ipad-dd \
    -resultBundlePath "$result" -parallel-testing-enabled NO \
    -test-timeouts-enabled YES -default-test-execution-time-allowance 360 \
    -maximum-test-execution-time-allowance 480 \
    CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=YES CODE_SIGN_IDENTITY=-
} 2>&1 | tee "$log"
xcrun xcresulttool get test-results summary --path "$result" --format json > "$result.summary.json" || true
echo 'RUN_EXIT 0' | tee -a "$log"
echo "Raw native evidence: $result"
