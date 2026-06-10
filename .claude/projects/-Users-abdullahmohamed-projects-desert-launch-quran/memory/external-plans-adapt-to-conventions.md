---
name: external-plans-adapt-to-conventions
description: When given an external plan/spec, take only the logic — use this repo's own structure, naming, and theme
metadata:
  type: feedback
---

When the user pastes an external implementation plan, spec, or reference from another project, treat it as a source of **logic only**. Do not copy its folder layout, file names, class names, or UI/theme choices.

**Why:** This repo has strict, non-negotiable conventions (two-letter file prefixes `cb_`/`s_`/`m_`/`r_`/`uc_`/`ds_`/`box_`, class = prefix uppercased; Clean Architecture data→domain→presentation; Cubit-only; `Either<Failure,T>` repos; shared widgets like `WSharedScaffold`; green/gold theme via `AppColorsLight`/`context.brand`). External plans use their own (often snake_case, different module shapes) — following them verbatim breaks consistency.

**How to apply:** Audit what already exists first, reuse it, then map the plan's logic onto our conventions. E.g. the plan's `adhan_settings_cubit.dart` → our `cb_adhan_settings.dart` + `s_adhan_settings.dart`; its `AdhanRepository` → `RAdhan`/`RImplAdhan`. See [[adhan-prayer-architecture]].
