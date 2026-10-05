#!/usr/bin/env python3
"""Import the azkar workbook into the bundled JSON under `assets/data/azkar/`.

    python3 tool/import_azkar_sheet.py [--dry-run] [--workbook PATH]

Needs `openpyxl` (`pip3 install openpyxl`). Reads `assets/data/azkar.xlsx` by
default.

The workbook keeps every original tab beside its "(Update)" copy; only the
update tabs are read (see SHEETS). For each one it rewrites the category file
with one entry per row:

    { id, sort, description, count, zekr, zekr_en, reference,
      fadel_zeker[], audio, category }

  - `zekr` / `fadel_zeker` are the Arabic text and virtue; `zekr_en` (the
    Arabic again, plus a transliteration and a translation) and `reference`
    are what the English UI shows instead.
  - Rows are written in `sort` order. A row with no `sort` is a leftover from
    the original tab, not part of the update, and is skipped (and reported).
  - Known typos in the Arabic text are corrected through TEXT_FIXES.
  - A blank `count` takes the count the same zekr had in the current JSON —
    matched by its Arabic text with the diacritics stripped — then
    COUNT_OVERRIDES, then 1 (reported).
  - `audio` is the sheet's `Audio` name (e.g. `Zikr-S-1`); the app plays
    `assets/audio/zike-audios/Zikr-S/Zikr-S-1.mp3`. A name with no file there
    is reported and dropped, so the player hides instead of failing.

Item ids are the sheet's ids, and the app keys favorites and daily progress by
`<file>_<id>` — renumbering a tab re-points those.

The category list itself (`azkar_catigories.json`) is not touched: a new tab
needs its row added there by hand.
"""

from __future__ import annotations

import argparse
import difflib
import json
import re
import sys
from pathlib import Path

try:
    import openpyxl
except ImportError:  # pragma: no cover - environment guard
    sys.exit("openpyxl is required: pip3 install openpyxl")

ROOT = Path(__file__).resolve().parent.parent
WORKBOOK = ROOT / "assets/data/azkar.xlsx"
AZKAR_DIR = ROOT / "assets/data/azkar"
AUDIO_DIR = ROOT / "assets/audio/zike-audios"

# (Arabic tab name, output file, category name written into each item).
# A tab is picked when its title holds both the name and "(Update)".
SHEETS = [
    ("أذكار الاستيقاظ", "wakeing_up.json", "أذكار الاستيقاظ"),
    ("أذكار الصباح", "morning.json", "أذكار الصباح"),
    ("أذكار المساء", "evening.json", "أذكار المساء"),
    ("أذكار النوم", "sleeping.json", "أذكار النوم"),
    ("أذكار بعد الصلاة", "after_pray.json", "أذكار بعد الصلاة"),
    ("أذكار المسجد", "masged.json", "أذكار المسجد"),
    ("دليل العمره", "umrah_guide.json", "دليل العمرة"),
    ("مفاتيح الفرج", "faraj_keys.json", "مفاتيح الفرج العشرة"),
]

# Blank counts the text match cannot recover, keyed by output file and the
# start of the zekr's normalized Arabic text.
COUNT_OVERRIDES = {
    # The original sleep list recited all three Quls as one zekr, three times;
    # the update splits them, and only al-Ikhlas kept its count.
    ("sleeping.json", "بسم الله الرحمن الرحيم قل اعوذ برب الفلق"): 3,
    ("sleeping.json", "بسم الله الرحمن الرحيم قل اعوذ برب الناس"): 3,
}

# Missing leading text in the sheet's Arabic, as (output file, start of the
# normalized zekr, text to prepend). Matching the normalized text keeps the
# fix independent of how the sheet orders its diacritics.
TEXT_FIXES = [
    # The opening alef of "اللهم" is missing in the final workbook.
    ("sleeping.json", "للهم انت الاول", "ا"),
]

# Old-count matches below this similarity are treated as different azkar.
MATCH_THRESHOLD = 0.9

_TASHKEEL = re.compile("[ؐ-ًؚ-ٰٟۖ-ۭـ]")


def normalize(text: str) -> str:
    """Arabic letters only: no diacritics, tatweel, punctuation or alef/yaa variants."""
    s = _TASHKEEL.sub("", text or "")
    s = re.sub("[أإآٱ]", "ا", s)
    s = s.replace("ى", "ي").replace("ة", "ه").replace("ؤ", "و").replace("ئ", "ي")
    s = re.sub(r"[^ء-ي]+", " ", s)
    return re.sub(r"\s+", " ", s).strip()


def clean(value) -> str:
    """Cell text with trimmed lines and at most one blank line between paragraphs."""
    if value is None:
        return ""
    s = str(value).replace("\r\n", "\n").replace("\r", "\n")
    s = "\n".join(line.strip() for line in s.split("\n"))
    return re.sub(r"\n{3,}", "\n\n", s).strip()


def as_int(value) -> int | None:
    s = clean(value)
    if not s:
        return None
    try:
        return int(float(s))
    except ValueError:
        return None


