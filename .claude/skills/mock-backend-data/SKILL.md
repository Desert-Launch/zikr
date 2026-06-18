---
name: mock-backend-data
description: Use whenever creating, shaping, or wiring DUMMY data that stands in for the not-yet-built backend in Taliah. Triggers on "mock data", "dummy data", "fake the API", "seed data", "no backend yet", or building any ds_mock_* / MockDataService work. Ensures the app cannot tell the backend is fake and that swapping to a real API later requires zero changes above the data layer.
---

# Mock-as-Backend (Taliah)

The app must behave as if a real backend exists. Mock lives ONLY in the data layer.

## The contract
- `ApiFlag.useMock` (in `core/services/network/api_flag.dart`) toggles mock vs real, per flavor.
- `ds_remote_<x>.dart` uses real endpoints from `end_points.dart` — write it now, keep dormant.
- `ds_mock_<x>.dart` loads `assets/db_mock/<x>.json` through `MockDataService`.
- Models parse the **exact shape the real API will return**. Flipping the flag changes nothing upstream.

## MockDataService responsibilities
```dart
class MockDataService {
  Future<dynamic> load(String name) async {
    final raw = await rootBundle.loadString('assets/db_mock/$name.json');
    return jsonDecode(raw);
  }
}
```
Extend it to optionally:
- Add latency (`Future.delayed`) so loading states show.
- Inject failures (a dev flag) so `WErrorState` + retry are exercised.

## Dummy JSON rules
1. Mirror the **expected real API envelope** (same keys, same nesting, snake_case/camelCase as the real API will use — match per endpoint, don't assume).
2. Keep **raw values**: numbers as numbers, ISO dates as strings — never pre-format.
3. Seed realistic Qatar K‑12 content (subjects, grades, names) but keep it small and maintainable.
4. One file per feature: `assets/db_mock/courses.json`, `grades.json`, `attendance.json`, etc.
5. Register `assets/db_mock/` in `pubspec.yaml`.

## Simulated heavy features feed from mock too
- GPS: a ticker interpolates a polyline → emits `m_child_location`.
- Virtual class: `m_virtual_session` with a sample `streamUrl`.
- Pickup/calling: a timer advances `m_pickup_request` status.
- Offline: cache mock results into Hive; an offline toggle forces Hive-only reads.

## Swap path (document in every repo impl)
```dart
// REAL_IMPL: set ApiFlag.useMock=false and ensure ds_remote_<x> endpoints + auth are live.
```

## Anti-patterns
- ❌ Mock objects created in the manager or screen.
- ❌ JSON shaped for UI convenience instead of the real contract.
- ❌ Hardcoded Dart lists instead of `assets/db_mock/*.json`.
- ❌ No failure path (every mock should be able to fail on demand).
