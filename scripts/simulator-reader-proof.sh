#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -n "${MAC_RUNNER_JOB_ID:-}" ]] || { echo "Run through mac-run BibleAI test_reader"; exit 1; }
# mac-run is the execution boundary; no direct Terminal invocation or lock bypass.
[[ -f Pods/Manifest.lock ]] || { echo 'CocoaPods missing: run prepare_dependencies first'; exit 1; }
[[ -z "$(git status --porcelain --untracked-files=no)" ]] || { echo 'Commit source before native proof'; exit 1; }
[[ $(df -Pk . | awk 'NR==2 {print $4}') -ge 15728640 ]] || { echo 'Need 15 GiB free'; exit 1; }
xcrun simctl list devices booted --json | python3 -c 'import json,sys; a=json.load(sys.stdin); assert not any(d["state"]=="Booted" for g in a["devices"].values() for d in g), "Another simulator is booted; coordinate with its owner"'
read -r device runtime < <(xcrun simctl list --json | python3 -c '
import json,sys
j=json.load(sys.stdin)
r=next((r for r in reversed(j["runtimes"]) if r.get("isAvailable") and "iOS" in r["name"]), None)
d=next((d for d in j["devicetypes"] if d["name"]=="iPhone 16"), None)
if not r or not d: sys.exit("No iPhone16/iOS runtime; stop")
print(d["identifier"],r["identifier"])')
[[ -n "$device" && -n "$runtime" ]]
filters=()
case "${1:-}" in
  "") ;;
  --account) filters=(-only-testing:BibleAIUITests/ReaderJourneyTests/testReadSaveNoteResumeAndSearch) ;;
  --growth) filters=(-only-testing:BibleAIUITests/ReaderJourneyTests/testZShareAndInvitationJourney) ;;
  *) echo 'Unsupported proof scope'; exit 1 ;;
esac
stamp=$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p build/proof
log="$PWD/build/proof/$stamp.log"
result="$PWD/build/proof/$stamp.xcresult"
owned=$(xcrun simctl create "BibleAI reader proof $stamp" "$device" "$runtime")
cleanup() {
  xcrun simctl shutdown "$owned" >/dev/null 2>&1 || true
  xcrun simctl delete "$owned"
  echo "INTERACTION CLEANUP PASSED $owned" | tee "$PWD/build/proof/$stamp.cleanup.log"
}
trap cleanup EXIT
xcrun simctl boot "$owned"
xcrun simctl bootstatus "$owned" -b
set +e
{
  echo "SOURCE $(git rev-parse HEAD)"
  xcodebuild test -jobs 2 -workspace BibleAI.xcworkspace -scheme BibleAIReaderTests \
    -destination "platform=iOS Simulator,id=$owned" -derivedDataPath build/reader \
    -resultBundlePath "$result" -parallel-testing-enabled NO \
    -test-timeouts-enabled YES -default-test-execution-time-allowance 360 \
    -maximum-test-execution-time-allowance 480 \
    ${filters[@]+"${filters[@]}"} CODE_SIGNING_ALLOWED=YES CODE_SIGNING_REQUIRED=YES CODE_SIGN_IDENTITY=-
} 2>&1 | tee "$log"
run_exit=${PIPESTATUS[0]}
set -e
xcrun xcresulttool get test-results summary --path "$result" --format json > "$result.summary.json"
echo "RUN_EXIT $run_exit" | tee -a "$log"
xcrun xcresulttool export attachments --path "$result" --output-path "$PWD/build/proof/$stamp-attachments"
echo "Raw native evidence: $result"
if [[ "${1:-}" == --growth ]]; then
  bundle=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' build/reader/Build/Products/Debug-iphonesimulator/BibleAI.app/Info.plist)
  data_dir=$(xcrun simctl get_app_container "$owned" "$bundle" data)
  python3 scripts/tests/growth/ui-state.py "$data_dir/Library/Preferences/$bundle.plist" "$run_exit"
fi
exit "$run_exit"
