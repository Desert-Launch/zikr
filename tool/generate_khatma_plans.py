#!/usr/bin/env python3
"""Generate every khatma plan under `assets/data/khatma/`.

A khatma plan is the mushaf cut into N daily awrad. Every plan here is built
from the same 240 rub' (quarter-hizb) boundaries the reader already trusts —
`RubStarts.rows` in `lib/modules/quran/domain/entities/rub_starts.dart`, which
was cross-checked against the ۞ marks printed in the bundled page layouts. A
30-day plan is therefore exactly one juz' a day, a 60-day plan one hizb, a
240-day plan one rub', and so on: the wird always ends on a mark the reader
can see in the mushaf.

    python3 tool/generate_khatma_plans.py

For each length in PLANS it writes `khatma_<days>_days.json` (one `day_N`
entry per wird, shape unchanged from the hand-made originals plus explicit
`start_surah_number` / `end_surah_number`) and rewrites
`khatma_metadata.json`. Plan ids are stable across runs (see PLAN_IDS): an
active `MKhatmaPlan` persists its `planId`, so an id must never be reassigned.

Lengths that do not divide 240 evenly (29 and 7 days) spread the remainder
across the plan so no two consecutive days differ by more than one rub'.

The 365-day plan is too fine for rub' marks (there are only 240), so it is
cut by ayah count instead — about seventeen a day — exactly as the hand-made
original was, minus its off-by-one glitches at surah boundaries.

Ayah text and page numbers come from `assets/data/mushaf_pages/`, so a wird
can never name a page the reader does not render.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RUB_STARTS = ROOT / "lib/modules/quran/domain/entities/rub_starts.dart"
SURAHS = ROOT / "assets/data/surahs.json"
PAGES = ROOT / "assets/data/mushaf_pages"
OUT = ROOT / "assets/data/khatma"

RUB_COUNT = 240
JUZ_COUNT = 30
LAST_AYAH = (114, 6)

# Plan length in days -> (Arabic daily-wird label, English daily-wird label).
# Labels describe the wird in the units a reader thinks in — arba' for the
# long plans, ajza' for the short ones.
PLANS: dict[int, tuple[str, str]] = {
    240: ("ربع", "One quarter"),
    120: ("ربعان", "Two quarters"),
    80: ("ثلاثة أرباع", "Three quarters"),
    60: ("أربعة أرباع", "Four quarters (half a juz')"),
    40: ("ستة أرباع", "Six quarters"),
    30: ("جزء", "One juz'"),
    29: ("جزء تقريبًا", "About one juz'"),
    20: ("جزء ونصف", "One and a half juz'"),
    15: ("جزءان", "Two juz'"),
    10: ("ثلاثة أجزاء", "Three juz'"),
    7: ("أربعة أجزاء تقريبًا", "About four juz'"),
    6: ("خمسة أجزاء", "Five juz'"),
    5: ("ستة أجزاء", "Six juz'"),
    3: ("عشرة أجزاء", "Ten juz'"),
}

# Plans cut by ayah count rather than on rub' marks.
AYAH_PLANS: dict[int, tuple[str, str]] = {
    365: ("حوالي ثلثي ربع", "About two-thirds of a quarter"),
}

# Stable ids. 1–5 were assigned by hand before this script existed and are
# referenced by persisted plans; the rest follow in the order they were added.
PLAN_IDS: dict[int, int] = {
    30: 1,
    60: 2,
    120: 3,
    240: 4,
    365: 5,
    80: 6,
    40: 7,
    29: 8,
    20: 9,
    15: 10,
    10: 11,
    7: 12,
    6: 13,
    5: 14,
    3: 15,
}

SUGGESTED = {30, 29}

ARABIC_INDIC_DIGITS = re.compile(r"[٠-٩۰-۹]")


def arabic_days(days: int) -> str:
    """`N يومًا` for 11 and up, `N أيام` for 3–10 — the tamyeez rule."""
    return f"{days} أيام" if days <= 10 else f"{days} يومًا"


def load_rub_starts() -> list[tuple[int, int, int]]:
    """The 240 `[surah, ayah, page]` rows out of the Dart source."""
    src = RUB_STARTS.read_text(encoding="utf-8")
    body = src[src.index("rows = ["):]
    body = body[: body.index("];")]
    rows = [
        (int(s), int(a), int(p))
        for s, a, p in re.findall(r"\[(\d+),\s*(\d+),\s*(\d+)\]", body)
    ]
    if len(rows) != RUB_COUNT:
        raise SystemExit(f"expected {RUB_COUNT} rub' rows, parsed {len(rows)}")
    return rows


def load_surahs() -> dict[int, dict]:
    data = json.loads(SURAHS.read_text(encoding="utf-8"))
    return {int(s["number"]): s for s in data}


def load_ayahs() -> dict[tuple[int, int], dict]:
    """Every ayah's text and the first/last page it is printed on."""
    ayahs: dict[tuple[int, int], dict] = {}
    for page in range(1, 605):
        layout = json.loads(
            (PAGES / f"page-{page:03d}.json").read_text(encoding="utf-8")
        )
        for line in layout["lines"]:
            if line["type"] != "text":
                continue
            for word in line["words"]:
                surah, ayah, _ = (int(x) for x in word["location"].split(":"))
                entry = ayahs.setdefault(
                    (surah, ayah), {"words": [], "first_page": page, "last_page": page}
                )
                entry["words"].append(word["word"])
                entry["last_page"] = page
    for entry in ayahs.values():
        text = " ".join(entry["words"])
        # The verse-number rosette rides on the last word; the caption shows the
        # number separately, exactly as DSLocalQuran strips it for sharing.
        entry["text"] = " ".join(ARABIC_INDIC_DIGITS.sub("", text).split())
    return ayahs


