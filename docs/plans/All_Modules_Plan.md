# All Modules — Complete Implementation Plan (v2)

> Companion to [`Quran_Module_Plan.md`](./Quran_Module_Plan.md). This document covers **every module except the Quran reader**.
> Stack assumption: Flutter · Cubit (`flutter_bloc`) · `flutter_modular` (DI + routing) · Hive · Clean Architecture · Dio.
> Conventions: see [`instructions.md`](../instructions.md) §7 (naming) and §8 (architecture).

**Change log (v2):**
- ✅ Decision 1 — Bundled top 10 adhan recitations with resources documented
- ✅ Decision 2 — Hourly tasbih fires 08:00–22:00 only
- ✅ Decision 3 — Mosques: 10 + 10 (load-more, not pagination), cache until user location changes
- ✅ Decision 4 — Reminders capped at 30
- ✅ Decision 5 — Khatma completion: congrats screen + "start a new khatma" button
- ✅ Decision 6 — Auth module added (Login + Registration + Forgot Password) backed by a **mock backend** with fake endpoints & seeded data
- ✅ Decision 7 — Dark mode is now an explicit v1 feature, planned end-to-end

---

## Table of Contents

1. [Overview](#1-overview)
2. [Shared Foundations](#2-shared-foundations)
3. [Theme System (Dark Mode included)](#3-theme-system)
4. [Mock Backend (Fake API Layer)](#4-mock-backend-fake-api-layer)
5. [Auth Module (Login + Register + Forgot Password)](#5-auth-module)
6. [Onboarding Module](#6-onboarding-module)
7. [Home Module](#7-home-module)
8. [Prayer Times Module](#8-prayer-times-module)
9. [Adhan Audio Engine](#9-adhan-audio-engine)
10. [Azkar Module](#10-azkar-module)
11. [Tasbih Module](#11-tasbih-module)
12. [Reminders Module (max 30)](#12-reminders-module)
13. [Mosques Module (10 + Load More + Location Cache)](#13-mosques-module)
14. [Qibla Module](#14-qibla-module)
15. [Khatma Module (with Congrats Flow)](#15-khatma-module)
16. [Settings Module](#16-settings-module)
17. [Notifications Service (Hourly 08–22 included)](#17-notifications-service)
18. [Legal Pages Module](#18-legal-pages-module)
19. [Cross-Module Integration Points](#19-cross-module-integration-points)
20. [Implementation Order & Timeline](#20-implementation-order--timeline)
21. [Acceptance Criteria](#21-acceptance-criteria)

---

## 1. Overview

The app is composed of **14 modules** plus shared services. Quran is in its own dedicated plan. This document covers the remaining 13 modules and 2 cross-cutting services (Adhan engine, Notifications), the mock backend, the theme system, and the auth flow.

**Status legend:**
- 🆕 **Build from scratch** — UI + logic + data layer all new
- 🎨 **UI rebuild only** — logic already implemented by client
- ⚙️ **Logic exists, polish UI + add missing pieces**

| # | Module | Status | Effort |
|---|--------|--------|--------|
| 3 | Theme System (incl. dark mode) | 🆕 | 2h |
| 4 | Mock Backend (fake API) | 🆕 | 3h |
| 5 | Auth (login/register/forgot) | 🆕 | 6h |
| 6 | Onboarding | 🆕 | 2h |
| 7 | Home | 🆕 | 4h |
| 8 | Prayer Times | 🎨 UI rebuild | 5h |
| 9 | Adhan Engine | 🆕 | 6h |
| 10 | Azkar | 🎨 UI rebuild | 4.5h |
| 11 | Tasbih | 🆕 | 2h |
| 12 | Reminders | 🆕 (cap 30) | 4.5h |
| 13 | Mosques | 🆕 (10+10 load-more, location cache) | 3.5h |
| 14 | Qibla | 🎨 UI rebuild | 1h |
| 15 | Khatma | ⚙️ + congrats flow | 2.5h |
| 16 | Settings | 🆕 | 2h |
| 17 | Notifications | 🆕 (hourly 08–22) | folded |
| 18 | Legal Pages | 🆕 | 1.5h |
| — | Project Setup | 🆕 | 8h |

**Total (non-Quran):** ~57 hours (up from 45 in v1 — Auth, Mock Backend, Theme System, and Dark Mode added per your decisions).

---

## 2. Shared Foundations

### 2.1 Hive `typeId` Registry (updated)

```dart
// Reserved Hive typeIds — NEVER reuse a number
//
//   0–9    Core      (MUser=0, MAuthToken=1, MAppSettings=2, MThemePref=3)
//   10–19  Quran     (MBookmark=10, MLastRead=11, MDownloadTask=12, MReciterPref=13)
//   20–29  Prayer    (MPrayerSettings=20, MPrayerCache=21)
//   30–39  Azkar     (MAzkarFavorite=30, MAzkarProgress=31)
//   40–49  Tasbih    (MTasbihCounter=40, MTasbihHistory=41)
//   50–59  Reminders (MReminder=50)
//   60–69  Mosques   (MFavoriteMosque=60, MMosquesCache=61)
//   70–79  Qibla     (MQiblaCalibration=70)
//   80–89  Khatma    (MKhatmaPlan=80, MKhatmaProgress=81, MKhatmaDay=82, MKhatmaCompletion=83)
//   90–99  Settings  (MNotificationsToggle=90)
//   100–109 Notifications (MScheduledNotification=100, MNotificationLog=101)
//   110–119 Adhan     (MAdhanPreference=110)
```

### 2.2 Global Routes class (updated)

```dart
class AppRoutes {
  static const root        = '/';
  static const splash      = '/splash';
  static const auth        = '/auth';
  static const onboarding  = '/onboarding';
  static const home        = '/home';
  static const quran       = '/quran';
  static const prayer      = '/prayer';
  static const adhan       = '/adhan';
  static const azkar       = '/azkar';
  static const tasbih      = '/tasbih';
  static const reminders   = '/reminders';
  static const mosques     = '/mosques';
  static const qibla       = '/qibla';
  static const khatma      = '/khatma';
  static const settings    = '/settings';
  static const legal       = '/legal';
}
```

### 2.3 App-startup decision tree

```
App start
   ↓
Splash (read flags)
   ↓
hasSeenOnboarding? ──No──→ Onboarding → Language → Location → Auth
   │ Yes
   ↓
isLoggedIn? ──No──→ Auth (Login)
   │ Yes
   ↓
Home
```

### 2.4 Shared widgets

These live in `lib/core/widgets/` and **all** support both light and dark themes via `Theme.of(context)`:

- `WSharedScaffold` · `WAppBar` · `WAppButton` (primary/secondary/outlined/text)
- `WLoadingIndicator` · `WCachedImage` · `WEmptyState` · `WErrorState`
- `WConfirmDialog` · `WBottomSheet` · `WSectionHeader` · `WCard`
- **New for auth:** `WTextField`, `WPasswordField`, `WPhoneField` (already in core), `WLinkText`

---

## 3. Theme System

### Goal
Full light + dark + system-follow theme, controlled by a singleton `CBTheme`, persisted to Hive, applied without app restart.

### File structure

```
lib/core/theme/
├── app_theme.dart                  # buildLightTheme(), buildDarkTheme()
├── app_colors.dart                 # static const colors per theme
├── app_typography.dart             # text styles (Cairo / Tajawal for Arabic, Inter for English)
├── app_dimensions.dart             # spacing, radii, elevations
└── theme_extensions.dart           # custom ThemeExtension<AppColors>

lib/core/cubits/
├── cb_theme.dart                   # SINGLETON
└── s_theme.dart                    # @freezed
```

### Color tokens (matches the green/gold Figma palette)

```dart
// Light
class AppColorsLight {
  static const primary        = Color(0xFF0E6B47);   // brand green
  static const primaryDark    = Color(0xFF0A5639);
  static const accent         = Color(0xFFC9A227);   // gold
  static const background     = Color(0xFFF8F8F8);
  static const surface        = Color(0xFFFFFFFF);
  static const onPrimary      = Color(0xFFFFFFFF);
  static const onBackground   = Color(0xFF1A1A1A);
  static const onSurface      = Color(0xFF1A1A1A);
  static const muted          = Color(0xFF6B6B6B);
  static const border         = Color(0xFFE0E0E0);
  static const error          = Color(0xFFD32F2F);
  static const success        = Color(0xFF2E7D32);
}

// Dark
class AppColorsDark {
  static const primary        = Color(0xFF2A9D6B);   // lifted green for contrast
  static const primaryDark    = Color(0xFF0E6B47);
  static const accent         = Color(0xFFE0BD4A);   // brighter gold for dark BG
  static const background     = Color(0xFF0F1411);   // near-black with green tint
  static const surface        = Color(0xFF1A211D);   // card surface
  static const onPrimary      = Color(0xFFFFFFFF);
  static const onBackground   = Color(0xFFEDEDED);
  static const onSurface      = Color(0xFFEDEDED);
  static const muted          = Color(0xFF9A9A9A);
  static const border         = Color(0xFF2A3530);
  static const error          = Color(0xFFEF5350);
  static const success        = Color(0xFF66BB6A);
}
```

### State

```dart
enum EThemeMode { system, light, dark }

@freezed
class STheme with _$STheme {
  const factory STheme({
    @Default(EThemeMode.system) EThemeMode mode,
  }) = _STheme;
}

class CBTheme extends Cubit<STheme> {
  CBTheme(this._repo) : super(const STheme());
  final RSettings _repo;

  Future<void> load() async {
    final mode = await _repo.getThemeMode();
    emit(state.copyWith(mode: mode));
  }

  Future<void> setMode(EThemeMode mode) async {
    await _repo.setThemeMode(mode);
    emit(state.copyWith(mode: mode));
  }

  ThemeMode toMaterialMode() => switch (state.mode) {
    EThemeMode.system => ThemeMode.system,
    EThemeMode.light  => ThemeMode.light,
    EThemeMode.dark   => ThemeMode.dark,
  };
}
```

### Root MaterialApp wiring

```dart
class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CBTheme, STheme>(
      bloc: Modular.get<CBTheme>(),
      builder: (_, state) => MaterialApp.router(
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: Modular.get<CBTheme>().toMaterialMode(),
        // … router config …
      ),
    );
  }
}
```

### Mushaf-specific dark-mode rule

The Quran reader needs an extra theme — **Sepia mode** — which sits between light and dark (warm cream paper). Define it in `app_theme.dart` as a third theme tag that the Quran reader picks via its own settings (independent of app theme).

### Effort: 2h

---

## 4. Mock Backend (Fake API Layer)

### Purpose
A self-contained fake backend that **looks and feels like a real REST API** to the rest of the app. This lets the auth flow, profile endpoints, and any future backend-dependent feature work today without any actual server. When a real backend exists later, only the `BaseDio.baseUrl` and a few endpoint paths change.

### Two implementation modes

The mock backend ships with **two switchable modes** controlled by a build flavor flag in `lib/flavors/`:

| Mode | Used in | How it works |
|------|---------|-------------|
| `mockMode = true` (default) | dev | Dio interceptor catches requests, returns canned JSON from `assets/mock/` with a realistic latency |
| `mockMode = false` | prod | Dio calls real backend at `BaseDio.baseUrl` |

This means **no code change** is needed in repos / data sources when switching to a real backend.

### File structure

```
lib/core/services/mock_backend/
├── mock_backend_module.dart                # registered in AppModule
├── mock_interceptor.dart                   # Dio interceptor that intercepts based on path
├── mock_database.dart                      # in-memory store, hydrated from assets/mock/*.json
├── handlers/
│   ├── auth_handler.dart                   # /auth/login, /auth/register, /auth/forgot, /auth/me
│   ├── profile_handler.dart                # /users/profile (GET, PATCH)
│   └── (future handlers go here)
└── models/
    └── m_mock_response.dart                # { statusCode, body, delayMs }

assets/mock/
├── users.json                              # seeded fake users
├── auth_responses.json                     # canned tokens, error responses
└── README.md                               # how the mock works
```

### Seeded fake users (`assets/mock/users.json`)

```json
[
  {
    "id": "u_001",
    "name": "محمد أحمد",
    "name_en": "Mohamed Ahmed",
    "email": "demo@quran.app",
    "phone": "+201001234567",
    "password_hash": "P@ssw0rd!",
    "avatar": "https://i.pravatar.cc/300?img=12",
    "created_at": "2026-01-15T10:30:00Z",
    "is_verified": true
  },
  {
    "id": "u_002",
    "name": "فاطمة محمد",
    "name_en": "Fatima Mohamed",
    "email": "test@quran.app",
    "phone": "+201112345678",
    "password_hash": "Test1234!",
    "avatar": "https://i.pravatar.cc/300?img=44",
    "created_at": "2026-02-20T14:45:00Z",
    "is_verified": true
  }
]
```

### Fake endpoints

| Method | Endpoint | Description | Mock response |
|--------|----------|-------------|--------------|
| POST | `/auth/register` | New user | 201 + user + token (after 800ms delay) |
| POST | `/auth/login` | Email/phone + password | 200 + user + token, or 401 if wrong |
| POST | `/auth/forgot-password` | Send reset link | 200 always (real-world: email sent) |
| POST | `/auth/reset-password` | With OTP from email | 200 if OTP=`123456` else 400 |
| POST | `/auth/logout` | Invalidate token | 204 |
| GET | `/auth/me` | Current user (via token) | 200 + user, or 401 |
| PATCH | `/users/profile` | Update name/avatar | 200 + updated user |
| POST | `/auth/refresh` | New access token | 200 + token |

### Mock interceptor behaviour

```dart
class MockInterceptor extends Interceptor {
  MockInterceptor(this._db, this._authHandler, this._profileHandler);
  final MockDatabase _db;
  final AuthHandler _authHandler;
  final ProfileHandler _profileHandler;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!AppConfig.useMockBackend) return handler.next(options);

    // Realistic network delay
    await Future.delayed(const Duration(milliseconds: 600));

    final MockResponse? response = switch (options.path) {
      '/auth/login'           => _authHandler.login(options.data),
      '/auth/register'        => _authHandler.register(options.data),
      '/auth/forgot-password' => _authHandler.forgotPassword(options.data),
      '/auth/reset-password'  => _authHandler.resetPassword(options.data),
      '/auth/logout'          => _authHandler.logout(options.headers),
      '/auth/me'              => _authHandler.me(options.headers),
      '/users/profile'        => _profileHandler.handle(options),
      _ => null,
    };

    if (response == null) return handler.next(options);

    handler.resolve(Response(
      requestOptions: options,
      statusCode: response.statusCode,
      data: response.body,
    ));
  }
}
```

### Token strategy
- On successful login/register: server returns `{ access_token: "mock_<userId>_<timestamp>", refresh_token: "..." }`.
- Token is stored in `BoxAuthToken` (typeId 1).
- `BaseDio` adds `Authorization: Bearer <token>` automatically on every request.
- The mock handler parses `Bearer mock_<userId>_*` and looks the user up.

### Effort: 3h

---

## 5. Auth Module

### Purpose
Onboard new users and authenticate returning users. Sits **after** onboarding language/location and **before** home.

### Screens

| Screen | Purpose |
|--------|---------|
| `SNLogin` | Email/phone + password + "Forgot password" link + "Create account" link |
| `SNRegister` | Name + email + phone + password + confirm password |
| `SNForgotPassword` | Email input → "send reset link" |
| `SNVerifyOtp` | 6-digit OTP from email (mock accepts `123456`) |
| `SNResetPassword` | New password + confirm |
| `SNRegisterSuccess` | Success state with "Continue to app" |

### File structure

```
lib/modules/auth/
├── auth_module.dart
├── data/
│   ├── models/
│   │   ├── m_user.dart                     # typeId 0
│   │   └── m_auth_token.dart               # typeId 1
│   ├── datasources/
│   │   ├── remote/
│   │   │   └── ds_remote_auth.dart         # uses BaseDio (intercepted by MockInterceptor)
│   │   └── local/
│   │       ├── ds_local_user.dart
│   │       └── ds_local_token.dart
│   ├── repos/
│   │   └── r_impl_auth.dart
│   └── sources/local/
│       ├── box_user.dart
│       └── box_auth_token.dart
├── domain/
│   ├── entities/
│   │   ├── param_login.dart                # email/phone, password
│   │   ├── param_register.dart             # name, email, phone, password
│   │   ├── param_forgot.dart               # email
│   │   ├── param_reset.dart                # email, otp, newPassword
│   │   └── e_auth_status.dart              # enum: loggedOut, loggingIn, loggedIn, error
│   ├── repos/
│   │   └── r_auth.dart
│   └── usecases/
│       ├── uc_login.dart
│       ├── uc_register.dart
│       ├── uc_forgot_password.dart
│       ├── uc_verify_otp.dart
│       ├── uc_reset_password.dart
│       ├── uc_logout.dart
│       ├── uc_get_current_user.dart
│       └── uc_is_logged_in.dart
└── presentation/
    ├── screens/
    │   ├── sn_login.dart
    │   ├── sn_register.dart
    │   ├── sn_forgot_password.dart
    │   ├── sn_verify_otp.dart
    │   ├── sn_reset_password.dart
    │   └── sn_register_success.dart
    ├── widgets/
    │   ├── w_auth_header.dart              # logo + green gradient top
    │   ├── w_social_button.dart            # placeholder for future social login
    │   ├── w_otp_input.dart                # 6-digit cells
    │   └── w_password_strength_meter.dart
    └── cubits/
        ├── cb_auth.dart                    # SINGLETON — global auth state
        ├── s_auth.dart
        ├── cb_login_form.dart              # per-screen form state
        ├── s_login_form.dart
        ├── cb_register_form.dart
        ├── s_register_form.dart
        ├── cb_forgot_form.dart
        ├── s_forgot_form.dart
        ├── cb_otp_form.dart
        └── s_otp_form.dart
```

### Singleton `CBAuth`

```dart
@freezed
class SAuth with _$SAuth {
  const factory SAuth({
    @Default(EAuthStatus.loggedOut) EAuthStatus status,
    MUser? user,
    String? token,
    String? error,
  }) = _SAuth;
}

class CBAuth extends Cubit<SAuth> {
  CBAuth(this._isLoggedIn, this._currentUser, this._logout)
      : super(const SAuth());

  Future<void> bootstrap() async {
    final logged = await _isLoggedIn();
    if (logged) {
      final res = await _currentUser();
      res.fold(
        (_) => emit(state.copyWith(status: EAuthStatus.loggedOut)),
        (user) => emit(state.copyWith(status: EAuthStatus.loggedIn, user: user)),
      );
    } else {
      emit(state.copyWith(status: EAuthStatus.loggedOut));
    }
  }

  Future<void> logout() async {
    await _logout();
    emit(const SAuth(status: EAuthStatus.loggedOut));
    Modular.to.pushNamedAndRemoveUntil(AuthRoutes.login, (_) => false);
  }

  void onLoggedIn(MUser user, String token) {
    emit(state.copyWith(status: EAuthStatus.loggedIn, user: user, token: token));
  }
}
```

### Routes

```dart
class AuthRoutes {
  static const login           = '/login';
  static const register        = '/register';
  static const forgotPassword  = '/forgot';
  static const verifyOtp       = '/otp';
  static const resetPassword   = '/reset';
  static const registerSuccess = '/success';
}
```

### Form validation rules

- Email: standard regex + max 100 chars
- Phone: Egyptian format `+201[0-9]{9}` or `01[0-9]{9}` (normalized to E.164 before sending)
- Password: min 8 chars, at least one letter and one digit
- OTP: exactly 6 digits

### Demo credentials shown on login screen

Since this is a mock backend, the login screen shows (in dev flavor only) a small "Demo credentials" card:

```
demo@quran.app · P@ssw0rd!
test@quran.app · Test1234!
```

Hidden in prod flavor.

### Integration with `BaseDio`

```dart
class BaseDio {
  late final Dio _dio;

  BaseDio() {
    _dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));

    _dio.interceptors.addAll([
      AuthInterceptor(),        // adds Bearer token
      if (AppConfig.useMockBackend) Modular.get<MockInterceptor>(),
      LoggingInterceptor(),
    ]);
  }
}
```

### Effort: 6h

---

## 6. Onboarding Module

### Purpose
First-run experience: 3 intro slides → language selection → location permission → **auth (Login or Register)** → home.

### Screens (unchanged from v1)

`SNOnboardingPager` · `SNLanguageSelection` · `SNLocationPermission`

After `SNLocationPermission` completes, the user is routed to `AuthRoutes.login`.

### Effort: 2h

---

## 7. Home Module

### Purpose
The main dashboard. (Unchanged from v1 — all widgets must support dark mode via `Theme.of(context)`.)

### Screens
`SNHome` only.

### Notes
- Profile area at the top reads from `CBAuth.state.user` (the logged-in user).
- Logout button on the profile area calls `CBAuth.logout()`.

### Effort: 4h

---

## 8. Prayer Times Module

🎨 **UI rebuild only.** (Unchanged from v1.)

### Effort: 5h

---

## 9. Adhan Audio Engine

### Top 10 bundled adhan recitations (Decision 1)

After researching the most widely-used adhan recitations across MENA and globally, here is the curated v1 bundle. All are available in the public domain or as free downloads from documented sources.

| # | Adhan | Reciter / Origin | Style | Egyptian audience appeal |
|---|-------|------------------|-------|--------------------------|
| 1 | **Adhan Makkah** | Sheikh Ali Ahmad Mulla (Imam, Masjid al-Haram) | Hijazi maqam | ⭐⭐⭐⭐⭐ globally recognised |
| 2 | **Adhan Madinah** | Sheikh Essam Bukhari (Imam, Masjid an-Nabawi) | Hijazi | ⭐⭐⭐⭐⭐ globally recognised |
| 3 | **Adhan Egypt (Classic)** | Sheikh Muhammad Rifat | Egyptian maqam | ⭐⭐⭐⭐⭐ **default for Egyptian users** |
| 4 | **Adhan Mishary Al-Afasy** | Mishary Rashid Al-Afasy | Kuwaiti modern | ⭐⭐⭐⭐⭐ most popular individual muezzin |
| 5 | **Adhan Naseer Al-Qatami** | Naseer Al-Qatami | Saudi modern | ⭐⭐⭐⭐ |
| 6 | **Adhan Islam Sobhi** | Islam Sobhi | Egyptian modern | ⭐⭐⭐⭐⭐ very popular young Egyptian voice |
| 7 | **Adhan Hafiz Mustafa Ozcan** | Hafiz Mustafa Özcan | Turkish maqam | ⭐⭐⭐⭐ distinctive Ottoman style |
| 8 | **Adhan Al-Aqsa** | Imam of Masjid Al-Aqsa | Levantine | ⭐⭐⭐⭐ symbolic importance |
| 9 | **Adhan Abdul Basit** | Sheikh Abdul Basit Abdus-Samad | Egyptian classical | ⭐⭐⭐⭐⭐ Egyptian legend |
| 10 | **Adhan Fajr (Egypt)** | Sheikh Mahmoud Khalil Al-Husary | Egyptian — includes "الصلاة خير من النوم" | ⭐⭐⭐⭐⭐ **default Fajr adhan** |

### Resource locations (free / public domain)

Bundle these as assets in the app (each file 600 KB – 1.5 MB at 64–128 kbps mono — total bundle ≈ 12 MB).

| Source | URL | Notes |
|--------|-----|-------|
| **Internet Archive (Sunnah Adhans)** | https://archive.org/details/adhans_sunnah | Largest free library; Adhan Makkah, Madina, Egypt, Mishary, Halab. Public domain / Creative Commons. |
| **Assabile.com** | https://www.assabile.com/adhan-call-prayer | Curated muezzin database; free MP3 downloads. |
| **IslamCan Azan MP3** | https://www.islamcan.com/audio/adhan/index.shtml | High-quality MP3s of the most famous adhans. |
| **GitHub — abodehq/Athan-MP3** | https://github.com/abodehq/Athan-MP3 | Pre-curated repo specifically for app developers. |

**Bundling strategy:**
- Compress all to 64 kbps mono (adhan audio doesn't need stereo or high bitrate).
- Average duration ≈ 2 min 30 sec per file → average size ≈ 1.2 MB.
- **Total bundle size ≈ 12 MB** (acceptable for an Islamic app's APK).
- For Fajr, the Fajr-specific adhan (#10) is auto-selected by the engine regardless of which "regular" adhan the user picks, unless they explicitly disable this behaviour in settings.

### Assets folder

```
assets/audio/adhan/
├── adhan_01_makkah.mp3
├── adhan_02_madinah.mp3
├── adhan_03_egypt_rifat.mp3            # default for Egyptian users
├── adhan_04_alafasy.mp3
├── adhan_05_qatami.mp3
├── adhan_06_islam_sobhi.mp3
├── adhan_07_ozcan_turkey.mp3
├── adhan_08_aqsa.mp3
├── adhan_09_abdul_basit.mp3
└── adhan_10_fajr_husary.mp3            # auto-selected for Fajr
```

And a metadata file:

```
assets/data/adhans.json
```

```json
[
  {
    "id": "adhan_makkah",
    "name_ar": "أذان مكة المكرمة",
    "name_en": "Makkah Adhan",
    "muezzin_ar": "الشيخ علي أحمد ملا",
    "muezzin_en": "Sheikh Ali Ahmad Mulla",
    "style": "hijazi",
    "asset": "assets/audio/adhan/adhan_01_makkah.mp3",
    "is_fajr_default": false,
    "duration_seconds": 158
  },
  {
    "id": "adhan_madinah",
    "name_ar": "أذان المدينة المنورة",
    "name_en": "Madinah Adhan",
    "muezzin_ar": "الشيخ عصام بخاري",
    "muezzin_en": "Sheikh Essam Bukhari",
    "style": "hijazi",
    "asset": "assets/audio/adhan/adhan_02_madinah.mp3",
    "is_fajr_default": false,
    "duration_seconds": 165
  },
  {
    "id": "adhan_egypt_rifat",
    "name_ar": "أذان مصر — الشيخ محمد رفعت",
    "name_en": "Egypt — Sheikh Mohamed Rifat",
    "muezzin_ar": "الشيخ محمد رفعت",
    "muezzin_en": "Sheikh Mohamed Rifat",
    "style": "egyptian_classical",
    "asset": "assets/audio/adhan/adhan_03_egypt_rifat.mp3",
    "is_fajr_default": false,
    "is_default_for_locale": ["ar-EG"],
    "duration_seconds": 174
  },
  {
    "id": "adhan_alafasy",
    "name_ar": "أذان الشيخ مشاري العفاسي",
    "name_en": "Sheikh Mishary Al-Afasy",
    "muezzin_ar": "الشيخ مشاري راشد العفاسي",
    "muezzin_en": "Sheikh Mishary Rashid Al-Afasy",
    "style": "modern",
    "asset": "assets/audio/adhan/adhan_04_alafasy.mp3",
    "is_fajr_default": false,
    "duration_seconds": 162
  },
  {
    "id": "adhan_qatami",
    "name_ar": "أذان ناصر القطامي",
    "name_en": "Naseer Al-Qatami",
    "muezzin_ar": "الشيخ ناصر القطامي",
    "muezzin_en": "Sheikh Naseer Al-Qatami",
    "style": "modern",
    "asset": "assets/audio/adhan/adhan_05_qatami.mp3",
    "is_fajr_default": false,
    "duration_seconds": 168
  },
  {
    "id": "adhan_islam_sobhi",
    "name_ar": "أذان إسلام صبحي",
    "name_en": "Islam Sobhi",
    "muezzin_ar": "إسلام صبحي",
    "muezzin_en": "Islam Sobhi",
    "style": "egyptian_modern",
    "asset": "assets/audio/adhan/adhan_06_islam_sobhi.mp3",
    "is_fajr_default": false,
    "duration_seconds": 156
  },
  {
    "id": "adhan_ozcan",
    "name_ar": "أذان حافظ مصطفى أوزجان (تركيا)",
    "name_en": "Hafiz Mustafa Özcan (Turkey)",
    "muezzin_ar": "حافظ مصطفى أوزجان",
    "muezzin_en": "Hafiz Mustafa Özcan",
    "style": "ottoman",
    "asset": "assets/audio/adhan/adhan_07_ozcan_turkey.mp3",
    "is_fajr_default": false,
    "duration_seconds": 180
  },
  {
    "id": "adhan_aqsa",
    "name_ar": "أذان المسجد الأقصى",
    "name_en": "Al-Aqsa Adhan",
    "muezzin_ar": "إمام المسجد الأقصى",
    "muezzin_en": "Imam of Al-Aqsa Mosque",
    "style": "levantine",
    "asset": "assets/audio/adhan/adhan_08_aqsa.mp3",
    "is_fajr_default": false,
    "duration_seconds": 170
  },
  {
    "id": "adhan_abdul_basit",
    "name_ar": "أذان الشيخ عبد الباسط عبد الصمد",
    "name_en": "Sheikh Abdul Basit Abdus-Samad",
    "muezzin_ar": "الشيخ عبد الباسط عبد الصمد",
    "muezzin_en": "Sheikh Abdul Basit Abdus-Samad",
    "style": "egyptian_classical",
    "asset": "assets/audio/adhan/adhan_09_abdul_basit.mp3",
    "is_fajr_default": false,
    "duration_seconds": 188
  },
  {
    "id": "adhan_fajr_husary",
    "name_ar": "أذان الفجر — الشيخ الحصري",
    "name_en": "Fajr Adhan — Sheikh Al-Husary",
    "muezzin_ar": "الشيخ محمود خليل الحصري",
    "muezzin_en": "Sheikh Mahmoud Khalil Al-Husary",
    "style": "egyptian_classical",
    "asset": "assets/audio/adhan/adhan_10_fajr_husary.mp3",
    "is_fajr_default": true,
    "duration_seconds": 195,
    "note_ar": "يحتوي على الصلاة خير من النوم",
    "note_en": "Includes 'Prayer is better than sleep'"
  }
]
```

### Default selection logic
- Locale is `ar-EG` (Egyptian Arabic): default = Adhan #3 (Sheikh Mohamed Rifat).
- Locale is any other Arabic: default = Adhan #1 (Makkah).
- Locale is non-Arabic: default = Adhan #4 (Alafasy — most universally recognised).
- Fajr always uses Adhan #10 unless user opts out in settings.

### Settings reciter picker integration

The Settings → Adhan picker screen lists all 10 with:
- Preview play button (plays the asset directly via `just_audio`)
- Selected indicator
- Separate row for "Fajr adhan" (defaults to #10, can override)

### Effort: 6h (was 5h in v1 — added 1h for adhan metadata + locale-aware defaults)

---

## 10. Azkar Module

🎨 **UI rebuild only.** (Unchanged from v1 — must support dark mode.)

### Effort: 4.5h

---

## 11. Tasbih Module

🆕 **Build from scratch.** (Unchanged from v1.)

### Effort: 2h

---

## 12. Reminders Module

### Purpose
User-created custom daily reminders, **capped at 30** (Decision 4) — this stays within iOS local notification limits (64 pending notifications per app) and matches realistic user behaviour.

### Cap enforcement

```dart
class UCCreateReminder {
  UCCreateReminder(this._repo);
  final RReminders _repo;

  Future<Either<Failure, MReminder>> call(ParamReminder p) async {
    final existing = await _repo.count();
    if (existing >= 30) {
      return Left(Failure.validationFailure(
        message: 'reminders_max_reached'.translated,   // "لقد وصلت إلى الحد الأقصى (30 تذكير)"
      ));
    }
    return _repo.create(p);
  }
}
```

### UI behaviour
- When count reaches 30, the "+" FAB on the list screen disables and shows a tooltip "Maximum reached (30)".
- When viewing the list, a small chip at the top shows "12 / 30".

### Effort: 4.5h (1.5h list + 3h form)

---

## 13. Mosques Module

### Purpose
Map of nearby mosques + list, with **10 + 10 load-more** behaviour and **location-cached results** (Decision 3).

### Behaviour spec

1. On screen open, app fetches the **first 10** nearest mosques from Google Places API.
2. List shows mosques + a "Load more" button at the bottom (not infinite scroll).
3. Tapping "Load more" fetches the **next 10**, appends them to the list.
4. The cache key is the user's coarse GPS coordinates rounded to ~100 m.
   - If user moves more than ~500 m, cache is invalidated and fetch restarts.
   - Otherwise, results are served from cache (no API call → no Google Places cost).
5. Cache is persisted in `BoxMosquesCache` (typeId 61) so the app survives restart without re-fetching.

### Cache model

```dart
@HiveType(typeId: 61)
class MMosquesCache {
  @HiveField(0) double anchorLatitude;        // user's GPS at fetch time
  @HiveField(1) double anchorLongitude;
  @HiveField(2) List<MMosque> mosques;        // accumulated results
  @HiveField(3) String? nextPageToken;        // Google Places token for next 10
  @HiveField(4) DateTime cachedAt;

  bool isStillValidForUserAt(double lat, double lng) {
    final d = _haversineMeters(anchorLatitude, anchorLongitude, lat, lng);
    return d < 500;   // user moved less than 500m
  }
}
```

### Cubit

```dart
@freezed
class SNearbyMosques with _$SNearbyMosques {
  const factory SNearbyMosques({
    @Default([]) List<MMosque> mosques,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(true) bool canLoadMore,
    String? nextPageToken,
    String? error,
  }) = _SNearbyMosques;
}

class CBNearbyMosques extends Cubit<SNearbyMosques> {
  CBNearbyMosques(this._getMosques, this._cache) : super(const SNearbyMosques());
  final UCGetNearbyMosques _getMosques;
  final RMosques _cache;

  Future<void> load() async {
    // 1. Get current location
    final loc = await _getLocation();

    // 2. Check cache
    final cached = await _cache.getCache();
    if (cached != null && cached.isStillValidForUserAt(loc.lat, loc.lng)) {
      emit(state.copyWith(
        mosques: cached.mosques,
        canLoadMore: cached.nextPageToken != null,
        nextPageToken: cached.nextPageToken,
      ));
      return;
    }

    // 3. Fresh fetch — first 10
    emit(state.copyWith(isLoading: true));
    final res = await _getMosques(loc, pageToken: null, limit: 10);
    res.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (page) => emit(state.copyWith(
        isLoading: false,
        mosques: page.items,
        canLoadMore: page.nextPageToken != null,
        nextPageToken: page.nextPageToken,
      )),
    );
  }

  Future<void> loadMore() async {
    if (!state.canLoadMore || state.isLoadingMore) return;
    emit(state.copyWith(isLoadingMore: true));

    final loc = await _getLocation();
    final res = await _getMosques(loc, pageToken: state.nextPageToken, limit: 10);
    res.fold(
      (failure) => emit(state.copyWith(isLoadingMore: false, error: failure.message)),
      (page) => emit(state.copyWith(
        isLoadingMore: false,
        mosques: [...state.mosques, ...page.items],
        canLoadMore: page.nextPageToken != null,
        nextPageToken: page.nextPageToken,
      )),
    );
  }
}
```

### Google Places API rate impact
With this design, a user who opens the Mosques screen once and stays in the same neighbourhood costs us **1 API call** (or 2 if they tap "Load more"). Without the cache, opening the screen 10 times would cost 10 calls. This is the main mitigation against the Google Places billing risk.

### Effort: 3.5h (was 3h — added 0.5h for the location-based cache + load-more)

---

## 14. Qibla Module

🎨 **UI rebuild only.** (Unchanged from v1.)

### Effort: 1h

---

## 15. Khatma Module

### Purpose
Plan-based Quran reading tracker. (Core unchanged from v1 — adds Decision 5: completion congrats screen.)

### New screen: `SNKhatmaCompleted`

When the user marks the final day of their plan as done, navigate to this celebration screen:

**Layout:**
- Big gold Kaaba-shaped illustration at top with subtle floating sparkles animation
- Headline: "ختمت القرآن — تقبل الله منك" / "You completed your Khatma — May Allah accept it"
- Stats card: total days, exact dates, longest streak
- Sharing CTA: "Share your completion with friends" (uses `share_plus`)
- Primary button: **"ابدأ ختمة جديدة" / "Start a new khatma"** → returns to `SNKhatmaPlans`
- Secondary button: "اعرض إحصائياتي / Show my stats" → reading history

### Completion record

```dart
@HiveType(typeId: 83)
class MKhatmaCompletion {
  @HiveField(0) String id;
  @HiveField(1) int planId;
  @HiveField(2) DateTime startedAt;
  @HiveField(3) DateTime completedAt;
  @HiveField(4) int totalDays;
  @HiveField(5) int longestStreakDays;
  @HiveField(6) int daysOnTime;          // days completed before deadline
}
```

All historical completions are preserved (so a user can see "I've completed 3 khatmas this year").

### Updated flow

```
SNKhatmaTracker
    │
    ├─→ user marks day N done
    │
    ├─→ Is this the final day?
    │       │
    │       ├─ Yes ──→ Save MKhatmaCompletion → SNKhatmaCompleted
    │       │
    │       └─ No  ──→ Stay on tracker, show toast "تمام — تقبل الله"
```

### Routes

```dart
class KhatmaRoutes {
  static const plans       = '/';
  static const tracker     = '/tracker';
  static const dayDetails  = '/day';
  static const completed   = '/completed';            // NEW
  static const history     = '/history';              // NEW

  static String dayDetailsFor(int dayIndex) => '$dayDetails?day=$dayIndex';
}
```

### Effort: 2.5h (was 2h — added 0.5h for completion screen + history)

---

## 16. Settings Module

### Purpose
Centralized app settings, now including **theme**, **profile management**, and **logout** (Decision 6 & 7).

### New rows added

| Section | Row | Behavior |
|---------|-----|----------|
| Profile | Edit name | Inline text field with save |
| Profile | Edit avatar | Picks from device gallery, uploads via mock `/users/profile` |
| Profile | **Logout** | Confirm dialog → `CBAuth.logout()` |
| Appearance | **Theme** | Light / Dark / System (radio buttons) |
| Appearance | **Language** | RTL/LTR switch with full app rebuild |

### File structure additions

```
lib/modules/settings/presentation/widgets/
├── w_theme_picker.dart                # NEW — 3 options with live preview swatches
├── w_avatar_picker.dart               # NEW — taps to open gallery
└── w_logout_tile.dart                 # NEW — confirm dialog + auth.logout()
```

### Effort: 2h

---

## 17. Notifications Service

### Hourly tasbih schedule (Decision 2)

The hourly tasbih notifications **only fire between 08:00 and 22:00** (15 notifications per day total, picking azkar with `hour % 10` from `hourly_notifications.json`).

```dart
class HourlyNotificationHandler {
  static const _activeHours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22];

  Future<void> scheduleAll() async {
    await _cancelAll();

    for (final hour in _activeHours) {
      final zekrIndex = hour % 10;
      final zekr = config.hourlyAzkar[zekrIndex];

      await _localNotifications.zonedSchedule(
        _baseId + hour,                       // unique ID per hour
        title: 'azkar_hourly_title'.translated,
        body: zekr.textAr,
        scheduledDate: _nextTimeAtHour(hour),
        notificationDetails: _hourlyDetails(),
        matchDateTimeComponents: DateTimeComponents.time,   // repeats daily
      );
    }
  }

  tz.TZDateTime _nextTimeAtHour(int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (next.isBefore(now)) next = next.add(const Duration(days: 1));
    return next;
  }
}
```

### Channel update

```
hourly_channel
  Importance: LOW
  Sound:      none (silent)
  Vibration:  no
  Lights:     no
```

This means the user sees the zekr quietly in the notification shade without being interrupted — exactly the right tone for hourly reminders during the day.

### Notes

- Users can **disable** the entire hourly category in Settings → Notifications.
- 22:00 is the **last** hourly tasbih; the 22:00 sleep azkar notification (from `init_notifications.json`) fires at the same minute but in a different channel (`azkar_channel`), so the user gets both.
- Quran reminders (Al-Mulk at 22:00, etc.) fire on their own schedule independent of the hourly bucket.

### Effort: folded into Notifications service (covered in §17 timeline)

---

## 18. Legal Pages Module

🆕 (Unchanged from v1.)

### Effort: 1.5h

---

## 19. Cross-Module Integration Points

### 19.1 Singleton Cubits (updated)

| Singleton | Owner module | Consumers |
|-----------|-------------|-----------|
| `CBTheme` | core | App root (MaterialApp), Settings |
| `CBAuth` | Auth | App router (logged-in check), Home (profile), Settings (logout) |
| `CBPrayerTimes` | Prayer Times | Home, Notifications |
| `CBKhatma` | Khatma | Home (daily wird card) |
| `CBAudioPlayer` (Quran) | Quran | Home (optional mini player) |
| `CBAdhanPlayer` | Adhan Engine | Notifications, Settings (preview), Adhan playing screen |
| `CBSettings` | Settings | Many modules (notification toggles, language) |
| `CBReciter` | Quran | Settings (default reciter row) |
| `NotificationsService` | core/services | Reminders, Prayer Times, Settings |

### 19.2 Updated app-startup decision tree

```
runApp()
   ↓
Splash (read flags & boot singletons)
   │
   ├─ CBTheme.load()
   ├─ CBAuth.bootstrap()
   ├─ CBPrayerTimes.load() (if location granted)
   ├─ CBKhatma.load() (if active khatma)
   └─ NotificationsService.rescheduleAll()
   ↓
hasSeenOnboarding? ──No──→ Onboarding flow → Language → Location → Login
   │ Yes
   ↓
isLoggedIn? ──No──→ Login
   │ Yes
   ↓
Home
```

### 19.3 Hive initialization order (updated)

```dart
await Hive.initFlutter();

// Register adapters
Hive.registerAdapter(MUserAdapter());                  // 0
Hive.registerAdapter(MAuthTokenAdapter());             // 1
Hive.registerAdapter(MAppSettingsAdapter());           // 2
Hive.registerAdapter(MThemePrefAdapter());             // 3
Hive.registerAdapter(MBookmarkAdapter());              // 10
// … all others …
Hive.registerAdapter(MAdhanPreferenceAdapter());       // 110

// Open boxes
await BoxUser().init();
await BoxAuthToken().init();
await BoxAppSettings().init();
// … etc
```

### 19.4 Modular root module (updated)

```dart
class AppModule extends Module {
  @override
  void binds(i) {
    i.addSingleton<BaseDio>(BaseDio.new);
    i.addSingleton<CBTheme>(CBTheme.new);
    i.addSingleton<NotificationsService>(NotificationsService.new);
    i.addSingleton<NotificationRouter>(NotificationRouter.new);
    if (AppConfig.useMockBackend) {
      i.addSingleton<MockDatabase>(MockDatabase.new);
      i.addSingleton<MockInterceptor>(MockInterceptor.new);
    }
  }

  @override
  void routes(r) {
    r.module(AppRoutes.auth,        module: AuthModule());
    r.module(AppRoutes.onboarding,  module: OnboardingModule());
    r.module(AppRoutes.home,        module: HomeModule());
    r.module(AppRoutes.quran,       module: QuranModule());
    r.module(AppRoutes.prayer,      module: PrayerTimesModule());
    r.module(AppRoutes.adhan,       module: AdhanEngineModule());
    r.module(AppRoutes.azkar,       module: AzkarModule());
    r.module(AppRoutes.tasbih,      module: TasbihModule());
    r.module(AppRoutes.reminders,   module: RemindersModule());
    r.module(AppRoutes.mosques,     module: MosquesModule());
    r.module(AppRoutes.qibla,       module: QiblaModule());
    r.module(AppRoutes.khatma,      module: KhatmaModule());
    r.module(AppRoutes.settings,    module: SettingsModule());
    r.module(AppRoutes.legal,       module: LegalModule());
  }
}
```

---

## 20. Implementation Order & Timeline (updated)

| Phase | Days | Hours | What |
|-------|------|-------|------|
| **1. Foundation** | 1 | 8h | Project setup, root module, AppRoutes, Hive registry, shared widgets |
| **2. Theme System** | ¼ | 2h | Light + Dark themes, `CBTheme` singleton, persisted preference |
| **3. Mock Backend** | ⅓ | 3h | `MockInterceptor`, `MockDatabase`, seeded users, fake endpoints |
| **4. Auth Module** | ¾ | 6h | Login + Register + Forgot Password + OTP, all wired to mock backend |
| **5. Onboarding** | ¼ | 2h | 3 slides → language → location → routes to Auth |
| **6. Settings (skeleton)** | ¼ | 2h | Empty settings with profile card and rows that link to feature screens |
| **7. Home (skeleton)** | ½ | 4h | Shortcuts grid + placeholder cards (real data plugs in as modules ship) |
| **8. Notifications scaffold** | ¼ | 2h | Channel setup, permission, router (handlers stubbed) |
| **9. Prayer Times UI** | ¾ | 5h | UI rebuild on existing client logic; wire `CBPrayerTimes` singleton |
| **10. Adhan Engine** | ¾ | 6h | 10 bundled adhans, audio engine, background service, prayer notification handler |
| **11. Azkar** | ¾ | 4.5h | UI rebuild + azkar notification handler |
| **12. Tasbih** | ⅓ | 2h | 3 sub-screens |
| **13. Reminders** | ¾ | 4.5h | List + form + cap-30 enforcement + notification scheduling |
| **14. Mosques** | ½ | 3.5h | Google Maps + load-more + location cache |
| **15. Qibla** | ⅛ | 1h | UI rebuild |
| **16. Khatma** | ⅓ | 2.5h | Plans + tracker + day details + congrats + history |
| **17. Quran Module** | ~9.5 | 75h | See [`Quran_Module_Plan.md`](./Quran_Module_Plan.md) |
| **18. Legal pages** | ¼ | 1.5h | 3 markdown screens |
| **19. Polish + QA + Stores** | 2 | 11h | Cross-module testing, dark-mode pass, store submission |

**Total non-Quran:** ~70h (up from 45h in v1).
**Total project:** ~145h (~18 working days solo).

### What grew vs v1
- +2h Theme System (now in v1)
- +3h Mock Backend
- +6h Auth Module
- +1h Adhan Engine (locale-aware defaults + 10 adhans metadata)
- +0.5h Mosques (load-more + cache)
- +0.5h Khatma (congrats + history)
- = +13h vs v1's 45h baseline (well below the v1 quotation's allowance)

---

## 21. Acceptance Criteria

### Per-module — unchanged from v1, with these additions

- [ ] **Dark mode:** every screen renders correctly in light, dark, and system-follow theme
- [ ] **Auth flow:** login/register/forgot/OTP all work end-to-end with mock backend
- [ ] **Mock backend:** flipping `AppConfig.useMockBackend` from true to false removes all canned responses (verified by network log)
- [ ] **Adhan engine:** all 10 adhans play, preview button works in Settings, Fajr-specific adhan auto-selects unless overridden
- [ ] **Hourly tasbih:** notifications fire only between 08:00 and 22:00; silent channel verified on real device
- [ ] **Reminders cap:** creating the 31st reminder shows a validation message
- [ ] **Mosques cache:** opening the screen twice in the same location triggers 1 API call; moving 500m+ triggers a fresh fetch
- [ ] **Mosques load-more:** "Load more" button appears at the bottom; tapping it appends 10 more results; disappears when no more results
- [ ] **Khatma completion:** marking the final day routes to congrats screen with the "Start a new khatma" CTA wired correctly
- [ ] **Khatma history:** historical completions persist and display correctly
- [ ] **Logout:** `CBAuth.logout()` clears token, returns user to login, preserves theme preference

### App-wide — unchanged from v1

(See v1 §18.)

---

## 22. Open Items (now resolved)

| # | Open item | Resolution |
|---|-----------|-----------|
| 1 | Adhan list | ✅ 10 selected, resources documented (§9) |
| 2 | Hourly schedule | ✅ 08:00–22:00 only (§17) |
| 3 | Mosques rate limiting | ✅ 10+10 load-more + location-based cache (§13) |
| 4 | Reminders cap | ✅ 30 max (§12) |
| 5 | Khatma completion | ✅ Congrats screen + Start New CTA (§15) |
| 6 | Auth & backend | ✅ Auth module + mock backend (§4, §5) |
| 7 | Dark mode | ✅ Full v1 feature, end-to-end (§3) |

All v1 open items are now closed. No new open items.

---

**End of plan (v2).**
For the Quran reader module, read [`Quran_Module_Plan.md`](./Quran_Module_Plan.md).
For developer conventions, read [`../instructions.md`](../instructions.md).
For AI assistant context, read [`../CLAUDE.md`](../CLAUDE.md).
