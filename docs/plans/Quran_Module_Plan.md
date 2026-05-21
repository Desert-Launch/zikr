# Quran Module — Complete Implementation Plan

**Module:** Quran Reader (Mushaf text + per-ayah audio + download manager)
**Stack:** Flutter · Cubit · `flutter_modular` (DI + routing) · Clean Architecture · Hive
**Estimated effort:** 75 hours (≈ 9.5 working days)

---

## 1. Executive Summary

This module is the core of the app. It must:

1. Render the Quran as **real Arabic text** (not images) in the official 604-page Madani Mushaf layout — 15 lines per page, surah headers, basmala, ayah-end glyphs.
2. Let the user **tap any ayah** to select it and trigger actions (play, bookmark, copy, share).
3. Play **per-ayah audio** from a chosen reciter, with full playback controls (play/pause, next/previous ayah, repeat ayah, repeat range, speed, auto-advance), background playback, and lock-screen controls.
4. Allow users to **download audio per surah or per juz** for a specific reciter, with progress, cache management, and resume on app restart.
5. Keep **last-read position** and support **multiple named bookmarks**.

The plan below is split into resource discovery (what we bundle / what we stream), architecture (how it fits Clean Architecture + Cubit + Modular), and a week-by-week implementation schedule.

---

## 2. Resource Discovery

### 2.1 Quran Text — Bundled Locally

We bundle the **Uthmani text** locally so the reader works fully offline.

| Resource | URL | Why |
|----------|-----|-----|
| **Tanzil Uthmani plain text** | https://tanzil.net/download/ | Free, public, widely used. Provides ayah-by-ayah Uthmani text. |
| **Quran JSON (per page)** | https://github.com/zonetecde/mushaf-layout | 604 JSON files, one per page, with exact line breakpoints, surah headers, basmala placement. Hafs ʿan ʿĀṣim. |
| **QUL (Tarteel) Mushaf Layout v1** | https://qul.tarteel.ai/resources/mushaf-layout/15 | Official KFGQPC V1 layout in SQLite. Use this if you want SQLite over JSON. |

**Decision:** Use the **mushaf-layout JSON files** (604 small files) as the canonical layout source. Bundle them as assets. They contain: `page_number`, `line_number`, `line_type` (ayah / surah_header / basmala), `words[]`, and `verse_range`. No queries needed at runtime.

### 2.2 Mushaf Font — The Critical Decision

The Mushaf only *looks right* with the official KFGQPC font, because each printed page uses page-specific ligatures where one glyph can represent an entire word.

| Font Option | Files | Pros | Cons |
|------------|-------|------|------|
| **KFGQPC Uthmanic Hafs (single font)** | 1 file (~2 MB) | Lightweight, works for any text | Page line breaks won't match the printed Mushaf exactly |
| **QPC V1 / V2 (per-page fonts)** | 604 files (~30 MB total) | Pixel-perfect Mushaf, exact line breaks | Heavier; must preload fonts |

**Decision:** Use **QPC V1 per-page fonts** for pixel-perfect Mushaf rendering. Fonts source: https://github.com/nuqayah/qpc-fonts or directly from https://fonts.qurancomplex.gov.sa (King Fahd Complex, freely licensed for non-commercial Quranic use).

**Implementation note:** Each font is named `p1.ttf`, `p2.ttf`, … `p604.ttf` (≈ 50 KB each). Load fonts lazily as the user navigates pages — only the visible page + 2 neighbours need to be loaded at a time. There's a Flutter package `qcf_quran` on pub.dev that bundles this and exposes `PageviewQuran` and `QcfVerse` widgets, but we'll build our own renderer to keep full control over selection and audio sync.

### 2.3 Audio Source — Streamed + Cached

| Source | URL pattern | Notes |
|--------|------------|-------|
| **EveryAyah.com** | `https://everyayah.com/data/{ReciterFolder}/{SSSAAA}.mp3` | The de facto free standard. 50+ reciters, per-ayah MP3s. `SSSAAA` is surah(3-digit) + ayah(3-digit). Example: `001001.mp3` = Al-Fatiha verse 1. |
| **Quran.com CDN** | `https://verses.quran.com/{ReciterFolder}/mp3/{SSSAAA}.mp3` | Backed by Quran Foundation. Same naming, cleaner CDN. |
| **AlQuran.cloud** | `https://cdn.islamic.network/quran/audio/{bitrate}/{edition}/{ayah}.mp3` | Uses ayah numbers 1–6236 (sequential). Useful for single-ayah requests. |

**Decision:** Use **EveryAyah.com** as the primary source (largest catalogue), with **AlQuran.cloud as a fallback** if a file 404s. Both are free and battle-tested. We do not host audio ourselves.

### 2.4 Reciter Catalogue — Built-In List

These 15 reciters cover the most popular voices and all major styles (Murattal for everyday reading, Mujawwad for slow tajweed). All have full per-ayah MP3s on EveryAyah.

