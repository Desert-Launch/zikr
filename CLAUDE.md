# CLAUDE.md

> Concise reference for AI assistants (Claude, Cursor, Copilot Chat, etc.) working in this codebase.
> For the full developer guide, see [`.claude/instructions.md`](./.claude/instructions.md).
> For the Quran reader module specifically, see [`docs/plans/Quran_Module_Plan.md`](./docs/plans/Quran_Module_Plan.md).

---

## 1. Project at a glance

**App:** Quran companion mobile app (قرآن) — Mushaf reader, prayer times, azkar, tasbih, Qibla, reminders, nearby mosques.
**Platforms:** Android & iOS.
**Language:** Flutter / Dart (SDK `^3.9.2`). Pubspec package name: **`quran`**.
**Audience:** Arabic-first, RTL by default. English/Urdu/French planned.

**Entry points:**
- `lib/main.dart` — boots in this order before `runApp`: `AppLogger.init()` → `LocalizeAndTranslate.init()` (ar/en) → `Hive.initFlutter()` + `QuranHiveRegistrar.registerAdapters()` → **open all ~22 Hive boxes** → `JustAudioBackground.init()` → `runApp(ModularApp(AppModule()))`. Post-build it runs `CBTheme.load()`, `CBAuth.bootstrap()`, `NotificationsService.init()`, `CBReminders.rescheduleAll()`, `AdhanBootstrap.run()`.
- `lib/core/services/routes/app_module.dart` — the **root `AppModule`**: registers box singletons, shared data sources, `BaseDio`, app-wide cubits, and mounts every feature module at its base path.
- Route paths live in `RoutesNames` (module bases) + per-module `*Routes` classes (e.g. `QuranRoutes`, `AdhanRoutes`) in the routes layer — see rule #3.

**Feature modules** (`lib/modules/`): `adhan`, `auth`, `azkar`, `home`, `khatma`, `legal`, `onboarding`, `prayer`, `qibla`, `quran`, `reminders`, `settings`, `tasbih`. App-wide cubits and shared services live in `lib/core/` (`cubits/`, `services/`, `widgets/`, `theme/`, `data/`).

---

## 2. Architecture (non-negotiable)

- **Clean Architecture**: `data/` → `domain/` → `presentation/` per feature module.
- **State management**: `flutter_bloc` — **Cubit** only. No `Bloc<Event,State>`, no `provider`, no `MobX`.
- **DI + Routing**: `flutter_modular`. One `Module` per feature.
- **Local storage**: `hive_ce` + `hive_ce_flutter` (use `HiveBoxBase<T>` wrapper).
- **Networking**: `dio` via shared `BaseDio` in `lib/core/services/network/`. Endpoints centralized in `end_points.dart`.
- **Error handling**: `dartz` — every repo method returns `Future<Either<Failure, T>>`.
- **Models**: `freezed` for immutable state classes, plain Dart with Hive annotations for persisted models.

---

## 3. The app is always running

The user runs the app in another terminal with hot reload.

- **Do NOT** run `flutter run`, `flutter build`, or anything that launches the app.
- Save your edits — they will hot-reload automatically.
- If a hot restart is needed (e.g., after a DI change, a Hive adapter change, or a route change), **tell the user** to hot restart. Do not do it yourself.
- `flutter analyze` and `dart fix --apply` are fine to run.

---

## 4. Task protocol (before writing code)

For any non-trivial change, report this block first:

```
📋 Task: <one-line description>
🏷️ Type: 🐛 Bug | ✨ Feature | 🔄 Refactor | ❓ Question | 🔍 Research | 🎨 Style | 📝 Docs
📍 Scope:
  • <file>  → <action>
  • <file>  → <action>
⚠️ Impact: <what might break>
🔧 Approach: <one-line strategy>
```

Then proceed if scope is obvious; otherwise wait for confirmation.

---

## 5. File naming — STRICT

Two-letter prefixes are mandatory. Class name = prefix uppercased.

