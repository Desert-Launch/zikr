---
name: flutter-debugging
description: Use when fixing a bug, error, exception, crash, or unexpected behavior in the Quran app. Triggers on "fix", "bug", "error", "crash", "not working", "exception", "wrong behavior", "analyze fails". Enforces the research → root-cause → fix → verify workflow and the zero-error completion gate.
---

# Flutter Debugging (Quran app)

Never rush to edit. Find the root cause, fix all occurrences, verify green. The app is **always running with hot reload** — do not run `flutter run`/`build`; save edits and (when needed) tell the user to hot restart.

## Workflow
### 1. Research
- Read the entire target file (not just the error line).
- Grep similar patterns + ALL usages of the symbol.
- Check imports, the cubit, the repo, the datasource, the Hive box — bugs often live a layer below the symptom.

### 2. Root cause
- Distinguish symptom from cause. A blank screen is usually a missing `emit`, an unmapped error swallowed into state, or a box that wasn't opened.
- Usual suspects in this app:
  - `HiveError: Box not found` → box opened too late; open it in `main()` before `runApp`.
  - UI doesn't update → missing `emit(state.copyWith(...))`, or `BlocSelector` selecting an unchanged field.
  - Mushaf glyphs render as boxes → QPC font not preloaded before the page builds.
  - Audio stops on lock → `JustAudioBackground.init()` ordering in `main()`.
  - Translation shows literally → key missing in `ar.json`/`en.json` or not prefixed; or used without `.tr()`.
  - Navigation fails → string-literal route instead of a typed `*Routes` builder.
  - `LateInitializationError` on a cubit field → cubit `new`'d directly instead of resolved via `Modular.get`/`binds`.
  - `!` on a nullable → crash (rule #4 forbids `!`).

### 3. Fix
- Fix the cause, not the symptom. Update ALL affected locations.
- Output the FULL corrected file/class, never a partial diff.
- Keep within layers: don't "fix" a UI bug by reaching into a datasource from the screen.

### 4. Verify (completion gate)
- [ ] `flutter analyze` = 0 errors.
- [ ] Walk the data flow: datasource/box → repo (`Either`) → usecase → cubit (`emit`) → screen (`BlocSelector`).
- [ ] Same bug checked elsewhere (grep).
- [ ] If a Hive adapter or freezed state changed → remember **`build_runner` is broken**: hand-edit the `.g.dart`/`.freezed.dart` + `quran_hive_registrar.dart` + `main.dart`, then tell the user to hot **restart**.
- Never say "done" with errors remaining or a half-fix.

## Common traps in this repo
- RTL: layout "broken" in Arabic is usually `left/right` instead of `start/end`.
- State: a value that "won't refresh" is usually a `BlocSelector` keyed to the wrong field, or mutating instead of `copyWith`.
- Audio/downloads: app-wide cubits are singletons — a second instance means it was `add`'d as a factory instead of `addSingleton`.