def previous_ayah(surah: int, ayah: int, surahs: dict[int, dict]) -> tuple[int, int]:
    if ayah > 1:
        return surah, ayah - 1
    return surah - 1, int(surahs[surah - 1]["totalAyah"])


def wird(
    start_ref: tuple[int, int],
    end_ref: tuple[int, int],
    surahs: dict[int, dict],
    ayahs: dict[tuple[int, int], dict],
) -> dict:
    start_surah, start_ayah = start_ref
    end_surah, end_ayah = end_ref
    start = ayahs[start_ref]
    end = ayahs[end_ref]
    return {
        "start_ayah_number": start_ayah,
        "end_ayah_number": end_ayah,
        "start_ayah_text": start["text"],
        "end_ayah_text": end["text"],
        "start_surah_en": surahs[start_surah]["name"],
        "start_surah_ar": surahs[start_surah]["arabic"],
        "end_surah_en": surahs[end_surah]["name"],
        "end_surah_ar": surahs[end_surah]["arabic"],
        "start_surah_number": start_surah,
        "end_surah_number": end_surah,
        "start_page_number": start["first_page"],
        "end_page_number": end["last_page"],
    }


def build_rub_plan(
    days: int,
    rubs: list[tuple[int, int, int]],
    surahs: dict[int, dict],
    ayahs: dict[tuple[int, int], dict],
) -> dict[str, dict]:
    """Day N covers a contiguous run of arba', so it starts on a printed mark."""
    plan: dict[str, dict] = {}
    for day in range(days):
        lo = day * RUB_COUNT // days
        hi = (day + 1) * RUB_COUNT // days
        start_surah, start_ayah, start_page = rubs[lo]
        if hi == RUB_COUNT:
            end = LAST_AYAH
        else:
            end = previous_ayah(rubs[hi][0], rubs[hi][1], surahs)
        entry = wird((start_surah, start_ayah), end, surahs, ayahs)
        if entry["start_page_number"] != start_page:
            raise SystemExit(
                f"rub' {lo + 1} starts {start_surah}:{start_ayah} on page "
                f"{entry['start_page_number']}, RubStarts says {start_page}"
            )
        plan[f"day_{day + 1}"] = entry
    return plan


def build_ayah_plan(
    days: int,
    surahs: dict[int, dict],
    ayahs: dict[tuple[int, int], dict],
) -> dict[str, dict]:
    """Day N covers an equal share of the 6236 ayat, in mushaf order."""
    order = [
        (surah, ayah)
        for surah in sorted(surahs)
        for ayah in range(1, int(surahs[surah]["totalAyah"]) + 1)
    ]
    total = len(order)
    plan: dict[str, dict] = {}
    for day in range(days):
        lo = day * total // days
        hi = (day + 1) * total // days
        plan[f"day_{day + 1}"] = wird(order[lo], order[hi - 1], surahs, ayahs)
    return plan


def metadata_entry(days: int) -> dict:
    label_ar, label_en = (PLANS | AYAH_PLANS)[days]
    return {
        "id": PLAN_IDS[days],
        "name_en": f"{days}-day khatma",
        "name_ar": f"ختمة {arabic_days(days)}",
        "days": days,
        "path": f"assets/data/khatma/khatma_{days}_days.json",
        "parts_per_day": round(JUZ_COUNT / days, 6),
        "parts_per_day_en": label_en,
        "parts_per_day_ar": label_ar,
        "quarters_per_day": round(RUB_COUNT / days, 6),
        "quarters_per_day_en": label_en,
        "quarters_per_day_ar": label_ar,
        "is_suggested": days in SUGGESTED,
    }


def dump(path: Path, payload: object) -> None:
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )


def main() -> None:
    rubs = load_rub_starts()
    surahs = load_surahs()
    ayahs = load_ayahs()

    generated: dict[int, dict[str, dict]] = {
        days: build_rub_plan(days, rubs, surahs, ayahs) for days in PLANS
    }
    generated.update(
        {days: build_ayah_plan(days, surahs, ayahs) for days in AYAH_PLANS}
    )
    for days, plan in generated.items():
        dump(OUT / f"khatma_{days}_days.json", plan)
        print(f"khatma_{days}_days.json: {len(plan)} awrad")

    metadata = [metadata_entry(days) for days in generated]
    metadata.sort(key=lambda entry: -entry["days"])
    dump(OUT / "khatma_metadata.json", metadata)
    print(f"khatma_metadata.json: {len(metadata)} plans")


if __name__ == "__main__":
    main()
