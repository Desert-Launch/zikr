---
name: modular-routing
description: Use for navigation, routes, deep links, or DI wiring in the Quran app — adding a route, navigating between screens, passing params, mounting a module. Triggers on "route", "navigate", "navigation", "deep link", "RoutesNames", "Modular.to", "module", "binds". Enforces typed *Routes builders (no string routes) with flutter_modular.
---

# Modular Routing (Quran app)

Routing + DI via `flutter_modular`. **Never** navigate with string literals.

## Typed routes — one file, per-module classes
All route literals live in `lib/core/services/routes/routes_names.dart`:
- `RoutesNames` holds the module **base paths** (`quranBase = '/quran/'`, `adhanBase = '/adhan/'`, …), mounted in `AppModule.routes`.
- Each module gets a `<X>Routes` class with `static const` sub-paths and `static String` builders that compose the base + query params.

```dart
class QuranRoutes {
  QuranRoutes._();
  static const String reader = '/reader';                       // sub-route inside the module
  static String readerFromAyah(int surah, int ayah) =>
      '${RoutesNames.quranBase}reader?surah=$surah&ayah=$ayah';  // full path builder
  static String readerFromPage(int page) =>
      '${RoutesNames.quranBase}reader?page=$page';
}
```
Navigate:
```dart
Modular.to.pushNamed(QuranRoutes.readerFromAyah(2, 255)); // ✅ typed builder
Modular.to.navigate(RoutesNames.homeBase);                // ✅ replace stack
Modular.to.pushNamed('/quran/reader?surah=2&ayah=255');   // ❌ never a literal
```

## Reading params in the screen
Query/path params arrive via `r.args` when the module binds the route:
```dart
r.child(QuranRoutes.reader, child: (_) => SNMushafReader(args: r.args));
```
Parse `args.queryParams['surah']` inside the screen/module — keep parsing at the route boundary, not scattered.

## Module template
```dart
class QuranModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<BoxBookmarks>(BoxBookmarks.new);   // boxes/datasources
    i.add<DSLocalQuran>(DSLocalQuran.new);
    i.add<RQuran>(RImplQuran.new);                    // interface → impl
    i.add(UCGetPageLayout.new);                        // usecases
    i.addSingleton<CBAudioPlayer>(CBAudioPlayer.new);  // app-wide cubit
    i.add<CBQuranReader>(CBQuranReader.new);            // per-screen cubit
  }

  @override
  void routes(r) {
    r.child(QuranRoutes.surahList, child: (_) => const SNSurahList());
    r.child(QuranRoutes.reader,    child: (_) => SNMushafReader(args: r.args));
  }
}
```
Mount the module at its base in the root `AppModule` (`lib/core/services/routes/app_module.dart`).

## DI lifecycle
- `i.add<T>(T.new)` — factory (new per request): per-screen cubits, usecases, repos, datasources.
- `i.addSingleton<T>(T.new)` — single instance: Hive box wrappers, `BaseDio`, app-wide cubits (audio, downloads, reciter).

## This app has no role gating
It's a single-user devotional app — there is **no** `RoleGuard`, `SessionService.role`, or role-scoped routing. Don't add them.

## Checklist
- [ ] Typed `*Routes` builder (no string literal)
- [ ] Route registered with `r.child(...)` in the module
- [ ] Module mounted at its base in `AppModule`
- [ ] New module base added to `RoutesNames`
- [ ] Back/forward behaves in RTL
