---
name: localization-rtl
description: Use for any text, translation, or RTL/LTR work in Taliah — adding strings, supporting Arabic/English, fixing mirrored layouts, language switching. Triggers on "translate", "localization", "i18n", "Arabic", "RTL", "add a string", "hardcoded text". Enforces FLAT JSON with underscore prefixes via localize_and_translate and correct RTL handling.
---

# Localization & RTL (Taliah)

Two locales: **Arabic (RTL, default)** and **English (LTR)**. Library: `localize_and_translate`.

## FLAT JSON only
```json
// assets/lang/ar.json
{ "auth_email": "البريد الإلكتروني", "courses_title": "المقررات", "common_retry": "إعادة المحاولة" }
```
```json
// assets/lang/en.json
{ "auth_email": "Email", "courses_title": "Courses", "common_retry": "Retry" }
```
- ❌ No nesting (`localize_and_translate` does not support it).
- ✅ Prefix by feature: `auth_`, `courses_`, `grades_`, `common_`.
- Keys identical across both files (run a key-parity check).

## Usage
```dart
Text('courses_title'.translated)
```
Never hardcode user-facing text. Every new string → add to BOTH `ar.json` and `en.json`.

## Language switching
- A `LocaleController` flips locale and triggers `Directionality` rebuild.
- Settings screen toggles language live (no restart).
- After switching, verify direction with `Directionality.of(context)`.

## RTL correctness
- Use **logical** insets: `EdgeInsetsDirectional.only(start:, end:)` not `left/right`.
- Use `AlignmentDirectional`, `start`/`end`, `TextAlign.start`.
- Icons that imply direction (back arrows, chevrons) must mirror — use `Icons.arrow_back_ios` with directional awareness or flip via `Transform` when needed.
- Test EVERY screen in both languages; fix overflow + mirroring.

## Numbers
- Arabic vs Hindi numerals: keep raw values; choose numeral rendering at the presentation layer per locale if required by spec.

## Checklist
- [ ] No hardcoded strings
- [ ] Key exists in ar.json AND en.json
- [ ] Directional insets/alignment used
- [ ] Screen verified in AR + EN
- [ ] Directional icons mirror correctly