def header_key(header) -> str:
    """Folds the header spellings the tabs use ("Zikr ( English)", "zekr (Arabic)", …)."""
    h = re.sub(r"[\s()]+", "", str(header or "")).lower()
    return {"zekr": "zikrarabic", "zekrarabic": "zikrarabic"}.get(h, h)


def find_sheet(workbook, name: str):
    for ws in workbook.worksheets:
        if "(Update)" in ws.title and name in ws.title:
            return ws
    return None


def read_rows(ws) -> list[dict]:
    rows = list(ws.iter_rows(values_only=True))
    keys = [header_key(h) for h in rows[0]]
    out = []
    for raw in rows[1:]:
        if all(clean(c) == "" for c in raw):
            continue
        out.append({k: raw[i] for i, k in enumerate(keys) if k and i < len(raw)})
    return out


def load_old(path: Path) -> list[dict]:
    if not path.exists():
        return []
    data = json.loads(path.read_text(encoding="utf-8"))
    return data if isinstance(data, list) else []


def old_count(zekr: str, old: list[dict]) -> int | None:
    target = normalize(zekr)
    best, best_score = None, 0.0
    for item in old:
        score = difflib.SequenceMatcher(
            None, target, normalize(item.get("zekr", "")), autojunk=False
        ).ratio()
        if score > best_score:
            best, best_score = item, score
    if best is None or best_score < MATCH_THRESHOLD:
        return None
    return as_int(best.get("count"))


def override_count(filename: str, zekr: str) -> int | None:
    text = normalize(zekr)
    for (file, prefix), count in COUNT_OVERRIDES.items():
        if file == filename and text.startswith(prefix):
            return count
    return None


def fix_text(filename: str, zekr: str, notes: list[str], row_id) -> str:
    """Applies TEXT_FIXES; a fixed text no longer matches, so re-runs are safe."""
    text = normalize(zekr)
    for file, prefix, missing in TEXT_FIXES:
        if file == filename and text.startswith(prefix):
            notes.append(f"id {row_id}: prepended '{missing}' to '{prefix}'")
            return missing + zekr
    return zekr


def audio_name(value, notes: list[str], row_id) -> str | None:
    name = clean(value)
    if not name:
        return None
    folder = name.rsplit("-", 1)[0]
    if not (AUDIO_DIR / folder / f"{name}.mp3").exists():
        notes.append(f"id {row_id}: audio '{name}' has no file — dropped")
        return None
    return name


def build(ws, filename: str, category: str) -> tuple[list[dict], list[str]]:
    old = load_old(AZKAR_DIR / filename)
    notes: list[str] = []
    items = []
    for index, row in enumerate(read_rows(ws)):
        zekr = clean(row.get("zikrarabic"))
        sort = as_int(row.get("sort"))
        if sort is None:
            notes.append(f"skipped unsorted row: {normalize(zekr)[:50]}")
            continue
        row_id = as_int(row.get("id")) or sort
        zekr = fix_text(filename, zekr, notes, row_id)
        count = as_int(row.get("count"))
        if count is None:
            count = old_count(zekr, old) or override_count(filename, zekr)
            if count is None:
                count = 1
                notes.append(f"id {row_id}: no count, no old match — set to 1")
            else:
                notes.append(f"id {row_id}: blank count filled with old count {count}")
        virtue = clean(row.get("fadel_zeker"))
        items.append(
            {
                "id": row_id,
                "sort": sort,
                "description": clean(row.get("description")),
                "count": count,
                "zekr": zekr,
                "zekr_en": clean(row.get("zikrenglish")),
                "reference": clean(row.get("reference")),
                "fadel_zeker": [line for line in virtue.split("\n") if line.strip()],
                "audio": audio_name(row.get("audio"), notes, row_id),
                "category": category,
                "_row": index,
            }
        )
    items.sort(key=lambda it: (it["sort"], it["_row"]))
    for it in items:
        del it["_row"]

    ids = [it["id"] for it in items]
    dupes = sorted({i for i in ids if ids.count(i) > 1})
    if dupes:
        notes.append(f"duplicate ids {dupes} — favorites/progress would collide")
    return items, notes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--dry-run", action="store_true", help="report only, write nothing")
    parser.add_argument("--workbook", type=Path, default=WORKBOOK)
    args = parser.parse_args()

    workbook = openpyxl.load_workbook(args.workbook, data_only=True)
    catalog = json.loads((AZKAR_DIR / "azkar_catigories.json").read_text(encoding="utf-8"))
    listed = {entry["filename"] for entry in catalog}

    for name, filename, category in SHEETS:
        ws = find_sheet(workbook, name)
        if ws is None:
            print(f"!! no '(Update)' tab for {name} — {filename} left as is")
            continue
        items, notes = build(ws, filename, category)
        with_audio = sum(1 for it in items if it["audio"])
        print(f"{filename}: {len(items)} azkar ({with_audio} with audio) from '{ws.title}'")
        for note in notes:
            print(f"   - {note}")
        if filename not in listed:
            print(f"   - not in azkar_catigories.json — add a row so the app lists it")
        if not args.dry_run:
            (AZKAR_DIR / filename).write_text(
                json.dumps(items, ensure_ascii=False, indent=4) + "\n", encoding="utf-8"
            )
    return 0


if __name__ == "__main__":
    sys.exit(main())