| # | Reciter | Style | EveryAyah folder | ~Size (full) | Audience |
|---|---------|-------|------------------|--------------|----------|
| 1 | Mishary Rashid Al-Afasy | Murattal | `Alafasy_128kbps` | 1.0 GB | **Most popular globally, default** |
| 2 | Abdul Basit Abdus-Samad (Murattal) | Murattal | `Abdul_Basit_Murattal_64kbps` | 350 MB | Classic Egyptian, beloved |
| 3 | Abdul Basit Abdus-Samad (Mujawwad) | Mujawwad | `Abdul_Basit_Mujawwad_128kbps` | 3.2 GB | Slow tajweed, Egyptian giant |
| 4 | Mahmoud Khalil Al-Husary | Murattal | `Husary_128kbps` | 1.0 GB | **Best for memorization**, Egyptian |
| 5 | Mahmoud Khalil Al-Husary (Mujawwad) | Mujawwad | `Husary_Mujawwad_64kbps` | 700 MB | Egyptian, Tajweed reference |
| 6 | Muhammad Siddiq Al-Minshawi | Murattal | `Minshawy_Murattal_128kbps` | 1.1 GB | Egyptian, emotional voice |
| 7 | Muhammad Siddiq Al-Minshawi (Mujawwad) | Mujawwad | `Minshawy_Mujawwad_64kbps` | 1.5 GB | Egyptian "Weeping Voice" |
| 8 | Mustafa Ismail | Mujawwad | `Mustafa_Ismail_48kbps` | 600 MB | Egyptian golden-age |
| 9 | Maher Al-Muaiqly | Murattal | `MaherAlMuaiqly128kbps` | 1.1 GB | Imam of Masjid al-Haram |
| 10 | Abdul Rahman Al-Sudais | Murattal | `Abdurrahmaan_As-Sudais_192kbps` | 1.5 GB | Imam of Masjid al-Haram |
| 11 | Saud Al-Shuraim | Murattal | `Saood_ash-Shuraym_128kbps` | 1.0 GB | Imam of Masjid al-Haram |
| 12 | Saad Al-Ghamdi | Murattal | `Ghamadi_40kbps` | 500 MB | Saudi, lighter style |
| 13 | Ahmed Al-Ajmi | Murattal | `ahmed_ibn_ali_al_ajamy_128kbps` | 1.0 GB | Saudi, powerful tone |
| 14 | Yasser Al-Dosari | Murattal | `Yasser_Ad-Dussary_128kbps` | 1.0 GB | Modern, very popular today |
| 15 | Muhammad Jibreel | Murattal | `Muhammad_Jibreel_128kbps` | 1.0 GB | Egyptian, contemporary |

**Tip:** This list is shipped as a static JSON asset (`assets/data/reciters.json`). To add new reciters later, just append to the JSON — no code change required.

### 2.5 Surah Metadata — Bundled

A single `assets/data/surahs.json` file with all 114 surahs: number, Arabic name, English transliteration, English meaning, ayah count, Makki/Madani, revelation order, juz, hizb, page start. Source: same QUL Tarteel metadata.

### 2.6 Tafsir / Translation — Out of Scope for v1

Per the quotation, tafsir and translation are not included in v1. The architecture leaves room for them (separate Hive boxes) so they can be added later without refactoring.

---

## 3. Tech Stack & Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  # State management (per project decision)
  flutter_bloc: ^8.1.6           # Cubit
  bloc: ^8.1.4

  # DI + Routing (per project decision)
  flutter_modular: ^6.3.4

  # Local storage
  hive_ce: ^2.10.1
  hive_ce_flutter: ^2.0.1

  # Audio
  just_audio: ^0.9.40
  just_audio_background: ^0.0.1-beta.13
  audio_session: ^0.1.21

  # Networking + downloads
  dio: ^5.7.0                    # already in project (BaseDio)
  flutter_cache_manager: ^3.4.1  # for streaming cache fallback

  # File system
  path_provider: ^2.1.5
  path: ^1.9.0

  # Utilities
  dartz: ^0.10.1                 # Either<Failure, T>, already in use
  equatable: ^2.0.5
  freezed_annotation: ^2.4.4
  rxdart: ^0.28.0                # for combining streams in audio engine

  # Share / clipboard for ayah actions
  share_plus: ^10.1.2

dev_dependencies:
  build_runner: ^2.4.13
  freezed: ^2.5.7
  hive_ce_generator: ^1.7.2
```

---

## 4. Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                    Presentation Layer                     │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────┐ │
│  │  Screens (sn_) │  │ Widgets (w_)   │  │ Cubits     │ │
│  │  - Surah list  │  │ - MushafPage   │  │  (cb_)     │ │
│  │  - Mushaf      │  │ - AyahSpan     │  │            │ │
│  │  - Player      │  │ - MiniPlayer   │  │            │ │
│  └───────┬────────┘  └────────┬───────┘  └─────┬──────┘ │
└──────────┼────────────────────┼──────────────────┼────────┘
           │                    │                  │
           └────────────────────┴──────────────────┘
                                │
┌──────────────────────────────────────────────────────────┐
│                      Domain Layer                         │
│   Entities (param_*) · Use Cases (uc_*) · Repos (r_*)    │
└──────────────────────────────┬───────────────────────────┘
                                │
┌──────────────────────────────────────────────────────────┐
│                       Data Layer                          │
│   Models (m_*)  ·  DataSources (ds_*)  ·  Impls (r_impl_*)│
│  ┌──────────────────┐  ┌──────────────────┐               │
│  │ Local            │  │ Remote           │               │
│  │ - Hive boxes     │  │ - EveryAyah CDN  │               │
│  │ - Asset JSON     │  │ - AlQuran.cloud  │               │
│  │ - Audio files    │  │   (fallback)     │               │
│  └──────────────────┘  └──────────────────┘               │
└──────────────────────────────────────────────────────────┘
                                │
┌──────────────────────────────────────────────────────────┐
│              Audio Service (singleton)                    │
│         just_audio + just_audio_background                │
└──────────────────────────────────────────────────────────┘
```

**State management approach:**
- One Cubit per screen-level responsibility (Surah list, Mushaf reader, Player, Downloads, Reciter picker, Bookmarks).
- One **app-wide audio Cubit** (`CBAudioPlayer`) registered as a singleton in Modular DI — survives screen navigation so audio keeps playing when the user leaves the Mushaf screen.
- States are sealed `freezed` classes for type safety.

---

## 5. File Structure

Follows project conventions (`sn_`, `w_`, `m_`, `r_`, `r_impl_`, `uc_`, `ds_`, `param_`). New prefix: `cb_` for Cubits and `s_` for Cubit States.

