"""Check the hand-authored guides against the Gospel Tour assignment and both bundled Bibles."""
import argparse
from collections import Counter
import json
from pathlib import Path
import re
import sqlite3

ROOT = Path(__file__).resolve().parents[3]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--index", type=Path, default=ROOT / "BibleAI/ScriptureIndex/scripture.sqlite3")
args = parser.parse_args()

plan = (ROOT / "BibleAI/Services/ReadingPlanService.swift").read_text()
tour = plan.split("private func createGospelTourPlan()", 1)[1].split("return ReadingPlan(", 1)[0]
days = re.findall(r"DailyReading\(day: (\d+),", tour)
assert days == [str(day) for day in range(1, 9)], days
assignments = re.findall(r'ReadingReference\(book: "([^"]+)", startChapter: (\d+)(?:, endChapter: (\d+))?', tour)
expected = {(book, chapter) for book, start, end in assignments
            for chapter in range(int(start), int(end or start) + 1)}
guides = json.loads((ROOT / "BibleAI/Resources/GospelTourGuides.json").read_text())
actual = Counter((item["focus"]["book"], item["focus"]["chapter"]) for item in guides)
assert actual == Counter(expected), (expected - actual.keys(), actual - Counter(expected))

metadata = (ROOT / "BibleAI/Models/BibleBook.swift").read_text()
books = re.findall(r'BibleBookInfo\(name: "([^"]+)", abbreviation:', metadata)
verse_checks = 0
with sqlite3.connect(args.index.resolve().as_uri() + "?mode=ro", uri=True) as db:
    for guide in guides:
        for field in ("title", "explanation", "reflection"):
            assert guide[field].strip(), (guide["focus"], field)
        assert guide["focus"] != guide["related"], guide["title"]
        for passage in (guide["focus"], guide["related"]):
            book, chapter = passage["book"], passage["chapter"]
            first, last = passage["first"], passage["last"]
            assert 0 < first <= last and chapter > 0, passage
            base = (books.index(book) + 1) * 1_000_000 + chapter * 1000
            for edition in ("kjv", "web"):
                query = f"SELECT rowid, text FROM {edition} WHERE rowid BETWEEN ? AND ? ORDER BY rowid"
                rows = db.execute(query, (base + first, base + last)).fetchall()
                assert [row[0] for row in rows] == list(range(base + first, base + last + 1)), (passage, edition)
                assert all(row[1].strip() for row in rows), (passage, edition)
                verse_checks += len(rows)
print(f"{len(days)} days, {len(guides)} chapter guides, {verse_checks} KJV/WEB verse checks passed")
