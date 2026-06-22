---
name: shared-components
description: Use when building or reusing common UI widgets in the Quran app, or when about to use a raw Flutter widget that already has a shared wrapper. Triggers on "button", "scaffold", "app bar", "loading", "text field", "empty state", "shared widget", "reusable component". Enforces using and extending core/widgets shared components instead of framework widgets.
---

# Shared Components (Quran app)

One place for common UI: `lib/core/widgets/`. If you reach for a framework widget that has a shared wrapper, use the wrapper. If a pattern repeats, extract it to `core/widgets/` immediately.

## Canonical shared widgets (`lib/core/widgets/`)
| Component | Replaces | Notes |
|-----------|----------|-------|
| `WSharedScaffold` | `Scaffold` | app-standard scaffold (`w_shared_scaffold.dart`) |
| `WGradientAppBar` | raw `AppBar` | the shared green gradient header — reuse on every screen |
| `WAppButton` | `ElevatedButton` / `TextButton` | named variants, not boolean soup (`w_app_button.dart`) |
| `WLoadingOverlay` | `CircularProgressIndicator` | blocking/inline loading (`w_loading_overlay.dart`) |
| `WEmptyState` | ad-hoc empty/error UI | icon + message + optional retry action |
| `WDetailRow` | ad-hoc label/value rows | `w_detail_row.dart` |
| `core/widgets/forms/W*Field` | raw `TextField` | `WTextField`, `WEmailField`, `WPasswordField`, `WPhoneField`, `WDateField`, `WDropdownField`, `WPinCodeField`, `WCheckboxField`, … |

## Rules
1. Never use a framework widget when a `W*` wrapper exists.
2. App-wide visual changes happen in ONE place (the shared component).
3. New shared field → `core/widgets/forms/`. New shared visual → `core/widgets/`.
4. Feature-specific widgets stay in `modules/<f>/presentation/widgets/` as `w_*` **classes** (no function widgets).
5. All shared widgets use screenutil sizing (`.w`/`.h`/`.sp`/`.r`), theme tokens (`AppColors`, `AppTextStyles`), and `.tr()` text.
6. Build variants with named constructors, not boolean flags.
7. Naming: shared widgets are `W*` with **no** project prefix (`WAppButton`, never `QrnButton`).

## When to extract
If you write the same widget tree twice → extract a shared component now, before the third copy exists.
