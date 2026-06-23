#!/usr/bin/env python3
"""Offline build: cpfair tajweed annotations -> per-QPC-page token JSON.

Bakes per-ayah Tajweed segmentation at build time, snapping boundaries to
grapheme clusters and mapping cpfair's 18 rules onto the app's 7 legend
categories. The renderer (WTajweedPage) lays these tokens out on the *QPC* page
grid (line-for-line), so each page file carries every ayah that appears on that
page. NOT app code.

Two quirks of the cpfair source handled here:
  * Its text prepends the Basmala to ayah 1 of every surah except Al-Fatihah
    (rendered as ayah 1:1) and At-Tawbah (has none). We strip that prefix and
    shift the rule offsets so ayah 1 holds only its own words (the standalone
    Basmala line is drawn separately by the app).
  * The last QPC word of each ayah carries the ayah-number glyph; tokens never
    include the number (the app draws its own badge)."""
import json, os, sys, unicodedata, glob, re

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = sys.argv[1] if len(sys.argv) > 1 else "/Users/abdullahmohamed/projects/desert_launch/quran"
OUT  = os.path.join(PROJ, "assets", "data", "tajweed")

RULE_MAP = {
    "madd_muttasil": "madd_obligatory", "madd_6": "madd_obligatory",
    "madd_2": "madd_permissible", "madd_246": "madd_permissible", "madd_munfasil": "madd_permissible",
    "ghunnah": "ghunnah",
    "qalqalah": "qalqalah",
    "ikhfa": "ikhfa_idgham", "ikhfa_shafawi": "ikhfa_idgham",
    "idghaam_ghunnah": "ikhfa_idgham", "idghaam_no_ghunnah": "ikhfa_idgham",
    "idghaam_shafawi": "ikhfa_idgham", "idghaam_mutajanisayn": "ikhfa_idgham",
    "idghaam_mutaqaribayn": "ikhfa_idgham",
    "iqlab": "iqlab",
    "silent": "silent", "hamzat_wasl": "silent", "lam_shamsiyyah": "silent",
}
PRIORITY = {
    "qalqalah": 90, "madd_obligatory": 80, "madd_permissible": 70,
    "iqlab": 60, "ikhfa_idgham": 50, "ghunnah": 40, "silent": 10,
}

def deharakat(s):
    """Drop combining marks so the Basmala matches despite diacritic variants
    (e.g. surahs 95/97 spell it with an extra shadda: بِّسْمِ)."""
    return "".join(c for c in s if not unicodedata.combining(c))

def load_text(path):
    text = {}
    for ln in open(path, encoding="utf-8").read().splitlines():
        p = ln.split("|")
        if len(p) == 3:
            text[(int(p[0]), int(p[1]))] = p[2]
    return text

def ayahs_per_page(proj):
    """Every (surah, ayah) that has a word on each QPC page (1..604)."""
    pages = {}
    for fp in glob.glob(os.path.join(proj, "assets/data/mushaf_pages/page-*.json")):
        page = int(re.search(r"page-(\d+)", fp).group(1))
        j = json.load(open(fp, encoding="utf-8"))
        seen = []
        for line in j.get("lines", []):
            for w in line.get("words", []) or []:
                parts = w.get("location", "").split(":")
                if len(parts) < 2:
                    continue
                key = (int(parts[0]), int(parts[1]))
                if key not in seen:
                    seen.append(key)
        pages[page] = seen
    return pages

def tokenize(text, annotations):
    n = len(text)
    cat = [None] * n
    for an in sorted(annotations, key=lambda a: PRIORITY.get(RULE_MAP.get(a["rule"], ""), 0)):
        c = RULE_MAP.get(an["rule"])
        if c is None:
            continue
        for i in range(max(0, an["start"]), min(an["end"], n)):
            if cat[i] is None or PRIORITY.get(c, 0) >= PRIORITY.get(cat[i], 0):
                cat[i] = c
    clusters = []
    i = 0
    while i < n:
        j = i + 1
        while j < n and unicodedata.combining(text[j]):
            j += 1
        clusters.append((i, j))
        i = j
    tokens = []
    for (s, e) in clusters:
        best = None
        for k in range(s, e):
            c = cat[k]
            if c and (best is None or PRIORITY.get(c, 0) > PRIORITY.get(best, 0)):
                best = c
        seg = text[s:e]
        if tokens and tokens[-1]["r"] == best:
            tokens[-1]["t"] += seg
        else:
            tokens.append({"t": seg, "r": best})
    return tokens

def main():
    text = load_text(os.path.join(HERE, "quran-uthmani.txt"))
    ann = json.load(open(os.path.join(HERE, "cpfair.json"), encoding="utf-8"))
    by_key = {(a["surah"], a["ayah"]): a["annotations"] for a in ann}

    basmala = text[(1, 1)]
    basmala_bare = deharakat(basmala)

    ayah_tokens = {}
    bad = 0
    for (s, a), txt in text.items():
        anns = by_key.get((s, a), [])
        # Strip the prepended Basmala from ayah 1 (all surahs but Fatihah/Tawbah).
        # Compare on the bare skeleton so diacritic variants still match.
        if a == 1 and s not in (1, 9):
            words = txt.split(" ")
            if len(words) >= 4 and deharakat(" ".join(words[:4])) == basmala_bare:
                strip = len(" ".join(words[:4])) + 1
                txt = txt[strip:]
                anns = [
                    {"rule": x["rule"], "start": x["start"] - strip, "end": x["end"] - strip}
                    for x in anns
                    if x["start"] >= strip
                ]
        toks = tokenize(txt, anns)
        if "".join(t["t"] for t in toks) != txt:
            bad += 1
            print("MISMATCH", s, a, file=sys.stderr)
        ayah_tokens[(s, a)] = toks

    pages = ayahs_per_page(PROJ)
    os.makedirs(OUT, exist_ok=True)
    for page in range(1, 605):
        data = {}
        for (s, a) in pages.get(page, []):
            data[f"{s}:{a}"] = ayah_tokens.get((s, a), [])
        with open(os.path.join(OUT, f"page-{page:03d}.json"), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, separators=(",", ":"))

    print(f"ayahs: {len(text)}  reconstruct-mismatches: {bad}  pages: 604")
    print("2:1 ->", json.dumps(ayah_tokens[(2, 1)], ensure_ascii=False))
    print("112:1 ->", json.dumps(ayah_tokens[(112, 1)], ensure_ascii=False))

if __name__ == "__main__":
    main()
