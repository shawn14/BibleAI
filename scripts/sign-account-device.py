#!/usr/bin/env python3
"""Sign and verify the actual Bible Debug bundle using the validated account profile.
Adapted from cairn/scripts/sign_device_app.py; no credential or portal writes.
"""
import datetime
import hashlib
import json
import os
from pathlib import Path
import plistlib
import shutil
import subprocess
import sys

if not os.environ.get('MAC_RUNNER_JOB_ID'):
    raise SystemExit('Use mac-run BibleAI prepare_account_device')
app = Path(sys.argv[1]).resolve()
result = json.loads(Path('scripts/asc/apple-account-device-profile.out.json').read_text())
assert result['ok'], 'Profile preparation failed'
c = result['result']
assert c['source'] == subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip(), 'Source changed after preparation'
profile_path = Path(c['profilePath'])
p = plistlib.loads(subprocess.check_output(['security', 'cms', '-D', '-i', str(profile_path)], stderr=subprocess.DEVNULL))
e = p['Entitlements']
info = plistlib.loads((app/'Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == c['bundle'], 'Unexpected app bundle'
assert 'iPhoneOS' in info['CFBundleSupportedPlatforms'], 'Require a physical-device build'
assert not list(app.rglob('*.appex')), 'Unexpected embedded app target; requires separate signing'
assert p['UUID'] == c['profileUUID'] and c['team'] in p['TeamIdentifier'], 'Profile changed'
assert p['ExpirationDate'] > datetime.datetime.utcnow() and c['udid'] in p['ProvisionedDevices'], 'Profile invalid for phone'
assert e.get('get-task-allow') is True and e['application-identifier'] == c['team']+'.'+c['bundle'], 'Not this app development profile'
assert c['identity'] in {hashlib.sha1(cert).hexdigest().upper() for cert in p['DeveloperCertificates']}, 'Identity not in profile'
assert c['identity'] in subprocess.check_output(['security', 'find-identity', '-v', '-p', 'codesigning'], text=True), 'Local identity unavailable'
requested = plistlib.loads(Path('BibleAI/BibleAI.entitlements').read_bytes())
entitlements = {'application-identifier': e['application-identifier'], 'com.apple.developer.team-identifier': c['team'], 'get-task-allow': True}
if 'keychain-access-groups' in e:
    entitlements['keychain-access-groups'] = [c['team']+'.'+c['bundle']]
for key,value in requested.items():
    if isinstance(value, str):
        value = value.replace('$(TeamIdentifierPrefix)', c['team']+'.').replace('$(CFBundleIdentifier)', c['bundle'])
    allowed = e.get(key)
    if isinstance(value, str) and isinstance(allowed, str):
        assert value == allowed or (allowed.endswith('*') and value.startswith(allowed[:-1])), 'Profile mismatch: '+key
    else:
        assert value == allowed, 'Profile mismatch: '+key
    entitlements[key] = value
entitlement_path = app.parent/'BibleAI.device.entitlements.plist'
entitlement_path.write_bytes(plistlib.dumps(entitlements))
shutil.copyfile(profile_path, app/'embedded.mobileprovision')
for library in sorted(app.rglob('*.dylib')):
    subprocess.run(['codesign', '--force', '--sign', c['identity'], str(library)], check=True)
for framework in sorted(app.rglob('*.framework'), key=lambda f:len(f.parts), reverse=True):
    subprocess.run(['codesign', '--force', '--sign', c['identity'], str(framework)], check=True)
subprocess.run(['codesign', '--force', '--sign', c['identity'], '--entitlements', str(entitlement_path), '--generate-entitlement-der', str(app)], check=True)
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
for library in app.rglob('*.dylib'):
    subprocess.run(['codesign', '--verify', '--strict', str(library)], check=True)
actual = plistlib.loads(subprocess.check_output(['codesign', '-d', '--entitlements', ':-', str(app)], stderr=subprocess.DEVNULL))
for key,value in entitlements.items():
    assert actual.get(key) == value, 'Signed artifact entitlement mismatch: '+key
print(json.dumps({'verifiedApp':str(app), 'version':info['CFBundleShortVersionString'], 'build':info['CFBundleVersion'], 'appleSignIn':actual['com.apple.developer.applesignin'], 'iCloudKV':actual['com.apple.developer.ubiquity-kvstore-identifier'], 'profileUUID':p['UUID']}))
