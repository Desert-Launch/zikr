---
name: shared-components
description: Use when building or reusing common UI widgets in Taliah, or when about to use a raw Flutter widget that already has a shared wrapper. Triggers on "button", "scaffold", "loading", "text field", "image", "empty state", "shared widget", "reusable component". Enforces using and extending core/widgets shared components instead of framework widgets.
---

# Shared Components (Taliah)

One place for common UI. If you reach for a framework widget that has a shared wrapper, use the wrapper. If a pattern repeats, extract it to `core/widgets/` immediately.

## Canonical shared widgets (`core/widgets/`)
| Component | Replaces | Notes |
|-----------|----------|-------|
| `WSharedScaffold` | `Scaffold` | keyboard dismiss on tap built in |
| `WLoadingIndicator` | `CircularProgressIndicator` | default brand color, `size`/`color` params |
| `WCachedImage` | `Image.network` | shimmer placeholder + error widget |
| `WAppButton` | `ElevatedButton`/`TextButton` | `.primary/.secondary/.outlined/.text` |
| `WAppTextField` | raw `TextField` | consistent style + validation hook |
| `WEmptyState` | ad-hoc empty UI | icon + message + optional action |
| `WErrorState` | ad-hoc error UI | message + `onRetry` |
| forms in `core/widgets/forms/` | raw fields | `WPhoneField`, `WEmailField`, ... |

## Rules
1. Never use a framework widget when a `W*` wrapper exists.
2. App-wide visual changes happen in ONE place (the shared component).
3. New shared field → `core/widgets/forms/`. New shared visual → `core/widgets/`.
4. Feature-specific widgets stay in `modules/<f>/presentation/widgets/`.
5. All shared widgets use screenutil sizing + theme tokens (`AppColors`, `AppTextStyles`) + `.translated` text.
6. Build variants with named constructors, not boolean flags soup.

## When to extract
If you write the same widget tree twice → extract a shared component now, before the third copy exists.
