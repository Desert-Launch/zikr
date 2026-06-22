---
name: pr-review
description: Use when reviewing a pull request, diff, branch, or set of changes in the Quran app before merge. Triggers on "review this PR", "review my changes", "check this diff", "is this ready to merge", "code review", "review before commit". Produces a structured, severity-tagged review enforcing the app's architecture, naming, Cubit state, data-layer, i18n/RTL, and quality gates.
---

# PR Review (Quran app)

Review against this app's conventions. Be direct — flag every violation with a fix, not a vibe. Block on 🔴, request changes on 🟠, note 🟡.

## Pre-flight
1. Read the diff fully + the files it touches (not just the hunks).
2. Grep for usages of changed symbols — did the PR update ALL call sites?
3. Confirm `flutter analyze` would pass (no obvious errors/unused imports).

## Review dimensions (score each)

### 🏛 Architecture & layering
- [ ] Code in the right layer (no Dio/datasource/Hive box in presentation; no logic in screens/cubits).
- [ ] Interfaces in `domain/repos/` (`r_*`), impls in `data/repos/` (`r_impl_*`) — never mixed.
- [ ] Repo methods return `Either<Failure, T>`; datasources throw, repo converts.
- [ ] One-direction flow: screen → cubit → usecase → repo → datasource/box.

### 🏷 Naming & structure
- [ ] Correct prefixes/locations (`sn_`, `w_`, `cb_`, `s_`, `f_`, `param_`/`e_`, `m_`, `box_`, `r_`, `r_impl_`, `uc_`, `ds_`).
- [ ] No `Screen` suffix; no project prefixes on shared components.
- [ ] No class > 300 lines; no function widgets.

### 🧩 State (Cubit)
- [ ] `CB*` extends `Cubit<S*>`; state is freezed; `emit(state.copyWith(...))`.
- [ ] `BlocBuilder`/`BlocSelector` wraps only the reactive subtree, not the `Scaffold`.
- [ ] No `Bloc<Event,State>`, no `provider`/`ChangeNotifier`, no MobX. `Either`/`Failure` folded in the cubit, not the UI.

### 📦 Data layer
- [ ] Errors mapped to `Failure` in `r_impl_*` (`try/on DioException/catch`).
- [ ] New Hive boxes opened in `main.dart`; box wrappers `addSingleton`.
- [ ] No invented `ds_mock_*` / `MockDataService` / `ApiFlag` (not used here); endpoints from `end_points.dart`.

### 🌐 i18n & RTL
- [ ] No hardcoded user-facing strings.
- [ ] Keys added to BOTH `ar.json` + `en.json`; FLAT; prefixed; used via `.tr()`.
- [ ] Directional insets/alignment; verified AR (default) + EN.

### 🎨 UI quality
- [ ] Shared components used (`WSharedScaffold`, `WGradientAppBar`, `WAppButton`, `WLoadingOverlay`, `WEmptyState`, form fields).
- [ ] Sizing via screenutil `.w`/`.h`/`.sp`/`.r` (or `core/responsive` helpers), no raw pixels.
- [ ] Loading/error/empty states driven off `LoadStatus`.

### 🧭 Routing & DI
- [ ] Typed `*Routes` builders only; no string routes.
- [ ] Module mounted in `AppModule`; correct `add` vs `addSingleton` lifecycle.

### 🛡 Safety
- [ ] No `!` null assertion unless provably safe on the same line; null-aware used.
- [ ] Package imports only (`package:quran/...`), sorted; no relative imports.
- [ ] No secrets/keys committed; no raw GPS/token in logs.

## Output format
```
## PR Review: <title>
**Verdict:** ✅ Approve / 🟠 Request changes / 🔴 Block

### 🔴 Blocking
- file:line — issue → fix

### 🟠 Should fix
- ...

### 🟡 Nits
- ...

### ✅ Good
- what was done well
```
Always include the exact fix or a corrected snippet for 🔴/🟠 items. Output full corrected files when the change is non-trivial. Do not approve with any 🔴 open.
