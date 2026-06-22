---
name: data-sources
description: Use whenever creating or wiring the data layer in the Quran app — Hive box wrappers, local datasources, remote Dio datasources, bundled-asset loaders, or download/cache work. Triggers on "data source", "datasource", "Hive box", "box_", "ds_", "cache", "remote API", "load asset", "download". Enforces the data-layer split (datasources/ vs sources/local), Either<Failure,T> at the repo boundary, and the no-mock-backend reality of this app.
---

# Data Sources (Quran app)

This app has **no mock backend** and no `ApiFlag`/`MockDataService` switch. Data is real: bundled assets, Hive caches, and a few remote APIs. Data sources may throw; the **repo** catches and returns `Either<Failure, T>`.

## Where each kind of source lives
| Kind | Folder | File → Class | Backed by |
|------|--------|--------------|-----------|
| Local datasource | `data/datasources/local/` | `ds_local_*.dart` | bundled JSON/assets, font files, platform plugins (geolocator, compass) |
| Remote datasource | `data/datasources/remote/` | `ds_remote_*.dart` | `BaseDio` (Aladhan prayer API, audio CDN) |
| Download datasource | `data/datasources/remote/` | `ds_*_downloader.dart` | `dio` + `flutter_cache_manager` / `path_provider` |
| Hive box wrapper | `data/sources/local/` | `box_*.dart` → `Box*` | `HiveBoxBase<T>` (`lib/core/utils/hive_box_base.dart`) |

## Hive box wrapper
```dart
// data/sources/local/box_bookmarks.dart
class BoxBookmarks extends HiveBoxBase<MBookmark> {
  BoxBookmarks() : super('quran_bookmarks', MBookmarkAdapter());
}
```
- Every box is **opened in `lib/main.dart` before `runApp`** (~22 boxes). A box opened lazily throws `HiveError: Box not found`.
- Register box wrappers as `addSingleton` in the module's `binds`.
- Adapters + the registrar (`quran_hive_registrar.dart`) are **hand-maintained** — `build_runner` is broken here (see CLAUDE.md §10).

## Remote datasource (Dio)
```dart
// data/datasources/remote/ds_remote_prayer.dart
class DSRemotePrayer {
  DSRemotePrayer(this._dio);
  final BaseDio _dio;

  Future<MPrayerDay> fetchTimings(...) async {
    final res = await _dio.get(EndPoints.aladhanTimings, queryParameters: {...});
    return MPrayerDay.fromJson(res.data['data']);   // let exceptions bubble
  }
}
```
- Endpoints are centralized in `end_points.dart`. Never inline a URL.
- The datasource does **not** catch — it lets `DioException` bubble to the repo.

## Repo converts exceptions → Failure
```dart
@override
Future<Either<Failure, MPrayerDay>> getTimings(...) async {
  try {
    return Right(await _remote.fetchTimings(...));
  } on DioException catch (e) {
    return Left(_handleDio(e));                 // → Failure.networkFailure / serverFailure
  } catch (e, st) {
    ErrorHelper.printDebugError(name: 'RImplPrayer.getTimings', error: e, stackTrace: st);
    return Left(Failure.unexpectedFailure(message: e.toString()));
  }
}
```
`Failure` factories available: `networkFailure`, `serverFailure`, `cacheFailure`, `authenticationFailure`, `notFoundFailure`, `validationFailure`, `unexpectedFailure`.

## Bundled assets (Quran text, fonts, azkar)
- Static Quran/azkar content ships in `assets/` and is read by `ds_local_*` via `rootBundle` — it is not fetched.
- QPC mushaf fonts are loaded by `ds_qpc_font_loader` and must be preloaded before the page renders (see Quran plan §10), or glyphs render as boxes.

## Anti-patterns
- ❌ Inventing a `ds_mock_*` / `MockDataService` / `ApiFlag` — that pattern is not used here.
- ❌ A datasource that returns `Either` (only repos do); datasources throw.
- ❌ A repo method that doesn't return `Either<Failure, T>`.
- ❌ Opening a Hive box anywhere other than `main()`.
- ❌ Hardcoded URLs instead of `end_points.dart`.
- ❌ Calling a `ds_*`, `box_*`, or `Dio` from a cubit or screen — go through usecase → repo.
