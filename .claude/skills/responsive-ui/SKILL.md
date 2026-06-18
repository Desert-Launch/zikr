---
name: responsive-ui
description: Use for any UI sizing, layout, or responsiveness work in Taliah — building screens/widgets, fixing overflow, supporting phones and tablets, spacing and typography. Triggers on "responsive", "screenutil", "sizing", "overflow", "tablet", "layout", "build the UI". Enforces flutter_screenutil usage, shared components, the 300-line cap, and no-function-widgets rule.
---

# Responsive UI (Taliah)

All sizing via Taliah's `*t` responsive extension (which wraps `flutter_screenutil`). All screens use shared components. Keep classes small.

## Sizing
Use the project getters from `core/extension/responsive_extension.dart` — **never** screenutil's raw `.w` / `.h` / `.sp` / `.r` directly. Import the extension, not `flutter_screenutil`.
```dart
import 'package:taliah/core/extension/responsive_extension.dart';

SizedBox(height: 16.ht);
Padding(padding: EdgeInsetsDirectional.all(12.wt));
Text('x', style: TextStyle(fontSize: 14.spt));
BorderRadius.circular(8.rt);
```
- Width → `.wt`, height → `.ht`, font → `.spt`, radius → `.rt` (also `.swt`/`.sht`/`.dmt`).
- `flutter_screenutil` is imported in exactly one place outside the extension: `core/app_widget.dart`, for `ScreenUtilInit` at the app root.
- Never hardcode raw pixel sizes for layout.

## Shared components (never use framework widgets directly)
| Use | Not |
|-----|-----|
| `WSharedScaffold` | `Scaffold` |
| `WLoadingIndicator` | `CircularProgressIndicator` |
| `WCachedImage` | `Image.network` |
| `WAppButton.*` | `ElevatedButton`/`TextButton` |
| `WAppTextField` | raw `TextField` |
| `WEmptyState` / `WErrorState` | ad-hoc empty/error UI |
Shared components live in `core/widgets/`. If a pattern repeats, extract it there immediately.

## Class size & structure
- **No class > 300 lines.** Split screens into widget classes.
- **No function widgets** (`Widget _buildCard()` ❌). Use a `class _Card extends StatelessWidget`.
- Move complex logic to manager/form classes, not the screen.

## Tablet / phone
- Use `LayoutBuilder` or screenutil breakpoints for tablet columns where the spec needs it (the spec requires responsive interfaces across screen sizes).
- Verify no overflow at small and large widths.

## State coverage on every screen
Loading → `WLoadingIndicator`; error → `WErrorState(onRetry:)`; empty → `WEmptyState`; data → content. Wire all four.

## Checklist
- [ ] All sizes via the `*t` extension (`.wt`/`.ht`/`.spt`/`.rt`), not raw screenutil getters
- [ ] Shared components used (no raw framework widgets where a W* exists)
- [ ] No class >300 lines; no function widgets
- [ ] Loading/error/empty handled
- [ ] No overflow phone + tablet, AR + EN
