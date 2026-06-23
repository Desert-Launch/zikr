# Tajweed dataset build (Approach B)

Offline, one-time generator for `assets/data/tajweed/page-*.json` — the
per-ayah Tajweed token dataset rendered by `WTajweedPage`. **Not app code.**
See `docs/plans/Tajweed_Approach_B_Plan.md`.

## What it does
1. Reads the exact Tanzil Uthmani text cpfair annotated (`quran-uthmani.txt`)
   and cpfair's per-ayah rule annotations (`cpfair.json`).
2. For each ayah, paints a per-codepoint rule array, snaps boundaries to
   grapheme clusters (so a base letter never separates from its harakat), and
   merges consecutive same-rule clusters into tokens `{ "t": text, "r": rule }`.
3. Maps cpfair's 18 rules → the app's 7 legend categories.
4. Assigns each ayah to the QPC page where it *begins* (from
   `assets/data/mushaf_pages/`) and writes one JSON per page (1..604).

Output is validated: every ayah reconstructs exactly from its tokens, and no
token starts with a combining mark.

## Sources (download once, place next to this script)
- `cpfair.json`:
  https://raw.githubusercontent.com/cpfair/quran-tajweed/master/output/tajweed.hafs.uthmani-pause-sajdah.json
  (CC BY 4.0)
- `quran-uthmani.txt` (the exact 2017 copy cpfair annotated — see their README):
  https://github.com/cpfair/quran-tajweed/files/7281388/quran-uthmani.txt
  (Tanzil.net terms of use)

## Run
```bash
python3 build_tajweed.py /absolute/path/to/repo
```
