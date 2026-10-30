#!/bin/bash
# Records the App Store preview: builds once, then screen-records the simulator while
# ReaderJourneyTests/testPreviewRecording drives the app. Output: build/preview/raw.mp4
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -n "${MAC_RUNNER_JOB_ID:-}" ]] || { echo "Run through mac-run BibleAI preview_video"; exit 1; }
[[ -f Pods/Manifest.lock ]] || { echo 'CocoaPods missing: run prepare_dependencies first'; exit 1; }
xcrun simctl list devices booted --json | python3 -c 'import json,sys; a=json.load(sys.stdin); assert not any(d["state"]=="Booted" for g in a["devices"].values() for d in g), "Another simulator is booted"'
read -r device runtime < <(xcrun simctl list --json | python3 -c '
import json,sys
j=json.load(sys.stdin)
r=next((r for r in reversed(j["runtimes"]) if r.get("isAvailable") and "iOS" in r["name"]), None)
d=next((d for d in j["devicetypes"] if d["name"]=="iPhone 16 Pro Max"), None)
if not r or not d: sys.exit("No iPhone 16 Pro Max / iOS runtime")
print(d["identifier"],r["identifier"])')
out="$PWD/build/preview"; mkdir -p "$out"; rm -f "$out/raw.mp4"
owned=$(xcrun simctl create "BibleAI preview $(date +%s)" "$device" "$runtime")
cleanup() { [[ -n "${REC:-}" ]] && kill -INT "$REC" 2>/dev/null || true; xcrun simctl shutdown "$owned" >/dev/null 2>&1 || true; xcrun simctl delete "$owned"; echo "CLEANUP $owned"; }
trap cleanup EXIT
xcrun simctl boot "$owned"; xcrun simctl bootstatus "$owned" -b >/dev/null
xcrun simctl status_bar "$owned" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
common=(-workspace BibleAI.xcworkspace -scheme BibleAIReaderTests -destination "platform=iOS Simulator,id=$owned" -derivedDataPath build/preview-dd -jobs 2 CODE_SIGNING_ALLOWED=YES CODE_SIGN_IDENTITY=-)
xcodebuild build-for-testing "${common[@]}" > "$out/build.log" 2>&1 || { grep -E "error:" "$out/build.log" | head; exit 1; }
xcrun simctl io "$owned" recordVideo --codec=h264 --force "$out/raw.mp4" >/dev/null 2>&1 & REC=$!
sleep 2
TEST_RUNNER_RECORD_PREVIEW=1 xcodebuild test-without-building "${common[@]}" -only-testing:BibleAIUITests/ReaderJourneyTests/testPreviewRecording > "$out/test.log" 2>&1 || { tail -30 "$out/test.log"; }
sleep 1; kill -INT "$REC"; wait "$REC" 2>/dev/null || true; REC=
[[ -s "$out/raw.mp4" ]] && echo "PREVIEW RAW OK $(du -h "$out/raw.mp4" | cut -f1)" || { echo "NO VIDEO"; exit 1; }
grep -E "Test Case .*testPreviewRecording.*(passed|failed)" "$out/test.log" || true
