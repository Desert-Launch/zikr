# قرآن — Quran companion app

Arabic-first (RTL) Flutter app for Android and iOS: Mushaf reader with per-ayah
audio and tafsir, prayer times with adhan alerts, azkar, tasbih, khatma,
Qibla, reminders, and nearby mosques.

**Stack:** Flutter (Dart `^3.9.2`) · Clean Architecture · Cubit (`flutter_bloc`)
· `flutter_modular` · `hive_ce` · `dio` · `dartz`.

## Getting started

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

`dart_defines.json` holds local build-time secrets (e.g. the Google Maps key)
and is gitignored. Without it, drop the flag — the mosques screen falls back to
photos instead of a map.

## Checks

```bash
flutter analyze   # must report zero errors
flutter test
```

## Docs

- [`CLAUDE.md`](./CLAUDE.md) — conventions and architecture rules (start here)
- [`.claude/instructions.md`](./.claude/instructions.md) — long-form developer guide
- [`docs/plans/`](./docs/plans) — module plans