| Type | File | Class | Folder |
|------|------|-------|--------|
| Screen | `sn_*.dart` | `SN*` | `presentation/screens/` |
| Widget | `w_*.dart` | `W*` | `presentation/widgets/` |
| Cubit | `cb_*.dart` | `CB*` | `presentation/cubits/` |
| Cubit State | `s_*.dart` | `S*` (freezed) | `presentation/cubits/` |
| Form | `f_*.dart` | `F*` | `core/services/forms/` |
| Model (data) | `m_*.dart` | `M*` | `data/models/` |
| Hive Box | `box_*.dart` | `Box*` | `data/sources/local/` |
| Entity/Param | `param_*.dart` / `e_*.dart` | `Param*` / `E*` | `domain/entities/` |
| Repo Interface | `r_*.dart` | `R*` | **`domain/repos/`** |
| Repo Impl | `r_impl_*.dart` | `RImpl*` | **`data/repos/`** |
| Use Case | `uc_*.dart` | `UC*` | `domain/usecases/` |
| Data Source | `ds_*.dart` | depends | `data/datasources/` |

**Never:**
- Add the `Screen` suffix to screen classes (`SNHome`, not `SNHomeScreen`).
- Add project prefixes to shared widgets (`WButton`, not `QrnButton`).
- Mix repo interfaces and implementations in the same folder.

---

## 6. The 8 critical rules — never violate

1. **Package imports only** — `package:quran/...` (the pubspec package name is `quran`). Never `../../`. Sort alphabetically.
2. **No `Bloc<Event,State>` ever** — Cubit only. One Cubit per screen, plus app-wide singletons (audio, downloads, reciter).
3. **No string literals for navigation.** Use a `Routes` class with type-safe builders. Example: `Modular.to.pushNamed(QuranRoutes.readerFromAyah(2, 255))`, never `'/quran/reader?surah=2&ayah=255'`.
4. **No null assertions (`!`).** Use `?.`, `??`, or explicit null checks. The only exception is *immediately after* a verified non-null check on the same line.
5. **`flutter analyze` must be zero errors** before any commit. Warnings acceptable only if pre-existing.
6. **Every repo method returns `Either<Failure, T>`.** Data sources let exceptions bubble; repos catch and convert.
7. **Use shared widgets, never raw framework widgets** when a shared one exists: `WSharedScaffold` not `Scaffold`, `WLoadingIndicator` not `CircularProgressIndicator`, `WCachedImage` not `Image.network`.
8. **Flat JSON for i18n** with underscore prefixes: `auth_email`, `quran_reader_play`. No nested structures.

---

## 7. Cubit pattern (this is the only state mgmt pattern)

```dart
// cb_quran_reader.dart
class CBQuranReader extends Cubit<SQuranReader> {
  CBQuranReader(this._getPage) : super(const SQuranReader());
  final UCGetPageLayout _getPage;

  Future<void> openPage(int page) async {
    emit(state.copyWith(status: LoadStatus.loading));
    final result = await _getPage(page);
    result.fold(
      (failure) => emit(state.copyWith(status: LoadStatus.error, error: failure.message)),
      (layout)  => emit(state.copyWith(status: LoadStatus.success, layout: layout)),
    );
  }
}

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
```

**In UI:** use `BlocBuilder`, `BlocSelector` (preferred for fine-grained rebuilds), or `BlocListener`. Wrap only the reactive sub-widget — never the whole `Scaffold`.

```dart
// ✅ Good
Column(
  children: [
    const _StaticHeader(),
    BlocSelector<CBQuranReader, SQuranReader, ParamAyahRef?>(
      selector: (s) => s.selectedAyah,
      builder: (_, ayah) => Text(ayah?.key ?? '—'),
    ),
  ],
)

// ❌ Bad — rebuilds entire scaffold
BlocBuilder<CBQuranReader, SQuranReader>(
  builder: (_, s) => Scaffold(...),
)
```

---

## 8. Modular module template

