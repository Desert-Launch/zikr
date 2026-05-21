# Project Instructions — Quran App (قرآن)

> Comprehensive developer & AI-assistant guide for this Flutter project.
> For a quick scannable version aimed at AI tools, see [`CLAUDE.md`](./CLAUDE.md).
> For the Quran reader module deep-dive, see [`docs/plans/Quran_Module_Plan.md`](./docs/plans/Quran_Module_Plan.md).

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Quick Start](#2-quick-start)
3. [Task Handling Protocol](#3-task-handling-protocol)
4. [Editing Workflow](#4-editing-workflow)
5. [Definition of Done](#5-definition-of-done)
6. [Critical Rules](#6-critical-rules-never-violate)
7. [File Naming Conventions](#7-file-naming-conventions)
8. [Architecture](#8-architecture)
9. [State Management — Cubit](#9-state-management--cubit)
10. [Routing & DI — Modular](#10-routing--di--modular)
11. [Data Layer Patterns](#11-data-layer-patterns)
12. [Networking & Error Handling](#12-networking--error-handling)
13. [Local Storage — Hive](#13-local-storage--hive)
14. [UI Patterns](#14-ui-patterns)
15. [Forms](#15-forms)
16. [Localization (i18n)](#16-localization-i18n)
17. [Testing & Quality Gates](#17-testing--quality-gates)
18. [Quick Reference](#18-quick-reference)

---

## 1. Project Overview

**App:** قرآن — a Quran companion mobile app for Android and iOS.

**Core features:**
- Custom Mushaf reader (text-based, official Madani 15-line layout)
- Per-ayah selection and per-ayah audio playback
- Multiple reciters with per-surah / per-juz audio download manager
- Prayer times with custom adhan audio engine and background scheduling
- Azkar, tasbih, reminders, nearby mosques, Qibla compass
- Bookmarks, khatma tracking, last-read persistence

**Audience:** Arabic-first users in MENA, primarily Egypt. The app is RTL by default. English, Urdu, and French are planned localizations.

**Tech stack:**
- Flutter (latest stable)
- State management: **Cubit** via `flutter_bloc`
- DI + Routing: **flutter_modular**
- Local storage: **hive_ce** + `hive_ce_flutter`
- Networking: `dio` (via shared `BaseDio`)
- Audio: `just_audio` + `just_audio_background`
- Functional error handling: `dartz` (`Either<Failure, T>`)
- Immutable state: `freezed`

---

## 2. Quick Start

### Initial context scan

When opening this codebase, do a *quick* scan (≤ 40 seconds):

- `lib/modules/` — feature modules (each is a `Module` with its own `data/`, `domain/`, `presentation/`)
- `lib/core/` — shared services (network, theme, DI, forms, widgets, utilities)
- `lib/main.dart` — Hive init, DI bootstrap, audio service init, app entrypoint
- `assets/` — Quran data (page JSONs, reciters JSON, fonts), localization files

Don't deep-read the whole tree. Grep for what you need when you need it.

### The app is already running

The user always has the app running in another terminal with hot reload.

- **DO NOT** run `flutter run`.
- Save your edits — they auto-reload.
- If a **hot restart** is needed (DI change, new Hive adapter, new route, new asset bundle, native plugin change), tell the user. Do not restart yourself.
- `flutter analyze` and `dart fix --apply` are fine to run.

### Confirmation message

After reading this, say:
> ✅ I've loaded the Quran app preferences. I'll do a quick scan for context, follow all conventions (Cubit + Modular + Clean Architecture), and remember the app is already running with hot reload.

---

## 3. Task Handling Protocol

For any non-trivial change, **before** writing code, report:

```
📋 Task: <one-line description>
🏷️ Type: 🐛 Bug | ✨ Feature | 🔄 Refactor | ❓ Question | 🔍 Research | 🎨 Style | 📝 Docs
📍 Scope:
  • <file path>  → <action>
  • <file path>  → <action>
⚠️ Impact: <what might break>
🔧 Approach: <one-line strategy>
```

If the scope is obvious (e.g., a typo fix, a color tweak), skip the block and just do it. Otherwise wait for user confirmation.

### Example

```
📋 Task: Fix Mushaf page not preloading next font
🏷️ Type: 🐛 Bug
📍 Scope:
  • w_mushaf_page.dart      → call FontLoader.load for page+1 in initState
  • mg_font_cache.dart      → evict pages outside ±2 window
⚠️ Impact: Memory usage during long reading sessions
🔧 Approach: Sliding-window LRU cache keyed by pageNumber, max 5

Proceeding...
```

---

## 4. Editing Workflow

### ⚠️ Think before you edit

Follow this 4-step workflow on any non-trivial change:

#### Step 1 — Research

- Read the target file fully (not just the function you'll change)
- Grep for all usages of the symbol you're modifying
- Check related files (imports, dependent widgets, route definitions)
- Understand the full surrounding context

#### Step 2 — Organize

- Identify the **root cause**, not just the symptom
- Plan the fix step-by-step
- Consider side effects (does this Cubit emit to anyone else?)
- Walk through edge cases
- Check if the same bug exists elsewhere

#### Step 3 — Execute

- Make precise edits matching exact indentation
- Update **all** affected locations
- Verify related code still works
- Add safeguards (null checks, error states) where reasonable

#### Step 4 — Own it

- Run `flutter analyze` — fix every error
- Mentally walk the code flow
- Ensure the fix is **complete**, not partial
- Check for similar issues elsewhere in the codebase

### 🔥 Never abandon a task

- If you hit an error → fix it
- If multiple places need fixing → fix them all
- If unsure → research more, don't guess
- If `flutter analyze` shows new errors after your edit, you are not done

### Before any edit, ask yourself

| Question | Why it matters |
|----------|----------------|
| Where else is this used? | Avoid breaking other features |
| What's the root cause? | Fix the problem, not the symptom |
| Will this affect related code? | Prevent cascade failures |
| Is there a shared pattern? | Maintain consistency |
| Did I run `flutter analyze`? | Catch issues before they ship |

### 🚫 Never

- Edit without reading the full file first
- Change code you don't understand
- Fix one place when multiple places need it
- Skip checking for similar issues elsewhere
- Leave half-solutions behind
- Say "done" when there are still errors

---

## 5. Definition of Done

A task is **complete** only when ALL of these are true:

| Checkpoint | Verification |
|------------|-------------|
| `flutter analyze` | Zero errors (warnings acceptable if pre-existing) |
| Logic verified | Mentally walked through the code flow |
| All locations updated | Grepped for usages, updated all affected files |
| Code generated (if needed) | Ran `build_runner` for Freezed/Hive changes |
| Root cause fixed | Not just a symptom patch |
| Similar issues checked | Same bug doesn't exist elsewhere |
| Hot restart noted (if needed) | User informed when restart is required |

---

## 6. Critical Rules — NEVER violate

### Rule 1 — Naming

- **NO** project prefixes on shared widgets (✅ `WButton`, ❌ `QrnButton`)
- **NO** `Screen` suffix on screen classes (✅ `SNHome`, ❌ `SNHomeScreen`)
- Use exact prefixes (full table in §7): `sn_`, `w_`, `cb_`, `s_`, `f_`, `m_`, `box_`, `e_`, `param_`, `r_`, `r_impl_`, `uc_`, `ds_`

### Rule 2 — Imports

- **ALWAYS** use package imports: `import 'package:qrn_app/...'`
- **NEVER** use relative imports (`../../`) — enforced by analyzer
- Sort imports alphabetically (linter enforces this)
- For conflicting names: `import 'package:x/x.dart' as x;`

### Rule 3 — Navigation

- **NEVER** navigate with string literals
  ```dart
  // ❌
  Modular.to.pushNamed('/quran/reader?surah=2&ayah=255');

  // ✅
  Modular.to.pushNamed(QuranRoutes.readerFromAyah(2, 255));
  ```
- Every feature module exports a `<Feature>Routes` class with type-safe builders.

### Rule 4 — Null safety

- **NEVER** use null assertion (`!`) unless you've **just** verified non-null on the line above
- Prefer `?.`, `??`, `??=`, and explicit null checks
  ```dart
  // ✅
  final ayah = state.selectedAyah;
  if (ayah == null) return _buildEmpty();
  // ayah is non-null here

  // ❌
  final ayah = state.selectedAyah!;   // can crash
  ```

### Rule 5 — Code quality

- **ALWAYS** run `flutter analyze` after changes
- Zero errors required before considering a task done
- Use `dart fix --apply` to clean up trivial issues

### Rule 6 — Architecture

- **State management:** Cubit only (no Bloc<Event,State>, no Provider, no MobX)
- **Clean Architecture:** data → domain → presentation
- **DI + Routing:** `flutter_modular` exclusively

### Rule 7 — Localization

- **FLAT** JSON files only — no nested structures
- Keys use feature-prefixed snake_case: `auth_email`, `quran_reader_play`, `prayer_times_fajr`

### Rule 8 — Component reuse

- **ALWAYS** use shared widgets when one exists
- **NEVER** use framework widgets directly when a shared one exists
  - Use `WSharedScaffold`, not `Scaffold`
  - Use `WLoadingIndicator`, not `CircularProgressIndicator`
  - Use `WCachedImage`, not `Image.network` or `CachedNetworkImage`
  - Use `WAppButton.primary(...)`, not raw `ElevatedButton`
- Shared widgets live in `lib/core/widgets/` or `lib/presentation/shared/`

---

## 7. File Naming Conventions

| Type | File pattern | Class pattern | Location | Example |
|------|--------------|---------------|----------|---------|
| **Screen** | `sn_*.dart` | `SN*` | `modules/<feat>/presentation/screens/` | `sn_surah_list.dart` → `SNSurahList` |
| **Widget** | `w_*.dart` | `W*` | `modules/<feat>/presentation/widgets/` (or `core/widgets/` for shared) | `w_mushaf_page.dart` → `WMushafPage` |
| **Cubit** | `cb_*.dart` | `CB*` | `modules/<feat>/presentation/cubits/` | `cb_audio_player.dart` → `CBAudioPlayer` |
| **Cubit State** | `s_*.dart` (freezed) | `S*` | `modules/<feat>/presentation/cubits/` | `s_audio_player.dart` → `SAudioPlayer` |
| **Form** | `f_*.dart` | `F*` | `core/services/forms/` | `f_login.dart` → `FLogin` |
| **Param/Entity** | `param_*.dart` | `Param*` | `modules/<feat>/domain/entities/` | `param_ayah_ref.dart` → `ParamAyahRef` |
| **Plain Entity** | `e_*.dart` | `E*` | `modules/<feat>/domain/entities/` | `e_playback_options.dart` → `EPlaybackOptions` |
| **Model (Hive/JSON)** | `m_*.dart` | `M*` | `modules/<feat>/data/models/` | `m_surah.dart` → `MSurah` |
| **Hive Box wrapper** | `box_*.dart` | `Box*` | `modules/<feat>/data/sources/local/` | `box_bookmarks.dart` → `BoxBookmarks` |
| **Repo Interface** | `r_*.dart` | `R*` | **`domain/repos/`** | `r_quran.dart` → `RQuran` |
| **Repo Implementation** | `r_impl_*.dart` | `RImpl*` | **`data/repos/`** | `r_impl_quran.dart` → `RImplQuran` |
| **Use Case** | `uc_*.dart` | `UC*` | `domain/usecases/` | `uc_get_surah_list.dart` → `UCGetSurahList` |
| **Data Source** | `ds_*.dart` | varies | `data/datasources/local/` or `remote/` | `ds_local_quran.dart` → `DSLocalQuran` |

### Clean Architecture rule (very strict)

- **Interfaces** (`r_*.dart`) MUST live in **`domain/repos/`** — abstractions only
- **Implementations** (`r_impl_*.dart`) MUST live in **`data/repos/`** — concrete classes
- Never mix interfaces and implementations in the same folder

---

## 8. Architecture

### Clean Architecture layers

```
lib/
├── core/                       # App-wide foundation
│   ├── di/                     # Modular root module
│   ├── services/
│   │   ├── network/            # BaseDio, end_points.dart
│   │   ├── forms/              # Shared form controllers
│   │   └── audio/              # Audio service init
│   ├── theme/                  # Colors, typography, dimensions
│   ├── utils/                  # Validators, extensions, helpers
│   └── widgets/                # Shared widgets (WAppButton, WSharedScaffold, …)
│
├── modules/                    # Feature modules (each = one Modular Module)
│   ├── quran/
│   │   ├── data/
│   │   │   ├── datasources/    # ds_*.dart (remote + local)
│   │   │   ├── models/         # m_*.dart
│   │   │   ├── repos/          # r_impl_*.dart
│   │   │   └── sources/local/  # box_*.dart
│   │   ├── domain/
│   │   │   ├── entities/       # param_*.dart, e_*.dart
│   │   │   ├── repos/          # r_*.dart (interfaces)
│   │   │   └── usecases/       # uc_*.dart
│   │   ├── presentation/
│   │   │   ├── screens/        # sn_*.dart
│   │   │   ├── widgets/        # w_*.dart
│   │   │   └── cubits/         # cb_*.dart, s_*.dart
│   │   └── quran_module.dart   # Modular Module (DI + routes)
│   │
│   ├── prayer_times/
│   ├── azkar/
│   ├── tasbih/
│   ├── reminders/
│   ├── mosques/
│   ├── qibla/
│   └── settings/
│
└── flavors/                    # dev / prod environment configs
```

### Module template

Every feature module is a `flutter_modular` `Module`:

```dart
class QuranModule extends Module {
  @override
  void binds(i) {
    // Data sources
    i.add<DSLocalQuran>(DSLocalQuran.new);
    i.add<DSRemoteAudio>(DSRemoteAudio.new);

    // Repositories — interface → impl
    i.add<RQuran>(RImplQuran.new);
    i.add<RAudio>(RImplAudio.new);

    // Use cases
    i.add(UCGetSurahList.new);
    i.add(UCPlayAyah.new);

    // Cubits — singletons for cross-screen, factory for per-screen
    i.addSingleton<CBAudioPlayer>(CBAudioPlayer.new);
    i.add<CBSurahList>(CBSurahList.new);
    i.add<CBMushafReader>(CBMushafReader.new);
  }

  @override
  void routes(r) {
    r.child(QuranRoutes.surahList, child: (_) => const SNSurahList());
    r.child(QuranRoutes.reader,    child: (_) => SNMushafReader(args: r.args.data));
  }
}
```

### Module Routes class (type-safe)

Every module exports a `<Feature>Routes` class. **No string literals anywhere else** in the app.

```dart
class QuranRoutes {
  static const surahList = '/';
  static const reader    = '/reader';
  static const bookmarks = '/bookmarks';

  // Type-safe builders
  static String readerFromPage(int page) => '$reader?page=$page';
  static String readerFromAyah(int surah, int ayah) =>
      '$reader?surah=$surah&ayah=$ayah';
}
```

Used as:
```dart
Modular.to.pushNamed(QuranRoutes.readerFromAyah(2, 255));
```

---

## 9. State Management — Cubit

We use **Cubit** from `flutter_bloc`. No `Bloc<Event, State>`. The redundancy of writing event classes does not justify itself for this app's complexity.

### Cubit structure

```dart
// cb_quran_reader.dart
class CBQuranReader extends Cubit<SQuranReader> {
  CBQuranReader(this._getPage) : super(const SQuranReader());

  final UCGetPageLayout _getPage;

  Future<void> openPage(int page) async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _getPage(page);
    result.fold(
      (failure) => emit(state.copyWith(
        status: LoadStatus.error,
        error: failure.message,
      )),
      (layout) => emit(state.copyWith(
        status: LoadStatus.success,
        layout: layout,
        error: null,
      )),
    );
  }

  void selectAyah(ParamAyahRef ref) {
    emit(state.copyWith(selectedAyah: ref));
  }

  void clearSelection() {
    emit(state.copyWith(selectedAyah: null));
  }
}
```

### State structure (always freezed)

```dart
// s_quran_reader.dart
@freezed
class SQuranReader with _$SQuranReader {
  const factory SQuranReader({
    @Default(LoadStatus.idle) LoadStatus status,
    MPageLayout? layout,
    ParamAyahRef? selectedAyah,
    String? error,
  }) = _SQuranReader;
}

enum LoadStatus { idle, loading, success, error }
```

### UI consumption

**Use `BlocSelector` whenever possible** — it rebuilds only when the selected field changes.

```dart
// ✅ Best: rebuilds only when selectedAyah changes
BlocSelector<CBQuranReader, SQuranReader, ParamAyahRef?>(
  selector: (s) => s.selectedAyah,
  builder: (_, ayah) => Text(ayah?.key ?? '—'),
)

// ✅ OK: rebuilds whole subtree when any field changes
BlocBuilder<CBQuranReader, SQuranReader>(
  builder: (_, state) => _PageView(layout: state.layout),
)

// ❌ Never wrap a whole Scaffold
BlocBuilder<CBQuranReader, SQuranReader>(
  builder: (_, s) => Scaffold(body: ...),   // very inefficient
)
```

### Singleton vs factory Cubits

| Pattern | DI registration | When to use |
|---------|----------------|-------------|
| Singleton | `i.addSingleton<CB>(CB.new)` | App-wide state (audio player, downloads, active reciter) |
| Factory | `i.add<CB>(CB.new)` | Per-screen state (form controller, list filter, screen-local UI) |

Singletons survive route changes — perfect for the audio player and download manager.

---

## 10. Routing & DI — Modular

### App entry point

```dart
// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive
  await Hive.initFlutter();
  Hive.registerAdapter(MUserAdapter());
  Hive.registerAdapter(MBookmarkAdapter());
  // … register all adapters …

  // Open all boxes used at startup
  await BoxUser().init();
  await BoxBookmarks().init();
  // …

  // Audio background service
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.qrn.audio',
    androidNotificationChannelName: 'Quran Recitation',
    androidNotificationOngoing: true,
  );

  runApp(ModularApp(module: AppModule(), child: const App()));
}
```

### Root module

```dart
class AppModule extends Module {
  @override
  void binds(i) {
    // Core singletons
    i.addSingleton<BaseDio>(BaseDio.new);
  }

  @override
  void routes(r) {
    r.module('/auth',     module: AuthModule());
    r.module('/quran',    module: QuranModule());
    r.module('/prayer',   module: PrayerTimesModule());
    r.module('/azkar',    module: AzkarModule());
    r.module('/qibla',    module: QiblaModule());
    r.module('/settings', module: SettingsModule());
    r.child('/', child: (_) => const SNHome());
  }
}
```

### Navigation rules

```dart
// ✅ Push
Modular.to.pushNamed(QuranRoutes.readerFromAyah(2, 255));

// ✅ Replace
Modular.to.pushReplacementNamed(AuthRoutes.login);

// ✅ Pop
Modular.to.pop();

// ✅ Pop with result
Modular.to.pop(selectedReciter);

// ❌ Never
Modular.to.pushNamed('/quran/reader?surah=2');
```

### Accessing dependencies

```dart
// Inside a widget
final cubit = Modular.get<CBAudioPlayer>();

// Inside a Cubit/repo, prefer constructor injection (added in module.binds)
class CBQuranReader extends Cubit<SQuranReader> {
  CBQuranReader(this._getPage, this._audioPlayer);
  final UCGetPageLayout _getPage;
  final CBAudioPlayer _audioPlayer;
}
```

---

## 11. Data Layer Patterns

### DataSource — direct I/O, no error handling

DataSources call APIs or read from disk and **let exceptions bubble up**.

```dart
class DSRemoteAudio {
  DSRemoteAudio(this._dio);
  final BaseDio _dio;

  Future<String> resolveAyahUrl(String reciterFolder, int surah, int ayah) async {
    final paddedSurah = surah.toString().padLeft(3, '0');
    final paddedAyah  = ayah.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$reciterFolder/$paddedSurah$paddedAyah.mp3';
  }
}
```

### Repository — catches and converts to `Either<Failure, T>`

Every repo method returns `Future<Either<Failure, T>>`:

```dart
// domain/repos/r_quran.dart (interface)
abstract class RQuran {
  Future<Either<Failure, List<MSurah>>> getSurahs();
  Future<Either<Failure, MPageLayout>>  getPage(int page);
}

// data/repos/r_impl_quran.dart (implementation)
class RImplQuran implements RQuran {
  RImplQuran(this._local);
  final DSLocalQuran _local;

  @override
  Future<Either<Failure, List<MSurah>>> getSurahs() async {
    try {
      final list = await _local.loadSurahs();
      return Right(list);
    } on DioException catch (e) {
      return Left(_handleDio(e));
    } catch (e, st) {
      ErrorHelper.printDebugError(
        name: 'RImplQuran.getSurahs', error: e, stackTrace: st,
      );
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }
}
```

### Use Case — single responsibility

A use case is a class with a single `call` method. Use them when there's real business logic to coordinate; if a Cubit method is calling exactly one repo method with no transformation, inline it.

```dart
class UCSaveBookmark {
  UCSaveBookmark(this._repo, this._lastRead);
  final RBookmarks _repo;
  final RLastRead _lastRead;

  Future<Either<Failure, MBookmark>> call(ParamAyahRef ref, {String? note}) async {
    final saved = await _repo.save(ref, note: note);
    return saved.fold(
      Left.new,
      (bookmark) async {
        await _lastRead.update(ref);   // side effect: update last-read too
        return Right(bookmark);
      },
    );
  }
}
```

---

## 12. Networking & Error Handling

### Use `BaseDio` for all API calls

`lib/core/services/network/base_dio.dart` is the shared Dio instance with interceptors (auth, logging, retry).

```dart
class DSRemoteAuth {
  DSRemoteAuth(this._dio);
  final BaseDio _dio;

  Future<MUser?> login(ParamsLogin params) async {
    final response = await _dio.post(APIEndPoints.auth.login, data: params.toJson());
    if (response.statusCode == 200) {
      return MUser.fromJson(response.data);
    }
    return null;
  }
}
```

Add new endpoints to `lib/core/services/network/end_points.dart`.

### API field naming — assume nothing

The backend mixes camelCase and snake_case. **Models MUST match the EXACT API response.** Read the actual response before writing `fromJson`.

```dart
// Example: API uses snake_case for this endpoint
factory MUser.fromJson(Map<String, dynamic>? json) => MUser(
  id:           json?['id'] as String?,
  firstName:    json?['first_name'] as String?,   // snake_case in API
  isActive:     json?['is_active'] as bool?,
  accessToken:  json?['access_token'] as String?,
);
```

### Error message extraction

The API inconsistently returns errors in both `'error'` and `'message'` fields. Always check both:

```dart
String message = 'حدث خطأ في الخادم';
if (data is Map<String, dynamic>) {
  message = data['error'] as String?
         ?? data['message'] as String?
         ?? 'حدث خطأ في الخادم';
}
```

### Standard `_handleDio` template

Use this in every `RImpl*`:

```dart
Failure _handleDio(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const Failure.networkFailure(
        message: 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.',
      );

    case DioExceptionType.badResponse:
      final statusCode = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'حدث خطأ في الخادم';
      if (data is Map<String, dynamic>) {
        message = data['error'] as String?
               ?? data['message'] as String?
               ?? 'حدث خطأ في الخادم';
      }
      if (statusCode == 401) return Failure.authenticationFailure(message: message);
      if (statusCode == 404) return Failure.notFoundFailure(message: message);
      if (statusCode == 422) return Failure.validationFailure(message: message);
      return Failure.serverFailure(message: message, statusCode: statusCode);

    case DioExceptionType.connectionError:
      return const Failure.networkFailure(message: 'لا يوجد اتصال بالإنترنت');

    default:
      return Failure.unexpectedFailure(message: e.message ?? 'حدث خطأ غير متوقع');
  }
}
```

---

## 13. Local Storage — Hive

We use `hive_ce_flutter` (the maintained fork). All boxes wrap `HiveBoxBase<T>`.

### Box wrapper

```dart
// box_bookmarks.dart
class BoxBookmarks extends HiveBoxBase<MBookmark> {
  BoxBookmarks() : super('quran_bookmarks', MBookmarkAdapter());
}
```

### Model with Hive annotations

```dart
import 'package:hive_ce_flutter/hive_flutter.dart';

part 'm_bookmark.g.dart';

@HiveType(typeId: 10)
class MBookmark {
  @HiveField(0) String id;
  @HiveField(1) int surah;
  @HiveField(2) int ayah;
  @HiveField(3) String? note;
  @HiveField(4) DateTime createdAt;

  MBookmark({
    required this.id,
    required this.surah,
    required this.ayah,
    this.note,
    required this.createdAt,
  });
}
```

### Typed IDs — never collide

Each Hive model has a unique `typeId`. Maintain a central registry in `lib/core/storage/hive_type_ids.dart`:

```dart
// Reserved typeIds (NEVER reuse a number)
// 0  → MUser
// 1  → MAuthToken
// 10 → MBookmark
// 11 → MLastRead
// 12 → MDownloadTask
// 13 → MReciterPref
// 20 → MPrayerSettings
// 21 → MAdhanPreference
// 30 → MReminder
// ...
```

### Local DataSource pattern

```dart
class LocalBookmarks {
  final BoxBookmarks _box = BoxBookmarks();

  Future<List<MBookmark>> getAll() async => _box.box.values.toList();

  Future<void> add(MBookmark b) async => _box.box.put(b.id, b);

  Future<void> delete(String id) async => _box.box.delete(id);

  ValueListenable<Box<MBookmark>> listenable() => _box.box.listenable();
}
```

### After changing a Hive model

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

And tell the user: **hot restart required** (not hot reload).

---

## 14. UI Patterns

### Always use `WSharedScaffold`

```dart
class WSharedScaffold extends StatelessWidget {
  final Widget body;
  final bool dismissKeyboardOnTap;

  const WSharedScaffold({
    super.key,
    required this.body,
    this.dismissKeyboardOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget scaffold = Scaffold(body: body);
    if (dismissKeyboardOnTap) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: scaffold,
      );
    }
    return scaffold;
  }
}
```

### Cached images

Always use `WCachedImage`:

```dart
class WCachedImage extends StatelessWidget {
  final String imageUrl;
  const WCachedImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
    imageUrl: imageUrl,
    placeholder: (_, __) => Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(color: Colors.white),
    ),
    errorWidget: (_, __, ___) => const Icon(Icons.error),
  );
}
```

### Buttons — named constructors

```dart
class WAppButton extends StatelessWidget {
  factory WAppButton.primary({required String text, required VoidCallback onPressed});
  factory WAppButton.secondary({required String text, required VoidCallback onPressed});
  factory WAppButton.outlined({required String text, required VoidCallback onPressed});
  factory WAppButton.text({required String text, required VoidCallback onPressed});
}
```

### Loading indicator

```dart
// ✅
const WLoadingIndicator()                       // default gold
const WLoadingIndicator(color: AppColors.white)
const WLoadingIndicator(size: 20)

// ❌
const CircularProgressIndicator()
```

### Null safety in UI

```dart
// ✅
final ayah = state.selectedAyah;
if (ayah == null) return const WEmptyState();
return _AyahActions(ref: ayah);

// ✅
final name = user?.name ?? 'مستخدم';
final price = product?.price ?? 0.0;

// ❌
final ayah = state.selectedAyah!;   // can crash
```

### Safe type conversion

```dart
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int)    return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

// ❌ Don't blindly cast
final price = data['price'] as double;   // crashes on int or null
```

---

## 15. Forms

Form controllers live in `lib/core/services/forms/` and extend `BaseFormController`.

Shared form fields live in `lib/core/widgets/forms/` (text fields, phone fields, email fields, …).

Common validators live in `lib/core/utils/validators/`.

```dart
class FLogin extends BaseFormController {
  late WPhoneField phoneField;
  late WPasswordField passwordField;

  @override
  void init() {
    phoneField    = WPhoneField(hint: 'auth_phone'.translated);
    passwordField = WPasswordField(hint: 'auth_password'.translated);
  }

  @override
  bool validate() => formKey.currentState!.validate();

  @override
  void clear() {
    phoneField.clear();
    passwordField.clear();
  }
}
```

If a needed field doesn't exist yet, add it to `lib/core/widgets/forms/` so all forms can use it.

---

## 16. Localization (i18n)

### Rules

- **FLAT** JSON only — no nesting
- Keys use **feature-prefixed snake_case**

```json
// assets/lang/ar.json
{
  "auth_email":        "البريد الإلكتروني",
  "auth_password":     "كلمة المرور",
  "auth_login":        "تسجيل الدخول",
  "quran_reader_play": "تشغيل",
  "quran_reader_pause":"إيقاف مؤقت",
  "prayer_times_fajr": "الفجر",
  "prayer_times_dhuhr":"الظهر"
}
```

### Usage

```dart
Text('auth_login'.translated)
```

Never inline Arabic strings in code — they all go in the JSON.

---

## 17. Testing & Quality Gates

### Required for every PR / completed task

- [ ] `flutter analyze` → zero errors
- [ ] Hot reload tested for the touched screen
- [ ] If Hive/Freezed/Modular changed → user told to hot **restart**
- [ ] No `print()` statements (use `debugPrint` or `ErrorHelper.printDebugError`)
- [ ] No commented-out code blocks
- [ ] No leftover TODOs without a tracking issue
- [ ] No `!` null assertions added (unless verified non-null on the previous line)

### Manual smoke test by feature

After touching the Quran reader: open a surah, swipe pages, tap an ayah, play audio, lock screen, unlock — verify nothing crashed.
After touching prayer times: check Fajr fires after overnight kill on a Xiaomi/Oppo device.
After touching downloads: cancel mid-download, restart app, confirm resume works.

### Manual command cheatsheet

```bash
flutter analyze
dart fix --apply
flutter pub run build_runner build --delete-conflicting-outputs
flutter pub run build_runner watch --delete-conflicting-outputs   # during active dev
```

---

## 18. Quick Reference

### File prefixes

```
sn_   → Screen
w_    → Widget
cb_   → Cubit
s_    → Cubit State (freezed)
f_    → Form
m_    → Model
box_  → Hive Box wrapper
e_    → Entity (plain)
param_→ Param entity
r_    → Repo Interface (in domain/repos/)
r_impl_→ Repo Impl (in data/repos/)
uc_   → Use Case
ds_   → Data Source
```

### Key rules

```
✅ Package imports only
✅ No 'Screen' suffix
✅ No project prefixes on shared widgets
✅ Cubit only (no Bloc<Event,State>, no Provider)
✅ flutter_modular for DI + routing
✅ Type-safe routes — never string literals
✅ Either<Failure, T> for every repo method
✅ Flat JSON for i18n with underscore prefixes
✅ WSharedScaffold + WLoadingIndicator + WCachedImage
✅ Hive for local storage with typeId registry
✅ build_runner after Freezed/Hive changes
```

### When in doubt

1. Grep the codebase for a similar pattern first
2. Check `CLAUDE.md` for the AI quick-reference
3. Check `docs/plans/Quran_Module_Plan.md` for Quran reader specifics
4. **Ask the user** rather than guessing
5. Never leave a task half-done — fix every analyze error before saying "done"

---

**End of instructions.md.**
For the full implementation plan of the Quran reader module, read [`docs/plans/Quran_Module_Plan.md`](./docs/plans/Quran_Module_Plan.md).