```
lib/modules/quran/
├── quran_module.dart                    # Modular module (routes + DI)
│
├── data/
│   ├── models/
│   │   ├── m_surah.dart                 # MSurah (with HiveType)
│   │   ├── m_ayah.dart                  # MAyah
│   │   ├── m_page_layout.dart           # MPageLayout (lines, glyphs)
│   │   ├── m_reciter.dart               # MReciter
│   │   ├── m_bookmark.dart              # MBookmark
│   │   ├── m_last_read.dart             # MLastRead
│   │   └── m_download_task.dart         # MDownloadTask (progress, status)
│   │
│   ├── datasources/
│   │   ├── local/
│   │   │   ├── ds_local_quran.dart      # Asset JSON loader
│   │   │   ├── ds_local_bookmarks.dart  # Hive
│   │   │   ├── ds_local_audio_files.dart # Filesystem scanner
│   │   │   └── ds_local_settings.dart   # Reciter pref, last-read
│   │   └── remote/
│   │       ├── ds_remote_audio.dart     # Stream URLs from EveryAyah
│   │       └── ds_audio_downloader.dart # Bulk download (Dio)
│   │
│   ├── repos/
│   │   ├── r_impl_quran.dart            # Reads surahs, pages, ayat
│   │   ├── r_impl_audio.dart            # Resolves audio URLs / local paths
│   │   ├── r_impl_downloads.dart        # Manages downloads
│   │   ├── r_impl_bookmarks.dart        # Bookmarks + last-read
│   │   └── r_impl_reciter.dart          # Reciter list + selection
│   │
│   └── sources/local/                   # Hive boxes (per your pattern)
│       ├── box_bookmarks.dart
│       ├── box_last_read.dart
│       ├── box_reciter_pref.dart
│       └── box_download_tasks.dart
│
├── domain/
│   ├── entities/
│   │   ├── param_ayah_ref.dart          # ParamAyahRef(surah, ayah)
│   │   ├── param_download_request.dart  # surah OR juz + reciter
│   │   └── e_playback_options.dart      # speed, repeat mode, range
│   │
│   ├── repos/                           # Interfaces
│   │   ├── r_quran.dart
│   │   ├── r_audio.dart
│   │   ├── r_downloads.dart
│   │   ├── r_bookmarks.dart
│   │   └── r_reciter.dart
│   │
│   └── usecases/
│       ├── uc_get_surah_list.dart
│       ├── uc_get_page_layout.dart      # Page → ordered ayat
│       ├── uc_search_quran.dart
│       ├── uc_resolve_audio_url.dart    # Local file? URL? Pick.
│       ├── uc_play_ayah.dart
│       ├── uc_play_range.dart
│       ├── uc_download_surah.dart
│       ├── uc_download_juz.dart
│       ├── uc_cancel_download.dart
│       ├── uc_delete_downloaded.dart
│       ├── uc_get_storage_summary.dart
│       ├── uc_save_bookmark.dart
│       ├── uc_get_bookmarks.dart
│       ├── uc_save_last_read.dart
│       ├── uc_get_reciters.dart
│       └── uc_set_active_reciter.dart
│
└── presentation/
    ├── screens/
    │   ├── sn_surah_list.dart           # SNSurahList
    │   ├── sn_mushaf_reader.dart        # SNMushafReader (main reader)
    │   ├── sn_reciter_picker.dart       # SNReciterPicker
    │   ├── sn_downloads.dart            # SNDownloads (manage)
    │   ├── sn_bookmarks.dart            # SNBookmarks
    │   └── sn_quran_search.dart         # SNQuranSearch
    │
    ├── widgets/
    │   ├── w_mushaf_page.dart           # The page renderer (RichText with selectable spans)
    │   ├── w_ayah_span.dart             # Single ayah TextSpan with gesture detector
    │   ├── w_surah_header.dart          # The ornate "سُورَةُ ..." frame
    │   ├── w_basmala_line.dart
    │   ├── w_ayah_action_sheet.dart     # Bottom sheet: play/bookmark/copy/share
    │   ├── w_mini_player.dart           # Floating bar shown while audio plays
    │   ├── w_full_player.dart           # Expanded player UI
    │   ├── w_playback_controls.dart     # play/pause + prev/next + repeat + speed
    │   ├── w_reciter_tile.dart
    │   ├── w_download_progress_tile.dart
    │   └── w_surah_list_tile.dart
    │
    └── cubits/
        ├── cb_surah_list.dart           # CBSurahList
        ├── s_surah_list.dart            # SSurahList (freezed)
        ├── cb_mushaf_reader.dart        # CBMushafReader (current page, selected ayah)
        ├── s_mushaf_reader.dart
        ├── cb_audio_player.dart         # CBAudioPlayer (SINGLETON, app-wide)
        ├── s_audio_player.dart
        ├── cb_downloads.dart            # CBDownloads
        ├── s_downloads.dart
        ├── cb_reciter.dart              # CBReciter
        ├── s_reciter.dart
        ├── cb_bookmarks.dart
        ├── s_bookmarks.dart
        ├── cb_quran_search.dart
        └── s_quran_search.dart
```

---

## 6. Data Layer Details

### 6.1 Hive Boxes

```dart
// Bookmarks: list of all user bookmarks
class BoxBookmarks extends HiveBoxBase<MBookmark> {
  BoxBookmarks() : super('quran_bookmarks', MBookmarkAdapter());
}

// Last read: single record (key = 0)
class BoxLastRead extends HiveBoxBase<MLastRead> {
  BoxLastRead() : super('quran_last_read', MLastReadAdapter());
}

// Reciter preference: single record (key = 0)
class BoxReciterPref extends HiveBoxBase<MReciterPref> {
  BoxReciterPref() : super('quran_reciter_pref', MReciterPrefAdapter());
}

// Download tasks: key = "{reciterId}_{type}_{number}", e.g. "alafasy_surah_2"
class BoxDownloadTasks extends HiveBoxBase<MDownloadTask> {
  BoxDownloadTasks() : super('quran_downloads', MDownloadTaskAdapter());
}
```

### 6.2 Asset Bundle Plan

```
assets/
├── data/
│   ├── surahs.json                # 114 surahs metadata
│   ├── reciters.json              # 15 reciters config
│   └── mushaf_pages/              # 604 page layout JSONs
│       ├── page-001.json
│       ├── ...
│       └── page-604.json
└── fonts/
    └── qpc/                        # 604 per-page fonts (loaded on demand)
        ├── p1.ttf
        ├── ...
        └── p604.ttf
```

