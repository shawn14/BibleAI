#!/bin/bash
# Known cached native build + explicit development signing path from Cairn.
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -n "${MAC_RUNNER_JOB_ID:-}" ]] || { echo 'Use mac-run BibleAI prepare_account_device'; exit 1; }
[[ -z "$(git status --porcelain)" ]] || { echo 'Commit source before device preparation'; exit 1; }
[[ $(df -Pk . | awk 'NR==2 {print $4}') -ge 15728640 ]] || { echo 'Need 15 GiB free'; exit 1; }
[[ -f Pods/Manifest.lock ]] && cmp -s Podfile.lock Pods/Manifest.lock || { echo 'Pods must match the committed lockfile'; exit 1; }
APPLY_APPLE_ACCOUNT_PROFILE=1 node scripts/asc/asc.mjs scripts/asc/apple-account-device-profile.mjs
node -e 'const r=JSON.parse(require("fs").readFileSync("scripts/asc/apple-account-device-profile.out.json","utf8")); if(!r.ok) throw new Error(r.error); console.log(JSON.stringify(r.result,null,2))'
echo "SOURCE $(git rev-parse HEAD)"
xcodebuild -quiet -jobs 2 -workspace BibleAI.xcworkspace -scheme BibleAI -configuration Debug \
  -destination 'generic/platform=iOS' -derivedDataPath build/reader -disableAutomaticPackageResolution \
  CODE_SIGNING_ALLOWED=NO build > build/account/device-build.log 2>&1 \
  || { tail -70 build/account/device-build.log; exit 1; }
app="$PWD/build/reader/Build/Products/Debug-iphoneos/BibleAI.app"
python3 scripts/sign-account-device.py "$app"
node --input-type=module - "$app" <<'JS'
import fs from 'node:fs';
import { execFileSync } from 'node:child_process';
const c = JSON.parse(fs.readFileSync('scripts/asc/apple-account-device-profile.out.json','utf8')).result;
execFileSync('xcrun', ['devicectl','--timeout','120','device','install','app','--device',c.device,process.argv[2]], { stdio:'inherit' });
execFileSync('xcrun', ['devicectl','--timeout','30','device','process','launch','--device',c.device,'--terminate-existing',c.bundle], { stdio:'inherit' });
console.log('Installed and launched the signed local Account candidate; interactive login/logout proof remains.');
JS
