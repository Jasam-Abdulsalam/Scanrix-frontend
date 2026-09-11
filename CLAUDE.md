# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Scanrix frontend: a Flutter app (package name `scanrix_frontend`, org `com.scanrix`) that
consumes the Scanrix backend (`../scanrix-backend`, FastAPI) — a "health product scanner".
Given a barcode (camera/manual entry) or OCR'd ingredient text, it shows an ingredient-level
safety analysis.

Product vision, problem statement, and target users: see [VISION.md](VISION.md).

Clean architecture + `flutter_bloc` for state management, `get_it` as a manual service
locator for DI. **No repository/interface layer by design** — domain use cases call the
API directly rather than going through a `Data` implementation of a `Domain`-defined
interface. This was a deliberate simplification (fewer files, faster to build against a
backend that's still moving) traded off against easier mocking/swapping later — see
`../scanrix-backend/CLAUDE.md` if you need backend context, and revisit this decision if
the app outgrows it.

**Networking is not wired up yet.** Every use case currently `throw`s `UnimplementedError`
with a `TODO` at the call site — see "Status / what's not done yet" below before assuming
any feature works end-to-end.

## Commands

```bash
# Setup
flutter pub get

# Run the app (needs the backend running — see ../scanrix-backend/CLAUDE.md)
flutter run

# Static analysis (must stay clean — no issues as of this writing)
flutter analyze

# Tests
flutter test
```

Flutter 3.35.6 / Dart 3.9.2 at time of scaffolding (`flutter --version`). No CI configured.

## Architecture

Each feature under `lib/features/<name>/` follows the same three-layer shape:

```
domain/
  entities/    # plain Dart classes (Equatable), no JSON knowledge
  usecases/    # implements core/usecase/UseCase<R, Params>; where the API call happens
data/
  models/      # extends the matching entity, adds fromJson()/toJson()
presentation/
  bloc/        # <name>_bloc.dart, <name>_event.dart, <name>_state.dart (flutter_bloc)
  pages/       # top-level route widgets
  widgets/     # feature-local widgets (currently empty — just .gitkeep)
```

- `lib/core/constants/api_constants.dart` — base URL + every endpoint path, kept in sync
  with the backend's `app/api/v1/api.py` route prefixes (`/auth`, `/products`, `/scan`,
  `/history`). **Update `baseUrl` here** to point at wherever the backend is actually
  running. Paths only, no logic — use cases call the backend through `ApiClient`, below,
  never by touching Dio directly.
- `lib/core/network/api_client.dart` — **the thing every use case actually calls.**
  `ApiClient.get/post/put/delete(path, ...)` takes an `ApiConstants` path (not a full
  URL), and in one place handles what would otherwise be duplicated per use case: builds
  the full `Uri` (base URL + path + query params), sends the request through `DioClient`,
  unwraps `response.data`, and maps `DioException` to `ServerException`/`NetworkException`
  consistently. Also exposes `setToken`/`clearToken`/`loadPersistedToken`, which just
  delegate to `DioClient` — see "Google Sign-In" below for how a use case calls these
  after a successful login. So far only `GoogleLoginUseCase` goes through this;
  `LoginUseCase`/`RegisterUseCase` are still stubs (see "Status" below).
- `lib/core/network/dio_client.dart` — lower-level than `ApiClient`; owns the raw `Dio`
  instance (base URL, timeouts), the Bearer-token interceptor, and a `TokenStorage`.
  Use cases should go through `ApiClient`, not this, directly.
- `lib/core/usecase/usecase.dart` — `abstract class UseCase<R, Params> { Future<R> call(Params params); }`.
  Every use case implements this so Blocs can call them uniformly.
- `lib/core/error/exceptions.dart` — `ServerException`, `NetworkException`, thrown by
  `ApiClient` on failed backend calls (or directly by a use case for a non-network failure,
  e.g. Google Sign-In being cancelled). Blocs already catch generic exceptions in their
  event handlers and map them to a `*Failure` state.