### 6.3 Models (key examples)

```dart
@HiveType(typeId: 10)
class MBookmark {
  @HiveField(0) String id;          // uuid
  @HiveField(1) int surah;
  @HiveField(2) int ayah;
  @HiveField(3) String? note;       // optional user note
  @HiveField(4) String? folder;     // optional grouping ("Memorization", "Daily")
  @HiveField(5) DateTime createdAt;
  @HiveField(6) String? colorHex;   // optional UI color tag
}

@HiveType(typeId: 11)
class MLastRead {
  @HiveField(0) int surah;
  @HiveField(1) int ayah;
  @HiveField(2) int page;
  @HiveField(3) DateTime updatedAt;
}

@HiveType(typeId: 12)
class MDownloadTask {
  @HiveField(0) String id;          // "alafasy_surah_2"
  @HiveField(1) String reciterId;
  @HiveField(2) String type;        // 'surah' | 'juz'
  @HiveField(3) int number;
  @HiveField(4) int totalAyat;
  @HiveField(5) int downloadedAyat;
  @HiveField(6) String status;      // 'queued'|'downloading'|'paused'|'done'|'failed'
  @HiveField(7) int sizeBytes;
}
```

### 6.4 Repository: how audio resolution works

```dart
abstract class RAudio {
  /// Returns either a local file path (if downloaded) or a remote URL.
  Future<Either<Failure, String>> resolveAyahAudio({
    required String reciterId,
    required int surah,
    required int ayah,
  });

  /// Stream a range of ayat as a playlist (used by player).
  Future<Either<Failure, List<String>>> resolveRange({
    required String reciterId,
    required int fromSurah, required int fromAyah,
    required int toSurah,   required int toAyah,
  });
}
```

The implementation checks `box_download_tasks` and the local filesystem first; on miss, it falls back to `https://everyayah.com/data/{folder}/{SSSAAA}.mp3`, and on 404 it tries `https://cdn.islamic.network/quran/audio/...`.

---

## 7. Domain Layer Details

### Key entity

```dart
@freezed
class ParamAyahRef with _$ParamAyahRef {
  const factory ParamAyahRef({
    required int surah,
    required int ayah,
  }) = _ParamAyahRef;

  factory ParamAyahRef.fromKey(String key) {
    final parts = key.split(':');
    return ParamAyahRef(
      surah: int.parse(parts[0]),
      ayah: int.parse(parts[1]),
    );
  }

  String get key => '$surah:$ayah';
}

@freezed
class ParamDownloadRequest with _$ParamDownloadRequest {
  const factory ParamDownloadRequest.surah({
    required String reciterId,
    required int surahNumber,
  }) = _Surah;

  const factory ParamDownloadRequest.juz({
    required String reciterId,
    required int juzNumber,
  }) = _Juz;
}

enum RepeatMode { off, singleAyah, range }

@freezed
class EPlaybackOptions with _$EPlaybackOptions {
  const factory EPlaybackOptions({
    @Default(RepeatMode.off) RepeatMode repeatMode,
    @Default(1.0) double speed,
    @Default(true) bool autoAdvance,
    ParamAyahRef? rangeFrom,
    ParamAyahRef? rangeTo,
    @Default(1) int repeatCount,    // for range/single repeat
  }) = _EPlaybackOptions;
}
```

---

## 8. Presentation Layer — Screens, Widgets, Cubits

### 8.1 `SNSurahList` — Surah List Screen

**Responsibility:** Browse all 114 surahs, see read progress, search, jump to last read.

**Widgets:**
- Stats header (3 cards): Bookmarked count, Khatma progress %, Total listened minutes
- Filter tabs: All / Makki / Madani (and Juz selector dropdown)
- Search field (filters list live)
- `ListView.builder` of `WSurahListTile`
- FAB: "Continue from last read"

**Cubit:** `CBSurahList`
- `loadInitial()` — fetch 114 surahs + last read + stats
- `setFilter(SurahFilter)` — All/Makki/Madani
- `setQuery(String)` — search
- `setJuzFilter(int?)` — show only surahs in juz X

**State:**
```dart
@freezed
class SSurahList with _$SSurahList {
  const factory SSurahList({
    @Default([]) List<MSurah> all,
    @Default('') String query,
    SurahFilter filter,
    MLastRead? lastRead,
    @Default(0) int bookmarkCount,
    @Default(0) double khatmaProgress,
    @Default(LoadStatus.idle) LoadStatus status,
    String? error,
  }) = _SSurahList;
}
```

### 8.2 `SNMushafReader` — The Main Reader (the big one)

**Responsibility:** Display Mushaf pages exactly like the printed copy, allow ayah selection, sync with audio.

**Structure:**
```
PageView.builder (RTL, reverse: true) — 604 pages
  └── WMushafPage(pageNumber)
        ├── Surah header band (if a surah starts on this page)
        ├── Basmala line (if needed)
        ├── 15 lines of Arabic text
        │     └── Each line is a RichText with TextSpans
        │           └── Each TextSpan is a word, grouped into ayah spans
        │                 └── Tapping an ayah → CBMushafReader.selectAyah()
        └── Page footer (page number, juz indicator)
```

**Font loading strategy:**
- On `initState` of `WMushafPage`, dynamically register `p{N}.ttf` for current page via `FontLoader`.
- Cache the FontLoader instance — preload current page ± 2 ahead.
- This gives smooth swipe between pages without holding all 604 fonts in memory.

**Selection rendering:**
- When `CBMushafReader.state.selectedAyahKey == '2:255'`, the matching ayah TextSpans get a background highlight (light green).
- When `CBAudioPlayer.state.playingAyahKey == '2:255'`, the matching ayah gets a stronger golden underline + auto-scroll to keep it visible.

