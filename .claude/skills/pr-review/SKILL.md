---
name: pr-review
description: Use when reviewing a pull request, diff, branch, or set of changes in Taliah before merge. Triggers on "review this PR", "review my changes", "check this diff", "is this ready to merge", "code review", "review before commit". Produces a structured, severity-tagged review enforcing Taliah's architecture, naming, provider, mock-first, i18n/RTL, and quality gates.
---

# PR Review (Taliah)

Review against Taliah conventions. Be direct — flag every violation with a fix, not a vibe. Block on 🔴, request changes on 🟠, note 🟡.

## Pre-flight
1. Read the diff fully + the files it touches (not just the hunks).
2. Grep for usages of changed symbols — did the PR update ALL call sites?
3. Confirm `flutter analyze` would pass (no obvious errors/unused imports).

## Review dimensions (score each)

### 🏛 Architecture & layering
- [ ] Code in the right layer (no Dio/datasource in presentation; no logic in screens/managers).
- [ ] Interfaces in `domain/repos/`, impls in `data/repos/` — never mixed.
- [ ] Models (`M*`) mapped to entities (`Param*`) before reaching UI.
- [ ] One-direction flow: screen → manager → usecase → repo → datasource.

### 🏷 Naming & structure
- [ ] Correct prefixes/locations (`sn_`, `w_`, `mg_`, `f_`, `param_`, `m_`, `r_`, `r_impl_`, `uc_`, `ds_`).
- [ ] No `Screen` suffix; no project prefixes on components.
- [ ] No class > 300 lines; no function widgets.

### 🧩 State (provider)
- [ ] `Mg*` extends `ChangeNotifier`; `isLoading`/`errorMessage`; `notifyListeners()` after changes.
- [ ] `Consumer`/`Selector` wraps only reactive subtree.
- [ ] No MobX. No `notifyListeners()` in build.

### 📦 Mock-first data
- [ ] Both `ds_remote_*` (dormant) and `ds_mock_*` present.
- [ ] Repo selects source via `ApiFlag`; errors via `_handleDioException` (both `error`+`message`).
- [ ] Mock JSON mirrors real API shape; raw values; has a failure path.

### 🌐 i18n & RTL
- [ ] No hardcoded user-facing strings.
- [ ] Keys added to BOTH `ar.json` + `en.json`; FLAT; prefixed.
- [ ] Directional insets/alignment; verified AR + EN.

### 🎨 UI quality
- [ ] Shared components used (`WSharedScaffold`, `WLoadingIndicator`, `WCachedImage`, `WAppButton`...).
- [ ] Sizing via the `*t` wrapper (`.wt`/`.ht`/`.spt`/`.rt`), not raw screenutil getters.
- [ ] Loading/error/empty states on every list/detail.

### 🧭 Routing
- [ ] Typed `AppRoutes` methods only; no string routes.
- [ ] `RoleGuard` applied to role-scoped routes.

### 🛡 Safety
- [ ] No `!` null assertion unless provably safe; null-aware used.
- [ ] Package imports only; no relative imports.
- [ ] No secrets/keys committed.

## Output format
```
## PR Review: <title>
**Verdict:** ✅ Approve / 🟠 Request changes / 🔴 Block

### 🔴 Blocking
- file:line — issue → fix

### 🟠 Should fix
- ...

### 🟡 Nits
- ...

### ✅ Good
- what was done well
```
Always include the exact fix or a corrected snippet for 🔴/🟠 items. Output full corrected files when the change is non-trivial.
