---
name: flutter-feature-builder
description: Use when creating a NEW feature module in the Quran app end-to-end (entity → model → repo interface → datasources/boxes → repo impl → usecase → cubit + freezed state → screen → DI module → typed route → AR/EN i18n). Triggers on "add a feature", "build the X screen/module", "scaffold X", or any request that creates a new vertical slice. Enforces Clean Architecture layering, naming conventions, Cubit state, and typed routing.
---

# Flutter Feature Builder (Quran app)

Build every feature as a complete vertical slice. Never create a screen without its data/domain layers.

## Order of operations (do not skip steps)
1. **Entity** — `domain/entities/param_<x>.dart` → `Param<X>` (or `e_<x>.dart` → `E<X>`): typed inputs/outputs the UI needs.
2. **Model** — `data/models/m_<x>.dart` → `M<X>`: `fromJson`/`toJson` for remote shapes; add Hive `@HiveType`/`@HiveField` annotations only if the model is cached/persisted.
3. **Repo interface** — `domain/repos/r_<x>.dart` → `R<X>`: every method returns `Either<Failure, T>`.
4. **DataSources / boxes** (only what the feature needs):
   - `data/datasources/remote/ds_remote_<x>.dart` — Dio calls via `BaseDio`, endpoints from `end_points.dart`.
   - `data/datasources/local/ds_local_<x>.dart` — bundled assets / platform plugins.
   - `data/sources/local/box_<x>.dart` → `Box<X>` extends `HiveBoxBase<T>` for persisted data. **Open the box in `main.dart`.**
5. **Repo impl** — `data/repos/r_impl_<x>.dart` → `RImpl<X>`: calls datasources, maps errors to `Failure` (`try/on DioException/catch`), returns `Either`.
6. **UseCase(s)** — `domain/usecases/uc_<verb>.dart` → `UC<Verb>`: one business action each, `call()`.
7. **State** — `presentation/cubits/s_<x>.dart` → `S<X>` (freezed): `LoadStatus status`, data fields, `String? error`.
8. **Cubit** — `presentation/cubits/cb_<x>.dart` → `CB<X>` extends `Cubit<S<X>>`: injects usecases, `emit(state.copyWith(...))`, folds `Either`.
9. **Screen** — `presentation/screens/sn_<x>.dart` → `SN<X>`: `WSharedScaffold` + `WGradientAppBar`, `BlocSelector`/`BlocBuilder` around reactive parts only, < 300 lines.
10. **Widgets** — `presentation/widgets/w_*.dart`: extract widget **classes** (no `Widget _buildX()`).
11. **DI module** — `<x>_module.dart` extends `Module`: bind datasources/boxes (`addSingleton` boxes), repo `i.add<R<X>>(RImpl<X>.new)`, usecases `i.add`, cubit `i.add<CB<X>>` (factory) or `addSingleton` if app-wide. Mount it at its base path in `AppModule`.
12. **Routes** — add the module base to `RoutesNames` and a typed `<X>Routes` class (in `lib/core/services/routes/routes_names.dart`) with `static String` builders. Register `r.child(...)` in the module's `routes`.
13. **i18n** — add FLAT keys to `assets/lang/ar.json` + `assets/lang/en.json` with `<feature>_` prefix; use `'key'.tr()`.
14. **Verify** — `flutter analyze` = 0; wire loading/error/empty states; verify RTL (Arabic is default).

## Checklist before "done"
- [ ] All layers exist (no screen-only features)
- [ ] Repo returns `Either<Failure, T>`; datasources throw, repo converts
- [ ] Cubit + freezed state; `BlocSelector` wraps only reactive subtree
- [ ] Module mounted in `AppModule`; any new Hive box opened in `main.dart`
- [ ] Typed `*Routes` builder added (no string literals)
- [ ] AR + EN FLAT keys added, used via `.tr()`
- [ ] `flutter analyze` = 0; no class > 300 lines; package imports only; no `!`

## Reality checks for this repo
- **`build_runner` is broken.** For freezed states and Hive adapters, hand-edit the generated `.freezed.dart`/`.g.dart` (mirror an existing one) + `quran_hive_registrar.dart` + `main.dart`. Tell the user to hot **restart**.
- **No mock-first / `ApiFlag` / `MockDataService`** — this app uses real bundled assets, Hive, and remote APIs (Aladhan, audio CDN). Don't scaffold `ds_mock_*`.
- **No user roles / RoleGuard** — it's a single-user devotional app. Don't add route guards.

## Anti-patterns
- ❌ Screen that calls a datasource/box/Dio directly (must go cubit → usecase → repo).
- ❌ Business logic in the screen or cubit (belongs in a usecase/repo).
- ❌ `Bloc<Event,State>`, `provider`, or MobX.
- ❌ String-literal navigation instead of a typed `*Routes` builder.
