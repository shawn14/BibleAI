"""Check the two shipped indexes against the reader's complete canonical chapter list."""
import re
import sqlite3
from pathlib import Path

root = Path(__file__).resolve().parents[3]
catalog = (root / "BibleAI/Models/BibleBook.swift").read_text()
books = re.findall(r'BibleBookInfo\(name: "([^"]+)".*?chapterCount: (\d+)\)', catalog)
assert len(books) == 66
path = root / "BibleAI/ScriptureIndex/scripture.sqlite3"
with sqlite3.connect(path.as_uri() + "?mode=ro", uri=True) as db:
    assert db.execute("PRAGMA integrity_check").fetchone()[0] == "ok"
    for edition, expected in (("kjv", 31102), ("web", 31098)):
        rows = db.execute(f"SELECT rowid, text FROM {edition} ORDER BY rowid").fetchall()
        assert len(rows) == expected, (edition, len(rows))
        chapters = {}
        for rowid, text in rows:
            book, remainder = divmod(rowid, 1000000)
            chapter, verse = divmod(remainder, 1000)
            assert 0 < book <= len(books) and verse > 0 and text == " ".join(text.split()) and text
            chapters.setdefault(book, set()).add(chapter)
        for number, (book, count) in enumerate(books, 1):
            assert chapters[number] == set(range(1, int(count) + 1)), (edition, book)
        print(f"{edition.upper()}: {len(rows)} nonempty verses, all 66 books and 1189 chapters")

        def matches(phrase):
            return dict(db.execute(f"SELECT rowid, text FROM {edition} WHERE {edition} MATCH ?", ('"' + phrase + '"',)))

        assert 1001001 in matches("In THE beginning")
        assert 43003016 in matches("only begotten Son" if edition == "kjv" else "one and only Son")
        assert 66022021 in matches("Amen")
        assert 43003016 not in matches("love"), "loved must not match a whole-word search for love"
        assert not matches("zzzzzzzzq")
        assert set(matches("let there be light")) == set(matches("let, there BE light"))
print("Verified phrase order, case, punctuation, word boundaries, edition wording and the final verse.")