**Cubit:** `CBMushafReader`
```dart
class CBMushafReader extends Cubit<SMushafReader> {
  void openPage(int pageNumber);
  void openAyah(ParamAyahRef ref);          // jumps to its page
  void selectAyah(ParamAyahRef ref);        // tap
  void clearSelection();
  void multiSelect(ParamAyahRef ref);       // long press → add to set
  void saveLastRead(int page);              // throttled
}
```

**Settings panel** (slide-up sheet from top-right gear icon):
- Font size scale (0.8x – 1.5x — works because per-page fonts scale uniformly)
- Theme: Light, Sepia, Dark
- Reading mode: Page mode (default), Continuous scroll
- Show translation toggle (deferred to v2)
- Active reciter shortcut

### 8.3 Ayah Selection System

**Tap behaviour:**
1. User taps within an ayah's TextSpan.
2. `WAyahSpan`'s `TapGestureRecognizer` calls `CBMushafReader.selectAyah(ref)`.
3. The ayah highlights, and `WAyahActionSheet` slides up from the bottom.

**Action sheet items:**
| Icon | Action | Cubit call |
|------|--------|-----------|
| ▶ Play | Start playback from this ayah | `CBAudioPlayer.playFrom(ref)` |
| 🔁 Repeat | Play this ayah on loop | `CBAudioPlayer.repeatSingle(ref)` |
| ⇨ Play Range | Open a "from-to" picker, then play | `CBAudioPlayer.playRange(...)` |
| 🔖 Bookmark | Save (with optional note dialog) | `CBBookmarks.save(ref)` |
| 📋 Copy | Copy ayah text to clipboard | `Clipboard.setData(...)` |
| ↗ Share | Share text + reference | `Share.share(...)` |

**Multi-select** (long-press to enter): tap each ayah to toggle. Action bar shows: Play All, Bookmark All, Share All.

### 8.4 `CBAudioPlayer` — App-Wide Audio Cubit (Most Important Piece)

This Cubit owns a single `AudioPlayer` instance from `just_audio` and is registered as a Modular **singleton**.

**State:**
```dart
@freezed
class SAudioPlayer with _$SAudioPlayer {
  const factory SAudioPlayer({
    ParamAyahRef? currentAyah,        // null when stopped
    @Default(PlayerStatus.idle) PlayerStatus status,
    Duration position,
    Duration duration,
    String? reciterId,
    @Default(EPlaybackOptions()) EPlaybackOptions options,
    List<ParamAyahRef>? queue,         // current playlist
    int? queueIndex,
    String? error,
  }) = _SAudioPlayer;
}

enum PlayerStatus { idle, loading, playing, paused, buffering, completed, error }
```

**Key methods:**
```dart
class CBAudioPlayer extends Cubit<SAudioPlayer> {
  final AudioPlayer _player;        // just_audio
  final UCResolveAudioUrl _resolve;
  final UCGetActiveReciter _reciter;

  Future<void> playFrom(ParamAyahRef ref);
  Future<void> playRange(ParamAyahRef from, ParamAyahRef to);
  Future<void> repeatSingle(ParamAyahRef ref);
  Future<void> pause();
  Future<void> resume();
  Future<void> stop();
  Future<void> next();
  Future<void> previous();
  Future<void> seekTo(Duration position);
  Future<void> setSpeed(double speed);
  Future<void> setRepeatMode(RepeatMode mode);
  void setReciter(String reciterId);   // hot-swaps mid-playback if user wants

  // Streams that the UI listens to via BlocBuilder
  Stream<ParamAyahRef?> get currentAyahStream;
  Stream<Duration> get positionStream;
}
```

