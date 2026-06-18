---
name: flutter-debugging
description: Use when fixing a bug, error, exception, crash, or unexpected behavior in Taliah. Triggers on "fix", "bug", "error", "crash", "not working", "exception", "wrong behavior", "analyze fails". Enforces the research → root-cause → fix → verify workflow and the zero-error completion gate.
---

# Flutter Debugging (Taliah)

Never rush to edit. Find the root cause, fix all occurrences, verify green.

## Workflow
### 1. Research
- Read the entire target file (not just the error line).
- Grep similar patterns + ALL usages of the symbol.
- Check imports, the manager, the repo, the datasource, the mock JSON — bugs often live a layer below the symptom.

### 2. Root cause
- Distinguish symptom from cause. A null on screen is usually a missing `notifyListeners()`, a mock shape mismatch, or an unmapped error.
- Check the usual suspects:
  - Mock JSON shape ≠ model `fromJson` → parse returns nulls.
  - Missing `notifyListeners()` → UI doesn't update.
  - `Consumer` placed wrong → no rebuild.
  - String route used → navigation fails.
  - `!` on a nullable → crash.
  - `setState`/`notifyListeners` during build → exception.

### 3. Fix
- Fix the cause, not the symptom. Update ALL affected locations.
- Output the FULL corrected file/class, never a partial diff.
- Add a guard if the same class of bug could recur.

### 4. Verify (completion gate)
- [ ] `flutter analyze` = 0 errors.
- [ ] Walk the data flow mentally: datasource → repo → usecase → manager → screen.
- [ ] Same bug checked elsewhere (grep).
- [ ] If Hive adapters changed → `build_runner`.
- Never say "done" with errors remaining or a half-fix.

## Common Taliah-specific traps
- Mock-first: if data is empty, suspect the JSON path/shape before the UI.
- RTL: layout "broken" in Arabic is usually `left/right` instead of `start/end`.
- Role routing: wrong screen for a role → check `RoleGuard` + `SessionService.role`.
- Offline (F11): stale data → Hive cache not invalidated.
