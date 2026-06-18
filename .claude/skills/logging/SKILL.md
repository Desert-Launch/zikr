---
name: logging
description: Use whenever adding, reviewing, or fixing logging in Taliah — any debug output, error reporting, network/request tracing, or replacing print/debugPrint. Triggers on "log", "logger", "print", "debugPrint", "trace", "console", "why is this failing", or adding any new feature/datasource/repo that performs an action worth recording. Enforces a single AppLogger, correct levels, mandatory redaction of secrets/student PII, and Clean Architecture log placement.
---

# Logging (Taliah)

One logger. Correct levels. Never log secrets or student PII. Logs are a debugging aid, not noise.

## The one rule that matters most
🚫 **NEVER log:** auth tokens, passwords, OTPs, full phone numbers, national IDs, GPS coordinates of a child, exam answers, or any student/parent personal data. This is a Qatar MOE / minors-data app — leaked PII in logs is a compliance incident, not a bug. When in doubt, redact.

## Use `AppLogger` only — never `print` / `debugPrint`
Logging lives in `core/services/logging/app_logger.dart`, backed by the `logger` package (pretty console in debug, silenced/forwarded in release).

```dart
// core/services/logging/app_logger.dart
import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

class AppLogger {
  AppLogger._();
  static final Logger _l = Logger(
    level: kReleaseMode ? Level.warning : Level.debug, // quiet in prod
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 6, colors: true),
  );

  static void t(String m) => _l.t(m);                 // trace (verbose flow)
  static void d(String m) => _l.d(m);                 // debug (dev info)
  static void i(String m) => _l.i(m);                 // info (lifecycle events)
  static void w(String m) => _l.w(m);                 // warning (recoverable)
  static void e(String m, [Object? err, StackTrace? s]) => _l.e(m, error: err, stackTrace: s);
}
```

## Levels — when to use which
| Level | Call | Use for | Example |
|-------|------|---------|---------|
| trace | `AppLogger.t` | fine-grained flow | "MgCourses.load() start" |
| debug | `AppLogger.d` | dev-only values (redacted) | "fetched 12 courses from mock" |
| info  | `AppLogger.i` | meaningful events | "login success role=teacher" |
| warning | `AppLogger.w` | recoverable issues | "mock latency injected failure, retrying" |
| error | `AppLogger.e` | caught exceptions + stack | "course fetch failed" + err + stack |

Default to `debug` for routine dev output. Reserve `info` for events you'd want in a release/warning build. `error` ALWAYS passes the exception object + stack trace.

## Where logs go (Clean Architecture)
- **Data layer (`r_impl_*`, `ds_*`)**: log network/mock calls and map+log exceptions. This is the primary place errors are recorded.
  ```dart
  } on DioException catch (e, s) {
    AppLogger.e('getCourses failed', e, s);
    return Left(_handleDioException(e));
  }
  ```
- **Domain (`uc_*`)**: usually no logging — keep usecases pure. Log only a genuinely notable business decision.
- **Presentation (`mg_*`)**: `trace`/`debug` for state transitions if useful; never log raw API payloads here.
- **Screens (`sn_*`, `w_*`)**: no logging. UI doesn't log.

## Redaction helpers (use them)
Add to the logger or an extension; always pass user-identifying values through these:
```dart
String maskPhone(String p) => p.length < 4 ? '***' : '****${p.substring(p.length - 3)}';
String maskId(String id) => '***${id.length}chars';
// tokens/coords → never log at all, not even masked
```
Example: `AppLogger.i('login ok user=${maskPhone(phone)} role=$role');`

## Network logging
- In debug only, attach a Dio interceptor that logs method + path + status — **strip Authorization headers and request bodies containing credentials**.
- Mock datasources (`ds_mock_*`): log at `debug` which JSON file was loaded + whether a failure was injected.

## Checklist before "done"
- [ ] No `print` / `debugPrint` anywhere (use `AppLogger`).
- [ ] No token / password / OTP / child GPS / full phone / national ID in any log.
- [ ] User identifiers masked via helpers.
- [ ] `error` logs include the exception object + stack trace.
- [ ] Correct level (not everything at `info`).
- [ ] No logging inside screens/widgets.
- [ ] Release build stays quiet (level ≥ warning).

## Anti-patterns
- ❌ `print('user: $user')` → leaks the whole object, wrong API.
- ❌ `AppLogger.i(response.data)` → may dump PII/secrets; and it's debug-level info.
- ❌ Logging in a loop over every list item → noise; log the count.
- ❌ `catch (e) { AppLogger.e(e.toString()); }` → loses the stack trace; pass `e, s`.
- ❌ Swallowing an exception with only a log and no `Left(Failure)` return.
