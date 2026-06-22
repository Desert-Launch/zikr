---
name: localization-rtl
description: Use for any text, translation, or RTL/LTR work in the Quran app — adding strings, supporting Arabic/English, fixing mirrored layouts, language switching. Triggers on "translate", "localization", "i18n", "Arabic", "RTL", "add a string", "hardcoded text", ".tr()". Enforces FLAT prefixed JSON via localize_and_translate and correct RTL handling.
---

# Localization & RTL (Quran app)

Two locales: **Arabic (RTL, default)** and **English (LTR)**. Library: `localize_and_translate` (`LocalizeAndTranslate.init('ar','en')` runs in `main()`).

## FLAT JSON only
```json
// assets/lang/ar.json
{ "common_retry": "إعادة المحاولة", "prayer_fajr": "الفجر", "quran_ayah_label": "آية" }
```
```json
// assets/lang/en.json
{ "common_retry": "Retry", "prayer_fajr": "Fajr", "quran_ayah_label": "Ayah" }
```
- ❌ No nesting (`localize_and_translate` does not support it).
- ✅ Prefix by feature: `common_`, `prayer_`, `quran_`, `azkar_`, `tasbih_`, `reminders_`, `adhan_`.
- Keys identical across both files (run a key-parity check).

## Usage — `.tr()`
```dart
Text('quran_ayah_label'.tr())
Text('quran_downloads_ayat_unit'.tr())
```
The translation getter in this app is **`.tr()`** (not `.translated`). Never hardcode user-facing text. Every new string → add to BOTH `ar.json` and `en.json`.

## RTL correctness
- Use **logical** insets: `EdgeInsetsDirectional.only(start:, end:)` — not `left/right`.
- Use `AlignmentDirectional`, `start`/`end`, `TextAlign.start`.
- Direction-implying icons (back arrows, chevrons) must mirror — flip via directional awareness or `Transform` / `Directionality`.
- Some shared helpers exist for this (e.g. `w_localize_rotation.dart`) — reuse before reinventing.
- Test EVERY screen in both languages; fix overflow + mirroring. Arabic is the default.

## Quran/Arabic numerals & script
- Quran text and ayah glyphs are Arabic regardless of UI locale — never translate scripture.
- Keep raw numeric values; choose numeral rendering (Western vs Arabic-Indic) at the presentation layer per locale where the spec calls for it.

## Checklist
- [ ] No hardcoded user-facing strings
- [ ] Key exists in `ar.json` AND `en.json`, FLAT + prefixed
- [ ] Rendered via `.tr()`
- [ ] Directional insets/alignment used
- [ ] Screen verified in AR (RTL) + EN (LTR); directional icons mirror
