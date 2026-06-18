---
name: provider-state
description: Use for any state-management work in Taliah — creating or editing mg_* managers, wiring Consumer/Selector, handling loading/error/empty state, or deciding what is reactive. Triggers on "state", "manager", "ChangeNotifier", "Consumer", "notifyListeners", "make this reactive". Enforces provider (ChangeNotifier) only — NO MobX.
---

# Provider State (Taliah)

State = `provider` `ChangeNotifier` managers named `mg_*` → `Mg*`. No MobX, ever.

## Manager skeleton
```dart
class MgFeature extends ChangeNotifier {
  final UCDoThing _uc;
  MgFeature(this._uc);

  bool isLoading = false;
  String? errorMessage;
  List<ParamItem> items = [];

  bool get isEmpty => !isLoading && errorMessage == null && items.isEmpty;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final res = await _uc();
      res.fold(
        (f) => errorMessage = f.message,
        (data) => items = data,
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
```

## Rules
1. Manager holds presentation state only; **no business logic** (that's usecases/repos) and **no widgets**.
2. Always expose `isLoading` + `errorMessage`; call `notifyListeners()` after each state change.
3. Reset `errorMessage` at the start of an action.
4. Provide derived getters (`isEmpty`, `hasItems`) instead of computing in the widget.
5. Inject usecases (or repo) via constructor; register in `binds.dart` as `addLazySingleton`.

## Consuming reactively
```dart
Consumer<MgFeature>(
  builder: (context, m, _) {
    if (m.isLoading) return const WLoadingIndicator();
    if (m.errorMessage != null) return WErrorState(message: m.errorMessage!, onRetry: m.load);
    if (m.isEmpty) return const WEmptyState();
    return WItemList(items: m.items);
  },
)
```
- Wrap **only** the reactive subtree, never an entire `Scaffold`.
- Use `Selector` when only one field drives a rebuild.
- Read without listening for callbacks: `context.read<MgFeature>().load()`.

## Anti-patterns
- ❌ `Consumer` around the whole screen.
- ❌ Calling `notifyListeners()` inside `build`.
- ❌ Mutating state without `notifyListeners()`.
- ❌ API/Either logic inside the manager (belongs in usecase/repo).
- ❌ Any MobX (`Store`, `@observable`, `@action`).
