#!/usr/bin/env python3
"""Cheap source/readiness checks. This does not compile or prove native behavior."""
import json
import pathlib
import re
import subprocess

root = pathlib.Path(__file__).resolve().parents[1]
project = root / 'BibleAI.xcodeproj/project.pbxproj'
text = project.read_text()
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
print('Source registration, asset JSON and whitespace checks passed. Native compilation: UNRUN.')
print('CocoaPods checkout:', 'present' if (root/'Pods/Manifest.lock').exists() else 'MISSING; run canonical prepare_dependencies on the allowed Mac')
print('Private AI configuration: not required for reading; provider study UNVERIFIED.')
