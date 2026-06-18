# QPC V4 Tajweed fonts (Approach A)

604 per-page **KFGQPC V4 Tajweed colour fonts** (`p1.ttf` … `p604.ttf`) — the
Tajweed rule colours are baked into the glyphs via the font's COLR/CPAL tables
(`QCF4001_COLOR`): Madd = red, Ghunnah = green, Qalqalah = blue, etc.

- Source: QUL / Tarteel CDN — `static-cdn.tarteel.ai/qul/fonts/quran_fonts/v4-tajweed/ttf/p{N}.ttf`.
- Loaded at runtime per page by `DSQpcFontLoader` (family `QCF_V4_P{page}`).
- The matching per-word glyph codes + line layout live in
  `assets/data/mushaf_v4/` (scraped from QUL mushaf-layout #19, validated so
  every glyph code is a subset of the corresponding font's cmap).
- Active when the reader font mode is `EQuranFontMode.tajweedV4`.

> Size note: this set is ~160 MB bundled. For production, consider on-demand
> download (see `docs/plans/Tajweed_Approach_A_Plan.md` §10) to keep the binary
> small — the loader already resolves fonts per page, so a downloaded-dir
> lookup is a localized change.
