---
name: responsive-ui
description: Use for any UI sizing, layout, or responsiveness work in the Quran app — building screens/widgets, fixing overflow, supporting phones and tablets, spacing and typography. Triggers on "responsive", "screenutil", "sizing", "overflow", "tablet", "layout", "build the UI". Enforces flutter_screenutil sizing, shared components, the 300-line cap, and the no-function-widgets rule.
---

# Responsive UI (Quran app)

Sizing via `flutter_screenutil`. All screens use shared components. Keep classes small.

## Sizing
Use screenutil getters directly — `.w`, `.h`, `.sp`, `.r`:
```dart
SizedBox(height: 16.h);
Padding(padding: EdgeInsetsDirectional.all(12.w), child: ...);
Text('x', style: TextStyle(fontSize: 14.sp));
BorderRadius.circular(8.r);
```
- `ScreenUtilInit` is configured once at the app root; everywhere else just use the getters.
- For values that must not blow up on large screens, use the project helpers in `lib/core/responsive/` (`ClampedFont` → `spCapped`/`spClamp`, `rCapped`; `ResponsiveEdgeInsets.responsive`). Reach for these instead of ad-hoc `.clamp()` chains.
- Never hardcode raw pixel sizes for layout.

## Shared components (never use framework widgets directly when a wrapper exists)
| Use | Not |
|-----|-----|
| `WSharedScaffold` | `Scaffold` |
| `WGradientAppBar` | raw `AppBar` (this is the shared green header) |
| `WAppButton` | `ElevatedButton` / `TextButton` |
| `WLoadingOverlay` | `CircularProgressIndicator` |
| `WEmptyState` | ad-hoc empty/error UI |
| `core/widgets/forms/W*Field` | raw `TextField` |
Shared components live in `lib/core/widgets/`. If a pattern repeats, extract it there immediately.

## Class size & structure
- **No class > 300 lines.** Split screens into widget classes.
- **No function widgets** (`Widget _buildCard()` ❌). Use `class _Card extends StatelessWidget`.
- Move logic to the cubit, not the screen.

## Tablet / phone
- Use `LayoutBuilder` or screenutil breakpoints where the spec needs tablet columns (responsive helpers in `lib/core/responsive/` cover common cases).
- Verify no overflow at small and large widths, AR + EN.

## State coverage on every screen
Loading → `WLoadingOverlay`; error/empty → `WEmptyState` (with retry); data → content. Drive these off the cubit's `LoadStatus`, wiring only the reactive subtree via `BlocSelector`.

## Checklist
- [ ] Sizes via `.w`/`.h`/`.sp`/`.r` (or the `core/responsive` helpers), no raw pixels
- [ ] Shared `W*` components used where they exist
- [ ] No class > 300 lines; no function widgets
- [ ] Loading/error/empty handled off `LoadStatus`
- [ ] No overflow phone + tablet, AR + EN
