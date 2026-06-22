---
name: cubit-state
description: Use for any state-management work in the Quran app — creating or editing cb_* cubits and s_* freezed states, wiring BlocBuilder/BlocSelector/BlocListener, handling loading/error/empty state, deciding what is reactive. Triggers on "state", "cubit", "bloc", "emit", "copyWith", "make this reactive", "BlocBuilder". Enforces flutter_bloc Cubit only — NO Bloc<Event,State>, NO provider, NO MobX.
---

# Cubit State (Quran app)

State = `flutter_bloc` **Cubit** named `cb_*` → `CB*`, with an immutable **freezed** state `s_*` → `S*`. No `Bloc<Event,State>`, no `provider`/`ChangeNotifier`, no MobX — ever.

## Cubit skeleton
```dart
// cb_feature.dart
class CBFeature extends Cubit<SFeature> {
  CBFeature(this._load) : super(const SFeature());
  final UCLoadItems _load;

  Future<void> load() async {
    emit(state.copyWith(status: LoadStatus.loading, error: null));
    final result = await _load();
    result.fold(
      (failure) => emit(state.copyWith(status: LoadStatus.error, error: failure.message)),
      (items)   => emit(state.copyWith(status: LoadStatus.success, items: items)),
    );
  }
}
```

## State skeleton (freezed)
```dart
// s_feature.dart
@freezed
class SFeature with _$SFeature {
  const factory SFeature({
    @Default(LoadStatus.idle) LoadStatus status,
    @Default(<ParamItem>[]) List<ParamItem> items,
    String? error,
  }) = _SFeature;
}
```
> ⚠️ `build_runner` is broken in this repo — `freezed` codegen will not run. Match an existing `s_*.freezed.dart` file's structure by hand, or model new state on a cubit that already compiles. Tell the user to hot **restart** after state-class changes.

## Rules
1. The cubit holds presentation state only — **no business logic** (that's usecases/repos) and **no widgets**.
2. Drive UI off one explicit status enum (`LoadStatus.idle/loading/success/error`), not scattered booleans.
3. Reset `error` at the start of an action (`copyWith(status: loading, error: null)`).
4. Repos return `Either<Failure, T>`; `fold` it in the cubit and surface `failure.message` into state. Never let `Either`/`Failure` leak into the UI.
5. Inject usecases (or the repo) via the constructor; register in the module's `binds`. Per-screen cubits use `i.add<CBX>(CBX.new)` (factory); app-wide cubits (audio, downloads, reciter) use `i.addSingleton<CBX>(CBX.new)`.
6. One cubit per screen, plus the app-wide singletons.

## Consuming reactively
```dart
Column(
  children: [
    const _StaticHeader(),                       // not reactive
    BlocSelector<CBFeature, SFeature, LoadStatus>(
      selector: (s) => s.status,                 // rebuild only on status change
      builder: (_, status) => switch (status) {
        LoadStatus.loading => const WLoadingOverlay(),
        LoadStatus.error   => WEmptyState(/* retry */),
        _                  => const _ItemList(),
      },
    ),
  ],
)
```
- `BlocSelector` is preferred — wrap **only** the reactive subtree, never the whole `Scaffold`.
- `BlocListener` for one-shot effects (snackbars, navigation), not for building UI.
- Read without listening to fire an action: `context.read<CBFeature>().load()`.

## Anti-patterns
- ❌ `BlocBuilder` around the entire `Scaffold` (rebuilds everything).
- ❌ `Bloc<Event,State>` — Cubit only.
- ❌ `provider` / `ChangeNotifier` / `notifyListeners` / any MobX (`Store`, `@observable`).
- ❌ Mutable state class or mutating fields — state is freezed + `copyWith`.
- ❌ API/Either/Failure handling inside the UI (belongs in cubit → usecase → repo).
