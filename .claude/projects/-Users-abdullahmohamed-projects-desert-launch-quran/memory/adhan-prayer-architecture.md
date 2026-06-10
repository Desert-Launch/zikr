---
name: adhan-prayer-architecture
description: How prayer times + adhan notifications are wired (Aladhan API, rolling scheduler, bundled clips)
metadata:
  type: project
---

Prayer + adhan stack (as of 2026-06, this session):

- **Prayer times** come from the **Aladhan remote API** (`api.aladhan.com/v1/timings`), NOT on-device `adhan` (removed). `DSRemotePrayer` has its own Dio. Country (from `geocoding` reverse-geocode) → method via `PrayerMethodMapper`; madhab → Aladhan `school`. Flow: `CBPrayerTimes` → `UCGetPrayerTimes` → `RImplPrayer`.
- **Adhan notifications**: `AdhanScheduler` (lib/modules/adhan/services/) owns a **rolling 7-day** schedule (id bands 200000/300000), replacing the old today-only logic in `CBPrayerTimes`. Triggered on prayer refresh + settings changes + app launch. Per-prayer toggles live in `MPrayerSettings.notifyForPrayer`; behaviour in `MAdhanSettings`; voice in `MAdhanPreference`.
- **Voice catalog/download**: `RAdhan`/`RImplAdhan` (own Dio, falls back to bundled `assets/data/adhans.json` when CDN fails). `CBAdhanDownload` drives the picker's download UI. First-launch `AdhanBootstrap` runs once.
- **Settings UI**: `SNAdhanSettings` (/adhan/settings), reached via a bell icon in the prayer header. Voice picker = `SNAdhanPicker` (/adhan/).
- Time display uses `TimeFormat.hm12()` (12h + Arabic ص/م).

**Assets — now CC-licensed (licensing resolved):** the islamcan placeholders were replaced with 4 Creative-Commons adhans from Wikimedia Commons: `adhan_mecca` (CC BY 3.0, default), `adhan_hassan2` (CC BY-SA 4.0), `adhan_aaqib` (CC BY-SA 4.0), `adhan_wiki` (CC BY-SA 3.0, is_fajr_default). Each carries `license`/`author`/`source_url` in `adhans.json`; `MAdhan.attribution` shows "license · author" in the picker (CC compliance). Full credits in `assets/audio/adhan/CREDITS.md`. Pipeline per voice: full mp3 in `assets/audio/adhan/<id>.mp3`, ≤27s clip in `res/raw/<id>.mp3` (+ `adhan_mecca_full.mp3` for bg-full), `.caf` in `ios/Runner/Sounds/`. Catalog regenerated. CC BY-SA is fine in a closed app (mere aggregation) as long as attribution + license shown and no DRM on the file.

**M6 background full-adhan (Android):** done WITHOUT `audio_service` — Android notification-channel sound has no 30s cap and plays when killed, so `AdhanScheduler._resolveChannel` creates a per-voice `adhan_<id>_full` channel pointing at `res/raw/<id>_full.mp3` when `androidBackgroundFullAdhan` + full mode are on. Only the default has a `_full` clip bundled; other voices need `<id>_full.mp3` dropped in res/raw.

**iOS sounds — DONE:** all 10 voices converted to compact IMA4 `.caf` in `ios/Runner/Sounds/` and registered in the Runner target's Copy Bundle Resources via the `xcodeproj` Ruby gem (project.pbxproj verified, lints OK).

**Remote catalog — opt-in:** `EndPoints.adhanCatalog` defaults to `''` (empty = remote disabled, no network). `RImplAdhan.fetchCatalog` skips the network when empty and serves bundled `adhans.json`. `MAdhan.isDownloadable` = `!bundled && fullUrl!=''` (bundled voices show no download button). `adhan_catalog.json` template at repo root — to enable OTA voices, host it and paste the URL into `EndPoints.adhanCatalog`.

**Still TODO (needs user infra/decisions):** host the catalog if OTA voice additions are wanted; confirm/replace audio licensing (placeholder islamcan files). See [[external-plans-adapt-to-conventions]].
