# `tool/azkar_audio/` — adhkar audio pipeline

Developer scripts that turn external audio sources into the committed manifest
under `assets/data/azkar_audio/`. They run with plain `dart run`, outside the
Flutter engine, and **never run in the app**.

Full design notes: [`docs/adhkar-audio-architecture.md`](../../docs/adhkar-audio-architecture.md).

## The pipeline

```bash
# 1. Pull raw source data into tool/azkar_audio/raw/ (network)
dart run tool/azkar_audio/import_hisn_muslim.dart
dart run tool/azkar_audio/import_archive_reader.dart [readerId ...]

# 2. Match it to the app's existing adhkar → assets/data/azkar_audio/mappings/
#    + docs/reports/adhkar-audio-mapping.md
dart run tool/azkar_audio/match_adhkar.dart

# 3. Probe every URL, write real file sizes back, drop dead entries
dart run tool/azkar_audio/validate_audio.dart --write --prune
dart run tool/azkar_audio/validate_audio.dart          # clean pass for the report

# 4. Assemble assets/data/azkar_audio/readers.json
dart run tool/azkar_audio/generate_manifest.dart

# 5. Gate
flutter test && flutter analyze
```

Step 3 is run twice on purpose: the first pass prunes anything that has died,
the second produces a report with `Problems (0)`, which is what
`generate_manifest.dart` requires before it will stamp `verified: true`.

## Files

| | |
|---|---|
| `sources.dart` | **The file you edit to add a sheikh.** Curated reader metadata + the archive.org files each one contributes. |
| `adhkar_corpus.dart` | Reads the app's own adhkar off disk, composing ids with `MAzkarItem.composeId` — the same rule the app parses. |
| `http_util.dart` | `dart:io` GET/HEAD helpers with a browser User-Agent (the sources sit behind Cloudflare). |
| `import_hisn_muslim.dart` | Pulls the 132-chapter Hisn al-Muslim catalogue, cleaning book apparatus out of each dhikr. |
| `import_archive_reader.dart` | Resolves declared archive.org files to real sizes/durations; fails loudly on a filename typo. |
| `match_adhkar.dart` | Runs `AzkarAudioMatcher`, maps chapter recordings to categories, writes the mappings + audit report. |
| `validate_audio.dart` | Structural checks (dangling ids, duplicates, non-https) plus network probing. `--offline` skips the network, `--write` folds sizes back in, `--prune` drops dead entries. |
| `generate_manifest.dart` | Computes each reader's counts *from the mapping files* and writes `readers.json`. |
| `raw/`, `reports/` | Generated intermediates. Committed so a rebuild is reproducible without re-fetching. |

## Why the logic lives in `lib/`

`AzkarAudioMatcher`, `AzkarSourceTextCleaner` and `ArabicNormalizer` sit under
`lib/`, not here, so the matching rules are covered by `flutter test`. These
scripts are thin drivers around them.
