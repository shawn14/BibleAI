#!/usr/bin/env python3
"""Cheap source/readiness checks. This does not compile or prove native behavior."""
import hashlib
import json
import pathlib
import re
import subprocess

root = pathlib.Path(__file__).resolve().parents[1]
project = root / 'BibleAI.xcodeproj/project.pbxproj'
text = project.read_text()
checksum = hashlib.sha1((root/'Podfile').read_bytes()).hexdigest()
assert 'PODFILE CHECKSUM: ' + checksum in (root/'Podfile.lock').read_text(), 'Podfile.lock checksum is stale; stop before installing'

assert 'ScriptureReaderView.swift in Sources' in text
assert 'ScriptureFeedModel.swift in Sources' in text
assert 'PassagePickerView.swift in Sources' in text
assert 'VerseStudySheet.swift in Sources' in text
assert 'Config.private.swift' not in text
assert 'Config.swift in Sources' in text
for path in root.glob('BibleAI/**/*.json'):
    json.loads(path.read_text())
for name in ('ScriptureFeedModel', 'ScriptureReaderView', 'PassagePickerView', 'VerseStudySheet'):
    matches = list(root.glob(f'BibleAI/**/{name}.swift'))
    assert len(matches) == 1, name
r = subprocess.run(['git', 'diff', '--check'], cwd=root, capture_output=True, text=True)
assert r.returncode == 0, r.stdout + r.stderr
# A missing test product name produced a real -Runner.app/PlugIns/.xctest collision.
# Read both target configurations through the project parser so this cannot silently return.
subprocess.run(['ruby', '-rxcodeproj', '-e',
    'p=Xcodeproj::Project.open("BibleAI.xcodeproj"); '
    't=p.targets.find { |v| v.name == "BibleAIUITests" }; abort "Missing UI test target" unless t; '
    't.build_configurations.each { |c| abort "Missing UI test product name in #{c.name}" '
    'unless c.build_settings["PRODUCT_NAME"] == "$(TARGET_NAME)" }'], cwd=root, check=True)
print('Source registration, target product names, lockfile, asset JSON and whitespace checks passed.')
print('Native compilation and UI outcomes are not proven by this source check.')
print('CocoaPods checkout:', 'present' if (root/'Pods/Manifest.lock').exists() else 'MISSING; run canonical prepare_dependencies on the allowed Mac')
print('Private AI configuration: not required for reading; provider study UNVERIFIED.')
