# Audio assets

This directory holds bundled audio used by the adhan engine and (later) other
content-driven features. Audio is **not** committed to the repo — drop the
files in matching the layout below before building a release.

## `adhan/`

10 MP3 files referenced by `assets/data/adhans.json`. The picker UI works
without them (just_audio errors are caught), but no sound plays.

```
adhan/
├── adhan_01_makkah.mp3
├── adhan_02_madinah.mp3
├── adhan_03_egypt_rifat.mp3       # default for ar-EG locale
├── adhan_04_alafasy.mp3           # default for non-Arabic locale
├── adhan_05_qatami.mp3
├── adhan_06_islam_sobhi.mp3
├── adhan_07_ozcan_turkey.mp3
├── adhan_08_aqsa.mp3
├── adhan_09_abdul_basit.mp3
└── adhan_10_fajr_husary.mp3       # default Fajr adhan
```

**Recommended encode:** 64 kbps mono MP3 — avg duration ~2:30, ~1.2 MB each,
total bundle ~12 MB.

**Sources** (free / public domain, see plan §9 for full list):

- Internet Archive — https://archive.org/details/adhans_sunnah
- Assabile — https://www.assabile.com/adhan-call-prayer
- IslamCan — https://www.islamcan.com/audio/adhan/index.shtml
- GitHub abodehq/Athan-MP3 — pre-curated for app developers

Don't forget to declare the directory in `pubspec.yaml` under `flutter > assets`
(it's already there) and to commit the actual MP3s separately or fetch them
from a CDN at runtime if size is a concern.