- `lib/core/storage/token_storage.dart` — wraps `flutter_secure_storage` to persist the
  JWT (Keychain/Keystore, not `shared_preferences` — a JWT is a bearer credential and
  shouldn't sit in unencrypted storage). Owned by `DioClient`; reached through `ApiClient`.
- `lib/core/di/injection_container.dart` — `final sl = GetIt.instance;` plus `Future<void> init()`,
  called once from `main()` before `runApp`. Registers every use case
  (`registerLazySingleton`) and every Bloc (`registerFactory`), registers `TokenStorage` →
  `DioClient` → `ApiClient` in that order, and calls `ApiClient.loadPersistedToken()` so a
  token from a previous session is attached before the app's first request.
- `lib/app.dart` — `ScanrixApp`: wraps `MaterialApp` in a `MultiBlocProvider` that pulls
  every top-level Bloc from `sl`. **Temporarily boots straight to `HomePage`** (was
  `LoginPage`) to make the home page easy to preview during development — there's still
  no router/auth-gate connecting the two. Switch `home:` back to `LoginPage()` once the
  login flow itself is confirmed working.
- `lib/main.dart` — `WidgetsFlutterBinding.ensureInitialized()` → `di.init()` → `runApp`.

### Home page (`lib/features/home/presentation/pages/home_page.dart`)

Static UI only, matching the provided design — no navigation wired yet. Tapping "Scan
Now", any `BottomNavBar` item, or a `QuickActionCard` currently does nothing; their
destination pages (`ScanPage`, `HistoryPage`, etc.) are still placeholder `Scaffold`s
anyway. When navigation does get wired, the plan (per earlier discussion, not yet
implemented) is simple push navigation per nav item rather than a persistent
`IndexedStack` tab shell — revisit that choice if the app's navigation needs grow.

Only `home/presentation/` exists — no `domain`/`data` layers, since this page has no data
of its own to fetch (it's a static shell composed from other features' content). Don't add
those layers speculatively; add them if/when this page actually needs its own use case.

New reusable `core/widgets/`: `PrimaryButton` (solid-emerald CTA — the `GlassButton`
counterpart for primary actions), `QuickActionCard`, `FloatingScanButton`, `BottomNavBar`
(composes `FloatingScanButton` internally). The profile avatar is a generic person icon,
not a real photo — there's no user-photo field or Google-profile-picture wiring yet.

### Sizing / responsive units

Every size value (padding, margins, radius, icon/asset dimensions) uses
`flutter_screenutil` instead of raw `double` literals. `ScreenUtilInit` wraps `MaterialApp`
in `lib/app.dart` with a `designSize` of `375x812` (iPhone X/11/13-mini frame, the common
Figma/mobile reference) — change the `_designSize` constant there if designs target a
different frame.

Convention — use these everywhere instead of bare numbers:
- `.w` — widths, horizontal padding/margin, horizontal offsets
- `.h` — heights, vertical padding/margin, vertical offsets
- `.r` — border radius, blur sigma, and square/uniform sizes (icon size, circle diameter) —
  scales by `min(scaleWidth, scaleHeight)` so these stay uniform on unusual aspect ratios
- `.sp` — font size

Reusable widgets in `core/widgets/` (`GlassCard`, `GlassButton`, `GoogleLogo`) take
**nullable** size parameters instead of literal defaults, because `.w`/`.h`/`.r`/`.sp` return
runtime values and Dart requires default parameter values to be compile-time constants — the
scaled default is resolved inside `build()` instead (e.g. `padding ?? EdgeInsets.all(20.r)`).
Follow that pattern for any new reusable widget that wants a built-in default size.

This is a project convention, not a Flutter/Dart requirement: `flutter_screenutil` scales
every dimension linearly against the fixed `designSize`, which is simple and consistent but
not the only valid approach to responsiveness (vs. `MediaQuery`/`LayoutBuilder`-driven
breakpoints, which adapt layout structure instead of just scaling numbers). Worth
revisiting if the app grows to support tablets/foldables, where linear scaling from a
phone-sized reference can look off.

### Feature ↔ backend endpoint map

| Feature    | Backend route                                  | Notes |
|------------|-------------------------------------------------|-------|
| `auth`     | `POST /auth/register`, `POST /auth/login`, `POST /auth/google` | `AuthTokenEntity` mirrors the `Token` schema. `/auth/google` is the only auth path actually wired to the network so far — see "Google Sign-In" below. |
| `products` | `GET /products/{barcode}`                       | `ProductEntity.isAnalyzing` is true when `verdict == "analyzing"` — the backend runs AI analysis as a background task, so the product page is expected to **poll** this endpoint until the verdict flips (see backend's scan flow docs). Polling isn't implemented yet. |
| `scan`     | `POST /scan/`, `POST /scan/analyze-text`        | `analyze-text` is the OCR path — synchronous, nothing persisted server-side. Its response is `{"success": bool, "analysis": {...}}`; `TextAnalysisModel.fromJson` expects the inner `analysis` object directly, not the wrapper — the use case will need to unwrap `["analysis"]` before parsing. |
| `history`  | `GET /history/?limit=`                          | `ScanHistoryEntity` mirrors `history_helper()`'s dict, not a Pydantic schema (backend returns `List[dict]`). |

### Google Sign-In

The only auth path that's actually networked end-to-end so far. Flow:
`login_page.dart`'s "Continue with Google" button dispatches `AuthGoogleLoginRequested` →
`AuthBloc` calls `GoogleLoginUseCase` → that runs the native Google Sign-In flow
(`google_sign_in` v7's `GoogleSignIn.instance.authenticate()`) to get a Google ID token,
POSTs it to the backend's `POST /auth/google`, and returns the same `AuthTokenEntity`
shape `LoginUseCase` would — the backend issues its own JWT either way, so the Bloc emits
the existing `AuthLoginSuccess`/`AuthFailure` states, no new state types needed.

This required standing up `DioClient`/`ApiClient` for real (both were `TODO` placeholders)
and registering them in `injection_container.dart`, but **only for `GoogleLoginUseCase`**
— `LoginUseCase` and `RegisterUseCase` deliberately still throw `UnimplementedError`;
wiring those up to `ApiClient` too is still "the main next step" below, just not done as
part of this. `GoogleLoginUseCase` calls `apiClient.post(ApiConstants.googleLogin, ...)`
and, on success, `apiClient.setToken(...)` — it never touches `DioClient` directly.

`google_sign_in: ^7.2.0` uses the newer singleton API: `GoogleSignIn.instance.initialize(...)`
must be awaited exactly once before any other call — done in
`injection_container.dart::init()`, before `AuthBloc`/`GoogleLoginUseCase` are registered.

**Setup required before this actually works** (nothing here works with real Google
accounts until this is done):
1. In Google Cloud Console, create an OAuth consent screen and three OAuth client IDs:
   **Web**, **Android** (package `com.scanrix.scanrix_frontend` + your signing
   certificate's SHA-1 — get it via `cd android && ./gradlew signingReport`), and **iOS**
   (bundle ID).
2. Put the **Web** client ID in `core/constants/google_auth_config.dart`
   (`GoogleAuthConfig.webClientId`) — it's used as `serverClientId` on every platform,
   which is what makes the ID token's `aud` claim match. The backend's `.env`
   `GOOGLE_CLIENT_ID` (see `../scanrix-backend/CLAUDE.md`) must be the exact same Web
   client ID — the two sides verify against each other.
3. iOS only: add the reversed iOS client ID as a URL scheme in
   `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>com.googleusercontent.apps.YOUR_IOS_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   ```
   No Android manifest changes are needed for this plugin version — Android verifies via
   Play Services against the package name + SHA-1 registered in step 1.
4. Known nuance to watch for once real credentials are in: Google's ID token audience
   handling differs slightly by platform (iOS can issue tokens audienced to the iOS
   client rather than the Web one). If the backend rejects a real iOS sign-in with an
   audience mismatch, the fix is on the backend side (accept the iOS client ID as an
   additional valid audience) — don't work around it by relaxing verification on the
   frontend.

The JWT is now persisted: `core/storage/token_storage.dart` wraps `flutter_secure_storage`
(Keychain/Keystore — deliberately not `shared_preferences`, since a JWT is a bearer
credential and shouldn't sit in unencrypted storage). `DioClient` owns the `TokenStorage`
and attaches `Authorization: Bearer <token>` to every request via an interceptor once a
token is set; `ApiClient` exposes `setToken`/`clearToken`/`loadPersistedToken` as thin
delegates to `DioClient`, since use cases only ever talk to `ApiClient`.
`GoogleLoginUseCase` calls `apiClient.setToken(...)` right after a successful
`/auth/google` response; `injection_container.dart::init()` calls
`apiClient.loadPersistedToken()` right after registering `ApiClient`, so a token from a
previous session is already attached before the first request of a new app launch. There's
still no routing/auth-gate (see below) — a persisted token doesn't currently skip
`LoginPage`, it only means requests are pre-authenticated once you do navigate somewhere
that calls the API.

## Status / what's not done yet

- **`ApiClient`/`DioClient` are wired for `GoogleLoginUseCase` only** (see "Google Sign-In"
  above). `LoginUseCase.call()` and `RegisterUseCase.call()` still throw
  `UnimplementedError` — wiring those through `ApiClient` the same way is the main next step.
- Token storage exists (`flutter_secure_storage`, see "Google Sign-In" above) but nothing
  reads it to skip `LoginPage` on a fresh launch — there's no auth-gate yet (next bullet).
- No routing package — `app.dart` hardcodes `home: const LoginPage()`. Navigation between
  auth → scan → product detail → history isn't wired.
- Pages (`login_page.dart`, `register_page.dart`, `scan_page.dart`,
  `product_detail_page.dart`, `history_page.dart`) are all placeholder `Scaffold`s with a
  single `Text` widget — no forms, no `BlocBuilder`/`BlocListener` wiring to their Blocs yet.
- `presentation/widgets/` folders are empty (just `.gitkeep`) in every feature.
- No camera/barcode-scanning or OCR package chosen yet, despite `scan` being the core flow.

## Gotchas

- The Flutter client is expected to **poll** `GET /products/{barcode}` after a scan until
  `verdict` is no longer `"analyzing"` (`"error"`/`"unknown"` are terminal too) — this is a
  backend design choice (see `../scanrix-backend/CLAUDE.md`'s "Scan flow" section), not
  optional client behavior.
- `core/di/injection_container.dart` registers Blocs with `registerFactory` (a new instance
  every `sl<XBloc>()` call) and use cases with `registerLazySingleton` (one shared instance).
  Keep that split when adding new features — don't singleton a Bloc.
