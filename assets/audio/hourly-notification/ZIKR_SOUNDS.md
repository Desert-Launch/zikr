# Hourly zekr notification clips

The twelve clips the hourly zekr feed plays, one per zikr. Filenames are the
`sound` values in `assets/data/notifictaions/hourly_notifications.json`, and
this folder is its `sound_dir` — that JSON is the source of truth; this file
only documents what has to exist.

## What lives here

| # | Zikr | File |
|---|------|------|
| 1 | سبحان الله | `zikr_subhan_allah.mp3` |
| 2 | الحمد لله | `zikr_alhamdulillah.mp3` |
| 3 | الله أكبر | `zikr_allahu_akbar.mp3` |
| 4 | لا إله إلا الله | `zikr_la_ilaha_illa_allah.mp3` |
| 5 | سبحان الله وبحمده | `zikr_subhan_allah_wa_bihamdih.mp3` |
| 6 | سبحان الله العظيم | `zikr_subhan_allah_al_azeem.mp3` |
| 7 | أستغفر الله العظيم وأتوب إليه | `zikr_astaghfirullah.mp3` |
| 8 | لا حول ولا قوة إلا بالله | `zikr_la_hawla_wala_quwwata.mp3` |
| 9 | اللهم صلِّ وسلِّم على نبينا محمد | `zikr_allahumma_salli.mp3` |
| 10 | حسبي الله ونعم الوكيل | `zikr_hasbi_allah.mp3` |
| 11 | الله الله ربي لا أشرك به شيئًا | `zikr_allahu_rabbi.mp3` |
| 12 | وأفوض أمري إلى الله إن الله بصير بالعباد | `zikr_ufawwidu_amri.mp3` |

They rotate with `hour % 12`, so any window of 12 hours or more (the default
is 08:00–22:00) plays every one of them each day.

Requirements for a new or replaced clip:

* **Filename = `sound` slug + `.mp3`**, and the slug must match
  `[a-z][a-z0-9_]*` — it doubles as an Android `res/raw` resource name.
* **Under 30 seconds.** iOS silently falls back to the default sound for a
  notification sound longer than 30s. These are single phrases (1–5s today);
  anything past ~8s is an interruption 15 times a day.
* **One voice across all of them.** They rotate hour by hour, so mixed
  reciters or mixed dialects are obvious and jarring.

## Wiring them up

Nothing in this folder reaches a notification on its own. Android plays a
`res/raw/` resource and iOS only a `.caf` in the app bundle — neither can read
a Flutter asset. After adding or changing a clip (and its JSON row), run:

```bash
python3 tool/sync_zikr_sounds.py
```

which copies each `.mp3` into `android/app/src/main/res/raw/`, converts it to
`ios/Runner/Sounds/<name>.caf` with `afconvert`, and registers the `.caf` in
`ios/Runner.xcodeproj/project.pbxproj`. It is idempotent — re-run it whenever a
clip changes or a new one is added to the JSON.

Then **rebuild both apps fully** (a hot restart cannot add a native resource).

## A missing clip

`DSHourlyTasbih` checks whether each clip is actually bundled before using it.
While a clip is missing, that hour falls back to the silent `hourly_channel` —
so the feature is inert rather than broken for that hour.