```dart
class QuranModule extends Module {
  @override
  void binds(i) {
    // DataSources
    i.add<DSLocalQuran>(DSLocalQuran.new);

    // Repos (interface → impl)
    i.add<RQuran>(RImplQuran.new);

    // Use cases
    i.add(UCGetSurahList.new);
    i.add(UCGetPageLayout.new);

    // Cubits — singletons for cross-screen, factory for per-screen
    i.addSingleton<CBAudioPlayer>(CBAudioPlayer.new);
    i.add<CBQuranReader>(CBQuranReader.new);
  }

  @override
  void routes(r) {
    r.child(QuranRoutes.surahList, child: (_) => const SNSurahList());
    r.child(QuranRoutes.reader,    child: (_) => SNMushafReader(args: r.args.data));
  }
}
```

**DI lifecycle quick rule:**
- `i.add<T>(T.new)` — factory (new instance per request). Use for per-screen Cubits, use cases, repos.
- `i.addSingleton<T>(T.new)` — single instance. Use for app-wide Cubits (audio, downloads), Hive box wrappers, network base.

---

## 9. Repository pattern

```dart
// domain/repos/r_quran.dart
abstract class RQuran {
  Future<Either<Failure, List<MSurah>>> getSurahs();
  Future<Either<Failure, MPageLayout>> getPage(int page);
}

// data/repos/r_impl_quran.dart
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
      ErrorHelper.printDebugError(name: 'RImplQuran.getSurahs', error: e, stackTrace: st);
      return Left(Failure.unexpectedFailure(message: e.toString()));
    }
  }
}
```

Standard `_handleDio` template lives in `instructions.md` §10.

---

## 10. Hive pattern

```dart
// box wrapper
class BoxBookmarks extends HiveBoxBase<MBookmark> {
  BoxBookmarks() : super('quran_bookmarks', MBookmarkAdapter());
}

// model (note: hive_ce_flutter, not legacy hive)
import 'package:hive_ce_flutter/hive_flutter.dart';
part 'm_bookmark.g.dart';

@HiveType(typeId: 10)
class MBookmark {
  @HiveField(0) String id;
  @HiveField(1) int surah;
  @HiveField(2) int ayah;
  MBookmark({required this.id, required this.surah, required this.ayah});
}
```

After adding/changing a Hive model, run:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```
…and tell the user to hot **restart** (not reload).

---

## 11. Common pitfalls

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| `LateInitializationError` on a Cubit field | Cubit accessed before `Modular.get` resolves | Inject in module `binds`; never `new` a Cubit directly in a widget |
| `HiveError: Box not found` | Box opened too late | Open all boxes in `main()` before `runApp` |
| Hot reload doesn't pick up a new route | Route changes require restart | Tell user: hot restart needed |
| Mushaf font glyphs render as boxes | QPC font not preloaded | Preload page font in `WMushafPage.initState` (see Quran plan §10) |
| Audio stops when screen locks | `just_audio_background` not initialized | Call `JustAudioBackground.init()` in `main()` before `runApp` |
| Translations key shows literally | Missing key in `assets/lang/*.json` or no underscore prefix | Add flat key with `feature_thing` pattern |

---

## 12. Quick command cheatsheet

```bash
# After model/freezed changes
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (good for active development)
flutter pub run build_runner watch --delete-conflicting-outputs

# Auto-fix lint issues
dart fix --apply

# Check the project compiles cleanly — this is the verification gate
flutter analyze
```

> **No test suite exists yet** (no `test/` directory). `flutter analyze` (zero errors) is the only automated gate. Lint config is stock `package:flutter_lints/flutter.yaml` (`analysis_options.yaml`), no custom rules.

Things **I (the AI) should never run** in this project:
- `flutter run`, `flutter build *`, `flutter emulators*`, `adb *`
- Anything that writes to the user's keychain or signing config
- Anything that opens a real network port

---

## 13. When in doubt

1. Read `.claude/instructions.md` (long-form spec).
2. For Quran reader specifics, read `docs/plans/Quran_Module_Plan.md`.
3. Grep the codebase for a similar pattern before inventing one.
4. If you must guess, **ask** rather than assume.
5. Never abandon a task half-done. If `flutter analyze` shows new errors after your edit, you're not done.
