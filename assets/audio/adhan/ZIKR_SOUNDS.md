# Hourly zekr notification clips

The ten clips the hourly zekr feed plays, one per zikr. Filenames are the
`sound` values in `assets/data/notifictaions/hourly_notifications.json` — that
JSON is the source of truth; this file only documents what has to exist.

## What to drop here

Drop the ten `.mp3` files into this folder (`assets/audio/adhan/`):

| # | Zikr | File |
|---|------|------|
| 1 | سبحان الله | `zikr_01_subhan_allah.mp3` |
| 2 | الحمد لله | `zikr_02_alhamdulillah.mp3` |
| 3 | الله أكبر | `zikr_03_allahu_akbar.mp3` |
| 4 | لا إله إلا الله | `zikr_04_la_ilaha_illa_allah.mp3` |
| 5 | سبحان الله وبحمده | `zikr_05_subhan_allah_wa_bihamdih.mp3` |
| 6 | سبحان الله العظيم | `zikr_06_subhan_allah_al_azeem.mp3` |
| 7 | أستغفر الله العظيم | `zikr_07_astaghfirullah_al_azeem.mp3` |
| 8 | لا حول ولا قوة إلا بالله | `zikr_08_la_hawla_wala_quwwata.mp3` |
| 9 | اللهم صلِّ وسلم على محمد وآله وصحبه | `zikr_09_allahumma_salli.mp3` |
| 10 | حسبي الله ونعم الوكيل | `zikr_10_hasbi_allah.mp3` |

Requirements:

* **Under 30 seconds.** iOS silently falls back to the default sound for a
  notification sound longer than 30s. These are single phrases, so 2–5s is the
  target; anything past ~8s is an interruption 15 times a day.
* **One voice across all ten.** They rotate hour by hour, so mixed reciters or
  mixed dialects are obvious and jarring.
* **Licensed for redistribution.** The Forvo / Freesound links in the original
  research are not usable: Forvo blocks automated download and its clips carry
  per-upload licences that were never cleared for app redistribution, and
  Freesound requires an account to download. Whatever ships here needs a
  licence that permits bundling in a distributed app — commission the recording,
  or use a source with an explicit CC0/CC-BY grant and record the attribution.

## Wiring them up

Nothing in this folder reaches a notification on its own. Android notification
channels can only play a `res/raw/` resource and iOS only a `.caf` in the app
bundle — neither can read a Flutter asset. Run:

```bash
python3 tool/sync_zikr_sounds.py
```

which copies each `.mp3` into `android/app/src/main/res/raw/`, converts it to
`ios/Runner/Sounds/<name>.caf` with `afconvert`, and registers the `.caf` in
`ios/Runner.xcodeproj/project.pbxproj`. It is idempotent — re-run it whenever a
clip changes or a new one is added to the JSON.

Then **rebuild both apps fully** (`flutter run` is not enough; a hot restart
cannot add a native resource).

## Until then

`DSHourlyTasbih` checks whether each clip is actually bundled before using it.
While a clip is missing, that hour falls back to the existing silent
`hourly_channel` — so the feature is inert rather than broken, and each hour
starts playing its zikr the moment its file lands and the app is rebuilt.