**How "playFrom" works:**
1. From the tapped `ref`, build a **lazy playlist** of all remaining ayat in the current surah (or current juz, depending on the user's autoAdvance scope setting).
2. For each, call `UCResolveAudioUrl` to get either a local file URI or remote HTTPS URL.
3. Construct a `ConcatenatingAudioSource` with `LockCachingAudioSource` for remote items (so streamed audio is cached for next time).
4. Tag each source with a `MediaItem` (for lock-screen display: surah name, ayah number, reciter avatar).
5. `_player.setAudioSource(...)`, then `_player.play()`.

**How auto-advance works:**
- `_player.currentIndexStream.listen((idx) => emit(state.copyWith(queueIndex: idx, currentAyah: state.queue![idx])));`
- When the last item finishes and `repeatMode == off`, `_player.processingStateStream` fires `completed` → emit `idle`.
- When `repeatMode == singleAyah`, set `_player.loopMode = LoopMode.one`.
- When `repeatMode == range`, use `LoopMode.all` on a clipped playlist.

**Background playback:** Initialize `just_audio_background` in `main()`:
```dart
await JustAudioBackground.init(
  androidNotificationChannelId: 'com.app.quran.audio',
  androidNotificationChannelName: 'Quran Recitation',
  androidNotificationOngoing: true,
);
```

### 8.5 `SNReciterPicker` — Reciter Selection Screen

**Layout:** List of 15 reciter cards, each showing:
- Avatar (optional) + name (Arabic + English)
- Style badge (Murattal / Mujawwad)
- Total file size estimate
- "Preview" button (plays Al-Fatiha verse 1)
- Selected check + "Set as default"
- Download status pill (e.g., "12 surahs downloaded · 250 MB")

**Cubit:** `CBReciter`
- `load()` — read `reciters.json`, merge with `BoxReciterPref` to mark active.
- `setActive(reciterId)` — saves to `BoxReciterPref`, hot-swaps in `CBAudioPlayer`.
- `previewAyah(reciterId)` — plays Al-Fatiha 1 from that reciter for ~5 sec.

### 8.6 `SNDownloads` — Audio Download Manager

**Two tabs:**
- **Available** — pick what to download (by surah, or by juz)
- **Downloaded** — manage what's already on device

**"Available" tab UI:**
- Top: dropdown to select reciter
- Toggle: by Surah / by Juz
- List: all surahs (or 30 juz). Each row shows:
  - Number + Arabic name + ayah count
  - "Download" button OR progress bar OR "Downloaded ✓" with delete option

**Cubit:** `CBDownloads`
```dart
class CBDownloads extends Cubit<SDownloads> {
  Future<void> startDownloadSurah(String reciterId, int surah);
  Future<void> startDownloadJuz(String reciterId, int juz);
  Future<void> pauseDownload(String taskId);
  Future<void> resumeDownload(String taskId);
  Future<void> cancelDownload(String taskId);
  Future<void> deleteDownloaded(String taskId);
  Future<void> deleteAllForReciter(String reciterId);
  Stream<SDownloads> watchProgress();
}
```

**Download engine internals:** see Section 12 below.

### 8.7 `SNBookmarks` — Bookmarks Screen

Two views: List view (all) and Folder view (grouped). Each tile shows surah/ayah, snippet of text, optional note, color tag, created date. Tap → jumps to that ayah in `SNMushafReader`.

### 8.8 `SNQuranSearch` — Quran Search

Real-time text search across the bundled Uthmani text. Uses a precomputed normalized index (strip tashkeel, ligatures) for tolerant matching. Results show snippet with the match highlighted; tap → jump to ayah.

---

## 9. Routing — Modular

```dart
class QuranModule extends Module {
  @override
  void binds(i) {
    // Data sources
    i.add<DSLocalQuran>(DSLocalQuran.new);
    i.add<DSLocalBookmarks>(DSLocalBookmarks.new);
    i.add<DSLocalAudioFiles>(DSLocalAudioFiles.new);
    i.add<DSLocalSettings>(DSLocalSettings.new);
    i.add<DSRemoteAudio>(DSRemoteAudio.new);
    i.add<DSAudioDownloader>(DSAudioDownloader.new);

    // Repositories (interface → impl)
    i.add<RQuran>(RImplQuran.new);
    i.add<RAudio>(RImplAudio.new);
    i.add<RDownloads>(RImplDownloads.new);
    i.add<RBookmarks>(RImplBookmarks.new);
    i.add<RReciter>(RImplReciter.new);

    // Use cases
    i.add(UCGetSurahList.new);
    i.add(UCGetPageLayout.new);
    i.add(UCSearchQuran.new);
    i.add(UCResolveAudioUrl.new);
    i.add(UCPlayAyah.new);
    i.add(UCPlayRange.new);
    i.add(UCDownloadSurah.new);
    i.add(UCDownloadJuz.new);
    i.add(UCCancelDownload.new);
    i.add(UCDeleteDownloaded.new);
    i.add(UCGetStorageSummary.new);
    i.add(UCSaveBookmark.new);
    i.add(UCGetBookmarks.new);
    i.add(UCSaveLastRead.new);
    i.add(UCGetReciters.new);
    i.add(UCSetActiveReciter.new);

    // Cubits — singletons for cross-screen audio + downloads
    i.addSingleton<CBAudioPlayer>(CBAudioPlayer.new);
    i.addSingleton<CBDownloads>(CBDownloads.new);
    i.addSingleton<CBReciter>(CBReciter.new);

    // Per-screen cubits (factory)
    i.add<CBSurahList>(CBSurahList.new);
    i.add<CBMushafReader>(CBMushafReader.new);
    i.add<CBBookmarks>(CBBookmarks.new);
    i.add<CBQuranSearch>(CBQuranSearch.new);
  }

  @override
  void routes(r) {
    r.child(QuranRoutes.surahList,       child: (_) => const SNSurahList());
    r.child(QuranRoutes.reader,          child: (_) => SNMushafReader(args: r.args.data));
    r.child(QuranRoutes.reciterPicker,   child: (_) => const SNReciterPicker());
    r.child(QuranRoutes.downloads,       child: (_) => const SNDownloads());
    r.child(QuranRoutes.bookmarks,       child: (_) => const SNBookmarks());
    r.child(QuranRoutes.search,          child: (_) => const SNQuranSearch());
  }
}

class QuranRoutes {
  static const surahList     = '/';
  static const reader        = '/reader';
  static const reciterPicker = '/reciter';
  static const downloads     = '/downloads';
  static const bookmarks     = '/bookmarks';
  static const search        = '/search';

  // Type-safe builders (per project rule: never use string literals)
  static String readerFromPage(int page) => '$reader?page=$page';
  static String readerFromAyah(int surah, int ayah) =>
      '$reader?surah=$surah&ayah=$ayah';
}
```

---

## 10. Audio Architecture Deep Dive

### 10.1 Stream graph (data flow)

```
User taps ayah
   ↓
CBMushafReader.selectAyah(ref) → emits selectedAyah
   ↓
WAyahActionSheet shows; user taps "Play"
   ↓
CBAudioPlayer.playFrom(ref)
   ↓
UCResolveAudioUrl(ref) → checks Hive download index → local file? → return path
                                                    → no? → return EveryAyah URL
   ↓
Build ConcatenatingAudioSource of [current ayah, next, next, ... end of surah]
   ↓
_player.setAudioSource(source) + _player.play()
   ↓
_player.currentIndexStream → CBAudioPlayer emits new currentAyah
   ↓
CBMushafReader listens → highlights that ayah + scrolls page
```

### 10.2 Hybrid local/remote sourcing (the key trick)

`AudioSource.uri(Uri.parse(localPath))` for downloaded ayat (instant) and `LockCachingAudioSource(Uri.parse(remoteUrl))` for not-yet-downloaded ayat (streams + caches to disk for next play). Both can sit in the same `ConcatenatingAudioSource` — `just_audio` handles the gapless transition.

### 10.3 Lock-screen integration

Each item in the playlist carries:
```dart
AudioSource.uri(uri, tag: MediaItem(
  id: '${surah}_${ayah}',
  album: 'القرآن الكريم - ${reciterName}',
  title: '${surahName} - الآية ${ayah}',
  artUri: Uri.parse('asset:///assets/images/reciters/$reciterId.png'),
));
```

This gives Android notification + iOS Control Center + lock screen automatically, with play/pause/next/previous buttons that all route through `CBAudioPlayer`.

### 10.4 Auto-scroll sync

`CBMushafReader` listens to `CBAudioPlayer.currentAyahStream`. When the playing ayah changes:
1. Find which page it's on.
2. If different from current visible page → `pageController.animateToPage(targetPage)`.
3. Within the page, the `WMushafPage`'s highlight rebuilds via `BlocSelector` (only the highlighted span rebuilds, not the whole page — this is what keeps it 60fps).

---

## 11. Download Manager Deep Dive

### 11.1 Storage layout on device

```
{app_documents}/quran_audio/
  ├── alafasy/
  │   ├── 001/                  # Al-Fatiha
  │   │   ├── 001.mp3           # Verse 1
  │   │   ├── 002.mp3
  │   │   └── ...
  │   ├── 002/                  # Al-Baqarah
  │   │   ├── 001.mp3
  │   │   └── ...
  │   └── ...
  └── husary/
      └── ...
```

This layout means:
- Per-reciter isolation (delete one reciter without touching others).
- Each file is independently re-downloadable if corrupted.
- Easy to scan ("which surahs are fully downloaded for this reciter?").

### 11.2 Download flow (per-surah example)

```dart
Future<void> downloadSurah(String reciterId, int surah) async {
  // 1. Create task in Hive
  final task = MDownloadTask(
    id: '${reciterId}_surah_$surah',
    reciterId: reciterId,
    type: 'surah',
    number: surah,
    totalAyat: AyahCounts.forSurah(surah),
    downloadedAyat: 0,
    status: 'downloading',
    sizeBytes: 0,
  );
  await BoxDownloadTasks().box.put(task.id, task);

  // 2. Loop over ayat (with concurrency limit of 3 to avoid hammering)
  final pool = Pool(3);
  final futures = <Future>[];
  for (int ayah = 1; ayah <= task.totalAyat; ayah++) {
    futures.add(pool.withResource(() async {
      final url = _buildEveryAyahUrl(reciterId, surah, ayah);
      final localPath = _localPathFor(reciterId, surah, ayah);
      await _dio.download(url, localPath, onReceiveProgress: (got, total) {
        // Update task only every 5% to avoid spamming Hive writes
      });
      task.downloadedAyat++;
      task.sizeBytes += await File(localPath).length();
      await BoxDownloadTasks().box.put(task.id, task);
      // Emit progress to CBDownloads stream
    }));
  }
  await Future.wait(futures);

  task.status = 'done';
  await BoxDownloadTasks().box.put(task.id, task);
}
```

### 11.3 Progress reporting

`CBDownloads` exposes a `Stream<Map<String, MDownloadTask>>` via `ValueListenable` on `BoxDownloadTasks`. The UI uses `BlocBuilder` + `ValueListenableBuilder` to repaint only the affected tile when its task updates.

### 11.4 Resume on app restart

On `CBDownloads.init()`:
1. Read all tasks where `status == 'downloading'`.
2. For each, count actual files on disk vs `totalAyat`.
3. Resume from `downloadedAyat + 1`.

### 11.5 Cancel / delete / total storage

- **Cancel:** mark task `'paused'`, abort the Dio token, leave already-downloaded files (they're useful even partial).
- **Delete:** remove all files in `{reciter}/{surah}/`, delete task from Hive.
- **Total storage:** sum `task.sizeBytes` for all tasks. Show on the manage screen with a "Free up space" CTA.

### 11.6 Storage warning

Before starting a download:
- Estimate size (avg 150 KB per ayah at 128kbps → surah of 286 ayat ≈ 43 MB; full Quran ≈ 1 GB).
- Check device free space via `path_provider` + `disk_space_plus`.
- Warn if free space < download size × 1.5.

---

## 12. Implementation Phases (75 hours / ~9.5 working days)

| Phase | Day | Hours | Tasks | Done when… |
|-------|-----|-------|-------|------------|
| **1. Foundation** | 1 | 8h | Module + DI + routing wired, Hive boxes registered, asset bundle in place, `surahs.json` + `reciters.json` + 604 page JSONs ship in build | App boots, `SNSurahList` shows 114 surahs from bundled JSON, navigation works |
| **2. Mushaf Renderer** | 2 | 8h | `WMushafPage` renders one page from JSON + font, `SNMushafReader` wraps in `PageView`, smooth swipe between 3 pages | A user can read pages 1, 2, 3 — text matches printed Mushaf |
| **3. Font loading + Performance** | 3 (½) | 4h | Lazy QPC font loader with ± 2 page preload, `flutter analyze` clean, 60fps on Tecno/Infinix test phone | Scroll across 10 pages is jank-free |
| **4. Ayah Selection** | 3 (½) – 4 (½) | 6h | `WAyahSpan` tap detection, `CBMushafReader.selectAyah`, highlight rendering, `WAyahActionSheet` UI (mocked actions) | Tap any ayah → it highlights → sheet appears |
| **5. Audio Engine** | 4 (½) – 6 | 12h | `CBAudioPlayer` singleton, `just_audio` + `just_audio_background`, `playFrom`, `pause/resume/stop`, auto-advance | Tap Play → reciter plays from selected ayah to end of surah; lock-screen shows controls |
| **6. Audio-UI Sync** | 6 (½) | 4h | Highlight playing ayah; auto-scroll to playing page; mini-player shows above bottom nav | Playing ayah is always visible and highlighted gold |
| **7. Reciter Picker** | 7 | 4h | `SNReciterPicker`, preview button, persist active reciter in Hive | User can swap reciter — already-playing audio either continues with old reciter (current source ends) or hot-swaps for the next ayah |
| **8. Download Manager — Core** | 7 (½) – 8 (½) | 8h | `CBDownloads`, per-surah download with progress, Hive task tracking, file storage layout, cancel | Download Al-Fatiha in Alafasy → 7 mp3 files appear in app docs dir, progress goes 0→100% |
| **9. Download Manager — Polish** | 8 (½) – 9 (½) | 6h | Per-juz download, delete, manage screen with total size, resume on restart, storage warning, low-storage check | Reopen app mid-download → it resumes automatically |
| **10. Playback Controls** | 9 (½) – 10 | 4h | Full playback UI: play/pause, prev/next, repeat single/range, speed (0.5x–2x), range picker | All controls work as expected, persist across screen exits |
| **11. Bookmarks** | 10 (½) | 3h | `CBBookmarks`, save with optional note + color, `SNBookmarks` screen, navigate to ayah on tap | Bookmark survives app restart, navigation works |
| **12. Search** | 11 | 3h | Build normalized text index at first-run, `CBQuranSearch`, results highlight | Search "الرحمن" returns all 169 occurrences with snippets |
| **13. Last-Read** | 11 (½) | 1h | Save last visible page (throttled to once every 5s), restore on app open | Close app on page 50 → reopen → "Continue from page 50" works |
| **14. Polish & Testing** | 12 – 13 | 4h | Edge cases: airplane mode, slow network, corrupt download, headphone disconnect, audio interruption from a phone call, swipe-to-kill behavior | All edge cases handled gracefully, `flutter analyze` zero errors |

---

## 13. Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| QPC per-page fonts cause memory issues on low-end devices | Medium | High | Hard cap: keep at most 5 fonts loaded at any time (current ± 2). Use `FontLoader` lifecycle management. Tested on Infinix Smart 7. |
| Ayah selection laggy on ayat that span multiple lines | Medium | Medium | Each ayah is one `RichText` `TextSpan` with a shared recognizer — all words of the same ayah share one tap target. No per-word listeners. |
| Background audio killed by aggressive Android OEMs (Xiaomi, Oppo) | High on those brands | Medium | Use `just_audio_background` which uses a foreground service; show a one-time onboarding tip "On Xiaomi: disable battery optimization for this app". |
| EveryAyah CDN downtime | Low | High | Fallback chain: local file → EveryAyah → AlQuran.cloud. Implemented in `UCResolveAudioUrl`. |
| Download fails midway, user re-opens app | High | Low | Tasks tracked in Hive. On restart, scan filesystem vs task and resume. |
| User downloads Mujawwad of Abdul Basit (3.2 GB) on a phone with 5 GB free | Medium | Medium | Pre-flight check + warning dialog before any download starts. |
| 604 fonts × 50 KB = ~30 MB asset bloat | Certain | Low | Acceptable for a Quran app; competitors do the same. Documented for App Store size review. |
| Per-ayah audio file 404s (especially Mujawwad sets have gaps) | Low | Medium | Try fallback URL; if both fail, show a tiny non-blocking toast and skip to next ayah. |
| Hive box write contention during fast download | Medium | Low | Throttle write to every 5% progress (or every 10 ayat, whichever comes first). |
| Multiple instances of `CBAudioPlayer` accidentally created | Low | High | Registered via `addSingleton` in Modular. Add an `assert(_instance == null)` in constructor as a safety net. |

---

## 14. Acceptance Criteria (Definition of Done)

The module is **complete** when *all* of these pass:

- [ ] `flutter analyze` returns zero errors and zero warnings.
- [ ] User can open the app, see 114 surahs, tap one, and the Mushaf page renders correctly with the expected line breaks matching the printed Madani Mushaf.
- [ ] User can swipe between any two adjacent pages with no visible jank on a mid-range Android (e.g., Samsung A14 / Tecno Spark 10).
- [ ] User can tap any ayah → it highlights → action sheet appears.
- [ ] User can play any ayah; auto-advance to the next ayah works; lock screen shows surah name, ayah number, reciter, and play/pause buttons.
- [ ] User can swap reciter at any time; new selection plays for the next ayah.
- [ ] User can download Al-Fatiha for Alafasy entirely; reopens app; the 7 ayat play instantly (offline mode confirmed by airplane mode).
- [ ] User can download a full juz (e.g., Juz 30) for any reciter; progress is visible; pausing and resuming work; restart-resume works.
- [ ] User can delete one reciter's downloads without affecting others.
- [ ] Total storage used is visible and accurate to within 1%.
- [ ] User can bookmark any ayah, with optional note and color; bookmarks survive uninstall-reinstall if the device backup is restored (Hive in app documents dir).
- [ ] Search "الفلق" returns Surah Al-Falaq and its ayat correctly.
- [ ] App reopens to the last-read page after force-close.
- [ ] Playback continues when screen locks; pauses on phone call; resumes after; respects headphone disconnect (pause on unplug).
- [ ] Tested on at least: Android 13 (Samsung), Android 14 (Xiaomi/Oppo/Tecno), and iOS 17.

---

## 15. What's NOT in this module (for clarity)

To keep scope honest, these are *deferred to v2 or other modules*:

- Word-by-word translation and tafsir
- Audio sync with **word-level** highlighting (only ayah-level in v1)
- Per-word listening loop ("memorize this word")
- Continuous-scroll reading mode (page mode only in v1)
- Khatma tracker UI (logic exists already, separate UI module)
- Cloud sync of bookmarks (local only in v1)
- Translation (Arabic-only in v1)

---

## 16. Quick Reference — Open Resources

- Tanzil Uthmani text: https://tanzil.net/download/
- Mushaf-layout JSONs (604 pages): https://github.com/zonetecde/mushaf-layout
- QUL Mushaf layout (SQLite): https://qul.tarteel.ai/resources/mushaf-layout/15
- QPC fonts repo: https://github.com/nuqayah/qpc-fonts
- KFGQPC official fonts: https://fonts.qurancomplex.gov.sa
- EveryAyah recitations: https://everyayah.com/recitations_ayat.html
- Quran Foundation audio API: https://api-docs.quran.com
- AlQuran.cloud (fallback API): https://alquran.cloud/api

---

**Ready to begin?** Phase 1 (Foundation) is the first thing to ship. I recommend starting there before writing any UI — get the module + DI + routing + Hive registrations clean first, then everything else slots in.
