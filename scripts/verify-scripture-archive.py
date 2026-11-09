"""Verify the signed BibleAI IPA contains exactly the source edition, notice and study guide assets."""
from pathlib import Path
from zipfile import ZipFile
import hashlib, re, sys

root=Path(__file__).resolve().parents[1]
files={'ScriptureIndex/scripture.sqlite3':'ScriptureIndex/scripture.sqlite3',
       'ScriptureIndex/NOTICE.txt':'ScriptureIndex/NOTICE.txt',
       'GospelTourGuides.json':'Resources/GospelTourGuides.json'}
with ZipFile(sys.argv[1]) as archive:
    for suffix, source in files.items():
        matches=[n for n in archive.namelist() if re.fullmatch(r'Payload/[^/]+\.app/'+re.escape(suffix),n)]
        if len(matches)!=1: raise SystemExit('Missing or duplicated in signed IPA: '+suffix)
        data=archive.read(matches[0])
        if data!=(root/'BibleAI'/source).read_bytes(): raise SystemExit('Signed IPA differs from tested source: '+suffix)
        print(suffix, hashlib.sha256(data).hexdigest())
