---
name: flutter-feature-builder
description: Use when creating a NEW feature module in Taliah end-to-end (entity → model → repo interface → datasources → repo impl → usecase → manager → screen → DI → routes → i18n). Triggers on "add a feature", "build the X screen/module", "scaffold X", or any request that creates a new vertical slice. Enforces Clean Architecture layering, naming conventions, mock-first data layer, and provider state.
---

# Flutter Feature Builder (Taliah)

Build every feature as a complete vertical slice. Never create a screen without its data/domain layers. Always mock-first.

## Order of operations (do not skip steps)
1. **Entity** — `domain/entities/param_<x>.dart` → `Param<X>`: typed inputs/outputs the UI needs.
2. **Model** — `data/models/m_<x>.dart` → `M<X>`: `fromJson`/`toJson` in the **exact shape the real API will return**. Add a Hive adapter only if the feature is cached/offline.
3. **Repo interface** — `domain/repos/r_<x>.dart` → `R<X>`: methods return `Either<Failure, T>`.
4. **DataSources**:
   - `data/datasources/ds_remote_<x>.dart` — real endpoints from `end_points.dart` (written, dormant).
   - `data/datasources/ds_mock_<x>.dart` — loads `assets/db_mock/<x>.json` via `MockDataService`, adds `Future.delayed`, can inject failure.
5. **Repo impl** — `data/repos/r_impl_<x>.dart` → `RImpl<X>`: picks source via `ApiFlag.useMock`, maps errors with `_handleDioException` (check BOTH `error` + `message`).
6. **UseCase(s)** — `domain/usecases/uc_<verb>.dart` → `UC<Verb>`: one action each, `call()`.
7. **Manager** — `presentation/managers/mg_<x>.dart` → `Mg<X>` extends `ChangeNotifier`: `isLoading`, `errorMessage`, data, `notifyListeners()`.
8. **Screen** — `presentation/screens/sn_<x>.dart` → `SN<X>`: `WSharedScaffold`, `Consumer<Mg<X>>` around reactive parts only, <300 lines.
9. **Widgets** — `presentation/widgets/w_*.dart`: extract widget **classes** (no `Widget _buildX()`).
10. **DI** — register all in `core/di/binds.dart` (datasources `.add`, repo `.add<R>`, usecases `.add`, manager `.addLazySingleton`).
11. **Routes** — add typed method to `AppRoutes`; gate with `RoleGuard` if role-scoped.
12. **i18n** — add FLAT keys to `ar.json` + `en.json` with `<feature>_` prefix.
13. **Verify** — `flutter analyze` = 0; add empty/loading/error states; verify RTL.

## Checklist before "done"
- [ ] All 4 layers exist (no screen-only features)
- [ ] Mock JSON file created in `assets/db_mock/` (+ failure path)
- [ ] Both `ds_remote_*` and `ds_mock_*` present
- [ ] Registered in `binds.dart`; typed route added
- [ ] AR + EN FLAT keys added
- [ ] Role gating applied if needed
- [ ] `flutter analyze` = 0; no class >300 lines; package imports only

## Anti-patterns
- ❌ Screen that calls a datasource directly (must go through manager → usecase → repo).
- ❌ Business logic in the screen or manager (belongs in usecase/repo).
- ❌ Mock data shaped differently from the real API contract.
- ❌ Pre-formatted numbers/dates in mock JSON.
