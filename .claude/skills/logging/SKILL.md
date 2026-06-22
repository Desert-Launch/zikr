---
name: logging
description: Use whenever adding, reviewing, or fixing logging in the Quran app — any debug output, error reporting, network/request tracing, or replacing print/debugPrint. Triggers on "log", "logger", "print", "debugPrint", "trace", "console", "why is this failing", or adding any new datasource/repo that performs an action worth recording. Enforces the single AppLogger (Talker-backed), correct levels, redaction of secrets/location, and Clean Architecture log placement.
---

# Logging (Quran app)

One logger: **`AppLogger`**, backed by **Talker** (`talker_flutter`). Correct levels. Never log secrets or precise user location. Logs are a debugging aid, not noise.

## Use `AppLogger` only — never `print` / `debugPrint`
Logging lives in `lib/core/services/logging/app_logger.dart`. `AppLogger.init()` runs first in `main()`. The Talker instance also feeds `talker_dio_logger` for network tracing and `talker_flutter` for the in-app log screen.

```dart
AppLogger.debug('openPage start page=$page', tag: 'CBQuranReader');
AppLogger.info('reschedule complete count=$n', tag: 'CBReminders');
AppLogger.warning('font preload retried', tag: 'WMushafPage');
AppLogger.error('getPage failed', error: e, stackTrace: st, tag: 'RImplQuran');
```

The API is `debug` / `info` / `warning` / `error`, each taking an optional `tag:`. `error` also takes `error:` and `stackTrace:`. (For caught exceptions, `ErrorHelper.printDebugError(name:, error:, stackTrace:)` is the established helper in repos.)

## Levels — when to use which
| Level | Call | Use for |
|-------|------|---------|
| debug | `AppLogger.debug` | dev-only flow + values | 
| info  | `AppLogger.info` | meaningful lifecycle events (boot, reschedule, downloads done) |
| warning | `AppLogger.warning` | recoverable issues (retry, fallback, permission denied) |
| error | `AppLogger.error` | caught exceptions — ALWAYS pass `error:` + `stackTrace:` |

Default to `debug` for routine output. Reserve `info` for events worth seeing in a noisy build. `error` always carries the exception + stack.

## What NOT to log
🚫 This is a personal devotional app — **never log:** precise GPS coordinates (used for prayer times/Qibla), any auth token, or full device identifiers. Coordinates: log "location resolved" or a coarse country/city, never raw lat/lng.

## Where logs go (Clean Architecture)
- **Data (`r_impl_*`, `ds_*`)**: primary place errors are recorded. Map + log exceptions:
  ```dart
  } on DioException catch (e) {
    AppLogger.error('getTimings failed', error: e, tag: 'RImplPrayer');
    return Left(_handleDio(e));
  } catch (e, st) {
    ErrorHelper.printDebugError(name: 'RImplPrayer.getTimings', error: e, stackTrace: st);
    return Left(Failure.unexpectedFailure(message: e.toString()));
  }
  ```
- **Domain (`uc_*`)**: usually silent — keep usecases pure. Log only a genuinely notable decision.
- **Presentation (`cb_*`)**: `debug` for state transitions if useful; never log raw payloads.
- **Screens (`sn_*`, `w_*`)**: no logging. UI doesn't log.

## Network logging
- The Dio `talker_dio_logger` interceptor traces method + path + status in debug. Ensure it does not dump auth headers or coordinate-bearing query params in release.

## Checklist before "done"
- [ ] No `print` / `debugPrint` (use `AppLogger`)
- [ ] No raw GPS / token / device id in any log
- [ ] `error` logs pass `error:` + `stackTrace:`
- [ ] Correct level (not everything at `info`)
- [ ] No logging inside screens/widgets

## Anti-patterns
- ❌ `print('state: $state')` — wrong API, leaks the whole object.
- ❌ `AppLogger.error(e.toString())` — loses the stack; pass `error: e, stackTrace: st`.
- ❌ Logging every item in a loop — log the count.
- ❌ Swallowing an exception with only a log and no `Left(Failure)` return.
